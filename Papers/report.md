# FERROELECTRIC GATE-ALL-AROUND FETS

# FOR NEXT-GENERATION NEUROMORPHIC

# SYSTEMS: DEVICE MODELING AND SPIKING

# NETWORK IMPLEMENTATION

```
EEE-4100: Project Work
(This project report has been submitted in partial fulfilment of the requirements for
the degree of Bachelor of Science in Electrical and Electronic Engineering)
```
#### SUBMITTED BY:

#### EXAM ROLL: 2326357 EXAM ROLL: 232635 6

#### REG. NO: 2020615833 REG. NO: 2020815831

#### SESSION: 20- 21 SESSION: 20- 21

```
Year and Semester: 4th Year 1st Semester
Date of Submission: 1 2 th November 202 5
```
```
Department of Electrical and Electronic Engineering
University of Dhaka
```

#### ABSTRACT

This work focuses on enabling energy-efficient neuromorphic computing through the
design and characterization of a novel, steep-switching Gate-All-Around Ferroelectric
FET (GAA-FeFET) using technology computer-aided design (TCAD). The CMOS-
compatible device will be engineered to utilize its hysteretic and partial-polarization-
switching dynamics to function as a key neuromorphic primitive, the Leaky-Integrate-
and-Fire (LIF) spiking neuron. The potential for its use as a multi-level analog synapse
will also be investigated. Sub-60 mV/decade switching and non-volatile memory
properties will be introduced by incorporating a ferroelectric HfZrOx (HZO) layer
within the GAA gate stack. The first half of the project will consist of designing a
nanosheet-based GAA-FeFET structure and calibrating the TCAD ferroelectric models
with experimental data reported in the literature. The second half will focus on
extracting a compact model of the device's primary neuromorphic characteristic (LIF
neuron) and implementing this model within a Python-based Spiking Neural Network
(SNN). This SNN will be designed for a clinically relevant application involving the
classification of cardiac arrhythmias from the MIT-BIH ECG database, using a system-
level approach for evaluating neuromorphic device performance. Data obtained from
the device and system-level simulations will be thoroughly analyzed to evaluate the
proposed GAA-FeFET's performance as a scalable neuromorphic hardware primitive.


## Table of Contents


## List of Figures

- ABSTRACT PAGE
- List of Figures
- CHAPTER 1: INTRODUCTION
   - I. BACKGROUND AND CONTEXT:
   - II. OBJECTIVES:.......................................................................................................
- CHAPTER 2: LITERATURE REVIEW
- CHAPTER 3: PROPOSED METHODOLOGY
   - Project Design:
      - Overall Design
      - Work done during 1st semester
      - Detail work plan for 2nd semester
      - Expected Outcome
   - Gantt Chart
- CHAPTER 4: CONCLUSION
- CHAPTER 5: REFERENCES
- Figure 1: Biological blueprint of Neuromorphic Computing PAGE
- Figure 2: Core Advantages of a GAA-FeFET Neuromorphic Platform.
- Figure 3: Objectives of the project.................................................................................
- Figure 4: 3D view of Gate All Around Transistor........................................................
- Figure 5: Target Id−Vg characteristics of a FeFET [17]
- Figure 6: System-Level Diagram for Python SNN-based ECG Classification
- Figure 7: Overall Project Workflow
- Figure 8: Sentaurus SDE model of the MFMIS Device [17]
- Figure 9: Gantt Chart of project workflow


#### CHAPTER 1

#### INTRODUCTION

### I. BACKGROUND AND CONTEXT:

The computational paradigm of modern electronics is built upon the von Neumann
architecture, which establishes a physical separation between processing (CPU) and
memory (RAM) units. For decades, this model has delivered exponential performance
gains via Moore's Law. However, for data-intensive tasks such as artificial intelligence
(AI) and real-time signal processing, this architecture faces a critical limitation known
as the "von Neumann bottleneck" [1]. The constant shuffling of data between the
processor and memory consumes the majority of system energy and time, creating an
efficiency barrier that cannot be solved by simple transistor scaling.

To overcome this bottleneck, the field of neuromorphic computing has emerged,
drawing inspiration from the structure and efficiency of the biological brain. The brain
performs "in-memory computing" by co-locating processing and memory within dense
networks of neurons and synapses. Spiking Neural Networks (SNNs), which operate
using asynchronous spikes rather than continuous signals, emulate this biological
behaviour and offer substantial gains in energy efficiency [2]. Neuromorphic
computing has also begun to influence artificial intelligence, enabling AI systems to
process data more efficiently and perform complex tasks at low power, particularly in
edge and real-time applications [3].

