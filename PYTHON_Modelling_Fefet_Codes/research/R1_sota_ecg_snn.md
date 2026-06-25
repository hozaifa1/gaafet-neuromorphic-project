# R1 — SOTA for ECG Arrhythmia Classification (SNN / Memristor / FeFET context)

Research note for the GAA-HZO-FeFET SNN paper (target: IEEE TED / Nature Electronics).
Date: 2026-06-24. All numbers below carry an explicit **protocol tag** because the headline accuracy is meaningless without it.

---

## 0. The single most important caveat (read first)

**Intra-patient vs inter-patient is the entire ballgame.** On MIT-BIH:

- **Intra-patient** (beats from the same patient appear in both train and test; random/stratified beat-wise split) routinely yields **99–99.8% accuracy and >0.98 macro-F1**. These numbers are inflated and a competent reviewer at TED / Nature Electronics treats them as *near-meaningless* for clinical claims. The model memorizes per-patient morphology.
- **Inter-patient** (de Chazal DS1 train / DS2 test, patients strictly disjoint) is the AAMI-recommended, clinically realistic protocol. Best-in-class here is **~97–98% overall accuracy BUT with minority-class (SVEB/S) F1 frequently in the 0.45–0.90 range and overall macro-F1 typically 0.80–0.92**. This is the bar that matters.

A 2025 systematic review (Silva et al., arXiv:2503.07276, "E3C" criteria: inter-patient + AAMI + embedded feasibility) found that **the large majority of high-accuracy ECG papers do NOT use inter-patient splits**, and explicitly flags this as the field's core credibility problem. Cite this review as your protocol justification.

de Chazal inter-patient split (canonical, memorize this):
- **DS1 (train):** 101,106,108,109,112,114,115,116,118,119,122,124,201,203,205,207,208,209,215,220,223,230
- **DS2 (test):** 100,103,105,111,113,117,121,123,200,202,210,212,213,214,219,221,222,228,231,232,233,234
- AAMI superclasses: N, S (SVEB), V (VEB), F, Q. Q is usually dropped (paced/unclassifiable; records 102,104,107,217 excluded).
- DS2 class counts (≈): N 44,259 / S 1,837 / V 3,221 / F 388 / Q 7 — **massive N imbalance (~89% N)**, which is exactly why accuracy alone is a trap.

---

## Q1. State-of-the-art by category

### (a) Conventional deep nets

**Intra-patient (inflated, do not compete here):**
- ConvNeXtTiny + SMOTE-TomekLink (Zubair et al., *Sci Rep* 2024, s41598-024-81992-w): **99.75% acc**, F1 ~0.9975. Intra-patient, SMOTE-balanced.
- MAK-Net (multiscale CNN + KAN, semanticscholar e373…): **99.80% acc, 0.9888 F1**. Intra-patient + SMOTE. Authors themselves concede inter-patient is the more stringent test they did not do.
- SE-multi-input CNN (PLOS One 2025, pone.0326079): **99.13% acc, 0.9446 macro-F1** (MIT-BIH), 95.84%/0.9591 (SPH). Intra-patient.
- rECGnition_v2.0 (arXiv:2502.16255): **98.07% acc / 98.05% F1** on 10-class; 99.01% F1 on 5-class AAMI. Mixed protocol — treat headline as intra-patient-flavored.

