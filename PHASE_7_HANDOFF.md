# Phase 7 handoff — clear the leftovers, make the figures, write the paper

Paste everything below the line into a fresh session. It is self-contained.

Do not touch `PYTHON_Modelling_Fefet_Codes/eeg detection/`. The EEG task was dropped.

---

## Where things stand

Repo: `F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet`, branch `paper/gap-fix`.

The simulations are done. There are 109 run nodes on disk and 1377 CSVs, and every planned
re-run (RR-0 through RR-10) has finished and been analysed. The SNN work is done too.

What is left is: clean up four loose ends, draw about sixty figures from data that is
already on disk, and write the paper.

Read these three first. They are short and they are the source of truth for every number:

1. [PHASE_1_5_RESULTS.md](PHASE_1_5_RESULTS.md) — the device numbers and how each was checked
2. [PHASE_6_RESULTS.md](PHASE_6_RESULTS.md) — the SNN work, figures K2/K3/K4
3. [PLOT_PLAN.md](PLOT_PLAN.md) — the list of 79 figures and where each one's data lives

Work in order. Part 0 first — two of those items change numbers that go in the paper, so
doing them after you start writing means rewriting.

---

# PART 0 — Clear the leftovers (half a day)

## 0.1 Make the two documents agree about RR-8b

Two files currently disagree about the same measurement. `PHASE_1_5_RESULTS.md` says the
cycle-to-cycle run gave **9** repeats with a spread of about 0.015 decades.
`PHASE_6_RESULTS.md` and the committed data say **11** repeats and 0.0215 decades.

Both were written while the data was still downloading, so one of them is simply out of date.

```bash
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet" && python rranalyze.py rr8b
```

Whatever that prints now is the truth. Then:

- open `PHASE_1_5_RESULTS.md` §4 and `PHASE_6_RESULTS.md` §6.4c and make both match it
- keep the repeat count next to the spread **everywhere it is quoted**, because the run was
  cut off by the two-hour job limit and never finished its 20 repeats
- do not average the two versions

If the numbers moved, also re-make the figure that depends on them:

```bash
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet/PYTHON_Modelling_Fefet_Codes/ecg detection" && python fig_k3_variability.py c2c
```

That takes about 40 minutes. Only run it if 0.1 actually changed the numbers.

## 0.2 Decide how many analog levels the paper claims

**This is the paper's headline device number and the two documents currently contradict each
other. Settle it before you write anything.**

The disagreement:

- `PHASE_1_5_RESULTS.md` says the device has **8 usable levels**, because levels 9 to 15 are
  packed so close together at the top of the range that cycle-to-cycle noise smears them into
  each other. It concludes that "15 levels" is only honest if you have write-verify circuitry.
- `PHASE_6_RESULTS.md` measured what happens if you actually deploy the network on only those
  8 levels: accuracy drops by 0.036. Deploying on all 15 under the measured noise costs 0.001.

Both are correct. They are answering different questions, and the paper needs to say so:

| what you are claiming | number | why it holds |
|---|---|---|
| the device, no verify circuitry | **8 levels** | levels 9–15 sit inside 0.11 decades, noise is 0.013–0.022 decades |
| the device, with write-verify | **~16 levels** | the measured range is 3.79 decades wide |
| what the network was deployed on | **15 levels** | assumes write-verify |

So: **state plainly, in both the device section and the network section, that the network
result assumes a write-verify array.**

That is not a weakness, and it should not be written apologetically. Figure K3a already shows
write-verify is unavoidable for this device anyway — without per-device calibration, deploying
onto the 20 corner devices drops accuracy to 0.243. With it, you get 0.8304, which is the
nominal result to four decimal places. The system needs write-verify regardless of the level
count, so the 15-level claim costs nothing extra.

If you skip this, a reviewer reads "8 levels" in one section and "15 levels" in the next and
concludes the paper contradicts itself.

## 0.3 Finish DIBL, or drop it on purpose

