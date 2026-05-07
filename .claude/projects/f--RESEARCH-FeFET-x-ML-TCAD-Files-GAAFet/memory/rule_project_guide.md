---
name: Project rule — follow .windsurf/rules/project-guide.md
description: Hard rule on writing TCAD code for this project. Never trust training data for Sentaurus syntax.
type: feedback
---

For every Sentaurus / sdevice command file, parameter file, or related TCAD code in this repo:

**Rule:** Follow the syntax and structure of the existing working references — `Simulations/calibration data/outputs/sdevice_calibration.cmd`, `Simulations/simC/sdevice_simC_v6.cmd`, `Simulations/sdevice_gaafet_lif.par`, `Reference_Codes/Working_Codes_MFMIS/`, and the official Sentaurus 2023.12 `Applications_Library` examples (e.g. `Memory/FeFET_CAM/`, `CMOS/CMOS_180nm/CV_des.cmd`). Never invent syntax from training data.

**Why:** The user explicitly stated this in `.windsurf/rules/project-guide.md` (always_on rule). Training-data syntax has caused wrong builds before. The official Sentaurus 2023.12 docs and the in-repo working codes are the only trusted sources for material parameters, Polarization model usage, ACCoupled/ACCompute, Transient/Quasistationary blocks, and tau_E / tau_P semantics.

**How to apply:**
- Before writing any new `.cmd` or `.par`, grep the existing working files for the closest analogue and copy its block structure.
- For features not present in repo (e.g. AC small-signal CV), use the in-tree official Sentaurus example (`CMOS_180nm/CV_des.cmd`, `FeFET_CAM/IdVg_des.cmd`) verbatim for that block.
- If a feature is in neither repo nor official examples, search `Sentaurus/sentaurus/V-2023.12/tcad/V-2023.12/` for similar uses; only fall back to web search of *official* Synopsys 2023.12 docs if nothing matches.
- Preserve exact patterns: `NewCurrentPrefix=` labelling, `CurrentPlot { Polarization/Vector (( 0 0.0145 )) }` probe location, `Method = Bitlis (Restart=100, Tolerance=1e-5, Iterations=200)` solver, `FEPolarizationIP=1.0`.
- Do not change tau_E / tau_P semantics; they live in the .par file's `Polarization { ... }` block and are swept manually or by SWB.
