---
name: causal-analytics
description: Causal inference methods, DAGs, and treatment effect estimation
trigger: causal, causality, DAG, treatment effect, counterfactual, difference-in-differences, instrumental variable, RDD, propensity score, do-calculus
---

# Causal Analytics

## Core Principles

**Correlation is not causation.** This skill is about going from "X and Y move together" to "X causes Y" using rigorous methodology.

Key question: What would have happened if the treatment/intervention had NOT occurred? (The fundamental problem of causal inference — we never observe the counterfactual.)

## Causal Graphs (DAGs)

```
Treatment (X) → Outcome (Y)
         ↗
Confounder (Z)  → Outcome (Y)
```

- **Confounder**: causes both X and Y → must control for it
- **Mediator**: X → M → Y → control for it only if you want the direct effect
- **Collider**: X → C ← Y → do NOT control for it (opens a spurious path)

### Tools
- **dagitty** (R/web): draw DAGs, find adjustment sets
- **DoWhy** (Python): causal graph + estimation

```python
import dowhy
from dowhy import CausalModel

model = CausalModel(
    data=df,
    treatment="treatment",
    outcome="outcome",
    common_causes=["age", "income"],
)
identified = model.identify_effect()
estimate = model.estimate_effect(identified, method_name="backdoor.linear_regression")
refutation = model.refute_estimate(identified, estimate, method_name="random_common_cause")
```

## Methods

### 1. Randomized Controlled Trial (RCT)
The gold standard. Random assignment eliminates confounders by design.
- A/B tests are RCTs
- Check balance (covariate means across groups)
- ITT (intent-to-treat) vs LATE (local average treatment effect)

### 2. Difference-in-Differences (DiD)
Compare treated vs control groups, before vs after intervention.

```
ATT = (Y_treated_after - Y_treated_before) - (Y_control_after - Y_control_before)
```

**Assumptions**: parallel trends (absent treatment, groups would have trended the same).

```python
import statsmodels.formula.api as smf

model = smf.ols("outcome ~ treated * post + controls", data=df).fit()
# The interaction coefficient (treated:post) is the DiD estimate
```

### 3. Instrumental Variables (IV)
Use an instrument Z that affects X but affects Y only through X.

**Requirements**: Z is relevant (correlates with X), Z is exogenous (no direct effect on Y), Z satisfies exclusion restriction.

```python
from linearmodels.iv import IV2SLS

# 2SLS estimation
model = IV2SLS.from_formula("outcome ~ 1 + controls + [treatment ~ instrument]", data=df)
result = model.fit()
```

### 4. Regression Discontinuity (RDD)
Treatment assigned by a cutoff on a running variable. Compare outcomes just above/below the cutoff.

```python
# Sharp RDD: compare outcomes in bandwidth around cutoff
bandwidth = 5
subset = df[(df.score >= cutoff - bandwidth) & (df.score <= cutoff + bandwidth)]
model = smf.ols("outcome ~ treated + score_centered + treated:score_centered", data=subset).fit()
```

### 5. Propensity Score Methods
Estimate P(treated | covariates), then match or weight.

```python
from sklearn.linear_model import LogisticRegression

# Estimate propensity scores
ps_model = LogisticRegression().fit(X_covariates, treatment)
propensity = ps_model.predict_proba(X_covariates)[:, 1]

# Inverse probability weighting (IPW)
df["weight"] = df["treated"] / propensity + (1 - df["treated"]) / (1 - propensity)
```

### 6. Synthetic Control
Construct a weighted combination of control units that matches the treated unit pre-intervention.

```r
library(Synth)

synth_out <- synth(dataprep.out)
path.plot(synth.res = synth_out, dataprep.res = dataprep.out)
```

### 7. Mediation Analysis
Decompose total effect into direct + indirect (through mediator).

```python
# Baron-Kenny approach
# Step 1: X → Y (total effect)
# Step 2: X → M (a path)
# Step 3: X + M → Y (c' = direct effect, b = mediator effect)
# Indirect effect = a * b
```

## Sensitivity Analysis

Always ask: "How much unmeasured confounding would it take to overturn this result?"

- **Rosenbaum bounds** (for matching)
- **E-value** (for observational studies)
- **Placebo tests** (apply method where you know there's no effect)
- **DoWhy refutation tests**: random common cause, placebo treatment, data subset

## Decision Framework

| Scenario | Best Method |
|----------|-------------|
| Can randomize | RCT / A/B test |
| Treatment at a cutoff | RDD |
| Policy change at a point in time | DiD |
| Have a good instrument | IV / 2SLS |
| Observational data, rich covariates | Propensity score + sensitivity |
| Single treated unit, many controls | Synthetic control |
| Want to decompose mechanism | Mediation analysis |

## Key Libraries

| Library | Language | Strengths |
|---------|----------|-----------|
| DoWhy | Python | Graph-based, refutation tests |
| EconML | Python | Heterogeneous treatment effects, ML-based |
| CausalImpact | R | Bayesian structural time series |
| MatchIt | R | Propensity score matching |
| rdrobust | R/Stata | Regression discontinuity |
| dagitty | R/web | DAG drawing, adjustment sets |
| Synth | R | Synthetic control method |