To fully realize the potential of SNNs, new hardware is required. Ferroelectric Field-
Effect Transistors (FeFETs) have become a leading candidate for this hardware. Based
on CMOS-compatible materials like Hafnium Zirconium Oxide (𝐻𝑓𝑍𝑟𝑂𝑥 or HZO),
FeFETs exhibit non-volatile memory and rich polarization-switching dynamics [4] [5].
properties allow a single FeFET to emulate the behavior of both a spiking neuron and
an analog synapse, offering a path to dense, low-power neuromorphic hardware. This
biological process, which is the blueprint for neuromorphic computing, is illustrated in
Figure 1, showing how input spikes are processed through synapses and neurons to
produce an integrated 'fire' response.

Simultaneously, transistor architecture is evolving from FinFETs to Gate-All-Around
(GAA) structures. GAA transistors, which wrap the gate around the channel on all sides,


provide superior electrostatic control, reduced short-channel effects, and higher drive
currents [6].

The advantages of using a FeFET-based approach for neuromorphic computing are
manifold. Firstly, its intrinsic non-volatility allows for zero standby power, crucial for
edge devices [7]. Secondly, its compatibility with existing CMOS fabrication processes
makes it commercially scalable, unlike more exotic materials [5]. Thirdly, the device
physics are well-suited for neuromorphic functions: the hysteretic switching is ideal for
creating relaxation oscillators (neurons), and the partial polarization switching allows
for a high number of analog conductance states (synapses) [8]. This project will harness
these advantages in a state-of-the-art GAA structure. Figure 2 summarizes this concept,
outlining how the superior electrostatic control of a GAA structure and the non-volatile
polarization of ferroelectric HZO combine to enable high-density, energy-efficient
neuromorphic computing.

```
Figure 1 : Biological blueprint of Neuromorphic Computing
```

### II. OBJECTIVES:.......................................................................................................

**Development of the Transistor Architecture:**

At the beginning of our project, we focus on designing a novel Gate-All-Around (GAA)
nanosheet Ferroelectric FET (FeFET) using Sentaurus TCAD. The transistor structure
will be designed and calibrated with attention to the nanosheet dimensions, including
thickness and width, as well as the ferroelectric gate stack thickness (HfZrOx). The goal
is to achieve a device that demonstrates stable hysteresis and a steep subthreshold slope
below 60 mV/dec, enabling efficient low-power operation.

**Analysis of Neuromorphic Functionality:**

The main aim of our project is to analyze the neuromorphic computing behaviors of the
GAA-FeFET. This includes studying the curves obtained from Sentaurus simulations
to understand the device’s response. The transistor will be modeled as a Leaky-
Integrate-and-Fire (LIF) neuron in a relaxation oscillator circuit to examine its spiking
dynamics. In addition, the device will be evaluated as an analog synapse by applying
potentiation and depression pulses, allowing us to quantify its multi-level conductance
states.

**System-Level Integration for Neuromorphic Tasks:**

This project also seeks to demonstrate the integration of the GAA-FeFET into a system-
level neuromorphic application. A Spiking Neural Network (SNN) for ECG arrhythmia
classification will be developed in Python, inspired by the work of Yuan et al. on VO₂
memristive devices [9]. This will involve creating a spike encoder for the MIT-BIH

## Figure 2: Core Advantages of a GAA-FeFET Neuromorphic Platform.


dataset and designing a custom SNN layer in PyTorch that incorporates the
characteristics of the simulated FeFET in place of conventional neuron models. The
network will be trained using the Surrogate Gradient method and benchmarked against
existing literature to evaluate classification performance. The overall workflow of these
objectives, from device design to system-level implementation and evaluation, is
depicted in the flowchart in Figure 3.

The primary objectives for the first semester centered on establishing the foundational
simulation framework necessary for the GAA-FeFET design. This involved two main
goals. First, to construct the device architecture for a 2D back-gated MoS 2 Negative
Capacitance FET (NC-FET) within the Sentaurus Structure Editor (SDE). This specific
device was chosen to serve as the initial platform for calibration, as it directly
corresponds to experimental data available in the literature. Second, to initiate the
model calibration process by simulating the device's Id-Vg transfer characteristics and
comparing these initial results against the published experimental data. The aim was to
validate the baseline TCAD setup and identify key parameters, such as the LK
coefficients, requiring rigorous tuning.


