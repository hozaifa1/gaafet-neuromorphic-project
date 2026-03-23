1568
IEEE TRANSACTIONS ON ELECTRON DEVICES, VOL. 69, NO. 3, MARCH 2022
Efﬁciency of Ferroelectric Field-Effect
Transistors: An Experimental Study
Nujhat Tasneem
, Graduate Student Member, IEEE, Muhammad M. Islam, Student Member, IEEE,
Zheng Wang
, Graduate Student Member, IEEE, Zijian Zhao, Graduate Student Member, IEEE,
Navnidhi Upadhyay, Sarah F. Lombardo, Hang Chen, Jae Hur
, Member, IEEE, Dina Triyoso,
Steven Consiglio
, Senior Member, IEEE, Kanda Tapily
, Senior Member, IEEE,
Robert Clark
, Member, IEEE, Gert Leusink, Santosh Kurinec
, Life Fellow, IEEE,
Suman Datta
, Fellow, IEEE, Shimeng Yu
, Senior Member, IEEE, Kai Ni
, Member, IEEE,
Matthias Passlack
, Fellow, IEEE, Winston Chern, Member, IEEE,
and Asif Khan
, Member, IEEE
Abstract— While the theoretical maximum of the memory
window Vt in a ferroelectric ﬁeld-effect transistor (FEFET)
is 2ECtF, EC and tF being coercive ﬁeld and FE thickness,
respectively, experimentally Vt is observed to be much
less than that, even in the case of complete polarization
switching in the ferroelectric layer. This occurs because
trapped charges in the gate oxide stack partially or com-
pletely screen the ferroelectric polarization, only a fraction
of which gets “electrostatically” reﬂected in the semicon-
ductor channel. In this article, we provide a generalized
experimental framework to quantify the efﬁciency of practi-
cal FEFETs in converting the switched ferroelectric polariza-
tion into the memory window. To that end, we propose three
efﬁciency metrics: 1) switched ferroelectric polarization
PF to memory window conversion ratio, ηMW = Vt/PF;
2) switched ferroelectric polarization to the semiconductor
charge (QS) conversion efﬁciency or the charge conver-
sion efﬁciency ηc = Qs/PF; and 3) the ratio of memory
window to the width of polarization versus gate voltage
Manuscript received November 12, 2021; revised January 2, 2022;
accepted January 6, 2022. Date of publication January 25, 2022; date of
current version February 24, 2022. This work was supported in part by the
Applications and Systems driven Center for Energy-Efﬁcient Integrated
NanoTechnologies (ASCENT), one of six centers in the Joint University
Microelectronics Program (JUMP), an Semiconductor Research Corpo-
ration (SRC) Program sponsored by the Defense Advanced Research
Projects Agency (DARPA). The review of this article was arranged by
Editor G. Snider. (Corresponding author: Nujhat Tasneem.)
Nujhat Tasneem, Muhammad M. Islam, Zheng Wang, Sarah F. Lom-
bardo, Hang Chen, Jae Hur, Shimeng Yu, Winston Chern, and Asif
Khan are with the School of Electrical and Computer Engineering
(ECE), Georgia Institute of Technology, Atlanta, GA 30318 USA (e-mail:
nujhat.tasneem@gatech.edu).
Zijian Zhao, Santosh Kurinec, and Kai Ni are with the Department
of Electrical and Microelectronic Engineering, Rochester Institute of
Technology, Rochester, NY 14623 USA.
Navnidhi Upadhyay and Suman Datta are with the Department of
Electrical Engineering, University of Notre Dame, Notre Dame, IN 46556
USA.
Dina Triyoso, Steven Consiglio, Kanda Tapily, Robert Clark, and
Gert Leusink are with TEL Technology Center, America, LLC, Albany,
NY 12203 USA.
Matthias Passlack is with Corporate Research, Taiwan Semiconductor
Manufacturing Company Ltd., San Jose, CA 95134 USA.
Color versions of one or more ﬁgures in this article are available at
https://doi.org/10.1109/TED.2022.3141988.
Digital Object Identiﬁer 10.1109/TED.2022.3141988
hysteresis characteristics (VP) or the voltage conversa-
tion efﬁciency ηV = Vt/VP. We measure and compare
these efﬁciency metrics in n-type and p-type FEFETs, fab-
ricated in different facilities by different groups. In all the
cases, we ﬁnd that the maximum values of memory window
efﬁciency (ηMW)max, charge conversion efﬁciency (ηc)max,
and voltage conversion efﬁciency (ηV)max are in the range:
2.5–5.5 Vm2/C, 4%–10%, and 5%–20%, respectively.
Index Terms— Efﬁciency, ferroelectric ﬁeld-effect transis-
tor (FEFET), memory window.
I. INTRODUCTION
F
ERROELECTRIC ﬁeld-effect transistors (FEFETs) have
emerged as an attractive non-volatile memory element for
embedded, data-centric applications, thanks to the discovery of
ferroelectricity in complementary metal–oxide–semiconductor
(CMOS)-compatible binary oxides based on hafnia and zir-
conia [1]. These ﬂuorite-structure ferroelectric oxides are
energy- and area-efﬁcient, suitable for merged logic–memory
functionalities, and compatible with high-volume semiconduc-
tor manufacturing processes [2]–[9]. One of the key design
objectives of an FEFET is to maximize the memory window
Vt for a given write voltage. The theoretical maximum
of Vt is 2ECtF, EC, and tF being coercive ﬁeld and FE
thickness, respectively [10]. However, all reports till date have
shown that Vt ≪2ECtF, even when the ferroelectric layer
in an FEFET operates on a major loop in the polarization (PF)
versus gate voltage (VG) characteristics (i.e., the ferroelectric
layer switches completely). Recent reports have shown that
this occurs due to the screening of ferroelectric polarization
at the interfaces by traps and that only a fraction of the
ferroelectric polarization gets electrostatically reﬂected in the
semiconductor channel, thereby reducing the memory window
signiﬁcantly below its theoretical limit [11]–[14].
Fig. 1 illustrates the discrepancy between the theoretical
framework and the experimental observations with regard to
the memory window in an FEFET. The experimental setups
for measuring the polarization versus gate voltage (P–VG)
and drain current versus gate voltage (ID–VG) characteristics
0018-9383 © 2022 IEEE. Personal use is permitted, but republication/redistribution requires IEEE permission.
See https://www.ieee.org/publications/rights/index.html for more information.
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 

