![](images/d04a098dd8e90150a25439c6f384bdbc1d08e4c7d6e4a5297df3c6d165cb1d23.jpg)

Check for updates

# OPEN ACCESS

EDITED BY

Patrick D. Lomenzo,

NaMLab gGmbH, Germany

REVIEWED BY

Amey Walke,

Interuniversity Microelectronics Centre

(IMEC),Belgium

Maximilian Lederer,

Fraunhofer Institute for Photonic

Microsystems, Germany

*CORRESPONDENCE

Xin Wen,

wenx@iis.ee.ethz.ch

SPECIALTY SECTION

This article was submitted to

Nanoelectronics

a section of the journal

Frontiers in Nanotechnology

RECEIVED 20 March 2022

ACCEPTED 19 July 2022

PUBLISHED 25 August 2022

CITATION

Wen X, Halter M, Bégon-Lours L and Luisier M (2022), Physical modeling of HZO-based ferroelectric field-effect

transistors with a  $\mathsf{WO}_{\mathsf{x}}$  channel

Front. Nanotechnol. 4:900592.

doi: 10.3389/fnano.2022.900592

COPYRIGHT

© 2022 Wen, Halter, Bégon-Lours and Luisier. This is an open-access article distributed under the terms of the

Creative Commons Attribution License

(CC BY). The use, distribution or reproduction in other forums is permitted, provided the original

author(s) and the copyright owner(s) are credited and that the original publication in this journal is cited, in

accordance with accepted academic practice. No use, distribution or

reproduction is permitted which does not comply with these terms.

# Physical modeling of HZO-based ferroelectric field-effect transistors with a  $\mathrm{WO}_x$  channel

Xin Wen $^{1*}$ , Mattia Halter $^{1,2}$ , Laura Bégon-Lours $^{2}$  and Mathieu Luisier $^{1}$

<sup>1</sup>Integrated Systems Laboratory, Department of Electrical Engineering and Information Technology, Zurich, Switzerland, <sup>2</sup>IBM Research GmbH—Zurich Research Laboratory, Rüschlikon, Switzerland

The quasistatic and transient transfer characteristics of  $\mathrm{Hf_{0.57}Zr_{0.43}O_2}$  (HZO)-based ferroelectric field-effect transistors (FeFETs) with a  $\mathrm{WO}_x$  channel are investigated using a 2-D time-dependent Ginzburg-Landau model as implemented in a state-of-the-art technology computer aided design tool. Starting from an existing FeFET configuration, the influence of different design parameters and geometries is analyzed before providing guidelines for next-generation devices with an increased "high  $(R_H)$  to low  $(R_L)$ " resistance ratio, i.e.,  $R_H / R_L$ . The suitability of FeFETs as solid-state synapses in memristive crossbar arrays depends on this parameter. Simulations predict that a 13 times larger  $R_H / R_L$  ratio can be achieved in a double-gate FeFET, as compared to a back-gated one with the same channel geometry and ferroelectric layer. The observed improvement can be attributed to the enhanced electrostatic control over the semiconducting channel thanks to the addition of a second gate. A similar effect is obtained by thinning either the HZO dielectric or the  $\mathrm{WO}_x$  channel. These findings could pave the way for FeFETs with enhanced synaptic-like properties that play a key role in future neuromorphic computing applications.

KEYWORDS

HZO, FeFET, TCAD, ferroelectric modeling, device simulation

# 1 Introduction

It has recently been shown that ferroelectric field-effect transistors (FeFETs) can function both as integrate-and-fire (IF) neurons (Mulaosmanovic et al., 2017; Chen et al., 2019) as well as solid-state synapses (Mulaosmanovic et al., 2018; Sun et al., 2018). They could thus build the core of brain-inspired spiking neural networks (SNNs) and other neuromorphic processors. For example, 5-bit analogue synaptic cores made of  $\mathrm{HfO_2}$ -based FeFETs and utilized as on-line accelerators have been demonstrated to outperform competing hardware solutions relying on conventional resistive random access memories (RAMs) by a factor of  $10^{3}$  to  $10^{6}$  in terms of speed (Jerry et al., 2017). Moreover, similar to spin-transfer-torque magnetic RAMs, the switching mechanism of FeFETs is extremely energy-efficient as it does not involve any material or structural changes. The resulting conductance modulation, which corresponds to the weight updates

of artificial neural networks (Zhao et al., 2011; Apalkov et al., 2013; Mulaosmanovic et al., 2015; Ali et al., 2018; Sun et al., 2018), occurs through the polarization switching of ferroelectric domains or grains. Hence, FeFETs are characterized by an improved reliability, as compared to synaptic devices taking advantage of ion-migration processes or phase-change materials.

Despite these impressive achievements, FeFETs have not yet reached their full potential: design guidelines that could lead to enhanced figures-of-merit are still needed. Device simulation, in particular technology computer aided design (TCAD), lends itself naturally to the creation of such guidelines. Here, the Sentaurus-Device (S-Device) TCAD tool has been selected to optimize the performance of FeFETs (Synopsys, 2019). It features a recently developed physical model that captures the switching of ferroelectric layers (Mulaosmanovic et al., 2015). The objective of this work is therefore twofold: first shedding light on the functionality of FeFETs and then carefully adjusting their design parameters in order to improve their behavior as solid-state synapses. The focus is on transistors with a  $\mathrm{WO}_x$  metal-oxide channel combined with a  $\mathrm{Hf}_x\mathrm{Zr}_{1 - x}\mathrm{O}_2$  (HZO) ferroelectric dielectric layer. Note that in all simulations conventional semiconductor transport based on drift-diffusion phenomena is assumed to describe the conduction mechanisms occurring in the amorphous oxide channel.

To accurately model the peculiarities of HZO layers, a two-to three-dimensional Ginzburg-Landau-type numerical approach is necessary (Chandra and Littlewood, 2007). Important is that it offers the possibility to explicitly account for the presence of grains displaying different polarization switching properties (Noh et al., 2019). In S-Device, such a model has been incorporated into a classical drift-diffusion solver which is employed to describe the electron and hole transport characteristics of the  $\mathrm{WO}_x$  semiconducting channel and to compute the resulting electrical currents (Selberherr, 1984).

Before providing novel design guidelines, the simulation procedure was first calibrated with the help of an existing back-gated  $\mathrm{Hf}_{0.57}\mathrm{Zr}_{0.43}\mathrm{O}_2$ -based FeFET incorporating a  $\mathrm{WO}_x$  channel similar to the one presented in (Halter et al., 2020). After a careful adaptation of the simulation parameters, a satisfactory agreement between the calculated and measured transfer characteristics of the FeFET testbed could be obtained, using a relatively simple 2-D geometry. In particular, a hysteretic window with a width of about  $2\mathrm{V}$  was extracted from the simulation, a value similar to the experimental one, but with a slightly different shape. The slope of the current with respect to the applied voltage, i.e.,  $dI_{D} / dV_{GS}$ , was found to be more flat in experiments, a phenomenon that can be attributed to the formation of a high density of ferroelectric grains inside the HZO. The characteristics of the considered FeFET have then been refined by accounting for the presence of multiple ferroelectric domains. As the number of domains increases in the HZO layer, the slope of the hysteresis loop decreases, provided that the standard deviation of the Landau

