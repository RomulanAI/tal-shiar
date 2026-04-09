---
name: latex
description: Expert LaTeX document preparation — academic papers, theses, reports, dissertations. Triggers when user asks about writing LaTeX documents, compiling LaTeX, TikZ diagrams, TeX packages, BibTeX, journal submissions, or any LaTeX-related document preparation.
---

# LaTeX Skill

Expert assistance with all things LaTeX — from simple articles to complex multi-volume dissertations.

## Core Workflow

1. Write clean, well-structured LaTeX
2. Use proper document class
3. Compile with `pdflatex` + `bibtex` + `pdflatex` + `pdflatex`
4. Return the final PDF or zip of sources

## Common Commands

```bash
pdflatex document.tex
bibtex document.aux
pdflatex document.tex
pdflatex document.tex
```

For makeindex:
```bash
makeindex document.idx
pdflatex document.tex
```

## Document Classes

- `article` — short papers, reports
- `report` — theses, dissertations
- `book` — multi-chapter books
- ` Memoir` — flexible book-like documents
- `IEEEtran` — IEEE papers
- `revtex4-1` / `revtex4-2` — APS/ AIP journals

## Package Essentials

```latex
\usepackage{amsmath,amssymb}
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage{booktabs}
\usepackage{natbib}
\usepackage{siunitx}
```

## Structure Template

```latex
\documentclass[12pt,a4paper]{article}
\usepackage[margin=1in]{geometry}
\usepackage{amsmath,graphicx,hyperref}

\title{Your Title Here}
\author{Your Name}
\date{\today}

\begin{document}
\maketitle
\begin{abstract}
...
\end{abstract}
\section{Introduction}
...
\section{Conclusion}
\bibliographystyle{plain}
\bibliography{refs}
\end{document}
```

## BibTeX Setup

```bib
@article{key2024,
  author={Author},
  title={Title},
  journal={Journal},
  year={2024},
  volume={1},
  pages={1--10}
}
```

## Graphics (TikZ)

```latex
\usepackage{tikz}
\usetikzlibrary{shapes,arrows,positioning}

\begin{tikzpicture}
\node[draw] (a) {A};
\node[draw,right=of a] (b) {B};
\draw[->] (a) -- (b);
\end{tikzpicture}
```

## Troubleshooting

- "File not found" → check `.bib` filename matches `\bibliography{refs}` (no .bib extension)
- "Undefined citation" → run bibtex then pdflatex twice more
- "Overfull hbox" → adjust `hyphenation` or use `\emergencystretch`
- "Missing $ inserted" → math must be in `$...$` or `\[...\]`
