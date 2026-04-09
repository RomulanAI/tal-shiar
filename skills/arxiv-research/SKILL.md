---
name: arxiv-research
description: Search, fetch, summarize, and analyze academic papers from ArXiv. Use when user asks about: finding papers on ArXiv, searching for research papers, summarizing ArXiv abstracts, downloading papers, academic literature research, paper analysis, citation tracking, or literature reviews. Covers ArXiv API queries, PDF fetching, Semantic Scholar for citations, CrossRef for DOI resolution, and synthesis of multiple papers into literature reviews.
---

# ArXiv Research Skill

Systematic approach to finding, reading, and synthesizing academic literature from ArXiv and related sources.

---

## 1. ArXiv API

### Direct Search via HTTP
```bash
# Search by keyword (returns Atom XML feed)
curl "https://export.arxiv.org/api/query?search_query=all:physics+informed+neural+networks&start=0&max_results=10&sortBy=relevance"

# By author
curl "https://export.arxiv.org/api/query?search_query=au:raissi&max_results=5"

# By title/abstract keywords
curl "https://export.arxiv.org/api/query?search_query=ti: PINNs+AND+abs:Fourier"

# Multiple search fields
# all: all fields, ti: title, au: author, abs: abstract, co: comments
```

### Python Client
```python
import arxiv

# Simple search
client = arxiv.Client()
search = arxiv.Search(
    query="physics informed neural networks",
    max_results=10,
    sort_by=arxiv.SortCriterion.Relevance
)
for result in client.results(search):
    print(f"{result.entry_id}")
    print(f"  {result.title}")
    print(f"  {result.summary[:200]}...")
    print(f"  {result.published}")
```

### Key ArXiv Categories
| Category | Topic |
|----------|-------|
| `cs.LG` | Machine Learning |
| `cs.AI` | Artificial Intelligence |
| `math.OC` | Optimization |
| `math.ST` | Statistics |
| `physics.comp-ph` | Computational Physics |
| `physics.flu-dyn` | Fluid Dynamics |
| `nlin.AO` | Adaptation & Self-Organization |
| `stat.ML` | Machine Learning (Stats) |

---

## 2. Fetching Papers

### Download PDF
```bash
# ArXiv PDF URL: arxiv.org/pdf/{id}.pdf
# Note: ArXiv IDs have evolved format: 2403.12345 (new) vs hep-th/9901001 (old)
curl -L -o paper.pdf "https://arxiv.org/pdf/2403.12345.pdf"

# With specific version
curl -L -o paper.pdf "https://arxiv.org/pdf/2403.12345v2.pdf"

# Or use wget
wget -O paper.pdf "https://arxiv.org/pdf/2403.12345.pdf"
```

### Parse Abstract / Metadata
```bash
# HTML abstract page
curl -s "https://arxiv.org/abs/2403.12345" | grep -A5 'class="abstract"'
```

---

## 3. Semantic Scholar API

### Free Tier
```bash
# Search papers
curl "https://api.semanticscholar.org/graph/v1/paper/search?query=PINNs&limit=5&fields=title,abstract,year,citationCount,authors"

# By DOI or ArXiv ID
curl "https://api.semanticscholar.org/graph/v1/paper/arXiv:2403.12345?fields=title,abstract,citations,references"
```

### Key Fields
- `title`, `abstract`, `year`, `venue`
- `citationCount`, `influentialCitationCount`
- `citations` (outbound references)
- `references` (inbound from this paper)

---

## 4. CrossRef for DOI Resolution
```bash
# Get DOI metadata
curl -s "https://api.crossref.org/works/10.1038/nature12373" | jq '.message.title, .message.author'
```

---

## 5. Literature Review Workflow

### Step 1: Search (5-10 papers)
```python
# Collect papers on topic
papers = []
for result in client.results(arxiv.Search(
    query="physics informed neural networks Burgers equation",
    max_results=20,
    sort_by=arxiv.SortCriterion.Relevance
)):
    papers.append({
        'id': result.entry_id.split('/')[-1],
        'title': result.title,
        'abstract': result.summary,
        'published': result.published.year,
        'url': result.pdf_url
    })
```

### Step 2: Filter
- Read abstracts
- Remove duplicates / superseded versions
- Keep: recent (≤5yr), high relevance, accessible

### Step 3: Deep Read
- Read PDF or fetch HTML abstract
- Extract: Problem, Method, Key Contributions, Limitations
- Note: How does this relate to other papers?

### Step 4: Synthesis
- Theme grouping (not paper-by-paper)
- Timeline of ideas
- Open questions / gaps

### Step 5: Write
- Introduction: problem + motivation
- Body: grouped by theme
- Conclusion: synthesis + future directions

---

## 6. Quick Reference: Common ArXiv IDs

| Paper | ID | Topic |
|-------|-----|-------|
| PINNs (Raissi 2019) | `arXiv:1711.10561` | Physics-Informed Neural Networks |
| FNO (Li 2020) | `arXiv:2010.08895` | Fourier Neural Operators |
| DeepONet (Lu 2021) | `arXiv:1912.11037` | DeepONet |
| Neural ODEs (Chen 2018) | `arXiv:1806.07366` | Neural ODEs |
| SONG (FNO Navier-Stokes) | `arXiv:2110.09452` | Super-resolution Navier-Stokes |
| WRF-BMA (Tung Warning) | — | WRF Ensemble post-processing |

---

## 7. ArXiv-Sanity (ML Paper Discovery)
```
http://arxiv-sanity.com/
```
Alternative: `https://paperswithcode.com/` for code links.

---

## 8. Example Literature Review Structure

For a 5-10 page review:

```
1. Introduction
   - Problem domain
   - Traditional approaches (brief)
   - Why AI for physics?

2. Method Category A: PINNs
   - Core idea
   - Strengths / Limitations
   - Key applications

3. Method Category B: Neural Operators
   - FNO, DeepONet
   - Operator learning paradigm
   - Comparison to PINNs

4. Applications Survey
   - Fluid dynamics
   - Solid mechanics
   - Climate/weather

5. Open Problems
   - Training challenges
   - Accuracy bounds
   - Benchmarks needed

6. Conclusion
```

---

## 9. Key Python Libraries
```python
arxiv                    # pip install arxiv
semanticscholar         # pip install semanticscholar
pysafetensors           # for local paper storage
```