coefficients between different domain exhibits a large enough range.

Such a calibration of the available physical models is essential before moving to the exploration phase, the optimization of FeFETs for neuromorphic computing applications. To act as solid-state synapses, FeFETs should fulfill very specific requirements: it should be possible to modulate their resistance (or conductance) over a large dynamic range by applying positive and negative electrical pulses (potentiation and depression). A high number of intermediate states, ideally equal to or larger than 32, should be reachable between the minimum  $(R_{L})$  and maximum  $(R_{H})$  values of the resistance, which correspond to the low (LRS) and high resistance state (HRS) of the device, respectively. Finally, the response of FeFETs to potentiation and depression stimulations should be as symmetric and linear as possible (Gokmen and Vlasov, 2016).

Here, we concentrate on the  $R_{H} / R_{L}$  resistance ratio, which should be maximized, while also considering the number of achievable states in between. The impact of various design parameters on these quantities will be thoroughly investigated. It will be shown that the  $R_{H} / R_{L}$  ratio increases as the thickness of the ferroelectric HZO layer decreases. This behavior can be explained by the enhanced gate control over the channel as the thickness of the ferroelectric layer is reduced. The same happens when the  $\mathrm{WO}_x$  channel is made thinner. Other design parameters will be discussed as well, among them the gate length and the introduction of a second gate contact, which provides the largest improvement among all considered options.

The paper is organized as follows: in Section 2, the simulation approach is presented, followed by the model calibration and multi-domain characterization in Section 3. Section 4 is dedicated to the influence of the different design parameters on the behavior of FeFET before drawing conclusions in Section 5.

# 2 Simulation approach

As technology computer aided design (TCAD) tool, the Sentaurus-Device (S-Device) package from Synopsys is employed to describe the physical characteristics of the investigated FeFETs (Synopsys, 2019). The simulation of such devices requires a special treatment due to the presence of switchable polarization within their dielectric layer. To address this issue, an electrostatic model based on the time-dependent Ginzburg-Landau (TDGL) equations and dedicated to ferroelectric materials and devices was implemented in S-Device (Synopsys, 2019). The TDGL equations extend Poisson's equation, while the transport properties are still captured by the drift-diffusion solver of S-Device.

The starting point of the S-Device TDGL model is the free-energy density of ferroelectric crystals, as proposed in (Starkov et al., 2013). This approach takes into account the electrostatic

potential-polarization coupling and is therefore very suitable for device simulations, where a gate voltage modifies the polarization of an oxide layer. The original formalism was extended to treat non-uniform polarizations (Chandra and Littlewood, 2007). To include the influence of the semiconductor material into this thermodynamic description, a variational principle of Poisson's equation is employed. The electronic charge density is incorporated into an energy functional  $\Pi$ , which represents the total potential energy of the system. It has the following form:

$$
\Pi = \int_ {\Omega} \left(\alpha_ {i} P _ {i} ^ {2} + \beta_ {i} P _ {i} ^ {4} + \gamma_ {i} P _ {i} ^ {6} + g _ {i j} | \nabla_ {j} P _ {i} | ^ {2} + \nabla_ {i} \psi P _ {i} - \frac {\varepsilon}{2} | \nabla \psi | ^ {2} + \psi \rho_ {q}\right) d \mathbf {r}, \tag {1}
$$

where  $\nabla_{j}P_{i} = \frac{\partial P_{i}}{\partial x_{j}}$ . In Eq. 1, the Einstein's summation convention is used. The first three terms correspond to the Landau energy density due to the polarization  $P_{i}$  along the cartesian coordinate  $i$ . They depend on the Landau coefficients  $\alpha_{i},\beta_{i}$ , and  $\gamma_{i}$ . The fourth term of the Ginzburg-Landau theory accounts for an additional energy cost caused by non-uniform polarizations and is proportional to  $g_{ij}$ , where  $j = \{x,y,z\}$ . The fifth term is the electrostatic potential-polarization coupling, while the last two terms represent the electrostatic field energy, including the semiconductor charge contribution  $\rho_{q}$ . Finally,  $\psi$  stands for the electrostatic potential, the main unknown quantity.

Considering the stationarity condition for the functional in Eq. 1, i.e.,  $\delta \Pi = 0$ , a set of partial differential equations (PDEs) can be derived (Zienkiewicz et al., 2005). Differentiating and integrating by parts Eq. 1 gives:

