---
name: economics
description: Economics — microeconomics, macroeconomics, econometrics, game theory, market analysis, economic policy, international trade, development economics, financial economics. Triggers when user asks about economic concepts, models, theories, policy analysis, market dynamics, trade, economic data, or economic research.
---

# Economics Skill

Expert economics assistance — from undergraduate theory to research-level econometrics.

## Core Workflow

1. Identify the economic problem or question
2. Apply appropriate theory/model
3. Work through the analysis
4. Interpret results with economic intuition
5. Report findings clearly

## Microeconomics

### Budget Constraint
```
p₁x₁ + p₂x₂ = m
x₂ = m/p₂ - (p₁/p₂)x₁
Slope = -p₁/p₂
```

### Utility Maximization
```
max U(x₁, x₂)
s.t. p₁x₁ + p₂x₂ = m

Lagrangian: L = U(x₁,x₂) - λ(p₁x₁ + p₂x₂ - m)
```

### Demand Functions
- **Ordinary demand**: x₁(p₁, p₂, m)
- **Compensated (Hicks) demand**: hᵢ(p₁, p₂, ū)
- **Inverse demand**: p(x)

### Elasticity

```python
# Price elasticity of demand
ε = (dQ/Q) / (dP/P) = (dQ/dP) * (P/Q)
ε = (∂x₁/∂p₁) * (p₁/x₁)
```

| ε < -1 | Elastic |
| ε = -1 | Unit elastic |
| -1 < ε < 0 | Inelastic |

### Perfect Substitutes / Complements
```python
# Substitutes: U = a*x + b*y → demand: x = m/p₁ if p₁ < p₂*α/β, else 0
# Complements: U = min(a*x, b*y) → demand: x = m/(p₁ + p₂*a/b)
```

## Macroeconomics

### National Accounts
```
Y = C + I + G + NX
NX = X - M

GDP deflator = (Nominal GDP / Real GDP) × 100
```

### Keynesian Cross
```
Equilibrium: Y* = C(Y-T) + I + G
```

### IS-LM Model

**IS curve** (goods market equilibrium):
```
Y = C(Y - T) + I(r) + G
dY/dY * (1 - MPC) = dY/dI * I'(r) * dr/dY
Slope: dr/dY = (1 - MPC) / I'(r) < 0
```

**LM curve** (money market equilibrium):
```
M/P = L(Y, r)
Slope: dr/dY = L_Y / L_r > 0
```

### AD-AS Model

**AD curve**: Y = Y(M, G, T, Z)
**AS curve**: Short-run (horizontal), Long-run (vertical at Y*)

### Phillips Curve

```python
# Short-run
π = πₑ - β(u - u*) + ε
# Long-run: vertical at natural rate of unemployment (NAIRU)
```

### Solow Growth Model

```python
# Basic: Y = K^α (AL)^(1-α)
# Steady state: sY = δK → K* = (sY*/δ)^(1/(1-α))
# Golden rule: MPK = δ → k*_gold = (s/(δ+γ+n))^(1/(1-α))
```

### Ramsey-Cass-Koopmans Model
Optimal growth with utility maximization and capital accumulation.

## Econometrics

### OLS Regression

```python
import statsmodels.api as sm

# Simple OLS
X = sm.add_constant(df['x'])
model = sm.OLS(df['y'], X).fit()
print(model.summary())

# Multiple OLS
X = sm.add_constant(df[['x1', 'x2', 'x3']])
model = sm.OLS(df['y'], X).fit()
```

### Key Formulas

```python
# OLS estimators
beta_hat = (X'X)⁻¹ X'y
E[beta_hat] = beta  # unbiased
Var[beta_hat] = σ² (X'X)⁻¹

# R²
R² = 1 - SSR/SST = ESS/SST

# Adjusted R²
R²_adj = 1 - (n-1)/(n-k) * SSR/SST

# Heteroskedasticity-robust SE
SE_rob = sqrt(diag(X'X)⁻¹ X'ΩX(X'X)⁻¹)
```

### Instrumental Variables (2SLS)

```python
from statsmodels.sandbox.regression.gmm import IV2SLS

iv_model = IV2SLS(endog, exog, instrument).fit()
print(iv_model.summary())
```

### Difference-in-Differences

```python
# Panel data setup
# Y = α + β*post + γ*treatment + δ*(post × treatment) + ε
df['post'] = (df['year'] >= treatment_year).astype(int)
df['did'] = df['post'] * df['treatment']
model = sm.OLS(df['y'], sm.add_constant(df[['post', 'treatment', 'did']])).fit()
```

### Regression Discontinuity Design (RDD)

```python
# Sharp RDD
df['running'] = df['score'] - cutoff
df['above'] = (df['running'] >= 0).astype(int)
model = sm.OLS(df['outcome'], sm.add_constant(df[['running', 'above', 'running_x_above']])).fit()
```

### Panel Data (Fixed Effects)

```python
import pandas as pd
from linearmodels.panel import PanelOLS

df = df.set_index(['entity', 'time'])
model = PanelOLS(df['y'], df[['x1', 'x2']], entity_effects=True).fit()
print(model.summary)
```

### IV Estimator Formula

```python
# First stage: x = πz + v
# Second stage: y = βx + ε
# Reduced form: y = π*β*z + (v*β + ε)
# IV estimator: β_IV = (Z'X)⁻¹ Z'y / (Z'Z)⁻¹ Z'x = Cov(Z,y)/Cov(Z,x)
```

## Game Theory

### Normal Form Games

| | L | R |
|---|---|---|
| **U** | (2,1) | (0,0) |
| **D** | (0,0) | (1,2) |

### Nash Equilibrium
Best response against each other's strategies.

### Dominant Strategy
A strategy that yields higher payoff regardless of opponent's choice.

### Mixed Strategies

```python
# Expected payoff
E[p1, p2] = p1*p2*u11 + p1*(1-p2)*u12 + (1-p1)*p2*u21 + (1-p1)*(1-p2)*u22
```

## Market Structures

| Type | Firms | P vs MC | Entry | Examples |
|------|-------|---------|-------|----------|
| Perfect Comp. | Many | P = MC | Free | Agriculture |
| Monopoly | One | P > MC | Blocked | Utilities |
| Monopolistic Comp. | Many | P > MC | Free | Restaurants |
| Oligopoly | Few | P > MC | Barriers | Airlines, telco |

### Lerner Index
```
L = (P - MC) / P = 1/|ε|
```

## International Trade

### Gravity Equation
```python
# Trade = A * (GDP_i * GDP_j) / Distance
import numpy as np
model = sm.OLS(np.log(trade), sm.add_constant(np.log(gdp_i) + np.log(gdp_j) - np.log(distance))).fit()
```

### Heckscher-Ohlin Model
Factor proportions drive trade patterns.

## Time Series Econometrics

```python
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.stattools import adfuller, grangercausalitytests
from statsmodels.tsa.var_model import VAR

# ADF test
result = adfuller(series)
# Cointegration test (Engle-Granger)
from statsmodels.tsa.stattools import coint
coint(y1, y2)

# VAR
model = VAR(df)
results = model.fit(maxlags=5)
results.summary()
```

## Data Sources

- **World Bank** (wbdata, wbgapi Python packages)
- **FRED** (fredapi Python package)
- **Penn World Table**
- **OECD**
- **Eurostat**

```python
# World Bank data
import wbgapi as wb
df = wb.data.DataFrame('NY.GDP.MKTP.CD', time=range(1990, 2023), economy=['USA', 'CHN', 'DEU'])
```
