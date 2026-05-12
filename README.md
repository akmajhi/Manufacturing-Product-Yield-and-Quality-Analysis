# Manufacturing Product Yield & Quality Analysis

**An end-to-end manufacturing analytics project built on a custom synthetic multi-table dataset — from data design and SQL modeling to a 3-page operational dashboard in Tableau.**

---

## Project Overview

This project was built to simulate a realistic manufacturing environment and demonstrate how raw operational data can be transformed into business-ready insights.

The core idea behind the project is that production quality is never driven by one variable alone. Yield loss can result from machine instability, maintenance delays, sensor drift, environmental variation, operator differences, process conditions, and product complexity. Instead of using a clean and unrealistic dataset, this project was intentionally designed to behave like a real industrial system.

To achieve that, I designed a synthetic manufacturing dataset from scratch, structured it like a production-grade operational database, processed it through PostgreSQL, and built a Tableau dashboard system focused on answering practical manufacturing questions.

The final result is not just a visualization project. It is a complete operational analytics workflow that demonstrates:

- SQL-based analytical modeling
- manufacturing KPI engineering
- operational problem-solving
- dashboard storytelling
- industrial business logic
- data-cleaning strategy
- production-quality reporting workflows

---

## Why I Built This Project

My background in instrumentation and industrial systems strongly influenced the way this project was designed.

In manufacturing environments, the real challenge is rarely just measuring a number. The actual challenge is understanding:

- why the number changed
- what operational factor caused the change
- whether the issue is machine-related, process-related, or human-related
- how the business should respond to it

That mindset shaped the structure of this project.

I wanted to create an analytics workflow that reflects how operational analysis is performed in real production environments:

- identify the business problem
- structure the raw data correctly
- create meaningful operational KPIs
- validate patterns through analysis
- build dashboards that support decision-making instead of only visualization

This project combines industrial domain understanding with analytics and business intelligence to create a realistic manufacturing quality analysis system.

---

## Business Questions Behind the Dashboard

The dashboard system is organized around three operational questions.

### Dashboard 1 — Company Production Health

**Business Question:**

> Is the factory operating efficiently, and where is quality loss happening at the business level?

This dashboard provides an executive-level overview of production health using KPIs such as yield percentage, production volume, defect concentration, throughput efficiency, and environmental risk.

---

### Dashboard 2 — Machine & Sensor Health

**Business Question:**

> Does maintenance improve reliability, and do sensor patterns reveal early signs of failure?

This dashboard focuses on machine reliability, maintenance impact, sensor instability, downtime behavior, and pre-defect operational patterns.

The analysis is designed around operational logic commonly used in instrumentation and reliability engineering.

---

### Dashboard 3 — Human Factors

**Business Question:**

> Do operator experience, certifications, shift patterns, and inspector behavior influence production quality?

This dashboard studies workforce-related variation and evaluates whether human operational factors measurably affect quality performance.

---

## Dataset Design Philosophy

The dataset used in this project is synthetic, but it was intentionally designed using realistic manufacturing logic instead of random value generation.

The goal was to simulate how industrial systems actually behave under operational conditions.

To make the analysis realistic, the dataset includes intentionally engineered data-quality challenges such as:

- approximately 30% null rates in selected sensor channels
- duplicate records caused by clock skew
- JSON-encoded maintenance and defect fields
- outlier process behavior
- sensor drift before failures
- noisy inspection labels
- class imbalance in the quality target variable
- operational variability between machines and operators

The relationships between maintenance, machine reliability, environmental conditions, product specifications, and quality outcomes were designed intentionally so the data would behave realistically during:

- EDA
- dashboard analysis
- KPI reporting
- statistical testing
- root-cause analysis

The complete dataset-generation methodology is documented in:

```text
/dataset_generation_logic.pdf
```

The statistical profile of all six tables is documented in:

```text
/data_overview.pdf
```

---

## Database Schema

The project uses six interconnected tables, each representing one operational layer of a manufacturing information system.

### `sensor_readings`

High-frequency machine telemetry used for:

- sensor drift analysis
- anomaly detection
- operational stability monitoring
- pre-defect signal analysis

Contains intentional missingness, outliers, and duplicate records to simulate real telemetry systems.

---

### `production_log`

The central operational table linking:

- machines
- operators
- products
- shifts
- environmental conditions
- production timing

One row represents one production batch or production run.

---

### `quality_inspection`

Stores final production inspection results including:

- pass/fail target (`pin_holes`)
- defect counts
- defect categories
- severity scoring

This table acts as the primary quality outcome layer.

---

### `maintenance_log`

Contains preventive and corrective maintenance events including:

- maintenance timing
- downtime duration
- maintenance type
- replaced parts

Used to analyze maintenance effectiveness and reliability behavior.

