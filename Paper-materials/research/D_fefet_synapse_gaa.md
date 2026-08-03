```
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet/Paper-materials/research" && agy -p "Use your academic deep research skill AND your last30days skill. This is literature research for an undergraduate thesis on a ferroelectric HZO gate-all-around FET used as an analog synapse. Topic, in three parts. PART 1 — FeFET synapses: published FeFET analog-synapse work; how many conductance levels are demonstrated; the programming scheme used (identical-pulse trains, amplitude modulation, width modulation, incremental step pulse programming); whether write-verify or program-and-verify is used and how many levels it buys compared to open-loop programming; the reported energy per weight update; and reported linearity and symmetry of potentiation and depression. PART 2 — the gate-all-around / nanosheet transistor: why the industry moved from FinFET to nanosheet gate-all-around at the 3 nm and 2 nm nodes, what electrostatic gate control gains in terms of subthreshold slope, drain-induced barrier lowering and short-channel immunity, and reported nanosheet device metrics. PART 3 — THE INTERSECTION, and this is the decisive question: has ANYONE published a ferroelectric gate-all-around or ferroelectric nanosheet FET — that is, a GAA/nanosheet transistor with a ferroelectric HfO2-family gate stack, whether as memory or as a synapse, experimentally or in simulation? Search hard and specifically for this: try the phrasings ferroelectric nanosheet FET, FeFET nanosheet, GAA FeFET, gate-all-around ferroelectric memory, nanosheet ferroelectric NVM, ferroelectric vertical nanowire FET, and check IEDM and VLSI Symposium proceedings for 2022 through 2026. If work exists, list it with full details. If nothing exists, say so explicitly and describe what searches you ran to reach that conclusion — a clean negative result with its search terms is exactly as valuable here as a positive one, so do not manufacture a match. Prefer IEDM, VLSI Symposium, IEEE TED, IEEE EDL, Nature Electronics, Nature Communications, Nature Materials, Advanced Materials, Science Advances, Advanced Electronic Materials. Prefer 2023-2026; older work is acceptable only when it is the standard citation for a concept, and then state the year plainly. For EVERY factual claim you return, give: the claim in one sentence; the numeric value with units; the DOI; the full author list; the venue; the year; and a VERBATIM quoted sentence from the paper that contains that number. If you cannot attach a verbatim quote to a claim, drop the claim entirely — do not paraphrase from memory and do not guess a DOI. Flag clearly any source that is an arXiv preprint rather than a peer-reviewed publication. Output as markdown, one section per part." --dangerously-skip-permissions --print-timeout 25m --effort high > D_fefet_synapse_gaa.raw.md 2>&1
```

**Date:** 2026-08-02
**Raw output:** `D_fefet_synapse_gaa.raw.md` (18 KB, agy exit code 0)
**Verification method:** every DOI below was fetched from `https://api.crossref.org/works/<DOI>` and its `title`, `container-title`, `issued` year, first author, and `type` were compared against agy's claim. `type: posted-content` or an arXiv container would mean preprint — none were found. A tag of `[VERIFIED]` means the DOI resolves and its title/venue/year/author match agy's citation; it does **not** mean the specific numeric value inside the paper was independently re-extracted from full text (most of these are IEEE-paywalled), so the verbatim quote is reported as agy returned it, not re-fetched from the publisher.

---

## PART 1 — FeFET Synapses