TASNEEM et al.: EFFICIENCY OF FERROELECTRIC FIELD-EFFECT TRANSISTORS: EXPERIMENTAL STUDY
1569
Fig. 1.
(a) Experimental setup to obtain the ferroelectric polarization
versus gate voltage (PF–VG) characteristics between gate (G) and
shorted source (S), drain (D), and body (B) terminals of the FEFET.
(b) Memory window, MW, acquired from the PF–VG loop is denoted by
ΔVP. (c) Experimental setup to obtain the ID–VG characteristics of the
FEFET. (d) Theoretically obtained maximum MW (ΔVt ≈2VC = 2ECtF)
from the ID–VG curve, while (e) shows the experimentally extracted MW
(ΔVt ≪2VC).
of an FEFET are shown in Fig. 1(a) and (c), respectively.
If a given combination of the program and erase voltages
(i.e., the sweep range of VG) leads to a complete polarization
switching, the window of the PF versus VG hysteresis loop,
VP, will follow the relationship VP = VC,+ −VC,−=
2VC = 2ECtF, where VC,+ and VC,−are the coercive voltages
of the ferroelectric layer only in the positive and negative
voltage ranges, respectively, and VC is the average of VC,+
and VC,−[i.e., VC = (VC,+ −VC,−)/2] [see Fig. 1(b)]. If the
sweep range of VG leads to a partial polarization switching,
VP < 2ECtF. Ideally, in either case: a complete polarization
switching or partial, if this polarization is fully translated to the
semiconductor as charge carriers, Vt ≈VP [see Fig. 1(d)].
However, experimentally, interfacial polarization screening by
trapped charges makes the electrostatic coupling between
the ferroelectric layer and the semiconductor channel weak;
hence, Vt is much lower than its theoretical counterpart—i.e.,
Vt ≪VP [see Fig. 1(e)].
Based on this perspective, an important metric for an
FEFET would be one that measures how efﬁcient the switched
ferroelectric polarization is in affecting a shift in the threshold
voltage Vt. We
propose an efﬁciency metric ηMW, which
we refer to as the (switched) polarization to memory window
conversion ratio, deﬁned as follows:
ηMW = Vt
PF
.
(1)
In the ideal case, the maximum value of ηMW, (ηMW)max =
2VC/2P◦= 2ECtF/2P◦, where P◦is the remnant polarization
of the ferroelectric layer. In a more general case that includes
a partial polarization switching, (ηMW)max = VP/2P◦.
At a given VG at which the device is in strong inversion, the
difference between the inversion carrier density between the
Fig. 2. (a) Fabrication process ﬂow of the FEFET. (b) HR-TEM image of
the FEFET gate-stack showing clear interfaces, with the inset showing
the schematic of the FEFET.
programmed and erased states is given by Qs = CONVt,
where CON is the ON-state capacitance of the FEFET. As such,
another metric of FEFET performance can be deﬁned, which
we refer to as ferroelectric polarization to semiconductor
charge conversion efﬁciency, as follows:
ηc = QS
PF
= CONηMW.
(2)
The ratio of the memory window to its theoretical maximum
is another useful metric, deﬁned as follows:
ηV =
ηMW
ηMWmax
= Vt
VP
.
(3)
We refer to this metric as the voltage conversion efﬁciency.
In this study, we establish an experimental protocol to
quantify the polarization to MW conversion ratio and the
charge and voltage conversion efﬁciencies in a ferroelectric
ﬁeld-effect transistor (FEFET). The protocol consists of a
sequence of three measurements: 1) the characterization of
the memory window Vt in the ID–VG characteristics using a
write–read–write–read pulse sequence; 2) the characterization
of the switched polarization PF using positive-up–negative-
down (PUND) method; and 3) the characterization of the
switched polarization PF and memory window VP in
the PF versus VG characteristics for slow sweeps of VG.
We ﬁrst carry out the protocol on a p-typeZrO2 FEFET and
quantify the polarization to MW conversion ratio and the
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 

