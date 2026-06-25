# R2 — FeFET Neuromorphic Circuit Architectures (2024–2026)

Research brief for a calibrated GAA-HZO FeFET device + SNN paper (target: IEEE TED / Nature Electronics).
Compiled June 2026. All numbers traced to cited sources at end.

## 0. The problem we are fixing

Prior design used the FeFET as a 2-state **leak resistor** in an RC LIF neuron with an
external **C_mem = 1.419 µF per neuron**. That microfarad cap destroys area/energy and uses
only a 2× resistance ratio of a device that actually has **15 analog levels over 4 decades,
3140× ON/OFF, ~0.014 fJ/pulse, near-ideal SS, full non-volatility**. The literature below
shows the field has moved entirely away from "FeFET-as-discrete-resistor + giant cap." Two
dominant, defensible roles exist: **(A) FeFET-as-synapse** in an analog in-memory MAC crossbar
(uses multi-level conductance directly), and **(B) FeFET-as-neuron** where polarization
*accumulation itself is the membrane integration* — capacitor-free, or with a tiny fF-pF cap.

---

## 1. FeFET-as-SYNAPSE (in-memory crossbar / MAC)

The mainstream 2023–26 mapping: store a quantized weight as a **multi-level V_th / conductance**
state of one FeFET; drive a read voltage on the wordline; the bitline current (or accumulated
charge / activation-time) is the dot product. Signed weights use **differential G+ − G− pairs**
(two FeFETs, or two columns). Multi-bit weights use either multi-level cells (MLC) or
bit-sliced single-level cells.

**Concrete demonstrations & numbers:**

| Work (node) | Cell | Levels / precision | Array | Efficiency | Accuracy | Notes |
|---|---|---|---|---|---|---|
| Soliman *FELIX* (22nm FDSOI) | 1 FeFET | bit-sliced, 8b act / 4b wt | 16×16 segments, up to 64 Mb | **36.5 TOPS/W** (8b/4b), **1169 TOPS/W** (1b/1b), **261 TOPS/W/mm²** (binary); 2.05 TOPS in 4.9 mm² | — | No DAC, only 3-bit ADC; bit-decomposition |
| MLC-FeFET IMC, Nat.Commun. 2023 (28nm HKMG) | **1FeFET-1R** | 2b/2b, multi-state V_th | crossbar, 64 fF accum. cap | **885.4 TOPS/W** (≈2× prior) | **96.6%** MNIST, **91.5%** image | MAC encoded in activation-time + accumulated current; 153.6 µW @ 66 MHz |
| DM-FeFET differential macro (28nm HKMG) | **2 FeFET differential** | multi-bit signed | 4 K-device crossbar | **196 TOPS/W** (VGG-8) | 94% train / 88% infer @ 1% BER | **223 Mb/mm²** bit density (≈2× conventional FeFET array) |
| TReCiM 2FeFET-1T (subthreshold) | **2FeFET-1T** | 1b & 2b | 128×128 | **26.06 TOPS/W** (1b), **48.03 TOPS/W** (2b) | 92.0% (bin) / 91.31% (2b) CIFAR-10 VGG-8 | Temperature-resilient (3× vs 1FeFET-1R), V_read 0.35 V |
| CurFe / ChgFe dual design (scaled 40nm) | 1 FeFET | 8b/8b | 128×128 | highest circuit-level 8b/8b IMC; 1.56× SRAM, 2.22× ReRAM; 1.37× system vs SoA | CIFAR10-ResNet18 | Inherent shift-add (no extra HW for multi-bit) |
| FeBiM Bayesian engine (45nm, 2FeFET/cell) | 2 FeFET | 2 b/cell logarithmic | 2×2 tile, cell area 0.076 µm² | **581.4 TOPS/W**, **17.20 fJ/inference**, **26.32 Mb/mm²** | iris classification | 10.7×/43.4× compact/eff vs SoA Bayesian |
| FeFET-CiM ADC-free logic (28nm, 2026 MDPI) | FeFET+CMOS gates | bitwise | — | NOR **0.0169 fJ/bit**, XNOR 0.304 fJ/bit; ps-level latency | — | ADC-free; up to 901× lower vs other CiM |

