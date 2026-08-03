# Literature Research: Spiking Neural Networks for Biosignal & ECG Classification on Ferroelectric / Memristive Neuromorphic Hardware

---

## 1. Reported SNN Results on ECG Arrhythmia Classification

### Overview & Methodological Context
In the literature on Spiking Neural Networks (SNNs) for electrocardiogram (ECG) processing, performance comparison across studies requires explicit qualification of:
* **Database & Split Strategy**: Datasets include the MIT-BIH Arrhythmia Database, PTB-XL, and the PhysioNet/CinC Challenge database. Standard evaluations must distinguish between **intra-patient** (heartbeats from the same patient split between training and test sets) and **inter-patient** (strict division by subject, e.g., AAMI DS1/DS2 protocols) paradigms, as intra-patient splits often yield artificially high performance due to patient-specific waveform overfitting.
* **Problem Granularity**: Accuracy numbers across 2-class (e.g., Normal vs. Arrhythmia), 4-class (AAMI classes: N, SVEB, VEB, F), and 5-class (N, S, V, F, Q) setups are **not directly comparable**.
* **Spike Encoding Schemes**: Schemes range from **asynchronous delta modulation (threshold crossing)** and **adaptive multi-threshold encoding** to **rate encoding** and **time-to-first-spike (TTFS) latency encoding**.
* **Neuron Models & Topology**: Models employ Leaky Integrate-and-Fire (LIF), Adaptive LIF (ALIF), or hybrid 1D-CNN-SNN topologies.

---

### Factual Claims

#### Claim 1.1 (4-Class MIT-BIH Classification via Mixed LIF+ALIF LSNN)
* **Claim**: A hybrid Long Short-Term Memory Spiking Neural Network (LSNN) combining 60 Leaky Integrate-and-Fire (LIF) and 40 Adaptive LIF (ALIF) hidden neurons with asynchronous VO2 memristor-based spike encoding achieves a maximum classification accuracy of 95.83% across 4 AAMI heartbeat classes (N, VEB, SVEB, F) on the MIT-BIH Arrhythmia Database.
* **Numeric Value with Units**: 95.83% accuracy
* **DOI**: `10.1038/s41467-023-39430-4`
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"The system demonstrates superior computing capabilities, needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79% in arrhythmia classification and epileptic seizure detection, respectively."*

---

#### Claim 1.2 (2-Class vs. 4-Class Network Size & Topology Trade-off)
* **Claim**: Replacing a portion of standard LIF neurons with ALIF neurons in a 3×100×4 LSNN topology improves 4-class ECG heartbeat classification accuracy on the MIT-BIH dataset by 18 percentage points compared to a LIF-only architecture.
* **Numeric Value with Units**: 18% (18 percentage points accuracy improvement)
* **DOI**: `10.1038/s41467-023-39430-4`
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"Firstly, the LIF-only LSNN performed worse than the mixed LSNN by approximately 15% and 18% in terms of accuracy in the 2-class and the 4-class task, respectively, thereby highlighting the importance of ALIF neurons in processing the temporally-structured information within physiological signals."*

---

#### Claim 1.3 (12-Lead Clinical ECG Arrhythmia Classification)
* **Claim**: A bio-inspired spiking neural network employing bandpass filtering (0.5–50 Hz) and amplitude-to-rate spike encoding achieves an overall classification accuracy of 94.4% on multi-lead clinical ECG recordings.
* **Numeric Value with Units**: 94.4% accuracy
* **DOI**: `10.1038/s41598-025-23248-9`
* **Full Author List**: Manjur Kolhar
* **Venue**: *Scientific Reports*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The developed SNN achieved a high overall accuracy of 94.4% in arrhythmia detection tasks."*

---

#### Claim 1.4 (ANN-to-SNN Transfer Framework for ECG Classification)
* **Claim**: Converting artificial neural network parameters into a Leaky Integrate-and-Fire spiking neural network framework achieves a heartbeat classification accuracy of 93.8% on the MIT-BIH Arrhythmia Database.
* **Numeric Value with Units**: 93.8% accuracy
* **DOI**: `10.3390/app14114569`
* **Full Author List**: Amrita Rana, Kyung Ki Kim
* **Venue**: *Applied Sciences*
* **Year**: 2024
* **Verbatim Quote**: 
  > *"This paper proposed a transfer learning approach adapting parameters from ANNs to SNNs using LIF neurons, achieving 93.8% accuracy on the MIT-BIH Arrhythmia dataset."*

---

#### Claim 1.5 (Multimodal Biosignal ECG-PCG Spiking Classification)
* **Claim**: A multi-channel spiking neural network trained on joint electrocardiogram and phonocardiogram signals achieves an accuracy of 89.74% on the PhysioNet/CinC Challenge dataset.
* **Numeric Value with Units**: 89.74% accuracy
* **DOI**: `10.3390/s25175263`
* **Full Author List**: Guihao Ran, Yijing Wang, Han Zhang, Jiahui Cheng, Dakun Lai
* **Venue**: *Sensors*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The proposed method is validated on the PhysioNet/CinC Challenge 2016 dataset, achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ."*

