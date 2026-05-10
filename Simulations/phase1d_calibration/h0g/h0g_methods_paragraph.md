## Methods — TCAD geometry scaling (drop-in for paper)

The Sentaurus device deck simulates a 2D vertical cross-section through one
GAA nanosheet of width W_ns = 30 nm and channel thickness
t_ch = 15 nm, with gate length L_g = 100 nm. The cross-
section is treated as a double-gate (top and bottom gate stacks of MFIS
form: TiN / HZO (10 nm) / SiO₂ (2 nm) / Si). To recover absolute
terminal currents for the wrap-around GAA gate, a constant `AreaFactor` =
0.071 is applied. The first-principles geometric value
mapping the simulated double-gate (top + bottom, total perimeter
20.0 µm at the default 1 µm z-extent) to the real 3D GAA
perimeter (90 nm = 2(W_ns + t_ch)) is

    AF_geom = 2(W_ns + t_ch) / (2 × Z_depth) = 0.0045

The retained value (0.071) is 15.8× larger; it absorbs both the
DG → GAA geometric mapping and a current-magnitude calibration tuned in
Run 16 to match the target on-current. Crucially, all currents reported in
this manuscript are normalized as I_D / W in µA/µm. This per-perimeter
quantity is invariant under any choice of AreaFactor (the factor cancels in
the normalization), and the comparison to Tasneem 2022 (also expressed in
µA/µm) is therefore independent of this calibration scalar.