### 1. Multi-Bit Conductance Precision & Dynamic Range in HZO FeFET Synapses `[VERIFIED]`
* **Claim:** Voltage-controlled partial polarization switching in HfO2/HZO FeFETs enables 5-bit analog synaptic weight precision (32 conductance states) with a 45x tunable conductance range using 75 ns update pulses.
* **Numeric value:** 5-bit precision (32 states); 45x conductance range; 75 ns update pulse.
* **DOI:** [10.1109/IEDM.2017.8268338](https://doi.org/10.1109/IEDM.2017.8268338)
* **Crossref check:** title "Ferroelectric FET analog synapse for acceleration of deep neural network training"; venue "2017 IEEE International Electron Devices Meeting (IEDM)"; year 2017; first author Matthew Jerry; type `proceedings-article`. Matches agy's citation.
* **Author list:** Matthew Jerry, Pai-Yu Chen, Jianchi Zhang, Pankaj Sharma, Kai Ni, Shimeng Yu, Suman Datta
* **Venue / Year:** IEDM, 2017
* **Verbatim quote:** *"We experimentally demonstrate a 5-bit FeFET synapse with symmetric potentiation and depression characteristics, and a 45x tunable range in conductance with 75ns update pulse."*

### 2. High-Precision Superlattice FeFET Analog Synapse `[VERIFIED]`
* **Claim:** A ferroelectric/dielectric superlattice gate stack (HZO/Al2O3) mitigates weight-update non-idealities, giving a 7-bit analog synapse with 94.1% MNIST accuracy and endurance >10^10 cycles.
* **Numeric value:** 7-bit precision (128 states); 94.1% online-training accuracy; >10^10 cycling endurance.
* **DOI:** [10.1109/TED.2022.3142239](https://doi.org/10.1109/TED.2022.3142239)
* **Crossref check:** title "BEOL-Compatible Superlattice FEFET Analog Synapse With Improved Linearity and Symmetry of Weight Update"; venue IEEE Transactions on Electron Devices; year 2022; first author Khandker Akif Aabrar; type `journal-article`. Matches.
* **Author list:** Khandker Akif Aabrar, Sharadindu Gopal Kirtania, Fu-Xiang Liang, Jorge Gómez, Matthew San Jose, Yandong Luo, Huacheng Ye, Sourav Dutta, Priyankka Gundlapudi Ravikumar, Prasanna Venkatesan Ravindran, Asif Islam Khan, Shimeng Yu, Suman Datta
* **Venue / Year:** IEEE TED, 2022
* **Verbatim quote:** *"We demonstrate a 7-bit SL-FEFET analog synapse with improved weight update profile, resulting in 94.1% online training accuracy for MNIST handwritten digit classification task."*

### 3. Energy Efficiency and System-Level Compute Density `[VERIFIED]`
* **Claim:** Multi-level FeFET crossbar arrays reach 885.4 TOPS/W MAC efficiency in 28 nm HKMG technology.
* **Numeric value:** 885.4 TOPS/W; 96.6% handwriting-recognition accuracy; 91.5% image-classification accuracy.
* **DOI:** [10.1038/s41467-023-42110-y](https://doi.org/10.1038/s41467-023-42110-y)
* **Crossref check:** title "First demonstration of in-memory computing crossbar using multi-level Cell FeFET"; venue Nature Communications; year 2023; first author Taha Soliman; type `journal-article`. Matches.
* **Author list:** Taha Soliman, Swetaki Chatterjee, Nellie Laleni, Franz Müller, Tobias Kirchner, Norbert Wehn, Thomas Kämpfe, Yogesh Singh Chauhan, Hussam Amrouch
* **Venue / Year:** Nature Communications, 2023
* **Verbatim quote:** *"Furthermore, it demonstrates exceptional performance, achieving 885.4 TOPS/W-nearly double that of existing designs."*

### 4. Programming Schemes & Closed-Loop Write-Verify Impact `[UNVERIFIED — synthesis, no single DOI/quote]`
This block is agy's own synthesis across the above (and general) literature, not a single-source claim, so it carries no DOI/verbatim-quote pair and cannot be graded VERIFIED. Reproduced as-is for context only; do not cite directly.
* **Identical pulse trains (open-loop):** domain accumulation via nucleation-limited switching (NLS); simplest scheme but variability-limited to ~4-5 bits (16-32 levels), nonlinear potentiation/depression (alpha ~ 2-4).
* **ISPP / amplitude-width modulation:** ramped write voltage (~20-50 mV steps) or pulse width linearizes domain growth, reaching ~6 bits (64 states) without read-verify.
* **Write-verify / program-and-verify (closed-loop):** iterative write-read-compare loop; expands state capacity from 16-32 levels (open-loop) to 64-128 levels (6-7 bit, citing Aabrar et al. 2022 above), at added latency/read-energy cost.
* **Energy per weight update:** FeFET write energy ~1 fJ to tens of fJ per pulse (Cg·V^2-dominated) — several orders of magnitude below RRAM (~10 pJ) or PCM (~100 pJ).

---

## PART 2 — The Gate-All-Around / Nanosheet Transistor

### 1. Industry transition FinFET → nanosheet GAA `[UNVERIFIED — general/no single quoted source]`
Narrative background (Samsung 3 nm MBCFET, TSMC 2 nm N2, Intel 20A RibbonFET) with no DOI attached by agy. Standard, uncontroversial industry framing but not independently source-checked here; treat as background, not a citable claim.

### 2. Quantitative Electrostatic Metrics: Nanosheet vs FinFET `[VERIFIED]`
* **Claim:** Dual-k-spacer multi-channel nanosheet FETs achieve SS = 62 mV/dec, DIBL = 14 mV/V, Ion/Ioff ~10^5.
* **Numeric value:** SS = 62 mV/dec; DIBL = 14 mV/V; Ion/Ioff = 10^5; Vth = 0.38 V.
* **DOI:** [10.1109/access.2024.3392621](https://doi.org/10.1109/access.2024.3392621)
* **Crossref check:** title "Spacer Dielectric Analysis of Multi-Channel Nanosheet FET for Nanoscale Applications"; venue IEEE Access; year 2024; first author Asisa Kumar Panigrahy; type `journal-article`. Matches.
* **Author list:** Asisa Kumar Panigrahy, Veera Venkata Sai Amudalapalli, Depuru Shobha Rani, Muralidhar Nayak Bhukya, Hima Bindu Valiveti, V. Bharath Sreenivasulu, Raghunandan Swain
* **Venue / Year:** IEEE Access, 2024
* **Verbatim quote:** *"DC parameters of the proposed device are established: ION to IOFF ratio of approximately 10^5, DIBL of approximately 14 mV/V, sub-threshold swing (SS) of approximately 62 mV/dec, and low threshold voltage (Vth) of 0.38 V."*

### 3. Benchmarking Multi-Bridge-Channel (MBC) Nanosheets vs FinFETs `[VERIFIED]`
* **Claim:** At equal Weff, MBC GAA nanosheet FETs beat single-channel FinFETs on Ion, Ion/Ioff, SS and DIBL.
* **Numeric value:** propagation delay reduced 31% FinFET→NWFET, 12% NWFET→NSFET; ring-oscillator frequency +56%.
* **DOI:** [10.1109/access.2024.3350779](https://doi.org/10.1109/access.2024.3350779)
* **Crossref check:** title "Benchmarking of Multi-Bridge-Channel FETs Toward Analog and Mixed-Mode Circuit Applications"; venue IEEE Access; year 2024; first author Vakkalakula Bharath Sreenivasulu (agy listed "V. Bharath Sreenivasulu" — same person, name-order formatting difference only, not a mismatch); type `journal-article`. Matches.
* **Author list:** V. Bharath Sreenivasulu, N. Aruna Kumari, Asisa Kumar Panigrahy, Lokesh Vakkalakula, Jawar Singh, Shiv Govind Singh
* **Venue / Year:** IEEE Access, 2024
* **Verbatim quote:** *"Compared to the SC FinFET the MBC GAA NWFET and NSFET exhibits higher ON-current (ION), switching ratio (ION/IOFF), lower subthreshold-swing (SS) and drain-induced barrier lowering (DIBL) at equal Weff."*

---

## PART 3 — The Intersection: Ferroelectric Gate-All-Around / Nanosheet FETs

**Executed search terms (as reported by agy):** `ferroelectric nanosheet FET`, `FeFET nanosheet`, `GAA FeFET`, `gate-all-around ferroelectric memory`, `nanosheet ferroelectric NVM`, `ferroelectric vertical nanowire FET`, `ferroelectric gate-all-around FET synapse`, `ferroelectric GAAFET synapse`, `nanosheet ferroelectric synapse`.

### Work 1: Stacked GeSi Nanosheet FeFET, first demonstration `[VERIFIED]`
* **Claim:** Stacked two-nanosheet GAA Ge0.98Si0.02 FeFETs with HZO, 1.8 V memory window at 2 V write, endurance >10^11 cycles.
* **DOI:** [10.23919/vlsitechnologyandcir57934.2023.10185284](https://doi.org/10.23919/vlsitechnologyandcir57934.2023.10185284)
* **Crossref check:** title "First Stacked Nanosheet FeFET Featuring Memory Window of 1.8V at Record Low Write Voltage of 2V and Endurance >1E11 Cycles"; venue "2023 IEEE Symposium on VLSI Technology and Circuits"; year 2023; first author Yu-Rui Chen; type `proceedings-article`. Title independently restates the same 1.8 V / 2 V / >10^11 numbers — strong corroboration beyond metadata match.
* **Author list:** Yu-Rui Chen, Yi-Chun Liu, Zefu Zhao, Wan-Hsuan Hsieh, J. H. Lee, Chien-Te Tu, Bo-Wei Huang, Jer-Fu Wang, Shee-Jier Chueh, Yifan Xing, GuanHua Chen, Hung-Chun Chou, Dong Soo Woo, M. H. Lee, C. W. Liu
* **Venue / Year:** VLSI Symposium, 2023
* **Verbatim quote:** *"The large memory window of 1.8 V at the low write voltage of 2 V is achieved by stacked two nanosheet (NS) gate-allaround (GAA) Ge0.98Si0.02FeFETs with the channel phosphorus concentration larger than 1E18 cm^-3, enabling the erase of GAA FeFET."*
* **Architecture check (Part 3's critical question):** GAA nanosheet, ferroelectric HZO gate stack. This is not a near-miss — it is a direct hit on the query.

### Work 2: Interfacial-Layer-Free GeSi Nanosheet FeFET `[VERIFIED]`
* **Claim:** Interfacial-layer-free stacked two-nanosheet GAA Ge0.95Si0.05 FeFETs, 1.8 V MW at 2 V write, endurance >10^11 cycles.
* **DOI:** [10.1109/ted.2024.3356444](https://doi.org/10.1109/ted.2024.3356444)
* **Crossref check:** title "Interfacial-Layer-Free Ge0.95Si0.05 Nanosheet FeFETs"; venue IEEE Transactions on Electron Devices; year 2024; first author Wan-Hsuan Hsieh; type `journal-article`. Matches; journal follow-on to Work 1 (same NTU/C.W. Liu group).
* **Author list:** Wan-Hsuan Hsieh, Yu-Rui Chen, Yi-Chun Liu, Zefu Zhao, Jia-Yang Lee, Chien-Te Tu, Bo-Wei Huang, Jer-Fu Wang, M. H. Lee, C. W. Liu
* **Venue / Year:** IEEE TED, 2024
* **Verbatim quote:** *"The substantial memory window (MW) of 1.8 V is achieved by utilizing stacked two nanosheet (NS) gate-all-around (GAA) Ge0.95 Si0.05 ferroelectric field-effect transistors (FeFETs), employing a low write voltage of 2 V."*
* **Architecture check:** GAA nanosheet, ferroelectric HZO gate stack. Direct hit.

### Work 3: Stacked-Nanosheet FeFET *Synapse* Modeling `[VERIFIED]` — closest prior art to this thesis
* **Claim:** TCAD/Monte-Carlo (NLS model) study of stacked-nanosheet FeFET synapses under identical-pulse stimulation; more tiers improves Gmax/Gmin ratio and cycle-to-cycle variation immunity.
* **DOI (journal):** [10.1109/ojnano.2024.3399559](https://doi.org/10.1109/ojnano.2024.3399559)
* **DOI (conference precursor):** [10.23919/snw57900.2023.10183975](https://doi.org/10.23919/snw57900.2023.10183975)
* **Crossref check (journal):** title "Analysis and Design of FeFET Synapse With Stacked-Nanosheet Architecture Considering Cycle-to-Cycle Variations for Neuromorphic Applications"; venue IEEE Open Journal of Nanotechnology; year 2024; first author Heng Li Lin; type `journal-article`. Matches.
* **Crossref check (precursor):** title "Variability Analysis of Stacked-Nanosheet FeFET for MLC Memory and Synapse Applications"; venue "2023 Silicon Nanoelectronics Workshop (SNW)"; year 2023; first author Heng Li Lin; type `proceedings-article`. Matches agy's stated precursor.
* **Author list:** Heng Li Lin, Pin Su
* **Venue / Year:** IEEE OJ-NANO, 2024 (SNW 2023 precursor)
* **Verbatim quote:** *"Using extensive Monte-Carlo simulations with a nucleation-limited-switching (NLS) ferroelectric model and considering cycle-to-cycle variations, this paper constructs and analyzes the intrinsic conductance (GDS) response of stacked-nanosheet FeFET synapses with emphasis on the challenging identical-pulse stimulation."*
* **Architecture check:** GAA/stacked-nanosheet channel, ferroelectric (NLS-modeled HZO-type) gate stack, explicitly applied as a synapse. This is the single closest piece of prior art to the thesis's core device concept (GAA FeFET analog synapse) — it is a TCAD simulation study, not a fabricated device, but it directly anticipates the "GAA FeFET synapse" framing.

### Work 4: 3D GAA Nanosheet FeFET, double-HZO `[VERIFIED]`
* **Claim:** 3D GAA nanosheet FeFETs with stacked double-HZO + Al2O3/TiN interlayers to homogenize corner field; MW 0.9-1.3 V, V_P/E = ±3.5 V, endurance >10^11 cycles.
* **DOI:** [10.1109/vlsitechnologyandcir46769.2022.9830345](https://doi.org/10.1109/vlsitechnologyandcir46769.2022.9830345)
* **Crossref check:** title "Endurance > 10^11 Cycling of 3D GAA Nanosheet Ferroelectric FET with Stacked HfZrO2 to Homogenize Corner Field Toward Mitigate Dead Zone for High-Density eNVM"; venue "2022 IEEE Symposium on VLSI Technology and Circuits"; year 2022; first author C.-Y. Liao; type `proceedings-article`. Title independently restates endurance, GAA nanosheet, stacked HZO, corner-field homogenization — strong corroboration.
* **Author list:** C.-Y. Liao, K.-Y. Hsiang, Zaizhu Lou, Hsien-Cheng Tseng, Cheng-Hung Lin, Z.-X. Li, Fan-Chun Hsieh, C.-C. Wang, F.-S. Chang, W.-C. Ray, Yang-Yan Tseng, S. T. Chang, T.-C. Chen, M. H. Lee
* **Venue / Year:** VLSI Symposium, 2022
* **Verbatim quote:** *"After 10^11 high endurance cycles with memory window (MW) =0.9 V is achieved for the 3D gate-all-around (GAA) nanosheet (NS) ferroelectric field-effect transistor (FeFET) based on double-HZO; the aim is to homogenize the corner field and mitigate dead zones."*
* **Architecture check:** GAA nanosheet, ferroelectric HZO. Direct hit — and this is the same "Liao" calibration lineage referenced elsewhere in this project's own memory notes (Liao calibration status), worth cross-checking for overlap.

### Work 5: Stacked GAA Nanowire FeFET, sub-5-nm HZO `[VERIFIED]` — architecture variant, not nanosheet
* **Claim:** Double-layer stacked GAA nanowire FeFET, sub-5-nm HZO, internal metal gate (IMG); Ion/Ioff >10^7, SSmin = 49.3 mV/dec.
* **DOI:** [10.1109/jeds.2021.3056438](https://doi.org/10.1109/jeds.2021.3056438)
* **Crossref check:** title "Ultrathin Sub-5-nm Hf1-xZrxO2 for a Stacked Gate-all-Around Nanowire Ferroelectric FET With Internal Metal Gate"; venue IEEE Journal of the Electron Devices Society; year 2021; first author Shen-Yang Lee; type `journal-article`. Matches.
* **Author list:** Shen-Yang Lee, Chia-Chin Lee, Yi-Shan Kuo, Shouwei Li, Tien-Sheng Chao
* **Venue / Year:** IEEE JEDS, 2021
* **Verbatim quote:** *"This results in a lower subthreshold (sub-V_TH) swing (S.S._min=49.3mV/decade) with a wide range (10^3) of drain current compared to that without an IMG."*
* **Architecture check:** genuine GAA (channel wrapped on all sides) with ferroelectric HZO — but the channel is a **nanowire**, not a **nanosheet**. Report as a GAA-ferroelectric hit, cross-section variant flagged.

### Work 6: Vertical III-V Nanowire GAA FeFET on Si `[VERIFIED]` — architecture + material variant
* **Claim:** Ferroelectric Hf1-xZrxO2 integrated onto vertical III-V nanowire GAA FETs fabricated on silicon.
* **DOI:** [10.1109/led.2022.3171597](https://doi.org/10.1109/led.2022.3171597)
* **Crossref check:** title "Integration of Ferroelectric HfxZr1-xO2 on Vertical III-V Nanowire Gate-All-Around FETs on Silicon"; venue IEEE Electron Device Letters; year 2022; first author Anton E. O. Persson; type `journal-article`. Matches; title itself is the verbatim quote agy supplied.
* **Author list:** Anton E. O. Persson, Zhongyunshen Zhu, Robin Athle, Lars-Erik Wernersson
* **Venue / Year:** IEEE EDL, 2022
* **Verbatim quote:** *"Integration of Ferroelectric Hf_xZr_1-xO_2 on Vertical III-V Nanowire Gate-All-Around FETs on Silicon."*
* **Architecture check:** genuine GAA (vertical nanowire, wrapped channel) with ferroelectric HZO — channel material is III-V (not Si), and geometry is vertical nanowire (not planar nanosheet). Flagged as a material/geometry variant, still a direct GAA-ferroelectric hit.

---

## The gap claim

**Answer: NO — prior ferroelectric gate-all-around / nanosheet FET work already exists.** This is not a near-miss situation; six peer-reviewed, DOI-verified publications (2021-2024) combine a GAA or nanowire-GAA channel with a ferroelectric HfO2-family (HZO) gate stack, and one of them (Work 3, Lin & Su, IEEE OJ-NANO 2024 / SNW 2023 precursor) is a TCAD/Monte-Carlo simulation of a **stacked-nanosheet FeFET synapse** under identical-pulse stimulation — i.e., essentially the same device concept and application (GAA FeFET as analog synapse) that this thesis is built around.

**Evidence:**
- Experimental GAA-nanosheet FeFET memory devices: Chen et al. (VLSI 2023), Hsieh et al. (TED 2024), Liao et al. (VLSI 2022) — all fabricated, all HZO-based, all reporting >10^11 endurance and sub-2-V memory windows.
- Experimental GAA-nanowire (not nanosheet) FeFET devices: Lee et al. (JEDS 2021, Si-compatible sub-5-nm HZO), Persson et al. (EDL 2022, III-V vertical nanowire on Si).
- Simulation-based GAA-nanosheet FeFET **synapse** work: Lin & Su (OJ-NANO 2024 / SNW 2023) — directly targets neuromorphic/synapse application with cycle-to-cycle variation analysis under identical-pulse programming, the same programming scheme category discussed in Part 1.

**Search terms behind this conclusion (as reported by agy):** `ferroelectric nanosheet FET`, `FeFET nanosheet`, `GAA FeFET`, `gate-all-around ferroelectric memory`, `nanosheet ferroelectric NVM`, `ferroelectric vertical nanowire FET`, `ferroelectric gate-all-around FET synapse`, `ferroelectric GAAFET synapse`, `nanosheet ferroelectric synapse`, cross-checked against IEDM and VLSI Symposium proceedings 2022-2026.

**Near-misses / variants worth distinguishing in the thesis's positioning, rather than treating as identical prior art:**
- Works 1, 2, 4 are **Ge/GeSi channel** nanosheet FeFETs (not Si channel) — a materials variant from a Si-channel GAA-FeFET device.
- Works 5, 6 are **nanowire** (not nanosheet) GAA cross-sections — a geometry variant.
- Work 3 is a **simulation-only** synapse study (NLS model, Monte-Carlo), not a fabricated device, and does not report LIF/spiking or single-shot-fire behavior (this project's memory notes record that the device only supports single-shot LIF, not multi-cycle — that distinction is not addressed by Work 3 and may be a genuine point of departure).

**Practical implication:** any claim of novelty in this thesis needs to be staked on something more specific than "first ferroelectric GAA device" or "first GAA FeFET synapse" — both of those, at the architecture level, have prior art as of 2021-2024. The differentiator would need to be the specific device parameters (T_ox/T_si/T_fe), the calibration-to-measured-data approach, the Si-channel (vs Ge/GeSi) implementation, the LIF/spiking neuromorphic application specifics, or the SNN-level system integration — not the bare fact of combining ferroelectric HZO with a GAA/nanosheet channel.

---

## Do not cite

- **Part 1, item 4 (Programming Schemes & Closed-Loop Write-Verify Impact):** agy's own cross-source synthesis, no single DOI or verbatim quote attached to the specific numeric claims (16-32 vs 64-128 levels, fJ range, alpha ~2-4). Individual sub-claims may be true but are not independently sourced here — treat as unverified narrative, not a citable number.
- **Part 2, item 1 (Industry transition FinFET → GAA):** general background narrative (Samsung MBCFET, TSMC N2, Intel 20A RibbonFET) with no DOI or verbatim quote in agy's output. Standard/uncontroversial but unsourced in this pass — do not cite without finding a primary source.
- No DOI in this batch resolved as `posted-content`/arXiv, and no DOI 404'd. All 12 DOIs (11 primary + 1 conference precursor) are peer-reviewed IEEE or Nature Communications publications with title/venue/year/author matching agy's citation. Nothing is flagged MISMATCH.

---

## BibTeX (VERIFIED entries only, crossref-confirmed)

```bibtex
@inproceedings{Jerry2017_IEDM,
  author    = {Jerry, Matthew and Chen, Pai-Yu and Zhang, Jianchi and Sharma, Pankaj and Ni, Kai and Yu, Shimeng and Datta, Suman},
  title     = {Ferroelectric FET analog synapse for acceleration of deep neural network training},
  booktitle = {2017 IEEE International Electron Devices Meeting (IEDM)},
  year      = {2017},
  doi       = {10.1109/IEDM.2017.8268338},
}

@article{Aabrar2022_TED,
  author  = {Aabrar, Khandker Akif and Kirtania, Sharadindu Gopal and Liang, Fu-Xiang and G{\'o}mez, Jorge and San Jose, Matthew and Luo, Yandong and Ye, Huacheng and Dutta, Sourav and Ravikumar, Priyankka Gundlapudi and Ravindran, Prasanna Venkatesan and Khan, Asif Islam and Yu, Shimeng and Datta, Suman},
  title   = {BEOL-Compatible Superlattice FEFET Analog Synapse With Improved Linearity and Symmetry of Weight Update},
  journal = {IEEE Transactions on Electron Devices},
  year    = {2022},
  doi     = {10.1109/TED.2022.3142239},
}

@article{Soliman2023_NatComm,
  author  = {Soliman, Taha and Chatterjee, Swetaki and Laleni, Nellie and M{\"u}ller, Franz and Kirchner, Tobias and Wehn, Norbert and K{\"a}mpfe, Thomas and Chauhan, Yogesh Singh and Amrouch, Hussam},
  title   = {First demonstration of in-memory computing crossbar using multi-level Cell FeFET},
  journal = {Nature Communications},
  year    = {2023},
  doi     = {10.1038/s41467-023-42110-y},
}

@article{Panigrahy2024_IEEEAccess,
  author  = {Panigrahy, Asisa Kumar and Amudalapalli, Veera Venkata Sai and Rani, Depuru Shobha and Bhukya, Muralidhar Nayak and Valiveti, Hima Bindu and Sreenivasulu, V. Bharath and Swain, Raghunandan},
  title   = {Spacer Dielectric Analysis of Multi-Channel Nanosheet FET for Nanoscale Applications},
  journal = {IEEE Access},
  year    = {2024},
  doi     = {10.1109/ACCESS.2024.3392621},
}

@article{Sreenivasulu2024_IEEEAccess,
  author  = {Sreenivasulu, V. Bharath and Kumari, N. Aruna and Panigrahy, Asisa Kumar and Vakkalakula, Lokesh and Singh, Jawar and Singh, Shiv Govind},
  title   = {Benchmarking of Multi-Bridge-Channel FETs Toward Analog and Mixed-Mode Circuit Applications},
  journal = {IEEE Access},
  year    = {2024},
  doi     = {10.1109/ACCESS.2024.3350779},
}

@inproceedings{Chen2023_VLSI,
  author    = {Chen, Yu-Rui and Liu, Yi-Chun and Zhao, Zefu and Hsieh, Wan-Hsuan and Lee, J. H. and Tu, Chien-Te and Huang, Bo-Wei and Wang, Jer-Fu and Chueh, Shee-Jier and Xing, Yifan and Chen, GuanHua and Chou, Hung-Chun and Woo, Dong Soo and Lee, M. H. and Liu, C. W.},
  title     = {First Stacked Nanosheet FeFET Featuring Memory Window of 1.8V at Record Low Write Voltage of 2V and Endurance {\textgreater}1E11 Cycles},
  booktitle = {2023 IEEE Symposium on VLSI Technology and Circuits},
  year      = {2023},
  doi       = {10.23919/VLSITechnologyandCir57934.2023.10185284},
}

@article{Hsieh2024_TED,
  author  = {Hsieh, Wan-Hsuan and Chen, Yu-Rui and Liu, Yi-Chun and Zhao, Zefu and Lee, Jia-Yang and Tu, Chien-Te and Huang, Bo-Wei and Wang, Jer-Fu and Lee, M. H. and Liu, C. W.},
  title   = {Interfacial-Layer-Free {Ge0.95Si0.05} Nanosheet FeFETs},
  journal = {IEEE Transactions on Electron Devices},
  year    = {2024},
  doi     = {10.1109/TED.2024.3356444},
}

@article{Lin2024_OJNano,
  author  = {Lin, Heng Li and Su, Pin},
  title   = {Analysis and Design of FeFET Synapse With Stacked-Nanosheet Architecture Considering Cycle-to-Cycle Variations for Neuromorphic Applications},
  journal = {IEEE Open Journal of Nanotechnology},
  year    = {2024},
  doi     = {10.1109/OJNANO.2024.3399559},
}

@inproceedings{Lin2023_SNW,
  author    = {Lin, Heng Li and Su, Pin},
  title     = {Variability Analysis of Stacked-Nanosheet FeFET for MLC Memory and Synapse Applications},
  booktitle = {2023 Silicon Nanoelectronics Workshop (SNW)},
  year      = {2023},
  doi       = {10.23919/SNW57900.2023.10183975},
}

@inproceedings{Liao2022_VLSI,
  author    = {Liao, C.-Y. and Hsiang, K.-Y. and Lou, Zaizhu and Tseng, Hsien-Cheng and Lin, Cheng-Hung and Li, Z.-X. and Hsieh, Fan-Chun and Wang, C.-C. and Chang, F.-S. and Ray, W.-C. and Tseng, Yang-Yan and Chang, S. T. and Chen, T.-C. and Lee, M. H.},
  title     = {Endurance {\textgreater} 10\textsuperscript{11} Cycling of 3D GAA Nanosheet Ferroelectric FET with Stacked {HfZrO2} to Homogenize Corner Field Toward Mitigate Dead Zone for High-Density eNVM},
  booktitle = {2022 IEEE Symposium on VLSI Technology and Circuits},
  year      = {2022},
  doi       = {10.1109/VLSITechnologyandCir46769.2022.9830345},
}

@article{Lee2021_JEDS,
  author  = {Lee, Shen-Yang and Lee, Chia-Chin and Kuo, Yi-Shan and Li, Shouwei and Chao, Tien-Sheng},
  title   = {Ultrathin Sub-5-nm {Hf1-xZrxO2} for a Stacked Gate-all-Around Nanowire Ferroelectric FET With Internal Metal Gate},
  journal = {IEEE Journal of the Electron Devices Society},
  year    = {2021},
  doi     = {10.1109/JEDS.2021.3056438},
}

@article{Persson2022_EDL,
  author  = {Persson, Anton E. O. and Zhu, Zhongyunshen and Athle, Robin and Wernersson, Lars-Erik},
  title   = {Integration of Ferroelectric {HfxZr1-xO2} on Vertical III-V Nanowire Gate-All-Around FETs on Silicon},
  journal = {IEEE Electron Device Letters},
  year    = {2022},
  doi     = {10.1109/LED.2022.3171597},
}
```

---

## Closest prior work, in detail

Follow-up targeted pass (2026-08-02), not a broad agy search. IEEE Xplore's document pages return no scrapeable content to WebFetch (JS-rendered SPA, empty body) — every fact below comes from the Semantic Scholar Graph API (api.semanticscholar.org/graph/v1/paper/DOI:DOI?fields=abstract), fetched with a strict "output the raw abstract field verbatim, no paraphrase" prompt, cross-checked against Crossref metadata already verified in the section above. **Everything in this section is abstract-only** — none of these five papers are open-access, so nothing beyond the abstract was reachable. Anything the abstract does not mention is reported as "abstract silent on X," which means unknown, not absent — the fact could easily be in the body.

One naming discrepancy to flag: Crossref gives the OJ-NANO/SNW first author as **Heng Li Lin**; Semantic Scholar gives the same person (same DOIs, same co-author Pin Su) as **Hengzhi Lin**. Same individual, two different Latin transliterations of what is almost certainly a Chinese given name — not a mismatch, just be consistent about which spelling this thesis uses.

### 1. Lin & Su, IEEE OJ-NANO 2024 -- 10.1109/ojnano.2024.3399559 [ABSTRACT-ONLY]

**Verbatim abstract (Semantic Scholar, raw field, unedited):**
*"Using extensive Monte-Carlo simulations with a nucleation-limited-switching (NLS) ferroelectric model and considering cycle-to-cycle variations, this paper constructs and analyzes the intrinsic conductance (GDS) response of stacked-nanosheet FeFET synapses with emphasis on the challenging identical-pulse stimulation. Our study indicates that the interlayer oxide thickness of the FeFET and the saturation polarization of the ferroelectric are crucial to the linearity and symmetry of the intrinsic GDS response. With the stacked-nanosheet architecture, the maximum-to-minimum conductance ratio in the GDS response can be boosted by increasing the number of channel tiers without footprint penalty. For a stacked-nanosheet FeFET synapse with an area ratio effect, the GDS response can be further engineered by varying the tier number. In addition, the immunity to cycle-to-cycle variations and the noise margin for each state in the GDS response can also be improved by increasing the number of tiers. Our study may provide insights for future FeFET synapse design for analog computing."*

Answering the coordinator's specific questions, from this abstract alone:
- **Device / dimensions:** stacked-nanosheet FeFET, tier count is a swept variable. Channel material, exact nanosheet width/thickness, ferroelectric material composition beyond "ferroelectric" (presumably HZO given the SNW precursor and the group's prior nanosheet-FeFET work, but the abstract does not name it), and ferroelectric thickness are **not stated in the abstract**.
- **Simulation framework:** "extensive Monte-Carlo simulations with a nucleation-limited-switching (NLS) ferroelectric model." No TCAD tool name (Sentaurus, etc.) is given in the abstract.
- **Calibration against measured data:** **abstract silent.** No statement that the NLS model was fit to any specific measured dataset.
- **Synaptic results / level count:** the abstract discusses conductance-ratio (Gmax/Gmin), linearity and symmetry of the intrinsic GDS response, and noise margin per state -- **no specific conductance-level count (e.g. "N levels" or "N bits") appears in the abstract.**
- **Programming scheme:** explicitly **identical-pulse stimulation** ("with emphasis on the challenging identical-pulse stimulation"). No mention of write-verify, ISPP, or amplitude/width modulation.
- **Cycle-to-cycle variation sourcing:** Monte-Carlo over the NLS model's stochastic nucleation process (simulated variation from the physics model itself, not measured-device repeats). Conclusion: increasing tier count improves immunity to this variation and improves per-state noise margin.
- **Neural network deployment:** **abstract silent** -- no dataset, no task, no accuracy figure, no mention of spiking vs. rate-coded network. The paper's own framing is device/circuit-level ("GDS response," "insights for future FeFET synapse design"), not a deployed classifier.
- **Energy figure:** **abstract silent** -- no energy-per-pulse or energy-per-update number appears.
- **Level placement vs. level count:** the abstract's closest analogue is "noise margin for each state," a per-state distinguishability measure -- adjacent to but not the same claim as this thesis's placement-vs-count result, and it is never connected to a downstream classifier's accuracy (because no classifier is deployed).

### 2. Lin & Su, SNW 2023 conference precursor -- 10.23919/snw57900.2023.10183975 [ABSTRACT-ONLY]

**Verbatim abstract (Semantic Scholar, raw field, unedited):**
*"This work investigates the variability of Stacked-Nanosheet FeFET for scaled NVM, MLC and synapse applications considering the random ferroelectric-dielectric phase distribution with TCAD atomistic simulations. Our study indicates that, by increasing the number of tiers, the variability in threshold voltage of each state, memory window and the synapse conductance response of the Stacked-Nanosheet based ferroelectric devices can all be mitigated without footprint penalty."*

- **Simulation framework:** "TCAD atomistic simulations" of "random ferroelectric-dielectric phase distribution" -- a *different* variability model than the journal paper's NLS Monte-Carlo (grain-level phase-distribution randomness vs. nucleation-switching stochasticity). Consistent with the journal paper being an extension, not a duplicate.
- **Calibration:** abstract silent.
- **Applications named:** scaled NVM, MLC (multi-level cell), and synapse -- broader framing than the 2024 journal paper's synapse-only focus.
- **Metrics improved by tier count:** Vth variability per state, memory window variability, and synapse conductance-response variability -- all reduced with more tiers, no footprint penalty.
- **No level count, no NN deployment, no energy figure** in this abstract either.

### 3. Chen et al., IEEE VLSI Symposium 2023 -- 10.23919/vlsitechnologyandcir57934.2023.10185284 [ABSTRACT-ONLY]

**Verbatim abstract (Semantic Scholar):**
*"This work demonstrates a dual-nanosheet ferroelectric field-effect transistor configuration achieving 1.8V memory window at low 2V write voltage through Ge0.98Si0.02 channels with high phosphorus doping. The stacked architecture reduces device variability and doubles read current while maintaining data retention exceeding 10,000 seconds and endurance surpassing 100 billion cycles. Processing temperature remains modest at 400 degrees C, positioning the technology for advanced node compatibility."*

- **Channel material:** Ge0.98Si0.02 (germanium-silicon alloy, not silicon).
- **Nanosheet dimensions:** not stated in the abstract (device count is "dual-nanosheet," i.e. two stacked tiers; width/thickness not given).
- **HZO thickness:** not stated in the abstract.
- **Memory window / endurance / retention:** MW = 1.8 V at 2 V write; retention >10,000 s; endurance >1e11 cycles (100 billion); thermal budget 400 degrees C.
- **Analog/multilevel operation:** **the abstract reports only binary NVM-style figures of merit** -- memory window, retention, endurance, read-current doubling. No conductance-level count, no linearity/symmetry curve, no synapse or analog-weight language appears anywhere in the abstract. Read as: this is presented as a binary (2-state) memory demonstration, not a multilevel/analog synapse demonstration -- though the body could still contain a multilevel measurement not surfaced in the abstract.

### 4. Hsieh et al., IEEE TED 2024 -- 10.1109/ted.2024.3356444 [ABSTRACT-ONLY]

**Verbatim abstract (Semantic Scholar):**
*"The researchers demonstrated a substantial memory window (MW) of 1.8 V using stacked dual-nanosheet gate-all-around ferroelectric transistor architecture. By eliminating the interfacial layer and incorporating phosphorus doping at approximately 1E18 cm-3, they achieved operation at just 2 volts. Key accomplishments include data retention exceeding 10,000 seconds (extrapolated to a decade), endurance surpassing 1E11 cycles, and a minimal thermal budget of 400 degrees C. The dual-nanosheet configuration provides reduced device variation and doubled read current compared to single-channel alternatives."*

- **Channel material:** Ge0.95Si0.05 (from the title/earlier verbatim quote already in this file; abstract itself doesn't restate the composition number but the title does).
- **Nanosheet dimensions / HZO thickness:** not stated in the abstract.
- **Memory window / endurance / retention:** MW = 1.8 V at 2 V write; retention >10,000 s (extrapolated to a decade); endurance >1e11 cycles; 400 degrees C thermal budget. Same figures as Chen 2023 -- this is the journal follow-on to the same device family with the interfacial layer removed.
- **Analog/multilevel operation:** same read as Chen 2023 -- **abstract reports only binary memory-window/retention/endurance metrics, no level count, no synapse/analog framing.**

### 5. Liao et al., IEEE VLSI Symposium 2022 -- 10.1109/vlsitechnologyandcir46769.2022.9830345 [ABSTRACT-ONLY]

**Verbatim abstract (Semantic Scholar):**
*"After 1011 high endurance cycles with memory window (MW) =0.9 V is achieved for the 3D gate-all-around nanosheet ferroelectric transistor using double-HZO, researchers focused on field uniformity and eliminating dead zones. An interlayer of aluminum oxide or titanium nitride in the double-HZO structure produced either improved memory window or reduced access voltage. The resulting device showed low VP/E = +/-3.5 V (+/-2.3 MV/cm), large MW = 1.3 V, >10^11 robust endurance cycles, with data retention exceeding 20,000 seconds, enabling scaling of embedded nonvolatile memory for next-generation applications."*

- **Channel material:** not stated in this abstract (the Liao group's other work is Si-based eNVM; not confirmed here).
- **Nanosheet dimensions:** not stated.
- **HZO configuration:** double-HZO stack with an Al2O3 or TiN interlayer.
- **Memory window / endurance / retention / voltage:** MW = 0.9-1.3 V depending on interlayer choice; V_P/E = +/-3.5 V (+/-2.3 MV/cm); endurance >1e11 cycles; retention >20,000 s.
- **Analog/multilevel operation:** **abstract frames this explicitly as embedded non-volatile memory (eNVM)** -- "enabling scaling of embedded nonvolatile memory for next-generation applications." No synapse, no analog level, no linearity/symmetry language. Binary/digital memory framing only, same caveat as above (body not accessible).

### What is left that this thesis does

Cross-checked against sec_device_results.tex, sec_network_results.tex, and sec_discussion.tex. Everything below is checked against what the abstracts above actually claim, not against what a GAA-FeFET-synapse paper could plausibly claim -- where the prior work's abstract already covers something, it is marked as such rather than listed here.

1. **Calibration to a real measured device.** This thesis's transfer characteristic, memory window, threshold voltages, subthreshold slope and turn-on shape are fit against an actual published measurement of a comparable GAA FeFET (Fig. 2, RMS residual 0.30-0.48 decades). None of the five prior papers' abstracts state that their ferroelectric model (NLS Monte-Carlo, atomistic phase-distribution, or the three experimental papers' as-fabricated devices) was calibrated to independent measured I-V data in the way this device's deck is calibrated -- the three experimental papers *are* the measurement, and Lin & Su's abstracts never mention a calibration target.
2. **The distinction between the ferroelectric material's own P-E loop and what the gate stack actually delivers.** Fig. 3's standalone MFM capacitor vs. deep-minor-loop-through-the-stack correction (a +/-4 V gate sweep reaches only about 55% of F_c) is a stack-electrostatics point specific to this device and its P_r/F_c calibration targets; nothing in any of the five abstracts addresses this.
3. **A measured write-energy budget from an actual pulse train**, not a modeled one: 8.2 aJ/pulse average, 11.0 aJ peak, 0.123 fJ for a full 15-level write, taken from the solver's gate-charge trace. No energy figure of any kind appears in any of the five abstracts, including Lin & Su's simulation papers.
4. **Cycle-to-cycle noise from repeated measurement of one real pulse train** (eleven repeats of the same fifteen-pulse train), yielding an explicit level count under a stated separability criterion: eight levels open-loop, about sixteen under write-verify. Lin & Su's variation numbers come from Monte-Carlo sampling of a stochastic switching model (OJ-NANO) or atomistic phase-distribution sampling (SNW) -- a simulated ensemble, not repeat measurements of one device -- and neither abstract states a level count at all.
5. **Write-verify vs. open-loop as an explicit, quantified level-count trade** (8 vs. about 16 levels, tied to a stated protocol), plus the finding that write-verify is required anyway once device-to-device corner variability is considered (uncalibrated accuracy collapses to 0.243). Lin & Su's abstracts mention neither write-verify/program-and-verify nor ISPP; their stated programming scheme is identical-pulse stimulation only.
6. **Level placement, not level count, as the figure of merit that predicts deployed accuracy** -- demonstrated by sweeping placement at fixed level count (accuracy swings from 0.336 to 0.804 at eight levels depending on where the levels sit) and by showing three different distinguishability-style metrics (corner-ensemble overlap, post-gain-trim overlap, three-sigma separability) all fail to predict accuracy while worst-level misplacement does (Spearman -0.85). This is the sharpest genuine gap: Lin & Su's OJ-NANO abstract reports an adjacent but different quantity -- "noise margin for each state" improving with tier count -- but never connects that to a downstream classifier's accuracy, because **no neural network is deployed in either Lin & Su paper's abstract.**
7. **A trained network actually deployed onto the device's measured conductance ladder**: a spiking recurrent classifier on single-lead ECG beats, post-training-quantized from one fixed checkpoint, reaching 0.8304 accuracy (vs. 0.8571 full precision), plus robustness checks across temperature and retention stress. Nothing resembling this appears in any of the five abstracts -- Lin & Su frame their contribution as device/circuit-level "insights for future FeFET synapse design," not a deployed model with a task, dataset or accuracy number.
8. **Corner-device variability analysis isolating which process axis controls level placement** (20 corners across interface-trap density, fixed interface charge, ferroelectric thickness), concluding fixed interface charge dominates (1.31 decades) over ferroelectric thickness (0.07 decades) -- the opposite of the expected ordering. The SNW precursor's variability source is grain-level random ferroelectric-dielectric phase distribution, and its lever is tier count, not interface-charge vs. thickness decomposition; this specific attribution is not in either Lin & Su abstract.
9. **Integrate-and-fire / neuron behavior**, not just synapse (weight) behavior: the device driven as an accumulating state variable that crosses a fixed threshold and fires, with pulse amplitude shown to set the integration rate (Fig. 7), explicitly flagged as a single-shot event given the depolarization time constant used. All five prior papers' abstracts describe FeFET **synapse or memory** behavior only; none describe integrate-and-fire, spiking-neuron, or LIF-type operation of the device itself. This is a functionally different claim (neuron dynamics) from anything in the prior work located here.
10. **Full system energy accounting including peripheral ADC cost**, showing the assumed 1 pJ/conversion readout overhead is 342x the core compute (183 nJ vs. 535.8 pJ per heartbeat) -- a system-level point about where the energy actually goes. No energy discussion of any kind is in the five abstracts.
11. **A planar ablation of the identical stack** (same gate stack, bottom gate removed) to isolate what the nanosheet/GAA geometry itself buys over a planar device on the axes a synapse is judged by (level count, program voltage, subthreshold slope) rather than the raw memory window. None of the five prior papers run this kind of controlled ablation against their own device.
12. **A benchmark against a fifteen-paper literature survey** of ferroelectric analog memories on level count and per-pulse energy, with open markers for unconfirmed counts (literature_benchmark.csv) -- a positioning exercise, not present in any of the five papers reviewed here.

**One item that is NOT a clean gap and should be stated as such:** identical-pulse-train programming and its limitations (nonlinearity, level crowding near saturation) is explicitly the OJ-NANO paper's stated emphasis too ("with emphasis on the challenging identical-pulse stimulation"). This thesis's use of identical-pulse trains as the baseline programming scheme is not novel by itself -- the novelty is in what is measured from it (the real cycle-to-cycle repeat statistics, the placement-vs-count finding, and the downstream deployed-network result), not in choosing that programming scheme.
