-- Row Counts --
use strava_app;
select 'daily_activity' as table_name, count(*) as row_count from daily_activity
union all select  'daily_calories', count(*) from daily_calories
union all select 'daily_intensities', count(*) from daily_intensities
union all select 'daily_steps', count(*) from daily_steps
union all select 'hourly_calories', count(*) from hourly_calories
union all select 'hourly_intensities', count(*) from hourly_intensities
union all select 'hourly_steps', count(*) from hourly_steps
union all select 'minute_calories_wide', count(*) from minute_calories_wide
union all select 'minute_intensities_wide', count(*) from minute_intensities_wide
union all select 'minute_steps_wide', count(*) from minute_steps_wide
union all select 'minute_sleep', count(*) from minute_sleep
union all select 'sleep_day', count(*) from sleep_day
union all select 'weight_log', count(*) from weight_log
union all select 'heartrate_seconds', count(*) from heartrate_seconds
union all select 'minute_steps_narrow', count(*) from minute_steps_narrow;

-- Unique users per table --
select 'daily_activity'      as table_name, count(distinct Id) as unique_users from daily_activity
union all select 'hourly_steps', count(distinct Id) from hourly_steps
union all select 'minute_sleep', count(distinct Id) from minute_sleep
union all select 'sleep_day', count(distinct Id) from sleep_day
union all select 'weight_log', count(distinct Id) from weight_log
union all select 'heartrate_seconds', count(distinct Id) from heartrate_seconds
union all select 'minute_steps_narrow', count(distinct Id) from minute_steps_narrow;

-- Date Range --
select 'daily_activity' as table_name, min(ActivityDate) as start_date, max(ActivityDate) as end_date from daily_activity
union all select 'sleep_day', min(SleepDay), max(SleepDay) from sleep_day
union all select 'weight_log', min(Date), max(Date) from weight_log
union all select 'heartrate_seconds', min(Time), max(Time) from heartrate_seconds;

-- Null check in daily_activity --
select
    sum(case when Id is null then 1 else 0 end) as null_Id,
    sum(case when ActivityDate is null then 1 else 0 end) as null_Date,
    sum(case when TotalSteps is null then 1 else 0 end) as null_Steps,
    sum(case when Calories is null then 1 else 0 end) as null_Calories,
    sum(case when SedentaryMinutes is null then 1 else 0 end) as null_SedentaryMins,
    sum(case when TotalDistance is null then 1 else 0 end) as null_Distance
from daily_activity;

-- null check in weight_log --
select
    count(*) as total_rows,
    sum(case when Fat is null then 1 else 0 end) as null_Fat,
    sum(case when BMI is null then 1 else 0 end) as null_BMI,
    sum(case when WeightKg is null then 1 else 0 end) as null_WeightKg
from weight_log;

-- duplicate check in daily_activity --
select
    Id,
    ActivityDate,
    count(*) as occurrences
from daily_activity
group by Id, ActivityDate
having count(*) > 1;

-- duplicate check in sleep_day --
select
    Id,
    SleepDay,
    count(*) as occurrences
from sleep_day
group by Id, SleepDay
having count(*) > 1;

-- Removing sleep dpulicates -- 
create table sleep_day_clean as
select *
from sleep_day
where (Id, SleepDay) in (
    select Id, MIN(SleepDay)
    from sleep_day
    group by Id, SleepDay
);

select
    (select count(*) from sleep_day) as original_rows,
    (select count(*) from sleep_day_clean) as clean_rows,
    (select count(*) from sleep_day)
    - (select count(*) from sleep_day_clean) as duplicates_removed;

-- checking for out of range values --
select
    min(TotalSteps) as min_steps,
    max(TotalSteps) as max_steps,
    min(Calories) as min_calories,
    max(Calories) as max_calories,
    min(SedentaryMinutes) as min_sedentary_mins,
    max(SedentaryMinutes) as max_sedentary_mins,
    min(VeryActiveMinutes) as min_very_active_mins,
    max(VeryActiveMinutes) as max_very_active_mins
from daily_activity;

-- zero step days --
select
    count(*) as zero_step_days,
    count(distinct Id) as users_affected,
    round (count(*) * 100.0 / (select count(*) from daily_activity), 1) as pct_of_all_days
from daily_activity
where TotalSteps = 0;

-- full sedentary days --
select
    count(*) as full_sedentary_days,
    count(distinct Id) as users_affected,
    round(count(*) * 100.0 / (select count(*) from daily_activity), 1) as pct_of_all_days
from daily_activity
where SedentaryMinutes >= 1440;

-- daily_activity --
alter table daily_activity
    add column ActivityDate_clean  date,
    add column DayOfWeek varchar(10),
    add column TotalActiveMinutes  int;