DIBL is currently not reported because two ways of extracting it disagreed about the *sign*.

The cause was found: on the wide −1.5 V sweep the transistor's off state is V-shaped (current
falls, bottoms out, then rises again). A naive search finds the falling side first and reads a
threshold from the wrong carrier, which gave a nonsense −241 mV/V. The fix is already in
`rranalyze.py` — `vth_cc()` now takes `after_min=True`, which starts looking from the bottom
of the V.

The data is on disk (`t11_dibl` finished). Finish the job:

```bash
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet" && python rranalyze.py rr2
```

Then check that the erased and programmed branches now give DIBL values with the **same sign**
and a sensible size (tens of mV/V, not hundreds).

- If they agree → report DIBL, and say in the methods which criterion you used.
- If they still disagree → leave DIBL out of the paper and say why in one sentence. Do not
  report a number you cannot reproduce two ways.

## 0.4 State the 2D limitation in the methods (writing task, no simulation)

**Decision already taken: no 3D simulation. Do not start one.**

Everything here is simulated as a **2D slice** of the transistor and scaled up to a nanosheet
by multiplying by a width factor. RR-10 proved that scaling is arithmetically exact to
1.8e-16. That proves the multiplication is right; it does not prove a flat slice behaves like
a real wrapped gate, which has corners and edge fields a slice cannot show.

Since we are not running the 3D check, the paper must say so plainly. Put a short paragraph in
the methods that states:

- the device is modelled as a 2D double-gate cross-section, mapped to a nanosheet through the
  gate perimeter (`Device_Optimization/norm.py`, 90 nm)
- the mapping was verified to be exact arithmetic (RR-10), and that is the extent of what was
  verified
- a full 3D gate-all-around simulation was not performed, so corner and edge-field effects are
  not captured

That is a normal, survivable limitation — plenty of published device work is 2D. What is not
survivable is a reviewer discovering it themselves. Write it in your own voice, do not
apologise for it, and do not bury it.

## 0.5 What NOT to run

**Do not re-run the endurance simulations.** The ferroelectric model used here has no wear-out
physics in it at all — no fatigue, no wake-up, no imprint. Cycling it more times produces a
perfectly flat line, because a flat line is what the equations say, not what a real device
would do. The 10-cycle run already hit the 2-hour limit and was recorded as not completed;
that cost you nothing scientific.

Either caption the existing cycling data as "write repeatability", making clear it is not an
endurance measurement, or leave that figure out. Do not spend machine time here.

**Do not bother finishing the cycle-to-cycle run to 20 repeats.** It would narrow the error bar
on the noise figure from about ±22 % to ±16 %. The conclusion does not change. Only worth it if
the machine is sitting idle anyway.

---

# PART 1 — Build one figure script (do this before drawing anything)

Right now there are 57 image files spread across four folders, made by six different scripts.
Nothing checks that a figure still matches the data it claims to show.

That is not a theoretical worry. In the last phase, **four figures were found to be showing
old data** — they had been drawn before a correction and never re-drawn, so they were showing
numbers 1.578× too large. A fifth was plotting a settling transient and calling it retention.
Nobody noticed for months.

So before drawing sixty more, build the thing that prevents it. PLOT_PLAN calls this item 0.7
and it was never done.

Write `Paper-materials/figs.py`:

- one function per figure, named after the figure ID — `def A1(): ...`, `def D2(): ...`
- a command line: `python figs.py --fig D2` and `python figs.py --all`
- one shared style block — reuse the existing
  `PYTHON_Modelling_Fefet_Codes/Combined Figures/figstyle.py`, which already matches the
  supervisor's requirements (bold text everywhere, tick marks inside the axes on the left and
  bottom only, no plot titles, thick axis lines)
- every figure saves three things: a 600 dpi PNG, a vector PDF, and the CSV of exactly the
  numbers it plotted
