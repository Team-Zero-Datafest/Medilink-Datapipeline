-- Triage trends analysis for data analysts
-- Time-series analysis of triage patterns

with daily_triage as (
    select
        date(visit_date) as visit_date,
        facility_id,
        facility_state,
        facility_category,
        triage_level,
        priority_category,
        patient_age_group,
        patient_sex,
        count(*) as visit_count
    from {{ ref('fct_triage_visits') }}
    where visit_date >= current_date - interval '90 days'
    group by 
        date(visit_date), facility_id, facility_state, facility_category,
        triage_level, priority_category, patient_age_group, patient_sex
),

state_daily_totals as (
    select
        visit_date,
        facility_state,
        sum(visit_count) as total_visits,
        avg(case when priority_category = 'Critical' then visit_count else 0 end) as avg_critical_visits,
        sum(case when triage_level <= 2 then visit_count else 0 end) as critical_count,
        sum(case when triage_level = 3 then visit_count else 0 end) as urgent_count,
        sum(case when triage_level >= 4 then visit_count else 0 end) as non_urgent_count
    from daily_triage
    group by visit_date, facility_state
),

moving_averages as (
    select
        visit_date,
        facility_state,
        total_visits,
        critical_count,
        urgent_count,
        non_urgent_count,
        
        -- 7-day moving averages
        avg(total_visits) over (
            partition by facility_state 
            order by visit_date 
            rows between 6 preceding and current row
        ) as ma_7_day_visits,
        
        avg(critical_count) over (
            partition by facility_state 
            order by visit_date 
            rows between 6 preceding and current row
        ) as ma_7_day_critical,
        
        -- Week over week comparison
        lag(total_visits, 7) over (
            partition by facility_state 
            order by visit_date
        ) as visits_7_days_ago
        
    from state_daily_totals
),

final as (
    select
        visit_date,
        facility_state,
        total_visits,
        critical_count,
        urgent_count,
        non_urgent_count,
        round(ma_7_day_visits, 1) as ma_7_day_visits,
        round(ma_7_day_critical, 1) as ma_7_day_critical,
        
        -- Percentage calculations
        round(100.0 * critical_count / nullif(total_visits, 0), 1) as pct_critical,
        round(100.0 * urgent_count / nullif(total_visits, 0), 1) as pct_urgent,
        round(100.0 * non_urgent_count / nullif(total_visits, 0), 1) as pct_non_urgent,
        
        -- Week over week growth
        case
            when visits_7_days_ago > 0 then
                round(100.0 * (total_visits - visits_7_days_ago) / visits_7_days_ago, 1)
            else null
        end as wow_growth_pct,
        
        -- Day of week
        to_char(visit_date, 'Day') as day_name,
        extract(dow from visit_date) as day_of_week,
        
        current_timestamp as dbt_updated_at
        
    from moving_averages
)

select * from final
order by facility_state, visit_date