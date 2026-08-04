# Literature benchmark — notes

## Summary

15 rows delivered (target was 12-20). All ferroelectric analog synapse devices
(FeFET + FTJ) — did not need to fall back to RRAM/PCM/ECRAM since >10
ferroelectric rows were confirmed. Confidence breakdown: **10 high, 5 medium,
0 low**. No row was invented; every row has a `source_quote` I actually read,
either directly in agy's extraction or independently re-confirmed via
WebSearch against a second, independent description of the paper's content.

## Process

Ran three `agy` deep-research calls in parallel background processes (see
exact commands below), split by device family: FeFET, FTJ, and
FeCAP/seminal-benchmark papers. All three returned inside ~4-5 minutes.

Combined raw output: 22 candidate rows. **agy's raw CSV had a systematic
formatting bug**: whenever several consecutive numeric columns
(`n_levels`/`energy_per_pulse_pJ`/`v_program_V`/`pulse_width_ns`/
`memory_window_V`) were blank, agy sometimes emitted one comma too few or too
many, shifting later fields (year/venue) out of position in the raw text. I
did not trust the raw column positions — I cross-checked every row that had
any numeric content against an independent WebSearch query (title + DOI +
the claimed number) and manually rebuilt the row from confirmed facts rather
than parsing the raw CSV positionally. This is also how I caught one wrong
DOI (below).

## Rows dropped (7 of the original 22) and why

- **Guan2024_AMT** (PZT FTJ, Adv. Mater. Technol. 2024) — real paper
  (10.1002/admt.202302238, confirmed), but agy's row carried zero
  quantitative data in any of the five metric columns — only a qualitative
  claim about a "mixed voltage pulse scheme" and ~92% CIFAR10 accuracy at
  the neural-network level, not the device level. Nothing to plot.
- **Zheng2025_SciAdv** (BFO FTJ on semiconductor, *Sci. Adv.* 2025,
  10.1126/sciadv.ads0724) — real paper, but its actual headline result is
  fatigue resistance (>10^8 cycles), not a memory window. agy's row put
  "0.2" in `memory_window_V`, but the quote it gave for that number was
  actually describing a *read voltage*, not a memory window — a
  field/quote mismatch I could not fix without inventing a number.
- **Lancaster2024_AMI** — agy gave DOI `10.48550/arxiv.2407.15796`
  (an arXiv preprint) while claiming venue "ACS Appl. Mater. Interfaces."
  I found the real published version: **10.1021/acsami.4c10338**,
  "Weight Update in Ferroelectric Memristors With Identical and
  Nonidentical Pulses" (Lancaster et al., ACS AMI 2024). Confirmed real,
  confirmed the quoted "86% linearity / 30 uC/cm2" figure — but that
  metric doesn't map onto any of our five required columns (no n_levels,
  energy, V, pulse width, or memory window given), so I dropped it rather
  than force a fit.
- **Mulaosmanovic2017_VLSI** — genuinely the first single-FeFET-synapse
  demonstration (28 nm GF HKMG, VLSI 2017, confirmed real,
  10.23919/VLSIT.2017.7998165) but it is a qualitative
  multi-bit-programmability demo; I could not find a specific level count,
  energy, or memory-window number to put in any column.