$$
\left\{ \begin{array}{l} - \varepsilon_ {0} \Delta \psi = - \nabla \mathbf {P} + \rho_ {q}, \\ 2 \alpha_ {i} P _ {i} + 4 \beta_ {i} P _ {i} ^ {3} + 6 \gamma_ {i} P _ {i} ^ {5} - 2 g _ {i j} \Delta P _ {i} + \rho \frac {d P _ {i}}{d t} = - \nabla_ {i} \psi . \end{array} \right. \tag {2}
$$

In Eq. 2,  $\mathbf{P}$  is the polarization vector and  $\varepsilon_0$  the vacuum permittivity.  $\rho$  corresponds to polarization viscosity introduced to represent the dynamics during polarization switching. The system in Eq. 2 can be solved in a device domain by applying the following boundary conditions:

$$
\psi = V _ {G} \quad \text {o n} \quad \Gamma_ {C}; \tag {3}
$$

$$
\left(- \varepsilon_ {0} \nabla \psi + \mathbf {P}\right) \cdot \mathbf {n} _ {\text {o u t}} = 0 \quad \text {o n} \quad \Gamma_ {\text {e x t}}, \tag {4}
$$

where  $\Gamma_C$  delimits the contour of the gate contact(s) and  $\Gamma_{ext}$  refers to the rest of the exterior domain boundaries. The  $\mathbf{n}_{\mathrm{out}}$  vector is orthogonal to the boundary domain and normalized.

Due to its mixed formulation and possible discontinuities of the polarization field at interfaces, the space discretization of the system in Eq. 2 presents several numerical challenges. Typically, strong oscillations of the polarization vector inside the ferroelectric layer are observed when implementing a "simple" finite-difference discretization scheme on a staggered grid.

To avoid such spurious oscillations that may lead to divergences of the numerical solution, a stabilized discretization scheme is necessary. In S-Device, a

![](images/65768513c1ed9ee211bd272bf02280b77b76521718f1e0299c9d293f459a910a.jpg)  
FIGURE 1 Epitaxial structure of the HZO-based, back-gated FeFET which serves as a calibration reference for this work (Halter et al., 2020). The ferroelectric HZO gate dielectric, the  $\mathrm{WO}_x$  channel, the source (S), the drain (D), and the gate (G) regions are indicated. The thickness of all layers and the channel length are given in nanometers and micrometers, respectively. Note that only 2-D structure is used during simulations.

discontinuous Galerkin finite element method is applied because of the stability it provides when dealing with problems of a similar form as Eq. 2 (Cockburn et al., 2002). The application of the Galerkin method requires rewriting Eq. 2 in a conservative form. This can be done by introducing an auxiliary flux corresponding to the displacement vector  $\mathbf{D} = -\varepsilon_0\nabla \psi +\mathbf{P}$ . Gauss's law of electrostatics can then be enforced element-by-element in a conservative way, with properly formulated numerical fluxes that ensure the stability of the method.

The Landau coefficients  $\alpha_{i},\beta_{i}$ , and  $\gamma_{i}$  are inputs to the solver. They can either be extracted from capacitor measurements or computed from density-functional theory (DFT) (Sholl and Steckel, 2011). The same applies to the polarization gradient coefficient  $g_{ij}$ . The coupling to the electronic transport comes from the charge density  $\rho_{q}$ , which, in S-Device, is calculated at the drift-diffusion (DD) level. All equations derived from the expression one are solved self-consistently with the DD ones.

# 3 Results and discussion

# 3.1 Model calibration

As starting point, the back-gated ferroelectric  $\mathrm{Hf}_{0.57}\mathrm{Zr}_{0.43}\mathrm{O}_2$  (HZO) field-effect transistor (FeFET) with a tungsten metal-oxide  $(\mathrm{WO}_x)$  channel similar to (Halter et al., 2020) is examined. Its epitaxial structure is displayed in Figure 1. The channel width (along the z-axis) and length (along the x-axis) of the considered device are equal to  $2\mu \mathrm{m}$  and  $0.8\mu \mathrm{m}$ , respectively. The measurements of the FeFET in Figure 2 serve as a reference to calibrate all material parameters of the two-dimensional (2-D)

![](images/7766661f53ecff05a432a652f3413919723c065cdd85b21327cf95b08770cfbb.jpg)  
FIGURE 2 Experimental (solid blue line) and simulation (dash-dotted red line) DC characteristics for the FeFET in Figure 1 with an 8 nm-thick  $\mathsf{WO}_x$  channel (Halter et al., 2020). (A) "Drain current  $I_{D}$  vs. gate voltage  $V_{GS}$ " hysteresis at  $V_{DS} = 0.2\mathrm{~V}$ ; (B) "Polarization vs. gate voltage" data; (C) "Polarization vs. electric field" characteristics of the ferroelectric HZO layer. Only simulation results are available for this quantity.

![](images/d2d56793e0765e98ee14a42f46beb65a24ecda58e64ebae2c021c3b0d5c61cc8.jpg)

![](images/b549c6c700827544f02191894c751f42250f6323d9f5ad72436099c9f3126e8b.jpg)

TABLE 1 Principle S-Device material parameters for the considered HZO ferroelectric layer.  

<table><tr><td>Parameter name in S-device</td><td>Description</td><td>Value</td></tr><tr><td>alpha1 (cm/F)</td><td>Landau&#x27;s coefficient (x component)</td><td>1.3e12</td></tr><tr><td>alpha2 (cm/F)</td><td>Landau&#x27;s coefficient (y component)</td><td>-9.889e10</td></tr><tr><td>beta1 (cm5/FC2)</td><td>Landau&#x27;s coefficient (x component)</td><td>0</td></tr><tr><td>beta2 (cm5/FC2)</td><td>Landau&#x27;s coefficient (y component)</td><td>2.007e20</td></tr><tr><td>gamma1, gamma2 (cm9/FC4)</td><td>Landau&#x27;s coefficient (x, y component)</td><td>0</td></tr><tr><td>g1, g2, g6 (cm3/FC2)</td><td>Coupling coefficient for the polarization gradient</td><td>5e-7</td></tr><tr><td>epsilon</td><td>Relative permittivity</td><td>33</td></tr><tr><td>rho (Ohm cm)</td><td>Polarization viscosity</td><td>2.25e4</td></tr></table>

TCAD physical model of S-Device (Synopsys, 2019). Once this is done, only the geometry and shape will be modified in Section 4 to enhance the synaptic-like characteristics of the FeFETs. Note that due to the planar structure of the considered transistor, 3-D simulations were not necessary to capture the physics at play. No additional contact resistance was included in our simulations. High contact resistances are expected to impact the quasistatic and transient characteristics of FeFETs. However, for transistors with relatively long channel like the ones considered in this study, the contribution of the contact resistance to the whole device resistance is relatively moderate ( $< 20\%$ ) (Halter et al., 2022).

The ferroelectric model relies on several material parameters, in particular the Landau coefficients  $\alpha_{i}$ ,  $\beta_{i}$ , and  $\gamma_{i}$ . The default parameters that are available in the S-Device library have been utilized as initial values. They have then been slightly adjusted to best match capacitance measurements. Consequently, the sole uncertainty in the calibration of the FeFET simulation model resides in the material parameters for  $\mathrm{WO}_x$ . To obtain them, we used the experimental  $\mathrm{WO}_x$  data presented in (Migas et al., 2010; Halter et al., 2020) and the values proposed in (Fountaine, 2015) for  $\mathrm{WO}_3$ . The most relevant material parameters for HZO and

TABLE 2 Same as in Table 1, but for the  ${\mathrm{{WO}}}_{x}$  channel.  

<table><tr><td>Parameter name in S-device</td><td>Description</td><td>Value</td></tr><tr><td>Eg0 (eV)</td><td>Bandgap</td><td>0.75</td></tr><tr><td>Epsilon</td><td>Relative permittivity</td><td>300</td></tr><tr><td>Chi0 (eV)</td><td>Electron affinity</td><td>4.5</td></tr><tr><td>mumax (cm2/Vs)</td><td>Electron mobility</td><td>0.016</td></tr><tr><td>mm</td><td>Effective mass for electrons</td><td>0.8</td></tr><tr><td>Nc300 (cm-3)</td><td>Conduction band density of states</td><td>1.8e19</td></tr><tr><td>Nv300 (cm-3)</td><td>Valence band density of states</td><td>7.1e19</td></tr></table>

$\mathrm{WO}_x$  that were employed in our simulations are shown in Tables 1, 2. Note that since 2-D simulations are carried out in this study, all coefficients along the  $z$ -axis of the HZO layer are defined to be zero. The Landau coefficients  $\alpha_i, \beta_i,$  and  $\gamma_i$  in the first five rows of Table 1 determine the polarization component  $P_i$  along the axis  $i = \{x,y,z\}$ , in case of anisotropic dielectric layer. Similarly, the  $g_{ij}$  coefficients refer to the polarization gradient factor that

influences the spatial derivative of  $P_{i}$  (Eq. 1). The polarization is assumed to be anisotropic to restrict the switchable component to the y-axis, which is the direction orthogonal to the gate of the transistor, whose structure is schematized in Figure 1. This feature is realized by defining positive  $\alpha_{i}$  values along the two other directions, i.e., the x- and z-axis. Generally, the polarization gradient coefficients  $g_{ij}$  is a symmetric  $3 \times 3$  tensor, which has six independent components. It can therefore be expressed in a six-component vector notation:  $g_{1} = g_{11}, g_{2} = g_{22}, g_{3} = g_{33}, g_{4} = g_{23} = g_{32}, g_{5} = g_{13} = g_{31}$ , and  $g_{6} = g_{12} = g_{21}$  (Synopsys, 2019). Regarding the relative permittivity of  $\mathrm{WO}_{x}$ , a value higher  $(\varepsilon_{\mathrm{WO}_{x}} = 300)$  than the experimentally measured one  $(\varepsilon_{\mathrm{WO}_{x}} = 189)$  had to be used to improve the quality of the fit. This discrepancy could possibly be attributed to the gate voltage-driven migration of oxygen vacancies from the HZO to the  $\mathrm{WO}_{x}$  layer. This mechanism has been experimentally shown to alter the resistive switching characteristics of FeFETs (Halter et al., 2022). It might also be at the origin of higher doping concentrations, modified dielectric properties, and/or reduced mobility. Moreover, the electron mobility was adjusted to best reproduce the experimental hysteretic curves, with a final value  $\mu_{e} = 0.016 \, \mathrm{cm}^{2}/\mathrm{Vs}$ . Experimentally, it was determined to be about  $0.19 \, \mathrm{cm}^{2}/\mathrm{Vs}$ . This difference at least partially originates from the omission of parasitic capacitances in our simulations.

The simulated and experimental characteristics of the 2-D FeFET structure are shown in Figure 2. In sub-plot (A), the experimental  $I_{D}$  vs.  $V_{GS}$  hysteretic loop is presented. The measured curve was shifted along the positive  $V_{GS}$  direction by  $1\mathrm{V}$ , as compared to the simulation data, to compensate for the accumulation of trapped charges, an effect that is not accounted for in our model (Muller et al., 2016). Apart from this rigid shift that must be applied, a good agreement between the calibrated TCAD results and the measured data can be observed. The simulated hysteretic window is about  $2\mathrm{V}$  wide, similar to the experimental one. The flatter  $dI_{D} / dV_{GS}$  slope of the experimental measurement can be attributed to the formation of a high density of ferroelectric domains inside the HZO layer, as will be discussed in Section 3.2. In addition, the simulated and experimental "polarization vs. gate voltage ( $P$  vs.  $V_{GS}$ )" characteristics of the ferroelectric HZO layer agree very well, as shown in sub-plot (B). In sub-plot (C), the "polarization vs. electric field" behavior of the HZO layer, as computed with the TCAD model, is presented. No experimental data is available for this quantity.

# 3.2 Multi-domain characterization

Based on this initial calibration, the agreement between the simulated and measured characteristics of the selected FeFET have been further improved by accounting for the presence of multiple ferroelectric domains. As the number of domains increases in the HZO layer, the  $dI_{D} / dV_{GS}$  slope of the switching hysteresis and the value of the ferroelectric

coercive field  $(E_{C})$  change, as compared to the single-domain case that has been so far assumed. When the required electric field and time for the polarization to switch are different in each ferroelectric domain, the slope of the electrical current  $I_{D}$  with respect to the gate voltage  $V_{GS}$  becomes more gradual, for both branches of the hysteresis. This indicates that polarization switching takes place in a sequential manner across all grains (Noh et al., 2019).

To include this effect, the ferroelectric HZO layer in the modeled FeFET structure was divided into  $N_{D}$  domains with equal size  $L_{D}$  along the x-axis. These domains join the source and drain contacts possess varying Landau's coefficients  $\alpha_{2n}$  along the y-axis, since  $\alpha_{2n}$  is closely related to the remnant polarization  $P_{r}$  and the coercive field  $E_{C}$  of the concerned domain, according to Eqs 1, 2. Here, the subscript of the Landau coefficient  $n$  corresponds to the index of the ferroelectric domain along y,  $n = 1$  being the first one on the source side, and  $n = N_{D}$  the last one close to the drain contact. The  $\alpha_{2n}$  values were randomly chosen according to a Gaussian distribution function with a mean value  $\mu_{\alpha 2} = -9.889\times 10^{10}\mathrm{cm / F}$  and standard deviations  $\sigma_{\alpha 2}$  varying between 0 and  $9.889\times 10^{10}\mathrm{cm / F}$ .

The simulated  $I_{D}$  vs.  $V_{GS}$  characteristics of four different HZO domain configurations ( $N_{D}$  and  $L_{D}$ ) are plotted in Figures 3A-D, together with the experimental reference. Note that the product  $N_{D} \times L_{D}$  remains the same in all cases,  $0.8\mu \mathrm{m}$ , which is equal to the total length of the  $\mathrm{WO}_x$  channel. It can be clearly observed that the slope of the hysteresis loop decreases when increasing  $\sigma_{\alpha 2}$ . Among all tested configurations, the one with  $N_{D} = 40$ ,  $L_{D} = 20 \mathrm{~nm}$ , and  $\sigma_{\alpha 2} = -0.3\mu_{\alpha 2}$  in Figure 3C gives the best agreement with the measurement. Moreover, the simulation with  $N_{D} = 80$ ,  $L_{D} = 10 \mathrm{~nm}$ , and  $\sigma_{\alpha 2} = -0.3\mu_{\alpha 2}$  leads to a similar result, but with slightly larger discrepancy. Since the domain size is generally smaller than the grain size (Hyun et al., 2018), this finding aligns well with the experimental observation of a mean grain size in HZO of  $26.8 \mathrm{~nm}$ , as reported in (Lombardo et al., 2021).

Next, we focused on the transient response of the  $\mathrm{WO}_x$ -based FeFET to a train of positive and negative electrical pulses applied to its source and drain contacts, while the gate is grounded. Desired is a gradual, multi-state modulation of the device resistance as a function of the number of applied pulses. As a first numerical analysis, the influence of  $N_{D}$  on the number of resistance states was investigated at a constant standard deviation value of  $\sigma_{\alpha 2} = -0.3\mu_{\alpha 2}$ . Results are shown in Figure 4. The amplitude of the electrical pulses first increases from 0 to  $4\mathrm{V}$  in step of  $0.1\mathrm{V}$  before decreasing from 0 to  $-4\mathrm{V}$  with a step size of  $-0.1\mathrm{V}$ . As a consequence, the resistance first increases (depression) and then decreases (potentiation). The duration of the writing pulses is set to  $10~\mu \mathrm{s}$ , as in experiments (Halter et al., 2020). As expected, the number of available resistance states increases as more ferroelectric domains  $N_{D}$  are considered. The maximum number of resistance states (15) is reached with  $N_{D} = 40$  and 80, which corresponds to domain sizes of 20 and

![](images/75f69b02e12a502392d5c9f986c684bf3ae8445809257a609936387ba08433a6.jpg)

![](images/7f1a371a7456fb0d748f3d51d69780145900f810b4219f2af037ea6d14b29168.jpg)

![](images/ea75b300bf40ec9763294fb734da00d2952b0e3ad520038104610210dca4c826.jpg)  
FIGURE 3 Experimental (solid line with crosses) and simulated  $I_{D}$  vs.  $V_{GS}$  transfer characteristics of the FeFET in Figure 1 with an 8 nm-thick  $\mathrm{WO}_x$  channel (Halter et al., 2020), different number of HZO domains  $(N_{D})$ , and varying standard deviations of the Landau coefficients  $(\sigma_{\alpha 2})$  at a source-to-drain voltage  $V_{DS} = 0.2\mathrm{V}$  (A)  $N_{D} = 12$ ,  $L_{D} = 67\mathrm{nm}$ ; (B)  $N_{D} = 20$ ,  $L_{D} = 40\mathrm{nm}$ ; (C)  $N_{D} = 40$ ,  $L_{D} = 20\mathrm{nm}$ ; (D)  $N_{D} = 80$ ,  $L_{D} = 10\mathrm{nm}$ .

![](images/2e88ee3fa6c4dc16fee8a8e6ddcecef065723734cb7dde664756c19573644287.jpg)

![](images/2482d3c1d6789f0fa5d6a7a78ec5a4bc212d2aaec5eccec68b2d9560e77ec0a8.jpg)

![](images/6307f478e81474a6776e11b0affe9814591e5fa428da9df4850096b5580952e5.jpg)  
FIGURE 4 Simulated response of the  $\mathrm{WO}_x$  -based FeFET of Figure 1 to a train of electrical pulses (as shown in subplot (A)) applied to the drain and source electrodes, while the gate is grounded. The pulse amplitude increases from O to  $4\mathrm{V}$  and then decreases from O to  $-4\mathrm{V}$  with a step size of  $\pm 0.1\mathrm{V}$  and a period of  $10~\mu s$  . Different number of domains  $N_{D}$  (from 12 to 80) at a constant standard deviation  $\sigma_{a2} = -0.3\mu_{a2}$  are considered.

$10\mathrm{nm}$ , respectively, the length of the channel still being equal to  $0.8\mu \mathrm{m}$ .

Continuing our analysis, the potentiation and depression behavior of the  $\mathrm{WO}_x$ -based FeFET is investigated for  $L_{D} = 10$  and

$20\mathrm{nm}$  with varying  $\sigma_{\alpha 2}$ . Here, the same electrical pulse sequence as in the measurements is used (Halter et al., 2020). Their amplitude increases first from 1.3 to  $2.7\mathrm{V}$  for depression and then decreases from  $-1.5$  to  $-2.5\mathrm{V}$  for potentiation, with a step

![](images/07f796f643909bed5f2b0502203c458058684c72fe89619453c08f7175a11be8.jpg)  
FIGURE 5 Simulated and experimental depression and potentiation response of the  $\mathsf{WO}_x$  -based FeFET of Figure 1 as a function of the number of electrical pulses at different standard deviations  $\sigma_{\alpha 2}$  for (A)  $N_{D} = 40$ $L_{D} = 20~\mathrm{nm}$  ; (B)  $N_{D} = 80$ $L_{D} = 10~\mathrm{nm}$  domain configurations. The writing pulse train increases from 1.3 to  $2.7\mathrm{V}$  for depression and then decreases from  $-1.5$  to  $-2.5\mathrm{V}$  for potentiation, with a step size of  $\pm 0.1\mathrm{V}$  .The experimental  $R_{H}$  and  $R_{L}$  values are both indicated. They correspond to the resistance at the beginning of the pulse sequence  $(R_L)$  and at the end of the depression part  $(R_H)$

![](images/99f9ebf30b9c80f2cc13bc5cbb9073b4720af5fb9a75cabef3fb1d7d9b1fc7ad.jpg)

size of  $\pm 0.1\mathrm{V}$  and a pulse duration of  $10~\mu \mathrm{s}$ . The simulated results are summarized and compared to experiments in Figure 5. For  $\sigma_{\alpha 2} \leq -0.5\mu_{\alpha 2}$ , the difference in  $R_{H} / R_{L}$  obtained at the two  $N_{D}$  considered here comes from the fact that the ferroelectric domains are not fully switched due to the relatively limited voltage swing of the applied pulses (from 1.3 to  $2.7\mathrm{V}$  for depression and from  $-1.5$  to  $-2.5\mathrm{V}$  for potentiation). The best agreement is obtained when  $N_{D} = 40$ ,  $L_{D} = 20\mathrm{nm}$ , and  $\sigma_{\alpha 2} = -\mu_{\alpha 2}$ . These results can then be used to extract the  $R_{H} / R_{L}$  resistance ratio, where  $R_{H}(R_{L})$  refers to the largest (smallest) resistance occurring in the depression/potentiation curve in Figure 5. This ratio is found to be 1.6. It should be noticed that the best match between the measured and simulated depression and potentiation characteristics is obtained for a larger standard deviation  $\sigma_{\alpha 2}$  than in the optimal DC case in Figure 3C. In Figure 3C,  $\sigma_{\alpha 2} = \mu_{\alpha 2}$  produces a good agreement with the experimental "  $I_{D}$  vs.  $V_{GS}$ " curve. This discrepancy could possibly be attributed to the fact that for durations longer than  $3\mu \mathrm{s}$ , the energy of each pulse is potentially large enough to enable oxygen migration between the HZO and  $\mathrm{WO}_x$  layers, which increases the  $R_{H} / R_{L}$  resistance ratio as compared to the case where only polarization switching occurs (Halter et al., 2022). As the migration of oxygen atoms cannot be described by the current TCAD model, the discrepancy between the quasistatic and transient results corresponds to the difference between the calibrated standard deviations of Landau's coefficients. In addition, larger  $\mathrm{R}_{H} / \mathrm{R}_{L}$  are expected for pulse durations longer than  $10~\mu \mathrm{s}$ , as confirmed experimentally (Halter et al., 2022). Note that the orientation of the polarization is restricted to the y-axis in this study although the switching characteristics of the investigated devices closely relies on this parameter and its

variation across the multiple ferroelectric domains. This partly explains the differences between simulations and experiments.

# 4 Prospective performance enhancements

Starting from the calibrated simulation results of Section 3, the influence of various design parameters has been studied to enhance the FeFET performance. More specifically, our theoretical investigations aim at designing novel FeFET structures with improved  $R_{H} / R_{L}$  resistance ratios, i.e., with larger dynamic ranges, as compared to the device configuration reported in (Halter et al., 2020). The higher the  $R_{H} / R_{L}$  ratio, the more efficient is the training of a crossbar array incorporating such devices. If possible, the number of available resistance states between  $R_{L}$  and  $R_{H}$  should also be maximized. All channel resistances are extracted at  $V_{DS} = 0.2\mathrm{V}$  by applying a DC IV-sweep from -200 to  $200\mathrm{mV}$  at the drain contact, while keeping the source and the gate grounded, as in experiments (Halter et al., 2020). For simplicity, all subsequent simulations were carried out utilizing FeFETs with a single-domain HZO layer, as the number of ferroelectric domains is not expected to significantly affect the resistance ratio of the device, as can be seen in Figure 4.

Because pulse-response simulations are computationally relatively intensive, the resistance ratios of the modified device designs were estimated as a first approximation by scaling the  $R_{H} / R_{L}$  results in Figure 5 with the following factor:  $(I_{ON} / I_{OFF})_{new} / (I_{ON} / I_{OFF})_{orig}$ . This factor can be extracted from the DC "current vs. voltage" transfer characteristics at

![](images/06bdf55bf23754283b6a682f4238e24db37572ef9614091937ab9320b0503357.jpg)  
FIGURE 6 (A)  $R_{H} / R_{L}$  resistance ratio as a function of the channel thickness  $T_{CH}$ , estimated from the hysteretic FeFET characteristics at  $V_{DS} = 0.2\mathrm{V}$ . (B) Corresponding  $I_{ON}$  and  $I_{OFF}$  as a function of  $T_{CH}$ , extracted from the DC transfer characteristics at 4 V and -4 V, respectively. (C) Surface potential  $\psi_{S}$  along the  $\mathrm{WO}_x$  channel at  $V_{G} = -4\mathrm{V}$  and  $V_{DS} = 0.2\mathrm{V}$ . The beginning of the source contact is situated at  $x = 0$ , the gate starts at  $x = 0.6\mu \mathrm{m}$  and goes till  $x = 1.4\mu \mathrm{m}$ .

![](images/72d140d014855c621f7060fe26689595736848c33a17a47ed49a653ed9a343d5.jpg)

![](images/fb6feabe790fe8303f332d10c21b420f0454ae6f26b9a93298ec1640d0b871b3.jpg)

$V_{DS} = 0.2\mathrm{V}$ ,  $I_{ON}(I_{OFF})$  being the current at  $4\mathrm{V}$ $(-4\mathrm{V})$ . Hence,  $(I_{ON} / I_{OFF})_{new}$  represents the simulated ratio between the ON- and OFF-state currents of the updated design, while  $(I_{ON} / I_{OFF})_{orig}$  is the same quantity for the original FeFET, as simulated in Figures 2, 3. As the  $R_{H} / R_{L}$  ratio coming from depression/potentiation measurements is expected to depend on the DC  $I_{ON} / I_{OFF}$  ratio, we believe that our simplified approach is sufficient to indicate which parameters have a positive or negative impact on the FeFET operation.

# 4.1 Impact of design parameters

# 4.1.1 Channel thickness

As a first design parameter, the impact of the channel thickness,  $T_{CH}$ , was analyzed taking advantage of the calibrated model. The simulation results are displayed in Figure 6. It can be observed in sub-plot (A) that by decreasing  $T_{CH}$  from 8 to  $4\mathrm{nm}$ , the  $R_{H} / R_{L}$  ratio, as estimated with the method outlined above, doubles. This finding has been confirmed experimentally, where an improvement by a factor 2 is obtained by halving the channel thickness of the FeFET (Halter et al., 2022). These results are not only encouraging, they also validate our approach, where only the DC FeFET characteristics are computed to approximate the  $R_{H} / R_{L}$  ratio. For  $T_{CH}$  thicker than  $10\mathrm{nm}$ , the estimated  $R_{H} / R_{L}$  ratio drops to unity due to the relatively low energy barrier between the source and drain regions, which leads to a decreased  $I_{ON} / I_{OFF}$ .

It can be seen in subplot (B) and that the increase in  $R_{H} / R_{L}$  can be mainly attributed to a rapid decrease of  $I_{OFF}$  as  $T_{CH}$  is reduced before saturating. The ON-state current also diminishes, but at a slower rate. This behavior is a consequence of the fact that transistors with a thinner channel exhibit a better electrostatics control than thicker ones, thus allowing for a more efficient switching off of the device. Further reducing  $T_{CH}$  below  $4\mathrm{nm}$  does not bring additional enhancement anymore because  $I_{OFF}$  remains almost constant. At this size,

![](images/9ba676e8a403a8bdcfcf01dd3f93bacf8d978e650a4a20d123a3268ab4121dd4.jpg)  
FIGURE 7 (A) Simulated  $R_{H} / R_{L}$  resistance ratio as a function of the ferroelectric layer thickness  $T_{FE}$ . (B) Corresponding  $I_{ON}$  and  $I_{OFF}$  currents as a function of  $T_{FE}$ . All simulations were performed at  $V_{DS} = 0.2\mathrm{V}$ .

![](images/cb8220ef707d5e5e6647e9ec6e00e87e5c109fe5541e666eb823c4dbd3f2b6ea.jpg)

$I_{OFF}$  is limited by the electron carrier concentration of the channel, which is equal to  $1.01 \times 10^{20} \mathrm{~cm}^{-3}$  in our case (Si et al., 2019). Moreover, the surface potential at the source/ channel interface is already negative at  $T_{CH} = 4 \mathrm{~nm}$ , as can be seen in Figure 6C. It thus forms a potential barrier at the source-gate interface so that further reductions of  $T_{CH}$  have little impact on  $I_{OFF}$ . In conclusion, an enhanced  $R_{H} / R_{L}$  ratio can be achieved by carefully adjusting  $T_{CH}$ .

# 4.1.2 HZO thickness

The transfer characteristics of the FeFET device have also been evaluated for different HZO layer thicknesses,  $T_{FE}$ . As shown in Figure 7, the  $R_{H} / R_{L}$  ratio increases as  $T_{FE}$  decreases. The underlying physical mechanism is similar to the one discussed in Section 4.1.1, i.e., the gate control over the channel becomes stronger as the ferroelectric layer thickness is reduced because the gate capacitance augments. The impact of  $T_{FE}$  is stronger on  $I_{ON}$  than on  $I_{OFF}$ , which leads to the observed positive effect on  $R_{H} / R_{L}$ . According to our simulations, if  $T_{FE}$  is reduced down to  $5\mathrm{nm}$ , a further increase of  $R_{H} / R_{L}$  could theoretically be envisioned, but two major issues might

![](images/feefca16f0b8f1c48c156f5a2e43436396489afd9367a52c0fcab0297979840e.jpg)  
FIGURE 8 Simulated double-gate FeFET structure with a planar  $\mathrm{WO}_x$  channel. Its dimensions are listed in Table 3.

TABLE 3 Geometrical parameters of the double-gate FeFET transistor in Figure 8.  

<table><tr><td>Parameter</td><td>Description</td><td>Value</td></tr><tr><td>TFE(nm)</td><td>Gate dielectric thickness (HZO)</td><td>10</td></tr><tr><td>TCH(nm)</td><td>Channel thickness (WOx)</td><td>8</td></tr><tr><td>LCH(μm)</td><td>Channel length</td><td>0.8</td></tr><tr><td>LS/D(μm)</td><td>Source/drain contact length</td><td>0.6</td></tr></table>

prevent such a positive outcome. First, thin HZO layers are known not to switch as efficiently as thicker ones (Vitale et al., 2010). Secondly, an ultra-scaled dielectric layer tends to be leaky and to induce large gate leakage currents. Note also that the benefit of thinning the HZO layer is less important than a reduction of the semiconductor channel thickness. It is therefore not the preferred option.

# 4.1.3 Gate length, channel width, and source/ drain extensions

Contrary to the two previous parameters,  $T_{CH}$  and  $T_{FE}$ , which directly affect the depression and potentiation behavior of  $\mathrm{WO}_x$ -based FeFETs, the lateral dimensions of the structure, the gate length  $L_{G}$ , and the source/drain extensions  $L_{S / D}$ , have little influence on the  $R_{H} / R_{L}$  ratio. The ON- and OFF-state currents scale proportionally to  $1 / L_{CH}$ , so that their impact on the  $R_{H} / R_{L}$  ratio cancels each other (KO, 1989). On the other hand, it has been observed that the length of the source/drain contact extensions,  $L_{S / D}$ , has a negligible influence on the simulated  $R_{H} / R_{L}$  ratios of the FeFETs.

![](images/37dd4cccec1cc0b37e47a1a813bcc84e78abf5ac16ee3eeb6896ef90d3c34377.jpg)

![](images/f9a55adf74a0f7062a5cb68bc76a56308bdd359e7422c60cb6ce72de3eed4f5e.jpg)  
B  
FIGURE 9 (A) Simulated transfer characteristics  $I_{D} - V_{GS}$  of the double-gate FeFET of Figure 8 and of the original back-gated FeFET of Figure 1. (B) Extracted surface potential  $\psi_{S}$  along the channel at  $V_{GS} = -4\mathrm{V}$  and  $V_{DS} = 0.2\mathrm{V}$ .

# 4.2 Double-gate architecture

Based on our simulation results as well as on experimental evidence, regardless of the device dimensions and channel doping concentrations (not shown here), it clearly appears that the originally proposed back-gated (BG) FeFET structure with a  $\mathrm{WO}_x$  channel cannot deliver  $R_{H} / R_{L}$  resistance ratios larger than  $\sim 4$ . As a consequence, to improve the performance, a different transistor design is required. Here, we propose a symmetric, double-gate (DG),  $\mathrm{WO}_x$ -based FeFET with a planar structure, as schematized in Figure 8. Its geometrical parameters are summarized in Table 3. Its dimensions are similar to those of the original BG FeFET, but with two instead of one gate contact and a length of the HZO ferroelectric layer that does not exceed that of the gates. In other words, the source and drain extensions are not covered by HZO.

The transfer characteristics of the proposed FeFET design are reported in Figure 9 and compared to those of the original backgated FeFET of Figure 1. With the same dimensions in both transistor configurations, the introduction of a second gate significantly improves the electrostatic control, which helps suppress the OFF-state current, while slightly improving the ON-state current by a factor of 1.6, as compared to the original structure. Hence, the DG device with an  $8\mathrm{nm}$ $\mathrm{WO}_x$  channel and a  $10\mathrm{nm}$  HZO layer could theoretically deliver a 13 times higher  $R_{H} / R_{L}$  resistance ratio than the original one with a single back gate, i.e., 20.8 instead of 1.6. This improvement is expected to be accompanied by a significant increase of the number of intermediate resistance states between  $R_{L}$  and  $R_{H}$ . Obviously, reducing the  $\mathrm{WO}_x$  channel thickness could further enhance the  $R_{H} / R_{L}$  ratio, but not as much as in the back-gated FeFET because the electrostatic control is already close to optimal with a double-gate architecture and  $T_{CH} = 8\mathrm{nm}$ .

# 5 Conclusion

The transfer characteristics of HZO-based FeFETs were simulated utilizing a 2-D, time-dependent Ginzburg-Landau ferroelectric model, as implemented in the S-Device TCAD tool. Starting from an existing back-gated FeFET with a  $\mathrm{WO}_x$  channel, good qualitative and quantitative agreements between the simulated and experimental DC performance were obtained after careful calibration. The influence of different design parameters (channel and ferroelectric layer thickness, gate length) and device geometries (double-gate architecture) on the  $R_{H} / R_{L}$  resistance ratio of these transistors were investigated. This ratio is a relevant figure-of-merit for neuromorphic computing applications because it is closely related to the dynamic range of the depression and potentiation characteristics and to the number of available resistance states that can be accessed by sending electrical pulses to the FeFETs. The  $R_{H} / R_{L}$  ratio should be as large as possible to enhance the learning capabilities of artificial neural networks based on memristive FeFET crossbar arrays. In terms of parameter screening, a channel thickness of  $4\mathrm{nm}$  seems to be optimal, regardless of the device geometry. It should be combined with a ferroelectric layer as thin as possible, while maintaining good polarization switching properties and low leakage currents.

However, to avoid large surface-to-volume ratios and minimize the impact of surface roughness, as typically encountered in ultra-thin channels, a double-gate FeFET appears as a more promising approach. It provides the best electrostatic control over the  $\mathrm{WO}_x$  channel, and is predicted to provide a 13 times larger  $R_{H} / R_{L}$  ratio than that of the original back-gated transistor with similar geometrical parameters. From a fabrication point of view, a double-gate structure might be more challenging than a reduction of the channel or ferroelectric layer thickness, but the benefit is far greater. Hence, the HZO-based FeFET technology might be a viable alternative to phase change materials, valence change memories, or electro-chemical cells as solid-state synapses in future neuromorphic computing circuits.

# References

Ali, T., Polakowski, P., Riedel, S., Böttner, T., Kämpfe, T., Rudolph, M., et al. (2018). Silicon doped hafnium oxide (hso) and hafnium zirconium oxide (hzo) based fefet: A material relation to device physics. Appl. Phys. Lett. 112, 222903. doi:10.1063/1.5029324  
Apalkov, D., Khvalkovskiy, A., Watts, S., Nikitin, V., Tang, X., Lottis, D., et al. (2013). Spin-transfer torque magnetic random access memory (stt-mram). ACM J. Emerg. Technol. Comput. Syst. (JETC) 9, 1-35.  
Chandra, P., and Littlewood, P. (2007). "A landau primer for ferroelectrics," in Physics of ferroelectrics (Berlin, Heidelberg: Springer), 69-116. doi:10.1007/978-3-540-34591-6_3  
Chen, C., Yang, M., Liu, S., Liu, T., Zhu, K., Zhao, Y., et al. (2019). "Bio-inspired neurons based on novel leaky-fetf with ultra-low hardware cost and

# Data availability statement

The raw data supporting the conclusion of this article will be made available by the authors, without undue reservation.

# Author contributions

XW and ML led the project. XW carried out the simulations. MH and LB-L designed and performed the experiments. XW and ML wrote and edited the paper. All authors contributed to the article and approved the submitted version.

# Funding

This work was supported by the EU H2020 ICT BeFerroSynaptic project No. 871737. Open access funding provided by ETH Zurich.

# Acknowledgments

We acknowledge Pawel Lenarczyk for the implementation of the simulation model and the helpful theoretical and technical support.

# Conflict of interest

MH and LB-L are employed by IBM Research GmbH—Zurich Research Laboratory.

The remaining authors declare that the research was conducted in the absence of any commercial or financial relationships that could be construed as a potential conflict of interest.

# Publisher's note

All claims expressed in this article are solely those of the authors and do not necessarily represent those of their affiliated organizations, or those of the publisher, the editors and the reviewers. Any product that may be evaluated in this article, or claim that may be made by its manufacturer, is not guaranteed or endorsed by the publisher.

advanced functionality for all-ferroelectric neural network," in 2019 symposium on VLSI technology (IEEE), T136-T137. doi:10.23919/VLSIT.2019.8776495  
Cockburn, B., Kanschat, G., Schötzau, D., and Schwab, C. (2002). Local discontinuous galerkin methods for the Stokes system. SIAM J. Numer. Analysis 40, 319-343. doi:10.1137/S0036142900380121  
Fountaine, K. T. (2015). Mesoscale optoelectronic design of wire-based photovoltaic and photoelectrochemical devices. Pasadena, California: California Institute of Technology. PhD Thesis.  
Gokmen, T., and Vlasov, Y. (2016). Acceleration of deep neural network training with resistive cross-point devices: Design considerations. Front. Neurosci. 10, 1. doi:10.3389/fnins.2016.00333

Halter, M., Bégon-Lours, L., Bragaglia, V., Sousa, M., Offrein, B., Abel, S., et al. (2020). A back-end, cmos compatible ferroelectric field effect transistor for synaptic weights. ACS Appl. Mat. Interfaces 12, 17725-17732. doi:10.1021/acsami.0c00877  
Halter, M., Bégon-Lours, L., Sousa, M., Popoff, Y., Drechsler, U., Bragaglia, V., et al. (2022). A multi-timescale synaptic weight based on ferroelectric hafnium zirconium oxide. Springer. (to be submitted).  
Hyun, S. D., Park, H. W., Kim, Y. J., Park, M. H., Lee, Y. H., Kim, H. J., et al. (2018). Dispersion in ferroelectric switching performance of polycrystalline hf0.5zr0.5o2 thin films. ACS Appl. Mater. Interfaces 10, 35374-35384.  
Jerry, M., Chen, P.-Y., Zhang, J., Sharma, P., Ni, K., Yu, S., et al. (2017). "Ferroelectric fet analog synapse for acceleration of deep neural network training," in 2017 IEEE international electron devices meeting (IEDM) (IEEE), 6.2.1-6.2.4. doi:10.1109/IEDM.2017.8268338  
Ko, P. K. (1989). "Chapter 1 - approaches to scaling," in Advanced MOS device physics, vol. 18 of VLSI electronics microstructure science. Editors N. G. Einspruch and G. S. Gildenblat (Elsevier), 1-37. doi:10.1016/B978-0-12-234118-2.50005-X  
Lombardo, S. F., Tian, M., Chae, K., Hur, J., Tasneem, N., Yu, S., et al. (2021). Local epitaxial-like templating effects and grain size distribution in atomic layer deposited hfo.5zr0.5o2 thin film ferroelectric capacitors. Appl. Phys. Lett. 119, 092901. doi:10.1063/5.0057782  
Migas, D. B., Shaposhnikov, V. L., and Borisenko, V. E. (2010). Tungsten oxides. ii. the metallic nature of magneli phases. J. Appl. Phys. 108, 093714. doi:10.1063/1.3505689  
Mulaosmanovic, H., Chicca, E., Bertele, M., Mikolajick, T., and Slesazeck, S. (2018). Mimicking biological neurons with a nanoscale ferroelectric transistor. Nanoscale 10, 21755-21763.  
Mulaosmanovic, H., Ocker, J., Müller, S., Noack, M., Müller, J., Polakowski, P., et al. (2017). "Novel ferroelectric fet based synapse for neuromorphic systems," in 2017 symposium on VLSI technology (IEEE), T176-T177. doi:10.23919/VLSIT.2017.7998165  
Mulaosmanovic, H., Slesazeck, S., Ocker, J., Pesic, M., Muller, S., Flachowsky, S., et al. (2015). "Evidence of single domain switching in hafnium oxide based fefets: Enabler for multi-level fefet memory cells," in 2015 IEEE international electron devices meeting (IEDM) (IEEE), 26.8.1-26.8.3. doi:10.1109/IEDM.2015.7409777

Muller, J., Polakowski, P., Muller, S., Mulaosmanovic, H., Ocker, J., Mikolajick, T., et al. (2016). "High endurance strategies for hafnium oxide based ferroelectric field effect transistor," in 2016 16th non-volatile memory technology symposium (NVMTS) (IEEE), 1-7. doi:10.1109/NVMTS.2016.7781517  
Noh, Y., Jung, M., Yoon, J., Hong, S., Park, S., Kang, B. S., et al. (2019). Switching dynamics and modeling of multi-domain zr-doped hfo2 ferroelectric thin films. Curr. Appl. Phys. 19, 486-490. doi:10.1016/j.cap.2019.01.022  
Selberherr, S. (1984). Analysis and simulation of semiconductor devices. Springer Science & Business Media.  
Sholl, D., and Steckel, J. A. (2011). Density functional theory: A practical introduction. John Wiley & Sons.  
Si, M., Lyu, X., Shrestha, P. R., Sun, X., Wang, H., Cheung, K. P., et al. (2019). Ultrafast measurements of polarization switching dynamics on ferroelectric and anti-ferroelectric hafnium zirconium oxide. Appl. Phys. Lett. 115, 072107. doi:10.1063/1.5098786  
Starkov, A., Pakhomov, O., and Starkov, I. (2013). Theoretical model for thin ferroelectric films and the multilayer structures based on them. J. Exp. Theor. Phys. 116, 987-994. doi:10.1134/S1063776113060149  
Sun, X., Wang, P., Ni, K., Datta, S., and Yu, S. (2018). "Exploiting hybrid precision for training and inference: A 2t-1fefet based analog synaptic weight cell," in 2018 IEEE international electron devices meeting (IEDM) (IEEE), 3.1.1-3.1.4. doi:10.1109/IEDM.2018.8614611  
Synopsys (2019). Sentaurus device user guide V-2019.12. USA, CA: IEEE.  
Vitale, W., Mohamed, M., and Ravaioli, U. (2010). "Monte Carlo study of transport properties in junctionless transistors," in 2010 14th international workshop on computational electronics (IEEE), 1-3. doi:10.1109/1WCE.2010.5677969  
Zhao, W., Devolder, T., Lakys, Y., Klein, J., Chappert, C., and Mazoyer, P. (2011). Design considerations and strategies for high-reliable stt-mram. Microelectron. Reliab. 51, 1454-1458. doi:10.1016/j.microrel.2011.07.001  
Zienkiewicz, O. C., Taylor, R. L., and Zhu, J. Z. (2005). "Generalization of the finite element concepts. galerkin-weighted residual and variational approaches," in The finite element method set (IEEE).
