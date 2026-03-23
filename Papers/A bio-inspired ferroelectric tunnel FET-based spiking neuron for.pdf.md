Micro and Nanostructures 188 (2024) 207788
Available online 15 February 2024
2773-0123/© 2024 Elsevier Ltd. All rights reserved.
A bio-inspired ferroelectric tunnel FET-based spiking neuron for 
high-speed energy efficient neuromorphic computing 
Mudasir A. Khanday , Farooq A. Khanday * 
Department of Electronics and Instrumentation Technology, University of Kashmir, Srinagar, India   
A R T I C L E  I N F O   
Keywords: 
Ferroelectric tunnel FET 
Indium antimonide 
Leaky integrate-and-fire 
Neuromorphic computing 
Spiking neural network 
A B S T R A C T   
In this study, a novel spiking neuron based on double-gate ferroelectric tunnel field effect tran­
sistor (DG-FE-TFET) is proposed in the 50 nm technology node. Through calibrated simulations in 
Atlas TCAD, it is verified that by leveraging the forward transfer characteristics, the device 
accurately emulates the spiking patterns exhibited by biological neurons. The device works on 
tunneling mechanism which ensures low voltage operation and thereby reduces overall energy 
consumption. The proposed neuron consumes an energy of 0.58 aJ per spike, which is 1.29, 
41.38, 7.75 × 105, 12.9 × 105, 1.89 × 105, 13.79 × 106, and 7.75 × 107 times lesser than V- 
DGTFET, FE-JLFET, Z2-FET, DG-TFET, FD-MOSFET, Ge-MOSFET, and Si-MOSFET. Notably, the 
neuron operates without the need for additional reset circuitry and achieves spiking frequency of 
344 GHz, which can be attributed to the sharp switching characteristics of the proposed device. 
This greatly simplifies implementation and facilitates a higher neuron density for energy-efficient 
neuromorphic chips with high-speed capabilities. Finally, based upon the proposed neuron, a 
multi-layer spiking neural network (SNN) is designed in Python platform. The network is 
implemented for signal classification with an accuracy of 84.4%.   
1. Introduction 
Neuromorphic computing, an emerging field with roots dating back to the 1980s, has gained significant attention and undergone 
remarkable advancements in recent years due to the rapid progress in artificial intelligence. It employs artificial neural systems with 
analog circuitry to mimic the functionality of the human brain. In the evolution of neural network models, the 1st generation per­
ceptron operates by applying a threshold to the weighted synaptic input to produce binary outputs. The 2nd generation artificial neural 
networks (ANNs) are characterized by their multi-layered architecture. They are widely used in deep learning for complex tasks like 
recognizing images and understanding language. The 3rd generation, SNNs, represents a remarkable leap in emulating biological 
neural networks. SNNs model neurons that communicate through generated spikes of electrical activity. This close resemblance to the 
human nervous system has captivated researchers in the pursuit of neuromorphic computing. 
Within a biological neuron, an essential role is played by the bilayer lipid cell membrane, which acts as a leaky capacitor and is 
responsible for the integration of incoming spikes. As the membrane potential gradually builds up and reaches a critical threshold, it 
triggers the firing of the neuron and generates a spike. This process is referred to as "integrate-and-fire," and it is represented by the 
widely used leaky integrate-and-fire (LIF) model. The LIF model is favoured for its simplicity in design, achieved by employing a 
minimal number of circuit elements. An illustration of biological neuron model, the equivalent circuit of the LIF neuron, and schematic 
* Corresponding author. 
E-mail address: farooqkhanday@kashmiruniversity.ac.in (F.A. Khanday).  
Contents lists available at ScienceDirect 
Micro and Nanostructures 
journal homepage: www.journals.elsevier.com/micro-and-nanostructures 
https://doi.org/10.1016/j.micrna.2024.207788 
Received 4 January 2024; Received in revised form 6 February 2024; Accepted 12 February 2024   