**Inter-patient (the real SOTA — these are the credible competitors):**
- MWCapsuleNets (MLP + weight capsule + Seq2seq, *Front. Physiol.* 2023, fphys.2023.1247587): reports very high per-class numbers but **trained on DS1_3 subset**; per the paper its overall ranks ~3rd in literature; S-class PPV 97.37%. Treat with caution — non-standard training subset.
- Tiny Matched-Filter CNN (Farag, *Sensors* 2023, sensors-23-01365): **98.18% acc, 92.17% macro-F1 (3-class N/S/V), SVEB Sen 85.3%, VEB Sen 96.34%**, 15 KB model. Clean inter-patient, edge-deployable — a strong, honest baseline.
- Ait Bourkha et al. (*IJACSA* 2024, vol15no2 paper 65): inter-patient 3-class, **98.06% acc**, V-class F1 95.89%, **S-class Sen only 77.75%** (shows the SVEB wall).
- SE-ResNet + expert features (Liu et al., *Med. Eng. Phys.* 2024, 104209): inter-patient **overall F1 83.39%** (5-class). Realistic, sober number.
- Fourier-decomposition + SVM (Fatimah et al., *Med. Eng. Phys.* 2024, 104102): inter-patient **98.03% acc, SVEB F1 89.35%, MCC 91.84%** — notable for explicitly reporting MCC and best-in-class SVEB.
- CNN+Transformer (PMC10933543): inter-patient overall acc **98.8% (EXP2) / 97.2% (EXP3)**; EXP3 SVEB still drops markedly.

**Takeaway:** credible inter-patient overall accuracy tops out ~98%; the discriminating metric is **SVEB (S) F1/sensitivity**, where even SOTA sits ~0.78–0.92.

### (b) SNNs specifically

- **sparrowSNN** (arXiv:2406.06543, HW/SW co-design + ASIC): **98.29% acc — claimed SOTA *for SNNs* on MIT-BIH**, 31.39 nJ/inference, 6.1 µW. Protocol is the Kachuee 5-class 80/20 split (intra-patient-style, not de Chazal). This is the number to beat for "best SNN accuracy," but flag its non-inter-patient protocol.
- **Xing et al.** (SNN + Channel-Wise Attention, FPGA; in Silva review): **98.26% acc, Sen 94.75%, F1 89.09%** under 70:30; **inter-patient acc drops to 92.07%** — a clean, honest intra-vs-inter delta you should cite.
- **Rana et al.** (LIF + attention, ANN→SNN, *Sensors* 2024, 24(11):3426): **93.8% acc, 85.4% F1, 88.0% precision** (MIT-BIH). Beats its 12-layer ANN baseline (89.9% acc / 83.6% F1).
- **DiSNN / MSPAN** (*Front. Neurosci.* 2021): 93.6% (algo) → **92.25% (on memristor CIM)**, 4-class.
- **Event-driven SCNN + LC-ADC** (arXiv:2205.13292): **93.59–94.01% acc**, level-crossing front-end (directly comparable to your delta-modulation encoder).
- Buettner et al. (ISVLSI, NSF-SHREC, Loihi via SNN-Toolbox): ANN→SNN on Kachuee 5-class; uses AAMI metrics + macro-F1; ~26× better EDP than Jetson Nano.

**SNN reality:** software/ASIC SNNs reach ~98% on easy (intra-patient/Kachuee) splits; on inter-patient they sit low-90s. No SNN paper convincingly cracks the SVEB wall under inter-patient.

### (c) Memristor / FeFET / in-memory-computing hardware demos

- **VO2 memristor LSNN — Yuan et al., *Nat. Commun.* 2023, s41467-023-39430-4 (this is "NCOMMS-23-03137").** Arrhythmia **95.83%**, seizure 99.79%. (See Q2 — this is your direct comparator.)
- **3D AND-flash CIM** (Im et al., *Adv. Sci.* 2024, advs.202308460): **93.5% acc**, STDP, 5-class. In-memory.
- **Flexible self-rectifying charge-trap memristor (f-MDPE)** (Lee et al., *Nat. Commun.* 2025, s41467-025-59589-2): **93.5% acc, macro-F1 0.774 (raw) / 0.804 (reconstructed), micro-F1 0.815–0.847**; 32×32 flexible crossbar, 0.3% of digital energy. **Reports macro-F1 explicitly — a good template and a sobering hardware number.**
- **FeFET CIM crossbar (multi-level, 28 nm HKMG)** (PMC10564859): first MLC-FeFET MAC macro; 96.6% MNIST / 91.5% CIFAR — **not ECG**, but the canonical FeFET-IMC device demonstration to cite for device credibility.
- **FeFET on-chip-learning CNN for ECG** (Hoogland MSc thesis, TU Delft): FeFET CIM accelerator benchmarked on MIT-BIH ECG — useful as a FeFET+ECG existence proof (thesis, not peer-reviewed; cite cautiously).
- **FeBiM** (arXiv:2410.19356): FeFET Bayesian inference engine, 581 TOPS/W — device-efficiency benchmark, not ECG.
- **Memristor neuromorphic (Hassan et al., EMBC 2018):** 96.17% 5-class, 34 ms/beat — older, intra-patient.

