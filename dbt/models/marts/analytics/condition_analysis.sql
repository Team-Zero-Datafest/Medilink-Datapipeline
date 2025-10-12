-- Condition and diagnosis analysis for analysts
-- Analysis of common conditions and diagnoses

with triage_conditions as (
    select
        unnest(likely_conditions) as condition,
        facility_state,
        patient_age_group,
        patient_sex,
        triage_level,
        priority_category,
        date_trunc('month', visit_date) as month
    from {{ ref('fct_triage_visits') }}
    where likely_conditions is not null
        and visit_date >= current_date - interval '12 months'
),

condition_summary as (
    select
        condition,
        facility_state,
        patient_age_group,
        patient_sex,
        month,
        count(*) as occurrence_count,
        avg(triage_level) as avg_triage_level,
        count(*) filter (where priority_category = 'Critical') as critical_count
    from triage_conditions
    where condition is not null and trim(condition) != ''
    group by condition, facility_state, patient_age_group, patient_sex, month
),

condition_totals as (
    select
        condition,
        sum(occurrence_count) as total_occurrences,
        count(distinct facility_state) as states_affected,
        count(distinct month) as months_present,
        round(avg(avg_triage_level), 2) as overall_avg_triage_level,
        sum(critical_count) as total_critical_cases
    from condition_summary
    group by condition
),

ranked_conditions as (
    select
        ct.*,
        row_number() over (order by total_occurrences desc) as rank_by_frequency,
        row_number() over (order by overall_avg_triage_level asc) as rank_by_severity,
        round(100.0 * total_occurrences / sum(total_occurrences) over (), 2) as pct_of_total
    from condition_totals ct
    where ct.total_occurrences >= 5  -- Filter out rare conditions
),

final as (
    select
        condition,
        total_occurrences,
        pct_of_total,
        overall_avg_triage_level,
        total_critical_cases,
        round(100.0 * total_critical_cases / nullif(total_occurrences, 0), 1) as pct_critical,
        states_affected,
        months_present,
        rank_by_frequency,
        rank_by_severity,
        
        case
            when overall_avg_triage_level <= 2 then 'High Severity'
            when overall_avg_triage_level <= 3 then 'Medium Severity'
            else 'Low Severity'
        end as severity_category,
        
        case
            when total_occurrences >= 100 then 'Very Common'
            when total_occurrences >= 50 then 'Common'
            when total_occurrences >= 20 then 'Moderate'
            else 'Rare'
        end as frequency_category,
        
        current_timestamp as dbt_updated_at
        
    from ranked_conditions
)

select * from final
order by total_occurrences desc