**Takeaways for our paper:**
- The **1FeFET-1R / 1T1FeFET cell with differential (G+ − G−) columns** is the canonical,
  publishable synapse. Signed weights = two physical devices or two columns.
- Reported analog level counts in *device* synapse papers: typically **32–136 states**
  (grain-engineered HZO: 100→136 states, G_max/G_min 5→90; laminated+plasma: 75→100 states).
  Our **15 levels over 4 decades** is modest in count but the **4-decade dynamic range
  (G_max/G_min ≈ 30×, R_on 2.34 MΩ → R_off 71 MΩ)** is far above the 5–90× typical — that is
  our differentiator. Emphasize range and retention, not raw level count.
- Competitive efficiency band today: **~25–200 TOPS/W at multi-bit (2–8b)**; **>500–1200 TOPS/W
  at binary/2b**; **fJ-to-tens-of-fJ per inference**; **bit density 26–223 Mb/mm²**.
- Accuracy bar: **>91% CIFAR-10 (VGG-8)** and **>96% MNIST** with device non-idealities included
  (NeuroSim v1.5 is the standard benchmarking backbone reviewers expect).

---

## 2. FeFET-as-NEURON (LIF) — integration & the leak problem

A standard FeFET is **non-volatile → no intrinsic leak**, so a naive LIF integrates forever.
The literature solves "where does the leak come from" in 4 distinct ways. Integration itself is
done by **cumulative/partial polarization switching** (sub-coercive pulses each flip a few more
domains → V_th creeps → I_d ramps = membrane potential), so **no integrating capacitor is needed
for the integrate function**. The variants differ in the leak/reset mechanism:

**Leak schemes (enumerated):**

1. **Antiferroelectric (AFE) self-reset / intrinsic depolarization** — *the cleanest.*
   Hf₀.₂Zr₀.₈O₂ AFeFET: polarization accumulates under pulses, then **spontaneously back-switches**
   (depolarization) in the gap → millisecond-scale leak, **no capacitor, no reset transistor.**
   - Compact AFeFET neuron (Nat. Commun. 2022): **37 fJ/spike**, endurance **>10¹²**, C2C var 3.93%,
     D2D 7.57%, electroforming-free; 100 µs pulses; 2-layer SNN → **96.8% MNIST**.
   - AFeFET reconfigurable (Nat. Commun. 2025): coupled polarization-switching + charge-trapping;
     reset-to-zero LIF, signal filtering (no fire on weak input), firing robust to **10⁸ cycles**.

2. **Leaky-FeFET (L-FeFET): engineered depolarization-field + gate leakage.**
   Thin (5 nm) HZO annealed 450 °C → enlarged depolarization field + leakage current → remanent
   polarization decays on its own = leak. **1 transistor + 1 resistor** LIF; halves hardware vs
   CMOS; supports spike-frequency adaptation. (Chen VLSI 2019; reviewed widely 2024–26.)

3. **Leak-via-negative-bias ("erase leak") — capacitor-free, applied-bias leak.**
   TU-Dresden 2T/7T FeFET I&F circuits: integrate with +2 V/0.1 µs program pulses; the **leakage
   phase applies −0.7 V for 90 µs** to accumulatively reverse polarization toward HVT → controllable
   leak strength via the negative voltage. Capacitor-free; reset = extra transistor to a negative bias.

4. **FeLIF (FeCap + CMOS, dual state-variable) — tiny caps, true RC + polarization.**
   Co-integrates a **ferroelectric capacitor (FeCap)** with CMOS. Membrane potential = voltage on
   FeCap. Two state variables: linear dielectric charge (fast LIF) + non-volatile polarization
   (slow tracking, gated by V_mem once V_c reached). dV_mem/dt = (I_syn − I_leak − I_p)/(C0 + C_par).
   **C0 = 0.558 pF, C_par = 15 fF, area 25 µm²** — i.e. **sub-pF, not µF.** Used in the BRUNO SNN
   (Braille / music tasks, IOP Neuromorph. Comp. 2026).

