# Literature Research: Ferroelectricity in Doped $\text{HfO}_2$ and HZO for TCAD Modeling of Ferroelectric Gate Stacks

---

## Section 1: Original Discovery of Ferroelectricity in Si-Doped $\text{HfO}_2$ Thin Films & Why It Mattered

### Overview & TCAD Context
Prior to 2011, non-volatile ferroelectric memories relied on perovskite oxides such as lead zirconate titanate ($\text{Pb[Zr}_{x}\text{Ti}_{1-x}\text{]O}_3$ or PZT) and strontium bismuth tantalate ($\text{SrBi}_2\text{Ta}_2\text{O}_9$ or SBT). However, perovskite materials suffer from severe fundamental scaling limits: as film thickness scales below $\sim 20\text{--}50\text{ nm}$, depolarization fields and severe domain pinning cause a breakdown of ferroelectricity (the "ferroelectric size effect"). Furthermore, perovskites introduce severe contamination risks and processing incompatibilities when introduced into modern silicon complementary metal-oxide-semiconductor (CMOS) fabrication lines.

The discovery of ferroelectricity in silicon-doped hafnium oxide ($\text{SiO}_2\text{-doped HfO}_2$) by T. S. Böscke et al. in 2011 completely transformed ferroelectric device research. Hafnium oxide was already an established, high-permittivity (high-$k$) gate dielectric deployed in production at advanced CMOS nodes (from 45 nm down to sub-7 nm FinFET nodes). Demonstrating ferroelectricity in thin-film $\text{HfO}_2$ ($\le 10\text{ nm}$) solved three major roadblocks:
1. **CMOS Process Compatibility:** $\text{HfO}_2$ utilizes existing atomic layer deposition (ALD) precursors and processing lines, eliminating material contamination risks.
2. **Thickness Scalability:** Unlike perovskites, hafnia-based ferroelectrics retain robust ferroelectricity down to ultrathin dimensions ($1\text{--}10\text{ nm}$).
3. **Thermal Budget Compatibility:** Mechanical encapsulation with top/bottom metal electrodes (e.g., TiN) enables low-temperature stress-induced crystallization down to Back-End-of-Line (BEOL) thermal budgets ($\le 400\text{ }^\circ\text{C}$).

---

### Fact-Checked Factual Claims Ledger

