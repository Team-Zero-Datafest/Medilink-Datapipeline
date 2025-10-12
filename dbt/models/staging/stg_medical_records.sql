-- Staging model for medical records
-- Cleans and standardizes medical record data

with source as (
    select * from {{ source('public', 'medical_records') }}
),

cleaned as (
    select
        id as record_id,
        patient_id,
        facility_id,
        trim(record_type) as record_type,
        data as record_data,
        created_at,
        updated_at,
        
        -- Extract common fields from JSONB
        data->>'diagnosis' as diagnosis,
        data->>'treatment' as treatment,
        data->>'medications' as medications,
        data->>'notes' as clinical_notes,
        
        -- Record metadata
        case
            when created_at = updated_at then false
            else true
        end as is_updated,
        
        date_part('day', age(updated_at, created_at)) as days_since_creation
        
    from source
)

select * from cleaned