**Fe-SBFET multifunctional neurons (RWTH, 2024–25):** single device type (HZO Schottky-barrier FET),
- 1 device synapse: **28 fJ/state**;
- **2-transistor IF neuron: 0.67 pJ/spike**, self-reset τ = 1.05 ms, 0.81 kHz;
- **5-transistor LIF/burst neuron: 2.6 pJ/spike** at 5.6 kHz — **no C, no R, no extra CMOS.**

**Split-gate FeFET neuron** (Lee, IEEE EDL 2022) and **double-gate / FDSOI FeFET** (astrocyte+dendrite,
arXiv 2025) give compact multi-terminal neuron/modulation in a single transistor.

---

## 3. The realistic, defensible membrane capacitance (the 1.419 µF fix)

**Core resolution: you do NOT need a membrane capacitor at all if you integrate in polarization
(schemes 1–3 above). If you keep a cap (scheme 4 / CMOS-LIF hybrid), it is fF–low-pF, never µF.**

Why the old 1.419 µF appeared: a passive RC neuron forcing τ ≈ 10 ms with the device's own ~MΩ
resistance needs C = τ/R. With R ≈ 7 MΩ, τ = 10 ms → C ≈ 1.4 nF already; the µF value implies an
even smaller effective R or a sub-ms-misread τ. Either way **τ = R·C with a fixed MΩ R is the trap.**

**Three legitimate routes to a ~ms–10 ms time constant without a big cap:**

- **(a) High-resistance bias / subthreshold leak.** Make the leak path a subthreshold transistor,
  not the FeFET channel. g_m ~ 0.1 µS (TSMC-65nm LIF leakage module: **G_m = 0.106–0.164 µS**),
  τ = C/G_m. With **C_mem = 0.1–2 pF**, that measured design tunes **τ = 0.609–18.83 µs**. To reach
  10 ms push G_m to ~nS (deep subthreshold) or clock-divide (route c). R needed for τ=10 ms at
  C=1 pF is **R = 10 GΩ** — achievable as a biased subthreshold device, impossible as channel R.
- **(b) Polarization time constant (no electrical RC at all).** In FeLIF the "leak" is the FeCap
  depolarization / domain back-switch time τ(E) = τ₀·exp[(E_a/E)^α] (τ₀=0.1 ps, E_a=1.27 V/nm, α=1.3).
  AFeFET back-switching natively gives **ms-scale** decay. The time constant is a *material/field*
  property, decoupled from any capacitor.
- **(c) Digital / clocked leak (capacitor-free, fully defensible).** Subtract a fixed decrement per
  clock tick (or periodically pulse a small −V erase). τ_eff = T_clk / (decrement fraction). This is
  what TrueNorth/Loihi-class digital LIF do; pairs perfectly with the FeFET's accumulative state.

**R–C tradeoff math (put this in the paper):**
- τ = R·C. For τ = 10 ms:
  - C = 1.419 µF → R = 7.05 kΩ (old, absurd cap).
  - **C = 1 pF → R = 10 GΩ** (subthreshold-biased leak transistor).
  - **C = 100 fF → R = 100 GΩ** (deep-subthreshold).
  - C = 15 fF (FeLIF C_par) → R = 667 GΩ, or use polarization-time leak instead.
- Energy to charge the cap to V_mem: E = ½·C·V². At V=1 V: 1.419 µF → **0.71 µJ** (catastrophic);
  1 pF → **0.5 pJ**; 100 fF → **50 fJ**; 15 fF → **7.5 fJ**. This single line kills the old design.

**Recommended defensible value:** **C_mem ≈ 0.1–2 pF** if a cap is retained (matches every measured
CMOS/FeFET-LIF above), with the time constant set by a **subthreshold leak transistor or by the
FE/AFE depolarization time** — *not* by the cap. Or **C_mem = 0** with AFE self-reset / clocked leak.

