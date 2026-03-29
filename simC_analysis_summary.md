# SimC Analysis Summary — Write-Then-Read LIF Protocol

**Date:** March 2026 (original QS-based) → April 2026 (write-then-read v3/v4/v5)
**Status:** Integration ✅ | Leak ✅ | Reset ✅ | Fire ⚠️ (5V peaks at 1.87× — v6 planned)

## Executive Summary

The write-then-read protocol successfully demonstrates **all four** LIF behaviors in partial form. v5 (pw=100ns, pw/τ_E=0.1) confirmed **gradual multi-pulse integration** and a **measurable leak gap** — the remaining challenge is pushing past the 2× fire threshold. v6 (Vpulse=5/6/7V) targets this.

| LIF Behavior | v3 (3/4/5V, pw=1µs) | v4 (1.5/2/2.5V, pw=1µs) | v5 (3/4/5V, pw=100ns) | v6 (planned) |
|---|---|---|---|---|
| **Integration** | ✅ saturates by P3 | ✅ saturates by P3 | **✅ gradual P1→P10** | Target: gradual + fire |
| **Leak** | ✅ gap visible | ✅ gap visible | **✅ 15-20% drop confirmed** | ✅ |
| **Fire** (ratio>2×) | ⚠️ P1 only (4-5V) | ❌ none reach 2× | ⚠️ max 1.87× (5V) | Target: P10-20 |
| **Reset** | ✅ 76-99% | ⚠️ overshoots (113-188%) | Mixed (107%/83%/72%) | Target: ~100% (Vreset=-5V) |

## Protocol Description

Unlike the original simC (which read current at VGS=2V during write pulses), the write-then-read protocol reads at a **constant VGS_read=0.20V** (just below Vth_virgin=0.263V). This amplifies small Vth shifts into measurable current ratio changes via the subthreshold slope (SS=60.8 mV/dec).

**Sequence per pulse:** Rise (1ns) → Write hold (pw) → Fall (1ns) → Read hold (100ns)
**Metrics:** $I_{D,read}/I_{D,baseline}$ ratio, polarization Py, estimated ΔVth

## SimC v3 Results — pw=1µs, Vpulse=3/4/5V

**Sweep:** `@Vpulse@` = 3.0, 4.0, 5.0V | N=10 pulses | Vreset=-6V | τ_E=1µs

| Vpulse | P1 Ratio | P10 Ratio | Reset % | Fire? |
|--------|----------|-----------|---------|-------|
| 3.0V | 1.80× | 1.93× | 98.7% | No (close) |
| 4.0V | **2.04×** | 2.17× | 83.4% | **P1** |
| 5.0V | **2.24×** | 2.36× | 76.1% | **P1** |

**Key findings:**
- 4V/5V fire on first pulse — pw=1µs is too long (pw/τ_E=1 → 63% switching per pulse)
- 3V approaches fire but saturates by P3 (1.80→1.87→1.91→plateau)
- Leak gap at P5→P6 shows current dip — ferroelectric relaxation signature
- Reset completeness inversely correlated with Vpulse (stronger P harder to reset)

## SimC v4 Results — pw=1µs, Vpulse=1.5/2.0/2.5V

**Sweep:** `@Vpulse@` = 1.5, 2.0, 2.5V | N=10 pulses | Vreset=-6V | τ_E=1µs

> SWB directories named n3(3V)/n4(4V)/n5(5V) — actual Vpulse verified from gate OuterVoltage in rise files.

| Vpulse | P1 Ratio | P10 Ratio | ΔVth P10 (mV) | Reset % |
|--------|----------|-----------|---------------|---------|
| 1.5V | 1.35× | 1.43× | −9.7 | 188% ⚠️ |
| 2.0V | 1.51× | 1.62× | −12.8 | 138% ⚠️ |
| 2.5V | 1.66× | 1.78× | −15.2 | 113% ⚠️ |

**Key findings:**
- **No fire** — all saturate below 1.8× (well short of 2× threshold)
- Same exponential saturation pattern (pw/τ_E = 1)
- **Reset overshoots** — Vreset=-6V too strong for these small polarization shifts
- Lower Vpulse reduces saturation ceiling but does NOT improve linearity

## Root Cause: pw/τ_E Ratio Too High

With pw/τ_E = 1µs/1µs = 1, each pulse switches ~63% of remaining switchable polarization (1 - e^(-1)). This causes:
- P1: 63% switched → big jump
- P2: 63% of remaining 37% = 23% → small additional
- P3: 63% of remaining 14% = 9% → nearly saturated
- **Result:** Exponential saturation in 3 pulses, regardless of Vpulse

**Fix:** Reduce pw/τ_E to 0.1 → ~10% switching per pulse → ~10 pulses to 65% → gradual linear integration.

## SimC v5 Results — pw=100ns, Vpulse=3/4/5V, Vreset=-4V (Completed)

**Sweep:** `@Vpulse@` = 3.0, 4.0, 5.0V | N=20 pulses | Vreset=-4V | pw=100ns | τ_E=1µs | pw/τ_E=0.1

| Vpulse | P1 Ratio | P10 Ratio | P20 Ratio | ΔVth P10 (mV) | Reset % | Fire? |
|--------|----------|-----------|-----------|---------------|---------|-------|
| 3.0V | 1.072× | 1.515× | 1.505× | −10.8 | 106.8% ⚠️ | No |
| 4.0V | 1.112× | 1.702× | 1.690× | −13.9 | 83.2% | No |
| 5.0V | 1.184× | **1.869×** | 1.855× | −16.3 | 72.0% | No |

