```
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet/Paper-materials/research" && agy -p "Use your academic deep research skill AND your last30days skill. This is literature research for an undergraduate thesis that deploys a spiking neural network for electrocardiogram classification onto a ferroelectric analog synapse array. Topic: spiking neural networks for biosignal classification, ECG in particular. Cover: (1) reported SNN results on ECG arrhythmia classification — the dataset used (MIT-BIH Arrhythmia Database, PTB-XL, or other), the number of classes and whether the split is inter-patient or intra-patient, the network size and topology, the neuron model, the encoding scheme used to turn a continuous ECG waveform into spikes, and the accuracy achieved; be careful to record whether an accuracy is on a 2-class, 4-class or 5-class problem, because those numbers are not comparable; (2) SNNs deployed on actual neuromorphic or in-memory hardware for biosignal work — Loihi, SpiNNaker, TrueNorth, custom analog macros — with the energy per inference or per classification where stated; (3) the specific paper by Yuan and co-authors published in Nature Communications in 2023 on a ferroelectric or memristive spiking network for ECG or biosignal classification, reporting an accuracy near 95.83 percent — find it, give its exact title, full author list, DOI, dataset, network topology and its headline accuracy, and quote the sentence stating that accuracy; (4) how much accuracy the literature reports losing when a trained SNN is quantised to a small number of analog conductance levels, and any reported dependence on how those levels are spaced rather than merely how many there are. Prefer Nature Electronics, Nature Communications, Nature Machine Intelligence, IEEE Transactions on Biomedical Circuits and Systems, IEEE TED, IEDM, Frontiers in Neuroscience, Science Advances. Prefer 2023-2026; older work is acceptable only when it is the standard citation for a concept, and then state the year plainly. For EVERY factual claim you return, give: the claim in one sentence; the numeric value with units; the DOI; the full author list; the venue; the year; and a VERBATIM quoted sentence from the paper that contains that number. If you cannot attach a verbatim quote to a claim, drop the claim entirely — do not paraphrase from memory and do not guess a DOI. Flag clearly any source that is an arXiv preprint rather than a peer-reviewed publication. Output as markdown, one section per sub-question." --dangerously-skip-permissions --print-timeout 25m --effort high > E_snn_ecg.raw.md 2>&1
```

Date: 2026-08-02

---

## Local ground truth

STEP 0 of the original task: what the local project files actually say, before touching the literature. Source files: `PYTHON_Modelling_Fefet_Codes/ecg detection/README.md`, `.../METHODOLOGY.md`, `.../model.py`, and `PHASE_6_RESULTS.md`.

