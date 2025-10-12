-- Fact table for medical records
-- Contains all medical record transactions

with medical_records as (
    select * from {{ ref('stg_medical_records') }}
),

patients as (
    select 
        patient_id,
        age_years,
        age_group,
        sex
    from {{ ref('stg_patients') }}
),

facilities as (
    select
        facility_id,
        facility_name,
        state,
        facility_category
    from {{ ref('stg_facilities') }}
),

final as (
    select
        mr.record_id,
        mr.patient_id,
        p.age_years as patient_age,
        p.age_group as patient_age_group,
        p.sex as patient_sex,
        mr.facility_id,
        f.facility_name,
        f.state as facility_state,
        f.facility_category,
        mr.record_type,
        mr.diagnosis,
        mr.treatment,
        mr.medications,
        mr.clinical_notes,
        mr.record_data,
        mr.is_updated,
        mr.days_since_creation,
        mr.created_at,
        mr.updated_at,
        
        -- Date dimensions
        date(mr.created_at) as record_date,
        extract(year from mr.created_at) as record_year,
        extract(month from mr.created_at) as record_month,
        extract(dow from mr.created_at) as record_day_of_week,
        to_char(mr.created_at, 'Day') as record_day_name,
        to_char(mr.created_at, 'Month') as record_month_name,
        
        current_timestamp as dbt_updated_at
        
    from medical_records mr
    left join patients p on mr.patient_id = p.patient_id
    left join facilities f on mr.facility_id = f.facility_id
)

select * from final