## Figure 3: Objectives of the project.................................................................................


#### CHAPTER 2

#### LITERATURE REVIEW

Efforts to continually scale down traditional semiconductor technologies have begun to
run into inherent physical limitations, often described as the Von Neumann bottleneck.
In this conventional architecture, computing units (logic cores) and data storage
elements (memory blocks) are physically separated, which leads to inefficiencies in
power usage, increased latency, and heat generation when handling the large volumes
of data typical in modern applications. To address these challenges, neuromorphic
computing has emerged, aiming to replicate the human brain’s parallel, event-driven,
and energy-efficient processing, where logic and memory functions are closely
integrated. Central to this approach are synaptic devices, which function as analogue
weight elements. Among these, the Ferroelectric Field-Effect Transistor (FeFET) stands
out as a strong candidate due to its CMOS compatibility, non-volatile behavior, compact
footprint, and very low write energy. The Gate-All-Around FeFET (GAA-FeFET)
further enhances device performance by offering superior electrostatic control, reduced
short-channel effects, and improved scalability.

Advanced semiconductor device architectures, such as the Gate-All-Around (GAA)
transistor, are crucial for continuing scaling efforts beyond current limitations. The
GAA structure allows for the aggressive downscaling of transistors and is a key
technology for enhancing efficiency in neuromorphic applications. N. Loubet et al.
demonstrated the fundamental capability of stacked nanosheet GAA transistors to
enable scaling beyond the performance limits of the FinFET architecture. The shift
toward GAA structures addresses previous challenges in conventional FET-based leaky
integrate-and-fire (LIF) neurons, particularly the need for a floating body and the
constraints on scaling the silicon-on-insulator (SOI) film in the sub-nanometer range
[10]. Y. Bhatawdekar et al. utilized the GAA Floating Nanosheet Field-Effect Transistor
(FNSFET) structure to design an energy-efficient LIF neuron, capitalizing on the
enhanced control over short-channel effects inherent to the GAA geometry. The
proposed GAA FNSFET LIF neuron design, featuring a gate length (Lg) of 100 nm,
achieved an exceptionally low energy consumption of 4.88 fJ (4.88×10−^15 J) per spike,
operating at a supply voltage of 1 V [11].


The incorporation of ferroelectric (FE) materials, such as HfO 2 based oxides, into the
gate stack has enabled the exploration of Negative Capacitance (NC) field-effect
transistors (NCFETs). NCFETs utilize the intrinsic negative slope of the ferroelectric
material’s capacitance-voltage (C-V) curve to amplify the internal voltage, potentially
lowering the subthreshold swing (SS) below the classical 60 mV/decade limit, which is
essential for ultra-low power applications. M.-H. Lee et al. reported experimental
results for ferroelectric HfZrOx FETs demonstrating the benefits of this material system
for NCFETs. Their optimized devices, showing a CET = 0.98 nm, achieved an
impressive minimum reverse subthreshold swing (SSrev) of 28 mV/dec and a forward
SS (SSfor) of 42 mV/dec, validating the potential for steep switching [12]. M.-Y. Kao
investigated the impact of the material microstructure on device performance,
particularly addressing variability arising from the non-uniform distribution of
dielectric (DE) and ferroelectric (FE) grains within the gate stack. Through TCAD
simulations, Kao quantified that the random spatial distribution of DE and FE phases
resulted in variations of the ON and OFF currents up to 14.44% and 30.23%,
respectively. This highlights that while NCFETs offer performance benefits, controlling
microstructural non-uniformity is crucial for minimizing variability in scaled devices
[13].

Ferroelectric FETs (FeFETs) are highly promising candidates for implementing energy-
efficient, non-volatile analog synapses in neuromorphic hardware due to their CMOS
compatibility and the ability of their ferroelectric layer to store multiple conductance
states. M. Jerry et al. successfully demonstrated the use of a FeFET as an analog synapse
for accelerating deep neural network (DNN) training. Their work showed that a FeFET
could operate as a multi-state weight cell, achieving 4 × conductance modulation and
requiring approximately 75 ns program pulses. This multi-bit operation is achieved
through the progressive switching of ferroelectric domains using sub-coercive voltage
pulses [14]. J. Zhao et al. optimized the operational bias schemes for HfAlOx (HAO)-
FeFET synapses in neural network (NN) systems, focusing on improving weights
linearity, accuracy, and energy efficiency during online training. Using measured data
from HAO-FeFETs under incremental pulses, they achieved a minimum nonlinearity
of 0.01 for both potentiation (increasing conductance) and depression (decreasing
conductance), demonstrating high suitability for online training [15].