1570
IEEE TRANSACTIONS ON ELECTRON DEVICES, VOL. 69, NO. 3, MARCH 2022
Fig. 3. Measurement protocol of FEFET metrics–memory window (ID–VG): (a) experimental setup and (b) pulse sequence to determine ΔVt of the
FEFET. (c) FEFET ID–VG and IG–VG characteristics with extracted ΔVt ≈0.5 V. IG ≪ID. The subthreshold slope (SS) of the ID–VG curve before
switching (black dotted curve) is ∼70 mV/dec. However, SS becomes ∼110 mV/dec after both the PGM (red curve) and ERS pulses (blue curve)
are applied on the device. (d) Next two experiments were conducted by using the experimental setup shown for the P–V measurement, where the
pulses were applied to the gate, and the ground was connected to the shorted S, D, and B terminals. Switched polarization (ΔPF, PUND): (e) pulse
sequence to determine ΔPF and (f) corresponding charge plot. The difference between the residual charges (Qres,1 and Qres,1) in this two-pulse
scheme gives the switching charge across the ferroelectric gate capacitor ΔPF as detailed in (g). Hysteresis loops (P–VG): (h) triangular pulses to
determine (i) PF–VG hysteresis loops obtained between G and shorted S, D, and B terminals. ΔPF and ΔVP are obtained from the hysteresis loop
as indicated in (i). Isw–VG curves obtained for 6.25 kHz (red), 10 kHz (blue), and after performing DLCC (black dotted) are also shown in the second
panel of (i).
charge and voltage conversion efﬁciencies. The universality
of the suggested measurement technique is further veriﬁed in
n-type Hf0.5Zr0.5O2 FEFETs fabricated in different facilities.
II. FEFET FABRICATION
A p-type FEFET with the gate-stack composed of 10 nm
of TiN, 5 nm of ZrO2, and 1.5 nm of chemical oxide (SiO2)
was fabricated using a simple gate-last process ﬂow shown
in Fig. 2(a) and the same devices as described in [14]. The
source S and drain D are formed using a 15-keV BF2 ion
implant with a dose of 4 × 1015 cm−2. After activating the
dopants, the gate-stack is formed using chemical oxide growth
and atomic layer deposition (ALD) of TiN/ZrO2, described
in reference [15]. Tungsten is then sputtered, the gate is
patterned using RIE, and the ZrO2 is etched at the vias using
BCl3/Cl2 RIE. The devices are ﬁnalized using a standard
interlayer dielectric (ILD) and metallization process followed
by a forming gas anneal (400 ◦C, 30 min). An n-type HZO
FEFET, the results of which are shown later in this manuscript
(see Figs. 7 and 8), was fabricated at Georgia Tech using the
same process ﬂow as described earlier, except that the source
and drain were formed using P ion implant at 20 keV with
a dose of 1015 cm−2. Fig. 2(b) shows the device schematic
and the cross-sectional high-resolution transmission electron
microscopy (HR-TEM) image of the FEFET gate-stack show-
ing the layer thicknesses and clear interfaces. The gate length,
LG, and width, W, of the measured device in this article are 8
and 80 μm, respectively.
III. MEASUREMENT FOR EFFICIENCY METRICS
The FEFET characterization protocol consists of three sub-
sequent measurements for a given combination of program and
erase voltages (VPGM and VERS, respectively), as follows.
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 