Micro and Nanostructures 188 (2024) 207788
2
of a typical SNN are shown in Fig. 1(a), (b), and (c), respectively. 
Traditional artificial spiking neurons are typically constructed using complex complementary metal-oxide semiconductor (CMOS) 
circuits [1], which involve multiple transistors to create a single neuron. This complexity results in low area and energy efficiency. In 
response to the need for better efficiency, there has been a push to develop new spiking neurons that rely on a single device. These 
devices, due to their unique operating principles, can perform the basic functions of spiking neurons with simpler circuits and offer 
high scalability. However, the main drawback is that many of these spiking neuron devices lack self-reset mechanisms, and hence 
require the use of additional circuits for initialization, which adds extra area and energy overhead. Therefore, there is ongoing interest 
in the development of CMOS-compatible compact 1T spiking neurons [2–8]. Another challenge in SNNs is energy consumption. In the 
context of edge computing in the era of the Internet of Things (IoT), low-power technologies like SOI are crucial. These technologies 
aim to minimize energy usage while maintaining efficient processing power, making them highly relevant for SNNs. 
Concerning this issue, TFETs have gained significant attention in recent times due to their notable characteristics, including 
subthreshold swing (SS) below 60 mV/decade, low leakage current, and reduced power dissipation compared to conventional 
MOSFETs. In this work, a novel Indium antimonide (InSb) based DG-FE-TFET is proposed for energy efficient 1T LIF neuron. The 
device works on tunneling mechanism and does not require additional circuitry for its operation. This greatly simplifies the neuron 
design, ensures higher integration density, and reduces the overall energy consumption. The rest of the paper is organized as follows. 
Section 2 explains device description, working principle, and characteristics. Results are discussed in section 3, and the applicability of 
the proposed neuron in signal classification is explained in section 4. The paper is concluded in section 5. 
2. Structural description and model calibration 
The architectural details of the proposed DG-FE-TFET are shown in Fig. 2(a). The device is simulated at channel length of 50 nm, 
and InSb thickness of 20 nm. The source has a p-type doping of 1 × 1020 cm−3 and the drain and channel have n-type doping of 5 ×
1019 cm−3 and 1 × 1017, respectively. The heavily doped 3 nm n + pocket at source-channel junction effectively narrows the tunneling 
width and enhances the lateral electric field, resulting in a noticeable improvement in the overall performance of the device. A gate 
oxide comprising of 4 nm layer of ferroelectric HfZrO2 (HZO), with a composition ratio of Hf: Zr = 1:1, has been employed. This HZO 
layer exhibits specific properties, including remanent polarization, Pr = 10μC/cm2; coercive field, Ec = 1.2MV/cm; and dielectric 
constant, K = 43. These chosen values have been optimized to attain non-hysteresis behavior [9], which is an important requirement 
for achieving ultra-low power neuronal operation of the device. 
InSb, a group III-V compound semiconductor, demonstrates a compelling set of characteristics, including small effective charge 
carrier mass (78000 cm2/V-s), low effective bandgap (0.17 eV), enhanced ON current, steeper turn-on behavior, high electron 
mobility, and efficient auger recombination control [11]. Therefore, it enhances the band-to-band tunneling rate (BTBT) according to 
equation (1): 
P(T)∝exp
[
−
A
(
Eg
3
2
̅̅̅̅̅
m∗
√
Eg + Δφ
)]
(1)  
where P(T) gives the tunneling probability, as approximated by Wentzel–Kramer–Brillouin approach, m∗is the effective mass of 
carrier, Δφ is tunneling window i.e., energy difference between maxima of valance band and minima of conduction band minima, and 
A is a constant. 
The device simulations have been performed in Atlas TCAD device simulator [12]. The various models used during the simulations 
Fig. 1. (a) Representation of biological neuron (b) Equivalent circuit of the LIF neuron (c) Schematics of a typical SNN.  
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  