The hysteretic switching characteristics of FeFETs make them excellent candidates for
building compact, capacitor-less artificial spiking neurons that mimic the
Leaky Integrate-and-Fire (LIF) dynamics of biological neurons. The dynamics are
typically realized through relaxation oscillators utilizing the polarization switching
properties. Z. Wang et al. experimentally demonstrated the fundamental operation of
ferroelectric spiking neurons based on the FeFET structure for applications such as
unsupervised clustering. This approach permits the realization of a FeFET-based LIF
neuron using only seven transistors (including one FeFET), with an estimated footprint
area of approximately 1.74 × 1.18 _μ_ m^2 at the 45nm technology node [16]. C. Jiang et
al. analyzed the crucial design parameters that govern the hysteretic characteristics
required for oscillation. Their analytical models showed that the critical thickness
(tFE, cri) necessary to induce hysteresis in a FeFET was calculated to be 31.2 nm for a
drain-source voltage (Vds) of 0.05 V and 43.75 nm for Vds = 1 V [17].

In the context of neuromorphic applications, several research efforts have explored the
integration of ferroelectric and advanced transistor technologies within spiking neural
network (SNN) frameworks. M. A. Khanday et al. proposed a bio-inspired spiking
neuron based on a double-gate ferroelectric tunnel FET (DG-FE-TFET) and
implemented it within a multi-layer spiking neural network (SNN) for heartbeat
classification. Utilizing heartbeat signals derived from the MIT-BIH database, the
system achieved classification of heartbeats into four target classes (N, F, SVEB, and
VEB). Leveraging the device’s tunneling mechanism for low voltage operation, the
proposed 50 nm DG-FE-TFET neuron consumes ultra-low energy of 0.58 aJ per spike
(0.58×10−18 J) and operates at a high spiking frequency of 344 GHz. The three-layer
SNN, implemented and simulated in Python, achieved a maximum classification
accuracy of 84.4% [18]. Y. He et al. demonstrated a spiking neural network (SNN)
utilizing HfO2-based Ferroelectric Tunnel Junction (FTJ) memristors as synapses for a
handwritten digit recognition task. Using a pure SPICE network simulation with the
FTJ compact model, they achieved a successful recognition rate of 78.8% when testing
with 1000 samples, demonstrating the application of ferroelectric devices in complex
neuromorphic systems [19]. J.-K. Han et al. successfully demonstrated high-scalability
artificial neurons (vertical Si Nanowire GAA 1T-neurons) that were applied in a two-
layer fully connected SNN for handwritten digit recognition using the MNIST dataset.


Utilizing the measured neuronal characteristics in a software simulation, they reported
a high recognition accuracy of 93% [20].

Effective training of SNNs requires specialized algorithms compatible with spike-based
event processing and the non-volatile nature of the underlying hardware (e.g., FeFETs
or FTJs). Y. He et al. relied on the fundamental principles of Spike-Timing-Dependent
Plasticity (STDP) to train the FTJ-based synaptic weights in their handwritten digit
recognition system. The training process involves modifying the conductance (synaptic
weight) based on the relative timing of presynaptic and postsynaptic spikes, driving the
continuous evolution of the FTJ array conductance [19]. S. Dutta et al. proposed using
the Surrogate Gradient (SG) learning algorithm to enable supervised learning on their
all-FeFET-based SNN platform. Their hardware implementation utilized the rich
stochastic dynamics of the FeFET neuron, demonstrating spike frequency adaptation
where the instantaneous firing rate of the neuron decreases with each output spike
which is a key biological feature important for homeostatic plasticity [21].


#### CHAPTER 3

#### PROPOSED METHODOLOGY

**I. Project Design:**

- **Overall Design:**

The project is organized following a device-to-system workflow and is divided into into
three interconnected stages. Each stage builds upon the outcomes of the previous one,
creating a smooth progression from device-level design to system-level application.

**Phase 1: Designing the Transistor Architecture** : The first stage involves designing a
novel GAA-FeFET nanosheet in Sentaurus TCAD. During this process, the device’s
physical models will be carefully calibrated to ensure accurate representation of its
electrical behavior.

