"""
Airflow DAG for Medical Records ETL Pipeline
Extracts CSV files from S3, loads to PostgreSQL, transforms with ID generation, 
and runs dbt models
"""
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import sys
import os

# Add elt directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../elt'))

from extract_from_s3 import S3Extractor
from load_to_postgres import PostgresLoader
from generate_ids import IDGenerator

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'medical_records_etl_pipeline',
    default_args=default_args,
    description='ETL pipeline for medical records from S3 to RDS',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    catchup=False,
    tags=['medical', 'etl', 's3', 'postgres'],
)


def extract_from_s3(**context):
    """Extract CSV files from S3"""
    extractor = S3Extractor()
    files = extractor.extract_all()
    
    # Push file info to XCom for next tasks
    context['ti'].xcom_push(key='downloaded_files', value=files)
    
    return len(files)


def load_facilities(**context):
    """Load facilities data"""
    files = context['ti'].xcom_pull(key='downloaded_files', task_ids='extract_from_s3')
    loader = PostgresLoader()
    
    for file_info in files:
        if 'facilities' in file_info['filename'].lower():
            count = loader.load_facilities(file_info['local_path'])
            return count
    
    return 0


def load_patients(**context):
    """Load patients data"""
    files = context['ti'].xcom_pull(key='downloaded_files', task_ids='extract_from_s3')
    loader = PostgresLoader()
    
    for file_info in files:
        if 'patients' in file_info['filename'].lower():
            count = loader.load_patients(file_info['local_path'])
            return count
    
    return 0


def load_medical_records(**context):
    """Load medical records data"""
    files = context['ti'].xcom_pull(key='downloaded_files', task_ids='extract_from_s3')
    loader = PostgresLoader()
    
    for file_info in files:
        if 'medical_records' in file_info['filename'].lower() or 'records' in file_info['filename'].lower():
            count = loader.load_medical_records(file_info['local_path'])
            return count
    
    return 0


def load_triage_visits(**context):
    """Load triage visits data"""
    files = context['ti'].xcom_pull(key='downloaded_files', task_ids='extract_from_s3')
    loader = PostgresLoader()
    
    for file_info in files:
        if 'triage' in file_info['filename'].lower():
            count = loader.load_triage_visits(file_info['local_path'])
            return count
    
    return 0


def generate_ids_transform(**context):
    """Transform staging data to production with ID generation"""
    generator = IDGenerator()
    results = generator.transform_all()
    
    context['ti'].xcom_push(key='transform_results', value=results)
    
    return results


def archive_processed_files(**context):
    """Archive processed files in S3"""
    files = context['ti'].xcom_pull(key='downloaded_files', task_ids='extract_from_s3')
    extractor = S3Extractor()
    
    archived_count = 0
    for file_info in files:
        try:
            extractor.archive_file(file_info['s3_key'])
            archived_count += 1
        except Exception as e:
            print(f"Failed to archive {file_info['filename']}: {str(e)}")
    
    return archived_count


# Define tasks
task_extract = PythonOperator(
    task_id='extract_from_s3',
    python_callable=extract_from_s3,
    dag=dag,
)

task_load_facilities = PythonOperator(
    task_id='load_facilities',
    python_callable=load_facilities,
    dag=dag,
)

task_load_patients = PythonOperator(
    task_id='load_patients',
    python_callable=load_patients,
    dag=dag,
)

task_load_medical_records = PythonOperator(
    task_id='load_medical_records',
    python_callable=load_medical_records,
    dag=dag,
)

task_load_triage_visits = PythonOperator(
    task_id='load_triage_visits',
    python_callable=load_triage_visits,
    dag=dag,
)

task_transform = PythonOperator(
    task_id='generate_ids_transform',
    python_callable=generate_ids_transform,
    dag=dag,
)

task_dbt_run = BashOperator(
    task_id='dbt_run',
    bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir /root/.dbt',
    dag=dag,
)

task_dbt_test = BashOperator(
    task_id='dbt_test',
    bash_command='cd /opt/airflow/dbt && dbt test --profiles-dir /root/.dbt',
    dag=dag,
)

task_archive = PythonOperator(
    task_id='archive_processed_files',
    python_callable=archive_processed_files,
    dag=dag,
)

# Define task dependencies
task_extract >> [task_load_facilities, task_load_patients, task_load_medical_records, task_load_triage_visits]
[task_load_facilities, task_load_patients] >> task_load_medical_records
[task_load_facilities, task_load_patients] >> task_load_triage_visits
[task_load_medical_records, task_load_triage_visits] >> task_transform
task_transform >> task_dbt_run >> task_dbt_test >> task_archive