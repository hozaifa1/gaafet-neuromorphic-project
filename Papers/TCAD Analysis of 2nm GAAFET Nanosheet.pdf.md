 
Nanoscale Device Design:  
A TCAD Analysis of 2nm GAAFET Nanosheet 
 
 
A Thesis  
Presented in Partial Fulfillment of the Requirements for the  
Degree of Master of Science  
with a  
Major in Electrical Engineering 
in the  
College of Graduate Studies  
University of Idaho  
by  
 
Nathan Totorica 
 
 
 
 
 
Approved by: 
Major Professor: Feng Li, Ph.D. 
Committee Members: Suat Ay, Ph.D.; Herbert Hess, Ph.D. 
Department Administrator: Joseph Law, Ph.D. 
 
 
 
 
May 2024 

ii 
 
Abstract 
The size of field effect transistors used in CMOS integrated circuits shrinks over each technology 
node to achieve lower power consumption, higher performance, and higher density. The increase in 
electrostatic control and reduced short channel effects (SCE) are key benefits to adopting new 
architectures like Gate-All-Around FET (GAAFET) to meet scaling requirements for next generation 
process nodes. Advanced architectures in the nanometer regime bring unique design challenges that 
require thorough characterization of device performance to ensure successful and robust 
implementation. Sentaurus TCAD provides a valuable tool to begin exploring the many design 
choices faced when encountering a novel structure such as GAAFET. Design choices around device 
dimensions, geometries, and materials can be simulated to understand impacts on performance. In this 
work, several of these design choices are explored, such as channel geometry, vertical channel 
stacking, and spacer material options, all in the context of projected parameters for the 2nm 
technology node. Key metrics like transfer characteristics, SCE susceptibility, extension resistance, 
and gate capacitance are used to create a basis for evaluating the device design robustness. The same 
n-type and p-type devices are then simulated using TCAD mixed mode circuit simulation to further 
explore device performance and evaluate tradeoffs. 
 
 

iii 
 
Acknowledgments 
I would like to thank my advisor Dr. Feng Li for the guidance and advice through this process. 

iv 
 
 
Dedication 
To Mylee, for so many amazing years and unconditional support.

v 
 
Table of Contents 
Abstract .................................................................................................................................................. ii 
Acknowledgments ................................................................................................................................. iii 
Dedication ............................................................................................................................................. iv 
Table of Contents ................................................................................................................................... v 
List of Tables ........................................................................................................................................ vii 
List of Figures ..................................................................................................................................... viii 
Chapter 1: Introduction .......................................................................................................................... 1 
Device Scaling ................................................................................................................................ 2 
Short Channel Effects (SCE) .......................................................................................................... 4 
MOSFET Operation ....................................................................................................................... 4 
Electrostatics ............................................................................................................................. 5 
Transport ................................................................................................................................... 6 
FinFET ............................................................................................................................................ 7 
Gate-All-Around FET (GAAFET) ................................................................................................. 7 
Chapter 2: GAAFET Device Simulation ................................................................................................ 9 
Gate Length Scaling ..................................................................................................................... 11 
Drain Induced Barrier Lowering (DIBL) ................................................................................ 12 
Subthreshold Swing (SS) ......................................................................................................... 13 
Gate Induced Drain Leakage (GIDL) ...................................................................................... 14 
Vt Rolloff ................................................................................................................................. 15 
Parasitic Elements ........................................................................................................................ 16 
Resistance ................................................................................................................................ 16 
Gate Capacitance ..................................................................................................................... 17 
Channel Weff ................................................................................................................................. 19 
Channel Height to Width Ratio .................................................................................................... 22 

vi 
 
Dual Vertically Stacked Channels ................................................................................................ 23 
Chapter 3: GAAFET Circuit Performance ........................................................................................... 25 
Ring Oscillator (RO) .................................................................................................................... 25 
Inverter ......................................................................................................................................... 26 
Noise Margins .............................................................................................................................. 29 
Chapter 4: Conclusion .......................................................................................................................... 32 
Bibliography ......................................................................................................................................... 33 
 
 
 

vii 
 
List of Tables 
Table 2.1 Device parameter setup for TCAD simulation ....................................................................... 9 
Table 3.1 Asymmetrical inverter noise margins ................................................................................... 31 
 
 
 

viii 
 
List of Figures 
Figure 1.1 Planar, FinFET, and GAAFET (i.e., MBCFET) [“3NM GAA MBCFET: A Cutting-Edge 
Advancement That Brings Unrivaled SRAM Design Flexibility”]. ................................................ 2 
Figure 1.2 Dennard scaling of semiconductor chip area. ....................................................................... 3 
Figure 1.3 Semiconductor technology node versus gate length [Yu, 2022]. .......................................... 3 
Figure 1.4  nMOS transfer characteristics [Lundstrom, 2018]. .............................................................. 4 
Figure 1.5 Energy band diagrams illustrating the band bending for accumulation, flat band, and 
depletion/inversion regions of operation [Lundstrom, 2018]. .......................................................... 5 
Figure 1.6 Energy band along the length of the channel showing band bending due to drain voltage 
for device with strong gate control [Lundstrom, 2018].................................................................... 6 
Figure 1.7 Differences of Fin pitches and heights for 22nm and 14nm FinFET [Wu, 2018]................. 7 
Figure 2.1 GAAFET SDE Model (Y-Z direction). .............................................................................. 10 
Figure 2.2 Doping concentration for (a) single channel and (b) dual channel device. ......................... 11 
Figure 2.3 Gate voltage versus drain current for gate lengths 10, 14, 24, and 124nm. ........................ 12 
Figure 2.4 Energy band diagram (along channel length) versus device gate length. ........................... 13 
Figure 2.5 Band to band tunneling in (a) lateral and (b) transversal direction [J. Fan et al, 2013]. ..... 15 
Figure 2.6 pn junction depletion region influence on vt Rolloff. ......................................................... 15 
Figure 2.7 S/D resistance extraction. .................................................................................................... 17 
Figure 2.8 CMOS gate capacitance [Baker, 2019]. .............................................................................. 18 
Figure 2.9 Gate voltage versus gate capacitance for single channel device. ........................................ 19 
Figure 2.10 Weff analysis. ..................................................................................................................... 20 
Figure 2.11 Weff analysis for (a) Ion, (b) Ioff, and (c) Ion/Ioff ratio ........................................................... 20 
Figure 2.12 Drain voltage versus drain current across Weff for Vgs=0.7V. ........................................... 21 
Figure 2.13 Weff analysis for (a) SS and (b) DIBL ............................................................................... 21 
Figure 2.14 H/W ratio analysis. ............................................................................................................ 22 
Figure 2.15 H/W analysis for (a) Ion, (b) Ioff, and (c) Ion/Ioff ratio. ........................................................ 23 
Figure 2.16 Gate voltage versus drain current comparison using low-k (Nitride) and high-k (HfO2) 
spacer materials on either single and dual stacked channel. .......................................................... 23 
Figure 2.17 Gate capacitance for Nitride and HfO2 spacer materials on single and dual channel 
devices ............................................................................................................................................ 24 
Figure 3.1 Ring Oscillator (a) schematic and (b) FO1 input/output waveforms. ................................. 26 
Figure 3.2 Inverter schematic [Sentaurus TCAD manuals, 2020]........................................................ 27 
Figure 3.3 Inverter voltage transfer curve (VTC)................................................................................. 28 

