version: 2

sources:
  - name: public
    description: Main PostgreSQL database containing medical records
    tables:
      - name: facilities
        description: Healthcare facilities
        columns:
          - name: id
            description: Primary key for facilities
            tests:
              - unique
              - not_null
      
      - name: patients
        description: Patient records
        columns:
          - name: id
            description: Primary key for patients
            tests:
              - unique
              - not_null
          - name: facility_id
            description: Foreign key to facilities
            tests:
              - not_null
              - relationships:
                  to: source('public', 'facilities')
                  field: id
      
      - name: medical_records
        description: Medical records for patients
        columns:
          - name: id
            description: Primary key for medical records
            tests:
              - unique
              - not_null
          - name: patient_id
            description: Foreign key to patients
            tests:
              - not_null
              - relationships:
                  to: source('public', 'patients')
                  field: id
      
      - name: triage_visits
        description: Triage visit records
        columns:
          - name: id
            description: Primary key for triage visits
            tests:
              - unique
              - not_null
          - name: patient_id
            description: Foreign key to patients
            tests:
              - not_null
              - relationships:
                  to: source('public', 'patients')
                  field: id

models:
  - name: stg_facilities
    description: Cleaned and standardized facility data
    columns:
      - name: facility_id
        description: Unique identifier for facility
        tests:
          - unique
          - not_null
      - name: facility_name
        tests:
          - not_null
      - name: state
        tests:
          - not_null
  
  - name: stg_patients
    description: Cleaned and standardized patient data
    columns:
      - name: patient_id
        description: Unique identifier for patient
        tests:
          - unique
          - not_null
      - name: age_years
        description: Patient age in years
        tests:
          - not_null
  
  - name: stg_medical_records
    description: Cleaned and standardized medical record data
    columns:
      - name: record_id
        description: Unique identifier for medical record
        tests:
          - unique
          - not_null
  
  - name: stg_triage_visits
    description: Cleaned and standardized triage visit data
    columns:
      - name: triage_id
        description: Unique identifier for triage visit
        tests:
          - unique
          - not_null
      - name: triage_level
        description: Triage priority level (1-5)
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3, 4, 5]