---
name: beamer
description: Expert LaTeX Beamer presentations — slides, academic talks, conference presentations, professional slides. Triggers when user asks about Beamer, LaTeX presentations, slide creation, or any presentation-related LaTeX work.
---

# Beamer Skill

Expert assistance with LaTeX Beamer presentations — from conference talks to lecture slides.

## Core Workflow

1. Create Beamer document with proper theme
2. Structure slides with frames
3. Add overlays, animations, transitions
4. Compile to PDF
5. Return PDF or zip of sources

## Basic Structure

```latex
\documentclass{beamer}
\usetheme{Madrid}       % theme
\usecolortheme{default} % color
\usepackage{amsmath,graphicx}

\title{Your Presentation Title}
\subtitle{Optional Subtitle}
\author{Your Name}
\institute{Your Institution}
\date{\today}

\begin{document}
\frame{\titlepage}

\section{Introduction}
\begin{frame}{Frame Title}
  Content here
\end{frame}
\end{document}
```

## Common Themes

| Theme | Style |
|-------|-------|
| `Madrid` | Professional blue, good for most talks |
| `Berlin` | Dark blue, bold |
| `Copenhagen` | Light with section navigation |
| `Warsaw` | Blue with shadowed title |
| `AnnArbor` | Purple/blue gradient |
| `CambridgeUS` | US academic style |
| `Singapore` | Clean, minimal |
| `PaloAlto` | Tree navigation sidebar |

## Color Themes

`default`, `albatross`, `beaver`, ` beetle`, `crane`, `dolphin`, `dove`, `fly`, `lion`, `monarch`, `seagull`, `seahorse`, `sidebartab`, `structure`, `whale`, `wolverine`

## Frames

### Simple frame
```latex
\begin{frame}{Title}
  Content
\end{frame}
```

### Two-column frame
```latex
\begin{frame}{Two Column Layout}
  \begin{columns}
    \column{0.5\textwidth}
    Left column content
    \column{0.5\textwidth}
    Right column content
  \end{columns}
\end{frame}
```

### Frame with bullets
```latex
\begin{frame}{Key Points}
  \begin{itemize}
    \item First point
    \item Second point
    \item Third point
  \end{itemize}
\end{frame}
```

## Overlays (Reveals)

### Reveal bullets one at a time
```latex
\begin{itemize}
  \item<1-> First always visible
  \item<2-> Second appears on click 2
  \item<3-> Third appears on click 3
\end{itemize}
```

### Alerted text
```latex
\alert<2>{This text appears on slide 2 only}
```

### Block with alert
```latex
\begin{block}<2>{Title}
  Content appears on slide 2
\end{block}
```

## Graphics

```latex
\begin{frame}{Results}
  \centering
  \includegraphics[width=0.8\textwidth]{figure.pdf}
\end{frame}
```

For accurate figures, use vector formats (PDF, PNG at high resolution).

## Math

```latex
\begin{frame}{Derivation}
  \begin{align}
    f(x) &= \int_0^x g(t) \, dt \\
         &= \mathcal{O}(x^2)
  \end{align}
\end{frame}
```

## Transitions

```latex
\transdissolve     % fade
\transblindshorizontal
\transblindsvertical
\transboxin
\transboxout
\transglitter
\transsplitverticalin
\transwipe
```

## Compile

```bash
pdflatex presentation.tex
# Beamer is single-pass, no bibtex needed usually
pdflatex presentation.tex
```

## Tips

- Use `\pause` for simple reveals
- Keep one idea per slide
- `shrink` to fit large frames: `\begin{frame}[shrink=10]{Title}`
- Use `\setbeamerfont{frametitle}{size=\large}` for smaller titles
- Add `\logo{\includegraphics[height=0.5cm]{logo.png}}` for institution logo