---

## 4. Figures of merit that make a 2025–26 paper competitive

**Neuron (LIF):**
- Energy/spike: AFeFET **37 fJ/spike** (best class); Fe-SBFET 2T-IF **0.67 pJ**, 5T-LIF **2.6 pJ**;
  CMOS mixed-signal LIF (TSMC 65nm) **10.12 pJ/spike**; 7nm FinFET LIF down to **~aJ–fJ**
  (1.26 aJ at C_mem 0.79 fF, but GHz spiking). Target **sub-100 fJ/spike** to be competitive;
  **<40 fJ/spike** is state-of-art.
- Endurance: **>10¹²** (AFeFET) is the bar; FeFET memory typically 10⁵–10⁸ — call this out as a risk.
- Variability: C2C ~4%, D2D ~7.5% reported as "good."
- Area: single-transistor / 2-transistor neuron, capacitor-free; AFeFET neuron area ~ one device.

**Synapse / MAC:**
- **fJ/MAC equivalently 25–1200 TOPS/W** (see §1). Sub-fJ logic (0.0169 fJ/bit NOR).
- Bit density **26–223 Mb/mm²**; cell area **~0.076 µm²** (2FeFET, 45nm).
- Inference latency: ps-level per logic op; macro MAC at tens of MHz (66 MHz demo).
- Inference energy: **17 fJ/inference** (small Bayesian); full DNN system multi-µJ.

**System accuracy bar:** MNIST **>96%**, CIFAR-10 VGG-8 **>91%** *with* device non-idealities (NeuroSim).

---

## 5. GAAFET-specific advantages to emphasize (synapse vs neuron)

GAA = gate fully wraps an ultrathin channel/nanowire/nanosheet → best-in-class electrostatics.

- **Synapse role (strongest fit):**
  - Superior electrostatic control → **steep, near-ideal SS** (our ~62 mV/dec) → cleaner separation
    of multi-level V_th states → more reliable analog levels & wider read margin under variation.
  - **Low leakage / short-channel immunity** (GAA suppresses DIBL) → low R_off (our 71 MΩ), large
    ON/OFF (3140×) → high MAC SNR and low static read power.
  - **BEOL / monolithic-3D & vertical-GAA FeFET** demonstrated with 10 nm HZO (vertical nanowire
    GAA FeFET, 2025; 2-stacked nanosheet GAA MPB-FET with HZO, 2025) → high-density 3D crossbars,
    the headline density argument.
  - CMOS-compatible HZO crystallizes at **≤400 °C** → BEOL-friendly integration over logic.
- **Neuron role:**
  - GAA's tight gate coupling makes **partial-polarization accumulation more uniform** (better
    integrate linearity) and the steep SS sharpens the fire threshold.
  - GAA low off-current is double-edged: great for retention, but the **non-volatility means you
    must add an explicit leak** (AFE phase, depolarization engineering, or clocked leak — §2).
  - GAA channel multiplicity (nanosheet stacks) can host **multi-domain averaging** → lower C2C
    variation in the firing time.

**Framing:** lead with **GAA-FeFET-as-synapse** (electrostatics + low leakage + 3D/BEOL density are
exactly GAA's strengths), and use a **compact capacitor-free / pF-cap LIF neuron** (AFE-style or
clocked leak) for the periphery — *not* the µF-RC neuron.

---

## 6. Enumerated candidate circuit configurations (≥8)

