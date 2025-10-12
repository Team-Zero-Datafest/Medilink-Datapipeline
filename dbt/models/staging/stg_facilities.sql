-- Staging model for facilities
-- Cleans and standardizes facility data

with source as (
    select * from {{ source('public', 'facilities') }}
),

cleaned as (
    select
        id as facility_id,
        trim(name) as facility_name,
        upper(trim(state)) as state,
        trim(lga) as lga,
        lat as latitude,
        lon as longitude,
        trim(type) as facility_type,
        created_at,
        
        -- Add derived fields
        case
            when type ilike '%hospital%' then 'Hospital'
            when type ilike '%clinic%' then 'Clinic'
            when type ilike '%center%' or type ilike '%centre%' then 'Health Center'
            when type ilike '%pharmacy%' then 'Pharmacy'
            else 'Other'
        end as facility_category,
        
        case
            when lat is not null and lon is not null then true
            else false
        end as has_coordinates
        
    from source
)

select * from cleaned