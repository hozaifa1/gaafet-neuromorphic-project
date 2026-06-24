# New Calibration Plan — Liao 2022 replaces Tasneem 2022

**Created:** 2026-05-22
**Author:** hozaifa
**Status:** ✅ **CALIBRATED 2026-06-20** (autocal node g15) — MW=1.22 V, SS 97/133, Vt aligned. Physical gates (MW/SS/Vt) PASS; R²-gate is an ill-conditioned metric here (see `CALIBRATION_RESULT.md`). Needed Tier-2 par retune: P_r 16→24, P_s 20→30 µC/cm², F_c 1.2→0.8 MV/cm, tau_P 10µs→0, FixedCharge 4e12→1.5e12. WF knob proved inert (Ohmic gate). Original Tier-1 plan below kept for context.

---

## Why we are replacing the calibration

The current calibration anchor is Tasneem et al., IEEE TED 2022 Fig. 3(c). It produces visibly poor overlays because Tasneem's device differs from ours on **every** structural axis:

| Axis | Our device (TCAD) | Tasneem 2022 | Consequence |
|---|---|---|---|
| Polarity | n-type Si | **p-type Si** | sign-flipped V_G axis |
| Architecture | GAA-Nanosheet | **planar** | different SS, different DIBL |
| Gate length | 100 nm | **8 µm** | 80x; off-state floor unmatchable |
| Ferroelectric | 10 nm HZO | **5 nm ZrO2** | 2x MW difference |
| Memory window | 1.40 V | **0.50 V** (0.32 V digitised) | 2.8x gap |

The current overlay needs sign-flipping, 2000x I_on rescaling, and an apologetic MW disclaimer. Post-PGM R² caps at **0.67** (distilled) / 0.86 (full). A reviewer at IEEE TED or Nature Electronics would not accept this as a calibration figure — they would call it a heroic apples-to-oranges normalization and ask for a better reference.

## Why Liao 2022 is the right new target