As shown in Figure 4, the three-dimensional view illustrates the structural configuration
of the Gate-All-Around (GAA) transistor. The device will employ a nanosheet-based
structure, chosen over nanowires for its improved electrostatic control and higher drive
current, consisting of silicon nanosheets fully wrapped by a metal-ferroelectric-
insulator-semiconductor (MFIS) gate stack. The channel will use silicon nanosheets,
while the gate stack will comprise a TiN metal gate, a Hf 0. 5 Zr 0. 5 O 2 (HZO) ferroelectric
layer, and a thin SiON or SiO 2 interfacial layer. The 1:1 Hf:Zr ratio ensures a robust
ferroelectric phase suitable for memory and switching applications. The simulation will

## Figure 4: 3D view of Gate All Around Transistor........................................................

(^)


integrate standard drift-diffusion transport models with the Landau-Khalatnikov (LK)
model for the HZO layer, with LK parameters calibrated to replicate experimental P-E
and C-V curves from the literature. The simulation plan begins with ferroelectric
calibration using a simple TiN/HZO/TiN capacitor, tuning the LK parameters until the
simulated polarization-electric field (P-E) loop aligns with experimental data. After
calibration, the complete GAA-FeFET will be simulated to extract its Id−Vg transfer

characteristics in both forward and reverse sweeps, targeting a clear hysteretic memory
window and sub-60 mV/dec switching slope indicative of negative capacitance
behaviour. The target Id−Vg transfer characteristic for the GAA-FeFET,
demonstrating a sharp turn-on and low off-state current, is shown in Figure 5.

**Phase 2: Neuromorphic Primitive Characterization** : In the second stage, the
electrical characteristics obtained from the simulations will be analyzed to model the
device as a Leaky-Integrate-and-Fire (LIF) neuron and as an analog synapse, enabling
exploration of its neuromorphic functionalities.

Since full TCAD simulations are computationally intensive, a compact model of the
GAA-FeFET will be extracted and implemented in Python or SPICE for system-level
analysis. The primary aim of this phase is to characterize the device as a neuromorphic
primitive, focusing on its behaviour as a Leaky-Integrate-and-Fire (LIF) neuron.

For neuron characterization, a 1FeFET-1T1C relaxation oscillator circuit will be
simulated in Python using the compact device model. A constant input current,

## Figure 5: Target Id−Vg characteristics of a FeFET [17]

(^10) **0.20.30.40.50.60.70.80.91.
−
10 −
10 −
10 −
10 −
10 −
10 −
10 −
10 −
Drain Current I
(D
A/
μm
)
Gate Voltage VGS (V)**


representing synaptic activity, will be applied to the circuit, and the capacitor voltage
(Vs) will be monitored. The voltage is expected to rise linearly until the FeFET switches
ON at a threshold voltage, then discharge abruptly, with intrinsic hysteresis causing a
reset at a lower voltage, effectively emulating LIF neuron dynamics.

**Phase 3: System-Level Implementation** : The final stage focuses on integrating the
characterized device into a Python-based Spiking Neural Network (SNN). This network
will utilize the device model from Phase 2 and will be applied to a neuromorphic ECG
classification task, demonstrating the practical system-level potential of the GAA-
FeFET.

In this final phase, the project demonstrates the neuromorphic computing capabilities
of the GAA-FeFET by implementing a complete ECG classification system in Python.
The MIT-BIH Arrhythmia dataset will be pre-processed into sparse spike trains using
a Python-based asynchronous spike encoder, which converts the analog ECG signals
into UP, DOWN, and CUE spike channels. A Long Short-Term Memory Spiking
Neural Network (LSNN) will be constructed in PyTorch, incorporating a custom
GAALIFNeuron layer whose parameters are derived directly from the f-I curve and
other device characteristics obtained in Phase 2. The network will be trained using
Backpropagation Through Time with the Surrogate Gradient method to handle spiking
non-linearities. Performance will be evaluated on a test set from the MIT-BIH database,
generating accuracy, sensitivity, and specificity metrics. These results highlight the
potential of the proposed GAA-FeFET for practical neuromorphic computing
applications. Figure 6 provides a visual diagram of this entire system-level workflow,
from the analog ECG signal input to the final classification output.


The project is expected to be successfully implemented, demonstrating both the
transistor-level performance of the GAA-FeFET and its integration into neuromorphic
circuits for system-level tasks. The results will provide comprehensive insights into the
device’s electrical behavior, compact modeling, and its application within a spiking
neural network. Figure 7 illustrates the complete workflow that has been described so
far, capturing all the stages from device design to system-level implementation.

