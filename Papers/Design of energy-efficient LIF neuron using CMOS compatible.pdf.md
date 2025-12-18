<!-- Neurocomputing 659 (2026) 131814 -->

<!--  -->

<!-- Contents lists available at ScienceDirect -->

<!-- **Neurocomputing** -->

<!-- ELSEVIER -->

<!-- journal homepage:www.elsevier.com/locate/neucom -->

<!-- 女 NEUROCOMPUTING -->

# Design of energy-efficient LIF neuron using CMOS compatible gate-all-around floating nanosheet FET for bio-inspired spiking neural networks

Yashodhan Bhatawdekara,Syed Mohammad Riyaza, Lakshmi Amrutha Yechuria, Sresta Valasa a,*, Venkata Ramakrishna Kotha a, Sunitha Bhukyaa,Shubham Tayalb, Narendar Vadthiya

aDepartment of Electronics and Communication Engineering, National Institute of Technology Warangal, 506004, India

bLayout Design, Staff engineer,Synopsys India Pvt. Ltd, Hyderabad 500032, India

## ARTICLEINFO

Keywords:

LIF neuron

Bio-inspired

SNN

NSFET

Spiking energy

Energy efficiency

## ABSTRACT

The fundamental component of an artificial spiking neural network (SNN) is an electronic device designed to emulate a biological neuron effectively. However, a key concern is the high energy consumption and large area associated with these artificial neurons, rendering them highly inefficient. This article presents a CMOS-compatible Gate-All-Around Floating Nanosheet Field-Effect Transistor (GAA FNSFET)-based Leaky Integrate-and-Fire (LIF) neuron with gate length of 100 nm. This design achieves an exceptionally low energy consump-tion of 4.88 fJ, thereby establishing a new benchmark in the field. Utilizing well calibrated 3D TCAD simulation and the SRH recombination model, along with the Unibo2 model to represent impact ionization phenomena, the proposed GAA FNSFET LIF neuron effectively captures integration and recombination aspects within it. More-over, it operates with a supply voltage of merely 1 V, significantly lower than conventional bulk FinFET and PD-SOI MOSFET-based LIF neurons. Also, it demonstrates spiking frequency of ~19.3 MHz, approximately ~105times higher than that of a biological neuron, controlled by the input voltage of the device, allowing the neuron adapt dynamically. The FNSFET technology offers superior electrostatic control, minimizing parasitic capaci-tances and facilitating rapid switching capabilities, thereby optimizing both power and performance simulta-neously.Furthermore, the effective area of the FNSFET amounts to 0.033 μ㎡ making it an appealing choice for low-power, area efficient, large-scale SNN applications.

## 1. Introduction

The rapid advancements in artificial intelligence (AI) and machine learning (ML) have spurred an interest in biologically inspired neural networks that aim to replicate the brain's high efficiency in computing. One such class is Spiking Neural Networks (SNNs), often regarded as the third generation of neural networks. Unlike conventional artificial neural networks (ANNs) that rely on continuous activation functions and involve heavy computational demands, SNNs incorporate the concept of neuronal spikes, enabling a more energy-efficient and bio-logically plausible form of computing. By mimicking the way neurons in the human brain communicate, SNNs have garnered significant atten-tion with current advancements in neuromorphic hardware, including brain-inspired chips such as Intel's Loihi and IBM's TrueNorth, which are being actively explored for real-world applications that demand low-latency and real-time processing [1,2]. Various models were proposed that includes the Izhikevich model [3], Hodgkin-Huxley model [4], Integrate and Fire model [5,6], and Leaky Integrate and Fire (LIF) model [7,8] to extend the biological accuracy of neuronal representations, providing researchers with tools to investigate intricate neuronal behavior. Among these, the LIF model is one of the most widely used due to its simplicity and effectiveness in capturing the key characteristics of biological neurons. The LIF neuron model simulates the dynamics of membrane potential, which integrates incoming spikes and leaks over time, resetting once a threshold is crossed. This provides an effective means to model neuronal behavior while avoiding excessive computa-tional complexity. Other models such as the Izhikevich model and Hodgkin-Huxley model have also been used to simulate spiking activity

* Corresponding author.

E-mail address: shreshtavalasa@gmail.com (S. Valasa).

https://doi.org/10.1016/j.neucom.2025.131814

Received 15 February 2025; Received in revised form 7 April 2025; Accepted 15 October 2025

Available online 16 October 2025

0925-2312/© 2025 Elsevier B.V. All rights are reserved, including those for text and data mining, AI training, and similar technologies.

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026)131814 -->

with higher levels of biological accuracy. However, these models came with increased computational overhead due to their complexity [9].

The implementation of SNNs started with the traditional CMOS cir-

cuits, and the CMOS-based transistors [7,10-13] have emerged as a primary candidate for constructing analog circuits capable of emulating neuronal dynamics. Emphasizing the advantages of neurons, analog-based implementations was found to be more efficient than digital ones, particularly regarding area and energy consumption [14, 15]. Various technologies have been utilized for hardware imple-mentations of SNNs, including silicon (Si) based CMOS transistor analog circuits, non-silicon devices like PCMO RRAM [16], and other ap-proaches [17,18]. Nonetheless, significant challenges remained in achieving the energy and area efficiency required for scaling to the high neuron densities observed in the human brain, which is approximately $10^{11}$ neurons [19]. Silicon-based two-terminal architectures have also been documented in the literature, including n-p-i-n diodes [20] and biristors [21] [22]. However, these designs require intricate circuitry to produce spikes and lack a control terminal, making it impossible to achieve neuron inhibition. Additionally, these structures incorporate a p-pocket in the channel, which imposes limitations on the downscaling of the device. Previous literature demonstrated that CMOS circuit-based LIF neurons encounter a major drawback in terms of leakage power [23]. In [24], an LIF neuron using PD-SOI MOSFET technology is showcased,which necessitates a drain bias of 2.8 V to generate sufficient current. Similarly, Chatterjee et al. [25] introduced a bulk FinFET-based LIF neuron that incorporates ann + buried layer to form a barrier for trapping excess charge carriers within the p-type body region. However, this enhancement lead to additional fabrication steps, complicating the process compared to conventional fabrication methods. Kamal et al. [26] have reported on the L-shaped bipolar impact ionization MOSFET (LBIMOS) as a viable LIF neuron for SNN implementations. This inno-vative LBIMOS design utilizes an internal current gain mechanism, enabling it to trigger II at low operating voltages, which is advantageous for enhancing energy efficiency in neural computations. Despite the advantages, the device fabrication process is notably complex. The requirement for additional masks to pattern the asymmetric source and drain regions complicates the overall manufacturing process, increasing the potential for production challenges. In previous implementations of FET-based LIF neurons, three primary challenges have been identified: 1. They necessitate a floating body to retain excess charge carriers, which limits the scaling of the silicon-on-insulator (SOI) film in the sub-nanometer range, 2. They require higher supply voltages and larger gate lengths, and 3. The stringent requirements for ultrasteep doping profiles at the source-channel and channel-drain metallurgical junc-tions, along with an elevated thermal budget to activate the dopants, hinder the scaling of FET-based LIF neuron devices in the sub-20 nm regime. To address the challenges associated with traditional FETs, recent research has focused on junctionless (JL) FETs [27,28] based LIF neuron. These transistors eliminate the need for metallurgical junctions, which simplifies the fabrication process and significantly reduces the thermal budget required for manufacturing. This streamlined approach offers benefits in terms of both cost and efficiency.

Conversely, modern portable consumer electronics such as micro-processors, smartphones, laptops, and medical devices rely on battery power, necessitating minimal energy consumption. The semiconductor industry is focused on optimizing device performance, which has led to the miniaturization of MOSFET sizes on chips [29]. However, these objectives encounter limitations due to various short-channel effects (SCEs) that adversely affect the low-power performance of MOS devices. The significant rise in both static and dynamic power consumption poses a considerable challenge for scaling MOSFETs [30,31]. In response, the Gate All Around (GAA) Lateral Nanosheet (LNS) FET provides enhanced control over the channel due to its design, which allows the gate to completely encircle the channel and offers improved electrostatic con-trol compared to traditional MOSFETs, DGFETs, and FinFETs [32,33]. Additionally, the stacked NSFET device presents a smaller effective area within a given footprint, facilitating higher integration density and potentially allowing for a reduction in overall chip size [34].However, a notable disadvantage of LNS is the substantial increase in effective capacitance caused by the overlap capacitance between the source/-drain (S/D) and the channel-to-channel spacing $\left(\mathrm {T}_{\mathrm {sp}}\right)$ . This increase oc-curs even as current drivability per unit area is enhanced compared to conventional FinFETs. Therefore, instead of adopting the GAA LNSFET, it is suggested to utilize a floating fin (F) shaped vertical NSFET in [35] to improve the power, performance, and area. Till date, the MOS device based LIF neurons were limited only to MOSFETs, DGFETs, and FinFETs. Therefore, motivated by the concept of FNS, in this manuscript for the first time, we introduce the concept of designing an energy-efficient LIF neuron based on a GAA FNSFET utilizing well-calibrated 3D TCAD simulations focusing on Impact Ionization (II) mechanism. The physical mechanisms within the device have been explained using the Shockley-Read-Hall (SRH) recombination and UniBo2 models by examining both transfer and transient characteristics. The key features of the proposed LIF neuron are as follows:

1. The GAA FNSFET demonstrates compatibility with CMOS fabrica-tion, precise electrostatic control, and scalability,making it an excellent option for low-power applications. Furthermore, the GAA channel eliminates the need for a floating body to store excess carriers.

2. The designed LIF neuuron based on FNSFET exhibits optimal energy consumption of 4.88 fJ per spike and a spiking frequency (~19.3 MHz) approximately $10^{5}$  times greater than that of biological neurons, representing the second lowest energy usage reported to date.

3. Additionally, the effective area of the device is only $0.033μ\mathrm {\;m}^{2}$ ,which is significantly smaller compared to previously reported CMOS-based LIF neurons. These advantageous characteristics posi-tion the proposed device for the high-density integration of neurons on a large scale.

## 2. Architecture of SNN

### 2.1. LIF neuron-model