ix 
 
Figure 3.4 Inverter transient simulation. .............................................................................................. 29 
Figure 3.5 Inverter (a) asymmetrical VTC and (b) VIH and VIL [Baker, 2019] ................................. 30 
Figure 3.6 First order derivative of the asymmetrical inverter VTC. ................................................... 30 
Figure 3.7 Matched inverter PU/PD network VTC. ............................................................................. 31 

1 
 
Chapter 1: Introduction 
Power, Performance, Area, and Cost (PPAC) demand smaller devices at each technology node. 
Reduced operating voltages necessitate smaller channel lengths to achieve higher speed and 
performance node after node. For decades the transistor architecture has remained largely the same, 
constructed in a 2-dimensiononal plane with a single gate interface. Significant engineering resources 
contributed to the continued device scaling for the planar architecture to counteract worsening short 
channel effects (SCE) and improve overall performance. Some of these key contributions include 
high-k metal gate, strain engineering, ultra-thin body silicon on insulator (UTB-SOI), and a mixture 
of Silicon with novel materials (e.g. Germanium). The introduction of the FinFET was the first major 
industry adopted architectural change to create a 3D structure with multi-gate interface. The FinFET 
extends the channel in the z-axis to form a tall “fin”, with gate interface on three sides of the channel. 
The primary driver for this paradigm shift is the increasingly detrimental SCE and excessive leakage 
current that make planar devices infeasible at the advanced technology nodes. Adopting a multi-gate 
architecture significantly increases the electrostatic control over the channel and the subsequent 
increase in effective width (Weff) helps to boost current density without increased footprint. FinFET 
has delivered promising results in both SCE suppression and overall performance for the 10nm, 7nm, 
and 5nm nodes. However, regarding 3nm and 2nm node, it is expected that even three gates will no 
longer be able to sufficiently suppress SCE and industry will naturally progress to four gates that fully 
encompass the channel on all sides (i.e. Gate-All-Around FET, GAAFET). The GAAFET structure 
typically takes the form of either a nanowire (NW) or nanosheet (NS). For NW, the channel is a 
cylindrical or square shape, while NS (also referred to as MBCFET or RibbonFET) is typically a thin 
rectangular shape. The width of the device can be modulated to provide designers flexibility in tuning 
performance for a given application. Additionally, GAAFET enables the ability to stack channels 
vertically, one over the other, to increase drive current without sacrificing larger dimensions in the x 
and y axes. Figure 1.1 illustrates the geometry differences between planar, FinFET, and NS (i.e., 
MBCFET) devices.  

2 
 
 
Figure 1.1 Planar, FinFET, and GAAFET (i.e., MBCFET) [“3NM GAA MBCFET: A Cutting-Edge Advancement That 
Brings Unrivaled SRAM Design Flexibility”]. 
 
Device Scaling 
Transistor scaling can hardly be mentioned without first acknowledging Moore’s Law, which has 
accurately predicted semiconductor scaling trends for the past several decades. This law is more of an 
economic observation, made by Gordon Moore (co-founder of Intel) in the 1960’s, that stated the 
number of transistors in an integrated circuit will double approximately every two years. Dennard 
scaling of MOSFET devices has enabled this prediction by requiring transistor area to scale by a 
factor of 0.5x, meaning a 0.7x reduction in both the x and y plane (i.e., √0.7 ≈0.5), illustrated by 
Figure 1.2. As the device area shrinks, so does chip capacitance and the necessary voltage and current 
to maintain operation. The electric field (V/m) will remain constant when the distance and voltage 
decrease accordingly, which allows for the increase in operating frequency while overall power 
density remains constant. 

3 
 
 
Figure 1.2 Dennard scaling of semiconductor chip area. 
 
In the past two decades this scaling trend has been increasingly difficult to maintain. Dennard 
scaling in the traditional sense reached its limit due to increased leakage and parasitic impacts. This 
trend results in the gradual tapering of gate length scaling in the mid 2000’s shown by Figure 1.3. The 
nomenclature around channel length and technology node diverged several years before this, around 
the 350nm node. At this point, the channel length was scaled aggressively at a rate greater than 0.7x, 
however, the technology node maintained this interval with more relevance to metal half-pitch. With 
the introduction of the FinFET, the technology node name effectively became meaningless to any 
specific device dimension. 
 
Figure 1.3 Semiconductor technology node versus gate length [Yu, 2022]. 
 

4 
 