Micro and Nanostructures 188 (2024) 207788
3
include CONSRH, DRIFT.DIFF, FERMI, CONMOB, FLDMOB, BTBT, and FERRO. To calibrate the TCAD models, the experimental results 
reported in Ref. [10] have been reproduced, as shown in Fig. 2(b). The simulated results show good agreement with the experimental 
data. The transfer characteristics of the proposed device are shown in Fig. 2(c). The enhanced ON-current and SS can be attributed to 
the use of FE-material [9] and n-pocket [13]. Theoretically, the SS of a FET is given as follows: 
SS =
∂VG
∂(log10 ID) = ∂VG
∂ψs
⏟⏞⏞⏟
x
∂ψs
∂(log10 ID)
⏟̅̅̅̅̅̅̅⏞⏞̅̅̅̅̅̅̅⏟
y
(2)  
where VG, ID, and ψs represent gate voltage, drain current, and surface potential, respectively. The impact of the ferroelectric material 
Fig. 2. (a) Schematics of the proposed device (not drawn to scale) (b) TCAD model calibration against the experimental work done by Boucart et al. 
[10]. (c) Transfer characteristics of the device with ferro and non-ferro gate oxides. Ferroelectric gate oxide shows sharp transition and hence low 
SS. (d) Effect of gate work function on threshold voltage. (e) Effect of ferroelectric oxide thickness and body doping concentration on 
threshold voltage. 
Fig. 3. A possible process flow for fabrication of the proposed device.  
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  

Micro and Nanostructures 188 (2024) 207788
4
reduces the ″x″ term, while the tunneling process influences the ″y″ term of equation (2). This results in reduction of SS below theoretical 
limit of 60 mV/decade for an ideal conventional MOSFET [14]. The sharp switching of the proposed device is responsible for low 
energy consumption and high spiking frequency of the neuron. 
The effect of gate work function (ΦG), ferroelectric oxide thickness, and body doping concentration on the threshold voltage (Vth) of 
the device has also been studied, as shown in Fig. 2(d). It has been observed that as ΦG is increased, the breakdown voltage also 
increases. This is because a higher value of the metal work function raises the flat-band voltage, which in turn increases Vth. From Fig. 2 
(e)–a nonmonotonic dependence of Vth on the doping concentration and ferroelectric oxide thickness is observed. These results are in 
consistent with the previously reported works [15,16]. 
A possible process flow of the proposed device is shown in Fig. 3. To start with, first a substrate of InSb is doped with donor and 
acceptor dopants to form drain and source, respectively. A 3 nm pocket is created at the source-channel junction by in-situ n-type 
doping of 5 × 1019 cm−3. Next, ferroelectric oxide layer is grown by the process of atomic layer deposition. This is followed by 
metallization of electrodes and etching out of unwanted oxide. Finally, the device is vertically flipped to perform oxidation and 
metallization of the upper gate [13]. 
3. Results and discussions 
The operational mechanism of the proposed device as LIF neuron can be comprehended through the circuit arrangement presented 
in Fig. 4(a). The emulation of spiking behavior akin to that of a biological brain is achieved by leveraging the forward transfer 
characteristics of the device. Initially, the device is assumed to be in the OFF state. Upon the application of a pulsating input current 
(Iin) of 1 μA to the device, the drain capacitor undergoes linear charging, leading to an increase in the output voltage (VO). This phase is 
commonly referred to as temporal integration. Subsequently, as the integrated voltage attains the threshold level (Vth) of 0.5 V, the 
device turns ON due to tunneling mechanism, and a current spike is observed, as depicted in Fig. 4(b). As a result, the body capacitor 
discharges and VO decreases. When the voltage reaches Vrest, the device switches to initial OFF state. The LIF behavior can also be 
verified from energy band diagrams (EBDs) and BTBT rate observed at different instants. Fig. 4(c) and (d) show the initial behavior of 
the device with zero tunneling rate and negligible band bending. However, when the device approaches Vth, a high tunneling rate is 
achieved due to significant band overlapping, as shown in Fig. 4(e) and (f). 
3.1. Dependence of spiking frequency 
A spiking neuron stores information in the frequency of spikes, and not in the profile of a particular spike. To gain insights into the 
spiking behavior, a pulsating current (Iin) with magnitude of 1 μA, duty cycle of 10%, and frequency of 10 GHz is applied. Conse­
quently, the drain capacitor begins to charge, and a spike train is observed. However, when the frequency of input current is reduced to 
5 GHz, the charging process slows down, thus decreasing the spiking frequency, as shown in Fig. 5. Additionally, the spiking frequency 
is a function of drain capacitance and magnitude and duty cycle of input current. A decrease in the capacitance reduces the charging 
time and increases the spiking rate. The dependence of spiking frequency on the magnitude of input current is shown in Fig. 6(a). It can 
be observed that when the magnitude is varied from 1 μA to 5 μA, the spiking frequency increases from 10 GHz to 46 GHz. This can be 
attributed to the fact that a higher magnitude of input current speeds up the charging process and thus increases the spiking frequency. 
Through extensive simulations in Atlas TCAD, it has been observed that the highest spiking frequency (fS) that can be achieved by the 
proposed neuron is 344 GHz at input current of 37 μA. The maximum frequency is limited by the charging-discharging time of the drain 
Fig. 4. (a) Biasing arrangement of DG-FE-TFET for LIF neuron. (b) Spiking behavior of the proposed neuron. (c), (d) Tunneling rate and EBD, when 
device is in the OFF state. (e), (f) Tunneling rate and EBD, when VO approaches Vth, and the device switches to the ON state. 
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  

