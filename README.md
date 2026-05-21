# Manufacturing Product Yield & Quality Analysis

<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)

**A full analytics project built from scratch — six linked tables, a complete SQL pipeline, and a three-page Tableau dashboard that answers real manufacturing questions.**

</div>

---

> **Disclaimer.** I am not a manufacturing expert or a certified data scientist. I am an instrumentation engineer who moved into data analytics and built this project to show how I think about operational problems using data. Everything here reflects my own understanding, my own approach, and the questions I kept asking when I worked on plant floors. If something looks unconventional, it is probably because I approached it from an engineering background rather than a textbook one.

---

## The Business Problem

Factories do not lose quality for one single reason. A batch can fail because the machine is drifting, maintenance happened too late, the speed is off, the environment is unstable, or the operator and inspector behavior is different from run to run.

That is the problem this project tries to answer.

The goal is simple: find the business reasons behind low yield and show them in a dashboard that a manager, engineer, or a analyst can understand without reading a technical report first.

---

## What I Found

Before I explain how everything was built, here is what the analysis actually surfaced.

### Page 1 — Production

<div align="center">

[![Tableau](https://img.shields.io/badge/View%20Live%20Dashboard-Tableau%20Public-E97627?style=for-the-badge&logo=tableau&logoColor=white)](https://public.tableau.com/app/profile/adarsh.kumar.majhi/viz/Manfr_YA/Dashboard-A)

</div>

![Dashboard 1 — Production](dashboard/01_dashboard_company_production.png)

The production page is designed for someone who needs the full picture of factory health in one view. The way to use it is not to read every chart separately. Start with the heatmap at the bottom right, which shows temperature and humidity plotted against defect rate. The dark red cells in that heatmap tell you which environmental conditions are most dangerous for quality. Then look up at the shift bar to see whether those bad conditions are clustered in a specific shift. Then check the defect type Pareto to see whether the failures happening under those conditions are all the same type, like surface cracks or dimensional errors, or whether they are spread across everything. When those three charts point at the same thing, you have found a real pattern, not just noise.

The severity score chart lives on this page because severity is a business impact question, not a technical one. A 15 percent defect rate on severity-2 surface scratches is a very different problem from a 15 percent defect rate on severity-9 structural failures, even though the defect rate number looks identical in both cases.

---

### Page 2 — Machines

![Dashboard 2 — Machines](dashboard/02_dashboard_machine_sensor.png)

The machine page starts with a single chart that I think is the most important one in the entire project. It is called the maintenance decay curve. It groups all 8,000 production runs by how many days had passed since that machine was last serviced, and then shows the defect rate for each group. The bars climb from left to right as maintenance age increases. That climbing pattern is not a coincidence. It is a proof, in plain visual terms, that delaying maintenance directly causes more product failures.

Once you see that pattern, the next question is which machines are the worst offenders. The MTBF chart answers that. MTBF stands for Mean Time Between Failures, and it simply measures how many days a machine runs on average before something breaks unexpectedly. A short MTBF means the machine breaks often. The PMP percentage, which stands for Planned Maintenance Percentage, tells you whether the maintenance team is being proactive or just reacting to things after they break. When you look at MTBF and PMP together for each machine, you can see whether the machines with the most failures are also the ones that receive the least planned maintenance.

The sensor drift chart on this page is the one that comes most directly from my instrumentation background. It compares sensor readings on days when defects were recorded against sensor readings on normal days. What you are looking for is whether vibration or temperature was already elevated on the days before failures showed up. If it was, the sensors were warning us and nobody was reading the warning. That is a pattern any instrumentation engineer will recognise immediately.

---

### Page 3 — People

![Dashboard 3 — People](dashboard/03_dashboard_human_factors.png)

The people page starts with the operator heatmap. Each row in that heatmap is one operator. Each column is a shift, morning, afternoon, or night. The colour of each cell shows that operator's defect rate during that specific shift. The reason this chart exists is that a simple average hides too much. An operator who performs fine on the morning shift but struggles badly on the night shift is a different kind of problem from an operator who is consistently high-risk on every shift. The heatmap shows both patterns at once.

From the heatmap, you can follow the thread in several directions. If a specific operator stands out on night shift, check the experience chart to see how long they have been working. Check the certifications chart to see whether formal training has made a measurable difference to defect rates. And then check the inspector consistency chart, because if the defect rate for a particular inspector is much higher or lower than the others, you have to ask whether the quality data itself is reliable, or whether one inspector is just applying a stricter standard than everyone else.

The factor impact chart at the bottom of this page is the most honest chart in the project. It shows how much each human factor, experience, certifications, shift, and environmental conditions, actually explains the variation in defect rate. If those bars are small, the data is telling you that the human factors in this dataset alone do not fully explain the quality outcomes. That is not a failure of the analysis. That is the analysis telling you what data is still missing, which in a real facility would be engineer setup records, overtime hours, and operator-machine pairing history.

---

## My Thinking Process

This section explains how the project was built and why decisions were made in this order. The direction is intentionally backwards from how most people describe their projects. Most project write-ups start with the data and end with the insight. I started with the insight I was looking for and worked backwards to figure out what data and structure I needed to get there.

### Step 1. Start with the business question

Before I touched any data, I wrote down three questions that I wanted a manager to be able to answer by looking at a single page of the dashboard.

* For the production page the question was: is the factory producing well, and where is quality being lost?
* For the machine page the question was: does maintenance actually help machines run longer and produce better output?
* For the people page the question was: do the humans running this factory make a measurable difference to quality, and do we have enough data to prove it?

Those three questions are what shaped every chart selection, every KPI choice, and every view I built in SQL. If a chart did not directly answer one of those questions, I did not include it.

### Step 2. Design the dashboard before looking at the data

Once the questions were clear, I sketched out what the dashboard needed to show. This sounds backwards. Most people say you should explore the data first and then decide what to show. But if you explore the data first without a question in mind, you end up showing whatever patterns happen to be interesting rather than whatever patterns are actually useful to the business.

Designing the dashboard structure first forced me to think about what the audience needed, not what the data happened to contain.

### Step 3. Design the dataset to answer those questions

Because the dataset for this project is synthetic, meaning I built it from scratch rather than getting it from a real company, I had to design it so that the patterns I wanted to analyse were actually present in the data. That does not mean the data is fabricated in a misleading way. It means the data was generated using real manufacturing logic, with real business rules governing how tables relate to each other, so that when you analyse it the patterns you find are the same kinds of patterns you would find in a real factory dataset.

The full logic behind how the dataset was designed is documented in `dataset_generation_logic.pdf` in this repository. The statistical profile of every column across all six tables is in `data_overview.pdf`.

The raw CSV files are not included in the repository because the full dataset is over 100MB. The documentation is detailed enough to reproduce the dataset if you want to.

### Step 4. Revisit the dashboard design after seeing the data

Once I had the dataset and ran a basic statistical profile on it, I went back and adjusted the dashboard design. The defect rate came out higher than intended because risk factors were stacking in the generator. Some sensor values came out negative because of how random walks work mathematically. Speed efficiency was measuring two things in completely different units and giving a meaningless result. None of that was visible until I actually looked at the data.

This step is where most tutorial projects skip something important. Real analytical work is not linear. You design something, you look at the data, you find that your design does not fit the data, and you adjust. The adjustments I made are documented honestly in the SQL files rather than being hidden.

### Step 5. Build the SQL pipeline

The SQL pipeline has eight files that run in order. Here is what each one does and why it exists.

**01_create_tables.sql** creates all six tables with the correct PostgreSQL data types. Every column that should be a number is stored as a number. Every date is stored as a timestamp. This sounds obvious but it matters because if a date is stored as plain text, you cannot do date arithmetic on it, which means you cannot calculate how long a production run took or how many days passed since the last maintenance service.

**02_create_foreign_keys.sql** connects the tables to each other after the data is loaded. A foreign key is a rule that says a value in one table must exist in another table. For example, every production run must link to a valid product in the product catalog. Running this after the data is loaded rather than during table creation avoids import order problems.

**03_data_cleaning_and_type_corrections.sql** handles two specific problems. The first is that the maintenance and defect fields were originally stored as plain text that happened to look like structured data, specifically as JSON arrays written as text strings. This file converts those into proper JSONB, which is the native format PostgreSQL uses for structured data, and then extracts individual flag columns from them. A flag column is just a 0 or 1 column that answers a yes or no question, like "did this maintenance event involve replacing a bearing?" Those flag columns are what make the Pareto charts in Tableau work without any complex parsing at query time. The second problem is duplicate records in the sensor data, which were introduced by the synthetic generator to simulate the kind of clock skew that happens in real data collection systems. This file finds and removes them.

**04_feature_engineering.sql** adds four physical columns to the production log table that every downstream view depends on. Duration in minutes is calculated from the start and end timestamps. Production date is extracted from the start timestamp as a plain date, which is used to join production runs to their daily sensor readings. Days since maintenance is the most important one. For every production run, this calculation finds the most recent maintenance event on that specific machine before that specific run started and calculates how many days had passed. This is what makes the maintenance decay curve chart possible. Last maintenance type records whether that most recent service was planned or an emergency repair.

**05_view_master_production.sql** builds the main analytical view, which has 8,000 rows, one for every production run. It joins all six tables together and calculates throughput, speed efficiency, speed deviation, and environmental risk in one place. Tableau connects to this view as its primary data source for the production and people pages.

**06_view_machine_reliability.sql** builds a summary with exactly 8 rows, one per machine. It contains MTBF, MTTR, maintenance compliance, downtime breakdown, parts replacement counts, and machine-level defect rate. This view exists separately from the main view because joining maintenance events directly into the production view would multiply rows in a way that corrupts all the aggregations. One machine with ten maintenance events would produce ten copies of every production row for that machine. Keeping this as a separate 8-row view prevents that problem entirely. Tableau connects to this as a secondary data source for the machines page.

**07_view_operator_summary.sql** builds a summary with exactly 15 rows, one per operator. Same separation logic as the machine reliability view. It contains career defect rate, average severity when failing, production volume, shift distribution, and average speed deviation per operator.

**08_view_sensor_pre_defect.sql** exists for one specific purpose. Tableau cannot natively label a production day as a day when defects occurred versus a normal day and then compare sensor readings between those two groups. This view does that labelling in SQL before the data reaches Tableau. It joins daily sensor readings to inspection results and marks each machine-date combination as either a defect day or a normal day. When Tableau receives this data, it can colour the sensor trend lines by that label and immediately show whether vibration or temperature was behaving differently on days when failures were recorded. That chart is the closest thing in this project to predictive maintenance logic, and it exists entirely because the SQL was built to support it.

### Step 6. Connect to Tableau and build the dashboards

Once all four views were working and verified in pgAdmin, they were connected to Tableau as separate data sources. The main production view handles the production and people pages. The machine reliability view handles the machines page. The operator summary view handles the bubble chart on the people page. The sensor pre-defect view handles the sensor drift chart on the machines page.

---

## Repository Structure

```
manufacturing-yield-analysis/
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_create_foreign_keys.sql
│   ├── 03_data_cleaning_and_type_corrections.sql
│   ├── 04_feature_engineering.sql
│   ├── 05_view_master_production.sql
│   ├── 06_view_machine_reliability.sql
│   ├── 07_view_operator_summary.sql
│   └── 08_view_sensor_pre_defect.sql
│
├── dashboard/
│   ├── 01_dashboard_company_production.png
│   ├── 02_dashboard_machine_sensor.png
│   └── 03_dashboard_human_factors.png
│
├── dataset_generation_logic.pdf
├── data_overview.pdf
└── README.md
```

---

## Tools Used

PostgreSQL was used for all data storage, cleaning, and view construction. pgAdmin was the database client. Tableau Desktop was used for dashboard development and Tableau Public for publishing.

There is no Python in this project. No notebooks. No machine learning libraries. The entire analytical pipeline from raw tables to published dashboard runs in SQL and Tableau calculated fields. That is a deliberate choice. Many manufacturing analytics environments are SQL-first, and being able to build production-quality analysis without stepping outside that stack is part of what this project is trying to demonstrate.

---

## Author

<div align="center">

### Adarsh Kumar Majhi

Instrumentation Engineer turned Data Analyst.
I build analysis around operational problems I have actually seen on plant floors.

[![LinkedIn](https://img.shields.io/badge/Connect%20on%20LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/adarshkmajhi/)

*If you work in manufacturing analytics, industrial IoT, or operational intelligence and want to talk about this kind of work, I would be glad to connect.*

</div>

---

<div align="center">

If this project was useful or interesting to you, feel free to star the repository.

</div>