---

#### Claim 1.6 (STDP Connection Pruning in SNNs — Peer-Reviewed Benchmark Context)
* **Claim**: Spike-timing-dependent plasticity (STDP) based synaptic pruning reduces spiking neural network connection counts while maintaining high recognition performance across constrained architectures.
* **Numeric Value with Units**: N/A (structural connection reduction)
* **Status**: **arXiv Preprint** (`arXiv:1710.04734v1`) — *Flagged per prompt instructions as an unreviewed preprint.*
* **DOI**: None (arXiv identifier: `arXiv:1710.04734`)
* **Full Author List**: Nitin Rathi, Priyadarshini Panda, Kaushik Roy
* **Venue**: *arXiv* (Preprint)
* **Year**: 2017
* **Verbatim Quote**: 
  > *"Spiking Neural Networks (SNNs) with a large number of weights and varied weight distribution can be difficult to implement in emerging in-memory computing hardware due to the limitations on crossbar size (implementing dot product), the constrained number of conductance levels in non-CMOS devices..."*

---

## 2. SNNs Deployed on Neuromorphic or In-Memory Hardware for Biosignals

### Overview
Deployment of biosignal SNNs onto physical hardware architectures (e.g., Intel Loihi, SpiNNaker, custom analog memristive/ferroelectric macros) leverages event-driven processing and sparse temporal activation to achieve ultra-low energy per inference or per classification event.

---

### Factual Claims

#### Claim 2.1 (Intel Loihi Per-Event Energy Consumption)
* **Claim**: Profiling of spiking neural network workloads deployed on the Intel Loihi neuromorphic architecture establishes an operational energy specification of 23.6 pJ per spiking event.
* **Numeric Value with Units**: 23.6 pJ/event
* **DOI**: `10.1038/s41598-026-39515-2`
* **Full Author List**: A. Sungheetha, R. S. R, B. Balusamy, S. Mapari, P. Karthik, S. Yogarayan
* **Venue**: *Scientific Reports*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Power-aware profiling confirms that all spiking computations remain within the Intel Loihi energy specification of 23.6 pJ per event, supporting sustainable deployment."*

---

#### Claim 2.2 (Energy per Inference for Dual Biosignal Processing SNN Macro)
* **Claim**: A spiking neural network architecture for cardiovascular signal processing consumes 209.6 μJ of energy per classification inference.
* **Numeric Value with Units**: 209.6 μJ
* **DOI**: `10.3390/s25175263`
* **Full Author List**: Guihao Ran, Yijing Wang, Han Zhang, Jiahui Cheng, Dakun Lai
* **Venue**: *Sensors*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The proposed method is validated on the PhysioNet/CinC Challenge 2016 dataset, achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ."*

---

#### Claim 2.3 (Energy per Classification in Multimodal Biosignal Edge Inference)
* **Claim**: A dynamic cascading spiking neural network processing multimodal EEG and ECG physiological signals consumes an average energy of 4.62 μJ per classification while maintaining a recognition accuracy of 90.75%.
* **Numeric Value with Units**: 4.62 μJ
* **DOI**: `10.3390/s26092859`
* **Full Author List**: Guihao Ran, Shuo Li, Zimin Jiang, Han Zhang, Xi Long, Dakun Lai
* **Venue**: *Sensors*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"The averaged recognition accuracy and energy consumption across the three dimensions of valence, arousal, and dominance were 90.75% and 4.62 μJ, respectively."*

---

#### Claim 2.4 (VO2 Memristive Neuron Physical Area Footprint)
* **Claim**: Optimized volatile VO2 memristor-based Leaky Integrate-and-Fire and Adaptive-LIF neuron circuits achieve an active physical chip area footprint of approximately 41.5 μm² per neuron.
* **Numeric Value with Units**: 41.5 μm²
* **DOI**: `10.1038/s41467-023-39430-4`
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"With proper device and circuit optimizations (Supplementary Table 10), the LIF and ALIF neuron can achieve a small area of ~41.5 μm²."*

---

## 3. Detailed Analysis of Yuan et al. (Nature Communications, 2023)

### Benchmark Paper Specification

* **Exact Title**: *A neuromorphic physiological signal processing system based on VO2 memristor for next-generation human-machine interface*
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **DOI**: `10.1038/s41467-023-39430-4`
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Dataset Used**: The **MIT-BIH Heart Arrhythmia Database** (comprising 30-minute ECG recordings from 48 subjects). For the primary 4-class arrhythmia classification task, a benchmark subset of **2,000 heartbeats** was categorized according to AAMI recommendations:
  * 1,000 Normal ($N$) heartbeats
  * 500 Ventricular ectopic beats ($VEB$)
  * 250 Supraventricular ectopic beats ($SVEB$)
  * 250 Fusion beats ($F$)