Micro and Nanostructures 188 (2024) 207788
5
capacitor. Since the capacitor discharges through the device, its switching behaviour governs the maximum achievable spiking fre­
quency. While a higher spiking frequency holds significance in the design of high-speed neuromorphic architectures, it concurrently 
results in a larger average power consumption. As previously explained, the increase in ΦG results in a corresponding rise in Vth. 
Consequently, this contributes to an increase in energy consumption, as shown in Fig. 6(b). 
3.2. Energy and power consumption 
The energy per spike, Espike, and average power consumption, P, of a spiking neuron are as follows: 
Espike = Vth × IS × tspike
(3)  
P = fS × Espike
(4) 
With the help of data obtained from Fig. 4(b), the energy consumption of the proposed neuron is calculated as follows: 
Espike = 0.5 × 0.4 × 10−6 × 2.9 × 10−12 = 0.58 aJ
(5) 
And the average power consumption is: 
P = 344 × 109 × 0.58 × 10−18 = 0.2 μW
(6) 
Notably, the energy and power efficiency of the proposed neuron are significantly improved. This can be attributed to the lower SS 
of the device. Lower SS ensures that temporal duration of output spike is very small, causing the device to consume lesser energy. 
Pertinent to mention that the energy consumption is 1.29 times lower, and the power consumption is halved compared to the recently 
reported vertically developed double-gate GaSb/Si TFET-based neuron [17]. 
3.3. Comparison with the state-of-the-art 
The proposed neuron is compared with the state-of-the-art neurons that do not use external circuitry, as shown in Table 1. The 
comparison is made in terms of technology node, energy consumption per spike, spiking frequency, and methodology. It is evident that 
Fig. 5. Dependence of spiking frequency of the proposed neuron on frequency of input current. A higher frequency of input current speeds up the 
charging process and thus increases the spiking frequency. 
Fig. 6. (a) Spiking frequency and energy consumption per spike as a function of magnitude of input current. (b) Effect of ΦG on threshold voltage 
and energy consumption of the neuron. 
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  

