# Phase 8 handoff — reformat as a thesis, write the introduction and literature review

Paste everything below the line into a fresh session. It is self-contained.

---

## Where things stand

Repo: `F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet`, branch `paper/gap-fix`. Everything below is
committed; `git log --oneline -8` shows the recent history.

**The simulations, the analysis and the figures are done.** Do not re-run Sentaurus. Do not
retrain the network. Do not redraw figures except where this document says so.

What exists:

| | |
|---|---|
| `Paper-materials/figs.py` | the one figure generator — `--fig <ID>`, `--all`, `--panels`, `--manifest`, `--lint` |
| `Paper-materials/figlib/` | 28 figure functions, one module per chapter |
| `Paper-materials/figures/` | 33 PNG + PDF + the CSV of exactly what each one plotted |
| `Paper-materials/panels/` | the 10 composed main-text panels |
| `Paper-materials/figures_manifest.csv` | per figure: source run, draw function, the claim it supports, the normalization used |
| `Paper-materials/paper/` | the manuscript: `main.tex` + six section files |
| `Paper-materials/literature_benchmark.csv` | 15 surveyed devices with DOI and the sentence each number was read from |

The manuscript currently builds clean: 15 pages, zero LaTeX errors, zero undefined references.

```bash
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet/Paper-materials/paper" && latexmk -pdf -interaction=nonstopmode main.tex
```

Read these three before you touch anything. They are the source of truth for every number:

1. [PHASE_1_5_RESULTS.md](PHASE_1_5_RESULTS.md) — the device numbers and how each was checked
2. [PHASE_6_RESULTS.md](PHASE_6_RESULTS.md) — the network work
3. `Paper-materials/figures_manifest.csv` — which figure supports which claim

---

# PART 1 — Reformat as a thesis report

It is currently laid out as an IEEE journal submission. It is not one. It is a final-year
undergraduate thesis report, and the format has to change.

## 1.1 Single column, not IEEEtran

In `Paper-materials/paper/main.tex`, replace the document class. Use `report` or `article`
at 12 pt with generous margins — a thesis is read on paper at arm's length, not in a
two-column journal. Keep `\usepackage{siunitx}`, `graphicx`, `booktabs`, `hyperref`.

Consequences you must handle:

- every `\begin{figure*}` becomes `\begin{figure}` — `figure*` only means anything in a
  two-column layout and will error or misbehave outside it
- the ten composite panels were sized for `\textwidth` in a two-column journal, i.e. a
  full page width. In single column they will be much wider. Set them to
  `width=\textwidth` and check each one is legible — if any panel comes out too small to
  read, split it: `figs.py` can emit the sub-figures individually, they are all in
  `Paper-materials/figures/`.
- `\IEEEkeywords` will not exist; use a plain keywords paragraph or drop it
- the `IEEEtran` bibliography style will not be available; use `plain`, `unsrt` or
  `IEEEtranN` if it is installed

## 1.2 Title and submission block

Replace the title and author block with exactly this content, formatted as a thesis title
page:

```
FERROELECTRIC GATE-ALL-AROUND FETS FOR NEXT-GENERATION NEUROMORPHIC SYSTEMS:
DEVICE MODELING AND SPIKING NETWORK IMPLEMENTATION

SUBMITTED BY:
EXAM ROLL: 2326357          EXAM ROLL: 2326356
REG. NO: 2020615833         REG. NO: 2020815831
SESSION: 20-21              SESSION: 20-21

Year and Semester: 4th Year 1st Semester
Date of Submission: 12th November 2025

Department of Electrical and Electronic Engineering
University of Dhaka
```

Two students, side by side. **No author names** — the roll and registration numbers are the
identification. Put it on its own title page (`\begin{titlepage}`), not in a running header.

Do not invent a supervisor name, a department head, an acknowledgements section or a
declaration page. If the department requires those, that is for the students to add.

## 1.3 Section numbering

Once the introduction and literature review exist (Part 2), the order is:

1. Introduction
2. Literature Review
3. Methodology  ← existing `sec_methods.tex`
4. Device Results  ← existing `sec_device_results.tex`
5. Network Results  ← existing `sec_network_results.tex`
6. Discussion  ← existing `sec_discussion.tex`
7. Conclusion  ← existing `sec_conclusion.tex`
8. References

The abstract stays before section 1.

---

# PART 2 — Introduction and literature review

This is the substance of Phase 8. **The research is done by `agy`; the writing is done by
you.** That division is deliberate — read it carefully before starting.

## 2.1 How the research is done

