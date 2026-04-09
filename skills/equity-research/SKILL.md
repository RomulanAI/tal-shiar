---
name: equity-research
description: Financial analysis, valuation, and equity research
trigger: equity, stock, valuation, DCF, earnings, financial statements, PE ratio, market cap
---

# Equity Research

## Core Workflow

1. **Screen** — identify candidates (sector, market cap, ratios)
2. **Analyze** — financial statements, ratios, competitive position
3. **Value** — DCF, comparables, precedent transactions
4. **Synthesize** — investment thesis with bull/bear cases

## Financial Statement Analysis

### Income Statement
- Revenue growth (YoY, CAGR)
- Gross margin, operating margin, net margin trends
- EPS growth, dilution effects
- Non-recurring items — always strip out for normalized earnings

### Balance Sheet
- Debt/equity ratio, net debt/EBITDA
- Current ratio, quick ratio (liquidity)
- Working capital trends (DSO, DIO, DPO)
- Goodwill/intangibles as % of total assets (acquisition quality signal)

### Cash Flow
- FCF = Operating CF - CapEx
- FCF yield = FCF / market cap
- Cash conversion ratio = Operating CF / Net Income (>1.0 is healthy)
- CapEx as % of revenue (capital intensity)

## Key Ratios

| Ratio | Formula | What It Tells You |
|-------|---------|-------------------|
| P/E | Price / EPS | Earnings multiple |
| EV/EBITDA | Enterprise Value / EBITDA | Operating value multiple |
| P/B | Price / Book Value | Asset-based valuation |
| ROE | Net Income / Equity | Return on shareholder capital |
| ROIC | NOPAT / Invested Capital | Capital efficiency |
| PEG | P/E / EPS Growth Rate | Growth-adjusted valuation |

## DCF Valuation

```
Enterprise Value = Sum of [FCF_t / (1 + WACC)^t] + Terminal Value / (1 + WACC)^n

Terminal Value = FCF_n * (1 + g) / (WACC - g)
  where g = terminal growth rate (typically 2-3%)

Equity Value = Enterprise Value - Net Debt + Cash
Price per Share = Equity Value / Shares Outstanding
```

### WACC Components
- Cost of equity: CAPM = Rf + Beta * (Rm - Rf)
- Cost of debt: after-tax = Rd * (1 - tax rate)
- Weights: market value of debt and equity

### Sensitivity Analysis
Always run a matrix: WACC (rows) vs terminal growth rate (columns). Show the range of implied share prices.

## Comparable Company Analysis

1. Select peer group (same sector, similar size/growth)
2. Calculate multiples: EV/EBITDA, P/E, EV/Revenue
3. Apply median/mean multiples to target's metrics
4. Adjust for growth differential, margin differential, risk

## Tools (Python)

```python
import yfinance as yf
import pandas as pd

# Fetch data
ticker = yf.Ticker("AAPL")
income = ticker.financials          # annual income statement
balance = ticker.balance_sheet      # balance sheet
cashflow = ticker.cashflow          # cash flow statement
info = ticker.info                  # summary (PE, market cap, etc.)

# Historical prices
hist = ticker.history(period="5y")
```

### SEC EDGAR API
```python
import requests

# Company filings
url = "https://efts.sec.gov/LATEST/search-index"
headers = {"User-Agent": "YourName your@email.com"}
# Use EDGAR full-text search for 10-K, 10-Q filings
```

## Sector-Specific Metrics

| Sector | Key Metrics |
|--------|------------|
| Tech/SaaS | ARR, NRR, Rule of 40, CAC/LTV |
| Banks | NIM, CET1 ratio, NPL ratio, ROA |
| Retail | Same-store sales, inventory turnover, revenue/sqft |
| Pharma | Pipeline value, patent cliff, R&D/revenue |
| REITs | FFO, AFFO, NAV, cap rate, occupancy |
| Insurance | Combined ratio, loss ratio, float |

## Research Note Structure

1. **Investment thesis** (2-3 sentences)
2. **Key metrics** (table: current vs historical vs peers)
3. **Catalysts** (what changes the story)
4. **Risks** (what breaks the thesis)
5. **Valuation** (DCF + comps, target price range)
6. **Recommendation** (with conviction level)