## Figure 6: System-Level Diagram for Python SNN-based ECG Classification

```
.
```

- **Work done during 1st semester**

During the first semester, the project focused on establishing the TCAD simulation
framework. The main goal was to construct the device architecture in Sentaurus and
initiate the model calibration process, which is essential for simulating the proposed
GAA-FeFET.

As part of this effort, a 2D back-gated MoS 2 Negative Capacitance FET (NC-FET) was
designed in the Sentaurus Structure Editor (SDE). This structure was selected as the
initial calibration platform because it directly corresponds to the experimental results
reported by Jiang et al. [3], providing a reliable reference for tuning the simulation
parameters.

The next step involved calibrating the TCAD physics models, particularly the Landau-
Khalatnikov (LK) model for the HZO layer, against the experimental data. An initial

## Figure 7: Overall Project Workflow


simulation of the Id−Vg transfer characteristics was carried out using the LK

coefficients and device parameters from the literature. However, the first-pass
simulation showed significant deviations from the experimental curves, with
discrepancies in threshold voltage and subthreshold slope, indicating that the published
parameters alone were insufficient to reproduce the steep-switching behaviour (SSrev=
52 .3mV/dec) [3]. Figure 8 shows the structure of our simulated device, which is a
Metal-Ferroelectric-Metal-Insulator-Semiconductor (MFMIS) Device.

In conclusion, the 1st-semester work successfully set up the TCAD structural
framework in SDE, but the initial calibration highlighted the need for a more systematic
tuning of the LK parameters and other key physical properties, such as interfacial layers
and contact resistances. This finding establishes the immediate priority for the second
semester, which is to perform a rigorous parameter calibration so that the NC-FET
model can serve as a validated baseline for the eventual GAA-FeFET design.

- **Detail work plan for 2nd semester**

In the second semester, the project will build upon the foundational work from the first
semester to complete a full device-to-system study. The initial focus will be on rigorous
calibration and validation of the NC-FET model. TCAD physics parameters, including
Landau coefficients, interface traps, and contact resistances, will be systematically
tuned to align the simulated Id−Vg and P-E curves with experimental data. Once

## Figure 8: Sentaurus SDE model of the MFMIS Device [17]

```
10 −11−0 8 −0 4 0.0 0.4 0.
```
```
10 −
```
```
10 −
```
```
10 −
```
```
10 −
```
```
10 −
```
```
10 −
```
```
Drain Current I
```
```
(D
A/
```
```
μm
```
```
)
```
```
Gate Voltage VGS (V)
```
(^) **SimulatedExperimental**
(a) (b)


validated, the model will serve as the basis for designing the nanosheet GAA-FeFET in
Sentaurus, where baseline Id−Vg and C-V simulations will confirm proper hysteresis,

memory window, and subthreshold slope behavior.

Following the device design, a compact model of the GAA-FeFET will be developed
in Python for neuromorphic system simulations. This model will be used to simulate a
1FeFET-1T1C relaxation oscillator circuit, allowing detailed characterization of its LIF
neuron properties and the generation of the frequency-current curve. Additional
neuromorphic features, such as preliminary synaptic behaviour including long-term
potentiation (LTP) and depression (LTD), will also be simulated if time permits,
providing insight into the device’s analog state precision and bit-level resolution for
neuromorphic applications.

Finally, the focus will shift to full neuromorphic system implementation in Python. The
MIT-BIH Arrhythmia dataset will be pre-processed using a Python-based
asynchronous spike encoder, converting analog ECG signals into sparse UP, DOWN,
and CUE spike trains suitable for spiking neural networks. A Long Short-Term Memory
Spiking Neural Network will be constructed in PyTorch, incorporating a custom
GAALIFNeuron layer whose parameters are directly derived from the compact device
simulations. The network will be trained using Backpropagation Through Time with
the Surrogate Gradient method, and its performance as a neuromorphic computing
system will be evaluated in terms of accuracy, sensitivity, and specificity.

- **Expected Outcome**

This project will deliver a comprehensive device-to-system study of a novel
neuromorphic computing element. The first outcome is a fully calibrated TCAD
simulation model of a nanosheet GAA-FeFET, which captures the intricate ferroelectric
and transport physics of the device and serves as a reliable foundation for designing
brain-inspired circuits. The second outcome is a detailed quantitative characterization
of the GAA-FeFET’s performance, demonstrating its ability to function both as an LIF
spiking neuron through the frequency-current curve and as an analog synapse via LTP
and LTD behavior with defined bit precision, effectively replicating key aspects of
neuronal and synaptic activity. The final outcome is a working Python-based Spiking
custom neuron model is physically grounded in the TCAD simulations. This