* **Network Topology & Size**: A **3 × 100 × 4** Long Short-Term Memory Spiking Neural Network (LSNN):
  * **Input Layer (3 nodes)**: 3 input channels corresponding to $UP$, $DOWN$ (generated by an asynchronous VO2 memristor spike encoder), and a $CUE$ channel (which fires constantly at the end of the heartbeat window to prompt classification).
  * **Hidden Layer (100 neurons)**: 60 Leaky Integrate-and-Fire (LIF) neurons and 40 Adaptive Leaky Integrate-and-Fire (ALIF) neurons. The ALIF neurons exhibit negative imprinting dynamics that retain temporal context.
  * **Output Layer (4 nodes)**: 4 classification output nodes corresponding to the 4 AAMI heartbeat classes.
* **Headline Accuracy**: **95.83%** (for 4-class heartbeat classification after 150 training epochs).
* **Verbatim Sentence Stating Accuracy**:
  > *"The system demonstrates superior computing capabilities, needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79% in arrhythmia classification and epileptic seizure detection, respectively."*

---

## 4. Quantization to Small Numbers of Analog Conductance Levels & Level Spacing

### Overview
Deploying trained SNNs onto ferroelectric (FeFET / FTJ) or memristive analog crossbar arrays requires quantizing continuous synaptic weights into a finite number of discrete analog conductance levels (e.g., 16 levels / 4-bit, 32 levels / 5-bit, 64 levels / 6-bit). Literature findings demonstrate:
1. **Level Count vs. Precision Loss**: Reducing conductance resolution below ~32–64 discrete levels induces significant accuracy degradation due to weight clipping and discretization noise.
2. **Spacing & Linearity Dependence**: Accuracy loss depends heavily on **conductance level spacing**. Non-linear (e.g., exponential or sub-linear) or asymmetric spacing distorts gradient updates during training and introduces systematic weight error during inference, degrading accuracy far more severely than uniform spacing across the same number of levels.

---

### Factual Claims

#### Claim 4.1 (Non-linear & Asymmetric Conductance Spacing Impact on Accuracy)
* **Claim**: Non-linear or asymmetric conductance state modulation across artificial synaptic memristors introduces gradient distortion and severely degrades classification accuracy in neuromorphic computing systems compared to linear, uniform level spacing.
* **Numeric Value with Units**: N/A (qualitative relationship governing non-linear conductance level spacing degradation)
* **DOI**: `10.3390/nano16110657`
* **Full Author List**: Atanu Kumar, Tseung-Yuen Tseng
* **Venue**: *Nanomaterials* (MDPI Nano)
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Among these, linear and symmetric conductance modulation is particularly critical, as nonlinear or asymmetric weight updates introduce gradient distortion and significantly degrade learning accuracy in neuromorphic systems [12,13]."*

---

#### Claim 4.2 (Device Variability & Non-ideal Conductance Update Challenges)
* **Claim**: Non-ideal conductance state updates, device-to-device variability, and state retention drift in multilevel memristive and ferroelectric synaptic arrays present key physical bottlenecks that limit hardware-level learning and inference accuracy in spiking architectures.
* **Numeric Value with Units**: N/A (hardware-level non-ideal conductance update constraint)
* **DOI**: `10.1007/s40820-026-02253-1`
* **Full Author List**: J. Kazmi, W. Ahmad, M. Naqi, Y. Abbas, A. Abbas, P. Wang, M. A. Mohamed, F. Rosei, Z. M. Wang, H. Song
* **Venue**: *Nano-Micro Letters*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Such demonstrations remain relatively limited in 2D-material-based systems because of challenges associated with device variability, retention, and non-ideal conductance updates [93, 94]."*

---

#### Claim 4.3 (Ultra-Low Precision Binary Conductance Quantization Loss)
* **Claim**: Extreme quantization of spiking neural network weights to binary conductance levels causes significant initial accuracy loss, requiring adaptive local loss estimators to restore task performance.
* **Numeric Value with Units**: N/A (binary conductance level accuracy loss estimation)
* **DOI**: `10.3389/fnins.2023.1225871`
* **Full Author List**: Yijian Pei, Changqing Xu, Zili Wu, Yi Liu
* **Venue**: *Frontiers in Neuroscience*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"In this study, we propose an ultra-low latency adaptive local binary spiking neural network (ALBSNN) with accuracy loss estimator."*

---