- every figure gets its current scaling from `Device_Optimization/norm.py` and never hardcodes
  a width or scale factor of its own
- **no figure is allowed to print a number in its caption or annotation that it did not
  calculate from the data on screen.** One published figure had "MW = 1.30 V" typed into it as
  plain text. It happened to be right, but it could never have caught an error.

Move the existing figure code into this script as you go, and delete the old copies once
they're ported. Two scripts drawing the same figure is how the last set drifted.

---

# PART 2 — Fix the figures that already exist (about a day)

PLOT_PLAN items 1.1 to 1.7. These figures exist but are wrong, misleading, or weak:

- the polarisation loops have a sign error and need re-captioning (C2)
- dynamic range vs read voltage (I5) replaces the old Figure 8
- the potentiation curve should be on a log axis with the level bands marked (F1)
- the temperature curves need a log axis plus an Arrhenius panel (F9)
- the retained current-voltage curve needs annotating (D1)
- the oxide-thickness and ferroelectric-thickness figures should be merged (I2, I3)
- retention (H1)

For retention, use `dev3_retention.png` as your model — it was rebuilt correctly in the last
phase, and it shows how to present a measurement where the first part of the curve is the
device settling down and only the flat part afterwards is the real result.

---

# PART 3 — Draw the remaining figures (about three days)

PLOT_PLAN items 2.1 to 2.10 — roughly sixty figures. **All of the data is already on disk.
None of this needs a simulation.**

The groups are: write transients (chapter E), the neuron circuit figures (chapter G, which uses
224 files nobody has touched yet), more current-voltage figures (D5–D10), the electric-field and
voltage-divider figures (C3–C8), the synapse analysis set (F2–F11), the design-space set
(I1–I10), the calibration chapter (B1–B9), four drawn schematics (A1, A4, A5, A6), the
comparison against the flat-transistor version (J1–J4), and H2/G7.

If a figure looks like it needs a new simulation, check `Device_Optimization/outputs/` first.
There are 109 run folders there, and an earlier phase converted 483 files that had been sitting
unused.

## 3.11 The two comparison-to-other-work figures (different job, plan time for it)

Two figures cannot be drawn from this repo at all, because their data is other people's
published results:

- **J5** — analog levels vs energy per pulse, with this work marked on it
- **J6** — memory window vs operating voltage, same idea

These need someone to go and read papers: pull ten to twenty published ferroelectric-memory
devices, record levels / energy per pulse / memory window / operating voltage for each, and
build a small table with a citation per row. Save it as
`Paper-materials/literature_benchmark.csv` with a `source` column giving the citation, so the
numbers can be checked later.

**J5 is needed for main-text panel 10**, so it is not optional if you want the full ten
composites. J6 is a nice-to-have and can be dropped or moved to supplementary.

Be realistic about this one: it is a couple of hours of careful reading, not a scripting task,
and it is the one part of the figure work that cannot be automated or harvested. Do not put it
at the end and run out of time — the comparison-to-others figure is often the first thing a
reviewer looks at.

## 3.12 A problem with main-text panel 9

PLOT_PLAN builds panel 9 (reliability) from **H1 + H4 + H5**, and H5 is the endurance figure.
Since the endurance simulation is not being re-run (see 0.5), you have two options:

- build panel 9 as **H1 + H4 + H8** (retention, mid-state retention, read disturb) — read
  disturb is a genuinely strong result: 0.0000 % drift over 990,000 equivalent reads
- or keep H5 but caption it honestly as write repeatability, making clear it is not an
  endurance measurement

The first is cleaner. Read disturb is real evidence about the device; the cycling figure is
mostly evidence about the model.

---

# PART 4 — Assemble

- **Ten combined figures for the main text.** PLOT_PLAN section 5.1 already specifies which
  figures group together. The remaining ~50 become supplementary material.
- **A tracking table**, `figures_manifest.csv`, with one row per figure: figure ID, the raw file
  it came from, the function in `figs.py` that draws it, **the specific claim it supports**, and
  which scaling convention it used. This permanently kills the "where did this number come
  from" problem that cost this project nine errors.