Short Channel Effects (SCE) 
The transition from gate lengths measured in micrometers (i.e., microelectronics) to state-of-the-art 
channel lengths in the tens of nanometers (i.e., nanoelectronics) has brought with it an abundance of 
technical challenges. A standard MOSFET log scale Ids versus Vgs curve is shown in Figure 1.4. 
Several primary characteristics of this curve are illustrated, including Ion current, Ioff current, drain 
induced barrier lower (DIBL), subthreshold swing (SS), and threshold voltage (Vt). The Ion current is 
referring to the Ids value when Vgs=Vdd. Similarly, Ioff current is the Ids value when Vgs=0V. The 
degradation of certain characteristics as channel lengths decrease has coined the name “short channel 
effects”. Some of the most common concerns result from a more gradual subthreshold slope, larger 
DIBL shift, decreased Vt, and large Ioff. 
 
Figure 1.4  nMOS transfer characteristics [Lundstrom, 2018]. 
 
MOSFET Operation 
Traditional MOSFET physics states that current is proportional to the width of the device, the amount 
of charge in the channel, and the carrier velocity. Current flow from source to drain is controlled by 
applying voltage to the gate to increase or decrease the energy barrier between source and drain. The 
shape of the I-V curve is a function of device electrostatics from charge in the channel, while the 
magnitude of the current is dependent on the transport (i.e., velocity). Electrostatics and transport are 
the two primary components of transistor physics. 

5 
 
Electrostatics 
A positive electrostatic potential lowers the energy of an electron. This is what enables the gate to 
control the energy barrier present in the channel. Poisson’s equation describes the electric potential of 
the channel in three-dimensional space. Energy band diagrams provide a convenient qualitative 
solution to Poisson’s equation. When a negative gate voltage is applied, both the conduction and 
valence energy bands bend upward. For an n-type device, this has the effect of accumulating holes as 
the valence band bends toward the Fermi level. When applying a positive voltage, the bands bend 
down, which depletes the channel of holes. If the conduction band is bent far enough, the conduction 
band bends toward the Fermi level and the channel inverts as free electrons gather under the gate. The 
band diagrams for accumulation, flat band, and depletion/inversion regimes of operation are 
illustrated in Figure 1.5. For small channel devices, the surface potential and charge in the channel is 
a function of both Vgs and Vds. Figure 1.6 illustrates a ‘well behaved’ energy band structure along the 
channel length in the presence of Vds applied across source and drain terminals. 
 
Figure 1.5 Energy band diagrams illustrating the band bending for accumulation, flat band, and depletion/inversion regions 
of operation [Lundstrom, 2018]. 
 

6 
 
 
Figure 1.6 Energy band along the length of the channel showing band bending due to drain voltage for device with strong 
gate control [Lundstrom, 2018]. 
 
Transport 
The carrier velocity (i.e., drift velocity) is proportional to the electric field as given by 𝑉𝑑= 𝜇𝐸. 
Electron and hole velocity are often different, even under the same electric field. Semi-classical 
transport using Boltzmann Transport Equations (BTE) and Drift Diffusion (DD) has remained the 
basis for carrier transport modeling in transistors for many decades. DD is derived from the BTE 
equations and works well to describe long channel devices (Lg > 1um). For short channel devices, 
gate lengths between 10nm and 100nm, a more accurate representation of transport is often needed. 
Without transitioning to more computationally expensive transport modeling, a quantum confinement 
correction term can be included with the DD to account for the quantum confinement that occurs at 
the channel / gate oxide barrier. The reduction of free carriers affects the current. This type of 
correction allows DD modeling to be used into the deca-nanometer regime. However, as channel 
lengths shrink even further (e.g., Lg <= 10nm) carrier transport approaches the ballistic regime where 
the velocity no longer saturates (i.e., minimal scattering occurs). This quasi-ballistic regime occurs 
when the mean-free time (i.e., the time between a carrier colliding with other carriers, impurities, 
phonons, etc.) is approximately the same length as the channel. To accurately model carrier 
movement requires using the carrier wave function described by Schrödinger’s time-dependent 
equation. 
 

7 
 
FinFET 
The change to a multi-gate, FinFET architecture became a necessary tool to overcome SCEs in the 
most recent advanced technology nodes. A standard FinFET cell typically employs multiple fins for a 
single device to meet the required current density while abiding by end application leakage 
constraints. Standard cell scaling has become increasingly difficult due to cell size limitation by fin-
to-fin pitch, and minimum fin to source/drain (S/D) width ratio to maintain acceptable resistance. Due 
to the limitations, scaling requires a discrete reduction in terms of the number of fins per cell. To 
maintain current drive with fewer fins, the fin heights are extended to increase Weff, however, this can 
lead to process challenges reliably meeting higher aspect ratios. Figure 1.7 depicts the fin pitch and 
height scaling between technology nodes to improve performance and meet scaling requirements. 
Along with logistical challenges, the difficulties to maintain the electrical effectiveness that garnered 
the mass adoption of the FinFET in the first place has become increasingly difficult to manage. 
 
Figure 1.7 Differences of Fin pitches and heights for 22nm and 14nm FinFET [Wu, 2018]. 
 
Gate-All-Around FET (GAAFET) 
The transition to GAAFET architecture strives to solve many of the shortcomings faced by FinFET. 
Several different types of GAAFETs exist depending on the orientation and shape of the channel. 
Broadly, these can be categorized as either lateral or vertical, and NW or NS based on the channel 
dimensions and shape. Although a lot of research is conducted on all types of GAAFET, the most 
promising based on industry trends appears to be lateral NS GAAFET. Like other MOSFET 
architectures, the substrate of the device can consist of either bulk silicon or buried oxide (BOX). 

8 
 
