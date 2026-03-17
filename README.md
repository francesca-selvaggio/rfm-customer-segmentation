# RFM Customer Segmentation

**Tools:** SQL (SQLite), Google Sheets, Power BI  
**Dataset:** [Online Retail II — UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii)  
**Rows analysed:** 805,620 (after data cleaning)  
**Customers segmented:** 5,881



## Dashboard Preview

Built in Power BI Desktop. ![RFM Dashboard](powerbi/dashboard\_preview.png)



Shows segment distribution, KPI cards, revenue by segment, and customer map (Recency vs Monetary).



## Goal

Segment an e-commerce customer base using the **RFM framework** (Recency, Frequency, Monetary) to identify high-value customers, detect churn risk, and support a data-driven retention strategy.

This project demonstrates end-to-end analytical thinking: from raw transactional data to actionable business recommendations.



## Data Cleaning

The raw dataset contained 1,067,371 rows. Before analysis, the following filters were applied in SQL:

* Removed rows with `Quantity ≤ 0` (returns and adjustments)
* Removed rows with missing `Customer ID`
* Removed rows with `Price ≤ 0`

**Result:** 805,620 valid rows retained across 5,881 unique customers.



## RFM Methodology

RFM scores were computed for each customer using a **reference date of 2011-12-10** (the day after the last transaction in the dataset).

|Metric|Definition|SQL Function|
|-|-|-|
|**Recency**|Days since last purchase|`JULIANDAY(ref) - JULIANDAY(MAX(InvoiceDate))`|
|**Frequency**|Number of distinct invoices|`COUNT(DISTINCT Invoice)`|
|**Monetary**|Total revenue generated|`SUM(Quantity * Price)`|

Each metric was scored 1–5 using **quartile-based NTILE(4)** in SQL, yielding real data-driven thresholds rather than arbitrary cutoffs.

### Scoring thresholds (derived from actual data distribution)

|Score|Recency (days)|Frequency (invoices)|Monetary (£)|
|-|-|-|-|
|5|≤ 26|≥ 7|≥ 2,308|
|4|≤ 96|≥ 3|≥ 899|
|3|≤ 380|≥ 2|≥ 349|
|2|≤ 500|≥ 1|≥ 100|
|1|> 500|< 1|< 100|



## Segmentation Logic

Segments were assigned based on RFM score combinations:

|Segment|Rule|Rationale|
|-|-|-|
|**VIP**|R ≥ 4, F ≥ 4, M ≥ 4, RFM\_total ≥ 14|Recent, frequent, high-spend|
|**Loyal**|R ≥ 3, F ≥ 3, M ≥ 3|Consistent across all dimensions|
|**New Customer**|R ≥ 4, F < 3|Recent but limited purchase history|
|**At Risk**|R < 3, F ≥ 4|Previously engaged, now inactive|
|**Dormant**|All others|Low engagement across dimensions|



## Results

|Segment|Customers|% of Base|
|-|-|-|
|Loyal|2,231|38%|
|Dormant|1,780|31%|
|VIP|1,197|21%|
|New Customer|372|6%|
|At Risk|301|5%|
|**Total**|**5,881**|**100%**|



## Business Recommendations

* ### VIP (21%) - Protect and reward

These customers generate the highest revenue per head. Focus: loyalty programmes, early access, dedicated account management. Risk of losing one VIP = disproportionate revenue impact.

* ### Loyal (38%) - The backbone

The largest group. Upsell and cross-sell opportunities. Nurture with personalised communications to prevent migration to Dormant.

* ### At Risk (5%) - Act fast

High historical frequency, but recently inactive. Targeted win-back campaigns within 30–60 days. A/B test discount vs. content-led re-engagement.

* ### New Customer (6%) - Convert or lose

Recently acquired but low frequency. The first 90 days are critical for habit formation. Focus: onboarding sequences, second-purchase incentives.

* ### Dormant (31%) - Triage

Large group with mixed values. Prioritise reactivation only for those with M\_score ≥ 3. Suppressing the rest of the marketing spend reduces CAC and improves list hygiene.




## Limitations

1. **No product-level data used** — RFM treats all purchases equally, regardless of product category or margin.
2. **Single-country bias** — The majority of transactions are UK-based; global segmentation would require country-level normalisation.
3. **Static snapshot** — RFM is a point-in-time analysis. Scores decay over time and require periodic refresh (recommended: monthly).
4. **NTILE is distribution-sensitive** — Quartile boundaries shift if the dataset composition changes. Thresholds should be recalibrated on new data.




## Repository Structure
```
rfm-customer-segmentation/
├── README.md
├── data/
│   └── rfm_results.csv           # Final scored and segmented customer data
├── sql/
│   └── rfm_analysis.sql          # Full SQL query: cleaning → scoring → segmentation
└── powerbi/
    ├── rfm_dashboard.pbix        # Interactive Power BI dashboard
    └── dashboard_preview.png     # Static preview image
```



## Tools Used

* **SQLite / DB Browser for SQLite:** data cleaning, RFM calculation, scoring, segmentation
* **Google Sheets**: data validation and exploratory review
* **Power BI Desktop**: dashboard and visualisation





## 👤 About

Industrial Engineer (MSc, LIUC University) with 3+ years of experience as a Business/Data Analyst across pharma, luxury fashion, and logistics.  
This project is part of a portfolio demonstrating SQL, data analysis, data visualizations and business thinking skills.

Contacts:

[LinkedIn](https://linkedin.com/in/francesca-selvaggio) - linkedin.com/in/francesca-selvaggio

Email - francesca.selvaggio@outlook.com

