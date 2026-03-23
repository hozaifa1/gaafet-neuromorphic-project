# Paper 1: Novel GAA-FeFET Structural Optimization for High-Performance LIF Neurons

## 1. Introduction and Fundamental Theory
To build an energy-efficient Spiking Neural Network (SNN), the core computational unit—the Leaky Integrate-and-Fire (LIF) neuron—must be carefully designed. In this project, we are utilizing a **Gate-All-Around Ferroelectric Field-Effect Transistor (GAA-FeFET)** to emulate this biological behavior.

### 1.1 How a GAA-FeFET Works
A conventional GAA-FET consists of silicon nanosheets surrounded completely by a gate stack, offering ultimate electrostatic control over the channel. By introducing a **Ferroelectric (FE)** layer (such as Hafnium Zirconium Oxide, HZO) into the gate stack, we create a FeFET. The FE layer exhibits a spontaneous electric polarization that can be reversed by an external electric field. This polarization modulates the threshold voltage ($V_{th}$) of the underlying transistor, allowing it to act as a non-volatile memory or an integrator.

### 1.2 The LIF Neuron Analogy in FeFETs
Biological neurons possess a cell membrane with capacitance, ion channels that act as resistors, and a mechanism to fire a spike when a threshold is reached. In our GAA-FeFET:
- **Integration (Membrane Capacitance):** The gate capacitance ($C_{gg}$) acts as the membrane capacitor. Incoming voltage/current pulses from pre-synaptic neurons accumulate charge on the gate, gradually increasing the gate voltage ($V_{GS}$) and shifting the ferroelectric polarization.
- **Leakage (Membrane Resistance):** Subthreshold leakage currents or natural depolarization of the FE layer act as the "leak," causing the accumulated potential to decay over time if no input is received.
- **Fire (Action Potential):** When the integrated gate potential exceeds the threshold voltage ($V_{th}$), the transistor abruptly turns ON. In our specific design, we leverage the **Impact Ionization (Kink Effect)** at a specific drain bias ($V_{DS}$) to create an abrupt, sharp spike in drain current ($I_{D}$), representing the neuron firing.
- **Reset (Refractory Period):** After firing, an external circuit or intrinsic polarization reset brings the membrane potential back to its resting state.

### 1.3 Key Difference: Bhatawdekar Paper vs. Our Device
The reference LIF neuron paper (Bhatawdekar et al.) uses a **standard GAA FNSFET** with no ferroelectric layer. Their LIF mechanism is purely Impact Ionization + Floating Body effect. Our device **adds an HZO ferroelectric layer** to provide programmable synaptic weights (threshold voltage modulation via polarization). This is the novel contribution but also introduces a fundamental challenge: the HZO layer changes the gate stack's capacitive voltage divider and the electrostatic coupling between the gate and the drain junction, potentially suppressing the Impact Ionization mechanism required for spiking.

---

## 2. Calibration Work Completed

### 2.1 Summary of Calibration Runs
All calibration details are in `Calibration_Log_2026_01_15.md`. Total: 16 runs across 3 stages.

**Stage 1 — DC Calibration (Runs 1-5):**
Swept FixedCharge and AreaFactor to match $V_{th}=0.25V$ and $I_{on}=600\mu A$ using Quasistationary solver. Achieved DC golden run at Run 5 with WF=3.9eV, FixedCharge=5.15e12, AreaFactor=0.224.

**Stage 2 — Hysteresis Integration (Runs 6-13):**
Activated ferroelectric physics (`Polarization` keyword for Preisach model). Switched to Transient solver (required for FE). AreaFactor recalibrated from 0.224 to 0.069 due to Transient solver calculating displacement + particle current differently. Sweep range increased to $\pm 6.0V$ to ensure $V_{fe} > V_c$ (coercive voltage).

**Stage 3 — Final Calibration (Runs 14-16):**
Re-tuned WF from 3.9eV to 4.35eV and FixedCharge to 4.0e12 to center the hysteresis loop.

### 2.2 Final Calibrated Parameters (Run 16 — "Golden")

| Parameter | Value | Purpose |
|---|---|---|
| Workfunction | 4.35 eV | Centers hysteresis loop |
| Fixed Charge | 4.0×10¹² cm⁻² | Fine-tunes $V_{th}$ to 0.25V |
| AreaFactor | 0.071 | Scales $I_{on}$ to 600μA (Transient mode) |
| $L_g$ / $T_{si}$ | 100nm / 15nm | Matches Bhatawdekar design |

