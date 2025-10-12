-- Fact table for triage visits
-- Contains all triage visit transactions

with triage_visits as (
    select * from {{ ref('stg_triage_visits') }}
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
        tv.triage_id,
        tv.patient_id,
        p.age_years as patient_age,
        p.age_group as patient_age_group,
        p.sex as patient_sex,
        tv.facility_id,
        f.facility_name,
        f.state as facility_state,
        f.facility_category,
        tv.triage_level,
        tv.triage_description,
        tv.priority_category,
        tv.likely_conditions,
        tv.recommendations,
        tv.condition_count,
        tv.recommendation_count,
        tv.language_code,
        tv.provider_name,
        tv.visit_date,
        
        -- Date dimensions
        date(tv.visit_date) as visit_date_only,
        extract(year from tv.visit_date) as visit_year,
        extract(month from tv.visit_date) as visit_month,
        extract(dow from tv.visit_date) as visit_day_of_week,
        to_char(tv.visit_date, 'Day') as visit_day_name,
        to_char(tv.visit_date, 'Month') as visit_month_name,
        extract(hour from tv.visit_date) as visit_hour,
        
        -- Time of day classification
        case
            when extract(hour from tv.visit_date) between 6 and 11 then 'Morning'
            when extract(hour from tv.visit_date) between 12 and 17 then 'Afternoon'
            when extract(hour from tv.visit_date) between 18 and 21 then 'Evening'
            else 'Night'
        end as time_of_day,
        
        current_timestamp as dbt_updated_at
        
    from triage_visits tv
    left join patients p on tv.patient_id = p.patient_id
    left join facilities f on tv.facility_id = f.facility_id
)

select * from final