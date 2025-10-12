-- Facility performance metrics for analysts
-- KPIs and operational metrics by facility

with facilities as (
    select * from {{ ref('dim_facilities') }}
),

monthly_visits as (
    select
        facility_id,
        date_trunc('month', visit_date) as month,
        count(*) as triage_visits,
        count(distinct patient_id) as unique_patients,
        avg(triage_level) as avg_triage_level,
        count(*) filter (where triage_level <= 2) as critical_visits,
        count(*) filter (where triage_level >= 4) as low_priority_visits
    from {{ ref('fct_triage_visits') }}
    where visit_date >= current_date - interval '12 months'
    group by facility_id, date_trunc('month', visit_date)
),

monthly_records as (
    select
        facility_id,
        date_trunc('month', created_at) as month,
        count(*) as medical_records,
        count(distinct patient_id) as unique_patients_with_records
    from {{ ref('fct_medical_records') }}
    where created_at >= current_date - interval '12 months'
    group by facility_id, date_trunc('month', created_at)
),

recent_activity as (
    select
        facility_id,
        count(*) as visits_last_30_days,
        avg(triage_level) as avg_triage_level_30d,
        count(*) filter (where triage_level <= 2) as critical_visits_30d
    from {{ ref('fct_triage_visits') }}
    where visit_date >= current_date - interval '30 days'
    group by facility_id
),

final as (
    select
        f.facility_id,
        f.facility_name,
        f.state,
        f.lga,
        f.facility_category,
        f.total_patients,
        f.total_triage_visits,
        f.avg_triage_level as overall_avg_triage_level,
        
        -- Recent activity (30 days)
        coalesce(ra.visits_last_30_days, 0) as visits_last_30_days,
        round(coalesce(ra.avg_triage_level_30d, 0), 2) as avg_triage_level_30d,
        coalesce(ra.critical_visits_30d, 0) as critical_visits_30d,
        
        -- Calculate averages from monthly data (12 months)
        round(avg(mv.triage_visits), 0) as avg_monthly_visits,
        round(avg(mv.unique_patients), 0) as avg_monthly_unique_patients,
        round(avg(mv.avg_triage_level), 2) as avg_monthly_triage_level,
        round(avg(mr.medical_records), 0) as avg_monthly_records,
        
        -- Performance indicators
        case
            when f.total_patients > 100 and f.is_active_last_30_days then 'High Volume'
            when f.total_patients between 50 and 100 and f.is_active_last_30_days then 'Medium Volume'
            when f.total_patients < 50 and f.is_active_last_30_days then 'Low Volume'
            else 'Inactive'
        end as volume_category,
        
        case
            when coalesce(ra.avg_triage_level_30d, 5) <= 2.5 then 'High Acuity'
            when coalesce(ra.avg_triage_level_30d, 5) between 2.5 and 3.5 then 'Medium Acuity'
            else 'Low Acuity'
        end as acuity_category,
        
        f.is_active_last_30_days,
        f.has_coordinates,
        
        current_timestamp as dbt_updated_at
        
    from facilities f
    left join monthly_visits mv on f.facility_id = mv.facility_id
    left join monthly_records mr on f.facility_id = mr.facility_id and mv.month = mr.month
    left join recent_activity ra on f.facility_id = ra.facility_id
    group by 
        f.facility_id, f.facility_name, f.state, f.lga, f.facility_category,
        f.total_patients, f.total_triage_visits, f.avg_triage_level,
        f.is_active_last_30_days, f.has_coordinates,
        ra.visits_last_30_days, ra.avg_triage_level_30d, ra.critical_visits_30d
)

select * from final