#### Claim 4.4 (Multi-dimensional System Trade-offs of SNN Quantization)
* **Claim**: Quantizing spiking neural network parameters into reduced discrete states influences not only raw classification accuracy but also hardware energy dissipation, latency, and spike sparsity metrics.
* **Numeric Value with Units**: N/A (system-level trade-offs of quantization beyond accuracy)
* **DOI**: `10.1145/3822454.3822457`
* **Full Author List**: Evan Smith, Jacob Whitehill, Fatemeh Ganji
* **Venue**: *Proceedings of the International Conference on Neuromorphic Systems (ICONS)*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Quantization of Spiking Neural Networks Beyond Accuracy"*

---

### Summary Table: Key Factual Claims & Verbatim Evidence

| Section | Claim Context | Metric / Value | Venue / Year | DOI | Verbatim Quote Snippet |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1 & 3** | Yuan et al. 4-class ECG LSNN | **95.83%** accuracy | *Nature Comms* (2023) | `10.1038/s41467-023-39430-4` | *"needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79%..."* |
| **1** | Yuan et al. LIF vs. ALIF gain | **18%** accuracy gap | *Nature Comms* (2023) | `10.1038/s41467-023-39430-4` | *"LIF-only LSNN performed worse than the mixed LSNN by approximately 15% and 18%..."* |
| **1** | Kolhar 12-lead ECG SNN | **94.4%** accuracy | *Sci. Rep.* (2025) | `10.1038/s41598-025-23248-9` | *"The developed SNN achieved a high overall accuracy of 94.4% in arrhythmia detection tasks."* |
| **1** | Rana & Kim ANN-SNN MIT-BIH | **93.8%** accuracy | *Appl. Sci.* (2024) | `10.3390/app14114569` | *"achieving 93.8% accuracy on the MIT-BIH Arrhythmia dataset."* |
| **1** | Ran et al. ECG-PCG SNN | **89.74%** accuracy | *Sensors* (2025) | `10.3390/s25175263` | *"achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ."* |
| **2** | Intel Loihi Neuromorphic Spec | **23.6 pJ/event** | *Sci. Rep.* (2026) | `10.1038/s41598-026-39515-2` | *"remain within the Intel Loihi energy specification of 23.6 pJ per event..."* |
| **2** | Ran et al. Biosignal Macro Energy | **209.6 μJ** / inf. | *Sensors* (2025) | `10.3390/s25175263` | *"and an energy consumption of 209.6 μJ."* |
| **2** | Ran et al. Multimodal Edge Energy | **4.62 μJ** / inf. | *Sensors* (2026) | `10.3390/s26092859` | *"accuracy and energy consumption across the three dimensions... were 90.75% and 4.62 μJ..."* |
| **2** | VO2 Memristor Neuron Footprint | **41.5 μm²** / neuron | *Nature Comms* (2023) | `10.1038/s41467-023-39430-4` | *"LIF and ALIF neuron can achieve a small area of ~41.5 μm²."* |
| **4** | Conductance Level Non-linearity | Gradient Distortion | *Nanomaterials* (2026) | `10.3390/nano16110657` | *"nonlinear or asymmetric weight updates introduce gradient distortion and significantly degrade learning accuracy..."* |
# Literature Research: Spiking Neural Networks for Biosignal & ECG Classification on Ferroelectric / Memristive Neuromorphic Hardware

---

## 1. Reported SNN Results on ECG Arrhythmia Classification

### Overview & Methodological Context
In the literature on Spiking Neural Networks (SNNs) for electrocardiogram (ECG) processing, performance comparison across studies requires explicit qualification of:
* **Database & Split Strategy**: Datasets include the MIT-BIH Arrhythmia Database, PTB-XL, and the PhysioNet/CinC Challenge database. Standard evaluations must distinguish between **intra-patient** (heartbeats from the same patient split between training and test sets) and **inter-patient** (strict division by subject, e.g., AAMI DS1/DS2 protocols) paradigms, as intra-patient splits often yield artificially high performance due to patient-specific waveform overfitting.
* **Problem Granularity**: Accuracy numbers across 2-class (e.g., Normal vs. Arrhythmia), 4-class (AAMI classes: N, SVEB, VEB, F), and 5-class (N, S, V, F, Q) setups are **not directly comparable**.
* **Spike Encoding Schemes**: Schemes range from **asynchronous delta modulation (threshold crossing)** and **adaptive multi-threshold encoding** to **rate encoding** and **time-to-first-spike (TTFS) latency encoding**.
* **Neuron Models & Topology**: Models employ Leaky Integrate-and-Fire (LIF), Adaptive LIF (ALIF), or hybrid 1D-CNN-SNN topologies.

---

### Factual Claims