The biological neuron serves as the essential component of the ner-vous system, facilitating the transmission of electrical impulses. It has three primary parts: the soma (cell body),axon, and dendrites, as illustrated in Fig. 1(a). Dendrites receive incoming signals from other presynaptic neurons and relay them to the soma. In turn, the axon transmits information away from the soma to other neurons or effector cells. At the synapse, the point of contact between neurons, neuro-transmitters are released, leading to excitation in the form of spikes to convey signals. The LIF model mimics ion movement across the cell membrane and includes a "leak" term to represent any disequilibrium within the cell, allowing it to closely reflect the behavior of biological neurons [36]. The fundamental structure of the LIF neuron consists of parallel capacitance and resistance circuits, depicted in Fig. 1(b) [37]. These circuits are designed to simulate the ion channels in the mem-brane,enabling pathways for charge flow.

When an arbitrary time-varying current $I_{in}(t)$  is introduced into the neuron, we get Eq. (1) based on Kirchhoff's current law:

$$\boldsymbol {I}(\boldsymbol {t})=\boldsymbol {I}_{\boldsymbol {R}}(\boldsymbol {t})+\boldsymbol {I}_{\boldsymbol {c}}(\boldsymbol {t})\tag{1}$$

Using Ohm's Law, the membrane potential measured between the interior and exterior of the neuron is directly proportiona1 to the current flowing through the resistor. Regarding the capacitive current, it cor-responds to the rate at which charge changes across the capacitor.By substituting these relationships, we can express the model dynamics as follows [24]:

<!-- 2 -->

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026) 131814 -->