demonstrates the potential of the device to support successful neuromorphic
applications and highlights its relevance for biomedical signal processing and other
brain-inspired computing tasks that require energy-efficient, parallel, and event-driven
computation.

**II. Gantt Chart:**

## Figure 9: Gantt Chart of project workflow


#### CHAPTER 4

#### CONCLUSION

To date, we have established a complete TCAD framework for simulating and
analyzing ferroelectric transistors, which now serves as the foundation for developing
a highly efficient GAA-FeFET aimed at enabling advanced neuromorphic
functionalities. This phase of the work has provided valuable insight into the complex
interaction between ferroelectric polarization, interface properties, and device
electrostatics. The next step involves fine-tuning these models to achieve accurate
calibration and to capture the steep-switching and memory behavior required for
neuromorphic operation. In parallel, efforts are being directed toward developing
compact models that can replicate the observed device characteristics at the circuit and
system levels. These models will be essential for simulating neuromorphic behaviors
such as spike generation and synaptic plasticity. One of the key challenges lies in
achieving precise parameter calibration across different simulation environments while
establishing a stable and compatible Python setup that can seamlessly integrate the
calibrated TCAD data for system-level analysis. Work is also underway to link the
device-level results to a functional spiking neural network model in Python, enabling a
direct evaluation of the GAA-FeFET’s potential in biomedical signal processing
applications.


#### CHAPTER 5

#### REFERENCES

[1] S. Paul, A. Krishna, W. Qian, R. Karam, and S. Bhunia, “MAHA: An energy-
efficient malleable hardware accelerator for data-intensive applications,” _IEEE
Trans Very Large Scale Integr VLSI Syst_ , vol. 23, no. 6, pp. 1005–1016, Jun.
2015, doi: 10.1109/TVLSI.2014.2332538.

[2] S. Yu, “Neuro-Inspired Computing with Emerging Nonvolatile Memorys,”
_Proceedings of the IEEE_ , vol. 106, no. 2, pp. 260–285, Feb. 2018, doi:
10.1109/JPROC.2018.2790840.

[3] N. R. Shanbhag and S. K. Roy, “Benchmarking In-Memory Computing
Architectures,” _IEEE Open Journal of the Solid-State Circuits Society_ , vol. 2,
pp. 288–300, 2022, doi: 10.1109/OJSSCS.2022.3210152.

[4] Y. Fang, J. Gomez, Z. Wang, S. Datta, A. I. Khan, and A. Raychowdhury,
“Neuro-mimetic dynamics of a ferroelectric FET-based spiking neuron,” _IEEE
Electron Device Letters_ , vol. 40, no. 7, pp. 1213–1216, Jul. 2019, doi:
10.1109/LED.2019.2914882.

[5] M. Halter _et al._ , “Back-End, CMOS-Compatible Ferroelectric Field-Effect
Transistor for Synaptic Weights,” _ACS Appl Mater Interfaces_ , vol. 12, no. 15,
pp. 17725–17732, Apr. 2020, doi: 10.1021/ACSAMI.0C00877.

[6] L. Pan, “Research of Gate-All-Around Field-Effect Transistors,” _Science and
Technology of Engineering, Chemistry and Environmental Protection_ , vol. 1, no.
9, Oct. 2024, doi: 10.61173/4GWHQ846.

[7] T. Ali _et al._ , “A Novel Dual Ferroelectric Layer Based MFMFIS FeFET with
Optimal Stack Tuning Toward Low Power and High-Speed NVM for
Neuromorphic Applications,” _Digest of Technical Papers - Symposium on VLSI
Technology_ , vol. 2020 - June, Jun. 2020, doi:
10.1109/VLSITECHNOLOGY18217.2020.9265111.

[8] H. L. Lin and P. Su, “Analysis and Design of FeFET Synapse with Stacked-
Nanosheet Architecture Considering Cycle-to-Cycle Variations for
Neuromorphic Applications,” _IEEE Open Journal of Nanotechnology_ , vol. 5, pp.
17 – 22, 2024, doi: 10.1109/OJNANO.2024.3399559.


[9] R. Yuan _et al._ , “A neuromorphic physiological signal processing system based
on VO2 memristor for next-generation human-machine interface,” _Nature
Communications 2023 14:1_ , vol. 14, no. 1, pp. 1–14, Jun. 2023, doi:
10.1038/s41467- 023 - 39430 - 4.