- **Base network attribution.** `README.md` §"Contents": *"`VO2_reference_paper.pdf` | The reference study (Yuan et al., *Nat. Commun.* 14:3695, 2023) whose LSNN architecture, neuron parameters and dataset we adopt; cited for those and for the CMOS-neuron parameters."*
- **What our project actually did with it.** `README.md` header: *"The device physics is the contribution: we adopt the reference VO2-memristor LSNN pipeline (its curated MIT-BIH dataset, level-crossing spike encoding, LSNN architecture and LIF/ALIF neuron parameters) and replace the reference's **software** synapses with our measured GAA-FeFET **hardware synapse**."* The encoder (level-crossing/delta, `UP`/`DOWN`/`CUE` channels) and neuron parameters (`model.py`, `eLIFVO2`/`ALIFVO2`) are the reference's, ported onto FeFET RC values.
- **Dataset / classes / split (our run).** `README.md` §"Result": *"MIT-BIH, 4 AAMI classes N/SVEB/VEB/F, intra-patient"*, protocol *"is **intra-patient** (random 1664/336 split of the curated `data_ecg` 2000-beat set). Report it as such."*
- **Network topology (our run).** `model.py` `VO2LSNN`: `DelayedLinear` input → `LinearDualRecurrentContainer` (LIF `eLIFVO2` + ALIF `ALIFVO2`) → `LPFilter` → linear `fc2` readout. `PHASE_6_RESULTS.md` §6.5 gives the exact deployed size: hidden layer is 160 neurons (100 LIF + 60 ALIF, not the reference's 60/40 split), `fc1.weight (160,3,10)`, `hidden.rc.weight (160,160,10)`, `fc2.weight (4,160)` — 261,440 weights / 522,880 FeFETs, because both `DelayedLinear` layers carry `max_delay=10` independently-programmed taps per connection.
- **Accuracy (our run) vs. the reference figure.** `README.md`: *"Software (full precision) 0.857 acc / On-device — 15 measured FeFET levels (300 K) 0.830 acc."* Explicitly stated next to the reference number: *"The reference study (Yuan et al., *Nat. Commun.* 14:3695, 2023) reports 95.83 % on the **same** MIT-BIH 4-class task and the **same** LSNN architecture, but with their VO2-memristor encoder and neurons and **software synapses**; our contribution is the **hardware device-synapse** (FeFET weights) and the device-physics demonstration, not matching that raw accuracy."*
- **`METHODOLOGY.md`** repeats this with the same 95.83 % figure and adds: *"The reference's 95.83% figure is on the **same LSNN architecture and the same 4-class task**, using its VO₂-memristor encoder and RC-based LIF/ALIF neurons with **software** synapses; matching that raw accuracy is not the target here."*

**Discrepancy check (STEP 0 requirement):** none found. Every local file that cites the number — README.md (×2), METHODOLOGY.md — states 95.83 %, MIT-BIH, 4 AAMI classes, and attributes it consistently to "Yuan et al., *Nat. Commun.* 14:3695, 2023." This matches the project's memory note verbatim. The only thing the local files do **not** state is whether the reference's split is formally "intra-patient" — see the CrossRef/PMC verification below, which resolves that gap: the reference paper itself never uses the term, but its numeric split (1664 train / 336 test, drawn from a pooled 2000-beat set) is the same random pooled split our project reports as intra-patient, and independently matches our own split counts exactly.

---

## Research return (agy, tidied — not reworded)

agy's raw output (`E_snn_ecg.raw.md`) printed the full report twice (a duplication artifact of the run, not a second research pass); content is deduplicated below. Every claim keeps agy's original number, DOI, venue, year and verbatim quote. Verification tags were added by fetching `https://api.crossref.org/works/<DOI>` for metadata and, where feasible, the open-access full text (via PMC) for the verbatim quotes.

### 1. Reported SNN results on ECG arrhythmia classification

#### Claim 1.1 — Yuan et al., 95.83 % on 4-class MIT-BIH `[VERIFIED]`
- **Claim**: Mixed 60-LIF + 40-ALIF LSNN with VO2-memristor asynchronous spike encoding reaches 95.83 % on 4 AAMI classes (N, VEB, SVEB, F), MIT-BIH.
- **Class count / split**: **4-class**, random pooled split (1664/336) — not called "inter-patient" or "intra-patient" by the paper itself, but methodologically the intra-patient style (see below).
- **DOI**: `10.1038/s41467-023-39430-4` — Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang — *Nature Communications* 14:3695 (2023)
- **Verbatim quote (confirmed against PMC10284901 full text, abstract)**: *"The system demonstrates superior computing capabilities, needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79% in arrhythmia classification and epileptic seizure detection, respectively."*
- **CrossRef check**: title, all 9 authors, venue, and year match agy's claim exactly.

#### Claim 1.2 — Yuan et al., LIF-only vs. mixed LSNN gap `[VERIFIED]`
- **Claim**: LIF-only LSNN underperforms the mixed LIF+ALIF LSNN by ~15 % (2-class) and ~18 % (4-class), 3×100×4 topology, MIT-BIH.
- **Class count / split**: **2-class and 4-class**, same random pooled split as above.
- **DOI**: `10.1038/s41467-023-39430-4` (same paper as 1.1)
- **Verbatim quote (confirmed against PMC10284901 full text)**: *"the LIF-only LSNN performed worse than the mixed LSNN by approximately 15% and 18% in terms of accuracy in the 2-class and the 4-class task, respectively"* — matches agy's quote exactly.

#### Claim 1.3 — Kolhar, 94.4 % clinical ECG `[VERIFIED, with important dataset/class/split correction]`
- **Claim**: SNN with bandpass filtering + amplitude-to-rate encoding reaches 94.4 % overall accuracy on multi-lead clinical ECG.
- **Class count / split**: agy's claim text did not specify — **verified from the actual paper (PMC12612072): this is NOT MIT-BIH.** Dataset is a 12-lead clinical repository of 45,152 patients (Chapman University / Shaoxing / Ningbo hospitals); classes are AFIB, SR, LBBB, RBBB (not the AAMI N/SVEB/VEB/F scheme); split is **strict inter-patient** ("no patient contributed samples to more than one of the training, validation, or test sets," 80-10-10 patient-wise). This accuracy is **not comparable** to the Yuan et al. 4-class AAMI number even though both papers report "4-class."
- **DOI**: `10.1038/s41598-025-23248-9` — Manjur Kolhar — *Scientific Reports* 15:39635 (2025)
- **Verbatim quote (confirmed against PMC12612072)**: *"The developed SNN achieved a high overall accuracy of 94.4% in arrhythmia detection tasks."*
- **CrossRef check**: author, venue, year match. agy did not supply the paper's real title in its claim text; the actual title is "A neuromorphic approach to early arrhythmia detection."

#### Claim 1.4 — Rana & Kim, 93.8 % MIT-BIH ANN-to-SNN transfer `[MISMATCH: fabricated / wrong DOI — DO NOT CITE]`
- **Claim as given by agy**: ANN-to-SNN transfer learning framework, LIF neurons, 93.8 % on MIT-BIH.
- **DOI given**: `10.3390/app14114569`
- **CrossRef result**: this DOI resolves to **"Research on the Construction of a Blockchain-Based Industrial Product Full Life Cycle Information Traceability System"**, authors Leifeng Xiao, Wenlei Sun, Saike Chang, Cheng Lu, Renben Jiang — a supply-chain blockchain paper with no relationship to SNNs, ECG, or Rana & Kim. **This is a fabricated citation**: agy attached a real, resolvable DOI to a paper it does not belong to.

#### Claim 1.5 — Ran et al., 89.74 % ECG+PCG `[VERIFIED]`
- **Claim**: Multi-channel SNN on joint ECG+PCG signals, 89.74 % on PhysioNet/CinC.
- **Class count / split**: **2-class (binary, normal vs. abnormal)**, dataset is PhysioNet/CinC Challenge **2016**; split is **inter-patient / patient-wise** (9:1 ratio, "all data augmentation procedures were conducted independently within the training and testing sets after the split" to prevent leakage) — confirmed against PMC12431316.
- **DOI**: `10.3390/s25175263` — Guihao Ran, Yijing Wang, Han Zhang, Jiahui Cheng, Dakun Lai — *Sensors* 25(17):5263 (2025)
- **Verbatim quote (confirmed)**: *"achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ"*

#### Claim 1.6 — Rathi, Panda & Roy, STDP pruning `[UNVERIFIED: arXiv preprint, 2017 — correctly flagged by agy itself]`
- No DOI, `arXiv:1710.04734`. Not peer-reviewed. Do not cite as a peer-reviewed source; usable only with an explicit preprint caveat if cited at all.

---

### 2. SNNs on neuromorphic / in-memory hardware for biosignal work

#### Claim 2.1 — Loihi, 23.6 pJ/event `[VERIFIED]`
- **DOI**: `10.1038/s41598-026-39515-2` — A. Sungheetha (Akey Sungheetha), Rajesh Sharma R., Balamurugan Balusamy, Shrikant Mapari, P. Karthik, Sumendra Yogarayan — *Scientific Reports* 16:10049 (2026)
- **Verbatim quote (confirmed against PMC13021978)**: *"Power-aware profiling confirms that all spiking computations remain within the Intel Loihi energy specification of 23.6 pJ per event, supporting sustainable deployment."*
- **Caveat**: full text shows this is the paper citing Intel's own published Loihi hardware spec ("Intel's Loihi neuromorphic research chip implements 130,000 spiking neurons with 130 million synaptic connections achieving energy efficiency of 23.6 pJ per spike operation..."), not a number the authors measured on their own biosignal workload. Cite as a Loihi hardware datum, not as this paper's original result.
- Actual paper title, for the record: "Biologically inspired neuromorphic-XAI synergy for transparent and low-carbon healthcare intelligence" — a healthcare-XAI paper, not ECG-specific.

#### Claim 2.2 — Ran et al., 209.6 μJ `[VERIFIED]` — duplicate citation of Claim 1.5's paper; see above for dataset/class/split.

#### Claim 2.3 — "Ran et al.", 4.62 μJ, 90.75 % `[MISMATCH: author names and task description wrong]`
- **DOI**: `10.3390/s26092859` — real, resolves.
- **CrossRef actual authors**: Guihao Ran, **Shengzhe** Li, **Zhiwen** Jiang, Han Zhang, **Xinyuan** Long, Dakun Lai.
- **agy's claimed authors**: Guihao Ran, **Shuo** Li, **Zimin** Jiang, Han Zhang, **Xi** Long, Dakun Lai — three of six given names are wrong (Shuo≠Shengzhe, Zimin≠Zhiwen, Xi≠Xinyuan). Family names and paper identity are correct, so this is not a fabricated DOI, but the author list as printed is not usable for a bibliography without correction.
- **Task description mismatch**: agy's claim says "multimodal EEG and ECG physiological signals." The actual title is **"UDC-SNN: An Uncertainty-Aware Dynamic Cascading Framework with Spiking Neural Network for Balancing Performance and Energy in Multimodal Emotion Recognition,"** and the quoted metric is reported "across the three dimensions of valence, arousal, and dominance" — standard emotion-recognition axes, not confirmed as ECG. Not independently verified against full text; do not present this as an ECG result.
- **Verbatim quote (as given by agy, DOI/venue confirmed, author names not)**: *"The averaged recognition accuracy and energy consumption across the three dimensions of valence, arousal, and dominance were 90.75% and 4.62 μJ, respectively."*

#### Claim 2.4 — Yuan et al., 41.5 μm² neuron area `[MISMATCH: number is wrong]`
- **DOI**: `10.1038/s41467-023-39430-4` (same base paper as 1.1/1.2/3)
- **agy's claim**: *"the LIF and ALIF neuron can achieve a small area of ~41.5 μm²"* (single combined figure).
- **Actual text (confirmed against PMC10284901)**: *"the LIF and ALIF neuron can achieve a small area of ~41.3 μm² and ~53.4 μm², respectively."* — two separate values for the two neuron types, neither of which is 41.5 μm². agy fabricated a single averaged-sounding number that does not appear in the source.

#### Claim 2.5 — Jeong et al., 6.5 ms inference latency `[VERIFIED, scope caveat]`
- **DOI**: `10.1021/acsnano.5c19720` — Siwoo Jeong et al. (24 authors, abbreviated list matches agy's) — *ACS Nano* 20(16):12236-12249 (2026)
- **Verbatim quote (as given by agy)**: *"...spike extraction (18.3 ± 2.0 ms), and SNN inference (6.5 ± 0.8 ms), demonstrating the feasibility of low-latency interaction."*
- **Scope caveat**: paper is "Event-Driven Neuromorphic Gaze Decoding via e-Skin Electrooculography" — this is **EOG (eye signal)**, not ECG. Fine as a general biosignal-hardware citation for §2 of the prompt, but must not be presented as ECG-specific.

---

### 3. Yuan et al. (*Nature Communications*, 2023) — full specification `[VERIFIED — base network source paper, all fields cross-checked against PMC10284901 full text]`

- **Exact title**: "A neuromorphic physiological signal processing system based on VO2 memristor for next-generation human-machine interface"
- **Full author list**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
- **DOI**: `10.1038/s41467-023-39430-4`
- **Venue / year**: *Nature Communications*, 14(1):3695, 2023 (issued June 21, 2023). PMCID PMC10284901.
- **Dataset (confirmed verbatim)**: *"2000 heartbeat samples were used as our dataset...the Normal (N), Ventricular ectopic beat (VEB), Supraventricular ectopic beat (SVEB), and Fusion beat (F) classes consisted of 1000, 500, 250, and 250 heartbeats, respectively"* — matches agy's and the project's own numbers exactly.
- **Split (confirmed verbatim)**: *"2000 heartbeat samples were used as our dataset, which were randomly split into a training set of 1664 samples and a testing set of 336 samples"* — the paper never uses the words "intra-patient" or "inter-patient." This is a random pooled split, the same style (and the exact same 1664/336 counts) our project's `README.md` calls intra-patient. **Class count: 4. Split: random/pooled (intra-patient by convention, not by the paper's own label).**
- **Network topology (confirmed verbatim)**: *"we used the proposed system with an LSNN of size 3 × 100 × 4, in which out of the 100 hidden neurons, 60 were LIF neurons while the other 40 were ALIF neurons."*
- **Headline accuracy / verbatim quote**: *"The system demonstrates superior computing capabilities, needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79% in arrhythmia classification and epileptic seizure detection, respectively."*
- **Discrepancy vs. project notes**: none in any of the above fields. CrossRef and PMC agree with the project's memory note and with `README.md`/`METHODOLOGY.md` on every point: title, author list, DOI, journal, volume/page (14:3695), dataset (2000 beats, 1000/500/250/250 by class), 3×100×4 (60 LIF/40 ALIF) topology, and the 95.83 % figure and its exact wording. The **only** correction found in this paper is unrelated to the headline number: the neuron-area figure agy separately reported in Claim 2.4 (41.5 μm²) does not match the source (41.3/53.4 μm² for LIF/ALIF).
- **Note for the thesis**: our project's own deployed network (`PHASE_6_RESULTS.md` §6.5) diverges from this reference topology — 160 hidden neurons (100 LIF + 60 ALIF) rather than the reference's 100 (60 LIF + 40 ALIF), because our redesign stage changed the split. Keep this distinction explicit whenever citing "the same LSNN architecture" — it is the same architecture *class* (delayed-FC → recurrent mixed LIF/ALIF → LP filter → linear read-out) with a different hidden-layer size, not an identical hyperparameter match.

---

### 4. Accuracy loss under conductance-level quantization, and dependence on level spacing

#### Claim 4.1 — Kumar & Tseng, linear/symmetric conductance modulation `[MISMATCH: author given name wrong]`
- **DOI**: `10.3390/nano16110657` — real, resolves. Title: "Polymer–Based Linear and Symmetric Artificial Synaptic Memristors for Accurate and Reliable Neuromorphic Computing Applications," *Nanomaterials*, 2026.
- **CrossRef actual first author**: **Anshu** Kumar. **agy's claimed first author**: **Atanu** Kumar. Given name is wrong; second author (Tseung-Yuen Tseng) and venue/year/quote are consistent with agy's claim.
- **Verbatim quote (as given by agy)**: *"Among these, linear and symmetric conductance modulation is particularly critical, as nonlinear or asymmetric weight updates introduce gradient distortion and significantly degrade learning accuracy in neuromorphic systems [12,13]."*
- No numeric accuracy-loss value attached to this claim (agy marked it N/A / qualitative).

#### Claim 4.2 — Kazmi et al., device variability bottlenecks `[VERIFIED]`
- **DOI**: `10.1007/s40820-026-02253-1` — Jamal Kazmi, Waqas Ahmad, Muhammad Naqi, Yawar Abbas, Aumber Abbas, Peijian Wang, Mohd Ambri Mohamed, Federico Rosei, Zhiming M. Wang, Hongwei Song — *Nano-Micro Letters* 18(1), article 2253 (2026). CrossRef author list matches agy's abbreviated list exactly.
- **Verbatim quote (as given by agy, not independently re-fetched from full text)**: *"Such demonstrations remain relatively limited in 2D-material-based systems because of challenges associated with device variability, retention, and non-ideal conductance updates [93, 94]."*
- Qualitative claim only, no numeric accuracy-loss value.

#### Claim 4.3 — Pei et al., binary-conductance SNN quantization `[MISMATCH: incomplete author list]`
- **DOI**: `10.3389/fnins.2023.1225871` — real, resolves. Title "ALBSNN: ultra-low latency adaptive local binary spiking neural network with accuracy loss estimator," *Frontiers in Neuroscience*, 2023.
- **CrossRef actual authors**: Yijian Pei, Changqing Xu, Zili Wu, Yi Liu, **Yintang Yang**.
- **agy's claimed authors**: Yijian Pei, Changqing Xu, Zili Wu, Yi Liu — dropped the fifth author (Yintang Yang).
- **Verbatim quote (as given by agy)**: *"In this study, we propose an ultra-low latency adaptive local binary spiking neural network (ALBSNN) with accuracy loss estimator."* — a title-paraphrase quote, not a data-bearing sentence; agy supplied no actual quantization-loss percentage from this paper.

#### Claim 4.4 — Yang et al., antiferroelectric multilevel synapse, >90 % yield / accuracy `[VERIFIED quote — MAJOR SCOPE CAVEAT, not ECG/SNN]`
- **DOI**: `10.1038/s41467-025-65691-2` — Dongliang Yang, Weifan Meng, Zhongyi Wang, Tianze Yu, Ce Li, Qianyu Zhang, Zirui Zhang, Huihan Li, Yinan Lin, Fei Xue, Peng Lin, Linfeng Sun — *Nature Communications* 16(1):10666 (2025), PMCID PMC12660946. Authors, venue, year confirmed against agy's list exactly.
- **Verbatim quotes (confirmed against PMC12660946 full text)**: *"the devices exhibit robust multilevel conductance modulation, stable bipolar switching (sustaining over 1000 cycles)"*; device yield *"the fabricated 5 × 5 array exhibited a device yield of 92% (23 out of 25 devices)"*; classification *"the system achieves a classification accuracy exceeding 90%"* with the specific figures *"achieving final test accuracies of 91.3% (CBPS) and 93.7% (ideal)."*
- **Scope caveat — read carefully before citing**: the paper's title is "Polymorphic functionalization driven by ion displacement-induced antiferroelectric ordering in CuBiP₂Se₆" — this is a **materials-physics paper**, and the classification demo is **facial recognition on the Olivetti Faces dataset (400 grayscale images, 40 individuals) mapped onto an artificial neural network**, not a spiking neural network and not ECG or any biosignal. Usable only as a generic "antiferroelectric multilevel conductance → >90 % array yield and classification accuracy is achievable" hardware datum — never as an ECG or SNN result.

#### Claim 4.5 — Smith, Whitehill & Ganji, "Quantization of SNNs Beyond Accuracy" `[VERIFIED metadata; quote is not data-bearing]`
- **DOI**: `10.1145/3822454.3822457` — Evan Smith, Jacob Whitehill, Fatemeh Ganji (Worcester Polytechnic Institute) — *Proceedings of ICONS '26* (International Conference on Neuromorphic Systems, Chicago), pp. 226–232, ACM, 2026. CrossRef confirms title, full author list, venue and year exactly.
- **Note**: agy's "verbatim quote" for this claim is literally the paper's own title, not a sentence containing data. agy correctly marked the numeric value as N/A. Useful only as a pointer to "quantization has multi-dimensional system trade-offs beyond raw accuracy" — no number to cite from this entry.

---

## Claims with no verifiable quote

- **Claim 1.6 (Rathi, Panda & Roy, arXiv:1710.04734, 2017)** — arXiv preprint, never peer-reviewed. agy flagged this correctly on its own. No DOI to verify against CrossRef. Cite only with an explicit "unreviewed preprint" caveat, if at all.
- **Claim 4.2 (Kazmi et al.)** and **Claim 4.1 quote text** — DOI/authors/venue verified via CrossRef, but the verbatim quotes were taken on trust from agy's raw output and not independently re-fetched from the paywalled/complex full text (Nano-Micro Letters, Nanomaterials) in this pass. Treat the sentence-level wording as agy-reported, not independently confirmed, even though the paper itself is real.
- **Claim 4.5 quote** — technically present, but it is the article title, not a data-bearing sentence. There is no verbatim numeric claim to attach to this entry.

---

## Do not cite

1. **Claim 1.4 — "Rana & Kim," DOI `10.3390/app14114569`.** Fabricated / wrong citation. The DOI resolves to an unrelated blockchain supply-chain paper (Xiao, Sun, Chang, Lu, Jiang, *Applied Sciences*, 2024). No paper matching agy's description ("93.8% MIT-BIH ANN-to-SNN transfer") was located under this DOI. If a "Rana & Kim ANN-to-SNN transfer, 93.8%, MIT-BIH" paper genuinely exists, it must be re-found and re-verified from scratch — do not reuse this DOI.
2. **Claim 1.6 — Rathi, Panda & Roy, arXiv:1710.04734 (2017).** Preprint, never peer-reviewed to date. Not citable as a peer-reviewed source in the thesis; usable only as background with an explicit preprint label.
3. **Claim 2.3 author list — DOI `10.3390/s26092859`.** The DOI and paper are real, but the author given names as reported by agy (Shuo Li, Zimin Jiang, Xi Long) are wrong (actual: Shengzhe Li, Zhiwen Jiang, Xinyuan Long), and the claim that the paper covers "EEG and ECG" is unverified against the actual full text (title indicates emotion recognition via valence/arousal/dominance, not confirmed ECG). Do not cite the 4.62 μJ / 90.75 % figures as an ECG-specific result without independently re-reading the paper.
4. **Claim 2.4 — 41.5 μm² neuron area, attributed to Yuan et al.** Number is fabricated: the source paper reports two separate values, 41.3 μm² (LIF) and 53.4 μm² (ALIF), not a single 41.5 μm² figure. If a neuron-area number is needed in the thesis, use 41.3 μm² / 53.4 μm² with the correct verbatim quote from PMC10284901.
5. **Claim 4.4 — Yang et al. antiferroelectric >90% accuracy.** Real and verified, but do not cite as an ECG, biosignal, or SNN result — the underlying demonstration is ANN-based facial recognition on the Olivetti Faces dataset. Usable only as a general hardware-yield/classification-accuracy datum for antiferroelectric multilevel synapses.

---

## BibTeX (VERIFIED entries only, CrossRef-sourced metadata)

```bibtex
@article{Yuan2023_NatComm,
  author  = {Yuan, Rui and Tiw, Pek Jun and Cai, Lei and Yang, Zhiyu and Liu, Chang and Zhang, Teng and Ge, Chen and Huang, Ru and Yang, Yuchao},
  title   = {A neuromorphic physiological signal processing system based on VO2 memristor for next-generation human-machine interface},
  journal = {Nature Communications},
  year    = {2023},
  volume  = {14},
  number  = {1},
  pages   = {3695},
  doi     = {10.1038/s41467-023-39430-4},
}

@article{Kolhar2025_SciRep,
  author  = {Kolhar, Manjur},
  title   = {A neuromorphic approach to early arrhythmia detection},
  journal = {Scientific Reports},
  year    = {2025},
  volume  = {15},
  number  = {1},
  pages   = {39635},
  doi     = {10.1038/s41598-025-23248-9},
}

@article{Ran2025_Sensors,
  author  = {Ran, Guihao and Wang, Yijing and Zhang, Han and Cheng, Jiahui and Lai, Dakun},
  title   = {Balancing Energy Consumption and Detection Accuracy in Cardiovascular Disease Diagnosis: A Spiking Neural Network-Based Approach with ECG and PCG Signals},
  journal = {Sensors},
  year    = {2025},
  volume  = {25},
  number  = {17},
  pages   = {5263},
  doi     = {10.3390/s25175263},
}

@article{Sungheetha2026_SciRep,
  author  = {Sungheetha, Akey and Sharma R., Rajesh and Balusamy, Balamurugan and Mapari, Shrikant and Karthik, P. and Yogarayan, Sumendra},
  title   = {Biologically inspired neuromorphic-XAI synergy for transparent and low-carbon healthcare intelligence},
  journal = {Scientific Reports},
  year    = {2026},
  volume  = {16},
  number  = {1},
  pages   = {10049},
  doi     = {10.1038/s41598-026-39515-2},
}

@article{Jeong2026_ACSNano,
  author  = {Jeong, Siwoo and Ko, Hyun Woo and Kang, Ji-Hoon and Ko, Jonghyeon and Sim, Inbo and Xu, Zhihao and Jeong, Hyeonu and Kim, Seung-Il and Choi, Yunseok and Jo, Suyeon and Shim, Jae Won and Seo, Paul Hongsuck and Chae, Min Seong and Kim, Yeni and Rehman, Abdul and Yeon, Hanwool and Park, Bo-In and Suh, Young-Woo and Lee, Hwa and Kim, Jeehwan and Lee, Kyusang and Bae, Sang-Hoon and Park, Min-Chul and Mun, Sungchul},
  title   = {Event-Driven Neuromorphic Gaze Decoding via e-Skin Electrooculography},
  journal = {ACS Nano},
  year    = {2026},
  volume  = {20},
  number  = {16},
  pages   = {12236--12249},
  doi     = {10.1021/acsnano.5c19720},
}

@article{Kazmi2026_NanoMicroLett,
  author  = {Kazmi, Jamal and Ahmad, Waqas and Naqi, Muhammad and Abbas, Yawar and Abbas, Aumber and Wang, Peijian and Mohamed, Mohd Ambri and Rosei, Federico and Wang, Zhiming M. and Song, Hongwei},
  title   = {2D Materials Powering Neuromorphic Intelligence},
  journal = {Nano-Micro Letters},
  year    = {2026},
  volume  = {18},
  number  = {1},
  pages   = {2253},
  doi     = {10.1007/s40820-026-02253-1},
}

@inproceedings{Smith2026_ICONS,
  author    = {Smith, Evan and Whitehill, Jacob and Ganji, Fatemeh},
  title     = {Quantization of Spiking Neural Networks Beyond Accuracy},
  booktitle = {Proceedings of the International Conference on Neuromorphic Systems (ICONS '26)},
  year      = {2026},
  pages     = {226--232},
  publisher = {ACM},
  address   = {Chicago, IL, USA},
  doi       = {10.1145/3822454.3822457},
}

@article{Yang2025_NatComm,
  author  = {Yang, Dongliang and Meng, Weifan and Wang, Zhongyi and Yu, Tianze and Li, Ce and Zhang, Qianyu and Zhang, Zirui and Li, Huihan and Lin, Yinan and Xue, Fei and Lin, Peng and Sun, Linfeng},
  title   = {Polymorphic functionalization driven by ion displacement-induced antiferroelectric ordering in CuBiP2Se6},
  journal = {Nature Communications},
  year    = {2025},
  volume  = {16},
  number  = {1},
  pages   = {10666},
  doi     = {10.1038/s41467-025-65691-2},
  note    = {Materials/ANN demo (Olivetti Faces facial recognition), NOT an ECG or SNN result -- cite only as a generic multilevel-conductance yield/accuracy datum.},
}
```

Not added to BibTeX (see "Do not cite" above): Claim 1.4 (fabricated DOI), Claim 1.6 (arXiv preprint), and the `s26092859` entry (author-name errors, unverified ECG relevance) — none of literature.bib should be updated from this file; this list is for the coordinator/thesis author's own paste-in.