`agy` (the Antigravity CLI) is installed and on PATH. Drive it from Bash:

```bash
agy -p "<your research prompt>" --dangerously-skip-permissions --print-timeout 25m --effort high
```

In every prompt to `agy`, explicitly instruct it to use:

- its **academic deep research skill** — for the substantive literature
- its **last30days skill** — for what has happened very recently in the field

**Rules for the research phase:**

1. **Top journals and recent work.** Prefer IEDM, VLSI, IEEE TED, IEEE EDL, Nature
   Electronics, Nature Communications, Nature Materials, Advanced Materials, Science
   Advances, Advanced Electronic Materials. Prefer 2023–2026. Older papers are fine when
   they are the standard citation for a concept (the 2011 Böscke HZO ferroelectricity
   paper, for example) — mark the year honestly.
2. **Every claim comes back with a DOI and a quoted sentence.** No exception. A finding
   `agy` cannot attach a quote to does not go in the paper.
3. **Run it in pieces, not as one giant call.** Split by topic (see 2.2) so each call
   returns inside the timeout. Four or five focused calls beat one that times out.
4. **Cross-check before you use it.** For anything you are going to state as fact, verify
   the paper exists and says what `agy` reports — fetch the abstract or the paper page
   yourself. A previous run of this pipeline caught `agy` handing back an arXiv preprint
   DOI labelled as a journal publication, and a read voltage relabelled as a memory
   window. Both would have gone into the paper unchallenged.
5. **You write the prose. `agy` does not.** Take its research output as raw material —
   findings, numbers, citations — and write the sections yourself, in the voice of the rest
   of the manuscript. Do not paste `agy` output into the paper.

Save every research return to `Paper-materials/research/` as markdown, one file per topic,
with the `agy` command that produced it at the top. That is the audit trail, and it means a
later session does not have to re-run the searches.

## 2.2 What to research

Five topics. One `agy` call each, minimum.

**A. Why neuromorphic computing, and why in-memory.** The von Neumann bottleneck as it
actually applies to edge inference. Energy per operation for conventional digital
accelerators versus analog in-memory compute. Where the field currently sits on
analog-in-memory accuracy. This motivates the whole thesis and it needs real numbers, not
adjectives.

**B. Analog synaptic devices — the competitive landscape.** RRAM, PCM, ECRAM, FeFET, FTJ.
For each: how the weight is stored, what limits the number of levels, what the reported
programming energy is, and what the known failure modes are. The thesis argues for
ferroelectric devices, so this section has to state fairly what the alternatives do well.

**C. Ferroelectric HfO2 and HZO.** The discovery of ferroelectricity in doped HfO2 and why
it mattered (CMOS compatibility, scalability). The orthorhombic phase. Wake-up, fatigue and
imprint — **this one matters for the thesis specifically**, because the simulation model
used here has none of those terms, and the methodology section already says so. The
literature review is where you establish what those effects are, so the limitation stated
later lands as informed rather than evasive.

**D. FeFET synapses and the gate-all-around architecture.** Reported FeFET synapse work,
level counts, programming schemes, write-verify. Then GAA/nanosheet transistors: why the
industry moved to them, what gate control buys, and whether anyone has published a
ferroelectric GAA device. **If nobody has, say so plainly — that is the gap this thesis
fills and it should be stated as a fact with a search behind it, not as a boast.**

**E. Spiking neural networks for biosignal classification.** SNNs on ECG specifically:
reported accuracies, network sizes, datasets, and what hardware they were deployed on. The
network results in this thesis are on ECG, so the reader needs to know what the field's
numbers look like. Include the source paper for the base network — see
`Paper-materials/../PYTHON_Modelling_Fefet_Codes/ecg detection/` and the project notes;
the real headline accuracy of the paper this network derives from is 95.83 %.

## 2.3 What to write

**Introduction** (roughly 3–5 pages in single column). Motivation from topic A, narrowing
to the specific problem. State the gap. State what this thesis does, in plain declarative
sentences. End with a thesis-organization paragraph. Every factual claim carries a citation.

**Literature Review** (roughly 6–10 pages). Topics B, C, D, E, in that order, each as a
subsection. This is a review, not a list — it should build an argument that arrives at the
gap the thesis addresses. Do not write "X et al. did A. Y et al. did B." Group by idea.

**Both sections must connect forward to the results that already exist.** The introduction
should promise what sections 4 and 5 deliver, and no more. Before you write a word, read
`sec_device_results.tex`, `sec_network_results.tex` and `sec_discussion.tex` so you do not
promise something the results do not contain.

Three findings carry this thesis, and the introduction should point at them:

