---
name: statistics
description: Statistical analysis, probability theory, hypothesis testing, regression analysis, Bayesian statistics, R, Python scipy/pandas/statsmodels. Triggers when user asks about statistics, probability, data analysis, hypothesis tests, regression, ANOVA, time series, Bayesian methods, or using R/Python for statistical work.
---

# Statistics Skill

Expert statistical analysis — from basic descriptive stats to advanced Bayesian modeling.

## Core Workflow

1. Understand the data and question
2. Choose appropriate statistical method
3. Perform analysis
4. Interpret and report results
5. Generate visualizations

## Python Stats Stack

```python
import numpy as np
import pandas as pd
import scipy.stats as stats
import statsmodels.api as sm
from scipy import linspace
import matplotlib.pyplot as plt

# Descriptive stats
df.describe()
df['col'].mean(), median(), std(), skew(), kurtosis()

# Correlation
df.corr()
```

## Common Tests

### t-test (one sample)
```python
from scipy.stats import ttest_1samp
t, p = ttest_1samp(data, popmean=0)
```

### t-test (two samples)
```python
from scipy.stats import ttest_ind
t, p = ttest_ind(group1, group2)
```

### Paired t-test
```python
from scipy.stats import ttest_rel
t, p = ttest_rel(before, after)
```

### Chi-square test
```python
from scipy.stats import chi2_contingency
chi2, p, dof, expected = chi2_contingency(observed)
```

### ANOVA
```python
from scipy.stats import f_oneway
f, p = f_oneway(group1, group2, group3)
```

### Mann-Whitney U (non-parametric)
```python
from scipy.stats import mannwhitneyu
u, p = mannwhitneyu(group1, group2)
```

### Kolmogorov-Smirnov test
```python
from scipy.stats import kstest, norm
ks, p = kstest(data, 'norm')  # test normality
```

## Regression

### Linear regression (OLS)
```python
import statsmodels.api as sm
X = sm.add_constant(df[['x1', 'x2']])  # add intercept
model = sm.OLS(y, X).fit()
print(model.summary())
```

### Logistic regression
```python
import statsmodels.api as sm
X = sm.add_constant(df[['x1', 'x2']])
model = sm.Logit(y, X).fit()
print(model.summary())
```

### Sklearn regression
```python
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
```

## Probability Distributions

```python
from scipy.stats import norm, t, chi2, f, binom, poisson, expon

# Normal distribution
norm.cdf(1.96)           # P(Z < 1.96)
norm.ppf(0.975)          # critical value
norm.pdf(0)              # density at 0

# t distribution
t.cdf(2.0, df=19)       # P(T < 2) with df=19

# Binomial
binom.pmf(k, n, p)      # P(X = k)
binom.cdf(k, n, p)      # P(X <= k)
```

## Confidence Intervals

```python
from scipy.stats import sem, t as t_dist
import numpy as np

def ci(data, confidence=0.95):
    n = len(data)
    m = np.mean(data)
    se = sem(data)
    h = se * t_dist.ppf((1 + confidence) / 2, n - 1)
    return m - h, m + h
```

## Bayesian Statistics

```python
# PyMC3/ArviZ for Bayesian modeling
import pymc3 as pm
import arviz as az

with pm.Model():
    # priors
    alpha = pm.Normal('alpha', mu=0, sigma=10)
    beta = pm.Normal('beta', mu=0, sigma=10)
    sigma = pm.HalfNormal('sigma', sigma=1)
    
    # likelihood
    mu = alpha + beta * x
    y_obs = pm.Normal('y_obs', mu=mu, sigma=sigma, observed=y)
    
    # inference
    trace = pm.sample(2000, tune=1000)
    az.plot_posterior(trace)
```

## Time Series

```python
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.stattools import adfuller, acf, pacf
from statsmodels.tsa.seasonal import seasonal_decompose

# ADF test for stationarity
result = adfuller(data)
print(f'ADF Statistic: {result[0]}')
print(f'p-value: {result[1]}')

# ARIMA
model = ARIMA(data, order=(1, 1, 1))
fitted = model.fit()
forecast = fitted.forecast(steps=10)
```

## Visualizations

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Distribution plot
sns.histplot(data, kde=True)

# Box plot
sns.boxplot(x='group', y='value', data=df)

# QQ plot
from scipy.stats import probplot
probplot(data, dist="norm", plot=plt)

# Correlation heatmap
sns.heatmap(df.corr(), annot=True, cmap='coolwarm')
```

## Effect Size

```python
# Cohen's d
def cohens_d(group1, group2):
    n1, n2 = len(group1), len(group2)
    var1, var2 = group1.var(), group2.var()
    pooled_std = np.sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))
    return (group1.mean() - group2.mean()) / pooled_std

# Cohen's d interpretation: 0.2 small, 0.5 medium, 0.8 large
```

## Multiple Testing Correction

```python
from scipy.stats import false_discovery_control

# Benjamini-Hochberg
from statsmodels.stats.multitest import multipletests
rejected, pvals_corrected, _, _ = multipletests(pvals, alpha=0.05, method='fdr_bh')
```

## Reporting Results

Always report:
- Test used + purpose
- Test statistic value
- Degrees of freedom (if applicable)
- p-value
- Effect size + confidence interval
- Interpretation in plain language
