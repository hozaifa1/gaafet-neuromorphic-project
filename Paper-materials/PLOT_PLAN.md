# SUPERSEDED

The master figure plan now lives at the repo root: [`../PLOT_PLAN.md`](../PLOT_PLAN.md).

It adds the code-level Areafactor / width-normalization audit of `Calibration/` and
`Device_Optimization/`, five further contradictions found in the same pass, and expands
the figure catalog from 33 to 79.

One correction carried over: this file said to use `Device_Optimization/par/app_frozen.par`
for re-runs. That is wrong — `app_frozen.par` has tau_E=1e-4 / tau_P=1e-4. Use
`par/app.par` with `@TAU_P@` rendered to `1e-5`.