Micro and Nanostructures 188 (2024) 207788
6
the proposed neuron consumes the least energy among 1T neurons reported in the literature. 
4.Signal classification 
Physiological signals offer valuable insights into various aspects of bodily functions and any deviations from their normal patterns 
can potentially signify underlying health issues. For instance, electrocardiogram (ECG) signals possess the capability to identify ar­
rhythmias, whereas electroencephalogram (EEG) signals can unveil abnormalities indicative of epilepsy during seizure episodes. ECG 
recordings typically encompass muscle depolarization and repolarization, including P, QRS, and T complexes, as shown in Fig. 7(b). 
Heartbeats are classified into four distinct categories: normal (N), supraventricular ectopic beat (SVEB), ventricular ectopic beat (VEB), 
and fusion (F). These classifications adhere to the standards set forth by the Association for the Advancement of Medical Instru­
mentation (AAMI). 
In this section, the proposed neuron has been implemented to classify the heartbeats into one of the four target classes. The 
heartbeat signals are taken from MIT-BIH database [18]. The spike encoder converts analog ECG signal into positive and negative spike 
trains, as shown in Fig. 7(a). The positive spike (UP) signifies when the input signal exceeds a threshold, while the negative spike 
(DOWN) denotes when the signal falls below a threshold. By employing this asynchronous encoding scheme, the accurate timing 
information of input signal is preserved. Also, the spike trains can accurately reconstruct the original input analog signal due to the 
inclusion of precise time information [19]. An additional CUE channel is used that continuously fires at the end of each heartbeat to 
initiate a valid output period. 
To verify the signal classification ability, a Python-based equivalent model of the proposed TFET neuron is designed by extracting 
various electrical parameters that characterize the behavior of the neuron. These parameters include device capacitance (0.2 fF), 
threshold voltage (0.5 V), resting potential (0.3 V), and OFF-state resistance (8 MΩ). Next, a three-layer SNN is designed consisting of 3 
neurons in input layer, which correspond to UP, DOWN, and CUE signals; 100 neurons in hidden layer; and 4 neurons in output layer, 
which correspond to N, F, SVEB, and VEB classes of heartbeats. The network is implemented in PyTorch and trained used Back­
propagation Through Time (BPTT) for 200 epochs. The simulation code and classification methodology are adapted from Ref. [19]. For 
training and evaluating, datasets of 1650 and 350 samples were used, respectively. The network was successful in classifying heart­
beats with the maximum accuracy of 84.4%, as shown in Fig. 7(c). This can also be cross verified by the dark diagonal line of the 
confusion matrix shown in Fig. 7(d). 
5. Conclusion 
This paper introduces a novel spiking neuron design based on a double-gate ferroelectric tunnel field effect transistor in the 50 nm 
technology node. Through calibrated simulations, it is validated that the neuron accurately replicates biological neuron spiking 
patterns with low energy consumption. The design does not need extra circuitry and spikes in GHz range, simplifying the design and 
allowing for higher neuron density, which is crucial for large-scale neuromorphic chips. Unlike impact ionization-based neurons, the 
DG-TFET uses tunneling mechanisms, reducing energy and power consumption. Finally, an SNN has been designed for ECG classifi­
cation with an accuracy of 84.4%. This work advances energy-efficient neuromorphic computing, holding potential for artificial in­
telligence and computational neuroscience. 
Ethics approval 
Not applicable. 
Consent to participate 
Not applicable. 
Table 1 
Benchmark with the state of the art.  
Ref. 
Device Type 
Tech Node 
Spiking Frequency 
Energy/spike (J) 
Methodology 
[2] 
Si-MOSFET 
880 nm 
0.8 KHz 
4.5 × 10−11 
Experimental 
[3] 
Ge-MOSFET 
800 nm 
1 KHz 
8 × 10−12 
Simulation 
[4] 
MOSFET 
400 nm 
1 KHz 
3.8 × 10−12 
Simulation 
[5] 
FD-MOSFET 
100 nm 
1 MHz 
1.1 × 10−13 
Simulation 
[6] 
DG-TFET 
50 nm 
12 KHz 
7.5 × 10−13 
Simulation 
[7] 
Z2-FET 
3 μm 
180 Hz 
4.5 × 10−13 
Experimental 
[8] 
FE-JLFET 
20 nm 
1 GHz 
24 × 10−18 
Simulation 
[17] 
V-DGTFET 
20 nm 
534 GHz 
0.75 × 10−18 
Simulation 
This work 
DG-FE-TFET 
50 nm 
344 GHz 
0.58 £ 10¡18 
Simulation  
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  

