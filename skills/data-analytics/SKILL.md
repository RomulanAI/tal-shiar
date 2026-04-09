---
name: data-analytics
description: Data wrangling, EDA, visualization, and analytical workflows
trigger: data analysis, EDA, visualization, dashboard, pandas, SQL, plot, chart, data wrangling
---

# Data Analytics

## Workflow

1. **Ingest** — load data (CSV, Parquet, SQL, API)
2. **Profile** — shape, types, nulls, distributions, outliers
3. **Clean** — handle missing values, fix types, deduplicate
4. **Explore** — univariate, bivariate, correlation, segmentation
5. **Analyze** — hypothesis testing, modeling, aggregation
6. **Communicate** — visualize, narrate, recommend

## Python Stack

### pandas (DataFrames)
```python
import pandas as pd

df = pd.read_csv("data.csv", parse_dates=["date"])
df.info()                          # types, nulls
df.describe(include="all")         # summary stats
df.value_counts("category")       # frequency
df.groupby("region").agg({"revenue": ["sum", "mean", "count"]})
df.pivot_table(values="amount", index="month", columns="category", aggfunc="sum")
```

### polars (fast DataFrames)
```python
import polars as pl

df = pl.read_csv("data.csv")
df.filter(pl.col("amount") > 1000).group_by("category").agg(pl.col("amount").mean())
```

### DuckDB (SQL on files)
```python
import duckdb

duckdb.sql("SELECT region, SUM(revenue) FROM 'sales.parquet' GROUP BY region ORDER BY 2 DESC")
duckdb.sql("SELECT * FROM read_csv_auto('data.csv') WHERE amount > 1000")
```

## SQL Patterns

```sql
-- Window functions
SELECT *,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY date DESC) as rn,
  SUM(amount) OVER (PARTITION BY customer_id) as total_spend,
  LAG(amount) OVER (PARTITION BY customer_id ORDER BY date) as prev_amount
FROM orders;

-- Cohort analysis
WITH first_purchase AS (
  SELECT customer_id, MIN(DATE_TRUNC('month', order_date)) as cohort
  FROM orders GROUP BY 1
)
SELECT cohort,
  DATE_DIFF('month', cohort, DATE_TRUNC('month', o.order_date)) as period,
  COUNT(DISTINCT o.customer_id) as active_customers
FROM orders o JOIN first_purchase f USING (customer_id)
GROUP BY 1, 2 ORDER BY 1, 2;

-- Funnel analysis
SELECT step,
  COUNT(*) as users,
  COUNT(*) * 100.0 / FIRST_VALUE(COUNT(*)) OVER (ORDER BY step) as pct_of_top
FROM events GROUP BY step ORDER BY step;
```

## Visualization

### matplotlib + seaborn
```python
import matplotlib.pyplot as plt
import seaborn as sns

fig, axes = plt.subplots(1, 3, figsize=(15, 5))
sns.histplot(df["revenue"], ax=axes[0])
sns.boxplot(data=df, x="category", y="revenue", ax=axes[1])
sns.heatmap(df.corr(numeric_only=True), annot=True, ax=axes[2])
plt.tight_layout()
plt.savefig("eda.png", dpi=150)
```

### plotly (interactive)
```python
import plotly.express as px

fig = px.scatter(df, x="spend", y="revenue", color="segment", size="customers",
                 hover_data=["name"], trendline="ols")
fig.write_html("scatter.html")
```

## EDA Checklist

- [ ] Shape: rows x columns
- [ ] Types: numeric vs categorical vs datetime vs text
- [ ] Missing: % null per column, patterns (MCAR/MAR/MNAR)
- [ ] Distributions: skew, kurtosis, outliers (IQR or z-score)
- [ ] Correlations: Pearson (linear), Spearman (monotonic)
- [ ] Cardinality: unique values per categorical column
- [ ] Duplicates: exact vs fuzzy
- [ ] Time patterns: trends, seasonality, gaps

## Data Quality Rules

| Check | Red Flag |
|-------|----------|
| Nulls > 50% | Drop column or impute with caution |
| Single-value column | Zero information — drop |
| High cardinality (>95% unique) | Likely an ID, not a feature |
| Negative values in amounts | Data entry error or returns |
| Future dates | Clock skew or data leak |
| Duplicate primary keys | Join/ETL bug |

## Storytelling Framework

1. **Context** — what business question are we answering?
2. **Finding** — what does the data show? (lead with the insight)
3. **Evidence** — supporting charts/tables (minimal, high signal)
4. **Implication** — so what? what should we do?
5. **Caveat** — what are the limitations?
