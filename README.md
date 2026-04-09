# Strava-app-user-analysis
End-to-end health data analytics project using SQL and Power BI to transform Fitbit user activity into actionable product insights and health recommendations
# Strava Fitness Data Analytics Case Study

## Project Overview
This project involves a deep-dive analysis of fitness tracker data (Fitbit) to uncover trends in physical activity, sleep patterns, and health metrics. By analyzing 30+ days of data from 33 users, I identified key gaps between user behaviour and global health benchmarks, providing actionable recommendations for product engagement.

## Tools & Tech Stack
* **SQL (MySQL):** Managed a complex schema of 15 tables; performed data transformation and aggregation.
* **Power BI:** Developed a multi-page interactive dashboard for executive and health-specific views.
* **Data Storytelling:** Compiled a comprehensive PDF report linking data trends to product strategy.

## Key Insights & Findings
* **The Activity Gap:** Average daily steps were 8,319—**17% below** the recommended 10,000-step benchmark.
* **Sedentary Risk:** Users averaged **15.9 hours of sedentary time** per day, a critical area for product intervention.
* **Sleep Quality:** Average sleep was ~7 hours, nearly an hour below the recommended 8-hour health standard.
* **High Retention:** 82% of users tracked their data consistently for the full month, showing high platform loyalty.

## Dashboard Previews
### Executive Overview
![Executive Overview](./images/Executive%20Overview.png)

### Sleep & Health Metrics
![Sleep Analysis](./images/Sleep%20Analysis.png)

## Recommendations
* **Automated Prompts:** Implement "Inactivity Alerts" during peak sedentary windows (10 AM – 2 PM) to encourage movement.
* **Personalized Sleep Coaching:** Develop in-app notifications based on the identified correlation between late-day high intensity and reduced sleep quality.
* **Tiered Goal Setting:** Shift from a static 10k step goal to "Dynamic Targets" to prevent user burnout and maintain engagement.

## How to Navigate this Repo
* **[SQL Scripts](./sql/strava_app_file.sql):** Contains the full workflow from table creation to complex joins for user profiling.
* **[Full Report](./docs/Strava_App_Project_Document.pdf):** A detailed PDF outlining the methodology, constraints, and strategic conclusions.

---
**Author:** Madhuresh Raj Selvaraj
