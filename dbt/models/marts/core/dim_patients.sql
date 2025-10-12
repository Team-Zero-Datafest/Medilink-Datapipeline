-- Dimension table for patients
-- Provides complete patient information for analysis

with patients as (
    select * from {{ ref('stg_patients') }}
),

facilities as (
    select * from {{ ref('stg_facilities') }}
),

patient_records as (
    select
        patient_id,
        count(*) as total_records,
        count(distinct record_type) as distinct_record_types,
        min(created_at) as first_record_date,
        max(created_at) as last_record_date
    from {{ ref('stg_medical_records') }}
    group by patient_id
),

patient_triage as (
    select
        patient_id,
        count(*) as total_triage_visits,
        min(triage_level) as min_triage_level,
        max(triage_level) as max_triage_level,
        avg(triage_level) as avg_triage_level,
        max(visit_date) as last_triage_date
    from {{ ref('stg_triage_visits') }}
    group by patient_id
),

final as (
    select
        p.patient_id,
        p.facility_id,
        f.facility_name,
        f.state as facility_state,
        f.lga as facility_lga,
        p.first_name,
        p.last_name,
        p.full_name,
        p.sex,
        p.date_of_birth,
        p.age_years,
        p.age_group,
        p.phone_number,
        p.has_valid_phone,
        p.created_at as patient_created_at,
        
        -- Medical record metrics
        coalesce(pr.total_records, 0) as total_medical_records,
        coalesce(pr.distinct_record_types, 0) as distinct_record_types,
        pr.first_record_date,
        pr.last_record_date,
        
        -- Triage metrics
        coalesce(pt.total_triage_visits, 0) as total_triage_visits,
        pt.min_triage_level,
        pt.max_triage_level,
        round(pt.avg_triage_level, 2) as avg_triage_level,
        pt.last_triage_date,
        
        -- Activity indicators
        case
            when pr.last_record_date >= current_date - interval '90 days' then true
            else false
        end as is_active_last_90_days,
        
        case
            when pt.last_triage_date >= current_date - interval '30 days' then true
            else false
        end as has_recent_triage,
        
        -- Health risk indicators
        case
            when pt.min_triage_level <= 2 then true
            else false
        end as has_critical_triage_history,
        
        current_timestamp as dbt_updated_at
        
    from patients p
    left join facilities f on p.facility_id = f.facility_id
    left join patient_records pr on p.patient_id = pr.patient_id
    left join patient_triage pt on p.patient_id = pt.patient_id
)

select * from final