- **Zheng2019_EDL** (Al:HfO2 MFM FeCAP, IEEE EDL 2019,
  10.1109/LED.2019.2921737) — real paper ("Artificial Neural Network Based
  on Doped HfO2 Ferroelectric Capacitors With Multilevel Characteristics"),
  but I could only confirm "multilevel" qualitatively plus a
  system-level 78% MNIST accuracy — no device-level n_levels/energy/window
  number.
- **Luo2023_ACSAMI** (ferroelectric-polymer voltage-mode synapse, ACS AMI
  2023, 10.1021/acsami.3c09506) — real paper, 97% MNIST accuracy at
  network level, but no device-level quantitative metric in our schema.
- **Lou2024_TED** (double-HZO FeFET, IEEE TED 2024,
  10.1109/TED.2024.3480054) — real paper about opposite-polarity-assisted
  detrapping, but the "16" in agy's row is a *conductance ratio*
  (Gmax/Gmin > 16x), not a confirmed discrete level count, and no other
  metric was available. Ambiguous enough that I dropped it rather than
  mislabel a ratio as `n_levels`.

## Verification round, 2026-08-03 — the medium rows resolved

The six medium-confidence rows below were re-checked against the source text. Five are
now resolved and carry `confidence = high`; the sixth stays medium. The confidence
breakdown in the summary above is superseded: it is now **14 high, 1 medium, 0 low**.
Note that the summary's "5 medium" count was itself wrong — the CSV had six medium rows,
because `Gao2024_NanoLett` was never discussed in the weakest-rows list below.

| row | route | verdict |
|---|---|---|
| `Song2024_AdvSci` | Europe PMC full text, PMC11040367 | **CORRECTED, 128 -> 140.** The 128 was arithmetic from the abstract's ">7-bit"; the body text states "we fabricated allowed us to confirm 140 levels". This raises the survey maximum and moves against this work. |
| `Park2026_AMI` | Semantic Scholar abstract | CONFIRMED at 64: "64 well-resolved conductance states". |
| `Kim2023_APLMater` | Crossref + Semantic Scholar abstract | CONFIRMED at 16: "16 states comprising four bits". |
| `Kim2026_ACSNano` | Semantic Scholar abstract | CONFIRMED at 22: "22 programmable conductance states". |
| `Bohuslavskyi2024_AdvElecMater` | Crossref + Semantic Scholar abstract | CONFIRMED at 20: "At least 20 reproducible analog states for temperatures below 100 K". |
| `Gao2024_NanoLett` | Crossref + Semantic Scholar abstract; ACS full text 403s, no PMC record, no open-access copy | **UNSTATED.** The paper gives no level count. `n_levels` stays blank, so the row is dropped from J5 by `dropna` and plots no point. Stays medium: the abstract is the only reachable text, so a count buried in the body cannot be ruled out. |

**The finding that matters more than any individual count: not one of the five states a
separability criterion or a cycle-to-cycle statistic behind its number.** Park2026 says
"well-resolved" and Bohuslavskyi says "reproducible" with "almost ideal linearity", but
neither attaches a sigma, a read margin, or a repeat count. This is independent support
for the argument in `sec_device_results.tex` that published level counts are not measured
against a common criterion, and it is why this work's own eight-level count is reported
under an explicit three-sigma test against noise measured over eleven repeats.

Consequences applied: `n_levels` and `source_quote` updated for Song2024_AdvSci;
`confidence` raised on the five; the J5 `claim=` string in `figlib/j_compare.py` now reads
"16 to 140"; J5 and panel 10 regenerated; and the caption and body prose in
`sec_device_results.tex` corrected, since no plotted point is an open marker any more.

## Rows I'd flag as the weakest of the 15 kept

*(Written before the verification round above; the five medium rows named here have since
been resolved. Kept for the record of what the original doubts were.)*

- **Song2024_AdvSci** (medium) — the 48 aJ/spike energy and 1 us pulse width
  are solidly confirmed (independently, via a PMC listing of the same
  paper). The `n_levels=128` is *not* directly quoted — it's my arithmetic
  inference from the paper's ">7-bit operation" claim (2^7=128), flagged as
  such in the quote. If a reviewer wants a hard level count for this row,
  it needs to come from the actual figure/table, not this inference.
- **Kim2026_ACSNano** (medium) — DOI and paper (ACS Nano, "Thermal
  Expansion-Engineered Ferroelectric Transistor Arrays") are confirmed
  real, but my independent WebSearch verification echoed back nearly the
  exact phrasing of my own query, which raises the possibility it is not
  an independent confirmation of the "22 states / 11 V window" numbers,
  just a repetition of what I asked for. I could not rule out that agy's
  number is right, but I also couldn't independently double it, hence
  medium not high.
- **Park2026_AMI** (medium) — paper confirmed real and on-topic
  (ITO/HZO/WOx FTJ, ACS AMI 2026), but I was not able to independently
  verify the specific "64 states / >10^8 cycles" figures beyond agy's
  extraction.
- **Kim2023_APLMater** (medium) — my own search explicitly said it could
  not confirm the "16 states / 4 bits" detail (it's apparently buried
  past the abstract). Kept at medium since the quote reads like real paper
  language and the paper/DOI are genuine, but this is the row I'd double-
  check first if this figure ever surprised a reviewer.
- **Bohuslavskyi2024_AdvElecMater** (medium) — paper confirmed real and
  on-topic (cryogenic HZO analog memory), but my independent search
  surfaced a *different* pair of numbers from the same paper (Pr=75
  uC/cm^2, memory window 6-8 V) rather than confirming the specific
  "20 states" figure agy quoted. Both could be true simultaneously
  (different operating regimes), but I couldn't independently pin the "20."

## What I could not find

- No FeCAP (bare ferroelectric-capacitor, non-transistor) row with a
  device-level n_levels/energy/window number survived verification — all
  three FeCAP candidates I found (Zheng2019, Luo2023, and one more) had
  only qualitative or network-level claims.
- No row was needed from RRAM/PCM/ECRAM — 15 ferroelectric rows already
  clear the 10-row threshold.
- I did not attempt to compute `energy_per_pulse_pJ` from V/C/t for any row
  where energy wasn't directly stated, because none of the confirmed rows
  gave a capacitance value — computing it would have required guessing a
  device capacitance, which the task rules disallow.

## Exact agy commands run

```
agy -p "<FeFET research prompt, full text below>" --dangerously-skip-permissions --print-timeout 30m --effort high
agy -p "<FTJ research prompt, full text below>" --dangerously-skip-permissions --print-timeout 30m --effort high
agy -p "<FeCAP/seminal research prompt, full text below>" --dangerously-skip-permissions --print-timeout 30m --effort high
```

All three were launched detached (`nohup ... &`) in parallel and polled
until their output files stopped growing and the processes exited (all
three finished within ~4-5 minutes). Each prompt instructed agy to use its
academic deep research skill and last30days skill, targeted 2024-2026
top-venue papers (IEDM, VLSI, IEEE TED/EDL, Nat. Electron., Nat. Commun.,
Adv. Mater., Sci. Adv., APL), and required the same 12-column CSV schema,
a real resolvable DOI, and an exact `source_quote` per row, with explicit
instructions not to fabricate.

After collecting agy's output, every row with any numeric content was
independently re-verified with a separate `WebSearch` query per DOI before
being kept, which is how the wrong Lancaster DOI and the Zheng2025
field/quote mismatch were caught.