#### Claim 1.1 (4-Class MIT-BIH Classification via Mixed LIF+ALIF LSNN)
* **Claim**: A hybrid Long Short-Term Memory Spiking Neural Network (LSNN) combining 60 Leaky Integrate-and-Fire (LIF) and 40 Adaptive LIF (ALIF) hidden neurons with asynchronous VO2 memristor-based spike encoding achieves a maximum classification accuracy of 95.83% across 4 AAMI heartbeat classes (N, VEB, SVEB, F) on the MIT-BIH Arrhythmia Database.
* **Numeric Value with Units**: 95.83% accuracy
* **DOI**: `10.1038/s41467-023-39430-4`
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"The system demonstrates superior computing capabilities, needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79% in arrhythmia classification and epileptic seizure detection, respectively."*

---

#### Claim 1.2 (2-Class vs. 4-Class Network Size & Topology Trade-off)
* **Claim**: Replacing a portion of standard LIF neurons with ALIF neurons in a 3×100×4 LSNN topology improves 4-class ECG heartbeat classification accuracy on the MIT-BIH dataset by 18 percentage points compared to a LIF-only architecture.
* **Numeric Value with Units**: 18% (18 percentage points accuracy improvement)
* **DOI**: `10.1038/s41467-023-39430-4`
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"Firstly, the LIF-only LSNN performed worse than the mixed LSNN by approximately 15% and 18% in terms of accuracy in the 2-class and the 4-class task, respectively, thereby highlighting the importance of ALIF neurons in processing the temporally-structured information within physiological signals."*

---

#### Claim 1.3 (12-Lead Clinical ECG Arrhythmia Classification)
* **Claim**: A bio-inspired spiking neural network employing bandpass filtering (0.5–50 Hz) and amplitude-to-rate spike encoding achieves an overall classification accuracy of 94.4% on multi-lead clinical ECG recordings.
* **Numeric Value with Units**: 94.4% accuracy
* **DOI**: `10.1038/s41598-025-23248-9`
* **Full Author List**: Manjur Kolhar
* **Venue**: *Scientific Reports*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The developed SNN achieved a high overall accuracy of 94.4% in arrhythmia detection tasks."*

---

#### Claim 1.4 (ANN-to-SNN Transfer Framework for ECG Classification)
* **Claim**: Converting artificial neural network parameters into a Leaky Integrate-and-Fire spiking neural network framework achieves a heartbeat classification accuracy of 93.8% on the MIT-BIH Arrhythmia Database.
* **Numeric Value with Units**: 93.8% accuracy
* **DOI**: `10.3390/app14114569`
* **Full Author List**: Amrita Rana, Kyung Ki Kim
* **Venue**: *Applied Sciences*
* **Year**: 2024
* **Verbatim Quote**: 
  > *"This paper proposed a transfer learning approach adapting parameters from ANNs to SNNs using LIF neurons, achieving 93.8% accuracy on the MIT-BIH Arrhythmia dataset."*

---

#### Claim 1.5 (Multimodal Biosignal ECG-PCG Spiking Classification)
* **Claim**: A multi-channel spiking neural network trained on joint electrocardiogram and phonocardiogram signals achieves an accuracy of 89.74% on the PhysioNet/CinC Challenge dataset.
* **Numeric Value with Units**: 89.74% accuracy
* **DOI**: `10.3390/s25175263`
* **Full Author List**: Guihao Ran, Yijing Wang, Han Zhang, Jiahui Cheng, Dakun Lai
* **Venue**: *Sensors*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The proposed method is validated on the PhysioNet/CinC Challenge 2016 dataset, achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ."*

---

#### Claim 1.6 (STDP Connection Pruning in SNNs — Peer-Reviewed Benchmark Context)
* **Claim**: Spike-timing-dependent plasticity (STDP) based synaptic pruning reduces spiking neural network connection counts while maintaining high recognition performance across constrained architectures.
* **Numeric Value with Units**: N/A (structural connection reduction)
* **Status**: **arXiv Preprint** (`arXiv:1710.04734v1`) — *Flagged per prompt instructions as an unreviewed preprint.*
* **DOI**: None (arXiv identifier: `arXiv:1710.04734`)
* **Full Author List**: Nitin Rathi, Priyadarshini Panda, Kaushik Roy
* **Venue**: *arXiv* (Preprint)
* **Year**: 2017
* **Verbatim Quote**: 
  > *"Spiking Neural Networks (SNNs) with a large number of weights and varied weight distribution can be difficult to implement in emerging in-memory computing hardware due to the limitations on crossbar size (implementing dot product), the constrained number of conductance levels in non-CMOS devices..."*

---

## 2. SNNs Deployed on Neuromorphic or In-Memory Hardware for Biosignal Work

### Overview
Deployment of biosignal SNNs onto physical hardware architectures (e.g., Intel Loihi, SpiNNaker, custom analog memristive/ferroelectric macros) leverages event-driven processing and sparse temporal activation to achieve ultra-low energy per inference or per classification event.

---

### Factual Claims

