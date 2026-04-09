---
name: r-lang
description: R programming, tidyverse, statistical modeling, and visualization
trigger: R language, ggplot, tidyverse, dplyr, lm, glm, Rmarkdown, CRAN
---

# R Programming

## Tidyverse Core

```r
library(tidyverse)  # loads dplyr, ggplot2, tidyr, readr, purrr, stringr, forcats, tibble

# Read data
df <- read_csv("data.csv")

# dplyr verbs
df %>%
  filter(amount > 100, !is.na(category)) %>%
  mutate(log_amount = log(amount),
         year = year(date)) %>%
  group_by(region, year) %>%
  summarise(total = sum(amount),
            n = n(),
            avg = mean(amount),
            .groups = "drop") %>%
  arrange(desc(total))

# Reshape
df %>% pivot_longer(cols = c(q1, q2, q3, q4), names_to = "quarter", values_to = "revenue")
df %>% pivot_wider(names_from = category, values_from = amount, values_fill = 0)

# Joins
left_join(orders, customers, by = "customer_id")
anti_join(all_products, sold_products, by = "product_id")  # unsold products
```

## ggplot2

```r
# Scatter + regression
ggplot(df, aes(x = spend, y = revenue, color = segment)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Revenue vs Spend by Segment",
       x = "Marketing Spend", y = "Revenue") +
  theme_minimal() +
  scale_color_brewer(palette = "Set2")

# Faceted time series
ggplot(df, aes(x = date, y = value)) +
  geom_line() +
  facet_wrap(~metric, scales = "free_y", ncol = 2) +
  theme_bw()

# Save
ggsave("plot.png", width = 10, height = 6, dpi = 300)
```

## Statistical Modeling

### Linear Models
```r
# OLS
model <- lm(revenue ~ spend + region + factor(quarter), data = df)
summary(model)
confint(model)

# Diagnostics
par(mfrow = c(2, 2))
plot(model)

# Predictions
predict(model, newdata = test_df, interval = "confidence")
```

### Generalized Linear Models
```r
# Logistic regression
logit <- glm(converted ~ age + spend + channel, data = df, family = binomial)
summary(logit)
exp(coef(logit))  # odds ratios

# Poisson regression (count data)
pois <- glm(claims ~ age + exposure, data = df, family = poisson, offset = log(exposure))
```

### Mixed Effects (lme4)
```r
library(lme4)

# Random intercepts
mixed <- lmer(score ~ treatment + time + (1 | subject_id), data = df)
summary(mixed)

# Random slopes
mixed2 <- lmer(score ~ treatment * time + (time | subject_id), data = df)
```

### Survival Analysis
```r
library(survival)
library(survminer)

surv_obj <- Surv(time = df$time, event = df$status)
km_fit <- survfit(surv_obj ~ group, data = df)
ggsurvplot(km_fit, data = df, pval = TRUE, risk.table = TRUE)

# Cox PH
cox <- coxph(surv_obj ~ age + treatment + stage, data = df)
summary(cox)
```

## Useful Packages

| Package | Purpose |
|---------|---------|
| `broom` | Tidy model output (`tidy()`, `glance()`, `augment()`) |
| `car` | VIF, Anova, influence plots |
| `caret` / `tidymodels` | ML pipeline (train/test, cross-validation) |
| `data.table` | Fast data manipulation (large datasets) |
| `lubridate` | Date/time manipulation |
| `patchwork` | Compose multiple ggplots |
| `gt` / `kableExtra` | Publication-quality tables |
| `mice` | Multiple imputation |
| `forecast` | Time series (ARIMA, ETS) |
| `brms` | Bayesian regression (Stan backend) |

## Rmarkdown

```yaml
---
title: "Analysis Report"
author: "Analyst"
date: "`r Sys.Date()`"
output:
  pdf_document:
    toc: true
  html_document:
    toc: true
    toc_float: true
    code_folding: hide
---
```

Code chunks: `` `r knitr::inline_expr("mean(df$x)")` `` for inline, or fenced chunks with `{r chunk_name, echo=FALSE, fig.width=10}`.

## Common Patterns

```r
# Apply function across columns
df %>% summarise(across(where(is.numeric), list(mean = mean, sd = sd), na.rm = TRUE))

# Iterate with purrr
models <- df %>%
  group_by(region) %>%
  nest() %>%
  mutate(model = map(data, ~ lm(revenue ~ spend, data = .x)),
         summary = map(model, broom::tidy)) %>%
  unnest(summary)

# Multiple testing correction
p.adjust(p_values, method = "BH")  # Benjamini-Hochberg
```