Micro and Nanostructures 188 (2024) 207788
7
Consent for publication 
Yes. 
Availability of data and materials 
Not applicable. 
Competing interests 
Not applicable. 
Funding 
This work was supported by the University Grants Commission, Government of India, through the Junior Research Fellowship 
under Grant 3742/(NET-JULY 2018). 
Authors’ contributions 
All authors have contributed equally. 
Disclosure of potential conflicts of interest 
There is no conflict of interest among the authors while submitting the manuscript. 
Research involving Human Participants and/or Animals 
Not applicable. 
Informed consent 
All authors have been informed before submitting the manuscript. 
Fig. 7. (a) The spike encoder converts ECG heartbeat into UP and DOWN spike trains, followed by CUE signal indicating a valid output period. (b) 
Schematics of a typical ECG and the proposed SNN. (c) Scatter plot of accuracy, showing the maximum accuracy of 84.4%. (d) The confusion matrix 
to validate the functionality of the SNN for the 4-class (N, F, SVEB, VEB) heartbeat classification. 
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  

Micro and Nanostructures 188 (2024) 207788
8
CRediT authorship contribution statement 
Mudasir A. Khanday: Writing – original draft, Validation, Software, Investigation, Formal analysis, Conceptualization. Farooq A. 
Khanday: Writing – review & editing, Writing – original draft, Validation, Supervision, Resources, Project administration, Method­
ology, Investigation, Conceptualization. 
Declaration of competing Interest 
The authors declare that they have no known competing financial interests or personal relationships that could have appeared to 
influence the work reported in this paper. 
Data availability 
No data was used for the research described in the article. 
References 
[1] F.A. Khanday, N.A. Kant, M.R. Dar, T.Z.A. Zulkifli, C. Psychalinos, Low-voltage low-power integrable CMOS circuit implementation of integer and 
fractional–order FitzHugh–nagumo neuron model, IEEE Transact. Neural Networks Learn. Syst. 30 (7) (July 2019) 2108–2122, https://doi.org/10.1109/ 
TNNLS.2018.2877454. 
[2] J.K. Han, et al., Mimicry of excitatory and inhibitory artificial neuron with leaky integrate-and-fire function by a single MOSFET, IEEE Electron. Device Lett. 41 
(2) (Feb. 2020) 208–211, https://doi.org/10.1109/LED.2019.2958623. 
[3] M.A. Khanday, F. Bashir, F.A. Khanday, Single germanium MOSFET-based low energy and controllable leaky integrate-and-fire neuron for spiking neural 
networks, IEEE Trans. Electron. Dev. 69 (8) (Aug. 2022) 4265–4270, https://doi.org/10.1109/TED.2022.3186274. 
[4] M.A. Khanday, F.A. Khanday, F. Bashir, Single SiGe transistor based energy-efficient leaky integrate-and-fire neuron for neuromorphic computing, in: Neural 
Processing Letters, 2023, https://doi.org/10.1007/s11063-023-11245-w. Mar. 
[5] V. Rajakumari, S.R. Panda, K.P. Pradhan, 1T FDSOI Based LIF Neuron without Reset Circuitry: A Proposal and Investigation, IEEE EDTM, Mar. 2023, https://doi. 
org/10.1109/edtm55494.2023.10103130, 2023 7th. 
[6] M.A. Khanday, F.A. Khanday, F. Bashir, F. Zahoor, Exploiting steep sub-threshold swing of tunnel FET for energy-efficient leaky integrate-and-fire neuron 
model, IEEE Trans. Nanotechnol. 22 (2023) 430–435, https://doi.org/10.1109/TNANO.2023.3296557. 
[7] Y. Chen, K. Xiao, Y. Qin, F. Liu, J. Wan, A compact artificial spiking neuron using a sharp-switching FET with ultra-low energy consumption down to 0.45 fJ/ 
spike, IEEE Electron. Device Lett. 44 (1) (Jan. 2023) 160–163, https://doi.org/10.1109/led.2022.3219465. 
[8] M.A. Khanday, S. Rashid, F.A. Khanday, 1T spiking neuron using ferroelectric junctionless FET with ultra-low energy consumption of 24 aJ/spike, Neural 
Process. Lett. (Aug. 2023) 1–13, https://doi.org/10.1007/s11063-023-11387-x. 
[9] M.H. Lee, et al., Steep slope and near non-hysteresis of FETs with antiferroelectric-like HfZrO for low-power electronics, IEEE Electron. Device Lett. 36 (4) (April 
2015) 294–296, https://doi.org/10.1109/LED.2015.2402517. 
[10] F.K. Boucart, A.M. Ionescu, Double-gate tunnel FET with High-$\kappa$ gate dielectric, IEEE Trans. Electron. Dev. 54 (7) (July 2007) 1725–1733, https://doi. 
org/10.1109/TED.2007.899389. 
[11] N. Bouarissa, H. Aourag, Effective masses of electrons and heavy holes in InAs, InSb, GaSb, GaAs and some of their ternary compounds, Infrared Phys. Technol. 
40 (4) (Aug. 1999) 343–349, https://doi.org/10.1016/s1350-4495(99)00020-1. 
[12] Atlas TCAD Device Simulator, Silvaco TCAD software, 2017. 
[13] S. Rashid, F. Bashir, F. A. Khanday and M. R. Beigh, "Dielectrically modulated III-V compound semiconductor based pocket doped tunnel FET for label free 
biosensing applications," IEEE Trans. NanoBioscience, doi: 10.1109/TNB.2022.3178763. 
[14] M.A. Ionescu, Ferroelectric Tunnel FET Switch and Memory, U.S. Patent 8362604B2, 2013. Jan. 29. 
[15] B. Liu, et al., Channel doping effects in negative capacitance field-effect transistors, Solid State Electron. 186 (Dec. 2021) 108181, https://doi.org/10.1016/j. 
sse.2021.108181. 
[16] P. Raut, U. Nanda, D.K. Panda, RF with linearity and non-linearity parameter analysis of gate all around negative capacitance junction less FET (GAA-NC-JLFET) 
for different ferroelectric thickness, Phys. Scripta 97 (10) (Sep. 2022) 105809, https://doi.org/10.1088/1402-4896/ac90fa. 
[17] S. Singh Priyanka, M. Panchore, Emulation of neuro-mimetic dynamics via GaSb/Si heterojunction V-DGTFET leaky-integrate-fire silicon neuron, Micro and 
Nanostructures 185 (Jan. 2024) 207709, https://doi.org/10.1016/j.micrna.2023.207709. 
[18] G.B. Moody, R.G. Mark, The impact of the MIT-BIH arrhythmia database, IEEE Eng. Med. Biol. Mag. 20 (3) (May-June 2001) 45–50, https://doi.org/10.1109/ 
51.932724. 
[19] R. Yuan, et al., A neuromorphic physiological signal processing system based on VO2 memristor for next-generation human-machine interface, Nat. Commun. 
14 (1) (2023), https://doi.org/10.1038/s41467-023-39430-4. 
M.A. Khanday and F.A. Khanday                                                                                                                                                                                  
