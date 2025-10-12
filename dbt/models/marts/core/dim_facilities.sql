-- Dimension table for facilities
-- Provides complete facility information for analysis

with facilities as (
    select * from {{ ref('stg_facilities') }}
),

facility_metrics as (
    select
        facility_id,
        count(distinct patient_id) as total_patients,
        min(created_at) as first_patient_date,
        max(created_at) as last_patient_date
    from {{ ref('stg_patients') }}
    group by facility_id
),

triage_metrics as (
    select
        facility_id,
        count(*) as total_triage_visits,
        avg(triage_level) as avg_triage_level
    from {{ ref('stg_triage_visits') }}
    group by facility_id
),

final as (
    select
        f.facility_id,
        f.facility_name,
        f.state,
        f.lga,
        f.latitude,
        f.longitude,
        f.facility_type,
        f.facility_category,
        f.has_coordinates,
        f.created_at as facility_created_at,
        
        -- Metrics
        coalesce(fm.total_patients, 0) as total_patients,
        coalesce(tm.total_triage_visits, 0) as total_triage_visits,
        round(coalesce(tm.avg_triage_level, 0), 2) as avg_triage_level,
        
        fm.first_patient_date,
        fm.last_patient_date,
        
        -- Activity indicators
        case
            when fm.last_patient_date >= current_date - interval '30 days' then true
            else false
        end as is_active_last_30_days,
        
        case
            when fm.total_patients > 0 then true
            else false
        end as has_patients,
        
        current_timestamp as dbt_updated_at
        
    from facilities f
    left join facility_metrics fm on f.facility_id = fm.facility_id
    left join triage_metrics tm on f.facility_id = tm.facility_id
)

select * from final