# FeFET LIF Calibration Workflow *(Rewritten Dec 20 2025 – VDS finding)*

This replaces the prior workflow. All recent evidence shows that **only the drain bias (V_DS) change from 1.0 V to 1.5 V altered the simulation output**. Adjusting `a_0`, `b_0`, `d_0`, or any other UniBo avalanche knobs produced byte-identical `.plt` files. Until we prove otherwise, treat V_DS as the sole effective control for the kink behavior in this project’s Sentaurus build.

---

## 1. Observed Behavior

1. **Kink only appears when V_DS ≥ 1.5 V.**  
   - Old files (V_DS = 1.0 V) lacked avalanche-induced slope changes.  
   - Raising V_DS to 1.5 V triggered the “kink” and improved I_ON/I_OFF by ~30×.
2. **Impact-ionization parameters currently inert.**  
   - Swapping `a_0/a_1` or `b_0/b_1` between 8e5↔1.5e6 made no difference (hash-identical outputs).  
   - Therefore, they cannot be relied upon for d₀ sweeps until we identify why Sentaurus is ignoring them.
3. **Plotting pipeline is verified.**  
   - `plot_idvg_final.py` and comparison scripts accurately expose identical vs different runs, so the lack of change is from the simulator, not the post-processing.

**Conclusion:** Assume V_DS is the only working knob for now. Calibration must revolve around controlled V_DS sweeps while we investigate why UniBo parameters are frozen.

---

## 2. Target Metrics (Bhatawdekar et al.)

| Metric | Target | Primary knob (current reality) |
|--------|--------|--------------------------------|
| Kink onset | V_DS = 1.0 V | V_DS sweep (currently stuck at 1.5 V) |
| Kink magnitude | 10–100× current jump | V_DS (since avalanche params inert) |
| Threshold voltage | −0.244 V | Gate workfunction |
| Threshold current | 94 nA | Derived once V_th + kink match |

---

## 3. Revised Calibration Flow

### Step A – Baseline reproducibility
1. Confirm `sdevice_gaafet_lif.cmd` is the version with **V_DS swept up to 1.5 V**.  
2. Run once to generate `1e6_final.plt` (reference).
3. Hash future runs (`Get-FileHash`) to verify whether any parameter edit changes output.

### Step B – V_DS sweep (primary knob)
1. Create three runs with identical `.par` files, varying only V_DS max:
   - **Run V1:** 1.0 V
   - **Run V2:** 1.2 V
   - **Run V3:** 1.5 V  
2. Plot each file; expect V1/V2 to match (no kink) and V3 to show the sharp rise.  
3. Document I_ON/I_OFF and slope variance for each run in this file.

### Step C – Attempt to re-enable avalanche parameters
1. Inspect Sentaurus version / license modules for UniBo options (check documentation directory or `*.cfg` files).  
2. If a PMI or alternative avalanche model exists, repeat the identical-run test to confirm parameters finally take effect.  
3. Until confirmed, keep `a_*`, `b_*`, `d_*` at defaults and do **not** assume they work.

### Step D – Threshold alignment (after kink via V_DS)
1. Use V_DS = 1.5 V data (since that produces a kink).  
2. Measure V_GS at |I_D| = 94 nA using the plotting scripts.  
3. Shift gate workfunction (4.5–4.65 eV sweep) to pull V_th toward −0.244 V.  
4. Record each workfunction setting and resulting V_th here.

### Step E – Hysteresis & transient checks
1. Once V_th is near target at V_DS = 1.5 V, evaluate hysteresis width with the same plots.  
2. If hysteresis is negligible, revisit FE polarization parameters (only after ensuring V_DS behavior is locked).  
3. Run the transient firing experiment using the calibrated static conditions; log whether the firing threshold matches 94 nA.

---

## 4. Open Questions / Action Items

| Priority | Task | Owner Notes |
|----------|------|-------------|
| P1 | Run the V_DS sweep (1.0 / 1.2 / 1.5 V) and archive plots + metrics | Confirms that V_DS is indeed the only working knob |
| P1 | Investigate why UniBo avalanche parameters don’t change outputs | Look for missing model licenses or script overrides |
| P2 | Once V_DS lever is understood, try alternative avalanche models (Okuto, Chynoweth) | Goal: regain control over kink at 1.0 V |
| P2 | Workfunction sweep for −0.244 V threshold (using V_DS = 1.5 V run) | Prepare for final calibration |
| P3 | FE hysteresis tuning and transient validation | After V_th + kink are settled |

> Keep logging every run (parameters + hashes + plots) in this document to avoid confusion about what actually changed. Once we regain control over avalanche parameters, the workflow can be updated again to fold V_DS back to 1.0 V.