TASNEEM et al.: EFFICIENCY OF FERROELECTRIC FIELD-EFFECT TRANSISTORS: EXPERIMENTAL STUDY
1571
Step 1 Memory window, Vt: Standard memory charac-
teristics were measured using a pre-polarization
pulse—program pulse (PGM)—ID–VG read—erase
pulse (ERS)—ID–VG read sequence as shown in
Fig. 3(b). The sweep speed for the ID–VG read
is 2.5 V/ms. In the case of a p-type FEFET,
the negative ERS pulse lowers the absolute value
of the threshold voltage (|Vt|), while the positive
PGM pulse increases it. The memory window, Vt,
is extracted from the ID–VG curves by taking the
difference in threshold voltages after program and
erase pulses. In this article, we deﬁne Vt as VG at
which ID/W = 10−4 μA/μm. Keysight B1500A
semiconductor device analyzer was used to obtain the
device characteristics. The program and erase pulse
widths were 10 μs. Representative ID–VG and IG–VG
curves (IG being the gate current) for VPGM = 3.4 V
and VERS = −6.6 V are shown in Fig. 3(c). It can
also be seen from Fig. 3(c) that the intrinsic sub-
threshold swing (SS), i.e., the SS of the ID–VG curve
before switching (black dotted curve) is much lower,
close to the ideal value (∼70 mV/dec), which is
indicative of a good quality interfacial oxide (SiO2).
However, the SS after the PGM and ERS voltages
is applied, i.e., the SS of the ID–VG curve after
switching [blue and red curves in Fig. 3(c)] is much
higher (∼110 mV/dec) which implies that the charge
trapping mostly originates after the ferroelectric layer
is switched.
Step 2 Switched polarization, PF: Immediately after the
Vt measurement for a given combination of (VPGM,
VERS), the experimental setup is changed to the
one shown in Fig. 3(d) to measure the switched
polarization (PF) using the positive-up–negative-
down (PUND) scheme [see Fig. 3(e)] by changing
the connection using a switch matrix. PUND pulse
sequence is applied at the gate (G) with the shorted
source, drain, and body (S, D, and B, respectively)
being grounded [see Fig. 3(d)]. Fig. 3(f) shows the
corresponding charge plot which is further detailed
in Fig. 3(g). After applying a pre-polarization pulse,
two subsequent erase ERS) pulses and two pro-
gram (PGM) pulses were applied. In both the cases,
the ﬁrst pulse switches the device under test (DUT),
while the second pulse only contains the dielectric
component and leakages. The difference between the
residual charges in this two-pulse scheme gives the
switching charge across the ferroelectric gate capac-
itor, PF [see Fig. 3(f) and (g)]. The program and
erase pulse widths were 10 μs here as well. Fig. 3(g)
shows the two subsequent voltage pulses (blue)
and the corresponding switching current (green) and
details the switched polarization extraction from the
corresponding charge plots (red).
Step 3 Hysteresis window VP and switched polarization,
PF: Finally, the PF–VG characteristics is mea-
sured by applying a triangular pulsing sequence [see
Fig. 3(h)] to G with the same connections (i.e., S,
Fig. 4. Variation of (a) ΔVt and (b) ΔPF with respect to VERS, and (c) ΔVt
with respect to ΔPF for different values of VPGM in ZrO2 FET. (d) CG–VG
curve for the p-type ZrO2 FEFET.
B, and D shorted) at 6.25 and 10 kHz taking into
account the dynamic leakage current compensation
(DLCC) [16] using a Keysight B1500A semiconduc-
tor device analyzer. The maximum values of the trian-
gular pulse sequence are VPGM and VERS, respectively.
The PF–VG curve [see Fig. 3(i)] shows single loop
hysteresis with consistent two peaks in the switching
current versus gate voltage (Isw–VG) curves—typical
characteristics of an FE material [see Fig. 3(i)]. The
MW obtained from the PF–VG loop is denoted by
VP here. PF, the switched polarization charge of
the FE layer, can also be determined from the PF–VG
loops as indicated in Fig. 3(i).
Vt obtained from step 1 and PF from step 2 which are
plotted as functions of VERS for different values of VPRG are
shown in Fig. 4(a) and (b), respectively. It can be observed
from these ﬁgures that at a given VPRG, an
increase in
|VERS| leads to a monotonic increase in PF, while Vt
increases until |VERS| ≈6.5 V, beyond which it starts to
decrease. This indicates that while |VERS| above 6.5 V results
in further switching of polarization, the increased trapping
effects at this voltage range overcompensate the effects of
the increased ferroelectric polarization on the semiconductor
charge. As a result, the Vt–PF curves for different values
of VPRG as shown in Fig. 4(c) have dome shapes, with the
peak of the dome increasing with the increase in VPRG. The
slope of Vt–PF curves is the switched polarization to
memory window conversion efﬁciency ηMW, as
deﬁned in
Section I. Fig. 5(a) shows the phase plot of ηMW in the (VERS,
VPGM) plane. The ON-state capacitance (CON) of the FEFET
was measured to be 1.34 μF/cm2 [see Fig. 4(d)] using the
impedance analyzer (E4990A). The switched polarization to
semiconductor charge conversion efﬁciency ηC = CONηMW
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 