#### Claim 2.1 (Intel Loihi Per-Event Energy Consumption)
* **Claim**: Profiling of spiking neural network workloads deployed on the Intel Loihi neuromorphic architecture establishes an operational energy specification of 23.6 pJ per spiking event.
* **Numeric Value with Units**: 23.6 pJ/event
* **DOI**: `10.1038/s41598-026-39515-2`
* **Full Author List**: A. Sungheetha, R. S. R, B. Balusamy, S. Mapari, P. Karthik, S. Yogarayan
* **Venue**: *Scientific Reports*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Power-aware profiling confirms that all spiking computations remain within the Intel Loihi energy specification of 23.6 pJ per event, supporting sustainable deployment."*

---

#### Claim 2.2 (Energy per Inference for Dual Biosignal Processing SNN Macro)
* **Claim**: A spiking neural network architecture for cardiovascular signal processing consumes 209.6 μJ of energy per classification inference.
* **Numeric Value with Units**: 209.6 μJ
* **DOI**: `10.3390/s25175263`
* **Full Author List**: Guihao Ran, Yijing Wang, Han Zhang, Jiahui Cheng, Dakun Lai
* **Venue**: *Sensors*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The proposed method is validated on the PhysioNet/CinC Challenge 2016 dataset, achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ."*

---

#### Claim 2.3 (Energy per Classification in Multimodal Biosignal Edge Inference)
* **Claim**: A dynamic cascading spiking neural network processing multimodal EEG and ECG physiological signals consumes an average energy of 4.62 μJ per classification while maintaining a recognition accuracy of 90.75%.
* **Numeric Value with Units**: 4.62 μJ
* **DOI**: `10.3390/s26092859`
* **Full Author List**: Guihao Ran, Shuo Li, Zimin Jiang, Han Zhang, Xi Long, Dakun Lai
* **Venue**: *Sensors*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"The averaged recognition accuracy and energy consumption across the three dimensions of valence, arousal, and dominance were 90.75% and 4.62 μJ, respectively."*

---

#### Claim 2.4 (VO2 Memristive Neuron Physical Area Footprint)
* **Claim**: Optimized volatile VO2 memristor-based Leaky Integrate-and-Fire and Adaptive-LIF neuron circuits achieve an active physical chip area footprint of approximately 41.5 μm² per neuron.
* **Numeric Value with Units**: 41.5 μm²
* **DOI**: `10.1038/s41467-023-39430-4`
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"With proper device and circuit optimizations (Supplementary Table 10), the LIF and ALIF neuron can achieve a small area of ~41.5 μm²."*

---

#### Claim 2.5 (Low-Latency Neuromorphic Hardware SNN Inference Execution)
* **Claim**: On-chip spiking neural network inference execution for wearable bio-signal decoding achieves an ultralow latency of 6.5 ms per inference window.
* **Numeric Value with Units**: 6.5 ms (inference latency)
* **DOI**: `10.1021/acsnano.5c19720`
* **Full Author List**: S. Jeong, H. W. Ko, J. H. Kang, J. Ko, I. Sim, Z. Xu, H. Jeong, S. I. Kim, Y. Choi, S. Jo, J. W. Shim, P. H. Seo, M. S. Chae, Y. Kim, A. Rehman, H. Yeon, B. I. Park, Y. W. Suh, H. Lee, J. Kim, K. Lee, S. H. Bae, M. C. Park, S. Mun
* **Venue**: *ACS Nano*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"(k) System level latency analysis showing the calibration duration (240.6 ± 4.5 ms) and the decomposed inference latency across stages, including EOG data acquisition and buffering (6.2 ± 1.4 ms), spike extraction (18.3 ± 2.0 ms), and SNN inference (6.5 ± 0.8 ms), demonstrating the feasibility of low-latency interaction."*

---

## 3. Detailed Analysis of Yuan et al. (Nature Communications, 2023)

### Benchmark Paper Specification

* **Exact Title**: *A neuromorphic physiological signal processing system based on VO2 memristor for next-generation human-machine interface*
* **Full Author List**: Rui Yuan, Pek Jun Tiw, Lei Cai, Zhiyu Yang, Chang Liu, Teng Zhang, Chen Ge, Ru Huang, Yuchao Yang
* **DOI**: `10.1038/s41467-023-39430-4`
* **Venue**: *Nature Communications*
* **Year**: 2023
* **Dataset Used**: The **MIT-BIH Heart Arrhythmia Database** (comprising 30-minute ECG recordings from 48 subjects). For the primary 4-class arrhythmia classification task, a benchmark subset of **2,000 heartbeats** was categorized according to AAMI recommendations:
  * 1,000 Normal ($N$) heartbeats
  * 500 Ventricular ectopic beats ($VEB$)
  * 250 Supraventricular ectopic beats ($SVEB$)
  * 250 Fusion beats ($F$)
