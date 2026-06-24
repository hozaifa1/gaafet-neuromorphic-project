# Handoff prompt — GAA-FeFET TCAD (device optimization DONE) → Python SNN modelling

Paste the block below into a fresh chat to continue with the Python SNN modelling.
The TCAD device work is complete; this hands off the optimized, characterized device.

---

You are continuing a GAA-FeFET → leaky-integrate-and-fire (LIF) spiking-neural-net
project. **The Sentaurus TCAD stage is COMPLETE.** A calibrated HZO GAA-FeFET was
optimized for the LIF/synapse role and fully characterized. Your job is the
**Python SNN modelling** that uses the device characteristics — do NOT re-run TCAD
unless explicitly asked. Read your memory files first, then
`F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Device_Optimization\OPTIMIZED_DEVICE.md`
(device datasheet) and `OPT_LOG.md` (full optimization study).

## What the device is (use these as the model's device equations/lookups)
Optimized GAA nanosheet FeFET (T_ox=1 nm, T_si=5 nm, T_fe=7 nm, L_g=100 nm,
calibrated HZO P_r=32/F_c=1.4). Operating point: read at V_G=0 V, V_DS=50 mV;
potentiate with +2 V/0.3 µs pulses; reset with −2 V erase; leak tau_P=10 µs.

Device characteristics (CSV data in `Device_Optimization/csv_export/raw/`):
- **Memory window** `memwin_fe07.csv`: retained I_D–V_G for erased & programmed
  states. ~3140× ON/OFF at V_G=0 (erased 9.4e-3, programmed 29.5 µA/µm), ΔV_t≈0.3 V.
- **Analog potentiation (LTP)** `ltp_potentiation.csv`: conductance vs cumulative
  pulse number — 15 monotonic levels over ~4 decades (1.0e-3→13.1 µA/µm). This is
  the synaptic-weight update rule (cumulative kinetic FE switching).
- **Retention/leak**: conductance decay over time at V_G=0 (tau_P≈10 µs) — see
  `csv_export/raw/leak_*.csv` (and OPTIMIZED_DEVICE.md).
- **Temperature**: LTP at 250/300/350 K — operating-window robustness.
- **Energy**: ~0.01–0.04 fJ per program pulse (switching charge × V).

## Suggested SNN modelling sprint
1. Build a device behavioural model in Python: state = retained conductance G;
   spike (+2 V pulse) → G update from the LTP curve (interpolate
   `ltp_potentiation.csv`); leak G→G_erased with tau_P; read output ∝ G at V_G=0;
   fire when G crosses a threshold; reset = erase.
2. Wrap as a LIF neuron / synapse layer (e.g. in snnTorch / Norse / custom NumPy).
3. Train/evaluate on a small benchmark (e.g. MNIST or a rate-coded task), reporting
   accuracy vs the device's level count (15), variability, retention, energy/spike.
4. Map circuit-level requirements back (V_pgm jitter, read margin from the 3140×
   window, temperature window) as device–circuit co-design guidance.

## DROP-IN PARAMETERS (use these directly)
`Device_Optimization/gaafefet_params_optimized.py` is a **drop-in replacement** for
`PYTHON_Modelling_Fefet_Codes/gaafefet_params.py` — identical keys/structure, only
values updated for the optimized device. Rename it to `gaafefet_params.py` and the
existing SNN code runs unchanged. Full prior→optimized comparison + provenance in
`Device_Optimization/SNN_PARAMETERS.md`. Headlines: SS=62 mV/dec, MW=0.336 V,
fire_ratio=30.6× (prior 2.0×), R_off=71 MΩ / R_on=2.34 MΩ, E≈0.014 fJ/pulse.
**Re-tune C_mem and input_scaling s** for the new (10⁴× higher) R — see SNN_PARAMETERS.md.

## Repo pointers
- Optimized device + study: `Device_Optimization/` (OPTIMIZED_DEVICE.md, OPT_LOG.md,
  PLAN.md, SNN_PARAMETERS.md, gaafefet_params_optimized.py). Harness: `opt.py`,
  `lifgen.py`, `memwingen.py`, `plt2csv.py`.
- Paper-ready CSVs: `Device_Optimization/csv_export/` (sweeps + raw curves).
- Calibration (locked, upstream): `New_cal/HYSTERESIS_CALIBRATION_RESULT.md`.
- Cluster (only if you must re-sim): `du@103.28.121.70`, pw in `New_cal/autocal/.pw`,
  single sdevice license — launch detached (nohup) + poll; `pkill -9 sdevice` to
  free a stuck license; negative-bias runs need instant gate ramps + Digits=5.

Priority for all decisions: a top-tier IEEE TED / Nature Electronics publication.