1572
IEEE TRANSACTIONS ON ELECTRON DEVICES, VOL. 69, NO. 3, MARCH 2022
Fig. 5. Phase maps of two efﬁciency parameters introduced in Section I.
(a) ηMW = ΔVt/ΔPF and (b) ηC = ΔQS/ΔPF for different VPGM and VERS
combinations.
Fig. 6.
(a) PF–VG hysteresis loops including minor loops of the FEFET.
The dashed gray lines show VPGM (≈3.4 V) and VERS (≈−6.6 V) at
which the P–VG goes to the major loop. (b) ΔVP at different VPGM
and VERS combinations obtained from the PF–VG hysteresis loops.
(c) Variation of ΔVt versus ΔVP for different values of VPGM in ZrO2
FET. (d) Phase map of memory ratio ηV = ΔVt/ΔVP for different VPGM
and VERS combinations.
is shown as a phase plot in the (VERS, VPGM) plane in
Fig. 5(b). We observe in Fig. 5(b) that in this particular device,
only 1%–3.5% of the switched ferroelectric polarization gets
reﬂected as the semiconductor charge.
Fig. 6(a) Major hysteresis loop in the PF–VG characteristics
obtained by sweeping VG between 3.4 and −6.6 V as well as a
number of minor loops obtained by sweeping VG in a smaller
voltage range. It is clearly observed that the width of the major
hysteresis loop VP (≈9 V) is much higher than the memory
window Vt (≈0.7 V) obtained for the corresponding write
voltages VPGM = 3.4 V and VERS = −6.6 V. Fig. 6(b) plots
VP as a function of VERS for different values of VPGM, while
Fig. 6(c) plots Vt as a function of VP. Finally, the voltage
conversion efﬁciency, ηV = Vt/VP, is plotted in Fig. 6(d).
It is observed that ηV is only 2%–5% of its theoretical limit
(≈1). The measurements were performed without waking up
the devices, since the values of PF and VP and hence
the efﬁciency remain approximately the same before and after
wakeup.
Fig. 7.
ID–VG curves for Hf0.5Zr0.5O2 n-FEFETs fabricated at
(a) GT, (b) UND, and (c) RIT. PF–VG hysteresis loops for HZO n-FEFETs
fabricated at (d) GATech, (e) UND, and (f) RIT. CG–VG curves for the
same n-FEFETs fabricated at (g) GATech, (h) UND, and (j) RIT.
IV. COMPARISON OF EFFICIENCY BETWEEN
DIFFERENT FEFETS
With the protocol for the measurement of FEFET efﬁciency
metrics established in the previous section, we now compare
different FEFETs of different types and fabricated in different
facilities in terms of efﬁciencies. In addition to the p-type
ZrO2-based FEFET discussed in the previous section, we con-
sider an n-type FEFET with a 10-nm Hf0.5Zr0.5O2 ferroelectric
layer fabricated at the Georgia Tech (GT) cleanroom, an
n-type FEFET with a 10-nm Hf0.5Zr0.5O2 ferroelectric layer
fabricated at the University of Notre Dame (UND) cleanroom,
and an n-type FEFET with a 10-nm Hf0.5Zr0.5O2 ferroelectric
layer fabricated at the Rochester Institute of Technology (RIT)
cleanroom. Fig. 7 shows the ID–VG, PF–VG, and CG–VG
characteristics of these devices. Fig. 8(a) and (b) shows the
comparison of Vt −PF and Vt −VP characteristics
among these devices. The polarization to MW conversion ratio
(ηMW) for all the FETs [see Fig. 8(c)] stays below 5.5 Vm2/C.
The voltage conversion efﬁciency ηV stays below 20%, and
the charge conversion efﬁciency ηC stays below 10% for the
four FEFETs as evident in Fig. 8(d) and (e), respectively. The
maximum values for ηMW, ηV , and ηC for the four devices
are shown in Fig. 8(f)–(h), respectively. The (ηMW)max ranges
from 2.5 to 5.5 Vm2/C [see Fig. 8(f)] which indicates that if
the remnant polarization is 20 μC/cm2, the maximum MW
will be only 0.5–1.1 V. Fig. 8(g) also shows that the n-type
HZO FEFETs from all three facilities (GT, ND, and RIT) are
observed to be more efﬁcient with regard to ηV than the p-type
ZrO2 FEFET, which is mostly due to the much higher voltage
required to switch the ferroelectric ZrO2. Finally, it is evident
from Fig. 8(h) that maximum 4%–10% of the switched FE
polarization is translated to the semiconductor as inversion
carriers.
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 