Bulk silicon has continued to be the mainstream option due to cheaper implementation but has the 
drawback of introducing a parasitic channel under the primary channels, that resembles a planar 
MOSFET due to the single gate interface. Several tactics have been explored to reduce the impact of 
this undesirable channel, such as modulating the parasitic channel shape to match more closely to the 
primary channels [Yunho, et al, 2020] and high doping leakage suppression [Jegadheesan, et al, 
2019]. The higher doping concentration increases the threshold voltage to offset from the primary 
channels, thereby reducing the leakage current contributed. An alternative option is to use buried 
oxide approach that forms a thin layer of SiO2 under the GAAFET structure and eliminates the 
parasitic channel all together. 
 

9 
 
Chapter 2: GAAFET Device Simulation 
Sentaurus TCAD is used for the device and circuit characterization of GAAFET NS structures 
[Sentaurus TCAD, 2022]. The device is generated using Sentaurus Structure Editor (SDE), which 
defines the materials, doping profile, and structure dimensions. Sentaurus Device (SDEVICE) is then 
used to define gate electrical characteristics, work-function, and physics models for device 
simulation. Many dimensional parameters are based on IRDS projected dimensions of the 2nm node, 
summarized in table 2.1 [IRDS, 2022]. 
 
Table 2.1 Device parameter setup for TCAD simulation 
N2 Parameter Setup for GAA 
nMOS 
pMOS 
Contacted Gate Pitch (CGP) (nm) 
45 
45 
Gate Length (Lg) (nm) 
14 
14 
Effective Oxide Thickness (EOT) (nm) 
1.32 
1.32 
Spacer (nm) 
6 
6 
Contact (nm) 
19 
19 
Stack Spacer (nm) 
20 
20 
Channel Doping (cm-3) 
2.E+17 
2.E+17 
Source/Drain Doping (cm-3) 
4.E+20 
4.E+20 
Work function (eV) 
4.52 
4.77 
 
Figure 2.1a and 2.1b show a single channel and dual channel device, while Figure 2.1c and 2.1d show 
the cross section along the Y-Z axis of the channel, respectively. Figure 2.2a and 2.2b show the X-Z 
cross section, highlighting the doping concentration profiles of the S/D and channel regions. The 
different cross section views enable easier visualization of the many material layers and region 
interfaces for these complex 3-dimensional structures. 
 

10 
 
 
 
(a) 
(b) 
 
 
(c) 
(d) 
Figure 2.1 GAAFET SDE Model for (a) single and (b) dual channel devices, with channel cross section (Y-Z direction) in 
(c) and (d) respectively. 
 
Several physics models are used conjointly to describe different aspects of material interfaces 
and device operation. A thin layer mobility model is incorporated to accurately describe channel 
geometry dependencies like electrical resistance due to surface roughness and scattering mechanisms. 
Using high-k stack can introduce remote scattering effects from the SiO2 and HfO2 interface. The 
Density Gradient (DG) quantum confinement correction term is included for the DD model to 

11 
 
increase accuracy in the carrier density of states calculation for nanoscale gate lengths. A channel 
length dependent ballistic mobility model is included to adjust doping dependent scattering across 
gate lengths. Generation-recombination and bandgap narrowing due to doping are enabled. Finally, to 
properly capture leakage currents, a non-local band to band tunneling (BTBT) model is used at the 
channel-to-drain and gate-to-drain overlap interface. 
 
 
(a) 
(b) 
Figure 2.2 Doping concentration for (a) single channel and (b) dual channel device. 
 
Parameter extraction relies on several built-in tools from Sentaurus Visual (SVISUAL) for 
extracting Ion, Ioff, SS, and DIBL values. I-V transfer characteristics are simulated at Vds = 0.7V and 
Vds = 0.05V to provide both saturation and linear regimes of operation. Ion and Ioff are extracted from 
I-V curves when Vgs = 0.7V and Vgs = 0V, respectively, with Vds = 0.7V. 
 
Gate Length Scaling 
The GAAFET structure helps to provide a necessary resilience against SCE, however, it is still not 
entirely immune. SCE will continue to be a limitation to how short of a channel length is ultimately 
feasible. Current IRDS predictions show gate length saturating around the 12nm mark [IRDS, 2022]. 
Figure 2.3 compares Ids versus Vgs curves at 124, 24, 14, and 10nm gate lengths. Several obvious 
changes in curve characteristics can be seen at each point as the gate length decreases. A noticeable 
reduction in threshold voltage due to Vt Rolloff and DIBL is present, as well as a degradation of SS as 

12 
 
a consequence of the reduced energy barrier, and a very prominent increase in Ioff current due to 
GIDL as Vgs decreases negatively. 
 
Figure 2.3 Gate voltage versus drain current for gate lengths 10, 14, 24, and 124nm. 
 
Drain Induced Barrier Lowering (DIBL) 
The potential barrier that separates the source and drain begins to see reduced height as these 
terminals become more electrostatically coupled. The voltage applied to the drain has increased 
influence on the barrier height the shorter the channel gets. This phenomenon is problematic since the 
potential barrier becomes a function of both Vgs and Vds and has the effect of the drain voltage 
moving the threshold voltage (Vt) level of the device. Ultimately, the device performance changes 
depending on what drain voltage is applied. This effect can be measured by first generating an Ids-Vgs 
curve in the linear mode of operation (Vds < Vgs - Vt), then again in the saturation region (Vds > Vgs - 
Vt), and using Equation 2.1. 

13 
 
𝐷𝐼𝐵𝐿 =  𝑉𝑡𝑙𝑖𝑛−𝑉𝑡𝑠𝑎𝑡
𝑉𝑑𝑠𝑠𝑎𝑡−𝑉𝑑𝑠𝑙𝑖𝑛
 
(2.1) 
The conduction band energy diagram in Figure 2.4 shows a clear trend in DIBL impact on barrier 
height. The quasi-Fermi level of the drain is lowered by factor of qVds, which distorts equilibrium and 
means that the device will begin conducting current for carriers with enough energy to overcome the 
resulting barrier. The lower the barrier becomes, the less energy is required. 
 
Figure 2.4 Energy band diagram (along channel length) versus device gate length. 
 