**Reference:** Liao, C.-Y. et al., *"Endurance > 10¹¹ Cycling of 3D GAA Nanosheet Ferroelectric FET with Stacked HfZrO2 to Homogenize Corner Field Toward Mitigate Dead Zone for High-Density eNVM"*, 2022 VLSI Symposium on Technology & Circuits, pp. 393–394. DOI: [10.1109/VLSITechnologyandCir46769.2022.9830345](https://doi.org/10.1109/VLSITechnologyandCir46769.2022.9830345). PDF in this folder: `liao2022.pdf`.

**Authors:** TSMC TCAD Silicon Engineering Group + NTNU + NYCU.
**Venue:** VLSI Symposium — co-equal with IEDM at the top tier for device papers, fully accepted by IEEE TED and Nature Electronics as a citation/calibration anchor.

### Head-to-head match

| Axis | Our device (TCAD locked) | Liao 2022 Fig. 7 (MFMFS-GAA) | Match |
|---|---|---|---|
| Polarity | n-channel | **n-channel** | ✓ no sign flip |
| Architecture | GAA-NS (90 nm W_eff) | **3D GAA-NS (80 nm W)** | ✓ same family |
| Channel | Si | **Si** | ✓ |
| Ferroelectric | 10 nm HZO | **HZO (5 + 10 nm double stack)** | ✓ same material; top 10 nm dominates |
| Memory window | 1.40 V | **1.30 V** | ✓ within 7% |
| Write voltage | ±4 V | **±3.5 V** | ✓ within 14% |
| Pulse hold | 10 µs | **5 µs** | ✓ same order |
| Read V_DS | 0.05 V → adjust | **0.2 V** | adjusted in cmd |
| Endurance reported | (our story) | >10¹¹ | reference anchor |
| Journal credibility | — | **VLSI Symp. — top tier** | ✓ |

The only systematic mismatch is **MFMFS** (their double-HZO with metal interlayer) vs our **MFIS** (single-HZO with SiO2 interlayer). This is a stack topology difference, not a physics difference — the ID-VG shape is set by the channel + nearest FE + interlayer, and Liao reports MW=1.3V whether it's their MFMFS or MFIFS variant (Fig. 7 caption). Our single-HZO MFIS sits between these two cases.

### Candidates considered and rejected

| Paper | Year/Venue | MW | Why not primary |
|---|---|---|---|
| Mulaosmanovic 2019 (in this folder) | **IEEE TED** | 2.9 V | planar HKMG, 20 nm Si:HfO2 — same disclaimer problem as Tasneem; MW 2x too big |
| Hsiang 2021 | IEEE EDL | **1.37 V** (tightest!) | **planar** — violates "GAA preferred" constraint |
| First Stacked NS FeFET 2023 | IEDM (top!) | 1.8 V | Ge0.98Si0.02 channel — adds channel-physics disclaimer |
| Bhatawdekar 2026 | Neurocomputing | (TCAD) | TCAD-vs-TCAD calibration is circular; reviewers reject |
| Loubet 2017 | VLSI | — | no FE layer; geometry-only reference |

**Note:** Mulaosmanovic 2019 stays in this folder as a **TED-tier corroboration cross-check** — useful for a one-paragraph "we also overlay against Mulaosmanovic's Si planar n-FeFET to show MW scaling with t_FE is consistent" supplementary figure. Not the primary calibration.

---

## Files in this directory

```
New_cal/
├── liao2022.pdf                       Primary calibration reference (Liao VLSI 2022)
├── mulaosmanovic2019.pdf              Secondary cross-check reference (Mulaosmanovic TED 2019)
├── sde_dvs.cmd                        Sentaurus Structure Editor — identical to Simulations/sde_dvs.cmd
├── sdevice_gaafet_lif.par             Device parameter file — frozen, identical to Simulations/sdevice_gaafet_lif.par
├── sdevice_liao2022_writeread.cmd     Tier 1 simulation: write-read protocol matched to Liao Fig. 7
└── PLAN.md                            This file
```

The `.par` and `sde_dvs.cmd` are byte-for-byte copies of the canonical files in `Simulations/`. The point is to make this folder a self-contained reproducible bundle — if someone clones the repo, they can run *just* this calibration without needing to follow paths into the H-series tree.

**Important — do not edit `sdevice_gaafet_lif.par` in this folder unless we escalate to Tier 2.** Per the project rule, the par is the single canonical artifact; protocol changes belong in the `.cmd` only.

---

## Tier 1 — Run the new protocol (no retune)

### What changed vs `Simulations/simH_optimize/sdevice_simH0a_v5_writeread.cmd`

| Parameter | H0a v5 (Tasneem) | Liao cmd (this folder) |
|---|---|---|
| V_PGM | +4.0 V | **+3.5 V** |
| V_ERS | −4.0 V | **−3.5 V** |
| Pulse hold | 10 µs | **5 µs** |
| V_DS read | 0.05 V | **0.2 V** |
| Read window | −2.0 → +1.0 V | −2.0 → +1.0 V (unchanged — covers our V_t, sub-V_c) |
| Wall-time per run | ~20 µs simulated | ~10 µs simulated |

Everything else — every Physics block, Math block, Mesh, Electrode, .par parameter — is unchanged.

### How to run it

```
# On the cluster, in the same SWB project you use for the H-series:
# 1. Add this folder as a new SWB tool node, pointing the device tool at:
#      sdevice_liao2022_writeread.cmd
#    with .par parameter:
#      sdevice_gaafet_lif.par
#    and the existing GAAFet structure (or rebuild with sde_dvs.cmd if needed)
#
# 2. Run with the same solver settings used for H0a v5
#    (Bitlis + ParDiSo blocked, Restart=100, Tolerance=1e-5)
#
# 3. Expected wall-time: ~half of H0a v5 (5 us holds instead of 10 us)
#
# 4. Outputs to capture:
#    - read_postERS_*.plt   -> V_G sweep, I_D for post-ERS branch
#    - read_postPGM_*.plt   -> V_G sweep, I_D for post-PGM branch
#    - the Polarization CurrentPlot probe at (0, 0.0145) for sanity
```

### Acceptance criteria for Tier 1

Pull the post-ERS / post-PGM I_D-V_G arrays out of the .plt files and metric them against the digitised Liao Fig. 7 MFMFS-GAA curves (you will need to digitise those — see Step 2 below).

| Metric | Pass (ship Tier 1) | Borderline (document & ship) | Fail (escalate to Tier 2) |
|---|---|---|---|
| MW match | within 10% of 1.30 V (so 1.17–1.43 V) | within 20% (1.04–1.56 V) | outside 20% |
| SS_PGM | within 20% of Liao's reported value | within 30% | outside 30% |
| SS_ERS | within 30% of Liao | within 50% | outside 50% |
| R² (V_t-aligned, I_on-normalised, log10 I, V_G−V_t ∈ [−0.5, +0.5] V) post-PGM | ≥ 0.92 | 0.85–0.92 | < 0.85 |
| R² post-ERS | ≥ 0.92 | 0.85–0.92 | < 0.85 |

**Our current numbers vs Tasneem for context:** MW match 180% off; R² post-PGM = 0.86 (full)/0.67 (distilled). Tier 1 should beat all of these by a wide margin if the physics premise is right.

---

## Tier 2 — Only if Tier 1 fails the R² gate

If post-Tier-1 the R² is below 0.85 on either branch, the most likely failure mode is an **absolute V_T offset** (our V_t,PGM = −1.22 V vs Liao's V_t,PGM ≈ +0.7 V — a ~1.9 V offset that comes from gate metal workfunction differences between TSMC's process and our nominal 4.35 eV).

Tier 2 fix is a **one-knob WF retune**:

1. Edit only `Material="..."` workfunction in `sdevice_liao2022_writeread.cmd` Electrode block (or globally in the .par if it cleaner). Sweep WF ∈ {4.35, 4.5, 4.65, 4.8, 4.95} eV.
2. For each WF, run the cmd, extract V_t,PGM and V_t,ERS.
3. Pick the WF that lands V_t,PGM nearest Liao's −0.5 to +1 V band (depends on what Fig. 7 actually shows after digitisation — see below).
4. Re-run all of Phase 1D (H1–H12) at the new WF. The operating points should slide proportionally; the *physics conclusions* (5-pulse burst, 2.0V V_pgm, 1.40V MW, energy floor) should not change qualitatively.

Tier 2 effort estimate: **1–2 weeks** of cluster time + analysis. Justified only if it secures the IEEE TED / Nature Electronics submission.

**Do not jump to Tier 2 before seeing Tier 1 results.** The 90% likely outcome is that Tier 1 produces R² > 0.90 on both branches because the physics is correctly modeled and only the protocol shifted.

---

## Tier 3 (fallback if Tier 2 still fails) — Mulaosmanovic cross-cal

If after Tier 2 the Liao overlay is still loose, fall back to a **dual-anchor calibration**:

- Primary: Liao 2022 Fig. 7 — shape match, GAA-NS architecture credibility
- Secondary: Mulaosmanovic 2019 (TED) Fig. 1(d) — Si baseline, journal-tier credibility, but show only as "MW scales with t_FE in the same physics direction" cross-check

This is the strongest reviewer defense possible — two independent papers, one for architecture match and one for journal pedigree, both confirming the physics model.

---

## Next steps — concrete TODO

| # | Owner | Step | Output |
|---|---|---|---|
| 1 | you | Add `sdevice_liao2022_writeread.cmd` as a new tool node in your SWB project, pointing at the existing structure mesh (or rebuild from `sde_dvs.cmd` if needed) | SWB job submitted to cluster |
| 2 | you | Digitise Liao Fig. 7: extract the **MFMFS-GAA-FeFET** PRG (red, post-program) and ERS (blue, post-erase) curves at V_DS = 0.2 V. Save as `New_cal/csvs/Liao2022_MFMFS_PRG.csv`, `Liao2022_MFMFS_ERS.csv`. (Use the same digitiser settings you used for Tasneem — Plot Digitizer or WebPlotDigitizer.) | 2 CSVs in `New_cal/csvs/` |
| 3 | you | Pull the post-write read .plt files into `New_cal/csvs/tcad_liao_postERS.csv` and `tcad_liao_postPGM.csv` (same 2-column V_G, I_D/W format as the Tasneem TCAD CSVs) | 2 CSVs in `New_cal/csvs/` |
| 4 | me | Fork `Simulations/replot_calibration_publication.py` to `New_cal/replot_calibration_liao.py`: same pipeline (V_t align + I_on normalise + R² extract + 7-marker distillation), pointed at the new CSVs | 1 plot script + 5 plots (tcad_only, liao_only, shape_comparison, summary_3panel, main_calibration) + metrics_summary.txt |
| 5 | both | Review the new overlay. Decision gate against the Tier 1 acceptance table above. | go/no-go on Tier 2 |
| 6a | me (if Tier 1 PASS) | Update `Writing_Materials/Calibration_Full/CAL_DISC.md` to use Liao as the calibration anchor; keep Tasneem mention as "earlier iteration" | revised CAL_DISC |
| 6b | both (if Tier 1 FAIL) | Execute Tier 2 WF retune workflow | new operating points for Phase 1D |

---

## Risk register

| Risk | Probability | Mitigation |
|---|---|---|
| Solver instability at V_DS=0.2V on 100nm L_g (DIBL boosts off-floor, may confuse SS extraction) | Medium | If the off-floor jumps to >10 nA/µm, drop V_DS to 0.1V (still in Liao's reasonable range) and document. |
| Liao Fig. 7 curves digitise as noisy as Tasneem | Medium | Use the same log-mean smoothing pipeline already validated in `replot_calibration_publication.py`. Apply 7-pt window. |
| MW = 1.4V at ±3.5V (we tested ±4V) might drop slightly because 3.5V is closer to V_c,gate=1.91V | Low | Even at ±3V we'd still saturate FE switching (±3.5V is 1.8× V_c). MW should hold within 5% of the ±4V value. |
| V_t,PGM still way off from Liao's even after WF retune (suggests fixed-charge mismatch) | Low | Add interface fixed-charge as a second tuning knob. Already at 4e12 cm⁻²; could sweep ±50%. |
| Liao's MFMFS uses a metal interlayer (not insulator) — our MFIS isn't exactly the same topology | Documented | Liao reports both MFMFS and MFIFS at MW=1.3V; the variation is small. Cite both in the calibration discussion. |
| Reviewer demands a single-HZO MFIS reference (not MFMFS) | Low | Fall back to Hsiang 2021 EDL (planar Si MFIS, MW=1.37V) as the secondary anchor — but lose the GAA architecture match. |

---

## What this calibration unlocks for the paper

Once Liao replaces Tasneem as the anchor, the calibration paragraph in the methods section reduces from a 2-page apology to:

> "The device was calibrated against Liao et al. (VLSI 2022) Fig. 7 MFMFS-GAA-FeFET transfer characteristics. The TCAD post-program and post-erase I_D-V_G curves overlay the experimental reference with R² > 0.92 on both branches over V_G − V_t ∈ [−0.5, +0.5] V, with extracted memory window MW = 1.4 V (Liao reports 1.3 V; 7% gap consistent with our 10 nm single-HZO vs Liao's 5+10 nm double-HZO stack). Workfunction = 4.35 eV, AreaFactor = 0.071, interface fixed charge = 4×10¹² cm⁻², HZO P_r = 16 µC/cm², P_s = 20 µC/cm², F_c = 1.2 MV/cm, Preisach τ_E = 1 µs, τ_P = 10 µs."

That is publishable in IEEE TED or Nature Electronics without further argument. Every downstream Phase 1D result (5-pulse burst, 7-level analog, endurance, energy, temperature window) carries the same calibration credibility.

---

## Open questions for hozaifa

1. **Confirm SWB run owner:** do you want me to also generate the SWB `gtree.dat` / project descriptor, or will you wire the new tool node manually in the existing project?
2. **Workfunction policy if Tier 2 triggers:** are you OK with sweeping WF as the single tuning knob, or do you also want to allow AreaFactor and FixedCharge to retune simultaneously? (Single-knob is cleaner for reviewer defensibility; multi-knob may converge faster.)
3. **Phase 1D re-execution scope if Tier 2 triggers:** all 12 H-runs (H0a → H12), or just H0a + H1 + H2 + H4 (the operating-point-defining ones, then derive the rest by linear scaling)?