[10] N. Loubet _et al._ , “Stacked nanosheet gate-all-around transistor to enable scaling
beyond FinFET,” _Digest of Technical Papers - Symposium on VLSI Technology_ ,
pp. T230–T231, Jul. 2017, doi: 10.23919/VLSIT.2017.7998183.
[11] Y. Bhatawdekar _et al._ , “Design of energy-efficient LIF neuron using CMOS
compatible gate-all-around floating nanosheet FET for bio-inspired spiking
neural networks,” _Neurocomputing_ , vol. 659, p. 131814, Jan. 2026, doi:
10.1016/J.NEUCOM.2025.131814.

[12] M. H. Lee _et al._ , “Bi-directional Sub-60mV/dec, Hysteresis-Free, Reducing
Onset Voltage and High Speed Response of Ferroelectric-AntiFerroelectric
Hf0.25Zr0.75O2 Negative Capacitance FETs,” _Technical Digest - International
Electron Devices Meeting, IEDM_ , vol. 2019-December, Dec. 2019, doi:
10.1109/IEDM19573.2019.8993581.

[13] M.-Y. Kao, “Negative Capacitance Field-Effect Transistor Design and Machine
Learning Applications in Compact Models,” 2022. [Online]. Available:
[http://www2.eecs.berkeley.edu/Pubs/TechRpts/2022/EECS-](http://www2.eecs.berkeley.edu/Pubs/TechRpts/2022/EECS-) 2022 - 34.html

[14] M. Jerry _et al._ , “Ferroelectric FET analog synapse for acceleration of deep neural
network training,” _Technical Digest - International Electron Devices Meeting,
IEDM_ , pp. 6.2.1-6.2.4, Jan. 2018, doi: 10.1109/IEDM.2017.8268338.

[15] J. Zhao _et al._ , “Voltage Bias Scheme Optimization in FeFET Based Neural
Network System,” _IEEE Electron Device Letters_ , vol. 44, no. 9, pp. 1464–1467,
Sep. 2023, doi: 10.1109/LED.2023.3300371.

[16] Z. Wang, S. Khandelwal, and A. I. Khan, “Ferroelectric Oscillators and Their
Coupled Networks,” _IEEE Electron Device Letters_ , vol. 38, no. 11, pp. 1614–
1617, Nov. 2017, doi: 10.1109/LED.2017.2754138.

[17] C. Jiang _et al._ , “The Study of Hysteretic Characteristics of FeFETs for
Neuromorphic Computing Using a Closed-Form Analytical Model,” _IEEE Trans
Electron Devices_ , vol. 71, no. 3, pp. 2184–2191, Mar. 2024, doi:
10.1109/TED.2024.3354880.

[18] M. A. Khanday and F. A. Khanday, “A bio-inspired ferroelectric tunnel FET-
based spiking neuron for high-speed energy efficient neuromorphic computing,”
_Micro and Nanostructures_ , vol. 188, p. 207788, Apr. 2024, doi:
10.1016/J.MICRNA.2024.207788.

[19] Y. He, W. C. Ng, and L. Smith, “TCAD modeling of neuromorphic systems
based on ferroelectric tunnel junctions,” _Journal of Computational Electronics
2020 19:4_ , vol. 19, no. 4, pp. 1444–1449, Jun. 2020, doi: 10.1007/S10825- 020 -
01544 - Z.


[20] J. K. Han, J. Oh, J. M. Yu, S. Y. Choi, and Y. K. Choi, “A Vertical Silicon
Nanowire Based Single Transistor Neuron with Excitatory, Inhibitory, and
Myelination Functions for Highly Scalable Neuromorphic Hardware,” _Small_ ,
vol. 17, no. 49, p. 2103775, Dec. 2021, doi:
10.1002/SMLL.202103775;SUBPAGE:STRING:ABSTRACT;WEBSITE:WE
BSITE:PERICLES;REQUESTEDJOURNAL:JOURNAL:16136829;WGROU
P:STRING:PUBLICATION.
[21] S. Dutta, C. Schafer, J. Gomez, K. Ni, S. Joshi, and S. Datta, “Supervised
Learning in All FeFET-Based Spiking Neural Network: Opportunities and
Challenges,” _Front Neurosci_ , vol. 14, p. 634, Jun. 2020, doi:
10.3389/FNINS.2020.00634.