Subthreshold Swing (SS) 
The logarithmic decrease in current below the threshold voltage is an important metric to consider 
when characterizing a device. This portion, known as the subthreshold swing, is present for all 
devices and is not an SCE by itself, however, the degradation due to channel length scaling is. This 
metric provides insight to the level of current that will continue to pass through a device even when it 
is off (Ioff). This “leakage” current is typically small for a single device (e.g., nA to pA range), 
however, multiplied by billions of devices, this becomes a major concern for VLSI design, especially 

14 
 
in portable electronic applications. A lower SS will allow for a lower Vt resulting in higher Ion current 
while maintaining the same Ioff current. SS is given in Equation 2.2, 
𝑆𝑆= 𝜕𝑉𝑔𝑠
𝜕𝑙𝑛𝐼𝑑
= 𝜕𝑉𝑔𝑠
𝜕𝜑𝑠
𝜕𝜑𝑠
𝜕𝑙𝑛𝐼𝑑
=  𝑘𝑇
𝑞 𝑙𝑛10 (1 + 𝐶𝑑𝑒𝑝
𝐶𝑜𝑥
) 
(2.2) 
where kT/q is thermal voltage, Cdep is depletion capacitance, and Cox is gate capacitance. The 
𝜕𝑉𝑔𝑠/𝜕𝜑𝑠 describes the gate to channel coupling, referred to as the body factor. The relationship 
between gate voltage (Vgs) and surface potential (𝜑𝑠) is governed by the capacitive voltage divider 
between Cox and Cdep. If Cdep is very small or Cox is large (i.e. strong gate to channel coupling), SS will 
approach the minimum limit of 60 mV/dec. The inverse of SS gives the slope of the subthreshold 
curve. 
 
Gate Induced Drain Leakage (GIDL) 
An important, but easily neglected, region of the device I-V characteristic curve is the range where 
Vgs becomes negative. In this range, the device can experience elevated GIDL due to severe 
conduction and valence band bending. The components of GIDL current typically arise from BTBT 
and can usually be categorized into two main pieces, lateral BTBT (L-BTBT) and transversal BTBT 
(T-BTBT). L-BTBT describes the lateral tunneling that occurs at the pn junction between the channel 
and the drain that usually dominates at smaller negative Vgs voltages. The diagram in Figure 2.5a 
illustrates the band bending that can be aggravated by increasingly negative Vgs. Steep doping profile 
transitions can exacerbate this mechanism. As Vgs decrease more negatively, T-BTBT can become 
more dominate if there is significant overlap between gate and drain regions as exaggerated in Figure 
2.5b. Extremely negative Vgs can lead to direct tunneling through the gate oxide. 
 
(a) 

15 
 
 
(b) 
Figure 2.5 Band to band tunneling in (a) lateral and (b) transversal direction [J. Fan et al, 2013]. 
 
Vt Rolloff 
For an n-type MOSFET to begin conducting (i.e., “turn on”), the gate voltage is increased which first 
depletes the channel of holes to a depth Wdm. As gate voltage continues to increase, an inversion layer 
of electrons is created forming a channel. At this point, the device is “on” and current will flow with 
applied voltage across the S/D contacts. For short channel devices, the depletion regions formed at the 
S/D pn junctions account for a larger contribution to the overall channel depletion compared to long 
channel, depicted by Figure 2.6. Therefore, lower gate voltage is required to deplete the channel to a 
depth, Wdm, and form the inversion layer. From an energy band diagram perspective, this effect can 
result in a lower energy barrier height. 
 
Figure 2.6 pn junction depletion region influence on vt Rolloff. 
 

16 
 
Parasitic Elements 
Inherent to all MOSFET devices are the parasitic elements of resistance and capacitance that come 
with design and architecture choices. At the advanced nodes, devices have moved to 3D architectures 
and with it comes increased parasitic components. These parasitic values begin to approach similar 
magnitudes of the device parameters and if not properly managed, can severely limit the performance 
of the device.  
 
Resistance 
Series resistance contributed from the S/D regions will limit overall Ion capability of the device. The 
total resistance associated with a GAAFET device can be broken down into two main categories as 
shown in Equation 2.3, 
𝑅𝑜𝑛= 𝑅𝑐ℎ+ 𝑅𝑆𝐷 
(2.3) 
where Ron is the total resistance of the device in linear mode of operation, Rch is the resistance 
contributed from the channel, and RSD is the resistance contributed from the S/D extensions. To 
estimate the contribution of each of these parts, an Ron versus gate length analysis is used. Ron is 
plotted over a range of gate lengths and the results are extrapolated to provide a y-intercept that gives 
an approximate resistance for an effective gate length (Leff) of zero. The source and drain are assumed 
to contribute one half of the resulting resistance for Leff = 0nm. Figure 2.7 demonstrates this technique 
and provides the approximation for S/D resistance at the 14nm gate length, equal to 5.6KΩ. The 
channel resistance is then calculated using Equation 2.3, which equates to 1.3KΩ. 

17 
 
 
Figure 2.7 S/D resistance extraction. 
 
The RSD portion can be further broken down into subcategories that include the contact resistance, 
S/D spreading resistance, and spacer extension resistance using a conductance integration method if 
more granular categorization is needed [Sudarshan et al, 2016]. 
 
Gate Capacitance 
CMOS technology power consumption can typically be categorized as either static or dynamic. The 
dynamic power draw is dominate and comes from the device switching logic states (i.e., logic zero to 
one or one to zero). The dynamic power draw can be calculated using Equation 2.4, 
𝑃𝑑= 𝐶𝑓𝑉𝑑𝑑
2 
(2.4) 
where C is the load capacitance, f the operating frequency, and Vdd the operating voltage. On the 
circuit level, the load capacitance equates to the gate capacitance of the circuit that is being driven. 
This gate capacitance is shown as a function of Vgs in Figure 2.8. 
 

18 
 
 
Figure 2.8 CMOS gate capacitance [Baker, 2019]. 
 