---

### `operators`

Contains workforce-related operational information such as:

- experience level
- certifications
- training dates

Supports human-factor analysis and operator-level quality evaluation.

---

### `product_catalog`

Stores product specifications including:

- product family
- tolerance limits
- recommended operating speed

Used to evaluate product-level production sensitivity and process variation.

---

## Repository Structure

```text
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

## SQL Pipeline — File by File

### `01_create_tables.sql`

Creates all six tables using appropriate PostgreSQL data types. This establishes the core database structure required for the analytical workflow.

---

### `02_create_foreign_keys.sql`

Adds foreign key relationships after data loading to preserve referential integrity across production, quality, maintenance, product, and operator tables.

---

### `03_data_cleaning_and_type_corrections.sql`

Handles critical data-cleaning operations including:

- duplicate removal
- JSONB transformation
- type standardization
- extraction of defect and maintenance flags

This step converts semi-structured operational data into Tableau-ready analytical fields.

---

### `04_feature_engineering.sql`

Creates analytical features required for downstream reporting and KPI analysis.

Key engineered features include:

- `duration_minutes`
- `production_date`
- `days_since_maint`
- `last_maint_type`
- `is_outlier`

These features support:

- maintenance decay analysis
- throughput monitoring
- operational efficiency studies
- sensor anomaly detection

---

### `05_view_master_production.sql`

The central analytical view containing one row per production run.

This view combines all major operational layers into a single dashboard-ready structure and calculates:

- throughput
- production speed efficiency
- environmental risk
- speed deviation metrics

This is the primary data source for the Company Health and Human Factors dashboards.

---

### `06_view_machine_reliability.sql`

Machine-level summary view containing:

- MTBF
- MTTR
- PM compliance
- downtime breakdown
- maintenance performance
- machine-level defect rates

Used as the primary data source for the Machine & Sensor Health dashboard.

---

### `07_view_operator_summary.sql`

Operator-level summary view containing:

- career defect rate
- average failure severity
- production volume
- shift distribution
- operational deviation metrics

Supports workforce and operator-performance analysis.

---

### `08_view_sensor_pre_defect.sql`

Creates a labeled sensor-analysis view that compares sensor behavior between:

- defect days
- normal production days

This view supports pre-defect signal analysis and early-warning pattern identification for predictive maintenance workflows.

---

## Dashboard

The complete dashboard system is published on Tableau Public.

### Tableau Public Dashboard

🔗 https://public.tableau.com/views/Manfr_YA/Dashboard-A?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

Use the Tableau tabs to navigate between all three dashboards.

---

### Dashboard 1 — Company Production Health

![Dashboard 1](dashboard/01_dashboard_company_production.png)

---

### Dashboard 2 — Machine & Sensor Health

![Dashboard 2](dashboard/02_dashboard_machine_sensor.png)

---

### Dashboard 3 — Human Factors

![Dashboard 3](dashboard/03_dashboard_human_factors.png)

---

## Key Operational Findings

- Machines with delayed maintenance periods showed higher defect concentration and operational instability.
- Preventive maintenance correlated with lower downtime and more stable production performance.
- Sensor vibration and temperature patterns increased before several defect-heavy production periods.
- Environmental instability amplified defect probability during high-speed production conditions.
- Operator experience reduced severe defect frequency, but machine condition remained the stronger quality driver overall.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL | Data storage, cleaning, analytical SQL, and view modeling |
| pgAdmin / DBeaver | Database development and query management |
| Tableau Desktop | Dashboard design and visualization |
| Tableau Public | Dashboard publishing and sharing |

The workflow is intentionally SQL-first because many manufacturing BI environments rely on SQL-based analytical pipelines before dashboard consumption.

---

## What I Learned Building This

This project reinforced the difference between designing systems for transactions and designing systems for analysis.

Transactional databases are optimized for operational integrity. Analytical systems must instead be structured around the business questions they need to answer. That often requires engineered features, aggregations, and reporting layers that improve analytical clarity and performance.

The project also reinforced how strongly domain knowledge affects interpretation.

For example, rising vibration trends are not just numerical patterns in a manufacturing environment. They can indicate bearing wear, instability, or an approaching mechanical failure. Translating those technical signals into understandable business insights is one of the most important parts of operational analytics.

---

## Author

### Adarsh Kumar Majhi

**Instrumentation Engineer | Data Analyst | Industrial Analytics**

This project reflects my interest in connecting industrial domain knowledge with data analytics to solve operational quality, reliability, and manufacturing performance problems using structured analytical systems.

- LinkedIn: https://www.linkedin.com/in/adarshkmajhi/

---

If you work in manufacturing analytics, operational intelligence, industrial IoT, or reliability engineering and want to discuss the type of work represented in this project, feel free to connect.