| # | Configuration | Weight/role | Leak/integration | Key sizing | Pros | Cons |
|---|---|---|---|---|---|---|
| C1 | **1FeFET-1R synapse crossbar** (MLC) | multi-level V_th weight; MAC = activation-time + Σcurrent | n/a (inference only) | 64 fF accum cap; 28nm | 885 TOPS/W, 96.6% MNIST, no extra structure | needs ADC; MLC variation |
| C2 | **Differential 2-FeFET synapse (G+ − G−)** | signed weight via two devices/columns | n/a | cell 0.076 µm²; 223 Mb/mm² | true signed weights, 2× density, 196 TOPS/W | 2 devices/weight |
| C3 | **2FeFET-1T CiM (TReCiM)** | 1–2 b weight, subthreshold read | n/a | 128×128, V_read 0.35 V | 48 TOPS/W 2b, temp-resilient (3×) | extra transistor/cell |
| C4 | **Bit-sliced 1-FeFET (FELIX)** | 8b via bit-decomposition | n/a | 16×16 seg, 22nm FDSOI | 36.5 TOPS/W 8b/4b, no DAC, 3b ADC | digital shift-add periphery |
| C5 | **AFeFET capacitor-free LIF neuron** | neuron; integrate in polarization | **intrinsic AFE self-reset (ms)** | 1 device, no C, no reset T | 37 fJ/spike, >10¹² endurance, 96.8% MNIST | needs AFE-phase HZO (our device is FE — process change) |
| C6 | **Leaky-FeFET (L-FeFET) 1T-1R LIF** | neuron | engineered depol-field + gate leakage | 1T+1R; 5nm HZO/450°C | halves HW vs CMOS, spike-freq adaptation | precise leak control hard |
| C7 | **2T/7T FeFET I&F, negative-bias leak** | neuron, capacitor-free | leak phase −0.7 V/90 µs (tunable) | 2–7 transistors, no cap | capacitor-free, tunable leak, programmable | reset needs extra T + neg supply |
| C8 | **FeLIF (FeCap+CMOS) dual-variable neuron** | neuron | FeCap depolarization + dielectric RC | **C0 0.558 pF, C_par 15 fF**, 25 µm² | true ms tracking, sub-pF caps, SNN-validated | mixed-signal, larger area |
| C9 | **Fe-SBFET 2T-IF / 5T-LIFB neuron** | neuron (+synapse same device) | self-reset τ=1.05 ms / burst | 2T = 0.67 pJ, 5T = 2.6 pJ | single device type, no C/R, multifunction | pJ-class energy (higher) |
| C10 | **CMOS-LIF + FeFET synapse hybrid, clocked/subthreshold leak** | FeFET = weight, CMOS = neuron | subthreshold leak T or digital clocked decrement | **C_mem 0.1–2 pF, G_m 0.1–0.16 µS, τ 0.6–18.8 µs** | fully defensible, foundry-CMOS neuron, tiny cap | neuron not in FeFET |

**Recommended for our paper (ranked):**
1. **C2 differential GAA-FeFET synapse crossbar** (plays to GAA electrostatics + our 4-decade range) +
   **C10 compact CMOS-LIF with pF cap & subthreshold/clocked leak** as the neuron. Most defensible,
   directly kills the µF cap, both blocks are silicon-proven.
2. If we can claim an AFE/depolarization-engineered variant of our HZO: **C5/C6** for a
   capacitor-free single-device neuron headline (37 fJ/spike class) — higher novelty, needs process
   justification since our calibrated device is non-volatile FE.

---

## Sources