- **The methods section.** It must cover:
  - that the device is a 2D cross-section scaled to a nanosheet, and that the absolute current
    level is **not** calibrated against experiment (the memory window, threshold voltage,
    subthreshold slope, on/off ratio and turn-on shape *are* calibrated)
  - which write/read timing was used for which figure
  - the two different on/off numbers and what each means: **5410×** is the retained memory
    window, **18.4×** is the read contrast after nine pulses. Never print them next to each
    other without saying which is which.
  - the working rules listed below

---

# PART 5 — Write the paper

Target is IEEE TED. You are not starting from a blank page: `METHODOLOGY.md`, `README.md` and
`PHASE_6_RESULTS.md` already contain most of the argument in draft form.

Three findings are genuinely new and should carry the paper:

**1. Where you put the conductance levels matters more than how many you have.**
With 8 levels, four different choices of *which* 8 gave accuracies from 0.336 to 0.491, while
spacing them evenly gave 0.804. Separately, once each device is given a simple gain
adjustment, what predicts its accuracy is how far its worst level sits from where it should
be — accuracy holds up to about 0.6 decades of error and falls apart by 0.9. Two independent
analyses, same conclusion.

**2. Level placement is controlled by interface charge, not by ferroelectric thickness.**
Changing fixed interface charge by ±10 % moves levels by 1.31 decades. Changing the
ferroelectric thickness by ±0.3 nm moves them by 0.07. This was the opposite of what everyone
expected, and it is the most directly useful result in the whole project — it tells a
fabrication team what to control.

**3. Being able to tell levels apart is not the same as the network working.**
Three separate measurements of "can you distinguish one level from the next" — and none of
them predicted accuracy. What predicts accuracy is how far the deployed weight ends up from
the weight you wanted.

**And state the scope honestly, in the abstract, not buried at the end.** The computing core
uses 535.8 pJ per heartbeat. The analog-to-digital converters that a real chip would need come
to 183 nJ — about 342 times more, under a standard assumption for their cost. The device is not
the limiting factor in a complete system. Say so before a reviewer does; it costs nothing and
it buys credibility for everything else.

---

## Working rules — these belong in the methods section

Each of these came from a real mistake caught in this project.

1. **Only compare two measurements taken in the same run.** Three published numbers compared
   readings from different runs and were wrong because of it.
2. **Wait for the device to settle before reading it, and always say how long you waited.**
   Reading too early created three separate fake failures — a retention collapse, a read-disturb
   collapse, and an endurance collapse — all of which looked like honest bad news.
3. **Always say how a threshold voltage was extracted.** The same calibration data gives
   1.218 V or 1.296 V depending on the current level you define the threshold at. Both are
   correct; neither means anything without saying which.
4. **A simulation finishing without an error is not a result.** Two runs completed cleanly with
   zero electric field everywhere. Look at the numbers.
5. **Check results that flatter you as hard as results that don't.**
6. **Count things instead of assuming them.** The synapse count was wrong by a factor of 24
   because nobody counted the delay taps in the network.
7. **A figure may not display a number it did not calculate.**

## Do not

- Do not touch `PYTHON_Modelling_Fefet_Codes/eeg detection/`. The EEG work was dropped.
  `build_defense_pdf.py` still has EEG sections, marked as out of date — leave the marks, don't
  re-run them.
- Do not retrain the ECG network. The checkpoint `paper150b_best.ckpt` is final.
- Do not "update" `Device_Optimization/verify_norm.py`. It deliberately holds old numbers so it
  can detect if the scaling ever breaks again. Changing it destroys the only thing it does.
- Do not quote the cycle-to-cycle noise figure without saying how many repeats it came from and
  that the run was cut short.
- Do not re-download `t14_end10` expecting a complete run. It is a partial, cut off at two hours.