TASNEEM et al.: EFFICIENCY OF FERROELECTRIC FIELD-EFFECT TRANSISTORS: EXPERIMENTAL STUDY
1573
Fig. 8.
(a) ΔVt versus ΔPF, and (b) ΔVt versus ΔVP for four different FEFETs (blue: ZrO2 p-FEFET and red: Hf0.5Zr0.5O2 n-FEFET fabricated at
GT, green: Hf0.5Zr0.5O2 n-FEFET fabricated at UND, and black: Hf0.5Zr0.5O2 n-FEFET fabricated at RIT). (c) ηMW = ΔVt/ΔPF, (d) ηV = ΔVt/ΔVP,
and (e) ηC = ΔQS/ΔPF versus VERS for the four FEFETs. (f) ηMW,max (range ∼2.5–5.5 Vm2/C), (g) ηV,max (range ∼5–20 ), and (h) ηC,max (range
∼4–10 ) for the four devices. These plots were evaluated for the four FEFETs at the minimum VPGM which gives the maximum ΔVt : VPGM = 3.4 V
for the ZrO2 p-FEFET and VPGM = 4 V for the Hf0.5Zr0.5O2 n-FEFETs.
We
note
that
the
PF–VG
curves
shown
in
Figs. 3(i) and 7(d)–(f)
do
not
have
an
odd
symmetry
[i.e., PF(VG) ̸= −PF(−VG)], as one would expect for the
case of an ideal metal–ferroelectric–metal (MFM) capacitor
with top and bottom electrodes with the same work-functions
and no trapped charges. To that end, we note that such a
symmetry is not guaranteed in the PF–VG characteristics
of
a
metal–ferroelectric–insulator–semiconductor
(MFIS)
structure, i.e., the gate-stack of an FEFET—even in the
ideal case. This is because the semiconductor charge–voltage
characteristics
of
a
standard
metal–oxide–semiconductor
(MOS)
structure
includes
accumulation,
depletion,
and
inversion regions and hence is not odd-symmetric. The
presence of bulk and interface traps and difference in the
work-function between the metal and the semiconductor
layer may add further to the asymmetry. All these factors
lead to a situation that the coercive voltages in the FEFET
P–VG curves are not symmetric with respect to VG = 0
(i.e., VC+ ̸= |VC−|). Such an asymmetry is particularly more
pronounced in the FEFET PF–VG characteristics shown in
Figs. 3(i) and 7(f), wherein |VC−| > VC+. In both of these
cases, VG had to be swept to a larger value in the negative
side than in the positive side. As such, PF at the most negative
VG is larger in magnitude than that at the most positive VG.
V. CONCLUSION
In summary, we established a generalized experimental
framework to quantify the efﬁciency of practical FEFETs
in converting the switched ferroelectric polarization into the
memory window. This was achieved by a measurement proto-
col where the memory window, the switched polarization, and
the width of the polarization versus gate voltage hysteresis
characteristics were all measured on the same devices, subse-
quently for a given value of program and erase voltages. Based
thereon, we calculated three efﬁciency metrics: 1) switched
ferroelectric polarization PF to memory window conversion
ratio ηMW = Vt/PF; 2) switched ferroelectric polarization
to the semiconductor charge (QS) conversion efﬁciency or
the charge conversion efﬁciency ηc = Qs/PF; and 3) the
ratio of memory window to the width of polarization versus
gate voltage hysteresis characteristics (VP) or the voltage
conversation efﬁciency ηV = Vt/VP. We measure and
compare these efﬁciency metrics in n-type and p-type FEFETs,
fabricated in different facilities in different groups. In all the
cases, we ﬁnd that the maximum values of polarization to
MW conversion ratio (ηMW)max, charge conversion efﬁciency
(ηc)max, and voltage conversion efﬁciency (ηV )max are in the
range: 2.5–5.5 Vm2/C, 4%–10%, and 5%–20%, respectively.
Our work is a step toward establishing efﬁciency metrics
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 

