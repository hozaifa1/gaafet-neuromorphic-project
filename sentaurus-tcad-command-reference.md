---
name: sentaurus-command-reference
description: "Full working command reference for driving Sentaurus TCAD on du@103.28.121.70 (what works / what doesn't)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 319bb887-200c-417f-97a5-00824f2579a0
---

Battle-tested command reference for the remote Sentaurus V-2023.12 box (see [[ieee-tcad-hackathon]], [[hackathon-submission-v1]]). Mirror kept at `F:\RESEARCH\AI-Scientist\sentaurus-tcad-command-reference.md` (global).

## Connect / transfer (from Windows Git-Bash)
- Run: `cd "/c/Program Files/PuTTY/" && ./plink.exe -batch -ssh -pw '<pw>' du@103.28.121.70 "csh -c 'source \$HOME/.cshrc && <cmd>'"`
- Upload: `"/c/Program Files/PuTTY/pscp.exe" -batch -pw '<pw>' localfile du@103.28.121.70:Sentaurus-files/<dir>/`  (add `-r` for a dir)
- Download: same with args swapped.
- **Env is csh-only** — wrap every tool call in `csh -c 'source $HOME/.cshrc && …'`. bash → `Illegal variable name`.

## csh gotchas (these bit me repeatedly)
- NO bash redirects: `2>/dev/null`, `2>&1`, `|&`(ok in csh)`. `2>/dev/null` → "Ambiguous output redirect". Use `>& file` to merge, or just drop it.
- `#` in an `echo` arg starts a csh comment → truncates the line. Quote markers: `echo ===TAG===` ok, `echo ###` bad.
- `grep -c X` returns exit 1 when count=0 → breaks `&&` chains. Use `;` not `&&` after greps.
- A glob with no match aborts the whole `&&` chain ("No match"). Guard with `ls … ;` (semicolon).
- Heredoc/printf for multi-line files: write locally + pscp instead (cleaner than fighting csh quoting).

## License (single sdevice license, shared)
- lmutil NOT on PATH: `/home/du/Sentaurus/scl/2023.09/linux64/bin/lmutil`
- Server: `27020@hostname1` (env `SNPSLMD_LICENSE_FILE`, `LM_LICENSE_FILE`).
- Check: `lmutil lmstat -a -c 27020@hostname1 >& /tmp/lm.txt` then grep `"Users of sdevice_all"`, `"sdevice-3d_all"`.
- **Cylindrical/axisymmetric sims check out `sdevice-3d_all`** (not just `sdevice_all`) — both must be free.
- Free a stuck license: `pkill -9 sdevice`. If a checkout persists, find the holder in lmstat (`J*` handle → PID) and `kill -9 <pid>`. Zombie SWB/qtx example runs (`gjob`,`gsub0`,`mpirun`,`qtx`) can hold it for hours — kill the swb parent PID + `pkill -9 qtx gjob gsub0 mpirun`.
- "unable to check out 1 sdevice license" in the .log = blocked, NOT computing. The run just waits.

## Core tools (all under `/home/du/Sentaurus/sentaurus/V-2023.12/bin`)
- Build mesh from an sde/Scheme deck: `sde -e -l sde_deck.cmd` (`;` comments; @node@ tokens must be sed-resolved first for standalone use). Output `n<node>_msh.tdr`.
- Run device: `sdevice deck.cmd` (`#` comments!). ~1–5 min. Writes `.plt` (Current), `.tdr` (Plot), `.log` (Output).
- Full SWB flow headless: `gsub -verbose -e all <projdir>` (from `~/Sentaurus-files`). Auto-resolves `@tdr@` dependency (sde before sdevice). Nodes numbered per gtree.dat (sde=1, sdevice=2 → IdVg_n2_des.plt). Runs single-thread/niced → slower than direct.
- Pack: `swbpack -Z proj.gzp <projdir>` (gzip; `gpack`/`gexport` DO NOT EXIST). Verify: `swbunpack -t proj.gzp` (list), `swbunpack proj.gzp` (extract into cwd).
- TDR→ASCII (DF-ISE) for parsing fields: `tdx -dd file.tdr outprefix` → outprefix.grd (Vertices/Edges/Regions) + outprefix.dat (per-region datasets). `.dat` datasets are PER-REGION and edge-based (fiddly to map to coords).

## Figures — svisual is headless-BLOCKED here
- `svisual -b script.tcl` runs but `export_view f.png -format png -overwrite` writes NOTHING (no X).
- `-batchx`/`-bx` (virtual X) FAILS: no `Xvfb` installed anywhere on the box.
- `-m`/`-cm` = Mesa software GL but still needs the X server → useless headless.
- svisual `get_variable_data <var> -dataset <h>` reads CURVE (.plt) data only, NOT mesh fields (`list_variables` returns 0 for a field tdr; even eDensity fails).
- ⇒ Generate figures with **matplotlib**: mesh edges from the `.grd` (Vertices+Edges), doping/materials as exact region rectangles (known geometry), IdVg from the `.plt`. Native svisual snapshots only via the user's GUI (`make_snapshots.tcl`).

## Physics keywords: works / doesn't (sdevice V-2023.12)
- 2D cylindrical: `Math{ Cylindrical(yAxis=0) }` → currents in ABSOLUTE Amps (true revolved wire). CONFIRMED.
- Stress: define `StressXX`/`YY`/`ZZ` as a dataset in the SDE deck like a doping profile:
  `(sdedr:define-constant-profile "P" "StressXX" 1e9)` + place-in-region. Load in sdevice via `File{ Piezo="@tdr@" }`.
- Stress models: `Physics(Material="Silicon"){ Piezo( Model( Mobility(eSubBand(Doping) hSixBand(Doping)) DeformationPotential(ekp hkp minimum) DOS(eMass hMass) ) ) }`. Log confirms "Deformation Potential Theory ... stress dependent bandgap and affinity". eSubBand(Doping) needs NO multivalley/AutoOrientation (unlike eSubBand(Fermi EffectiveMass Scattering)).
- `StressMobilityDependence=Piezoresistance` → SYNTAX ERROR. Only valid value in examples is `TensorFactor` (and that needs eMultiValley). So use eSubBand route above instead.
- Convergence for nMOS + BTBT + holes: `Math{ Iterations=50 Notdamped=50 Method=Blocked SubMethod=ParDiSo RelErrControl Digits=5 RefDens_e/hGradQuasiFermi_ElectricField_HFS=1e12 }`. Iterations=15 FAILS ("iterations larger than 15" → MinStep exit). Solve order: Coupled{Poisson} → {Poisson eQuantumPotential} → {Poisson Electron Hole eQuantumPotential} → ramp Vd → ramp Vg (MaxStep 0.02–0.05).
- Quantum correction for DD = `eQuantumPotential` (density-gradient). Works standalone.
- BTBT: `Recombination( Band2Band(Model=Hurkx) )` (also Schenk). Gate WF via `Electrode{ ... Workfunction=4.4 }`.

## Extraction (see tools/extract_nw.py, maxvel.py)
- `.plt` is DF-ISE text: dataset names in `datasets = [ … ]`, then `Data { … }` flat floats, col-major by header order (index by NAME, e.g. "drain_contact TotalCurrent", "gate_contact OuterVoltage"). NOT the listed order.
- Max electron velocity: `tdx -dd n1_des.tdr conv` → parse `Dataset("eVelocity")` (vector dim=2) in conv.dat, max of sqrt(vx²+vy²). Units already cm/s.