Along with power considerations, gate capacitance is also an important consideration for circuit 
speed. Large gate capacitance will increase switching delay and result in slower logic operations. 
Smaller channel widths tend to reduce parasitic capacitance between the S/D regions and if multiple 
channels are vertically stacked. The gate capacitance can be evaluated using TCAD small signal AC 
analysis options, where a complex matrix is calculated from resulting current changes to small 
voltage perturbation at a specified frequency. The imaginary part of this complex matrix is the result 
of the out of phase contribution from device capacitance. Figure 2.9 demonstrates gate capacitance 
for a single channel GAAFET as a function of Vgs, across different MOSFET regions of operation.  

19 
 
 
Figure 2.9 Gate voltage versus gate capacitance (Cgg) for single channel device. 
 
Channel Weff 
The effective width of the NS device is described in Equation 2.5, 
𝑊𝑒𝑓𝑓= 2 × (𝑊𝑖𝑑𝑡ℎ+ 𝐻𝑒𝑖𝑔ℎ𝑡) × 𝑛𝑢𝑚_𝑐ℎ𝑎𝑛𝑛𝑒𝑙𝑠
 
(2.5) 
where the perimeter of the NS device is calculated and multiplied by the number of vertically stacked 
channels (in this case num_channels = 1). To understand channel geometry impacts on performance, 
the channel effective width is adjusted around projected parameters of the 2nm node. Height and 
width parameters for low power devices are projected to be 6nm and 15nm, respectively. This 
analysis simply adjusts the height and width dimensions to change Weff, while maintaining the 
projected height to width ratio of 0.4. Figure 2.10 illustrates the effect of increasing Weff around this 
ratio. 

20 
 
 
Figure 2.10 Weff analysis. 
 
The results for Ion, Ioff, and Ion/Ioff ratio are shown in Figure 2.11. Intuitively, a larger channel created 
with large Weff has a significant increase in Ion current shown by Figure 2.11a. An apparent drawback 
to this is that the Ioff current, depicted in Figure 2.11b, appears to increase at an even greater rate. 
Comparing Ion/Ioff ratio, this asymmetry is even more stark, shown by Figure 2.11c.  
 
 
 
(a) 
(b) 
(c) 
Figure 2.11 Weff analysis for (a) Ion, (b) Ioff, and (c) Ion/Ioff ratio 
 
Examining Figure 2.11a results, there appears to be a significant increase in Ion current for channel 
Weff larger than 30nm. The smaller channel dimensions will suffer from increased resistance due to 
scattering and quantum confinement effects, that will reduce overall Ion current. The extracted Ron 
values are plotted along with the Ids versus Vds curve in Figure 2.12. Significantly larger Ron is 
observed at the smaller Weff values, that then steadily decrease for the larger Weff values. This agrees 
with the Ion versus Weff results shown in Figure 2.11a. A notable decrease in electrostatic control over 
the channel can be observed as the channel dimensions increase shown in subthreshold swing and 
DIBL calculations, Figure 2.13a and 2.13b, respectively. 

21 
 
 
Figure 2.12 Drain voltage versus drain current across Weff for Vgs=0.7V. 
 
 
 
(a) 
(b) 
Figure 2.13 Weff analysis for (a) SS and (b) DIBL 
 

22 
 
Channel Height to Width Ratio 
The height to width (H/W) ratio is now varied while maintaining a constant Weff to understand H/W 
relationship impact on device performance. Figure 2.14 shows the progression from small ratio value 
(i.e., small height and large width), to larger ratio value (i.e., large height and small width). 
 
Figure 2.14 H/W ratio analysis. 
 
The ratios at the extreme ends will produce a thin rectangular shape, while the ratios near 1.0 will 
produce a square shape. Good symmetry between the extreme ratios indicate there is little difference 
as to the orientation of a thin rectangular channel from purely a geometry standpoint, but that the 
thinner the channel the less Ion current is achievable and that subsequently less Ioff current is incurred. 
A square shaped channel will enable a larger Ion, however, the added benefit of this somewhat 
plateaus and the drawback of increased Ioff outweighs the benefits significantly. Figure 2.15a shows 
the mostly flat Ion response across geometry, with a slight peak for a square channel ratio of 1. 
Similarly, to the previous Weff observations there is a significant drop in Ion current for extremely thin 
channels. Confirmed by Ioff results in Figure 2.15b, this suggests too small of channel dimensions will 
encounter detrimental resistivity and mobility degradation from scattering and quantum confinement 
effects. The Ion/Ioff ratio is included in Figure 2.15c. 
This result suggests that the best channel geometry is a rectangular shape, with channel H/W 
ratio in the range of 0.2 to 0.4 for best balance of Ion and Ioff performance. Depending on application 
in either low-power or high-performance electronics, these dimensions can be adjusted according to 
the specific requirements. This result is in good agreement with how IRDS ultimately projected 2nm 
node dimensions on both low-power and high-performance devices. 
 

23 
 
 
 
 
(a) 
(b) 
(c) 
Figure 2.15 H/W analysis for (a) Ion, (b) Ioff, and (c) Ion/Ioff ratio. 
 
Dual Vertically Stacked Channels 
Stacking an additional channel provides a means for increasing Ion current while maintaining a strict 
device footprint. The Ids-Vgs curve in Figure 2.16 shows a near 2x increase in Ion current from adding 
a second channel. The main tradeoff to increasing Ion with this method is a proportional increase in 
Ioff, seen by the subthreshold region of Figure 2.16.  
 
Figure 2.16 Gate voltage versus drain current comparison using low-k (Nitride) and high-k (HfO2) spacer materials on both 
single and dual stacked channel. 

24 
 
