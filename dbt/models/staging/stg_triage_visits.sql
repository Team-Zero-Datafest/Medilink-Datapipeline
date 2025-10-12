-- Staging model for triage visits
-- Cleans and standardizes triage visit data

with source as (
    select * from {{ source('public', 'triage_visits') }}
),

cleaned as (
    select
        id as triage_id,
        patient_id,
        facility_id,
        triage_level,
        likely_conditions,
        recommendations,
        trim(language) as language_code,
        trim(provider) as provider_name,
        created_at as visit_date,
        
        -- Triage level descriptions
        case triage_level
            when 1 then 'Emergency - Immediate'
            when 2 then 'Very Urgent - 10 minutes'
            when 3 then 'Urgent - 30 minutes'
            when 4 then 'Less Urgent - 60 minutes'
            when 5 then 'Non-Urgent - 120 minutes'
            else 'Unknown'
        end as triage_description,
        
        -- Priority categorization
        case
            when triage_level <= 2 then 'Critical'
            when triage_level = 3 then 'High'
            when triage_level = 4 then 'Medium'
            else 'Low'
        end as priority_category,
        
        -- Extract condition count
        case
            when likely_conditions is not null then array_length(likely_conditions, 1)
            else 0
        end as condition_count,
        
        -- Extract recommendation count
        case
            when recommendations is not null then array_length(recommendations, 1)
            else 0
        end as recommendation_count
        
    from source
    where triage_level between 1 and 5
)

select * from cleaned