1. **Where you put the conductance levels matters more than how many you have.**
2. **Level placement is controlled by interface charge, not ferroelectric thickness** —
   ±10 % of fixed interface charge moves levels by 1.31 decades; ±0.3 nm of HZO moves them
   by 0.07. This is the most directly actionable result in the project.
3. **Being able to tell levels apart is not the same as the network working.**

## 2.4 Bibliography

`Paper-materials/paper/literature.bib` currently holds only the 15 benchmark devices, as
data points. Add the narrative citations to it. Keep every entry traceable — the
`Paper-materials/research/` files are where a reader (or a defense committee) can check
where each one came from.

**Never invent a citation.** If a claim cannot be attached to a verified paper, either cut
the claim or write it as your own reasoning without a citation.

## 2.5 Style

Run the `humanizer` skill over each finished section, **one section at a time, in its own
subagent** — not the whole document at once. The existing sections were done this way and
the new ones should match.

---

# PART 3 — One decision you have to make

## The benchmark figure (J5) does not flatter this work, and that is the question

`Paper-materials/figures/J5.png` plots analog level count across 15 surveyed ferroelectric
devices with this work marked. Published counts run 16 to 128. This work is at **8
open-loop** and **~16 with write-verify**. On that axis alone, this device looks worst.

Two things are true and both belong in the decision:

- **The comparison is not like-for-like.** Those papers report a level count with no stated
  separability criterion and no cycle-to-cycle statistics. The 8 here is what survives a
  3σ test against σ measured over 11 repeats of the same pulse train on the same device. It
  is a conservative number produced by a stricter method, and no other row in the table has
  that.
- **The thesis's own central result is that level count does not predict accuracy.** The
  network scored 0.8304 on 15 levels and 0.8036 on 8; four different choices of *which* 8
  gave 0.336 to 0.491. Placement dominates count. A figure showing others reporting more
  levels, immediately before a result showing level count is the wrong figure of merit, is
  an argument rather than a defeat.

**Option A — keep it, reframe it (recommended).** Retitle the subsection along the lines of
"reported level counts are not comparable", make the criterion asymmetry the explicit point,
and lead into the placement result. The current text in `sec_device_results.tex` already
does most of this. A defense committee that asks "how do you compare?" gets a real answer.

**Option B — drop J5.** Panel 10 becomes the planar ablation alone. Defensible for a thesis,
and it removes an axis on which the device looks weak. The cost is that the first question
in the viva becomes "how does this compare to published devices?" and there is no figure.

If you take Option B, also cut the benchmark subsection in `sec_device_results.tex` and
remove the `\nocite{*}` block from `main.tex` — with J5 gone, those 15 entries have nothing
citing them.

**Whichever is chosen, the six medium-confidence rows in
`Paper-materials/literature_benchmark_notes.md` should be spot-checked before submission.**
They are drawn as open markers, but "could not confirm in the paper text" is not a state to
submit in if it can be resolved.

---

# PART 4 — Small remaining items

None of these block Part 1 or Part 2. Do them if there is time.

- **Panel legibility after the single-column reflow.** Check every panel at final size. Any
  panel that is unreadable gets split into its sub-figures.
- **`figs.py --lint` must stay clean.** It refuses two things: a hardcoded width or
  Areafactor, and a literal number typed into drawn text. Both are errors that happened in
  this project and cost real time.
- **The abstract states the system scope honestly** — the computing core is 535.8 pJ per
  heartbeat and the ADCs a real chip would need come to 183 nJ, about 342× more. Keep that.
  It is in the abstract deliberately, not buried.
- **`autoresearch/` and the deleted `graphs.pptx`** are uncommitted working-tree noise.
  Decide whether to commit or clean them.

---

# Do not

- Do not re-run Sentaurus. There is one shared license and every planned run is finished.
- Do not retrain the ECG network. `paper150b_best.ckpt` is final.
- Do not touch `PYTHON_Modelling_Fefet_Codes/eeg detection/`. The EEG task was dropped.
- Do not "update" `Device_Optimization/verify_norm.py`. It deliberately pins old numbers so
  it can detect if the scaling ever breaks again.
- Do not change any number in the results, methods or discussion sections. They are
  reconciled against the figures, and every figure computes its own caption values from the
  data it plotted. If a number looks wrong, check `figures_manifest.csv` and the figure's
  CSV before concluding anything.
- Do not quote the cycle-to-cycle noise figure without saying it came from 11 repeats and
  that the run was cut short at the two-hour job limit.
- Do not let `agy` write paper prose. It researches; you write.