Using a high-k material for the spacer region between gate and S/D also shows additional gains in Ion 
current, indicating a boost in gate to channel and gate to channel extension region coupling. The 
HfO2 spacer material appears to add additional Ion increase with minimal impact on Ioff, showing 
similar SS as Nitride. However, an important consideration is the gate capacitance increase from 
using these options. Figure 2.17 shows the total gate capacitance increase for single versus dual 
channel, as well as for Nitride versus HfO2 spacer material. The dual channel and HfO2 options add 
significant increase to gate capacitance. Higher gate capacitance will affect the dynamic power 
consumption as indicated by Equation 2.4, so higher gate capacitance is necessary to consider as a 
tradeoff to increasing device drive with higher Ion current. Similarly, if gate capacitance increases too 
steeply, it can decrease the desired speed benefit of higher drive, since subsequent logic cells will 
create a larger load capacitance. 
 
Figure 2.17 Gate capacitance for Nitride and HfO2 spacer materials on single and dual channel devices 
 
 

25 
 
Chapter 3:  GAAFET Circuit Performance 
TCAD Mixed Mode circuit simulation allows for creating netlists of custom designed devices to 
enable quick feedback on device operation from the circuit perspective. With the growing need for 
Design Technology Co-optimization (DTCO) this is a powerful tool for assessing relevant circuit-
based figures of merit sooner in the device design process. 
 
Ring Oscillator (RO) 
Ring oscillators are commonly used to evaluate process speed. The odd number of inverters in a 
closed loop introduce positive feedback that intentionally causes unstable behavior. The schematic for 
a 3-stage RO is shown in Figure 3.1a, as well as the first stage inverter input and output waveforms in 
Figure 3.1b. The frequency of oscillation can be calculated using Equation 3.1. 
𝑓𝑜𝑠𝑐=
1
𝑛× 𝑡𝑝𝑑
 
(3.1) 
where n is the number of inverters and tpd is the propagation delay of both High-to-Low and Low-to-
High transitions, tPHL + tPLH. A simple fan-out of 1 (F01) is used for 3-stage RO resulting in 
approximately a 15ps oscillation period or oscillation frequency of ~22GHz. The fanout describes the 
number of parallel devices (or equivalent device sizing) at each stage. Larger fanouts (e.g., F03 or 
F04) can be used to increase the speed of the RO and can help represent more typical loading 
conditions so that extracted simulation power and frequency results reflect real world expectation. 
 
(a) 

26 
 
 
(b) 
Figure 3.1 Ring Oscillator (a) schematic and (b) FO1 input/output waveforms. 
 
Inverter 
Taking a deeper dive into the RO performance means looking at the individual inverter stage 
performance by itself. The inverter is one of the most common CMOS circuits used in digital chips, 
so in depth characterization of this circuit has meaningful impact on overall chip performance. The 
schematic for an inverter is shown in Figure 3.2. The circuit is built by using a pMOS pull-up (PU) 
and nMOS pull-down (PD) network. The input signal Vin is connected to the gate of both PU and PD 
networks. The PU network connects to the voltage supply rail, while the PD network connects to the 
reference or ground rail. The circuit output, Vout, is then connected to either the supply rail when Vin 
is low, creating a logic one output, or to ground when Vin is high, creating a logic zero output. From 
the C-V evaluation, an 80aF load is chosen for Cout to replicate the realistic load capacitance of 
driving another inverter stage. The Vin and Vdd voltages are simply modeled using an ideal voltage 
source. 

27 
 
 
Figure 3.2 Inverter schematic [Sentaurus TCAD manuals, 2020]. 
 
Simulating this environment, we can evaluate the voltage transfer curve (VTC) for when Vin switches 
from low to high, shown by Figure 3.3. The switching point, Vsw, is where Vin = Vout, on the VTC 
curve. The ideal switching point, marked by the diagonal line, intersects this point exactly at Vdd/2 
[Weste, Neil H. E., Harris, David Money, 2015]. The switching current is overlayed to show the 
difference between Pdynamic and Pstatic current profiles. Pdynamic is given in Equation 2.4 and Pstatic is 
determined by 𝐼𝑜𝑓𝑓𝑥 𝑉𝑑𝑑. Although Ioff appears minimal compared to Ion, this has continued to be an 
increasing concern due to the growing number of transistors per semiconductor chip. Also, because 
Pstatic does not contribute to any meaningful computation, this is strong motivation for maintaining 
low Ioff on a device level basis. 

28 
 
 
Figure 3.3 Inverter voltage transfer curve (VTC). 
 
A transient simulation in depicted Figure 3.4 shows the ideal voltage source Vin signal with 25ps rise 
and fall time, and the subsequent inverter Vout signal. The Vout signal begins to show some 
characteristic RC delay from charging the 80aF load through the on-state resistance of the PU and PD 
devices. Overlayed on this graph is the alternating current flowing into and out of the load 
capacitance. Notably, a much larger current is seen during the initial switch that will discharge the 
capacitor from its fully charged state before a more symmetrical charge/discharge cycle is seen. 
Current alternates between positive and negative values as the inverter switches from either sinking 
current when the nMOS is active and supplying current when the pMOS is active. The current 
polarity is reflected by this since it is plotted from the Cout perspective. Similar to the VTC in Figure 
3.3, the majority of current is seen only during switching operations. 

29 
 
 
Figure 3.4 Inverter transient simulation. 
 
Noise Margins 
An ideal VTC occurs when the PU and PD devices are well matched, so that the switching point is at 
or very close to Vdd/2. This gives the inverter equal noise margin for both logical 1 and logical 0 
inputs. The VTC in Figure 3.5a was generated using an nMOS and pMOS with identical device 
widths. Plotting the ideal Vsw, it is apparent that the inverter has asymmetry in its transfer 
characteristics. The switching point is approximately 325mV (instead of Vdd/2 = 350mV). This 
translates as a logical 1 having more noise margin than a logical 0. Noise margins are calculated using 
Equation 3.2. 
𝑁𝑀𝐿= 𝑉𝐼𝐿−𝑉𝑂𝐿 
 
𝑁𝑀𝐻= 𝑉𝑂𝐻−𝑉𝐼𝐻 
(3.2) 
 

30 
 
 
 