<!-- Dendrites Cell Body $X_{1}$ (a) Axon terminal $x_{2}$ $Y_{1}$ $x_{n}$ Axon Inputs Outputs $Y_{2}$ $\cdots Y_{n}$ -->
![](https://web-api.textin.com/ocr_image/external/7ac1b775bdd82e01.jpg)

<!-- $C_{mem}$ S $I_{in}$ $R.$ G $0\mathrm {n}V_{\mathrm {c}}\geq V_{\mathrm {th}}$ $mem$ D $\overline {0\mathrm {ff}}V_{\mathrm {C}}&lt;V_{\mathrm {th}}$ $三$ -->
![](https://web-api.textin.com/ocr_image/external/8d5c83e9567ff08b.jpg)

<!-- $X_{1}$ $w_{1}$ (c) $X_{2}$ $w_{2}$ $X_{3}$ Σ LIF $w_{3}$ spike $X_{4}$ $w_{n}$ -->
![](https://web-api.textin.com/ocr_image/external/effde25176f53558.jpg)

Fig. 1. (a) Vizualization of typical biological neuron (b) LIF neuron along with the reset circuit, (c) typical model of a spiking neural network with an LIF neuron.

$$\boldsymbol {I}_{\boldsymbol {R}}(\boldsymbol {t})=\frac {\boldsymbol {V}_{\text {mem}}(\boldsymbol {t})}{\boldsymbol {R}_{\text {mem}}}\tag{2}$$

$$\frac {\mathrm {d}\boldsymbol {Q}}{\mathrm {\;d}\boldsymbol {t}}=\boldsymbol {I}_{\boldsymbol {C}}(\boldsymbol {t})=\boldsymbol {C}_{\text {mem}}\frac {\mathrm {d}\boldsymbol {V}_{\text {mem}}(\dot {\boldsymbol {t}})}{\mathrm {d}\boldsymbol {t}}\tag{3}$$

$$\boldsymbol {C}_{\text {mem}}\frac {\mathrm {d}\boldsymbol {V}_{\text {mem}}}{\mathrm {dt}}=\boldsymbol {I}(\boldsymbol {t})-\left(\frac {\boldsymbol {V}_{\text {mem}}-\boldsymbol {V}_{\text {reset}}}{\boldsymbol {R}_{L}}\right)\tag{4}$$

In this context, $\boldsymbol {V}_{\text {mem}}$  represents the membrane potential, $\boldsymbol {R}_{\text {mem}}$  de-notes the leaky resistance, $\boldsymbol {V}_{\text {reset}}$ refers to the resting membrane poten-tial, and $C_{\text {mem}}$  indicates the membrane capacitance. The inputs are multiplied by weights $\boldsymbol {W}_{n}$  and aggregated as shown in Fig. 1(c). When $\boldsymbol {V}_{\text {mem}}$  reaches the threshold $V_{th},$ the neuron produces a spike, after which the voltage resets to zero for a refractory period; these device parameters help limit the neuron's firing frequency. Additionally, effective man-agement of leakage in the LIF model is crucial, as an imbalance can lead to problems. If leakage is absent, $\boldsymbol {V}_{\text {mem}}$ stays static until activated. Conversely, a neuron with excessive leakage may fire erratically, even in response to slight delayed signals.

### 2.2. Design and scalability of the device

The 3D bird's eye view and 2D cross-sectional representations of the proposed GAA FNSFET, designed using the Sentaurus TCAD tool [39], is illustrated in Fig. 2(a) and Fig. 2(b), respectively. The design parameters utilized for constructing the device are detailed in Table 1, adhering to specifications outlined in the International Technology Roadmap for Semiconductors (ITRS) [40]. The gate length $\left(\mathrm {L}_{\mathrm {g}}\right)$ and FNS height ( $\left.\mathrm {H}_{\mathrm {FNS}}\right)$ )is set to 100 nm and 90 nm respectively. The FNS thickness $\mathrm {T}_{\mathrm {NS}}$  is varied to get the better aspect ratio. Additionally, a silicon dioxide $\mathrm {SiO}_{2}$ oxide layer with a thickness of 2 nm, known for its high thermal sta-bility, is deposited on the channel. To reduce punch through or drain-induced barrier lowering (DIBL), it is essential to create a sharp p-n junction in the source/drain (S/D) regions. The device incorporates boron (p-type) and arsenic (n-type) dopants in the channel and S/D areas,with concentrations of $1\times 10^{16}/\mathrm {m}^{3}\mathrm {f}$ or boron and $1\times 10^{20}/\mathrm {m}^{3}$ for arsenic. Utilizing a channel region with lighter doping results in a notable enhancement of the ON current while minimizing the sub-threshold swing.

A variety of models are integrated into the TCAD setup to investigate the characteristics of integration, firing, and leakage. These models include Lombardi and Philips unified mobility models, Shockley-Read Hall (SRH) recombination, the Unibo2 impact ionization (II) model, Fermi-Dirac carrier statistics, and Auger recombination models. Detailed explanations of these models are available in our previous work [41,42],with the Unibo2 II model discussed in further detail in subse-quent sections. The simulation framework utilized in this research is thoroughly calibrated against the work of N. Loubet et al., [38] achieving a close match through careful adjustments of velocity satu-ration, mobility, source/drain resistances, and metal work function, as illustrated in Fig. 2(d).

The procedural flow for examining the characteristics of the LIF neuron utilizing the designed device is depicted in Fig. 3. The reset circuitry proposed for the FNSFET device based on the LIF neuron is illustrated in Fig. 2(c). The neuron receives pulses of input current $\left(\mathrm {I}_{1},\mathrm {I}_{2},\right.$ $\text {IN}$ ) from a pre-synaptic neuron, which are converted into a voltage $\left(V_{IN}\right.$  through a current-to-voltage (I-V) converter. This voltage is then applied to the

When $V_{IN}$ reaches the threshold voltage $Vth,$ a comparator triggers a reset of the drain terminal, resulting in the generation of output spikes. The input biasing system, which utilizes voltages $V_{DG}$ and $V_{SG},$ along with the output spike response characterized at various time instances: $t_{1}$  (equilibrium), $t_{2}$ (leaky integration), $t_{3}$  (fire), and $t_{4}$  (reset), is shown in Fig. 4. Typically, the kink effect arises from the impact ionization (II) process, where intense electric fields within the channel provide carriers with adequate energy to create electron-hole pairs. The likelihood and

<!-- 3 -->

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026) 131814 -->

(a) (b)

<!-- Spacers Gate Drain Source BOX -->
![](https://web-api.textin.com/ocr_image/external/2c7dff2d7e99ee61.jpg)

<!-- Gate $SiO_{2}$ Channel -->
![](https://web-api.textin.com/ocr_image/external/e7bbc8a29407af31.jpg)

<!-- (c) 、 $w_{1}$ $I_{1}$ $\overline {\mathbf {w}_{2}}$ $\mathrm {I}_{2}$ $\mathbf {I}_{\mathbf {n}}$ T $\overline {\mathbf {w}_{\mathbf {n}}}$ $V_{SG}$ $s$ D $V_{\text {ref}}$ $in$ $-$ $I_{in}R$ S 1 $R_{1}$ $-V_{cc}$ $\mathbf {V}_{\mathbf {o}}$ omparator $\mathbf {R}_{2}$ $-V_{ee}$ 4747 -->
![](https://web-api.textin.com/ocr_image/external/b37de2ddc0dbe8d0.jpg)

<!-- (d) $1E-4$ Experimental data TCAD data 1.8E-4 1E-5 1.5E-4 A 1E-6 $L_{g}=12nm$ 1.2E-4 $1E-7$ $T_{NS}=5\mathrm {\;nm}$ $\log \left(\mathrm {I}_{\mathrm {D}}\right)$ 9.0E-5 1E-8 $1_{\mathrm {D}}(AA)$ $V_{\mathrm {DS}}=0.7\mathrm {\;V}$ 6.0E-5 $1E-9$ $1E-10$ 3.0E-5 1E-11 $0.0E+0$ 0.0 0.1 0.2 0.3 0.4 0.5 0.6 $V_{GS}(V)$ -->
![](https://web-api.textin.com/ocr_image/external/f6e5aaf7162d04fe.jpg)

(e)

<!-- Substrate preparation (a) (b) Z Substrate SiGe formation followed by Si channel (a) SiGe Selective etching and Fin Formation (b) (c) Si channel Dummy gade formation (c) S/D etching Spacer material Inner spacer formation (e) (e) (f) Dummy gate Source/drain epltaxial growth Gate Oxide SiO2 Dummy gate removal SIGe Selective etch (f) Metal gate Gate oxide deposition (e) S/D contact metal Metal gate deposition (e) x-cut view Contact formation+MI BEOL (HAn9) -->
![](https://web-api.textin.com/ocr_image/external/4d8cfc1b0e396891.jpg)

Fig. 2. (a) 3D view (b) 2D view (c) reset circuitry of the proposed device (d) calibration with experimental data [38] (e) Fabrication feasibility of the proposed FNSFET device.

**Table 1**

Parameter specification of the designed GAA FNSFET.


| Parameter | Value |
| --- | --- |
| Gate Length $\left(\mathrm {L}_{\mathrm {G}}\right)$ | 100nm |
| Gate Oxide Thickness $T_{OX}$ | 2nm |
| Fin Height $\left(\mathrm {H}_{\mathrm {FNS}}\right)$ | 90nm |
| Fin thickness $\left(\mathrm {T}_{\mathrm {FNS}}\right)$ | 15nm<br>$1\times 10^{16}/\mathrm {cm}^{3}$ |
| Channel p-Doping (Boron) | $1\times 10^{20}/\mathrm {cm}^{3}$ |
| Source/Drain n-Doping (Arsenic) |  |
| Sheet Silicide Resistivity | $7.5Ω/sq.$ |
| Gate Metal Work Function | 4.6 eV |
| Contact Resistivity | $7Ω.μ\mathrm {\;m}^{2}$ |


effectiveness of impact ionization are highly influenced by the local electric field present in the channel.

The impact of varying TFNs on the kink effect in the output charac-teristics is illustrated in Fig. 5(a). It is evident that the kink effect is mmore pronounced in the proposed LIF neuron based on FNSFET with increase in $\mathrm {T}_{\mathrm {FNS}}$ . This is because greater $\mathrm {T}_{\mathrm {FNS}}$  supports a stronger vertical electric

<!-- No Optimizing Assessment of Adequate to the device minimal Drain achieve sufficient Impact lonization dimensions Bias $Yes$ spike Analysis of generation minimum $V_{th}$ Transient Analysis and Ith $\mathbf {I}_{\mathrm {th}}$ -->
![](https://web-api.textin.com/ocr_image/external/3e11ff6b2ebaf207.jpg)

Fig. 3. Procedural flow for spike generation of LIF neuron based NSFET.

field, potentially increasing the region available for impact ionization, allowing carriers more space to gain energy and ionize.Additionally, larger thickness contributes to a more even vertical electric field

<!-- 4 -->

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026)131814 -->

<!-- $V_{DG}$ (とaiealoA $(a)$ $t_{1}$ $t_{2}$ $t_{3}$ $t_{4}$ time $V_{SG}$ -->
![](https://web-api.textin.com/ocr_image/external/262430844302810c.jpg)

<!-- $I_{th}$ $t_{3}$ Juoino meO (b) $t_{2}$ $t_{1}$ $t_{4}$ time -->
![](https://web-api.textin.com/ocr_image/external/aaba45b1af8156fc.jpg)

Fig. 4. (a) Input bias as a functionof time, (b) corresponding output spike response at various time instances: $_{1}$ (equilibrium), $t_{2}$ (leaky integration), $t_{3}$ (fire),and $t_{4}$ (reset).

**(a)**

<!-- 1000 $T_{FNS}=10nm$ $T_{FNS}=15nm$ 800 $T_{FNS}=30nm$ $T_{FNS}=40nm$ $\mathrm {T}_{\mathrm {FNS}}=50$ $nm$ 600 $\mathrm {T}_{\mathrm {DS}}(\mathrm {μA})$ $400$ 200 $V_{GS}=2V$ $H_{FNS}=90nm$ 0 0.0 0.5 1.0 1.5 2.0 $V_{DS}(V)$ -->
![](https://web-api.textin.com/ocr_image/external/aebf0ce74e3e46fa.jpg)

**(b)**

<!-- 600 $V_{GS}=1V$ $-V_{GS}=1.2V$ $V_{GS}=1.4V$ $V_{GS}=1.6V$ 500 $V_{GS}=1.8V-$ $-V_{GS}=2V$ 400 $\mathrm {T}_{\mathrm {DS}}(\mathrm {μA})$ 300 200 100 0 0.0 0.5 1.0 1.5 2.0 $V_{DS}(V)$ -->
![](https://web-api.textin.com/ocr_image/external/631a58d3d63d648a.jpg)

Fig.5. Output characteristics of FNSFET showing kink effect for device optimization (a) Variation of $\mathrm {T}_{\mathrm {FNS}}$  atHF $\mathrm {FNS}=90$ nm (b) Variation of $\mathrm {V}_{\mathrm {GS}}$  at optimal dimension source terminal of the FNSFET.

distribution, enhancing the II process and thereby benefiting the inte-gration functionality of the LIF neuron. However, focussing the Fig. 5(a), the kink effect is properly observed starting at $\mathrm {T}_{\mathrm {FNS}}=15$ nm itself. Therefore, the $\mathrm {T}_{\mathrm {FNS}}$ is fixed at 15 nm for further analysis. Moreover, at these optimal dimensions i.e., $\mathrm {L}_{\mathrm {g}}=100$ nm, $\mathrm {H}_{\mathrm {FNS}}=90$  nm,and $\mathrm {T}_{\mathrm {FNS}}$ $=1$ 5 nm, the operating voltage( $\left(V_{GS}\right)$ of the device is adjusted to identify the conditions under which the kink effect is most effectively observed (Fig. 5(b)). A notable increase in the drain current is observed in the device's output characteristics beginning at $V_{GS}=1V,$ which represents the minimum voltage required to initiate the impact ionization effect necessary for neuronal behavior.

### 2.3. Tuning of impact ionization parameters

To replicate the neuron model, a small negative voltage is applied to the source. At a designated time $\left(t_{1}\right)$  , a high voltage is introduced to the drain, as illustrated in Fig. 4. The application of this high drain voltage generates a significant electric field at the gate-drain junction. In such circumstances, the overall current traversing the device can be viewed as the combination of two components: inst, which denotes the current that flows through the device under typical operating conditions without II, and ss, representing the current produced by II, occurring close to the drain due to the intense electric field. The Impact ionization (II) occurs when high-energy charge carriers (electrons and holes) gain sufficient kinetic energy from the electric field and collide with atoms in the drain region. This process leads to the formation of additional electron-hole pairs, thereby enhancing current flow. The FNSFET ex-hibits the characteristics of the LIF neuron by engaging the II mecha-nism, commonly referred to as avalanche generation, which requires a distinct threshold of field strength alongside the potential for accelera-tion, typically observed in wide space charge regions. When the width of the space charge region surpasses the average free path between ioni-zation events,charge multiplication occurs, which can result in elec-trical breakdown. This conventional II process is expressed as follows:

$$G=\frac {1}{q}\left(α_{n}\overrightarrow {\left|J_{n}\right|}+α_{p}\overrightarrow {\left|J_{p}\right|}\right)\tag{5}$$

where $G^{\prime }$  is the electron-hole pair generation rate, $α_{n}$ and $α_{p}$ are carrier ionization co-efficients, and $\overrightarrow {\left|J_{n}\right|},\overrightarrow {\left|J_{p}\right|}$  are the electron, hole current densities.

To comprehend and forecast the performance of the LIF neuron structured FNSFET, we have integrated the "New University of Bologna" II model,which accurately reflects the influence on device functionality even under elevated lattice temperatures. This model can simulate II behavior across a wide spectrum of electric fields. The equation that characterizes this model is presented as follows:

$$\boldsymbol {α}\left(\boldsymbol {F}_{\text {ava}},\boldsymbol {T}\right)=\frac {\boldsymbol {F}_{\text {ava}}}{\boldsymbol {a}(\boldsymbol {T})+\boldsymbol {b}(\boldsymbol {T})\boldsymbol {\exp }\left[\frac {\boldsymbol {d}(\boldsymbol {T})}{\boldsymbol {F}_{\text {ava}}+\boldsymbol {c}(\boldsymbol {T})}\right]}\tag{6}$$

Here, the coefficients a, b, $C$ , d are temperature dependent poly-nomials of lattice temperature $'T'$  and given by:

$$\boldsymbol {a}(\boldsymbol {T})=\sum _{k=0}^{3}\quad \boldsymbol {a}_{k}\left(\frac {\boldsymbol {T}}{\mathbf {1}\boldsymbol {K}}\right)^{k}\tag{7}$$

<!-- 5 -->

Y.Bhatawdekar et al.

#### Neurocomputing 659 (2026)131814

$$\boldsymbol {b}(\boldsymbol {T})=\sum _{k=0}^{3}\quad \boldsymbol {b}_{k}\left(\frac {\boldsymbol {T}}{\mathbf {1}\boldsymbol {K}}\right)^{k}\tag{8}$$

$$\boldsymbol {c}(\boldsymbol {T})=\sum _{k=0}^{3}\quad \boldsymbol {c}_{k}\left(\frac {\boldsymbol {T}}{\mathbf {1}\boldsymbol {K}}\right)^{k}\tag{9}$$

$$\boldsymbol {d}(\boldsymbol {T})=\sum _{k=0}^{3}\quad \boldsymbol {d}_{k}\left(\frac {\boldsymbol {T}}{\mathbf {1}\boldsymbol {K}}\right)^{k}\tag{10}$$

In the simulation configuration, we have incorporated bandgap dependence as a factor in Avalanche, which allows for the remod-ification of d(T) to:

$$\boldsymbol {d}(\boldsymbol {T})\rightarrow \left(\frac {\boldsymbol {\beta }\boldsymbol {E}_{g}}{\boldsymbol {q}λ}/\boldsymbol {d}_{0}\right)\sum _{k=0}^{3}\boldsymbol {d}_{k}\left(\frac {\boldsymbol {T}}{\mathbf {1}\boldsymbol {K}}\right)^{k}\tag{11}$$

where $\beta =$ proportionality constant, $\boldsymbol {E}_{g}=\text {bandgap},$ $λ=\text {carrier}$  optical-phonon mean freepath

By appropriately adjusting these parameters, the rate of 'II' is enhanced. The holes generated from 'II' become concentrated in the channel potential well, closely resembling the integration process in the LIF neuron. As electrons move toward the drain end, there is a sudden spike in the drain current, causing the output characteristics to notice-ably kink, indicating the accumulation of additional holes.

At the initial time point, where $\mathrm {t}=\mathrm {t}_{1},$ ,with $V_{DG}=0\mathrm {\;V},$ the barrier potential of the channel is significantlyy high, as shown in Fig. 6(a). Under these conditions, the injection of electrons from the source to the drain is minimal, resulting in low II and an insignificant ID. Additionally, the concentration of extra holes within the channel region is very low. As time progresses to $\mathrm {t}=\mathrm {t}_{2},$ the potential barrier in the channel decreases compared to t1, as illustrated in Fig. 6(b). This change leads to an increased flow of electrons from the source to the drain.

When the drain region is reached, the reverse bias across the drain junction becomes sufficiently strong to initiate II, resulting in the accumulation of holes in the potential well. This leads to an increase in $\mathrm {I}_{\mathrm {D}}$ . Moreover, the accumulation of holes in the potential well reduces the barrier between the source and the channel. Consequently, the LIF neuron-based FNSFET exhibits leaky behavior as some holes migrate across the channel to the source region. This phenomenon initiates positive feedback.

Additionally, due to this positive feedback, the potential barrier continues to diminish over time, moving toward $\mathrm {t}=\mathrm {t}_{3}$ (Fig.6(b)).This decline results in a higher concentration of excess holes in the channel, leading to an increase in current flow. This higher $\mathrm {I}_{\mathrm {D}}$  eventually reaches the threshold level $\mathrm {I}_{\mathrm {th}}$ triggering the firing of the LIF neuron, followed by a rapid reset. At this point, the loss of stored holes in the channel region of the FNSFET LIF neuron becomes apparent. Consequently,ID decreases due to hole recombination occurring within the channel re-gion of the FNSFET at the time instance $\mathrm {t}=\mathrm {t}_{4}$  (Fig. 6(a)). This process culminates in the reset of the LIF neuron-based NSFET. This behavior is crucial in neuromorphic computing applications, where precise control of charge accumulation and dissipation is essential for energy-efficient spike generation.

## 3. Results and discussion

The proposed FNSFET demonstrates adequate 'II' and generates excess carriers at low $V_{D},$ which is an essential attribute for imple-menting LIF neurons based on silicon devices. To enhance neuronal functionality, the optimization of the coefficients in the "New University of Bologna $II"$ model (as indicated in Eq. (5)) relies on the structure of the device to ensure convergence in TCAD simulations. In this context, the parameter $d(T)$ within the TCAD setup is highly significant and has a substantial impact on device performance. Fig. 7(a) illustrates a wide range of variations in the coefficients $do\_e$ and d0h, which vary from $1\times 10^{5}-9\times 10^{6}$ where e and h denote electron and hole character-istics, respectively. Once the parameters are optimally adjusted,as demonstrated in Fig. 7(a), the coefficients for the II model are defined to establish the threshold point, indicated by a sharp change in drain current. Since biological neurons exhibit significantly lower ID during output spikes [43], the minimal current associated with II, necessary for neuron firing, is set at $1\times 10^{6}$ . The drain bias also has a crucial impact on the device's energy consumption; thus, a variation of $\mathrm {I}_{\mathrm {D}}$  for $V_{}$ ranging from 0.6 V to 1.4 V is analyzed for both with and without II, as shown in Fig. 7(b).

Notably, all voltage levels demonstrate sharp increases in current with the II model; however, it is essential to reduce $V_{D}$ for lower energy consumption.Therefore, $V_{D}$ has been optimally set at 1.0 V, which en-sures sufficient 'II' and is significantly lower than the drain bias reported in Table 2. By observing a sharp change in the slope of the drain current as a function of $\mathrm {V}_{\mathrm {SG}}$ in Fig. 7(b), the threshold voltage $V_{th}$ is manually established at $-0.244V$ , with the corresponding $\mathrm {I}_{\mathrm {th}}$  observed to be 94 nA. This threshold is adequate for neuron firing. When $\left|V_{SG}\right|<\left|V_{th}\right|,$ $\mathrm {I}_{\mathrm {D}}$  is unable to reach $\mathrm {I}_{\mathrm {th}}$ . Conversely,when $\left|V_{SG}\right|$  exceeds $\left|V_{th}\right|$ ,the time required to reach $I_{\text {th}}$ decreases. As a result, the spike frequency increases with higher input levels, mirroring the behavior of biological counter-parts in the LIF neuron RC circuit model. A key aspect of modeling a silicon FET device as a LIF neuron is understanding how $\mathrm {I}_{\mathrm {D}}$  varies over time at different $V_{SG}$ values. Therefore, the relationship between $\mathrm {I}_{\mathrm {D}}$  and time for various $V_{SG}$ values is investigated while maintaining a fixed $V_{D}$ 

(a)

(b)

<!-- 1.00 0.75 $\mathbf {E}_{\mathrm {C}}$ $\mathbf {I}_{\mathbf {D}}$ 0.50 $\mathbf {E}_{\mathbf {V}}$ No Imapct Ionization(II) (e) Faiau3 0.25 0.00- $t_{1}\&t_{4}$ -0.25 Source Channel Drain -0.50 -0.75 -1.00 -0.3 $-0.2$ $-0.1$ 0.0 0.1 0.2 0.3 Position along x-axis (μm) -->
![](https://web-api.textin.com/ocr_image/external/51824dcf08dfe036.jpg)

<!-- 0.5 $\mathrm {I}_{\mathrm {D}}$ $=$ 0.0 $\mathbf {E}_{\mathbf {C}}$ $\mathbf {t}_{2}$ $\mathrm {t}_{3}$ $-0.5$ $\mathbf {V}_{\mathrm {SG}}$ $\mathbf {I}_{\mathrm {ii}-\mathrm {e}}$ GJau3 $-1.0$ $\mathbf {E}_{\mathrm {V}}$ $\mathrm {I}_{\text {leak-h}}$ $-1.5$ $V_{D}=1.0V$ $-2.0$ $\mathbf {I}_{\mathrm {ii}-\mathrm {h}}$ $8$ $-0.3-0.2-0.1$ 0.0 0.1 0.2 0.3 Position along (μm) $x-axis$ -->
![](https://web-api.textin.com/ocr_image/external/a8a06237d4aac165.jpg)

**Fig.6.** Energy band diagram along the device at various time intervals which are indicated in Fig. 4. (a) For time intervals $\mathrm {t}_{1}\mathcal {S}\mathrm {t}_{4}$ with $\mathrm {t}_{1}$  being the initial time point and $\mathrm {t}_{4}$  showcasing the reset (b) time intervals $\mathrm {t}_{3}{}^{2}\mathrm {t}_{4}$  where II is shown with integrate and fire mechanisms.

<!-- 6 -->

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026) 131814 -->

**(a)** **(b)**

<!-- 100 $1\times 10^{5}-$ $-2\times 10^{5}$ 80 $5\times 10^{5}$ $-8\times 10^{5}$ $1\times 10^{6}$ $-2\times 10^{6}$ $5\times 10^{6}$ $-7\times 10^{6}$ 60 $9\times 10^{6}$ without II $\mathrm {T}_{\mathrm {DS}}(\mathrm {μA})$ $40$ 20 0 $-0.5$ $-0.4$ $-0.3$ -0.2 -0.1 0.0 $V_{SG}$ (V) -->
![](https://web-api.textin.com/ocr_image/external/33afe41fde254183.jpg)

<!-- 120 $-V_{D}=0.4V=V_{D}=0.6V$ 100 $V_{D}=0.8V=$ $-V_{D}=1.0V$ （三） $V_{D}=1.1V=V_{D}=1.2V$ $V_{D}=1.3V-V_{D}=1.4V$ 80 $V_{D}=0.4V-V_{D}=0.6V$ $V_{D}=0.8V$ $V_{D}=1.0V$ TuaJino ueO 60 $V_{D}=1.$ $V_{D}=1.2V$ $V_{D}=1.3$ $V_{D}=1.4V$ 40 without 20 0 $-0.5$ $-0.4$ $-0.3$ $-0.2$ $-0.1$ 0.0 $V_{SG}$ (V) -->
![](https://web-api.textin.com/ocr_image/external/dc1769b74ab2207b.jpg)

Fig.7. (a)Variation of $I_{D}$ for different values of $d_{0_{h}}$  and $d_{0_{e}}$  parameters of 'Unibo2 II' model where e and h denote electron and hole characteristics, respectively. (b)Comparison of drain current $I_{D}$  for with and without 'Unibo2 II' model for different $V_{D}$ The minimal current associated with II, necessary for neuron firing, is set at $do\_e$  and d0 $\mathrm {h}=1\times 10^{6}$ due to neuronal firing sufficiency. The threshold voltage $\left(V_{\text {th}}\right)$ is manually set here in this phase.

**Table 2**

Benchmarking of the designed LIF neuron with state-of-art simulation and experimental results.

State-of-art simulation results comparison


| Device | $\mathbf {L}_{\mathrm {g}}$(nm) | $V_{th}(V)$ | Spiking frequency(Hz) | Area | Energy/spike | $V_{DS}(V)$ |
| --- | --- | --- | --- | --- | --- | --- |
| CMOS [44] | 65 nm node |  | 1.9 MHz | 538 $μ\mathrm {m}^{2}$ | $4.13\times 10^{-11}$ | scalable till 20 nm ITRS |
| CMOS [14] | 800 | $>1$ | 200 Hz | $1.6\mathrm {\;mm}^{2}$ | $9\times 10^{-10}$ | 3.3V |
| CMOS [45] |  |  | 1 MHz | $70\times 40\mu \mathrm {\;m}^{2}$ | $8\times 10^{-12}$ | . |
| CMOS [46] | 90 |  | 100 KHz |  | $4\times 10^{-13}$ |  |
| Phase Change CMOS [17] |  | $>1$ | 10 Hz-10MHz | To be written | $3\times 10^{-11}$ |  |
| DG-JLFET [27] | 20 | 0.31 | 100 MHz |  | $1.14\times 10^{-12}$ | 1.2V |
| Bulk FinFET [25] | 100 | 0.6 | 1.9 MHz | $0.04μ\mathrm {\;m}^{2}$ | $6.3x10^{-15}$ | 3V |
| Silicon Nanowire [47] |  | 1.5 | 20 KHz |  | $2.9\times 10^{-15}$ |  |
| LBIMOS [48] | 90 | 0.2 | 0.5 GHz |  | $1.8\times 10^{-13}$ | 2.1V |
| PCMO RRAM [16] |  |  | 1 MHz | $5\times 5\mu \mathrm {\;m}^{2}$and scalable $0.8μ\mathrm {\;m}^{2}$ | $1\times 10^{-11}$ $3.22x10^{-15}$ | 2.3V |
| BTBT based neuron [49] | 40 | . | 150 KHz |  |  |  |
| FBFET [50] | 1000 |  | 200 Hz | $52\mathrm {\;F}^{2}$ | $2.5\times 10^{-13}$ |  |
| SB MOSFET [51] | 180 | 4.5 | 50-275 Hz |  | $4\times 10^{-12}$ |  |
| Trench bipolar IMOS [52] | 75 | 0.16 | ~MHz | $0.056μ\mathrm {\;m}^{2}$ | $0.35\times 10^{-12}$ | 1.8V |
| Finfet [53] | 11 |  | 222.27 MHz |  | $0.0281x10^{-15}$ | 0.5V |
| SiGe-MOSFET [54] | 400 | 0.4 |  | $0.564μ\mathrm {\;m}^{2}$ | $3.8\times 10^{-12}$ |  |
| L DG BIMOS [55] | 90 | 0.2 | 500 GHz |  | $0.1050x10^{-12}$ | 1.5V |
| SiGe source TFET [56] | 50 | 0.2 | 9 THz |  | $177\times 10^{-21}$ |  |
| $\mathrm {In}_{0.95}\mathrm {Ga}_{0.05}\mathrm {As}\text {MOSFET}$ [57] | 300-700 | 1.06 | 0.26 MHz-0.62 MHz |  | $7.11\times 10^{-12}$ $196\times 10^{-18}$ |  |
| strained Bipolar Charge Plasma Transistor [58] | . | 0.84 | 12 GHz |  |  |  |
| GaSb/Si TFET [59] | 20 | 0.47 | 534 GHz |  | $0.748\times 10^{-18}$ | 0.2V |
| SiGe resistive switching transistor [60] |  | . | 350 KHz |  | $0.36\times 10^{-12}$ |  |
| State-of-art experimental results comparison |  |  |  |  |  |  |
| Device | $\mathbf {L}_{\mathrm {g}}$ (nm) | Vth(V) | Spiking frequency(Hz) | Area | Energy/spike | $V_{DS}(V)$ |
| CMOS [15] | 65 |  | 26 KHz |  | $4\times 10^{-15}$ | 200mV |
| SOI CMOS [24] | 100 | 0.26 | 20 MHz | $1.8μ\mathrm {\;m}^{2}$ | $3.5\times 10^{-11}$ | 2.8V |
| MOSFET [61] | 880 | 1 | 20 Hz | 6 $\mathrm {F}^{2}$ | $45\times 10^{-12}$ | 2V |
| Biristor [21] |  | . | 2 KHz | $4\mathrm {\;F}^{2}$ | $5.68\times 10^{-12}$ |  |
| FeFET [62] | 80 |  | 80 Hz |  |  | $2.4\mathrm {\;V}-2.8\mathrm {\;V}$ |
| CMOS [63] | 180 | 1.4 |  | $3.6\mathrm {\;mm}^{2}$ | $900\times 10^{-12}$ | 1.8V |
| CMOS [64] | 180 |  | 3.7 Hz | $168\mathrm {\;mm}^{2}$ | $941\times 10^{-10}$ |  |
| CMOS [65] | 65 |  | 120 KHz | $3.6\mathrm {\;mm}^{2}$ | $790\times 10^{-12}$ |  |
| Proposed FNSFET based LIF neuron |  | 0.244 | 19.3 MHz |  |  |  |
| This work | 100 | 0.244 | 19.3 MHz | 0.033 $μ\mathrm {m}^{2}$ | $4.88x10^{-15}$ | 1.0V |


of 1.0 V, as depicted in Fig. 8. It is clear that when $\left|V_{SG}\right|<0.244\text {,the}$ drain current $\mathrm {I}_{\mathrm {D}}$  does not reach the threshold current $\mathrm {I}_{\mathrm {th}}$ of 94 nA, as the voltage applied is inadequate for sufficient II. Furthermore, at $\left|V_{SG}\right|$ $=-0.$ $.31$ $V,$  the potential barrier diminishes, prompting an immediate rise $\text {in}I_{D}$ , as shown in the enlarged section of Fig. 8(b). When ID increases and meets $I_{th}=94$ $nA)$ at $V_{SG}=-0.$ $.244V,$ this specific $\mathrm {V}_{\mathrm {SG}}$ is referred to as the threshold voltage $V_{th}$ for the LIF neuron-inspired FNSFET. Under conditions where $\left|V_{SG}\right|>\left|V_{th}\right|,$ electrons flow from the source to the drain region. Due to the intense electric field present at the drain-channel interface, electrons gain enough energy, resulting in sufficient II. The created electron-hole pairs move toward the drain, and the accumulation of holes in the potential well reduces the barrier between the source and channel, leading to hole leakage back to the source. This behavior illustrates the leakage traits of the FNSFET designed for the LIF neuron.For $\left|V_{SG}\right|<\left|V_{th}\right|,$ spikes are not produced because ID stabilizes before reaching $\mathrm {I}_{\mathrm {th}}$ .However,when $\left|V_{SG}\right|\geq 0.$ 244 V,the $\mathrm {I}_{\mathrm {D}}$  achieves $\mathrm {I}_{\mathrm {th}}$ 

<!-- 7 -->

### Y.Bhatawdekar et al.

### Neurocomputing 659 (2026) 131814

**(a)** **(b)**

<!-- 0.4 $\mathbf {V}_{\mathrm {SG}}=-0.2\mathrm {\;V}$ () $V_{SG}=-0.225V$ $V_{SG}=-0.24V$ 0.3 $V_{SG}=-0.245V$ $\mathbf {V}_{\mathrm {SG}}=-0.25\mathrm {\;V}$ 1uaJJno ueO $V_{\mathrm {SG}}=-0.26\mathrm {\;V}$ 0.2 $V_{\mathrm {SG}}=-0.27\mathrm {\;V}$ $V_{SG}=-0.28V$ 0.1 $I_{th}=94nA$ 0.0 0 1 2 3 4 5 Time(μS) -->
![](https://web-api.textin.com/ocr_image/external/259b093fa748e2f5.jpg)

<!-- 0.4 （三）uaJ.Jno ueAO 0.3 0.2 0.1 0.0 1.00 1.02 1.04 1.06 1.08 1.10 Time (μS) -->
![](https://web-api.textin.com/ocr_image/external/ced720515407eeee.jpg)

**Fig.** 8. (a) Time taken by the current to reach $\mathrm {I}_{\mathrm {th}}$ value for different $V_{SG}$ with $V_{D}$  being optimally set at 1.0 V, which ensures sufficient 'II' with $V_{th}$ established at -0.244 V,with the corresponding Ith observed to be 94 nA (b) Transient Analysis of $I_{D}$ with various $V_{SG}$ at $V_{D}$  of 1.0 V which is a zoomed in version of Fig. 8(a) shown for better visuality.

(indicating leaky integration), and once it surpasses $\mathrm {I}_{\mathrm {th}}$  a spike occurs (known as firing). This mechanism is visualized in Fig. 9(a) and is fol-lowed by resetting $V_{D}$  to 0 V, which is commonly termed the refractory period (typically lasting a few microseconds). After this refractory in-terval, the current resumes from the starting potential when $V_{D}$  is restored to 1.0 V during each reset cycle. This restarts the spike cycle, as illustrated in Fig. 9(b), with spikes occurring every 180 ns under the specified biasing conditions.

Similar to biological systems, where incoming signals from presyn-aptic neurons affect the firing rate (spikingfrequency), the spiking fre-quency of the proposed LIF neuron based on NSFET is similarly influenced by the applied input signal $V_{SG}.$  The spiking frequency attained by the designed LIF neuron falls within the MHz range, rendering it suitable for effective hardware acceleration in neuro-morphic computing. The maximum energy per spike for the proposed LIF neuron-based NSFET is calculated using the following equation $[27]$ :

Energy/Spike= $V_{D}\mathrm {x}I_{th}\mathrm {x}t_{\text {spike}}$  (12)

where $\mathrm {V}_{\mathrm {D}}=1.0\mathrm {\;V},\mathrm {I}_{\mathrm {th}}=94$ $nA,$ $\mathrm {t}_{\text {spike}}=52$ ns which produces a energy/ spike of 4.88 fJ which is much less than the other reported LIF neuron based nano-scaled devices as shown in Table 2. Moreover, the minimum drain voltage $V_{D}$ required for spike generation in the proposed neuron is much lower compared to various device-based neurons documented in existing literature. The comparative study clearly shows that the proposed LIF neuron can produce spikes with a significantly reduced $V_{D}$ than other devices. Lastly, to enhance overall area efficiency,nanoscale devices play a vital role in integrated functional blocks. Although there are several energy-related challenges associated with constructing the reset circuit, these issues can be mitigated using strategies that are comprehensively discussed in [49]. Consequently, the designed GAA FNSFET can serve as a substitute for the leaky integration function of the LIF neuron, ensuring optimal energy and area efficiency.

## 4. Challenges in device design and potential applications

### 4.1. Variability and scalability concerns

The impact ionization is sensitive to doping and device dimensions, hence the potential device-to-device variability and scaling challenges for sub-100 nm implementations is discussed in short here. The pro-posed GAA FNSFET structure inherently mitigates some of these con-cerns due to its superior electrostatic control and reduced short-channel effects (SCEs) compared to planar and FinFET-based designs. To further minimize variability in the proposed device, the following strategies can be employed: (a) Optimized Doping Engineering: Precise doping con-centration control through advanced techniques such as atomic-layer doping (ALD) can reduce fluctuations in impact ionization rates. (b) Strain Engineering: Strain-induced bandgap modulation can be lever-aged to maintain uniform carrier transport properties across multiple

(a) (b)

<!-- 105 90 $V_{D}=1V$ 75 $V_{\mathrm {SG}}=-0.244\mathrm {\;V}$ (FE) 1uaiinOueiO 60 Energy/Spike $e=4.88fJ$ 45 30 15 0 0.0 0.5 1.0 1.5 2.0 2.5 3.0 Time(μS) -->
![](https://web-api.textin.com/ocr_image/external/515ac9b5f5994484.jpg)

<!-- 100 $\mathrm {VSG}=-0.25\mathrm {\;V}$ 80 (PE)1uanOueAO 60 40 20 0 0 1 2 3 4 Time (μS) -->
![](https://web-api.textin.com/ocr_image/external/fea3efc3a564447a.jpg)

Fig. 9. (a)Single spike implementation at $V_{SG}=V_{D}=-0244V$ with energy/spike noticed to be 4.88 fJ, (b) multiple spike production at $V_{SG}=-0.25\mathrm {\;V}$ $V_{D}=1.0V.$ 

<!-- 8 -->

<!-- Y.Bhatawdekar et al. Neurocomputing 659 (2026) 131814 -->

devices. (c) Process-Induced Variability Mitigation: Advanced lithog-raphy techniques, such as extreme ultraviolet (EUV) lithography, and self-aligned gate processes can reduce variations in critical dimensions and doping profiles. Additionally, extensive TCAD-based Monte Carlo simulations can be performed to statistically model the expected vari-ations and optimize device design parameters to minimize performance deviations.

While GAAFET technology is CMOS-compatible and has seen sig-nificant progress, the large-scale, high-yield fabrication of complex cir-cuits based on sub-100 nm GAA FETs is still an evolving area. However, several factors indicate its increasing feasibility. The fabrication feasi-bility is supported by: (a) Compatibility with Existing CMOS Process Flows: GAAFET fabrication follows a replacement metal gate (RMG) process similar to FinFETs, making integration into large-scale manufacturing viable. (b) Monolithic 3D Integration Potential: The vertical stacking of GAAFETs enables higher device density without excessive area overhead, facilitating large-scale neuromorphic circuit implementations. (c) Process Maturity and Industry Adoption: Leading semiconductor manufacturers have already demonstrated GAAFET-based transistors at the 3 nm and sub-100 nm nodes [38],reinforcing their viability for neuromorphic computing applications.

### 4.2. Applications of the proposed technique in some representative neuromorphic hardware

The BiCoSS architecture emphasizes a multigranular approach, integrating different levels of computational units to achieve large-scale cognitive capabilities [66]. Our proposed GAA FET-based LIF neuron, with its potential for low power consumption and compact size due to the GAA structure, could be highly beneficial at the fine-grained (neuron) level of the BiCoSS architecture in following ways: (a) Enhanced Energy Efficiency: The inherent advantages of FNSFETs, such as superior electrostatic control, can lead to lower operating voltages and reduced leakage currents compared to traditional planar MOSFETs. This translates to significant power savings when implementing a large number of LIF neurons, which is crucial for the energy budget of the BiCoSS system aiming for brain-scale computation. (b) Increased Den-sity: The smaller footprint achievable with FNSFETs could allow for a higher density of neuron implementations on-chip. This aligns with BiCoSS's goal of scaling to a large number of computational unitswithin a given area. (c) Tunable Neuron Characteristics: Depending on the specific design of the FNSFET and the associated circuitry,it may be possible to fine-tune the characteristics of our LIF neuron (e.g., threshold voltage, time constant) to match the diverse computational re-quirements envisioned within the multigranular BiCoSS framework. This flexibility could be exploited for implementing different types of neurons or adapting neuron behavior dynamically.

The framework in [67] focuses on context-dependent learning and robust operation through fault-tolerant spike routing. Our proposed FNSFET-based LIF neuron can contribute to this architecture by enhancing the reliability and predictability of individual neuron behavior by: (a) Improved Device Reliability and Uniformity: FNSFETs are known for their better short-channel effects and potentially improved device-to-device uniformity compared to planar devices. This can lead to more consistent and reliable spiking behavior across a large array of neurons, which is essential for the fault-tolerant spike routing mechanism to function effectively. Less variability in neuron charac-teristics reduces the complexity of routing and ensures predictable signal propagation. (b) Low-Power Spiking Events: The energy effi-ciency of our FNSFET-based LIF neuron can contribute to a lower overall power budget for the learning framework. This is particularly important in systems where spike activity is frequent, as lower power per spike translates to significant energy savings at the system level. (c) Potential for Integrated Learning Mechanisms: While our current focus is on the LIF neuron, the CMOS compatibility of our FNSFET design opens pos-sibilities for integrating synaptic plasticity mechanisms (learning rules) directly within or in close proximity to the neuron circuit in future it-erations. This could further enhance the context-dependent learning capabilities of the framework.

The architecture in [68] emphasizes the implementation of large-scale, biophysically detailed neural networks with multi-compartment neurons using digital circuits. Our GAA FET-based LIF neuron, while a simplified model compared to multi-compartment neurons, can serve as a fundamental building block within such a sys-tem,particularly for implementing the individual compartments or as a computationally efficient approximation of more complex neuronal dynamics in certain scenarios. (a) Efficient Implementation of Basic Compartments: Even in multi-compartment models, individual com-partments often exhibit integrate-and-fire-likke behavior. Our low-power and compact FNSFET-based LIF neuron can provide an efficient way to implement a large number of these basic computational units within each multi-compartment neuron. (b) Scalability through Density and Low Power: The scalability of the target architecture relies on the ability to implement a vast number of neurons. The potential for higher density and lower power consumption offered by our FNSFET design directly contributes to this scalability, allowing for larger and more complex biophysically meaningful networks to be realized within practical power and area constraints. (c) Foundation for Future Complexity: The CMOS compatibility of our design allows for the potential integration of more complex functionalities in future iterations, potentially moving towards more sophisticated compartment models or the incorporation of active conductances alongside the basic integrate-and-fire mechanism.

The framework in [69] focuses on integrating visual perception and decision-making using a fault-tolerant quadruplet-spike learning rule. Our proposed FNSFET-based LIF neuron can contribute to the efficiency and robustness of the neural network implementing this framework.(a) Efficient Spike Generation and Propagation: The low-power character-istics of our FNSFET-based LIF neuron can lead to more energy-efficient generation and propagation of the quadruplet spikes that are central to the learning rule. This is crucial for maintaining the energy efficiency of the overall system, especially when dealing with high-frequency spiking activity associated with visual processing and decision-making. (b) Contribution to Fault Tolerance: As mentioned earlier, the potential for improved device reliability and uniformity in FNSFETs can contribute to the fault tolerance of the network. More predictable neuron behavior makes the system less susceptible to individual device variations or failures. (c) Platform for Implementing the Learning Rule: The CMOS platform allows for the integration of the necessarycircuitry to imple-ment the quadruplet-spike learning rule in conjunction with our LIF neuron. Future work could explore the co-design of the neuron and the learning rule implementation for optimized performance.

Finally, our proposed CMOS compatible GAA FET-based LIF neuron offers promising advantages in terms of power efficiency, density,and potential reliability, making it a valuable candidate for integration into various advanced neuromorphic hardware architectures like the ones discussed. Further research and development focusing on specific inte-gration strategies and the exploration of more complex neuron func-tionalities based on GAA FET technology can further enhance the capabilities of these neuromorphic systems.

## 5. Conclusion

In the search for novel devices to replicate the characteristics of a biological neuron for neuromorphic computing, this study has show-cased the LIF neuron implemented using the NSFET. It consumes energy per spike of 0.75fJ per spike, making it highly efficient and ideal for SNN applications. The device requires a drain voltage VD of 1 V to trigger II, making the NSFET based LIF neuron consume less energy compared to MOSFET. Moreover, it shows a spiking frequency which is $\;10^{5}$  times greater than biological neuron (~10 Hz) and is linearly dependent on the input voltage $V_{SG}$  after reaching the threshold voltage $V_{th}$  As magnitude of input voltage increases, the spike frequency raises linearly which shows the adaptive nature of the device (LIF neuron). Conse-quently, as the output activity changes, there is a corresponding esca-lation in energy consumption, attributed to the increased occurrence of spikes. The fundamental objective of this paper is to implement a LIF neuron which can operate effectively with low power consumption, and it is clearly seen that the Floating Nanosheet FET based LIF neuron has low power relative to devices used in the literature. By properly modeling the device and adopting the right parameters to capture neuronal characteristics, this paper facilitates broader usage of Floating Nanosheet-based LIF neuron for SNN applications.

<!-- 9 -->

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026) 131814 -->

# CRediT authorship contribution statement

**Narendar** **Vadthiya**: Methodology, Resources, Validation, Concep-tualization, Software, Supervision. **Sunitha** **Bhukya**:Writing-review & editing, Visualization, Conceptualization, Data curation, Writing -original draft, Methodology, Investigation. **Shubham** Tayal: Supervi-sion, Methodology, Validation, Conceptualization. **Sresta** **Valasa:** Investigation, Data curation, Formal analysis, Methodology, Visualiza-tion, Writing -review & editing, Writing-original draft, Validation, Conceptualization. **Venkata** **Ramakrishna** **Kotha**: Writing-review & editing, Writing - original draft, Conceptualization, Visualization, Investigation, Data curation, Formal analysis, Methodology. Syed **Mohammad Riyaz**: Writing-review & editing,Writing-original draft, Validation, Data curation, Visualization, Investigation, Conceptualiza-tion, Formal analysis. **Lakshmi** **Amrutha** **Yechuri**: Methodology, Conceptualization, Investigation, Validation, Writing-review & edit-ing, Visualization, Formal analysis, Writing-original draft, Data cura-tion. **Yashodhan** **Bhatawdekar:** Visualization, Writing - review & editing, Validation, Investigation, Data curation, Methodology, Formmal analysis, Writing -original draft, Conceptualization.

# Declaration of Competing Interest

The authors declare that they have no known competing financial interests or personal relationships that could have appeared to influence the work reported in this paper.

# Data availability

No data was used for the research described in the article.

# References

[1] Y.Lei,et al., How to form brain-like memory in spiking neural networks with the help of frequency-induced mechanism, Neurocomputing 623(2025),https://doi. org/10.1016/j.neucom.2025.129361.

[2] A. Vicente-Sola, D.L. Manna, P. Kirkland, G.Di Caterina, and T. Bihl, "Spiking Neural Networks for event-based action recognition: A new task to understand their advantage," 2022, doi:10.1016/j.neucom.2024.128657.

[3] M.Heidarpur, A. Ahmadi, M. Ahmadi, M. Rahimi Azghadi, CORDIC-SNN: On-FPGA STDP learning with izhikevich neurons, IEEE Trans. Circuits Syst. I Regul. Pap. 66(7) (2019)2651-2661,https://doi.org/10.1109/TCSI.2019.2899356.

[4] A. Amirsoleimani, M. Ahmadi, A. Ahmadi, M. Boukadoum, Brain-inspired pattern classification with memristive neural network using the Hodgkin-Huxley neuron, 2016 IEEE Int. Conf. Electron. Circuits Syst. ICECS 2016 (2016) 81-84,https://doi. org/10.1109/ICECS.2016.7841137.

[5] X.Wu,et al.,Dynamic threshold integrate and fire neuron model for low latency spiking neural networks, Neurocomputing 544 (2023), https://doi.org/10.1016/j. neucom.2023.126247.

[6] Y. Zhou, A. Zhang, Improved integrate-and-fire neuron models for inference acceleration of spiking neural networks, Appl. Intell. 51 (4) (2021)2393-2405, https://doi.org/10.1007/s10489-020-02017-3.

[7] M. Zare, E. Zafarkhah, N. S. Anzabi-Nezhad, An area and energy efficient LIF neuron model with spike frequency adaptation mechanism, Neurocomputing 465(2021)350-358,https://doi.org/10.1016/j.eucom.2021.09.004.

[8] J.Tang, J.H. Lai, W.S. Zheng, L. Yang, X. Xie, Relaxation LIF: a gradient-based spiking neuron for direct training deep spiking neural networks, Neurocomputing 501 (2022)499-513,https://doi.org/10.1016/j.neucom.2022.06.036.

[9] P.Pietrzak, S. Szczęsny, D. Huderek, L. Przyborowski,Overview of spiking neural network learning approaches and their computational complexities,", Sensors 23(6)(2023)https://doi.org/10.3390/s23063037.

[10] M.K. Park, et al., Field effect Transistor-Type devices using High-k gate insulator stacks for neuromorphic applications, ACS Appl. Electron. Mater. 2 (2) (2020) 323-328,https://doi.org/10.1021/acsaelm.9b00698.

[11] Y.Jang,J. Park, J. Kang, S.Y. Lee, Amorphous InGaZnO (a-IGZO) synaptic transistor for neuromorphic computing, ACS Appl. Electron. Mater.4(4)(2022) 1427-1448,https://doi.org/10.1021/acsaelm.1c01088.

[12] B.Max, M. Hoffmann, H. Mulaosmanovic, S. Slesazeck, T. Mikolajick, Hafnia-based double-layer ferroelectric tunnel junctions as artificial synapses for neuromorphic computing, ACS Appl. Electron. Mater. 2 (12) (2020)4023-4033,https://doi.org/ 10.1021/acsaelm.0c00832.

[13] A.Ghani, et al., Evaluating the generalisation capability of a CMOS based synapse, Neurocomputing 83 (2012) 188-197,https://doi.org/10.1016/j. neucom.2011.12.010.

[14] G. Indiveri, E. Chicca, R. Douglas, A VLSI array of low-power spiking neurons and bistable synapses with spike-timing dependent plasticity, IEEE Trans. Neural Netw. 17 (1) (2006)211-221,https://doi.org/10.1109/TNN.2005.860850.

[15] I. Sourikopoulos, et al., A 4-fJ/spike artificial neuron in 65 nm CMOS technology, Front. Neurosci. 11 (MAR) (2017), https://doi.org/10.3389/fnins.2017.00123.

[16] S. Lashkare, S. Chouhan, T. Chavan, A. Bhat, P. Kumbhare, U. Ganguly, PCMO RRAM for Integrate-and-Fire neuron in spiking neural networks, IEEE Electron. Device Lett. 39 (4) (2018)484-487,https://doi.org/10.1109/LED.2018.2805822.

[17] T. Tuma, A. Pantazi, M. Le Gallo, A. Sebastian, E. Eleftheriou, Stochastic phase-change neurons, Nat. Nanotechnol. 11 (8) (2016) 693-699,https://doi.org/ 10.1038/nnano.2016.70.

[18] A.Amin Fida, F.A. Khanday, S. Mittal, An active memristor based rate-coded spiking neural network, Neurocomputing 533 (2023)61-71,https://doi.org/ 10.1016/j.neucom.2023.02.038.

[19] H. Eslahi, T.J. Hamilton, S. Khandelwal, Compact and energy efficient neuron with tunable spiking frequency in 22-nm FDSOI, IEEE Trans. Nanotechnol. 21 (2022) 189-195,https://doi.org/10.1109/TNANO.2022.3157585.

[20] Y.Chen, K. Xiao, Y. Qin, F. Liu, J. Wan, A compact artificial spiking neuron using a Sharp-Switching FET with Ultra-Low energy consumption down to 0.45 fJ/Spike, IEEE Electron Device Lett. 44 (1)(2023)160-163,https://doi.org/10.1109/ LED.2022.3219465.

[21] J.W.Han,M.Meyyappan, Leaky Integrate-And-Fire biristor neuron, IEEE Electron Device Lett.39 (9) (2018)1457-1460,https://doi.org/10.1109/ LED.2018.2856092.

[22] J.K. Han,S.Y.Yun, S.W.Lee,J.M.Yu, Y.K. Choi, A review of artificial spiking neuron devices for neural processing and sensing, Adv. Funct. Mater. 32 (33) (2022),https://doi.org/10.1002/adfm.202204102.

[23] A.K. Singh, V. Saraswat, M.S. Baghini, U. Ganguly, Quantum tunneling based Ultra-Compact and energy efficient spiking neuron enables hardware SNN, IEEE Trans. Circuits Syst. I Regul. Pap. 69 (8) (2022) 3212-3224,https://doi.org/10.1109/ TCSI.2022.3172176.

[24] S. Dutta, V. Kumar, A. Shukla, N.R. Mohapatra, U. Ganguly, Leaky integrate and fire neuron by charge-discharge dynamics in floating-body MOSFET, Sci. Rep.7(1) (2017),https://doi.org/10.1038/s41598-017-07418-y.

[25] D. Chatterjee, A. Kottantharayil, A CMOS compatible bulk FinFET-Based ultra low energy leaky integrate and fire neuron for spikingneural networks, IEEE Electron Device Lett. 40 (8) (2019) 1301-1304,https://doi.org/10.1109/ LED.2019.2924259.

[26] A. Kumar Kamal, N. Kamal, J.Singh, A low power L-shaped gate bipolar impact ionization MOSFET based capacitorless one transistor dynamic random access memory cell, Jpn. J. Appl. Phys. 60 (6) (2021),https://doi.org/10.35848/1347-4065/ac016c.

[27] N. Kamal, J. Singh, A highly scalable junctionless FET leaky Integrate-and-Fire neuron for spiking neural networks, IEEE Trans. Electron. Devices 68 (4) (2021) 1633-1638,https://doi.org/10.1109/TED.2021.3061036.

[28] J.K.Han,J.M. Yu, Y.K. Choi, A junctionless single transistor neuron with vertically stacked multiple nanowires for highly scalable neuromorphic hardware, IEEE Trans. Electron. Devices 69 (6) (2022)3142-3146,https://doi.org/10.1109/ TED.2022.3167622.

[29] S. Valasa, V.R. Kotha, N. Vadthiya, Pushing the boundaries: design and simulation approach of negative capacitance nanosheet FETs with ferroelectric and dielectric spacers at the Sub-3 nm technology node for Analog/RF/Mixed signal applications, ACS Appl. Electron.Mater. 6 (5) (2024) 3206-3215,https://doi.org/10.1021/ acsaelm.3c01862.

[30] R.K. Ratnesh, et al., Advancement and challenges in MOSFET scaling, Mater. Sci. Semicond.Process 134 (2021), https://doi.org/10.1016/j.mssp.2021.106002.

[31] N.H.Hamid, T.B. Tang, A.F. Murray, Probabilistic neural computing with advanced nanoscale MOSFETs, Neurocomputing 74 (6) (2011) 930-940,https://doi.org/ 10.1016/j.neucom.2010.10.010.

[32] S. Valasa, V.R. Kotha, S. Tayal, N. Vadthiya, Design space optimization for eradication of NDR effect in Dielectric/Ferroelectric stacked negative capacitance Multi-Gate FETs at Sub-3nm technology for Digital/Analog/RF applications, IEEE Trans. Dielectr. Electr. Insul (2024),https://doi.org/10.1109/TDEI.2024.3432088.

[33] V. Kothwal, S. Valasa, V.R. Kotha, S. Bhukya, N. Vadthiya, B. Vadthya, A comparative analysis of FinFET and nanosheet FET based circuits with geometrical parameter variations at sub-5 nm technology node, 2023 IEEE 20th India Counc. Int. Conf. INDICON 2023 (2023) 753-758,https://doi.org/10.1109/ INDICON59947.2023.10440865.

[34] S. Valasa, S. Tayal, L.R. Thoutam, J. Ajayan, S. Bhattacharya, A critical review on performance,reliability, and fabrication challenges in nanosheet FET for future analog/digital IC applications, Micro Nanostruct. 170 (2022),https://doi.org/ 10.1016/j.micrna.2022.207374.

<!-- 10 -->

<!-- Y.Bhatawdekar et al. -->

<!-- Neurocomputing 659 (2026) 131814 -->

[35] M. Kim, S. Kim, K. Lee, J.H. Lee, B.G. Park, D. Kwon, Floating fin shaped stacked nanosheet MOSFET for low power logic application, IEEE J. Electron. Devices Soc. 11 (2023)95-100,https://doi.org/10.1109/JEDS.2023.3237386.

[36] A.Jaiswal, S. Roy, G. Srinivasan, K. Roy, Proposal for a Leaky-Integrate-Fire spiking neuron based on magnetoelectric switching of ferromagnets, IEEE Trans. Electron. Devices 64 (4) (2017) 1818-1824,https://doi.org/10.1109/ TED.2017.2671353.

[37] N.Brunel, M.C.W. Van Rossum, Lapicque's 1907 paper: from frogs to integrate-and-fire, Biol. Cyber 97 (5-6) (2007) 337-339,https://doi.org/10.1007/s00422-007-0190-0.

[38] N. Loubet, et al., Stacked nanosheet gate-all-around transistor to enable scaling beyond FinFET, Dig. Tech. Pap. Symp. VLSI Technol. (2017) T230-T231,https:// doi.org/10.23919/VLSIT.2017.7998183.

[39] "Sentaurus device user guide version T-202203, Synopsys, Mountain View, CA, 2022"..

[40] B. Hoefflinger"ITRS 2028-international roadmap of semiconductors," CHIPS 2020VOL. 2 New Vistas Nanoelectron., pp. 143-148,2015, doi: 10.1007/978-3-319-22093-27..

[41] R. Andavarapu, et al., A proposal for optimization of spacer engineering at Sub-5-nm technology node for JL-TreeFET: a deviceto circuit level implementation, IEEE Trans. Electron Devices 71(1)(2024)453-460,https://doi.org/10.1109/ TED.2023.3339086.

[42] C. Anguru, et al., Optimization of sidewall spacer engineering at Sub-5 nm technology node for JL-nanowire FET: digital/analog/RF/circuit perspective, ECS J. Solid State Sci. Technol. 13 (1) (2024)013002,https://doi.org/10.1149/2162-8777/ad15a8.

[43] J.R. Burger, The neuron as a controlled toggle circuit, Circuits Syst. 05 (12)(2014) 309-316,https://doi.org/10.4236/cs.2014.512032.

[44] A. Joubert, B. Belhadj, O. Temam, R. Héliot, Hardware spiking neurons design: analog or digital? Proc. Int. Jt. Conf. Neural Netw. (2012) https://doi.org/ 10.1109/IJCNN.2012.6252600.

[45] J.H.B. Wijekoon,P. Dudek, Compact silicon neuron circuit with spiking and bursting behaviour, Neural Netw. 21 (2-3) (2008) 524-534,https://doi.org/ 10.1016/j.neunet.2007.12.037.

[46] M.C.-A. Jose, D. Timothy, S. Narayan, A scalable neural chip with synaptic electronics using CMOS integrated memristors, Nanotechnology 24(38)(2013) 384011. (http://stacks.iop.org/0957-4484/24/i=38/a=384011) ([Online]. Available).

[47] S.Woo,J.Cho,D.Lim, Y.S. Park, K. Cho, S. Kim, Implementation and characterization of an Integrate-and-Fire neuron circuit using a silicon nanowire feedback Field-Effect transistor, IEEE Trans. Electron. Devices 67(7)(2020) 2995-3000,https://doi.org/10.1109/TED.2020.2995785.

[48] A.K. Kamal, J. Singh, Simulation-Based ultralow energy and High-Speed LIF neuron using silicon bipolar impact ionization MOSFET for spiking neural networks, IEEE Trans. Electron. Devices 67 (6)(2020)2600-2606,https://doi.org/ 10.1109/TED.2020.2985076.

[49] T. Chavan, S. Dutta, N.R. Mohapatra, U. Ganguly, Band-to-band tunneling based ultra-energy-efficient silicon neuron, IEEETrans. Electron. Devices 67 (6) (2020) 2614-2620,https://doi.org/10.1109/TED.2020.2985167.

[50] K.B. Choi, et al., A split-gate positive feedback device with an integrate-and-fire capability for a high-density low-power neuron circuit, Front. Neurosci. 12 (OCT) (2018),https://doi.org/10.3389/fnins.2018.00704.

[51] F. Bashir, F. Zahoor, A.S. Alzahrani, A.R. Khan, A single schottky barrier MOSFET-Based leaky integrate and fire neuron for neuromorphic computing, IEEE Trans. Circuits Syst. II Express Briefs 70 (11) (2023) 4018-4022,https://doi.org/ 10.1109/TCSII.2023.3286810.

[52] A. Lahgere, Design of leaky integrate and fire neuron for spiking neural networks using trench bipolar I-MOS, IEEE Trans. Nanotechnol. 22 (2023) 260-265, https:// doi.org/10.1109/TNANO.2023.3278537.

[53] U. Mushtaq, M.W. Akram, D. Prasad, A. Islam, An energy and area-efficient spike frequency adaptable LIF neuron for spiking neural networks, Comput. Electr. Eng. 119(2024),https://doi.org/10.1016/j.compeleceng.2024.109562.

[54] M.A. Khanday, F.A. Khanday, F. Bashir, Single SiGe transistor based Energy-Efficient leaky Integrate-and-Fire neuron for neuromorphic computing, Neural Process. Lett. 55 (6) (2023) 6997-7007,https://doi.org/10.1007/s11063-023-11245-w.

[55] S.Sarkhel, T. Kumari, P. Saha, L-Shaped double gate bipolar impact ionization MOSFET based energy efficient leaky integrate and fire neuron for spiking neural network, IEEE Trans. Nanotechnol. 22 (2023)673-678,https://doi.org/10.1109/ TNANO.2023.3322880.

[56] S. Priyanka, M. Singh, Panchore, Leaky-integrate-fire neuron based on vertically extended drain Sil-xGex source TFET: Ultra-energy-efficient and high speed design, Microelectron. J. 148 (2024),https://doi.org/10.1016/j. mejo.2024.106182.

[57] M. Faizan, S.A. Loan, H.I. Alkhammash, Highly scalable In0.95Ga0.05As based controllable leaky-integrate-fire neuron for high performance spiking neural network and applications, Phys. Scr. 100 (2) (2025),https://doi.org/10.1088/ 1402-4896/adab45.

[58] Priyanka, S. Singh, M. Panchore, Strained bipolar charge plasma transistor as a high speed LIF neuron, Micro Nanostruct. 203 (2025), https://doi.org/10.1016/j. micrna.2025.208127.

[59] Priyanka, S. Singh, M. Panchore, Emulation of neuro-mimetic dynamics via GaSb/ Si heterojunction V-DGTFET leaky-integrate-fire silicon neuron, Micro Nanostruct. 185(2024),https://doi.org/10.1016/j.micrna.2023.207709.

[60] Y.Kim, H. Kim, K. Oh, J.H. Park, B.D.Kong, C.K. Baek, Low-energy and tunable LIF neuron using SiGe bandgap-engineered resistive switching transistor, Discov. Nano 19(1)(2024),https://doi.org/10.1186/s11671-024-04079-5.

[61] J.K. Han, et al., Mimicry of excitatory and inhibitory artificial neuron with leaky Integrate-and-Fire function by a single MOSFET, IEEE Electron Device Lett.41(2) (2020)208-211,https://doi.org/10.1109/LED.2019.2958623.

[62] Z. Wang, et al., Experimental demonstration of ferroelectric spiking neurons for unsupervised clustering, Tech. Dig. Int. Electron Devices Meet. IEDM 2018-December (2018) 13.3.1-13.3.4,https://doi.org/10.1109/IEDM.2018.8614586.

[63] M.S. Asghar, S.Arslan, H. Kim, A low-power spiking neural network chip based on a compact lif neuron and binary exponential charge injector synapse circuits, Sensors 21 (13)(2021),https://doi.org/10.3390/s21134462.

[64] B.V. Benjamin, et al., Neurogrid: a mixed-analog-digital multichip system for large-scale neural simulations, Proc. IEEE 102 (5) (2014) 699-716,https://doi.org/ 10.1109/JPROC.2014.2313565.

[65] S.A. Aamir, et al., An accelerated LIF neuronal network array for a large-scale mixed-signal neuromorphic architecture, IEEE Trans. Circuits Syst. I Regul. Pap. 65(12)(2018)4299-4312,https://doi.org/10.1109/TCSI.2018.2840718.

[66] S. Yang, et al., BiCoSS: toward Large-Scale cognition brain with multigranular neuromorphic architecture, IEEE Trans. Neural Netw. Learn. Syst. 33(7)(2022) 2801-2815,https://doi.org/10.1109/TNNLS.2020.3045492.

[67] S. Yang, J. Wang, B. Deng, M.R. Azghadi, B. Linares-Barranco, Neuromorphic context-dependent learning framework with Fault-Tolerant spike routing, IEEE Trans. Neural Netw. Learn. Syst. 33 (12) (2022) 7126-7140,https://doi.org/ 10.1109/TNNLS.2021.3084250.

[68] S. Yang, et al., Scalable digital neuromorphic architecture for Large-Scale biophysically meaningful neural network with Multi-Compartment neurons,IEEE Trans. Neural Netw. Learn. Syst. 31 (1) (2020) 148-162,https://doi.org/10.1109/ TNNLS.2019.2899936.

[69] S.Yang, H. Wang, Y. Pang, Y. Jin, B. Linares-Barranco, Integrating visual perception with decision making in neuromorphic Fault-Tolerant Quadruplet-Spike learning framework, IEEE Trans. Syst. Man Cybern. Syst. 54 (3) (2024) 1502-1514, https://doi.org/10.1109/TSMC.2023.3327142.

**Yashodhan** **Bhatawdekar** is currently pursuing his Bachelor's degree in the Department of Electronics and Communication Engineering, National Institute of Technology WWar-angal, India. His research interests include the modeling of semiconductor devices, ma-chine learning, deep learning, and neuromorphic computing.

**Syed Mohammad** **Riyaz** is **currently** **pursuing** his Bachelor's degree in the Department of Electronics and Communication Engineering, National Institute of Technology Warangal, India. His research interests include the modeling of semiconductor devices, machine learning, deep learning, and neuromorphic computing.

**Lakshmi** **Amrutha** **Yechuri** is currently pursuing her Bachelor's degree in the Department of **Electronics** **and** Communication Engineering, National Institute of Technology War-angal,India. Her research interests include the modeling of semiconductor devices, ma-chine learning, deep learning, and neuromorphic computing.

**Sresta** **Valasa** is currently working towards her Ph.D. degree in Department of Electronics and Communication Engineering, National Institute of Technology Warangal, India. Her research interests include the simulation and modeling of advanced semiconductor de-vices, machine learning, and neuromorphic computing.

**Venkata** **Ramakrishna Kotha** is currently **working** towards his Ph.D. degree in Depart-**ment** of Electronics and Communication Engineering, National Institute of Technology Warangal, India. His research interests include the simulation and modeling of advanced semiconductor devices, 2-D based devices, machine learning, and neuromorphic computing.

**Sunitha** **Bhukya** is currently working towards her Ph.D. degree in Department of Elec-**tronics** **and** Communication Engineering, National Institute of Technology Warangal, India. Her research interests include the simulation and modeling of advanced semi-conductor devices, machine learning, and neuromorphic computing.

**Shubam Tayal** is currently working as a Layout Design, Staff Engineer with Synopsys India Private Ltd., Hyderabad 500032, India.

**Narendar** **Vadthiya** received the M. Tech and Ph.D. degrees from Motilal Nehru National Institute of Technology (MNNIT) Allahabad, Uttar Pradesh, India respectively. He worked as an Assistant Professor under the SMDPII Project in the Department of Electronics and Communication Engineering from July 27, 2010 to October 5, 2012. He worked as an Assistant Professor in department of ECE in MNNIT Allahabad, U.P, India from October 15, 2012, to May 10, 2018. From May 11, 2018 he has been working as an assistant professor in the department of Electronics and Communication Engineering, National Institute of Technology Warangal, Telangana, India. His research interest includes Beyond CMOS, Nanoscale device design and modeling, Carbon Nanotubes and 2D material-based devices, VLSI Circuits & Systems, and machine learning, and neuromorphic computing.

<!-- 11 -->