- MLC-FeFET IMC crossbar, 885 TOPS/W, 28nm — *First demonstration of in-memory computing crossbar using multi-level Cell FeFET*, Nature Communications 2023. https://www.nature.com/articles/s41467-023-42110-y / https://pmc.ncbi.nlm.nih.gov/articles/PMC10564859/
- FELIX, 36.5–1169 TOPS/W, 22nm FDSOI — *FELIX: A Ferroelectric FET Based Low Power Mixed-Signal In-Memory Architecture for DNN Acceleration*, ACM TECS. https://dl.acm.org/doi/10.1145/3529760
- DM-FeFET differential macro, 196 TOPS/W, 223 Mb/mm², 28nm — *Demonstration of Differential Mode FeFET Array-Based in-Memory Computing Macro*, Adv. Intell. Syst. 2023. https://bishtref.com/articles/10.1002/aisy.202200389
- TReCiM 2FeFET-1T, 26–48 TOPS/W, temp-resilient — arXiv:2501.01052. https://arxiv.org/abs/2501.01052
- CurFe/ChgFe dual FeFET IMC with shift-add — arXiv:2410.19593. https://arxiv.org/html/2410.19593
- FeBiM Bayesian, 581 TOPS/W, 17 fJ/inf, 26.32 Mb/mm² — arXiv:2410.19356. https://arxiv.org/html/2410.19356v1
- FeFET-CiM ADC-free logic, 0.0169 fJ/bit, 28nm — MDPI Electronics 15(4):841, 2026. https://www.mdpi.com/2079-9292/15/4/841
- Compact AFeFET neuron, 37 fJ/spike, >10¹² endurance, 96.8% MNIST — Nature Communications 2022. https://www.nature.com/articles/s41467-022-34774-9
- AFeFET reconfigurable LIF, self-reset, 10⁸ cycles — Nature Communications 2025. https://www.nature.com/articles/s41467-025-59603-7
- Leaky-FeFET (L-FeFET) 1T-1R, depolarization+leakage leak — Chen et al. VLSI 2019; reviewed in OSTI emerging-apps survey. https://www.osti.gov/pages/servlets/purl/3019473
- 2T/7T FeFET I&F capacitor-free, −0.7V/90µs leak — TU-Dresden SPICE study. https://tud.qucosa.de/api/qucosa%3A77196/attachment/ATT-0/
- FeLIF (FeCap+CMOS), C0 0.558 pF / C_par 15 fF, BRUNO SNN — Fehlings et al., Neuromorph. Comput. Eng. 2026. https://iopscience.iop.org/article/10.1088/2634-4386/ae573b
- Fe-SBFET neurons 28 fJ/state, 0.67 pJ (2T-IF), 2.6 pJ (5T-LIFB) — RWTH. https://publications.rwth-aachen.de/record/1024539/files/1024539.pdf
- Ferroelectric LIF review (metrics/optimization) — The Innovation Materials 4(2):100202, 2026. https://www.the-innovation.org/article/doi/10.59717/j.xinn-mater.2026.100202
- Ferroelectric neuromorphic devices review — Nature Reviews Electrical Engineering 2(773–787), 2025. https://www.nature.com/articles/s44287-025-00222-1
- CMOS mixed-signal LIF, 10.12 pJ/spike, C_mem 0.1–2 pF, G_m 0.106–0.164 µS, τ 0.6–18.8 µs, TSMC 65nm — UT-CERC-25-02. https://users.ece.utexas.edu/~gerstl/publications/UT-CERC-25-02.LIF.pdf
- 7nm FinFET LIF, C_mem 0.5–4 fF, 1.26 aJ/spike — arXiv:2505.03764. https://arxiv.org/pdf/2505.03764
- DG-FeFET astrocyte/dendrite (FDSOI), LIF params — arXiv:2504.14466. https://arxiv.org/html/2504.14466
- Vertical GAA FeFET, 10nm HZO, BEOL ≤400°C — ECS Meeting Abstr. 2025. https://iopscience.iop.org/article/10.1149/MA2025-01311591mtgabs
- 2-stacked nanosheet GAA MPB-FET, HZO — Adv. Sci. 2025. https://pmc.ncbi.nlm.nih.gov/articles/PMC12079460/
- GAA NW Fe-FET ML/XAI (TCAD-validated, CMOS-compatible, neuromorphic) — Phys. Scr. 100 056006, 2025. https://iopscience.iop.org/article/10.1088/1402-4896/adc499
- Grain-size-engineered HZO synapse, 100→136 states, G_max/G_min 5→90 — Nanoscale 2025. https://pubs.rsc.org/en/content/articlehtml/2025/nr/d4nr05381h
- Laminated HZO + plasma synapse, 75→100 states — Nanoscale 2025. https://pubs.rsc.org/en/content/articlehtml/2025/nr/d4nr04592k
- NeuroSim V1.5 benchmarking backbone — arXiv:2505.02314. https://arxiv.org/html/2505.02314