**Key findings — GRADUAL INTEGRATION CONFIRMED:**
- **pw/τ_E = 0.1 works:** P1 ratios are 1.07-1.18× (vs 1.80-2.24× in v3) — each pulse switches ~10% of remaining polarization
- **Monotonic integration P1-P10:** Current ratio increases steadily for 10 pulses before saturating
- **Leak gap CONFIRMED:** P10→P11 shows **15-20% current drop** across all voltages (P11 incremental ratio: 0.85, 0.82, 0.80) — ferroelectric relaxation during 5µs gap
- **Post-leak recovery:** Pulses P11-P20 partially recover but cannot exceed pre-leak P10 ceiling — the relaxed polarization domains are re-switchable but total remains bounded
- **Saturation ceiling at 5V ≈ 1.87×** — just 7% short of 2× fire threshold
- **Reset scaling:** Vreset=-4V overshoots at 3V (107%), adequate at 4V (83%), insufficient at 5V (72%)

**Per-pulse incremental analysis (ID_Pn / ID_P(n-1)):**
- P1-P3 show largest increments (1.07-1.21× per step) — initial rapid integration
- P4-P10 slow down monotonically (1.02-1.06×) — approaching saturation
- P11 drops sharply (0.80-0.85×) — leak gap effect
- P12-P20 resume integration but at diminishing rate

**Why no fire at 5V:**
The saturation ceiling (~1.87×) is determined by the total switchable polarization at Vpulse=5V with the capacitive divider. At VGS=5V, the voltage across HZO ≈ 1.44V (just above Ec≈1.2V), so only a fraction of domains switch. Higher Vpulse will drive more complete switching → higher ceiling.

**Plots:** `Simulations/py_scripts/simC_v5_fig1-6_*.png`

## SimC v6 Plan — pw=100ns, Vpulse=5/6/7V, Vreset=-5V (NEXT)

**Goal:** Push past the 2× fire threshold by increasing Vpulse to access more switchable polarization.

| Parameter | v3 | v4 | v5 | **v6** | Rationale |
|-----------|----|----|----|----|-----------|
| pw | 1µs | 1µs | 100ns | **100ns** | pw/τ_E=0.1 confirmed to work |
| Vpulse | 3/4/5V | 1.5/2/2.5V | 3/4/5V | **5/6/7V** | Push past 1.87× ceiling |
| N_PULSES | 10 | 10 | 20 | **30** | More room for gradual rise |
| Vreset | -6V | -6V | -4V | **-5V** | Compromise: -4V too weak at 5V+, -6V overshoots |
| LEAK_AFTER | 5 | 5 | 10 | **15** | Later leak test for more integration data |

**Expected behavior:**
- 5V: ceiling ~1.87× (from v5) — confirms baseline
- **6V: V_HZO ≈ 1.73V (1.44× Ec) → significantly more switching → ceiling ~2.2×** ← likely fire
- 7V: V_HZO ≈ 2.02V (1.68× Ec) → near-complete switching → fire on early pulse

**Files:** `Simulations/simC/sdevice_simC_v6.cmd`, `generate_simC_v6.py`

## Valid Parameters for Step 2

```python
VALID_PARAMETERS = {
    "Vth_virgin": 0.263,        # V (from calibration Run 16)
    "ID_baseline": 9.525e-6,    # A (from write-then-read at VGS_read=0.20V)
    "SS": 60.8e-3,              # V/dec (from Run 6+7b extraction)
    "tau_E": 1e-6,              # s (switching time constant in par file)
    "MW": 0.681,                # V (from calibration Run 16)
    "pw_optimal": 100e-9,       # s (pw/tau_E=0.1 gives gradual integration)
    "leak_drop": 0.15,          # ~15-20% current drop in 5µs gap (v5)
}

PENDING_PARAMETERS = {  # Require v6 results
    "Vpulse_fire": None,   # Minimum Vpulse for fire (expected: ~6V)
    "N_fire": None,        # Number of pulses to fire at optimal Vpulse
    "dVth_per_pulse": None, # ΔVth per pulse in gradual regime
    "E_spike": None,       # Energy per spike from fire transient
    "Vreset_optimal": None, # Vreset for ~100% reset at fire Vpulse
    "tau_leak": None,      # Leak time constant (needs τ_P > 0)
}
```

## Next Steps

1. **Run SimC v6** on Sentaurus server (SWB: sweep @Vpulse@ = 5.0, 6.0, 7.0)
2. **Analyze v6 results** — expect fire at 6V or 7V
3. **If fire confirmed:** Extract N_fire, E_spike, dVth_per_pulse → populate PENDING_PARAMETERS
4. **If 6V fires:** Run targeted sweep around 6V (5.5, 6.0, 6.5V) for precise fire threshold
5. **After fire confirmed:** Run with τ_P > 0 for true leak characterization
6. **Final:** Extract all LIF parameters → feed into Step 2 SNN model

## Analysis Scripts & Plots

| File | Purpose |
|------|---------|
| `py_scripts/analyze_simC_v3.py` | v3/v4 analysis script |
| `py_scripts/analyze_simC_v5.py` | v5 analysis script (20 pulses) |
| `py_scripts/simC_v3_fig[1-6]_*.png` | v3 results (6 plots) |
| `py_scripts/simC_v4_fig[1-6]_*.png` | v4 results (6 plots) |
| `py_scripts/simC_v5_fig[1-6]_*.png` | v5 results (6 plots) |
| `simC/generate_simC_v[3-6].py` | Command file generators |
| `simC/sdevice_simC_v[3-6].cmd` | Simulation command files |