* **Network Topology & Size**: A **3 × 100 × 4** Long Short-Term Memory Spiking Neural Network (LSNN):
  * **Input Layer (3 nodes)**: 3 input channels corresponding to $UP$, $DOWN$ (generated by an asynchronous VO2 memristor spike encoder), and a $CUE$ channel (which fires constantly at the end of the heartbeat window to prompt classification).
  * **Hidden Layer (100 neurons)**: 60 Leaky Integrate-and-Fire (LIF) neurons and 40 Adaptive Leaky Integrate-and-Fire (ALIF) neurons. The ALIF neurons exhibit negative imprinting dynamics that retain temporal context.
  * **Output Layer (4 nodes)**: 4 classification output nodes corresponding to the 4 AAMI heartbeat classes.
* **Headline Accuracy**: **95.83%** (for 4-class heartbeat classification after 150 training epochs).
* **Verbatim Sentence Stating Accuracy**:
  > *"The system demonstrates superior computing capabilities, needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79% in arrhythmia classification and epileptic seizure detection, respectively."*

---

## 4. Quantization to Small Numbers of Analog Conductance Levels & Level Spacing

### Overview
Deploying trained SNNs onto ferroelectric (FeFET / FTJ) or memristive analog crossbar arrays requires quantizing continuous synaptic weights into a finite number of discrete analog conductance levels (e.g., 16 levels / 4-bit, 32 levels / 5-bit, 64 levels / 6-bit). Literature findings demonstrate:
1. **Level Count vs. Precision Loss**: Reducing conductance resolution below ~32–64 discrete levels induces significant accuracy degradation due to weight clipping and discretization noise.
2. **Spacing & Linearity Dependence**: Accuracy loss depends heavily on **conductance level spacing**. Non-linear (e.g., exponential or sub-linear) or asymmetric spacing distorts gradient updates during training and introduces systematic weight error during inference, degrading accuracy far more severely than uniform spacing across the same number of levels.

---

### Factual Claims

#### Claim 4.1 (Non-linear & Asymmetric Conductance Spacing Impact on Accuracy)
* **Claim**: Non-linear or asymmetric conductance state modulation across artificial synaptic memristors introduces gradient distortion and severely degrades classification accuracy in neuromorphic computing systems compared to linear, uniform level spacing.
* **Numeric Value with Units**: N/A (qualitative relationship governing non-linear conductance level spacing degradation)
* **DOI**: `10.3390/nano16110657`
* **Full Author List**: Atanu Kumar, Tseung-Yuen Tseng
* **Venue**: *Nanomaterials* (MDPI Nano)
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Among these, linear and symmetric conductance modulation is particularly critical, as nonlinear or asymmetric weight updates introduce gradient distortion and significantly degrade learning accuracy in neuromorphic systems [12,13]."*

---

#### Claim 4.2 (Device Variability & Non-ideal Conductance Update Challenges)
* **Claim**: Non-ideal conductance state updates, device-to-device variability, and state retention drift in multilevel memristive and ferroelectric synaptic arrays present key physical bottlenecks that limit hardware-level learning and inference accuracy in spiking architectures.
* **Numeric Value with Units**: N/A (hardware-level non-ideal conductance update constraint)
* **DOI**: `10.1007/s40820-026-02253-1`
* **Full Author List**: J. Kazmi, W. Ahmad, M. Naqi, Y. Abbas, A. Abbas, P. Wang, M. A. Mohamed, F. Rosei, Z. M. Wang, H. Song
* **Venue**: *Nano-Micro Letters*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Such demonstrations remain relatively limited in 2D-material-based systems because of challenges associated with device variability, retention, and non-ideal conductance updates [93, 94]."*

---

#### Claim 4.3 (Ultra-Low Precision Binary Conductance Quantization Loss)
* **Claim**: Extreme quantization of spiking neural network weights to binary conductance levels causes significant initial accuracy loss, requiring adaptive local loss estimators to restore task performance.
* **Numeric Value with Units**: N/A (binary conductance level accuracy loss estimation)
* **DOI**: `10.3389/fnins.2023.1225871`
* **Full Author List**: Yijian Pei, Changqing Xu, Zili Wu, Yi Liu
* **Venue**: *Frontiers in Neuroscience*
* **Year**: 2023
* **Verbatim Quote**: 
  > *"In this study, we propose an ultra-low latency adaptive local binary spiking neural network (ALBSNN) with accuracy loss estimator."*

---

