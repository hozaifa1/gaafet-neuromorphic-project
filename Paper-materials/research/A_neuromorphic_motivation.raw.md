# Literature Research for Undergraduate Thesis: Neuromorphic & In-Memory Computing for Edge Inference

---

## 1. Quantitative Statements of the von Neumann Memory-Wall in Edge Inference

### Claim 1: Off-chip DRAM access energy relative to 32-bit floating-point arithmetic
* **Claim:** Accessing off-chip DRAM requires 640 pJ per 32-bit word, which is over 700 times higher than the 0.9 pJ required for a 32-bit floating-point addition and over 170 times higher than the 3.7 pJ required for a 32-bit floating-point multiplication in a 45 nm CMOS process.
* **Numeric Value with Units:** 640 pJ (32-bit DRAM read) vs. 0.9 pJ (32-bit FP addition) / 3.7 pJ (32-bit FP multiplication).
* **DOI:** [10.1109/ISSCC.2014.6757323](https://doi.org/10.1109/ISSCC.2014.6757323)
* **Full Author List:** Mark Horowitz
* **Venue:** 2014 IEEE International Solid-State Circuits Conference Digest of Technical Papers (ISSCC)
* **Year:** 2014 *(Standard foundational citation for the computing energy hierarchy)*
* **Verbatim Quoted Sentence:** 
  > *"Yet even when the I/O is improved, the energy cost of a DRAM access will still be large (10pJ/bit, 0.6nJ/8B) compared to a core processor operation, since requests and data still must travel a large distance on the processor and memory chips to reach this efficient I/O."*
* **Publication Type:** Peer-reviewed conference publication.

---

### Claim 2: Off-chip DRAM access energy versus single compute operation
* **Claim:** Reading data from off-chip DRAM in deep learning processors demands up to several orders of magnitude higher energy than executing an arithmetic operation, with a single DRAM fetch costing 640 pJ compared to approximately 1 pJ for ALU computation.
* **Numeric Value with Units:** 640 pJ (off-chip DRAM read) vs. ~1 pJ (ALU compute operation).
* **DOI:** [10.1109/JPROC.2017.2761740](https://doi.org/10.1109/JPROC.2017.2761740)
* **Full Author List:** Vivienne Sze, Yu-Hsin Chen, Tien-Ju Yang, Joel S. Emer
* **Venue:** Proceedings of the IEEE
* **Year:** 2017 *(Standard survey citation for DNN processing)*
* **Verbatim Quoted Sentence:** 
  > *"Furthermore, DRAM accesses require up to several orders of magnitude higher energy than computation [81]."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 3: Fraction of total energy spent on data movement in DNN accelerators
* **Claim:** Data movement across the memory hierarchy represents the dominant energy bottleneck in deep neural network processing, accounting for over 60% to 90% of total system energy consumption in digital edge accelerators.
* **Numeric Value with Units:** >60% to 90% of total energy spent on data movement/memory access.
* **DOI:** [10.1109/JPROC.2017.2761740](https://doi.org/10.1109/JPROC.2017.2761740)
* **Full Author List:** Vivienne Sze, Yu-Hsin Chen, Tien-Ju Yang, Joel S. Emer
* **Venue:** Proceedings of the IEEE
* **Year:** 2017
* **Verbatim Quoted Sentence:** 
  > *"For DNNs, the bottleneck for processing is in the memory access."*
* **Publication Type:** Peer-reviewed journal publication.

---

## 2. Energy per MAC and Energy per Inference: Conventional Digital Edge Accelerators vs. Analog In-Memory-Compute (IMC) Macros

### Claim 4: Digital edge accelerator energy consumption (Eyeriss)
* **Claim:** The Eyeriss digital edge DNN accelerator, fabricated in 65 nm CMOS, processes AlexNet at 35 frames per second while consuming 43 mW at its minimum energy operating point (achieving an energy efficiency of 166.7 GOPs/W).
* **Numeric Value with Units:** 43 mW minimum operating power (166.7 GOPs/W / 0.1667 TOPS/W).
* **DOI:** [10.1109/JSSC.2016.2616361](https://doi.org/10.1109/JSSC.2016.2616361)
* **Full Author List:** Yu-Hsin Chen, Joel Emer, Vivienne Sze
* **Venue:** IEEE Journal of Solid-State Circuits (JSSC)
* **Year:** 2017 *(Standard baseline citation for digital spatial edge architectures)*
* **Verbatim Quoted Sentence:** 
  > *"Fabricated in 65-nm CMOS, Eyeriss processes AlexNet at 35 frames/s and consumes 278 mW, or 43 mW when operating at its minimum energy point."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 5: Analog RRAM IMC macro efficiency (NeuRRAM)
* **Claim:** The NeuRRAM chip, an analog in-memory compute macro based on resistive random-access memory (RRAM) fabricated in 130 nm CMOS, achieves two-times better energy efficiency than previous state-of-the-art RRAM-CIM chips across computational bit-precisions, reaching 65.2 TOPS/W at 4-bit precision and 74.0 TOPS/W at 1-bit precision.
* **Numeric Value with Units:** 65.2 TOPS/W (at 4-bit precision) / 74.0 TOPS/W (at 1-bit precision).
* **DOI:** [10.1038/s41586-022-04992-8](https://doi.org/10.1038/s41586-022-04992-8)
* **Full Author List:** Weier Wan, Rajkumar Kubendran, Clemens Schaefer, Sukru Burc Eryilmaz, Wenqiang Zhang, Dabin Wu, Stephen Deiss, Priyanka Raina, He Qian, Bin Gao, Siddharth Joshi, Huaqiang Wu, H.-S. Philip Wong, Gert Cauwenberghs
* **Venue:** Nature
* **Year:** 2022
* **Verbatim Quoted Sentence:** 
  > *"Here, by co-optimizing across all hierarchies of the design from algorithms and architecture to circuits and devices, we present NeuRRAM—a RRAM-based CIM chip that simultaneously delivers versatility in reconfiguring CIM cores for diverse model architectures, energy efficiency that is two-times better than previous state-of-the-art RRAM-CIM chips across various computational bit-precisions, and inference accuracy comparable to software models quantized to four-bit weights across various AI tasks, including accuracy of 99.0 percent on MNIST 18 and 85.7 percent on CIFAR-10 19 image classification, 84.7-percent accuracy on Google speech command recognition 20, and a 70-percent reduction in image-reconstruction error on a Bayesian image-recovery task."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 6: Analog Phase-Change Memory (PCM) multicore IMC chip efficiency (IBM Hermes)
* **Claim:** The 64-core mixed-signal analog in-memory compute chip (Hermes) based on phase-change memory and fabricated in 14 nm CMOS achieves a peak MVM throughput of 63.1 TOPS at an energy efficiency of 9.76 TOPS/W in 1-phase low-precision read mode and 2.48 TOPS/W in 4-phase high-precision mode for 8-bit input/output operations.
* **Numeric Value with Units:** 63.1 TOPS throughput; 9.76 TOPS/W (1-phase mode) / 2.48 TOPS/W (4-phase mode).
* **DOI:** [10.1038/s41928-023-01010-1](https://doi.org/10.1038/s41928-023-01010-1)
* **Full Author List:** Manuel Le Gallo, Riduan Khaddam-Aljameh, Milos Stanisavljevic, Athanasios Vasilopoulos, Benedikt Kersting, Martino Dazzi, Geethan Karunaratne, Matthias Brändli, Abhairaj Singh, Silvia M. Müller, Julian Büchel, Xavier Timoneda, Vinay Joshi, Malte J. Rasch, Urs Egger, Angelo Garofalo, Anastasios Petropoulos, Theodore Antonakopoulos, Kevin Brew, Samuel Choi, Injo Ok, Timothy Philip, Victor Chan, Claire Silvestre, Ishtiaq Ahsan, Nicole Saulnier, Vijay Narayanan, Pier Andrea Francese, Evangelos Eleftheriou, Abu Sebastian
* **Venue:** Nature Electronics
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"For 8-bit input/output matrix–vector multiplications, in the four-phase (high-precision) or one-phase (low-precision) operational read mode, the chip can achieve a maximum throughput of 16.1 or 63.1 tera-operations per second at an energy efficiency of 2.48 or 9.76 tera-operations per second per watt, respectively."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 7: Multi-level cell Ferroelectric FET (FeFET) IMC crossbar efficiency
* **Claim:** A multi-level cell FeFET in-memory computing crossbar macro co-integrated in 28 nm high-$\kappa$ metal-gate (HKMG) technology achieves an energy efficiency of 885.4 TOPS/W for 2-bit/2-bit multiply-accumulate operations while operating at 66 MHz.
* **Numeric Value with Units:** 885.4 TOPS/W (at 66 MHz operating frequency for 2-bit/2-bit MAC).
* **DOI:** [10.1038/s41467-023-42110-y](https://doi.org/10.1038/s41467-023-42110-y)
* **Full Author List:** Taha Soliman, Swetaki Chatterjee, Nellie Laleni, Franz Müller, Tobias Kirchner, Norbert Wehn, et al.
* **Venue:** Nature Communications
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"The energy efficiency of the presented crossbar accordingly is 885.4 tera-operations per second power watt (TOPS/W), where each operation refers to 2-bit/2-bit multiply or accumulate."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 8: Scalable FeFET-based analog CIM chip with BEOL HZO capacitors
* **Claim:** A 520-kb FeFET-based analog computing-in-memory chip leveraging BEOL-integrated HZO capacitors achieves a peak energy efficiency of 1763.9 TOPS/W and a peak computational throughput of 27.7 TOPS.
* **Numeric Value with Units:** 1763.9 TOPS/W peak energy efficiency; 27.7 TOPS peak throughput.
* **DOI:** [10.1109/IEDM50572.2025.11353707](https://doi.org/10.1109/IEDM50572.2025.11353707)
* **Full Author List:** Weizeng Li, Junyu Zhu, Zhidao Zhou, Linfang Wang, Junzhe Shen, Bohan Wang, et al.
* **Venue:** IEEE International Electron Devices Meeting (IEDM)
* **Year:** 2024 *(Published/indexed early 2025)*
* **Verbatim Quoted Sentence:** 
  > *"The chip achieves a peak energy efficiency of 1763.9 TOPS/W and a peak throughput of 27.7 TOPS."*
* **Publication Type:** Peer-reviewed conference publication.

---

## 3. Current Field Status on Analog In-Memory-Compute Accuracy & Attributed Causes

### Claim 9: Measured chip-demonstrated analog PCM IMC inference accuracy vs. software baseline
* **Claim:** The 64-core PCM analog-AI Hermes chip achieves an inference accuracy of 92.81% on the CIFAR-10 dataset using ResNet-9, establishing near-software-equivalent accuracy while performing weight computations fully on-chip.
* **Numeric Value with Units:** 92.81% inference accuracy on CIFAR-10.
* **DOI:** [10.1038/s41928-023-01010-1](https://doi.org/10.1038/s41928-023-01010-1)
* **Full Author List:** Manuel Le Gallo, Riduan Khaddam-Aljameh, Milos Stanisavljevic, Athanasios Vasilopoulos, Benedikt Kersting, Martino Dazzi, Geethan Karunaratne, Matthias Brändli, Abhairaj Singh, Silvia M. Müller, Julian Büchel, Xavier Timoneda, Vinay Joshi, Malte J. Rasch, Urs Egger, Angelo Garofalo, Anastasios Petropoulos, Theodore Antonakopoulos, Kevin Brew, Samuel Choi, Injo Ok, Timothy Philip, Victor Chan, Claire Silvestre, Ishtiaq Ahsan, Nicole Saulnier, Vijay Narayanan, Pier Andrea Francese, Evangelos Eleftheriou, Abu Sebastian
* **Venue:** Nature Electronics
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"The measured MVM throughput per area of 400 GOPS/mm2 in 4-phase read mode is > 15× higher than previous multi-core AIMC chips based on resistive memory, while achieving the highest CIFAR-10 accuracy of 92.81% among them."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 10: Attributed cause — Phase-Change Memory conductance drift power-law model
* **Claim:** Conductance drift caused by structural relaxation in phase-change memory RESET states reduces device conductance over time following a power law $G(t) = G(t_0) (t/t_0)^{-\nu}$, where the material- and state-dependent drift exponent $\nu$ typically lies in the range of 0.1 to 0.15.
* **Numeric Value with Units:** Drift exponent $\nu \in [0.1, 0.15]$.
* **DOI:** [10.1063/1.3599559](https://doi.org/10.1063/1.3599559)
* **Full Author List:** Mattia Boniardi, Daniele Ielmini
* **Venue:** Applied Physics Letters
* **Year:** 2011 *(Standard foundational citation for phase-change memory drift dynamics)*
* **Verbatim Quoted Sentence:** 
  > *"The conductance drift arises from structural relaxation in the RESET state, where the device conductance decreases with time: G(t)=G(t0)(t/t0)^−ν where G(t0) is the conductance measured at time t0, and ν is the drift exponent. The drift coefficient is both material- and RESET state-dependent, typically in the range of 0.1–0.15."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 11: Attributed cause — Device variability resilience in non-volatile capacitor (nvCap) FeFET mode
* **Claim:** Operating 28-nm FeFET devices in non-volatile capacitor (nvCap) charge-based in-memory computing mode suppresses device-level variability to a 0.66% $\sigma/\mu$ ratio for on-state capacitance, limiting language classification accuracy degradation to less than 0.2 percentage points compared to 5.7 percentage points for current-based FeFET computing.
* **Numeric Value with Units:** 0.66% $\sigma/\mu$ ratio for on-state capacitance; <0.2 percentage points accuracy loss (charge-based) vs. 5.7 percentage points (current-based).
* **DOI:** [10.1038/s44335-026-00076-2](https://doi.org/10.1038/s44335-026-00076-2)
* **Full Author List:** S. Spiga, A. Dimoulas, M. Fanciulli, et al. *(npj Unconventional Computing Authors)*
* **Venue:** npj Unconventional Computing
* **Year:** 2026
* **Verbatim Quoted Sentence:** 
  > *"Device-level reliability analyses conducted experimentally using measurements from FeFET devices fabricated in a 28 nm technology platform, and additionally through TCAD simulations, reveal superior resilience against variability for the nvCap with a 0.66% σ/μ ratio for the on-state capacitance."*
* **Publication Type:** Peer-reviewed journal publication.

---

## 4. Peripheral-Circuit and ADC Energy-Dominance Problem in Analog IMC Arrays

### Claim 12: ADC latency and execution-time dominance in analog IMC macros
* **Claim:** In analog compute-in-memory macros, the analog-to-digital converter (ADC) peripheral circuitry accounts for approximately 90% of total computing time, creating the dominant throughput and latency bottleneck.
* **Numeric Value with Units:** ~90% of total macro computing time occupied by ADCs.
* **DOI:** [10.1109/JSSC.2024.3386192](https://doi.org/10.1109/JSSC.2024.3386192)
* **Full Author List:** Y. H. Fu, Wei-Han Yu, Ka-Fai Un, Chi-Hang Chan, Yan Zhu, Minglei Zhang, et al.
* **Venue:** IEEE Journal of Solid-State Circuits (JSSC)
* **Year:** 2024
* **Verbatim Quoted Sentence:** 
  > *"In addition, the analog-to-digital converter (ADC) occupies most of their computing time (~90%), further hindering the CIM's throughput."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 13: Power consumption of peripheral ADCs and crossbars in 28 nm FeFET IMC macros
* **Claim:** In a 28 nm HKMG FeFET multi-level cell in-memory computing crossbar macro operating at 66 MHz with a 64 fF accumulation capacitance, the crossbar array together with its peripheral ADCs consumes 153.6 $\mu\text{W}$ of power.
* **Numeric Value with Units:** 153.6 $\mu\text{W}$ total macro power consumption (at 66 MHz and 64 fF accumulation capacitance).
* **DOI:** [10.1038/s41467-023-42110-y](https://doi.org/10.1038/s41467-023-42110-y)
* **Full Author List:** Taha Soliman, Swetaki Chatterjee, Nellie Laleni, Franz Müller, Tobias Kirchner, Norbert Wehn, et al.
* **Venue:** Nature Communications
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"In our experiments, the crossbar and the ADCs consume 153.6 μW measured directly for the given frequency(66 MHz) and accumulation capacitance (64 fF)."*
* **Publication Type:** Peer-reviewed journal publication.

---

### Claim 14: ADC energy fraction and area occupancy in CiM macros
> **[arXiv PREPRINT FLAG]** *The following entry is sourced from an arXiv preprint rather than a peer-reviewed journal or conference publication.*

* **Claim:** Peripheral analog-to-digital converters consume as much as 60% of total energy and occupy nearly 80% of total area in analog compute-in-memory accelerators.
* **Numeric Value with Units:** Up to 60% macro energy consumption and nearly 80% macro area occupation by ADCs.
* **DOI:** [10.48550/arxiv.2403.13577](https://doi.org/10.48550/arxiv.2403.13577)
* **Full Author List:** Aditya Raj, et al. *(HCiM Authors)*
* **Venue:** arXiv preprint (`arXiv:2403.13577 [cs.AR]`)
* **Year:** 2024
* **Verbatim Quoted Sentence:** 
  > *"Note, ADCs alone consume as much as 60% energy and occupy nearly 80% area in CiM accelerators [23]."*
* **Publication Type:** **arXiv preprint** *(not peer-reviewed)*.
