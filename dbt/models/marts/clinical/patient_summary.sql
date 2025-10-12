-- Patient clinical summary for analysts
-- Comprehensive view of patient medical history

with patients as (
    select * from {{ ref('dim_patients') }}
),

recent_records as (
    select
        patient_id,
        array_agg(distinct record_type order by record_type) as record_types,
        array_agg(distinct diagnosis order by diagnosis) filter (where diagnosis is not null) as diagnoses,
        max(created_at) as last_record_date
    from {{ ref('fct_medical_records') }}
    where created_at >= current_date - interval '12 months'
    group by patient_id
),

recent_triage as (
    select
        patient_id,
        array_agg(distinct unnest(likely_conditions) order by unnest(likely_conditions)) as conditions,
        max(triage_level) as most_severe_triage,
        max(visit_date) as last_triage_date
    from {{ ref('fct_triage_visits') }}
    where visit_date >= current_date - interval '12 months'
    group by patient_id
),

final as (
    select
        p.patient_id,
        p.full_name,
        p.age_years,
        p.age_group,
        p.sex,
        p.facility_name,
        p.facility_state,
        p.phone_number,
        
        -- Medical history
        p.total_medical_records,
        p.total_triage_visits,
        rr.record_types as recent_record_types,
        rr.diagnoses as recent_diagnoses,
        rt.conditions as recent_conditions,
        
        -- Risk assessment
        p.has_critical_triage_history,
        rt.most_severe_triage as most_severe_triage_last_year,
        
        -- Activity
        p.is_active_last_90_days,
        p.has_recent_triage,
        p.last_record_date,
        p.last_triage_date,
        rr.last_record_date as last_record_date_12mo,
        rt.last_triage_date as last_triage_date_12mo,
        
        -- Patient engagement score (0-100)
        least(100, (
            case when p.has_valid_phone then 20 else 0 end +
            case when p.total_medical_records > 0 then 30 else 0 end +
            case when p.is_active_last_90_days then 30 else 0 end +
            case when p.has_recent_triage then 20 else 0 end
        )) as engagement_score,
        
        current_timestamp as dbt_updated_at
        
    from patients p
    left join recent_records rr on p.patient_id = rr.patient_id
    left join recent_triage rt on p.patient_id = rt.patient_id
)

select * from final