1574
IEEE TRANSACTIONS ON ELECTRON DEVICES, VOL. 69, NO. 3, MARCH 2022
for ferroelectric devices which will allow for the commu-
nity to benchmark FEFET results generated all across the
globe, leading toward an informed and steady progress of the
ﬁeld.
ACKNOWLEDGMENT
The TEL Technology Center is acknowledged for depositing
the ALD ZrO2 stack.
REFERENCES
[1] J. Müller et al., “Ferroelectricity in simple binary ZrO2 and HfO2,”
Nano Lett., vol. 12, no. 8, pp. 4318–4323, Jul. 2012, doi: 10.1021/
nl302049k.
[2] J. Hoffman et al., “Ferroelectric ﬁeld effect transistors for memory appli-
cations,” Adv. Mater., vol. 22, nos. 26–27, pp. 2957–2961, Apr. 2010,
doi: 10.1002/adma.200904327.
[3] M. Trentzsch et al., “A 28 nm HKMG super low power embedded NVM
technology based on ferroelectric FETs,” in IEDM Tech. Dig., Dec. 2016,
pp. 5–11, doi: 10.1109/IEDM.2016.7838397.
[4] S. Dunkel et al., “A FeFET based super-low-power ultra-fast embedded
NVM technology for 22 nm FDSOI and beyond,” in IEDM Tech. Dig.,
Dec. 2017, pp. 7–19, doi: 10.1109/IEDM.2017.8268425.
[5] K. Ni et al., “A novel ferroelectric superlattice based multi-level cell
non-volatile memory,” in IEDM Tech. Dig., Dec. 2019, pp. 8–28, doi:
10.1109/IEDM19573.2019.8993670.
[6] S. S. Cheema et al., “Enhanced ferroelectricity in ultrathin ﬁlms grown
directly on silicon,” Nature, vol. 580, no. 7804, pp. 478–482, Apr. 2020,
doi: 10.1038/s41586-020-2208-x.
[7] T. Mikolajick, U. Schroeder, and S. Slesazeck, “The past, the present,
and the future of ferroelectric memories,” IEEE Trans. Electron
Devices, vol. 67, no. 4, pp. 1434–1443, Mar. 2020, doi: 10.1109/TED.
2020.2976148.
[8] A. I. Khan, A. Keshavarzi, and S. Datta, “The future of ferroelectric
ﬁeld-effect transistor technology,” Nature Electron., vol. 3, no. 10,
pp. 588–597, Oct. 2020, doi: 10.1038/s41928-020-00492-7.
[9] A. J. Tan et al., “Ferroelectric HfO2 memory transistors with high-κ
interfacial layer and write endurance exceeding 1010 cycles,” IEEE
Electron Device Lett., vol. 42, no. 7, pp. 994–997, Jul. 2021, doi:
10.1109/LED.2021.3083219.
[10] H.-T. Lue, C.-J. Wu, and T.-Y. Tseng, “Device modeling of fer-
roelectric memory ﬁeld-effect transistor (FeMFET),” IEEE Trans.
Electron Devices, vol. 49, no. 10, pp. 1790–1798, Oct. 2002, doi:
10.1109/TED.2002.803626.
[11] K. Toprasertpong, M. Takenaka, and S. Takagi, “Direct observation
of interface charge behaviors in FeFET by quasi-static split CV and
Hall techniques: Revealing FeFET operation,” in IEDM Tech. Dig.,
Dec. 2019, pp. 7–23, doi: 10.1109/IEDM19573.2019.8993664.
[12] K. Toprasertpong, Z. Y. Lin, T. E. Lee, M. Takenaka, and S. Takagi,
“Asymmetric polarization response of electrons and holes in Si FeFETs:
Demonstration of absolute polarization hysteresis loop and inversion
hole density over 2×1013 cm2,” in Proc. IEEE Symp. VLSI Technol.,
Jun. 2020, pp. 1–2.
[13] R. Ichihara et al., “Re-examination of vth window and reliability in
HfO2 FeFET based on the direct extraction of spontaneous polarization
and trap charge during memory operation,” in Proc. IEEE Symp.
VLSI Technol., Jun. 2020, pp. 1–2, doi: 10.1109/VLSITechnology18217.
2020.9265055.
[14] N.
Tasneem
et
al.,
“The
impacts
of
ferroelectric
and
interfa-
cial layer thicknesses
on ferroelectric
FET design,” IEEE Elec-
tron Device Lett., vol. 42, no. 8, pp. 1156–1159, Aug. 2021, doi:
10.1109/LED.2021.3088388.
[15] V. Mukundan et al., “Structural correlation of ferroelectric behavior
in mixed hafnia-zirconia high-K dielectrics for FeRAM and NCFET
applications,” MRS Adv., vol. 4, no. 9, pp. 545–551, Feb. 2019, doi:
10.1557/adv.2019.148.
[16] R. Meyer, R. Waser, K. Prume, T. Schmitz, and S. Tiedke, “Dynamic
leakage current compensation in ferroelectric thin-ﬁlm capacitor struc-
tures,” Appl. Phys. Lett., vol. 86, no. 14, Apr. 2005, Art. no. 142907,
doi: 10.1063/1.1897425.
Authorized licensed use limited to: Biruni Universitesi. Downloaded on November 09,2022 at 17:17:46 UTC from IEEE Xplore.  Restrictions apply. 
