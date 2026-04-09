---
name: health-medical-research
description: Clinical research methodology, biostatistics, epidemiology, and evidence-based medicine
trigger: clinical trial, epidemiology, biostatistics, survival analysis, meta-analysis, systematic review, CONSORT, STROBE, PubMed, evidence-based, RCT, cohort, case-control, NNT, hazard ratio
---

# Health & Medical Research

## Study Design Hierarchy (Evidence Pyramid)

1. **Systematic Reviews & Meta-analyses** (strongest)
2. **Randomized Controlled Trials (RCTs)**
3. **Cohort Studies** (prospective > retrospective)
4. **Case-Control Studies**
5. **Cross-Sectional Studies**
6. **Case Reports / Expert Opinion** (weakest)

## Study Types

### RCT Design
- **Parallel**: treatment vs control, simultaneous
- **Crossover**: each subject gets both, washout period between
- **Cluster**: randomize groups (hospitals, clinics), not individuals
- **Non-inferiority**: prove new treatment is no worse than standard
- **Adaptive**: modify design mid-trial based on interim results

### Observational
- **Prospective cohort**: follow exposed/unexposed forward in time → relative risk
- **Retrospective cohort**: use historical records → same measures, less control
- **Case-control**: start with cases (disease) and controls → odds ratio
- **Cross-sectional**: snapshot at one point in time → prevalence, associations

## Key Measures

| Measure | Formula | Use |
|---------|---------|-----|
| Relative Risk (RR) | P(event\|exposed) / P(event\|unexposed) | Cohort studies |
| Odds Ratio (OR) | (a*d) / (b*c) from 2x2 table | Case-control studies |
| Hazard Ratio (HR) | Instantaneous rate ratio | Survival analysis |
| NNT | 1 / ARR (absolute risk reduction) | Clinical decision-making |
| NNH | 1 / ARI (absolute risk increase) | Harm assessment |
| Sensitivity | TP / (TP + FN) | Diagnostic test (rule out) |
| Specificity | TN / (TN + FP) | Diagnostic test (rule in) |
| PPV/NPV | Depends on prevalence | Post-test probability |
| AUC-ROC | Area under ROC curve | Discriminative ability |

## Biostatistics

### Sample Size
```r
# Two-group comparison (proportions)
library(pwr)
pwr.2p.test(h = ES.h(p1 = 0.30, p2 = 0.20),  # effect size
            sig.level = 0.05, power = 0.80)

# Two-group comparison (means)
pwr.t.test(d = 0.5, sig.level = 0.05, power = 0.80, type = "two.sample")
```

### Survival Analysis
```r
library(survival)
library(survminer)

# Kaplan-Meier
km <- survfit(Surv(time, event) ~ treatment, data = df)
ggsurvplot(km, pval = TRUE, risk.table = TRUE,
           xlab = "Months", ylab = "Survival Probability")

# Cox Proportional Hazards
cox <- coxph(Surv(time, event) ~ treatment + age + stage, data = df)
summary(cox)           # HRs with CIs
cox.zph(cox)           # test PH assumption
```

### Meta-Analysis
```r
library(meta)

# Fixed/random effects meta-analysis
m <- metagen(TE = log_OR, seTE = se_log_OR, studlab = study,
             data = studies, sm = "OR", random = TRUE)
forest(m)              # forest plot
funnel(m)              # publication bias
metabias(m)            # Egger's test
```

```python
# Python alternative
import pymare

dataset = pymare.Dataset(y=effect_sizes, v=variances, names=study_names)
results = pymare.estimators.DerSimonianLaird().fit_dataset(dataset)
```

## Reporting Guidelines

| Study Type | Guideline | Checklist |
|------------|-----------|-----------|
| RCT | CONSORT | 25 items + flow diagram |
| Observational (cohort/case-control) | STROBE | 22 items |
| Systematic Review | PRISMA | 27 items + flow diagram |
| Diagnostic Accuracy | STARD | 30 items |
| Quality Improvement | SQUIRE | 18 items |
| Case Reports | CARE | 13 items |

## Literature Search

### PubMed / MEDLINE
```
# Boolean search
(("diabetes mellitus"[MeSH]) AND ("metformin"[MeSH]) AND ("randomized controlled trial"[pt]))

# Filters: humans, English, last 5 years, RCT
```

### Systematic Review Workflow
1. Define PICO (Population, Intervention, Comparison, Outcome)
2. Search PubMed, Embase, Cochrane, Web of Science
3. Screen titles/abstracts → full text review
4. Extract data (standardized form)
5. Assess risk of bias (Cochrane RoB 2.0 or Newcastle-Ottawa)
6. Synthesize (narrative or meta-analysis)
7. GRADE certainty of evidence

## Clinical Coding

| System | Purpose | Example |
|--------|---------|---------|
| ICD-10/11 | Diagnosis classification | E11.9 = T2DM without complications |
| SNOMED CT | Clinical terminology | Concept hierarchy with relationships |
| CPT | Procedures (US billing) | 99213 = office visit, established |
| LOINC | Lab/clinical observations | 2345-7 = glucose in serum |
| ATC | Drug classification | A10BA02 = metformin |

## Bias Checklist

| Bias | What It Is | Mitigation |
|------|-----------|------------|
| Selection | Non-random group assignment | Randomization, matching |
| Information | Measurement differs by group | Blinding, standardized instruments |
| Confounding | Third variable causes both | Adjustment, stratification, matching |
| Attrition | Differential dropout | ITT analysis, sensitivity analysis |
| Publication | Positive results published more | Funnel plot, register protocols |
| Lead-time | Early detection ≠ longer survival | Use mortality, not survival from diagnosis |
| Immortal time | Misclassified person-time | Proper time-zero, landmark analysis |

## Critical Appraisal Questions

1. Was the study question clearly defined (PICO)?
2. Was the study design appropriate for the question?
3. Was selection bias minimized?
4. Were outcomes measured validly and reliably?
5. Were confounders identified and controlled?
6. Was follow-up adequate?
7. Are the results clinically meaningful (not just statistically significant)?
8. Are the results generalizable to my patient population?