**FeFET-specific ECG with rigorous inter-patient + macro-F1: essentially a gap in the literature.** That gap is your opportunity (see Q4/Q5).

---

## Q2. The NCOMMS-23-03137 VO2 paper — exact identification and scrutiny

**Yuan, Tiw, Cai, Yang, Liu, Zhang, Ge, Huang, Yang. "A neuromorphic physiological signal processing system based on VO2 memristor for next-generation human-machine interface." *Nature Communications* 14, 3603 (2023). DOI 10.1038/s41467-023-39430-4.** Code: github.com/pekjuntiw/NCOMMS-23-03137.

- **Architecture:** VO2 threshold-switching memristors build (i) an asynchronous spike *encoder* (LC-ADC / delta-modulator-inspired, emits UP/DOWN spike trains) and (ii) LIF + Adaptive-LIF (ALIF) neurons inside a **Long-Short-Term-Memory Spiking Neural Network (LSNN)** trained by BPTT with surrogate gradients.
- **Task / classes:** ECG heartbeat classification, **4 AAMI classes: N, VEB, SVEB, F** (also a 2-class N/not-N task). Matches your N/F/S/V framing.
- **Reported accuracy: 95.83%** (max test accuracy over 150 epochs, Fig. 5h). The paper provides a **confusion matrix (Fig. 5i)** and an ablation (Fig. 5j) showing ALIF neurons are what give the LSNN its capacity (mixed LSNN > LIF-only, ALIF-only).

**Critical reconciliation with your brief:** the published headline is **95.83%, not 89.58%**, and the paper does not foreground a "336-test-beat / 2000-beat" framing. The 89.58% / 90.18% / 2000-beat-split numbers appear to come from **your prior FeFET port's specific reimplementation** of the dataset (likely a balanced 2000-beat subset, 1664/336 split), *not* from the original VO2 paper. **Action: verify exactly which split your prior port used before claiming "we beat the VO2 paper."** Comparing your 90.18% against their 95.83% would be a self-inflicted wound; comparing like-for-like on your own 2000-beat balanced subset is defensible only if you also reproduce their protocol.

**Is 95.83% on a small test set credible / what would a reviewer demand?**
- The original uses MIT-BIH with a balanced/subset selection and a *patient-mixed* (effectively intra-patient) split — so 95.83% is **not directly comparable to inter-patient SOTA** and is on the optimistic side. A ~336-beat test set (your port) gives a **±~3.3% 95% CI on a single accuracy point** (binomial, p≈0.9, n=336) — i.e., 90.18% vs 89.58% is **statistically indistinguishable noise**. Do not hang a claim on a 0.6-point gap.
- A TED / Nature Electronics reviewer will demand, at minimum: **(1) inter-patient (de Chazal DS1/DS2) split; (2) per-class sensitivity/+P/F1 with the full confusion matrix; (3) macro-F1 (not just accuracy) given the N imbalance; (4) a test set far larger than 336 beats — ideally the full DS2 (~49k beats); (5) Cohen's kappa or MCC; (6) variability/error bars across seeds or device-variation Monte Carlo for the hardware claim.**

---

## Q3. Metrics top reviewers now require for class-imbalanced ECG

Top-1 accuracy alone is **disqualifying** for imbalanced ECG. Expected reporting package:

1. **Macro-F1** (unweighted mean of per-class F1) — the headline fairness metric; dominated by SVEB/F performance.
2. **Per-class sensitivity (recall/Se) and positive predictivity (+P / precision)** for N, S, V, F — AAMI EC57 standard. SVEB Se is the field's hardest number.
3. **Specificity** per class.
4. **AAMI Se / +P / FPR / Acc** reporting convention (de Chazal-style table).
5. **Cohen's kappa** and/or **Matthews Correlation Coefficient (MCC)** — both robust to imbalance; MCC increasingly expected (e.g., Fatimah 2024 reports MCC 91.84%).
6. **Full confusion matrix** (non-negotiable).
7. For hardware: **energy/inference, power, area, device-variation robustness** (Monte Carlo over C2C/D2D variation), and accuracy-under-variation.

State explicitly that you report inter-patient. Reviewers now actively penalize unstated intra-patient inflation.

---

## Q4. 2024–2026 FeFET- / GAAFET-specific neuromorphic biosignal/ECG papers

- **FeFET-IMC is well established for image tasks** (MLC-FeFET MAC macro, 28 nm HKMG, PMC10564859, 2023; Variation-resilient FeFET BNN, arXiv:2312.15444; FeBiM Bayesian engine, arXiv:2410.19356) — device role = **synaptic weight / MAC crossbar**.
- **FeFET-specific ECG**: only the **TU Delft MSc thesis (Hoogland)** benchmarks a FeFET CIM accelerator on MIT-BIH ECG (device = synapse, on-chip learning CNN). No peer-reviewed FeFET+ECG inter-patient paper with macro-F1 found.
- **GAAFET-specific neuromorphic biosignal**: **no dedicated published GAA-FeFET ECG/biosignal classifier found** in 2024–2026. The closest neuromorphic-ECG hardware are non-FeFET (VO2, RRAM, charge-trap flash, 3D-AND flash).
- Device-role landscape in neuromorphic ECG: **VO2 → neurons (LIF/ALIF) + spike encoder**; **RRAM/flash/charge-trap → synapses (crossbar MAC)**. Your GAA-HZO-FeFET can plausibly claim **both** (analog synapse via polarization states + LIF neuron via your τ_P dynamics) — a genuine novelty angle, but only single-shot LIF "fire" is currently defensible per your device notes (multi-cycle LIF blocked by τ_P=0 latch).

**Conclusion: a rigorous GAA-HZO-FeFET ECG-SNN with inter-patient evaluation and full AAMI metrics would be, to the best of this search, the first of its kind.** That is the headline novelty — not the accuracy number.

---

## Q5. Recommended benchmark target (defensible "beats prior work")

**Do NOT frame the contribution as "we beat 89.58%/95.83% accuracy."** A 0.6-point gain on 336 beats dies in review. Frame it on **protocol rigor + device novelty + competitive macro-F1 at hardware-relevant energy**.

**Primary headline target (the credible claim):**
> On the **inter-patient (de Chazal DS1/DS2)** MIT-BIH protocol, 4-class AAMI (N/S/V/F), report **overall accuracy ≥ 97%** *with* **macro-F1 ≥ 0.88** and **SVEB (S) F1 ≥ 0.80**, full confusion matrix, **Cohen's kappa ≥ 0.85** and **MCC**, plus **per-pulse energy (~0.02 fJ/pulse regime from your device)** and accuracy-under-device-variation Monte Carlo.

Rationale: this **matches or exceeds the best honest inter-patient deep nets** (Farag 92% macro-F1 / 3-class; Liu 83% F1 / 5-class; Fatimah SVEB-F1 89%) while **dominating every neuromorphic-hardware demo** (VO2 95.83% but patient-mixed; f-MDPE macro-F1 0.774–0.804; flash/RRAM CIM 92–93.5%) on protocol rigor, and being the **first FeFET (and first GAAFET) ECG-SNN** with this evaluation.

**Secondary "SNN SOTA" target (if you keep the easy split for one comparison table):**
> Reproduce the VO2 paper's own protocol/subset and show **≥ 95.83% accuracy with comparable or better macro-F1**, *plus* a separate inter-patient table. This gives a like-for-like win over NCOMMS-23-03137 without protocol cheating.