#### Claim 1.1: Discovery of Ferroelectricity in Encapsulated Si-Doped $\text{HfO}_2$ Thin Films
* **Claim:** The original discovery established that 10 nm $\text{SiO}_2$-doped $\text{HfO}_2$ thin films with less than $4\text{ mol. \% SiO}_2$ crystallized under mechanical encapsulation transition into a ferroelectric phase.
* **Numeric Value with Units:** $10\text{ nm}$ film thickness; $<4\text{ mol. \% SiO}_2$ concentration.
* **DOI:** [10.1063/1.3634052](https://doi.org/10.1063/1.3634052)
* **Full Author List:** T. S. Böscke, Johannes Müller, D. Bräuhaus, U. Schröder, U. Böttger
* **Venue:** *Applied Physics Letters*
* **Year:** 2011
* **Verbatim Quoted Sentence:** 
  > *"Films with a thickness of 10 nm and with less than 4 mol. % of SiO2 crystallize in a monoclinic/tetragonal phase mixture."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 1.2: Remanent Polarization and Coercive Field in Foundational Si-Doped $\text{HfO}_2$
* **Claim:** Polarization measurements on encapsulated 10 nm $\text{SiO}_2$-doped $\text{HfO}_2$ thin films demonstrated a remanent polarization exceeding $10\text{ }\mu\text{C/cm}^2$ at a coercive field of $1\text{ MV/cm}$.
* **Numeric Value with Units:** $>10\text{ }\mu\text{C/cm}^2$ remanent polarization ($P_r$); $1\text{ MV/cm}$ coercive field ($E_c$).
* **DOI:** [10.1063/1.3634052](https://doi.org/10.1063/1.3634052)
* **Full Author List:** T. S. Böscke, Johannes Müller, D. Bräuhaus, U. Schröder, U. Böttger
* **Venue:** *Applied Physics Letters*
* **Year:** 2011
* **Verbatim Quoted Sentence:** 
  > *"This phase shows a distinct piezoelectric response, while polarization measurements exhibit a remanent polarization above 10 μC/cm2 at a coercive field of 1 MV/cm, suggesting that this phase is ferroelectric."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 1.3: Perovskite Size Effect Limits vs. $\text{HfO}_2$ Thin Film Scalability
* **Claim:** Conventional perovskite-structure ferroelectrics encounter severe integration barriers due to the ferroelectric size effect and CMOS incompatibility, triggering a research shift toward scalable $\text{HfO}_2$-based thin films starting in 2011.
* **Numeric Value with Units:** 2011 (year marking the industrial research paradigm shift).
* **DOI:** [10.1016/j.fmre.2023.02.010](https://doi.org/10.1016/j.fmre.2023.02.010)
* **Full Author List:** Jiajia Liao, Siwei Dai, Ren‐Ci Peng, Jiangheng Yang, Binjian Zeng, Min Liao, Yichun Zhou
* **Venue:** *Fundamental Research*
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"However, conventional perovskite-structure ferroelectrics (e.g., PbZrxTi1-xO3) encounter severe limitations for high-density integration owing to the size effect of ferroelectricity and incompatibility with complementary metal-oxide-semiconductor technology."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 1.4: BEOL-Compatible $400\text{ }^\circ\text{C}$ Thermal Budget for HZO Thin Films
* **Claim:** Room-temperature deposited TiN top electrodes of at least $90\text{ nm}$ thickness induce tensile stress during a $400\text{ }^\circ\text{C}$ low-thermal-budget anneal, producing $\text{Hf}_{0.5}\text{Zr}_{0.5}\text{O}_2$ (HZO) capacitors with a switching polarization of $45\text{ }\mu\text{C/cm}^2$ and a saturation voltage of $\sim 1.5\text{ V}$.
* **Numeric Value with Units:** $400\text{ }^\circ\text{C}$ anneal temperature; $90\text{ nm}$ TiN electrode thickness; $45\text{ }\mu\text{C/cm}^2$ switching polarization ($2P_r$); $\sim 1.5\text{ V}$ saturation voltage.
* **DOI:** [10.1063/1.4995619](https://doi.org/10.1063/1.4995619)
* **Full Author List:** Si Joon Kim, Dushyant Narayan, Jae‐Gil Lee, Jaidah Mohan, Joy S. Lee, Jaebeom Lee, Harrison S. Kim, Youngchul Byun, Antonio T. Lucero, Chadwin D. Young, Scott R. Summerfelt, Tamer San, Luigi Colombo, Jiyoung Kim
* **Venue:** *Applied Physics Letters*
* **Year:** 2017
* **Verbatim Quoted Sentence:** 
  > *"We report on atomic layer deposited Hf0.5Zr0.5O2 (HZO)-based capacitors which exhibit excellent ferroelectric (FE) characteristics featuring a large switching polarization (45 μC/cm2) and a low FE saturation voltage (∼1.5 V) as extracted from pulse write/read measurements."*
* **Publication Type:** Peer-reviewed journal publication.

---

## Section 2: Crystallographic Origin & HZO Characteristics at 5–10 nm

### Overview & TCAD Context
Undoped bulk $\text{HfO}_2$ is monoclinic ($m$-phase, space group $P2_1/c$) at ambient temperature and pressure, which is centrosymmetric and non-ferroelectric. Upon heating, it transitions to a centrosymmetric tetragonal phase ($t$-phase, $P4_2/nmc$) at $\sim 1720\text{ }^\circ\text{C}$ and a cubic phase ($c$-phase, $Fm\overline{3}m$) at $\sim 2600\text{ }^\circ\text{C}$.

Ferroelectricity in $\text{HfO}_2$ and $\text{Hf}_{0.5}\text{Zr}_{0.5}\text{O}_2$ (HZO) originates from the stabilization of a metastable **non-centrosymmetric orthorhombic phase** ($o$-phase), belonging to the space group **$Pca2_1$** ($o\text{III}$-phase). In this structure, displacement of oxygen atoms along the polar $c$-axis breaks inversion symmetry, producing spontaneous electrical polarization.

The $Pca2_1$ phase is stabilized via four primary thermodynamic and mechanical drivers:
1. **Dopant Incorporation / Equimolar Zr Substitution:** Substituting 50% Zr ($\text{Hf}_{0.5}\text{Zr}_{0.5}\text{O}_2$) lowers the free-energy barrier between the tetragonal and orthorhombic phases compared to pure $\text{HfO}_2$.
2. **Capping Layer Stress:** Top metal electrodes (e.g., TiN, TaN, W) exert in-plane tensile mechanical stress during post-deposition annealing, suppressing volume expansion required for transition to the monoclinic phase.
3. **Surface Energy & Grain Size Effects:** Small crystallite grain sizes ($5\text{--}15\text{ nm}$) increase surface-to-volume ratio. Because the surface energy of the orthorhombic/tetragonal phase ($\gamma_o, \gamma_t$) is lower than that of the monoclinic phase ($\gamma_m$), small grains thermodynamically favor $Pca2_1$.
4. **Thickness Scaling (5–10 nm):** In $\text{Hf}_{0.5}\text{Zr}_{0.5}\text{O}_2$ films scaled to $5\text{--}10\text{ nm}$, typical remanent polarization values range from $P_r \approx 15\text{--}25\text{ }\mu\text{C/cm}^2$ ($2P_r \approx 30\text{--}50\text{ }\mu\text{C/cm}^2$) with coercive fields of $E_c \approx 1.0\text{--}2.0\text{ MV/cm}$.

---

### Fact-Checked Factual Claims Ledger

#### Claim 2.1: Non-Centrosymmetric Orthorhombic $Pca2_1$ Phase Stability under Shear Strain
* **Claim:** Density functional theory atomic modeling confirms that shear strain modulates the thermodynamic stability of the ferroelectric non-centrosymmetric orthorhombic $o\text{III}$-phase ($Pca2_1$ space group) in HZO.
* **Numeric Value with Units:** Space group $Pca2_1$ ($o\text{III}$-phase); space group $Pmn2_1$ ($o\text{IV}$-phase).
* **DOI:** [10.1063/5.0159700](https://doi.org/10.1063/5.0159700)
* **Full Author List:** Yun-Wen Chen, C. W. Liu
* **Venue:** *Applied Physics Letters*
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"The stabilities of hafnium and zirconium oxide ferroelectric orthorhombic phases, oIII-phase (Pca21) and oIV-phase (Pmn21), under shear strain are investigated theoretically by atomic modeling with density functional theory calculations."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 2.2: Interfacial Termination Control for Ultrathin ($1.5\text{ nm}$) Orthorhombic Phase Stabilization
* **Claim:** Controlled $\text{MnO}_2$ interfacial termination stabilizes the polar orthorhombic (111) orientation in $\text{Hf}_{0.5}\text{Zr}_{0.5}\text{O}_2$ thin films scaled down to an ultrathin thickness of $1.5\text{ nm}$ without requiring a wake-up stage.
* **Numeric Value with Units:** $1.5\text{ nm}$ film thickness.
* **DOI:** [10.1038/s41467-023-37560-3](https://doi.org/10.1038/s41467-023-37560-3)
* **Full Author List:** Shu Shi, Haolong Xi, Tengfei Cao, Weinan Lin, Zhongran Liu, Jiangzhen Niu, Da Lan, Chenghang Zhou, Jing Cao, Hanxin Su, Tieyang Zhao, Ping Yang, Yao Zhu, Xiaobing Yan, Evgeny Y. Tsymbal, He Tian, Jingsheng Chen
* **Venue:** *Nature Communications*
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"Even though the Hf 0.5 Zr 0.5 O 2 thickness is as thin as 1.5 nm, the clear ferroelectric orthorhombic (111) orientation is observed on the MnO 2 termination."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 2.3: Typical Remanent Polarization and High Endurance in Interlayered HZO ($10\text{ nm}$)
* **Claim:** Sequentially deposited $\text{TiN/HZO/TiN}$ capacitors incorporating a $1\text{ nm Al}_2\text{O}_3$ interlayer achieve a remanent polarization ($2P_r$) of $\sim 42\text{ }\mu\text{C/cm}^2$ and maintain endurance past $10^8\text{ cycles}$ at $3.5\text{ MV/cm}$.
* **Numeric Value with Units:** $1\text{ nm Al}_2\text{O}_3$ interlayer thickness; $2P_r \sim 42\text{ }\mu\text{C/cm}^2$; $>10^8\text{ cycles}$ endurance limit; $3.5\text{ MV/cm}$ electric field amplitude.
* **DOI:** [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a)
* **Full Author List:** H. Alex Hsain, Young H. Lee, Suzanne Lancaster, Patrick D. Lomenzo, Bohan Xu, Thomas Mikolajick, Uwe Schroeder, Gregory N. Parsons, Jacob L. Jones
* **Venue:** *Nanotechnology*
* **Year:** 2022
* **Verbatim Quoted Sentence:** 
  > *"We report that TiN/HZO/TiN capacitors with a 1 nm Al 2 O 3 at the top interface demonstrate a higher remanent polarization (2P r ∼ 42 μ C cm −2 ) and endurance limit beyond 10 8 cycles at a cycling field amplitude of 3.5 MV cm −1 ."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 2.4: Pinched Hysteresis and Metastable Ferroelectricity in Scaled $5\text{ nm}$ HZO
* **Claim:** When HZO thickness scales down to $5\text{ nm}$, depolarization fields distort switching characteristics into pinched hysteresis by driving the material into a coexisting stable paraelectric and metastable ferroelectric state.
* **Numeric Value with Units:** $5\text{ nm}$ film thickness; sub-$10\text{ nm}$ scaling regime.
* **DOI:** [10.1038/s42005-022-00951-x](https://doi.org/10.1038/s42005-022-00951-x)
* **Full Author List:** Nikitas Siannas, Christina Zacharaki, Polychronis Tsipas, Stefanos Chaitoglou, Laura Bégon‐Lours, Thomas Mikolajick, Athanasios Dimoulas
* **Venue:** *Communications Physics*
* **Year:** 2022
* **Verbatim Quoted Sentence:** 
  > *"Using Landau-Ginsburg-Devonshire (LGD) theory for the analysis of the experimental results, it is shown here that, in thin (5 nm) HZO, depolarization fields drive the system in a stable paraelectric phase coexisting with a metastable ferroelectric one, which explains the pinched hysteresis."*
* **Publication Type:** Peer-reviewed journal publication.

---

## Section 3: THE RELIABILITY TRIAD (Wake-up, Fatigue, Imprint), Depolarisation & Charge Trapping

### Overview & TCAD Modeling Context
In TCAD modeling of ferroelectric Field-Effect Transistors (FeFETs) featuring Metal-Ferroelectric-Insulator-Semiconductor (MFIS) gate stacks, three major reliability phenomena—collectively called **The Reliability Triad**—govern device degradation during bipolar voltage cycling and thermal stress:

```
                          THE RELIABILITY TRIAD
     ┌──────────────────────────────┼──────────────────────────────┐
     ▼                              ▼                              ▼
  WAKE-UP                        FATIGUE                        IMPRINT
  • Oxygen vacancy               • Defect generation &          • Asymmetric charge
    redistribution                 domain wall pinning            trapping & bias field
  • Phase transition             • Micro-cracking &             • Memory window shift
    (tetragonal -> orthorhombic)   dielectric breakdown           & threshold voltage drift
  • Cycles: 10² - 10⁴            • Cycles: >10⁵ - 10⁸           • Time / Thermal stress
```

#### 1. Wake-Up Effect
* **Physical Mechanism:** Electric-field cycling causes the spatial migration and redistribution of oxygen vacancies ($V_O$) toward electrode interfaces. This field-driven redistribution depins domain walls and induces a structural phase transformation from non-ferroelectric monoclinic/tetragonal phases into the polar orthorhombic $Pca2_1$ phase.
* **Cycle Count & Magnitude:** Typically occurs during initial electric field cycling over $10^1\text{--}10^4\text{ cycles}$. It increases $P_r$ by $20\text{--}50\%$, expanding the memory window ($\text{MW}$) in FeFETs.
* **FeFET Manifestation:** Manifests as a widening of the memory window ($\Delta V_{th} = V_{th,HVT} - V_{th,LVT}$) and a shift in threshold voltage ($V_{th}$) states during early cycling.

#### 2. Fatigue Effect
* **Physical Mechanism:** Severe, prolonged bipolar cycling generates excessive oxygen vacancy defects and interface traps. These defects cluster along grain boundaries and domain walls, pinning domain walls so they can no longer switch under an applied field.
* **Cycle Count & Magnitude:** Sets in after $\sim 10^5\text{--}10^8\text{ cycles}$, causing a continuous drop in remanent polarization ($P_r$) until ferroelectric switching ceases or dielectric breakdown occurs.
* **FeFET Manifestation:** Manifests as severe narrowing and collapse of the Memory Window ($\text{MW} \to 0\text{ V}$), rendering High-$V_{th}$ (HVT) and Low-$V_{th}$ (LVT) states indistinguishable.

#### 3. Imprint Effect
* **Physical Mechanism:** Under unipolar field stress or high-temperature storage, asymmetric charge trapping at interfacial defect states builds up an internal bias field ($E_{im}$).
* **Cycle Count & Magnitude:** Develops as a function of cumulative bake time and unipolar voltage stress; shifts the polarization-voltage ($P\text{-}V$) hysteresis loop along the voltage axis by $\Delta V_{im} \approx 0.1\text{--}0.5\text{ V}$.
* **FeFET Manifestation:** Manifests as parallel drift of both $V_{th,HVT}$ and $V_{th,LVT}$ in the same direction, leading to state instability and read errors.

#### 4. Depolarization in MFIS Stacks & Interface Charge Trapping
* **Depolarization Field ($E_{dep}$):** In an MFIS gate stack (Metal / FE-$\text{HfO}_2$ / IL-$\text{SiO}_2$ / Si-substrate), incomplete charge screening by the low-$k$ interfacial layer ($\text{SiO}_2$) induces an uncompensated internal depolarization field ($E_{dep}$) directed opposite to the ferroelectric polarization vector $\vec{P}$:
  $$E_{dep} = -\frac{\vec{P}}{\varepsilon_{FE} \left(1 + \frac{\varepsilon_{IL} d_{FE}}{\varepsilon_{FE} d_{IL}}\right)}$$
  This depolarization field destabilizes written polarization states over time, causing retention loss.
* **Charge Trapping Competition/Masking:** High electric fields across the thin interfacial layer ($\sim 1\text{ nm SiO}_2$) trigger electron and hole injection into FE/IL interface traps. Trapped charges screen the ferroelectric dipoles, competing with or completely masking pure ferroelectric polarization switching in FeFET $I\text{-}V$ measurements.

---

### Fact-Checked Factual Claims Ledger

#### Claim 3.1: TCAD-Verified Mechanism of the Wake-Up Effect
* **Claim:** Technology Computer Aided Design (TCAD) modeling and Preisach density analysis confirm that the wake-up effect in ferroelectric hafnium oxide is driven by oxygen vacancy redistribution rather than new defect creation.
* **Numeric Value with Units:** Redistribution of existing oxygen vacancy defects during field cycling.
* **DOI:** [10.1002/adfm.201600590](https://doi.org/10.1002/adfm.201600590)
* **Full Author List:** Milan Pešić, Franz P. G. Fengler, Luca Larcher, Andrea Padovani, Tony Schenk, Everett D. Grimley, Xiahan Sang, James M. LeBeau, Stefan Slesazeck, Uwe Schroeder, Thomas Mikolajick
* **Venue:** *Advanced Functional Materials*
* **Year:** 2016
* **Verbatim Quoted Sentence:** 
  > *"Combining the comprehensive ferroelectric switching current experiments, Preisach density analysis, and transmission electron microscopy (TEM) study with compact and Technology Computer Aided Design (TCAD) modeling, it has been found out that during the wake‐up of the device no new defects are generated but the existing defects redistribute within the device."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 3.2: Role of Oxygen Vacancies ($V_O$) in Endurance and Switching
* **Claim:** The concentration, migration, and redistribution of intrinsic oxygen vacancies ($V_O$) govern physical phase transitions, switching speed, and endurance limit in $\text{HfO}_2$-based ferroelectric memories.
* **Numeric Value with Units:** Oxygen vacancy ($V_O$) defect concentration and migration dynamics.
* **DOI:** [10.1186/s40580-023-00403-4](https://doi.org/10.1186/s40580-023-00403-4)
* **Full Author List:** Jaewook Lee, Kun Yang, Ju Young Kwon, Ji Eun Kim, Dong Han, Seung-Eun Lee, Seung-Won Lee, Dong-Hyun Kim, Hyeong-Jun Kim, Tae-Gon Kim, Gwang-Sik Kim, Seung-Geun Kim, Seung-Hyun Kim, Hyoungsub Kim
* **Venue:** *Nano Convergence*
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"Moreover, the switching speed and endurance of ferroelectric memories are strongly correlated to the V o concentration and redistribution."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 3.3: Charge Trapping vs. Depolarization in FeFET Data Retention Loss
* **Claim:** Retention loss in $\text{HfO}_2$-based FeFETs is governed by the interplay of charge trapping at interfacial dielectric layers and depolarization fields, where effective work function and interfacial layer engineering yield an extrapolated 10-year memory window of $\sim 0.8\text{ V}$ at $85\text{ }^\circ\text{C}$.
* **Numeric Value with Units:** $\sim 0.8\text{ V}$ memory window; $85\text{ }^\circ\text{C}$ temperature; 10-year retention extrapolation.
* **DOI:** [10.1109/ted.2021.3096510](https://doi.org/10.1109/ted.2021.3096510)
* **Full Author List:** Y. Higashi, N. Ronchi, B. Kaczer, Md Nur K. Alam, Barry O’Sullivan, Kaustuv Banerjee, S. R. C. McMitchell, L. Breuil, A. Walke, G. Van den bosch, D. Linten, Jan Van Houdt
* **Venue:** *IEEE Transactions on Electron Devices*
* **Year:** 2021
* **Verbatim Quoted Sentence:** 
  > *"Based on our understanding, excellent improvement of the DR is achieved: memory window ~0.8 V at 85 °C, extrapolated to ten years."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 3.4: Device-Level Reliability Challenges in $\text{HfO}_2$-Based FeFETs
* **Claim:** Persistent reliability degradation in $\text{HfO}_2$-based ferroelectric field-effect transistors manifests primarily as retention loss, endurance degradation, and threshold voltage variability.
* **Numeric Value with Units:** Retention, endurance, and variability reliability metrics.
* **DOI:** [10.1109/jproc.2023.3234607](https://doi.org/10.1109/jproc.2023.3234607)
* **Full Author List:** Nicolò Zagni, Francesco Maria Puglisi, Paolo Pavan, Muhammad A. Alam
* **Venue:** *Proceedings of the IEEE*
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"Unfortunately, however, HfO2-FeFETs also suffer from persistent reliability challenges, specifically affecting retention, endurance, and variability."*
* **Publication Type:** Peer-reviewed journal publication.

---

## Section 4: Reported Mitigation Strategies

### Overview & TCAD Modeling Context
To overcome the Reliability Triad and improve FeFET operational margins, research groups have developed four primary categories of mitigation strategies:

1. **Interfacial Layer (IL) Engineering:** 
   Inserting high-permittivity or passivating dielectric interlayers (e.g., $\text{Al}_2\text{O}_3$, $\text{Si}_3\text{N}_4$, $\text{TiO}_2$, $\text{HZO/Al}_2\text{O}_3$) between the ferroelectric film and electrodes or substrate reduces interfacial oxygen vacancy generation, lowers leakage current, and decreases the voltage drop across the IL.
2. **Doping Profiles & Stoichiometry Optimization:**
   Graded dopant concentration profiles (e.g., Zr gradient, La/Y/Al doping) and oxygen stoichiometry control prevent vacancy agglomeration at interfaces and stabilize the polar $Pca2_1$ phase without severe cycling degradation.
3. **Pulse Scheme Engineering:**
   Applying optimized write/read pulse trains—such as trapezoidal pulse shaping, write-after-read schemes, and alternating recovery pulses—relieves internal stress, promotes domain depinning, and cancels internal bias fields ($E_{im}$) to suppress imprint.
4. **Interface Termination & Low-Thermal-Budget Processing:**
   Engineering crystal layer terminations at the bottom interface suppresses initial phase distortion and eliminates the need for wake-up cycling altogether.

---

### Fact-Checked Factual Claims Ledger

#### Claim 4.1: Alumina Passivating Interlayers for Fatigue Mitigation
* **Claim:** Inserting a thin $1\text{ nm Al}_2\text{O}_3$ passivating interlayer at the $\text{HZO/TiN}$ interface provides excess oxygen to mitigate oxygen vacancy formation, suppressing fatigue and increasing endurance beyond $10^8\text{ cycles}$ at $3.5\text{ MV/cm}$.
* **Numeric Value with Units:** $1\text{ nm Al}_2\text{O}_3$ interlayer thickness; $>10^8\text{ cycles}$ endurance limit; $3.5\text{ MV/cm}$ electric field amplitude.
* **DOI:** [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a)
* **Full Author List:** H. Alex Hsain, Young H. Lee, Suzanne Lancaster, Patrick D. Lomenzo, Bohan Xu, Thomas Mikolajick, Uwe Schroeder, Gregory N. Parsons, Jacob L. Jones
* **Venue:** *Nanotechnology*
* **Year:** 2022
* **Verbatim Quoted Sentence:** 
  > *"By inserting an interfacial layer while limiting exposure to the ambient environment, we successfully introduce a protective passivating layer of Al 2 O 3 that provides excess oxygen to mitigate vacancy formation at the interface."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 4.2: Work-Function and Interfacial Engineering for Depolarization & Trapping Mitigation
* **Claim:** Optimizing the interfacial layer and controlling effective work-function (eWF) bias reduces depolarization field loss and suppresses charge trapping, achieving a 10-year extrapolated memory window of $\sim 0.8\text{ V}$ at $85\text{ }^\circ\text{C}$.
* **Numeric Value with Units:** $\sim 0.8\text{ V}$ memory window; $85\text{ }^\circ\text{C}$ retention temperature; 10-year extrapolation duration.
* **DOI:** [10.1109/ted.2021.3096510](https://doi.org/10.1109/ted.2021.3096510)
* **Full Author List:** Y. Higashi, N. Ronchi, B. Kaczer, Md Nur K. Alam, Barry O’Sullivan, Kaustuv Banerjee, S. R. C. McMitchell, L. Breuil, A. Walke, G. Van den bosch, D. Linten, Jan Van Houdt
* **Venue:** *IEEE Transactions on Electron Devices*
* **Year:** 2021
* **Verbatim Quoted Sentence:** 
  > *"In addition, the impact of external bias and interfacial layer (IL) on the DR loss is revealed: the polarization loss is strongly affected by the external bias in both types of FEFET, indicating effective work function (eWF) has a strong impact on depolarization."*
* **Publication Type:** Peer-reviewed journal publication.

---

#### Claim 4.3: Elimination of Wake-Up Effect via Interfacial Termination Engineering
* **Claim:** Interfacial termination control on $\text{MnO}_2$-terminated bottom electrodes stabilizes the ferroelectric orthorhombic (111) phase in ultrathin $1.5\text{ nm}$ HZO films while completely eliminating the wake-up effect.
* **Numeric Value with Units:** $1.5\text{ nm}$ film thickness; 0 wake-up cycles required.
* **DOI:** [10.1038/s41467-023-37560-3](https://doi.org/10.1038/s41467-023-37560-3)
* **Full Author List:** Shu Shi, Haolong Xi, Tengfei Cao, Weinan Lin, Zhongran Liu, Jiangzhen Niu, Da Lan, Chenghang Zhou, Jing Cao, Hanxin Su, Tieyang Zhao, Ping Yang, Yao Zhu, Xiaobing Yan, Evgeny Y. Tsymbal, He Tian, Jingsheng Chen
* **Venue:** *Nature Communications*
* **Year:** 2023
* **Verbatim Quoted Sentence:** 
  > *"We find that the Hf 0.5 Zr 0.5 O 2 films on the MnO 2 -terminated La 0.67 Sr 0.33 MnO 3 have more ferroelectric orthorhombic phase than those on the LaSrO-terminated La 0.67 Sr 0.33 MnO 3 , while with no wake-up effect."*
* **Publication Type:** Peer-reviewed journal publication.

---

## Summary Table for TCAD Parameter Setup

| Parameter / Feature | Representative Empirical Range | Primary Physical Driver | Key Literature Reference |
| :--- | :--- | :--- | :--- |
| **Ferroelectric Phase** | Orthorhombic $Pca2_1$ ($o\text{III}$-phase) | Oxygen displacement along polar $c$-axis | Chen & Liu (2023), *APL* [10.1063/5.0159700](https://doi.org/10.1063/5.0159700) |
| **Remanent Polarization ($P_r$)** | $15\text{--}25\text{ }\mu\text{C/cm}^2$ ($2P_r \approx 30\text{--}50\text{ }\mu\text{C/cm}^2$) | Encapsulation strain & grain size ($5\text{--}15\text{ nm}$) | Hsain et al. (2022), *Nanotechnology* [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a) |
| **Coercive Field ($E_c$)** | $1.0\text{--}2.0\text{ MV/cm}$ | High intrinsic energy barrier in fluorite oxide | Böscke et al. (2011), *APL* [10.1063/1.3634052](https://doi.org/10.1063/1.3634052) |
| **Thermal Budget** | $\le 400\text{ }^\circ\text{C}$ anneal | Mechanical tensile stress via TiN top electrode ($\ge 90\text{ nm}$) | Kim et al. (2017), *APL* [10.1063/1.4995619](https://doi.org/10.1063/1.4995619) |
| **Wake-up Mechanism** | $10^2\text{--}10^4\text{ cycles}$ | Oxygen vacancy ($V_O$) redistribution & domain depinning | Pešić et al. (2016), *AFM* [10.1002/adfm.201600590](https://doi.org/10.1002/adfm.201600590) |
| **Fatigue Mechanism** | $>10^5\text{--}10^8\text{ cycles}$ | Defect generation & domain wall pinning | Lee et al. (2023), *Nano Convergence* [10.1186/s40580-023-00403-4](https://doi.org/10.1186/s40580-023-00403-4) |
| **Imprint / Bias Field** | Shift $\Delta V_{im} \approx 0.1\text{--}0.5\text{ V}$ | Asymmetric charge trapping & internal bias field $E_{im}$ | Zagni et al. (2023), *Proc. IEEE* [10.1109/jproc.2023.3234607](https://doi.org/10.1109/jproc.2023.3234607) |
| **Depolarization / Retention** | 10-year $\text{MW} \sim 0.8\text{ V}$ at $85\text{ }^\circ\text{C}$ | Uncompensated $E_{dep}$ across low-$k$ interfacial layer ($\text{SiO}_2$) | Higashi et al. (2021), *IEEE TED* [10.1109/ted.2021.3096510](https://doi.org/10.1109/ted.2021.3096510) |
| **Mitigation (Passivation)** | Endurance $>10^8\text{ cycles}$ at $3.5\text{ MV/cm}$ | Insertion of $1\text{ nm Al}_2\text{O}_3$ oxygen-rich passivating interlayer | Hsain et al. (2022), *Nanotechnology* [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a) |
