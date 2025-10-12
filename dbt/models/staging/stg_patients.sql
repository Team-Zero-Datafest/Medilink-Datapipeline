-- Staging model for patients
-- Cleans and standardizes patient data

with source as (
    select * from {{ source('public', 'patients') }}
),

cleaned as (
    select
        id as patient_id,
        facility_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        upper(trim(sex)) as sex,
        dob as date_of_birth,
        trim(phone) as phone_number,
        created_at,
        
        -- Add derived fields
        concat(trim(first_name), ' ', trim(last_name)) as full_name,
        
        -- Calculate age
        date_part('year', age(current_date, dob)) as age_years,
        
        -- Age groups
        case
            when date_part('year', age(current_date, dob)) < 1 then 'Infant'
            when date_part('year', age(current_date, dob)) between 1 and 12 then 'Child'
            when date_part('year', age(current_date, dob)) between 13 and 17 then 'Adolescent'
            when date_part('year', age(current_date, dob)) between 18 and 64 then 'Adult'
            else 'Senior'
        end as age_group,
        
        -- Phone validation
        case
            when phone is not null and length(phone) > 8 then true
            else false
        end as has_valid_phone
        
    from source
    where dob is not null
)

select * from cleaned