**Hard numbers to beat, by lane:**
| Lane | Number to beat | Source | Protocol |
|---|---|---|---|
| Best SNN accuracy | 98.29% acc | sparrowSNN 2024 | Kachuee 5-class (not inter-patient) |
| Direct comparator (VO2) | 95.83% acc, 4-class | Yuan *Nat.Commun.* 2023 | patient-mixed subset |
| Best memristor/FeFET ECG macro-F1 | 0.774–0.804 macro-F1 | f-MDPE *Nat.Commun.* 2025 | inter-patient-ish, full DS2 |
| Best honest inter-patient SVEB-F1 | 0.8935 | Fatimah 2024 | inter-patient DS1/DS2 |
| Best inter-patient 5-class overall F1 | ~0.834 | Liu *MEP* 2024 | inter-patient DS1/DS2 |

**Non-negotiables for survival in review:** inter-patient split named explicitly; full confusion matrix; macro-F1 + per-class Se/+P; kappa/MCC; test set ≫ 336 beats (use full DS2); error bars / variation Monte Carlo on the hardware claim; honest statement that intra-patient numbers (yours or others') are not the basis of the claim.

---

## Skeptical flags (things that would NOT survive peer review)

1. **"90.18% beats 89.58%"** on a 336-beat test set — inside the ±3.3% confidence interval; statistically meaningless. **Drop this framing entirely.**
2. **Comparing your number to the VO2 95.83%** without matching protocol — you'd be comparing a possibly-harder split to an easier one and could appear to *lose*.
3. **Any intra-patient 99%+ number** presented as a contribution — reviewers will flag inflation immediately.
4. **Accuracy without macro-F1 / confusion matrix** on ~89%-N-imbalanced data — desk-reject risk.
5. **Single-seed / single-run hardware accuracy** with no device-variation analysis — a TED/Nat.Elec. device reviewer will demand C2C/D2D Monte Carlo.
6. **GAA "first" claims** — defensible per this search, but phrase as "to our knowledge, the first GAA-FeFET ECG-SNN," and back the device role (synapse vs neuron) explicitly given your single-shot-LIF constraint.

---

## Key citations (authors / venue / year / number / protocol)

- Yuan, Tiw, Cai, et al. *Nat. Commun.* 14:3603 (2023) — VO2 LSNN, **95.83%** 4-class, patient-mixed. **[NCOMMS-23-03137]**
- Silva, Silva, Moreira, et al. arXiv:2503.07276 (2025) — systematic review, E3C/inter-patient standardization. **[cite for protocol]**
- de Chazal et al. (2004) — inter-patient DS1/DS2 paradigm. **[cite for split]**
- sparrowSNN, arXiv:2406.06543 (2024) — **98.29%** SNN SOTA, 31.39 nJ, Kachuee split.
- Xing et al. (in Silva review) — SNN+CAM, 98.26% (70:30) / **92.07% inter-patient**.
- Rana et al. *Sensors* 24(11):3426 (2024) — SNN LIF+attention, 93.8% / F1 85.4%.
- Lee, Rhee, Kim, et al. *Nat. Commun.* 16 (2025), s41467-025-59589-2 — flexible charge-trap memristor f-MDPE, 93.5% acc, **macro-F1 0.774–0.804**.
- Im, Shin, Lee, et al. *Adv. Sci.* 11(26) (2024), advs.202308460 — 3D AND-flash CIM, 93.5%, STDP.
- MLC-FeFET MAC macro, PMC10564859 (2023) — FeFET-IMC device benchmark (MNIST 96.6%).
- Farag, *Sensors* 23(1):1365 (2023) — Tiny MF-CNN, inter-patient **98.18% acc / 92.17% macro-F1 (3-class)**, SVEB Se 85.3%.
- Liu et al. *Med. Eng. Phys.* 130:104209 (2024) — SE-ResNet+expert, inter-patient **overall F1 83.39%** (5-class).
- Fatimah et al. *Med. Eng. Phys.* (2024), 104102 — FDM+SVM, inter-patient 98.03% acc, **SVEB F1 89.35%, MCC 91.84%**.
- Zubair et al. *Sci Rep* 14 (2024), s41598-024-81992-w — ConvNeXt+STL, **99.75%** intra-patient (inflated).