**Results:**
- $V_{th}$ (Fwd): **0.263 V** (target 0.25V) 
- $I_{peak}$: **604 μA** (target 600μA) 
- Memory Window: **0.681 V** (CCW direction) 

### 2.3 What Calibration Did NOT Cover

The calibration matched two scalar targets ($V_{th}$, $I_{on}$) and verified the hysteresis loop. However, the following were **not** performed:

- **Full $I_D$-$V_{GS}$ curve shape matching** — Only 2 points matched, not the full transfer characteristic
- **Output characteristics ($I_D$-$V_{DS}$) verification** — **CRITICAL OMISSION** — the kink effect was never verified
- **Subthreshold swing (SS) verification** during calibration
- **DIBL verification**
- **Velocity saturation calibration** (paper: calibrated; ours: Sentaurus defaults)
- **S/D resistance calibration** (paper: 7 Ω·μm²; ours: not set)
- **Contact resistance** (paper: 7 Ω·μm²; ours: not set)
- **Comparison against Loubet et al. experimental data**

For **memory/synaptic weight** operation, the completed calibration is sufficient. For **LIF neuron** operation requiring Impact Ionization, it is **insufficient** because the kink effect (II signature) was never verified.

---

## 3. Spiking Simulation Attempts (Runs 1-8c)

Full details in `spiking_simulation_debugging_log.md`.

### 3.1 Key Lessons Learned (Valid Fixes)
- **Biasing order matters:** Gate bias must be set FIRST, then drain is pulsed (Bhatawdekar Fig.4)
- **Initial $V_{DS}$ must be 0V:** $V_D$ must equal $V_S$ initially to avoid leakage
- **Negative source bias:** $V_S = -0.25V$ per paper
- **Transient+Goal uses normalized step sizes:** fractions of (FinalTime - InitialTime), not absolute seconds
- **Missing $\tau_E$:** Required in Preisach model for transient stability
- **Subthreshold swing:** SS = 60.8 mV/dec confirmed via two-point extraction

### 3.2 Run 8 Result: Operating Point Correct, II Dead
Run 8 ($V_{GS} = -0.11V$) achieved the target channel current (~183 nA) but Impact Ionization multiplication factor M = 4.99×10⁻⁸ — completely negligible.

### 3.3 Runs 8a/8b/8c: d0 Parameter Sweep — FAILED
Swept d0 from 7.1e5 to 1e5 (7× change). **All three runs produced byte-identical output** (MD5 hash match). Changing d0 had literally zero effect because II generates zero carriers at this operating point. The 9.15 fA source hole current comes entirely from Band2Band tunneling (Hurkx model), not II.

### 3.4 Root Cause: Device Cannot Produce Impact Ionization

The electric field at the drain-body junction ($F_{ava}$) is far below the critical field required for avalanche generation at any d0 value. The GAA-FeFET's strong electrostatic gate coupling (designed for logic) combined with the HZO capacitive voltage divider suppresses the drain junction field to the point where II is physically impossible.

**The Bhatawdekar paper verified II capability via output characteristics (Fig 5, Fig 7) BEFORE attempting transient spiking. We skipped this step entirely.**

---

## 4. Current Status: BLOCKED — Impact Ionization Verification Required

### 4.1 The Single Most Important Missing Step

**We must run output characteristics ($I_D$-$V_{DS}$ sweep) to determine if our device can produce the kink effect at all.** Without this, all transient spiking attempts are premature.

The paper's Fig 5 shows ID-VDS curves with a clear kink at VDS ~0.7-1.0V for various VGS values. The paper's Fig 7(a) shows how d0 tuning affects the kink. These DC sweeps are the fundamental prerequisite for LIF operation.

---

## 5. Corrected Next Steps (In Priority Order)

### Step 1: Output Characteristics Sweep (IMMEDIATE)

**Goal:** Determine if the GAA-FeFET structure can produce Impact Ionization.

**Action:** Create a new `sdevice_des.cmd` variant for DC output characteristics:
1. Ramp $V_{GS}$ to a fixed value (e.g., 0.3V, 0.5V, 1.0V) using Quasistationary
2. Sweep $V_{DS}$ from 0V to 2.0V using Quasistationary
3. Record $I_D$ vs $V_{DS}$ at each $V_{GS}$
4. Use d0_e = d0_h = 1e5 (maximum II) for this test
5. Plot $I_D$-$V_{DS}$ and look for kink (sudden slope change)