(a) 
(b) 
Figure 3.5 Inverter (a) asymmetrical VTC and (b) VIH and VIL [Baker, 2019] 
 
The VIL and VIH points, A and B in Figure 3.5b, can be calculated by taking the first order derivative 
of the VTC curve and recording the Vin where the slope is -1. Any input values less than VIL will 
output a full logic one equal to VOH, while any input values greater than VIH will output a logic zero 
equal VOL. Input values greater than VIL but less than VIH can lead to metastability, meaning that that 
the output can result in either a logic one or logic zero and may take an undetermined amount of time 
to resolve one way or the other. Larger device gain creates a steeper VTC curve, bringing VIL and VIH 
closer together, reducing the risk of metastability occurring. 
 
Figure 3.6 First order derivative of the asymmetrical inverter VTC. 

31 
 
Table 3.1 Asymmetrical inverter noise margins 
 
 
The derivative of the VTC curve is shown graphically in Figure 3.6. Plugging these values into 
Equation 3.2, the noise margin for logic 0 and logic 1 are calculated and results shown in table 3.1. 
This describes the amount of input fluctuation from a noisy environment (i.e., the input logic levels 
are not perfectly at Vdd or ground) the inverter can tolerate before potentially risking a metastable 
state. To provide more symmetric noise margins for the PU and PD networks, the widths of the 
devices can be adjusted so that the resistance, and resulting drives, are equal. The result of increasing 
the pMOS width shows how matched inverter drive moves the Vsw to the Vdd/2 point, shown in Figure 
3.7. 
 
Figure 3.7 Matched inverter PU/PD network VTC. 
 
 

32 
 
Chapter 4: Conclusion 
This thesis explores some of the fundamental MOSFET device characterization steps to better 
understand impacts of different design choices. As semiconductor scaling continues to shrink, the 
margin for error shrinks with it. This emphasizes the need for strong understanding of the potential 
roadblocks that SCE may introduce for MOSFETs on the nanometer scale. As shown in this work, 
leveraging TCAD is a powerful way to explore options and accurately assess device characteristics. 
Taking a top-down approach, many aspects of the GAAFET structure are analyzed to determine the 
best parameter options. Starting with channel effective width and geometry, physically accurate 
models help to create a framework for best implementation. Results from sweeping channel 
dimensions align well with the height and width specifications projected by IRDS. This showed H/W 
ratios in range of 0.2 and 0.4 will provide the best tradeoffs between Ion/Ioff ratio. These results should 
be interpreted as guidelines and indicate parameters like Weff can be modulated in conjunction with 
H/W ratio to meet end application needs. While the GAAFET structure is not immune to SCE, the 
increased electrostatic control of the channel can help significantly reduce their impact. Tolerable 
SCE, like SS and DIBL, can be achieved with the GAAFET structure, underlining that channel 
geometry engineering, vertically stacked channels, and material choices are useful knobs to adjust 
performance. Parasitic extraction is necessary to understand tradeoffs to these types of choices, shown 
by fundamental methodologies for resistance and gate capacitance parameter extraction that are 
analyzed and discussed. Circuit level performance metrics, such as RO and inverter VTC, are 
simulated to provide additional context for device level results. 
Ultimately, the transition to GAAFET architecture provides an optimistic outlook that with 
the right tailored approach, GAAFET can enable viable solutions for the 2nm process node (and 
possibly beyond).

33 
 
Bibliography
 “3NM GAA MBCFET: A Cutting-Edge Advancement That Brings Unrivaled SRAM Design 
Flexibility.” Samsung Semiconductor Global, semiconductor.samsung.com/news-
events/tech-blog/3nm-gaa-mbcfet-unrivaled-sram-design-flexibility/. Accessed 21 Apr. 2024.  
Baker, R. Jacob. CMOS Circuit Design, Layout, and Simulation. IEEE Press, 2019.  
 
International roadmap for devices and Systems 2022, 
irds.ieee.org/images/files/pdf/2022/2022IRDS_WP-MtM.pdf. Accessed 21 Apr. 2024.  
 
J. Fan, M. Li, X. Xu and R. Huang, "New observation on gate-induced drain leakage in Silicon 
nanowire transistors with Epi-Free CMOS compatible technology on SOI substrate," 2013 
IEEE SOI-3D-Subthreshold Microelectronics Technology Unified Conference (S3S), 
Monterey, CA, USA, 2013, pp. 1-2, doi: 10.1109/S3S.2013.6716583. 
Jegadheesan, V, et al. “Impact of Geometrical Parameters and Substrate on Analog/RF Performance 
of Stacked Nanosheet Field Effect Transistor.” Materials Science in Semiconductor 
Processing, vol. 93, 2019, pp. 188–195, doi.org/https://doi.org/10.1016/j.mssp.2019.01.003 
Lundstrom, Mark. Fundamentals of Nanotransistors. World Scientific, 2018.  
Sentaurus TCAD (Version R2020-12) Manuals, Synopsys Inc., Mountainview, CA, USA 2020. 
Sudarshan Narayanan, et al, “Extraction of parasitic and channel resistance components in FinFETs 
using TCAD tools”, Solid-State Electronics, Volume 123, 2016, Pages 44-50, ISSN 0038-
1101,https://doi.org/10.1016/j.sse.2016.05.018. 
Weste, Neil H. E., Harris, David Money. CMOS VLSI Design: A Circuits and Systems Perspective. 
Pearson India, 2015.  
Wu, Yung-Chun, and Yi-Ruei Jhan. 3D TCAD Simulation for CMOS Nanoeletronic Devices. 
Springer, 2018.  
Yu, Shimeng. Semiconductor Memory Devices and Circuits. CRC Press, Taylor et Francis Group, 
2022.  
Yunho Choi, et al, “Simulation of the effect of parasitic channel height on characteristics of stacked 
gate-all-around nanosheet FET”, Solid-State Electronics, Volume 164, 2020, 107686, ISSN 
0038-1101, https://doi.org/10.1016/j.sse.2019.107686. 
