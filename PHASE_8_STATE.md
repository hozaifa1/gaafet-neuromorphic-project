# Phase 8 — state at pause (2026-08-03)

Branch `paper/gap-fix`, nothing committed yet this phase. All work is on disk.

## Done

**Part 1 — thesis reformat: complete.**
`Paper-materials/paper/main.tex` is now `\documentclass[12pt,a4paper,oneside]{article}`,
single column, geometry left 1.25in / right 1in / top 1in / bottom 1in, one-and-a-half
spaced. Title page carries the exact roll/reg block with no author names, then abstract,
keywords, TOC. Section order: Introduction, Literature Review, Methodology, Device
Results, Network Results, Discussion, Conclusion, References. `\section{Method}` renamed
to `Methodology`. Bibliography pulls three files: `literature.bib`,
`literature_narrative.bib` (introduction), `literature_review.bib` (literature review).

**Part 3 — decision made: Option A.** J5 stays. The subsection is retitled
"Reported level counts are not measured against a common criterion" so the criterion
asymmetry is the heading rather than a defence in paragraph two. `\nocite{*}` stays.

**Part 2 — research: complete and verified.** Five dossiers in `Paper-materials/research/`
(A motivation, B synaptic devices, C HZO ferroelectricity, D FeFET+GAA, E SNN/ECG), each
claim tagged VERIFIED / MISMATCH / UNVERIFIED against Crossref, each with a `## Do not
cite` section and a Crossref-authoritative BibTeX block. Raw agy returns kept alongside.

**Part 2 — writing: both sections drafted and humanized.**
`sec_introduction.tex` (~1258 words) and `sec_literature.tex` (~3000 words, four
subsections).

**Part 4 — panels: fixed.** Every panel restacked to one column (`ncol=1` in the `PANELS`
dict in `figs.py`); panel 8 split into panels 8 and 11; the five tall panels are
`[p]` floats at `height=0.9\textheight`. Row gap widened (`hspace` 0.02 -> 0.12 when
`nrow > 1`) because the (b)/(c) letters collided with the axis label of the row above.
Effective text size went from ~3 pt to ~7-10 pt, checked by rendering at true print size.
`figs.py --lint` clean.

**Part 4 — housekeeping.** `autoresearch/` is a clone of Karpathy's repo, added to
`.gitignore`. Root `graphs.pptx` was a duplicate of `Paper-materials/graphs.pptx`; its
deletion is staged. `literature.bib` regenerated with real Crossref metadata for all
fifteen benchmark entries (they were placeholder authors and invented titles, and
`\nocite{*}` prints them all).

## THE FINDING THAT CHANGED THE THESIS

The handoff's premise was wrong. **Ferroelectric gate-all-around devices are published
work.** Six DOI-verified papers; the closest is Lin & Su, *IEEE Open J. Nanotechnology*
2024, `10.1109/ojnano.2024.3399559` — a simulated stacked-nanosheet FeFET synapse under
cycle-to-cycle variation. Verified against Crossref directly. Never claim first-ness.
The contribution is staked instead on: calibration against a measured transfer
characteristic, a measured write-energy and cycle-to-cycle budget, level *placement* vs
count, the interface-charge-over-thickness ranking, and a trained SNN deployed on the
measured ladder with the ADC term stated. Both new sections are written on that footing.
Saved to memory as `project_gaa_fefet_prior_art.md`.

## In flight when paused — CHECK THESE FIRST

1. **`benchmark-apply` agent.** Applying verified corrections to
   `Paper-materials/literature_benchmark.csv`: `Song2024_AdvSci` n_levels **128 -> 140**
   (the 128 was an inference from ">7-bit"; the full text at PMC11040367 states 140), and
   `confidence` medium -> high for Park2026_AMI (64), Kim2023_APLMater (16),
   Kim2026_ACSNano (22), Bohuslavskyi2024_AdvElecMater (20). `Gao2024_NanoLett` stays
   medium — the paper states no count and it is dropped from the plot anyway.
   Then: update the J5 `claim=` string in `figlib/j_compare.py` from "16 to 128" to
   "16 to 140", regenerate J5 and panel 10, and fix two things in
   `sec_device_results.tex` — the caption sentence "Open markers are counts that could not
   be confirmed in the paper text" (no plotted point is open any more) and the body text
   "run from sixteen to a hundred and twenty-eight" and "six of the fifteen rows carry
   that caveat".
   **Verify this landed. If it did not, apply it by hand — the correction runs against
   this thesis's interest (140 becomes the survey's highest count) and must not be
   dropped.** None of the five papers states a separability criterion, which supports the
   subsection's argument independently.
2. **`humanize-lit` agent.** Humanizer pass over `sec_literature.tex`. It was told NOT to
   run a build. Check the file still has balanced LaTeX.

## Next steps, in order

1. Check the two agents above landed; finish their work by hand if not.
2. **Serialized final build.** Concurrent `latexmk` runs in `Paper-materials/paper`
   corrupted each other's aux files during this session (NUL bytes through `main.aux`,
   `main.toc`, `main.bbl`). Delete `main.aux main.bbl main.toc main.out main.fls
   main.fdb_latexmk` first, then one clean `latexmk -pdf -g -interaction=nonstopmode
   main.tex`. Confirm zero errors, zero undefined references, zero undefined citations.
3. Read the built PDF end to end at final size — title page, TOC, panel placement, the
   reference list rendering with real titles.
4. Commit. Identity: `git -c user.name="hozaifa1" -c user.email="20hozaifa02@gmail.com"`.

## Standing rules for this work

- Do not re-run Sentaurus; do not retrain the network; do not change a results number
  unless the underlying datum was verified wrong (the Song 140 correction is the only
  such case so far).
- A dossier claim tagged VERIFIED means the paper exists and matches its metadata. It does
  **not** mean the number in the summary line appears in the quoted sentence. Two errors
  in the introduction were caught exactly there: a "640 pJ per 32-bit DRAM word" figure
  absent from both quotes cited for it, and a cross-reference to `sec:variability` where
  the interface-charge result actually lives at `sec:interface`. Check quotes, not tags.
- The research passes returned real DOIs carrying fabricated author lists, one DOI
  resolving to an unrelated delta-sigma ADC paper, and one number ("500 states") that its
  source gives as "up to 1000". Everything cited was re-verified against Crossref.