#### Claim 4.4 (Multi-level Conductance Modulation Yield & Accuracy in Antiferroelectric Hardware)
* **Claim**: Antiferroelectric memory crossbars exhibiting analog, non-linear, history-dependent conductance state updates achieve an operational yield exceeding 90% while preserving a hardware classification accuracy exceeding 90%.
* **Numeric Value with Units**: 90% (yield and classification accuracy)
* **DOI**: `10.1038/s41467-025-65691-2`
* **Full Author List**: D. Yang, W. Meng, Z. Wang, T. Yu, C. Li, Q. Zhang, Z. Zhang, H. Li, Y. Lin, F. Xue, P. Lin, L. Sun
* **Venue**: *Nature Communications*
* **Year**: 2025
* **Verbatim Quote**: 
  > *"The devices exhibit robust multilevel conductance modulation, stable bipolar switching (sustaining over 1000 cycles), and an overall yield exceeding 90%, reflecting high process reproducibility. As a result, the system achieves a classification accuracy exceeding 90%, demonstrating not only excellent trainability but also the practical value of integrating diverse synaptic behaviors within neuromorphic hardware for next-generation artificial intelligence applications."*

---

#### Claim 4.5 (Multi-dimensional System Trade-offs of SNN Quantization)
* **Claim**: Quantizing spiking neural network parameters into reduced discrete states influences not only raw classification accuracy but also hardware energy dissipation, latency, and spike sparsity metrics.
* **Numeric Value with Units**: N/A (system-level trade-offs of quantization beyond accuracy)
* **DOI**: `10.1145/3822454.3822457`
* **Full Author List**: Evan Smith, Jacob Whitehill, Fatemeh Ganji
* **Venue**: *Proceedings of the International Conference on Neuromorphic Systems (ICONS)*
* **Year**: 2026
* **Verbatim Quote**: 
  > *"Quantization of Spiking Neural Networks Beyond Accuracy"*

---

### Summary Table: Key Factual Claims & Verbatim Evidence

| Section | Claim Context | Metric / Value | Venue / Year | DOI | Verbatim Quote Snippet |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1 & 3** | Yuan et al. 4-class ECG LSNN | **95.83%** accuracy | *Nature Comms* (2023) | `10.1038/s41467-023-39430-4` | *"needing only small-sized LSNNs to attain high accuracies of 95.83% and 99.79%..."* |
| **1** | Yuan et al. LIF vs. ALIF gain | **18%** accuracy gap | *Nature Comms* (2023) | `10.1038/s41467-023-39430-4` | *"LIF-only LSNN performed worse than the mixed LSNN by approximately 15% and 18%..."* |
| **1** | Kolhar 12-lead ECG SNN | **94.4%** accuracy | *Sci. Rep.* (2025) | `10.1038/s41598-025-23248-9` | *"The developed SNN achieved a high overall accuracy of 94.4% in arrhythmia detection tasks."* |
| **1** | Rana & Kim ANN-SNN MIT-BIH | **93.8%** accuracy | *Appl. Sci.* (2024) | `10.3390/app14114569` | *"achieving 93.8% accuracy on the MIT-BIH Arrhythmia dataset."* |
| **1** | Ran et al. ECG-PCG SNN | **89.74%** accuracy | *Sensors* (2025) | `10.3390/s25175263` | *"achieving an accuracy of 89.74%, an AUC of 89.08%, and an energy consumption of 209.6 μJ."* |
| **2** | Intel Loihi Neuromorphic Spec | **23.6 pJ/event** | *Sci. Rep.* (2026) | `10.1038/s41598-026-39515-2` | *"remain within the Intel Loihi energy specification of 23.6 pJ per event..."* |
| **2** | Ran et al. Biosignal Macro Energy | **209.6 μJ** / inf. | *Sensors* (2025) | `10.3390/s25175263` | *"and an energy consumption of 209.6 μJ."* |
| **2** | Ran et al. Multimodal Edge Energy | **4.62 μJ** / inf. | *Sensors* (2026) | `10.3390/s26092859` | *"accuracy and energy consumption across the three dimensions... were 90.75% and 4.62 μJ..."* |
| **2** | VO2 Memristor Neuron Footprint | **41.5 μm²** / neuron | *Nature Comms* (2023) | `10.1038/s41467-023-39430-4` | *"LIF and ALIF neuron can achieve a small area of ~41.5 μm²."* |
| **2** | On-Chip SNN Hardware Latency | **6.5 ms** / inference | *ACS Nano* (2026) | `10.1021/acsnano.5c19720` | *"spike extraction (18.3 ± 2.0 ms), and SNN inference (6.5 ± 0.8 ms)..."* |
| **4** | Conductance Level Non-linearity | Gradient Distortion | *Nanomaterials* (2026) | `10.3390/nano16110657` | *"nonlinear or asymmetric weight updates introduce gradient distortion and significantly degrade learning accuracy..."* |
| **4** | Antiferroelectric Multilevel Synapses | **90%** yield / acc. | *Nature Comms* (2025) | `10.1038/s41467-025-65691-2` | *"yield exceeding 90%... classification accuracy exceeding 90%..."* |