update daily_activity
set ActivityDate_clean = STR_TO_DATE(ActivityDate, '%m/%d/%Y'),
    TotalActiveMinutes = VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes;

update daily_activity
set DayOfWeek = DAYNAME(ActivityDate_clean);

select 'daily_activity done' as status,
       count(*) as rows_updated
from daily_activity
where ActivityDate_clean is not null;

-- hourly_steps --
alter table hourly_steps
    add column ActivityHour_clean datetime,
    add column DayOfWeek varchar(10),
    add column HourOfDay tinyint;

update hourly_steps
set ActivityHour_clean = STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p'),
    DayOfWeek = dayname(STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p')),
    HourOfDay = hour(STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p'));

select 'hourly_steps done' as status,
       count(*) as rows_updated
from hourly_steps
where ActivityHour_clean is not null;

-- hourly_calories --
alter table hourly_calories
    add column ActivityHour_clean datetime,
    add column HourOfDay tinyint;

update hourly_calories
set ActivityHour_clean = STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p'),
    HourOfDay = hour(STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p'));

select 'hourly_calories done' as status,
       count(*) as rows_updated
from hourly_calories
where ActivityHour_clean is not null;

-- hourly_intensities --
alter table hourly_intensities
    add column ActivityHour_clean datetime,
    add column HourOfDay tinyint;

update hourly_intensities
set ActivityHour_clean = STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p'),
    HourOfDay = hour(STR_TO_DATE(ActivityHour, '%m/%d/%Y %h:%i:%s %p'));

select 'hourly_intensities done' as status,
       count(*) as rows_updated
from hourly_intensities
where ActivityHour_clean is not null;

-- sleep_day_clean --
alter table sleep_day_clean
    add column SleepDay_clean date,
    add column DayOfWeek varchar(10),
    add column SleepHours float,
    add column MinsToFallAsleep int;

update sleep_day_clean
set SleepDay_clean    = date(STR_TO_DATE(SleepDay, '%m/%d/%Y %h:%i:%s %p')),
    DayOfWeek = dayname(date(STR_TO_DATE(SleepDay, '%m/%d/%Y %h:%i:%s %p'))),
    SleepHours = round(TotalMinutesAsleep / 60.0, 2),
    MinsToFallAsleep  = TotalTimeInBed - TotalMinutesAsleep;

select 'sleep_day_clean done' as status,
       count(*) as rows_updated
from sleep_day_clean
where SleepDay_clean is not null;

-- weight_log --
alter table weight_log
    add column Date_clean date;

update weight_log
set Date_clean = date(STR_TO_DATE(Date, '%m/%d/%Y %h:%i:%s %p'));

select 'weight_log done' as status,
       count(*) as rows_updated
from weight_log
where Date_clean is not null;

-- heartrate_seconds --
alter table heartrate_seconds
    add column Time_clean datetime,
    add column HourOfDay  tinyint;

update heartrate_seconds
set Time_clean = STR_TO_DATE(time, '%m/%d/%Y %h:%i:%s %p'),
    HourOfDay  = hour(STR_TO_DATE(Time, '%m/%d/%Y %h:%i:%s %p'));

select 'heartrate_seconds done' as status,
       count(*) as rows_updated
from heartrate_seconds
where Time_clean is not null;

-- overall activity summary --
select
    count(distinct Id) as total_users,
    count(*) as total_days_logged,
    round(avg(TotalSteps), 0) as avg_daily_steps,
    round(avg(TotalDistance), 2) as avg_daily_distance_km,
    round(avg(Calories), 0) as avg_daily_calories,
    round(avg(VeryActiveMinutes), 1) as avg_very_active_mins,
    round(avg(FairlyActiveMinutes), 1) as avg_fairly_active_mins,
    round(avg(LightlyActiveMinutes), 1) as avg_lightly_active_mins,
    round(avg(SedentaryMinutes), 1) as avg_sedentary_mins,
    round(avg(SedentaryMinutes) / 60.0, 1) as avg_sedentary_hours,
    round(avg(TotalActiveMinutes), 1) as avg_total_active_mins,
    sum(case when TotalSteps >= 10000 then 1 else 0 end) as days_met_10k_goal,
    round(sum(case when TotalSteps >= 10000 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_days_met_10k_goal
from daily_activity
where TotalSteps > 0;

-- Average steps by day of week --
select
    DayOfWeek,
    round(avg(TotalSteps), 0) as avg_steps,
    round(avg(Calories), 0) as avg_calories,
    round(avg(TotalActiveMinutes), 1) as avg_active_mins,
    round(avg(SedentaryMinutes), 1) as avg_sedentary_mins,
    count(*) as days_recorded
from daily_activity
where TotalSteps > 0
group by DayOfWeek
order by FIELD(DayOfWeek,
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
    
-- Activities by minutes breakdown --
select
    round(avg(SedentaryMinutes), 1) as avg_sedentary_mins,
    round(avg(SedentaryMinutes)/60, 2) as avg_sedentary_hours,
    round(avg(LightlyActiveMinutes), 1) as avg_lightly_active_mins,
    round(avg(FairlyActiveMinutes), 1) as avg_fairly_active_mins,
    round(avg(VeryActiveMinutes), 1) as avg_very_active_mins,
    round(avg(TotalActiveMinutes), 1) as avg_total_active_mins,
    round(avg(SedentaryMinutes) * 100.0
        / (avg(SedentaryMinutes) + avg(TotalActiveMinutes)), 1) as pct_time_sedentary,
    round(avg(TotalActiveMinutes) * 100.0
        / (avg(SedentaryMinutes) + avg(TotalActiveMinutes)), 1) as pct_time_active
from daily_activity
where TotalSteps > 0;

-- binning steps vs calories -- 
select
    case
        when TotalSteps < 2500  then '1. Under 2,500'
        when TotalSteps < 5000  then '2. 2,500 – 5,000'
        when TotalSteps < 7500  then '3. 5,000 – 7,500'
        when TotalSteps < 10000 then '4. 7,500 – 10,000'
        when TotalSteps < 12500 then '5. 10,000 – 12,500'
        else '6. 12,500+'
    end as steps_bucket,
    count(*) as days,
    round(avg(Calories), 0) as avg_calories,
    round(avg(TotalActiveMinutes), 1) as avg_active_mins,
    round(avg(SedentaryMinutes), 1) as avg_sedentary_mins
from daily_activity
where TotalSteps > 0
group by steps_bucket
order by steps_bucket;

-- user activity level classification --
select
    Id,
    round(avg(TotalSteps), 0) as avg_daily_steps,
    round(avg(Calories), 0) as avg_daily_calories,
    round(avg(SedentaryMinutes), 1) as avg_sedentary_mins,
    round(avg(VeryActiveMinutes), 1) as avg_very_active_mins,
    count(*) as days_logged,
    round(sum(case when TotalSteps >= 10000 then 1 else 0 end)
        * 100.0 /count(*), 1) as pct_days_met_10k,
    case
        when avg(TotalSteps) < 5000  then 'Sedentary'
        when avg(TotalSteps) < 7500  then 'Low Active'
        when avg(TotalSteps) < 10000 then 'Somewhat Active'
        when avg(TotalSteps) < 12500 then 'Active'
        else 'Highly Active'
    end as activity_level
from daily_activity
where TotalSteps > 0
group by Id
order by avg_daily_steps desc;

-- activity level distribution -- 
select
    activity_level,
    count(*) as user_count,
    round(count(*) * 100.0 / sum(count(*)) over(), 1) as pct_of_users,
    round(avg(avg_daily_steps), 0) as avg_steps_in_group,
    round(avg(avg_daily_calories), 0) as avg_calories_in_group
from (
    select
        Id,
        avg(TotalSteps) as avg_daily_steps,
        avg(Calories) as avg_daily_calories,
        case
             when avg(TotalSteps) < 5000  then 'Sedentary'
            when avg(TotalSteps) < 7500  then 'Low Active'
            when avg(TotalSteps) < 10000 then 'Somewhat Active'
            when avg(TotalSteps) < 12500 then 'Active'
            else 'Highly Active'
        end as activity_level
    from daily_activity
    where TotalSteps > 0
    group by Id
) user_levels
group by activity_level
order by FIELD(activity_level,
    'Sedentary','Low Active','Somewhat Active','Active','Highly Active');
    
-- top 5 most and least active users --
select ranking, Id, avg_steps, avg_calories, avg_very_active_mins
from (
    select 'Most Active' as ranking, Id,
           round(avg(TotalSteps), 0) as avg_steps,
           round(avg(Calories), 0) as avg_calories,
           round(avg(VeryActiveMinutes), 1) as avg_very_active_mins,
           row_number() over (order by round(avg(TotalSteps), 0) desc) as rn,
           1 as sort_order
    from daily_activity
    where TotalSteps > 0
    group by Id
    union all
    select 'Least Active', Id,
           round(avg(TotalSteps), 0),
           round(avg(Calories), 0),
           round(avg(VeryActiveMinutes), 1),
           row_number() over (order by round(avg(TotalSteps), 0) asc),
           2
    from daily_activity
    where TotalSteps > 0
    group by Id
) ranked
where rn <= 5
order by sort_order, avg_steps desc;

-- Average steps by hour of day -- 
select
    HourOfDay,
    round(avg(StepTotal), 0) as avg_steps,
    count(*) as record_count
from hourly_steps
where HourOfDay is not null
group by HourOfDay
order by HourOfDay;

-- average calories by hour of day --
select
    HourOfDay,
    round(avg(Calories), 1) as avg_calories
from hourly_calories
where HourOfDay is not null
group by HourOfDay
order by HourOfDay;

-- top 5 peak activity hours --
select
    hs.HourOfDay,
    round(avg(hs.StepTotal), 0) as avg_steps,
    round(avg(hc.Calories), 1) as avg_calories,
    round(avg(hi.TotalIntensity), 1) as avg_intensity
from hourly_steps hs
join hourly_calories hc
  on hs.Id = hc.Id
 and hs.ActivityHour_clean = hc.ActivityHour_clean
join hourly_intensities hi
  on hs.Id = hi.Id
 and hs.ActivityHour_clean = hi.ActivityHour_clean
group by hs.HourOfDay
order by avg_steps desc
limit 5;

-- steps by hour and day of week --
select
    hs.DayOfWeek,
    hs.HourOfDay,
    ROUND(avg(hs.StepTotal), 0) as avg_steps,
    round(avg(hc.Calories), 1) as avg_calories,
    round(avg(hi.TotalIntensity), 1) as avg_intensity
from hourly_steps hs
join hourly_calories hc
  on hs.Id = hc.Id
 and hs.ActivityHour_clean = hc.ActivityHour_clean
join hourly_intensities hi
  on hs.Id = hi.Id
 and hs.ActivityHour_clean = hi.ActivityHour_clean
group by hs.DayOfWeek, hs.HourOfDay
order by field(hs.DayOfWeek,
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    hs.HourOfDay;
    
    -- activity by time period --
    select
    case
        when hs.HourOfDay between 5 and 11 then '1. Morning (5am–11am)'
        when hs.HourOfDay between 12 and 16 then '2. Afternoon (12pm–4pm)'
        when hs.HourOfDay between 17 and 20 then '3. Evening (5pm–8pm)'
        when hs.HourOfDay between 21 and 23 then '4. Night (9pm–11pm)'
        else '5. Late Night (12am–4am)'
    end as time_period,
    round(avg(hs.StepTotal), 0) as avg_steps,
    round(avg(hc.Calories), 1) as avg_calories,
    round(avg(hi.TotalIntensity), 1) as avg_intensity,
    count(*) as record_count
from hourly_steps hs
join hourly_calories hc
  on hs.Id = hc.Id
 and hs.ActivityHour_clean = hc.ActivityHour_clean
join hourly_intensities hi
  on hs.Id = hi.Id
 and hs.ActivityHour_clean = hi.ActivityHour_clean
group by time_period
order by time_period;

SELECT
    COUNT(*)        AS row_count,
    MIN(SleepHours) AS min_sleep_hrs,
    MAX(SleepHours) AS max_sleep_hrs,
    ROUND(AVG(SleepHours), 2) AS avg_sleep_hrs
FROM sleep_day_clean
WHERE SleepHours IS NOT NULL;

-- overall sleep summary --
select
    count(distinct Id) as users_with_sleep_data,
    count(*) as total_nights_logged,
    round(avg(SleepHours), 2) as avg_sleep_hours,
    round(min(SleepHours), 2) as min_sleep_hours,
    round(max(SleepHours), 2) as max_sleep_hours,
    round(avg(MinsToFallAsleep), 1) as avg_mins_to_fall_asleep,
    round(avg(TotalTimeInBed) / 60.0, 2) as avg_time_in_bed_hours,
    sum(case when SleepHours >= 7 then 1 else 0 end) as nights_met_7hr_goal,
    round(sum(case when SleepHours >= 7 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_met_7hr_goal,
    sum(case when SleepHours >= 8 then 1 else 0 end) as nights_met_8hr_goal,
    round(sum(case when SleepHours >= 8 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_met_8hr_goal
from sleep_day_clean;

-- sleep by day of week --
select
    DayOfWeek,
    round(avg(SleepHours), 2) as avg_sleep_hours,
    round(avg(TotalTimeInBed / 60.0), 2) as avg_time_in_bed_hours,
    round(avg(MinsToFallAsleep), 1) as avg_mins_to_fall_asleep,
    count(*) as nights_recorded
from sleep_day_clean
group by DayOfWeek
order by FIELD(DayOfWeek,
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
    
    -- sleep quality per user --
    select
    Id,
    count(*) as nights_logged,
    round(avg(SleepHours), 2) as avg_sleep_hours,
    round(avg(MinsToFallAsleep), 1) as avg_mins_to_fall_asleep,
    sum(case when SleepHours < 6 then 1 else 0 end) as nights_under_6hrs,
    sum(case when SleepHours between 7 and 9
						then 1 else 0 end) as nights_ideal_7_to_9hrs,
    sum(case when SleepHours > 9 then 1 else 0 end) as nights_over_9hrs,
    case
        when avg(SleepHours) < 6 then 'Poor (<6h)'
        when avg(SleepHours) < 7 then 'Insufficient (6–7h)'
        when avg(SleepHours) <= 9 then 'Ideal (7–9h)'
        else 'Oversleeping (>9h)'
    end as sleep_quality
from sleep_day_clean
group by Id
order by avg_sleep_hours desc;

-- minute level sleep state breakdown --
select
    case value
        when 1 then '1 - Asleep'
        when 2 then '2 - Restless'
        when 3 then '3 - Awake'
    end as sleep_state,
    count(*) as total_minutes,
    round(count(*) * 100.0 /
        (select count(*) from minute_sleep), 2) as pct_of_total
from minute_sleep
group by value
order by value;

-- sleep state per user --
select
    Id,
    sum(case when value = 1 then 1 else 0 end) as mins_asleep,
    sum(case when value = 2 then 1 else 0 end) as mins_restless,
    sum(case when value = 3 then 1 else 0 end) as mins_awake,
    count(*) as total_mins_tracked,
    round(sum(case when value = 1 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_asleep,
    round(sum(case when value = 2 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_restless,
    round(sum(case when value = 3 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_awake
from minute_sleep
group by Id
order by pct_asleep desc;
 
 -- sleep quality vs next day activity --
 select
    case
        when sc.SleepHours < 6  then '1. Poor (<6h)'
        when sc.SleepHours < 7  then '2. Low (6–7h)'
        when sc.SleepHours <= 9 then '3. Good (7–9h)'
        else '4. Long (>9h)'
    end as sleep_category,
    count(*) as days,
    round(avg(da.TotalSteps), 0) as avg_next_day_steps,
    round(avg(da.Calories), 0) as avg_next_day_calories,
    round(avg(da.SedentaryMinutes), 1) as avg_next_day_sedentary_mins,
    round(avg(da.VeryActiveMinutes), 1) as avg_next_day_very_active_mins
from sleep_day_clean sc
join daily_activity da
  on sc.Id = da.Id
 and sc.SleepDay_clean = da.ActivityDate_clean
where da.TotalSteps > 0
group by sleep_category
order by sleep_category;

-- weight overview --
select
    count(distinct Id) as users_logged_weight,
    count(*) as total_entries,
    round(avg(WeightKg), 1) as avg_weight_kg,
    round(min(WeightKg), 1) as min_weight_kg,
    round(max(WeightKg), 1) as max_weight_kg,
    round(avg(BMI), 1) as avg_bmi,
    round(min(BMI), 1) as min_bmi,
    round(max(BMI), 1) as max_bmi,
    sum(case when IsManualReport = 'True'  then 1 else 0 end) as manual_entries,
    sum(case when IsManualReport = 'False' then 1 else 0 end) as auto_entries
from weight_log;

-- BMI classification per user -- 
select
    Id,
    round(avg(WeightKg), 1) as avg_weight_kg,
    round(avg(BMI), 1) as avg_bmi,
    case
        when avg(BMI) < 18.5 then 'Underweight'
        when avg(BMI) between 18.5 and 24.9 then 'Normal'
        when avg(BMI) between 25.0 and 29.9 then 'Overweight'
        else 'Obese'
    end as bmi_category,
    count(*) as entries_logged
from weight_log
group by Id
order by avg_bmi;

-- manual vs auto logging --
select
    IsManualReport as log_method,
    count(*) as entry_count,
    round(count(*) * 100.0 / (select count(*) from weight_log), 1) as pct_of_total
from weight_log
group by IsManualReport;

-- weight trend per user over time --
select
    Id,
    Date_clean as log_date,
    WeightKg as weight_kg,
    BMI as bmi,
    IsManualReport as manual_entry
from weight_log
order by Id, Date_clean;

-- overall heartrate summary --
select
    count(distinct Id) as users_with_hr_data,
    round(avg(value), 1) as avg_bpm,
    min(Value) as min_bpm,
    max(Value) as max_bpm,
    round(STDDEV(Value), 1) as std_dev_bpm
from heartrate_seconds;

-- Average heart rate per user -- 
select
    Id,
    round(avg(Value), 1) as avg_bpm,
    min(Value) as min_bpm,
    max(Value) as max_bpm,
    round(avg(case when HourOfDay between 0 and 5
			then Value end), 1) as est_resting_bpm
from heartrate_seconds
group by Id
order by avg_bpm;

-- overall distribution of hear rate zone --
select
    case
        when Value < 90  then '1. Rest / Recovery  (<90 bpm)'
        when Value < 108 then '2. Fat Burn         (90–107 bpm)'
        when Value < 126 then '3. Aerobic          (108–125 bpm)'
        when Value < 153 then '4. Cardio           (126–152 bpm)'
        else '5. Peak (153+ bpm)'
    end as hr_zone,
    count(*) as seconds_in_zone,
    round(count(*) * 100.0 /
        (select count(*) from heartrate_seconds), 2) as pct_of_time
from heartrate_seconds
group by hr_zone
order by hr_zone;

-- heart rate zones per user --
select
    Id,
    round(avg(Value), 1) as avg_bpm,
    round(sum(case when Value < 90
			then 1 else 0 end) * 100.0 / COUNT(*), 1) as pct_zone1_rest,
    round(sum(case when Value between 90 and 107
				then 1 else 0 end) * 100.0 / COUNT(*), 1) as pct_zone2_fat_burn,
    round(sum(case when Value between 108 and 125
				then 1 else 0 end) * 100.0 / COUNT(*), 1) as pct_zone3_aerobic,
    round(sum(case when Value between 126 and 152
				then 1 else 0 end) * 100.0 / COUNT(*), 1) as pct_zone4_cardio,
    round(sum(case when Value >= 153
			then 1 else 0 end) * 100.0 / COUNT(*), 1) as pct_zone5_peak
from heartrate_seconds
group by Id
order by avg_bpm desc;

-- average heart rate by hour of day --
select
    HourOfDay,
    round(avg(Value), 1) as avg_bpm,
    round(min(Value), 1) as min_bpm,
    round(max(Value), 1) as max_bpm
from heartrate_seconds
group by HourOfDay
order by HourOfDay;

-- days logged per user --
select
    Id,
    count(*) as total_days,
    sum(case when TotalSteps > 0 then 1 else 0 end) as active_days,
    sum(case when TotalSteps = 0 then 1 else 0 end) as zero_step_days,
    round(sum(case when TotalSteps > 0 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_active_days,
    case
        when count(*) >= 28 then'High (28–31 days)'
        when count(*) >= 21 then'Moderate (21–27 days)'
        when count(*) >= 14 then'Low (14–20 days)'
        else 'Very Low (<14 days)'
    end as usage_tier
from daily_activity
group by Id
order by total_days desc;

-- usage tier distribution --
select
    usage_tier,
    count(*) as user_count,
    round(count(*) * 100.0 /
        (select count(distinct Id) from daily_activity), 1) as pct_of_users
from (
    select Id,
        case
            when count(*) >= 28 then'High (28–31 days)'
            when count(*) >= 21 then'Moderate (21–27 days)'
            when count(*) >= 14 then 'Low (14–20 days)'
            else 'Very Low (<14 days)'
        end as usage_tier
    from daily_activity
    group by Id
) t
group by usage_tier
order by user_count desc;

-- feature adoption --
select
    da.Id,
    case when sl.Id is not null then 'Yes' else 'No' end as tracks_sleep,
    case when wl.Id is not null then 'Yes' else 'No' end as tracks_weight,
    case when hr.Id is not null then 'Yes' else 'No' end as tracks_heart_rate
from (select distinct Id from daily_activity) da
left join (select distinct Id from sleep_day_clean)   sl on da.Id = sl.Id
left join (select distinct Id from weight_log) wl on da.Id = wl.Id
left join (select distinct Id from heartrate_seconds) hr on da.Id = hr.Id
order by tracks_sleep desc, tracks_weight desc, tracks_heart_rate desc;

-- feature adoption summary --
select
    tracks_sleep,
    tracks_weight,
    tracks_heart_rate,
    count(*) as user_count,
    round(count(*) * 100.0 /
        (select count(distinct Id) from daily_activity), 1) as pct_of_users
from (
    select
        da.Id,
        case when sl.Id is not null then 'Yes' else 'No' end as tracks_sleep,
        case when wl.Id is not null then 'Yes' else'No' end as tracks_weight,
        case when hr.Id is not null then 'Yes' else 'No' end as tracks_heart_rate
    from (select distinct Id from daily_activity) da
    left join (select distinct Id from sleep_day_clean) sl on da.Id = sl.Id
    left join (select distinct Id from weight_log) wl on da.Id = wl.Id
    left join (select distinct Id from heartrate_seconds) hr on da.Id = hr.Id
) t
group by tracks_sleep, tracks_weight, tracks_heart_rate
order by user_count desc;

-- -- steps vs sleep quality --
select
    round(avg(case when sc.SleepHours >= 7
			then da.TotalSteps end), 0) as avg_steps_good_sleep,
    ROUND(avg(case when sc.SleepHours < 7
                   then da.TotalSteps end), 0) as avg_steps_poor_sleep,
    ROUND(avg(case when sc.SleepHours >= 7
                   then da.Calories end), 0) as avg_cal_good_sleep,
    ROUND(avg(case when sc.SleepHours < 7
                   then da.Calories end), 0) as avg_cal_poor_sleep,
    ROUND(avg(case when sc.SleepHours >= 7
                   then da.SedentaryMinutes end), 1) as avg_sedentary_good_sleep,
    ROUND(avg(case when sc.SleepHours < 7
				then da.SedentaryMinutes end), 1) as avg_sedentary_poor_sleep
from sleep_day_clean sc
join daily_activity da
  on sc.Id = da.Id
 and sc.SleepDay_clean = da.ActivityDate_clean
where da.TotalSteps > 0;

-- sedentary time vs sleep qality --
SELECT
    CASE
        WHEN da.SedentaryMinutes < 600  THEN '1. Low Sedentary (<10h)'
        WHEN da.SedentaryMinutes < 800  THEN '2. Moderate (10–13h)'
        WHEN da.SedentaryMinutes < 1000 THEN '3. High (13–17h)'
        ELSE                                 '4. Very High (>17h)'
    END                                                     AS sedentary_category,
    COUNT(*)                                                AS days,
    ROUND(AVG(sc.SleepHours), 2)                           AS avg_sleep_hours,
    ROUND(AVG(da.TotalSteps), 0)                           AS avg_steps,
    ROUND(AVG(da.Calories), 0)                             AS avg_calories
FROM daily_activity da
JOIN sleep_day_clean sc
  ON da.Id = sc.Id
 AND da.ActivityDate_clean = sc.SleepDay_clean
WHERE da.TotalSteps > 0
GROUP BY sedentary_category
ORDER BY sedentary_category;

-- activity level vs BMI --
select
    activity_level,
    round(avg(avg_bmi), 1) as avg_bmi,
    round(avg(avg_weight_kg), 1) as avg_weight_kg,
    count(distinct Id) as users
from (
    select
        da.Id,
        wl.BMI as avg_bmi,
        wl.WeightKg as avg_weight_kg,
        case
            when avg(da.TotalSteps) < 5000  then 'Sedentary'
            when avg(da.TotalSteps) < 7500  then 'Low Active'
            when avg(da.TotalSteps) < 10000 then 'Somewhat Active'
            when avg(da.TotalSteps) < 12500 then 'Active'
            else 'Highly Active'
        end as activity_level
    from daily_activity da
    join weight_log wl on da.Id = wl.Id
    where da.TotalSteps > 0
    group by da.Id, wl.BMI, wl.WeightKg
) classified
group by activity_level
order by FIELD(activity_level,
    'Sedentary','Low Active','Somewhat Active','Active','Highly Active');
    
    -- heart rate vs activity level --
    select
    ul.activity_level,
    round(avg(hr.Value), 1) as avg_bpm,
    count(distinct hr.Id) as users
from heartrate_seconds hr
join (
    select Id,
        case
            when avg(TotalSteps) < 5000  then'Sedentary'
            when avg(TotalSteps) < 7500  then 'Low Active'
            when avg(TotalSteps) < 10000 then 'Somewhat Active'
            when avg(TotalSteps) < 12500 then 'Active'
            else 'Highly Active'
        end as activity_level
    from daily_activity
    where TotalSteps > 0
    group by Id
) ul on hr.Id = ul.Id
group by ul.activity_level
order by FIELD(ul.activity_level,
    'Sedentary','Low Active','Somewhat Active','Active','Highly Active');

-- BMI category vs sleep hours --
select
    case
        when wl.BMI < 18.5 then '1. Underweight (<18.5)'
        when wl.BMI between 18.5 and 24.9 then '2. Normal (18.5–24.9)'
        when wl.BMI between 25.0 and 29.9 then '3. Overweight (25–29.9)'
        else '4. Obese (30+)'
    end as bmi_category,
    count(distinct sc.Id) as users,
    round(avg(sc.SleepHours), 2) as avg_sleep_hours,
    round(min(sc.SleepHours), 2) as min_sleep_hours,
    round(max(sc.SleepHours), 2) as max_sleep_hours,
    round(avg(sc.MinsToFallAsleep), 1) as avg_mins_to_fall_asleep,
    sum(case when sc.SleepHours >= 7
					then 1 else 0 end) as nights_met_7hr_goal,
    round(sum(case when sc.SleepHours >= 7
			then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_met_7hr_goal
from weight_log wl
join sleep_day_clean sc on wl.Id = sc.Id
group by bmi_category
order by bmi_category;

-- BMI vs sleep quality category --
select
    case
        when wl.BMI < 18.5 then '1. Underweight (<18.5)'
        when wl.BMI between 18.5 and 24.9 then '2. Normal (18.5–24.9)'
        when wl.BMI between 25.0 and 29.9 then '3. Overweight (25–29.9)'
        else '4. Obese (30+)'
    end as bmi_category,
    case
        when sc.SleepHours < 6  then '1. Poor (<6h)'
        when sc.SleepHours < 7  then '2. Insufficient (6–7h)'
        when sc.SleepHours <= 9 then '3. Ideal (7–9h)'
        else '4. Oversleeping (>9h)'
    end as sleep_quality,
    count(*) as nights,
    round(avg(wl.BMI), 1) as avg_bmi,
    round(avg(sc.SleepHours), 2) as avg_sleep_hours
from weight_log wl
join sleep_day_clean sc on wl.Id = sc.Id
group by bmi_category, sleep_quality
order by bmi_category, sleep_quality;

-- per user BMI vs sleep --
select
    wl.Id,
    round(avg(wl.BMI), 1) as avg_bmi,
    case
        when avg(wl.BMI) < 18.5 then 'Underweight'
        when avg(wl.BMI) between 18.5 and 24.9 then 'Normal'
        when avg(wl.BMI) between 25.0 and 29.9 then 'Overweight'
        else 'Obese'
    end as bmi_category,
    round(avg(sc.SleepHours), 2) as avg_sleep_hours,
    round(avg(sc.MinsToFallAsleep), 1) as avg_mins_to_fall_asleep,
    case
        when avg(sc.SleepHours) < 6 then 'Poor (<6h)'
        when avg(sc.SleepHours) < 7 then 'Insufficient (6–7h)'
        when avg(sc.SleepHours) <= 9 then 'Ideal (7–9h)'
        else 'Oversleeping (>9h)'
    end as sleep_quality,
    round(avg(da.TotalSteps), 0) as avg_daily_steps,
    round(avg(da.SedentaryMinutes), 1) as avg_sedentary_mins
from weight_log wl
join sleep_day_clean sc on wl.Id = sc.Id
join daily_activity da on wl.Id = da.Id
                        and sc.SleepDay_clean = da.ActivityDate_clean
where da.TotalSteps > 0
group by wl.Id
order by avg_bmi desc;

-- user segmentation --
select
    da.Id,
    round(avg(da.TotalSteps), 0) as avg_daily_steps,
    round(avg(da.TotalDistance), 2) as avg_distance_km,
    round(avg(da.Calories), 0) as avg_daily_calories,
    round(avg(da.VeryActiveMinutes), 1) as avg_very_active_mins,
    round(avg(da.SedentaryMinutes), 1) as avg_sedentary_mins,
    count(distinct da.ActivityDate) as days_logged,
    round(sum(case when da.TotalSteps >= 10000
                 then 1 else 0 end)
        * 100.0 / count(*), 1) as pct_days_met_10k,
    round(avg(sc.SleepHours), 2) as avg_sleep_hours,
    round(avg(sc.MinsToFallAsleep), 1) as avg_mins_to_fall_asleep,
    round(avg(wl.BMI), 1) as avg_bmi,
    round(avg(hr.avg_bpm), 1) as avg_bpm,
    case
        when avg(da.TotalSteps) < 5000 then 'Sedentary'
        when avg(da.TotalSteps) < 7500 then 'Low Active'
        when avg(da.TotalSteps) < 10000 then 'Somewhat Active'
        when avg(da.TotalSteps) < 12500 then 'Active'
        else 'Highly Active'
    end as activity_level,
    case
        when avg(sc.SleepHours) is null then 'No Sleep Data'
        when avg(sc.SleepHours) < 6 then 'Poor (<6h)'
        when avg(sc.SleepHours) < 7 then 'Insufficient (6–7h)'
        when avg(sc.SleepHours) <= 9 then 'Ideal (7–9h)'
        else 'Oversleeping (>9h)'
    end as sleep_profile
from daily_activity da
left join sleep_day_clean sc
       on da.Id = sc.Id
      and da.ActivityDate_clean = sc.SleepDay_clean
left join weight_log wl
       on da.Id = wl.Id
left join (
    select
        Id,
        avg(Value) as avg_bpm
    from heartrate_seconds
    group by Id
) hr
on da.Id = hr.Id
where da.TotalSteps > 0
group by da.Id
order by avg_daily_steps desc;