**Decision tree:**
- **Kink observed** → Device supports II → Fix transient biasing → Proceed to spiking
- **No kink up to $V_{DS}$ = 2.0V** → Proceed to Step 2

### Step 2: FE Layer Isolation Test (If No Kink)

**Goal:** Determine if the HZO layer is killing II.

**Action:** Disable FE physics and re-run the same output characteristics:
```
* Physics(Material="HZO") {
*     Polarization
* }
```

**Decision tree:**
- **Kink appears without FE** → HZO is screening the drain field → Need FE stack re-engineering
- **No kink even without FE** → Base GAA structure doesn't support II → Need structural changes (Step 3)

### Step 3: Structural Root Cause Analysis (If No Kink Without FE)

Investigate why the base GAA FET doesn't produce II:
1. **Extract electric field profile** along the drain junction from the TDR output
2. **Compare field magnitude** against UniBo2 critical field ($\sim 10^5$ V/cm)
3. **Potential fixes:**
   - Asymmetric drain doping (LDD) to concentrate the field
   - Increase $T_{si}$ beyond 15nm to create a stronger floating body
   - Reduce gate coupling (e.g., partial gate coverage) — trades off electrostatic control
   - Verify channel doping ($1×10^{16}$ cm⁻³) creates sufficient drain-body depletion

### Step 4: Proper Full Calibration (After Structural Fix)

Once II capability is confirmed:
1. Match full $I_D$-$V_{GS}$ curve shape (not just 2 points) — verify SS, DIBL, $I_{off}$
2. Calibrate velocity saturation and S/D resistance per paper
3. Match output characteristics with kink against paper Fig 5
4. Re-enable FE and verify hysteresis + kink coexist
5. Set $I_{th}$ from kink analysis (paper: 94 nA)
6. THEN proceed to transient spiking

### Step 5: Transient Spiking (After Full Calibration)

Use the validated operating point from output characteristics to set up the transient simulation with correct biasing.

---

## 6. Phase II: Novel Device Engineering (Deferred)

Phase II innovations (asymmetric junction, floating body optimization, FE stack engineering) remain valid design directions but are **deferred** until Phase I baseline spiking is achieved. Notably, the asymmetric junction engineering (Section 6.1) may become part of the structural fix if Step 3 reveals insufficient drain junction field.

### 6.1 Asymmetric Junction Engineering for Low-Voltage Firing
- Engineer an asymmetric drain doping profile or LDD extension to maximize the local electric field near the drain at low $V_{DS}$.
- TCAD Action: Introduce spatial doping gradient in sdevice structure generation.

### 6.2 Floating Body and Volume Inversion Optimization
- Optimize nanosheet thickness ($T_{si} \approx 15-25$ nm) to maximize hole-storage capacity.
- TCAD Action: Transient multi-pulse simulations varying $T_{si}$.

### 6.3 Ferroelectric Stack Engineering for Analog Integration
- Tune HZO thickness ($T_{fe}$) and interfacial layer ($T_{ox}$) for multi-domain gradual polarization switching.
- TCAD Action: Enable multi-domain Preisach model, sweep $T_{fe}$ and $T_{ox}$.

---

## 7. File Reference

| File | Location | Purpose |
|---|---|---|
| Calibration Log | `Calibration_Log_2026_01_15.md` | Full 16-run calibration history |
| Spiking Debug Log | `spiking_simulation_debugging_log.md` | Runs 1-8c analysis and root causes |
| Calibration CMD | `Simulations/calibration data/sdevice_calibration.cmd` | Hysteresis sweep command file |
| Spiking CMD | `Simulations/sdevice_des.cmd` | LIF transient command file |
| Parameter File | `Simulations/sdevice_gaafet_lif.par` | Material parameters (d0, FE, mobility) |
| Calibration Data | `Simulations/calibration data/` | CSV outputs, PLT files, plots |
| Spiking Outputs | `Simulations/spiking_runs/Run 8*/` | Transient PLT files per run |
| Analysis Script | `Simulations/py_scripts/analyze_8abc.py` | Run 8a/8b/8c comparison |
| Plot Script | `Simulations/py_scripts/plot_spiking.py` | Transient visualization |
