# Workflow

# Comprehensive Technical Roadmap for Simulating 2D Nanosheet GAAFET LIF Neurons via Sentaurus TCAD

## 1. Introduction: The Convergence of Ferroelectrics and Neuromorphic Architectures

## 2. Device Structure and Geometrical Definition (SDE)

The foundation of any TCAD simulation is the structural definition. For the LIF neuron application, the dimensions are not chosen for maximum logic density, but rather to facilitate specific physical phenomena—specifically, the acceleration of carriers for impact ionization and the retention of charge in the floating body.

### 2.1 Dimensional Specifications

**Here is the revised Dimensional Specifications** table with the source names added directly to the column:

**2.1 Dimensional Specifications**

| **Parameter** | **Symbol** | **Value** | **Justification** | **Source** |
| --- | --- | --- | --- | --- |
| **Gate Length** | $L_g$ | 100 nm | Sufficient length to allow carrier acceleration for Impact Ionization at low V_{DS}. Sub-10nm channels would suppress II due to quasi-ballistic transport. | Design of energy-efficient LIF neuron... |
| **Nanosheet Thickness** | $T_{FNS}$ | 15 nm | Thick enough to sustain a floating body potential well; thin enough to maintain gate control. | Design of energy-efficient LIF neuron... |
| **Fin Height (Width)** | $H_{FNS}$ | 90 nm | In the 2D cross-section, this acts as the normalization width (W) for current density. | Design of energy-efficient LIF neuron... |
| **Interfacial Oxide** | $T_{ox}$ | 2 nm | SiO_2 layer to ensure interface quality and reduce scattering. | Design of energy-efficient LIF neuron... |
| **Ferroelectric Thickness** | $T_{FE}$ | 10 nm | Thickness required to establish a stable coercive voltage (V_c) compatible with the operating window. | General FeFET Literature (HZO) |
| **Source/Drain Length** | $L_{S/D}$ | $\sim 50 nm$ | Approximate length in the Sentaurus Structure Editor (SDE) to isolate contacts from the channel region and minimize parasitic effects. |  |
- **"Design of energy-efficient LIF neuron..."**: Refers to the core research paper, "Design of energy-efficient LIF neuron using CMOS compatible gate-all-around floating nanosheet FET for bio-inspired spiking neural networks."

**Analysis of Gate Length ($L_g = 100$ nm):** While logic scaling pushes gate lengths below 12 nm , the LIF neuron requires a "runway" for charge carriers. Impact ionization is a scattering process that depends on the carrier gaining kinetic energy from the electric field in excess of the silicon bandgap (1.12 eV). In extremely short channels, transport becomes quasi-ballistic, and carriers may traverse the channel without undergoing the necessary scattering events to generate electron-hole pairs. The 100 nm length specified in is a deliberate design choice to maximize the ionization rate at lower drain voltages ($V_{DS} \approx 1.0 V$), ensuring energy efficiency (4.88 fJ/spike).

**Analysis of Nanosheet Thickness ($T_{FNS} = 15$ nm):** The thickness of the silicon channel is a critical variable. A channel that is too thin (e.g., < 5 nm) would be fully depleted by the gate workfunction and built-in potentials, leaving no neutral region for holes to accumulate. This would eliminate the floating body effect, which is the heart of the integration mechanism. Conversely, a channel that is too thick would degrade electrostatic control, leading to high leakage (I_{off}) and poor subthreshold swing. The 15 nm specification represents an optimal trade-off, creating a distinct potential well for charge integration while maintaining the "kink" effect necessary for the firing threshold.

### Analysis of Fin Height (the 2D-3D Tradeoff)

## 1. Problem Statement

The physical device defined in the reference architecture is a 3D Gate-All-Around Floating Nanosheet FET with a specific Fin Height ($H_{FNS}$) of **90 nm**1. However, the simulation framework is restricted to a 2D cross-section to optimize computational efficiency.

Standard 2D TCAD simulations assume a default depth (Z-axis) of **$1.0 \mu m$**. Without correction, this discrepancy results in:

- **Current Magnitude Error:** Drain currents ($I_{DS}$) will be overestimated by a factor of ~11x (1000 nm / 90 nm).
- **Capacitance Error:** The floating body volume will be artificially large, creating an incorrect body capacitance ($C_{body})$ that distorts the integration time and spiking frequency of the LIF neuron.

## 2. Theoretical Justification

To accurately model the 3D physics in a 2D environment, a scaling factor must be applied. Two approaches were evaluated:

### Primary Approach: Volumetric Scaling (Selected Baseline)

This method prioritizes the accurate simulation of the **Floating Body Effect**, which is the core mechanism of the LIF neuron. The integration rate of the neuron depends on the volume of the silicon body where charge accumulates.

- **Logic:** The 2D simulation captures the Length ($L_g$) and Thickness ($T_{FNS}$). Scaling strictly by the Height ($H_{FNS}$) ensures the total silicon volume matches the physical device.
- **Result:** This preserves the correct charge-to-voltage relationship ($\Delta V = \Delta Q / C$), ensuring accurate spiking timing.

### Secondary Approach: Perimeter Scaling (Tuning Option)

This method prioritizes **Current Drive** $(I_{ON})$. In a real GAA device, the gate wraps around the sidewalls, adding extra channel width.

- **Logic:** The "Effective Width" $(W_{eff})$ is approximately the perimeter of the nanosheet ($2 \times H_{FNS} + 2 \times T_{FNS}$).
- **Usage:** This method is reserved as a "backup" strategy if the device fails to reach the firing threshold current ($I_{th} = 94 nA$) under Volumetric Scaling.

## 3. Implementation Workflow

### Phase 1: Structure Generation (SDE)

**Action:** Ignore $H_{FNS}$ during geometric construction.

- Draw the device strictly in the 2D plane (X and Y axes).
- Use the standard Gate Length ($L_g = 100 nm$) and Thickness ($T_{FNS} = 15 nm$) as defined.

### Phase 2: Device Physics Configuration (S-Device)

Action: Apply the AreaFactor scaling parameter.

Instead of manually calculating current densities after the simulation, configure the simulator to scale all outputs (Currents, Capacitances, Charges) automatically.

1. **Locate the Physics Section:** In your S-Device command file input.
2. **Define AreaFactor:** Set the `AreaFactor` variable to **0.09**.
    - *Calculation:* $90 \text{ nm} / 1000 \text{ nm (default)} = 0.09$.
3. **Alternative Setting (Optional):** If "Perimeter Scaling" is required later for troubleshooting low currents, this value would be adjusted to **0.105**.

### Phase 3: Validation Criteria

To confirm the scaling is active and correct, perform the following check on the simulation output:

1. **Check Unit Order of Magnitude:**
    - Run a simple $I_d-V_g$ sweep.
    - At $V_{DS} = 1.0 V$ and high $V_{GS}$, the current should be in the range of **micro-amps ($\mu A$)** (e.g., $10-100 \mu$ A).
    - If the current is in **milli-amps (mA)**, the `AreaFactor` was not applied correctly, and the result is defaulting to the  $1 \mu m$ depth.
2. **Threshold Check:**
    - Verify if the leakage current allows for the identification of the target threshold current ($I_{th} \approx 94 nA$).

### 2.2 Sentaurus Structure Editor (SDE) Workflow

The construction of this geometry in SDE involves defining the 2D cross-section. Since the device is a GAA structure, the 2D view along the transport direction appears as a Double-Gate FET (DGFET), with the gate stack wrapping around the top and bottom of the silicon body.

**Step 1: Define Parameters** The first action in the SDE Scheme script is to define the variables extracted above. This parameterization allows for easy sensitivity analysis later.

```json
(define Lg 0.100) ; Gate Length

(define Tsi 0.015) ; Nanosheet Thickness

(define Tox 0.002) ; Interfacial Oxide Thickness

(define Tfe 0.010) ; Ferroelectric HZO Thickness

(define Lsd 0.040) ; Source/Drain Extension
```

**Step 2: Create the Silicon Body** A rectangular region representing the silicon nanosheet is generated. The coordinate system is typically centered, with the channel extending from $x = -L_g/2$ to $x = L_g/2$. The source and drain regions extend beyond this to $\pm(L_g/2 + L_{sd})$.

- **Material:** Silicon
- **Region Name:** region_channel

**Step 3: The Gate Stack Construction** The gate stack is composite, consisting of the Interfacial Layer (IL) and the Ferroelectric (FE) layer. In a 2D GAA approximation, this stack must be placed both **above** and **below** the silicon body to simulate the "surrounding" nature of the gate.

- **Top Stack:**
    - IL ($SiO_2$): From  $y = T_{si}/2$ to $y = T_{si}/2 + T_{ox}$.
    - FE (HZO): From $y = T_{si}/2 + T_{ox}$ to $y = T_{si}/2 + T_{ox} + T_{fe}$.
    - Gate Contact ($TiN$): Placed on top of the FE layer.
- **Bottom Stack:**
    - Symmetrical arrangement in the negative y-direction.

**Step 4: Contact Definition**

- **Source Contact:** Placed at the extreme left edge of the silicon body.
- **Drain Contact:** Placed at the extreme right edge.
- **Gate Contact:** The top and bottom metal lines are electrically coupled to form a single "Gate" electrode.

**Step 5: Meshing Strategy for Impact Ionization and Ferroelectrics** Standard meshing is insufficient for this simulation. Impact ionization is highly localized at the drain-channel junction where the electric field peaks. Furthermore, the Ginzburg-Landau model for ferroelectrics requires a dense mesh to resolve polarization gradients.

- **Junction Refinement:** A meshing window must be placed at the channel-drain interface with an extremely fine step size ($dx \approx 1-2$ nm) to capture the peak electric field and the generation rate of electron-hole pairs.
- **Transverse Refinement:** Across the thickness of the nanosheet (y-direction), a mesh size of < 0.5 nm is recommended to resolve the quantum confinement effects (using Density Gradient models) and the charge accumulation profile in the floating body.
- **Ferroelectric Refinement:** The HZO layer requires a fine mesh ($dy \approx 1$ nm) to ensure convergence of the polarization vector P, especially if multi-domain dynamics are activated.

## 3. Material Properties and Physics Customization (S-Device)

The fidelity of the simulation hinges on the material parameters. While S-Device contains default libraries, the specific properties of HZO and the calibrated Impact Ionization model for LIF neurons must be manually injected.

### 3.1 Silicon Doping Profiles

**3.1 Silicon Doping Profiles**

| **Region** | **Dopant** | **Type** | **Concentration ($cm^{-3}$)** | **Function** | **Source** |
| --- | --- | --- | --- | --- | --- |
| **Channel** | Boron | P-type | $1 \times 10^{16}$ | Low doping minimizes impurity scattering and allows full depletion at low $V_{gs}$, essential for the "Leaky" behavior. | Design of energy-efficient LIF neuron... |
| **Source** | Arsenic | N-type | $1 \times 10^{20}$ | Degenerate doping ensures ohmic contacts and low series resistance. | Design of energy-efficient LIF neuron... |
| **Drain** | Arsenic | N-type | $1 \times 10^{20}$ | High concentration creates a sharp junction, enhancing the electric field for Impact Ionization. | Design of energy-efficient LIF neuron... |

**Insight on Doping Profile:**

The choice of a very low channel doping ($1 \times 10^{16} \text{ cm}^{-3}$) is paramount for the LIF mechanism. It facilitates the depletion of the channel at low gate bias, which is necessary for the initial "Leaky" current, and it maximizes the sensitivity of the floating body potential to the small charge accumulation from impact ionization, directly controlling the firing threshold. The abrupt, high-concentration source/drain doping ensures the high-field region at the drain junction is well-defined, which is key to triggering the Impact Ionization cascade at a low drain voltage ($V_{DS} = 1.0 \text{ V}$).

**Workfunction Engineering:** The gate metal workfunction is the primary knob for tuning the threshold voltage ($V_{th}$).

- **Parameter:** Workfunction
- **Value:** 4.6 eV
- **Material:** Titanium Nitride (TiN) reference.
- **Adjustment:** In 2D simulations, the lack of corner effects (which naturally lower $V_{th}$ in 3D structures due to field crowding) may necessitate a slight lowering of this value (e.g., to 4.52 - 4.55 eV) to match 3D current levels, though 4.6 eV is the starting baseline from.

### 3.2 Ferroelectric HZO Physics (Landau-Khalatnikov)

Modeling HZO requires the Ferroelectric physics module in S-Device, which solves the time-dependent Ginzburg-Landau (TDGL) equation coupled with Poisson's equation. The polarization P is determined by the thermodynamic free energy landscape defined by the Landau coefficients $\alpha$, $\beta$, and $\gamma$.

**Material:** $Hf_{0.57}Zr_{0.43}O_{2}$ (HZO) The specific stoichiometry 57:43 is chosen for its proximity to the morphotropic phase boundary, offering robust ferroelectricity.

| **Sentaurus Parameter** | **Symbol** | **Value** | **Unit** | **Explanation** | **Source** |
| --- | --- | --- | --- | --- | --- |
| alpha | $\alpha$ = [x y z] | alpha = $1.3e12$ $-9.889e10$ $1.3e12$ | $cm/F$ | The negative coefficient creates the "double well" energy potential required for bistability (memory). | General FeFET Literature (HZO) |
| beta | $\beta$ | $2.00720 \times 10^{19}$ | $cm^5/F C^2$ | Determines the steepness of the potential wells; critical for the coercive field value. | General FeFET Literature (HZO) |
| gamma | $\gamma$ | 0 | cm^9/F C^4 | Higher-order term, set to zero for this model simplification. | General FeFET Literature (HZO) |
| g11, g22 | g | $5 \times 10^{-7}$ | $cm^3/F$ | Gradient energy coefficients. They penalize sharp changes in polarization, enforcing domain wall width. | General FeFET Literature (HZO) |
| rho | $\rho$ | $2.25 \times 10^4$ | $\Omega \cdot cm$ | Kinetic viscosity. This damping term determines the switching speed and is crucial for transient convergence. | General FeFET Literature (HZO) |
| epsilon | $\epsilon_r$ | 33 | - | The background dielectric constant of the lattice. | General FeFET Literature (HZO) |
| ec | E_c | $1.1 \times 10^6$ | V/cm | Reference Coercive Field (used for initialization). | General FeFET Literature (HZO)
Figure 2C |
| pr | P_r | $20 \times 10^{-6}$ | $C/cm^2$ | Remnant Polarization charge density. | General FeFET Literature (HZO)
Figure 2C |
- **"General FeFET Literature (HZO)"**: Refers to general literature, such as "Physical modeling of HZO-based ferroelectric field-effect transistors...", which establishes the standard dimensions for $\text{HfZrO}_2$ (HZO) stacks in neuromorphic applications.
- ----**Anisotropy in 2D:** Since the simulation is 2D, the polarization axis must be explicitly defined. The relevant polarization is perpendicular to the gate (y-direction).
- **Implementation:** In the S-Device parameter file, alpha should be defined as a tensor or specifically for the y-axis. Often,  $\alpha_1$ (x-axis) is set to a positive value (paralelectric) to force the polarization vector to align along the y-axis (the switching direction).

### 3.3 Impact Ionization Model (Unibo2)

This is the most critical parameter set for the LIF neuron. Standard impact ionization models (like Chynoweth) often underestimate the generation rate in nanometer-scale devices operating at low voltages. The "UniBo2" (University of Bologna) model is required because it accounts for non-local effects and high-field transport more accurately.

**The "Firing" Trigger:** To achieve the firing behavior at a drain voltage of $V_{DS} = 1.0$ V (as opposed to the breakdown voltage of silicon which is much higher), the ionization rate must be enhanced. explicitly modifies the pre-factor d0 of the UniBo2 model.

**3.3 Impact Ionization Model (Unibo2)**

| **Parameter** | **Symbol** | **Standard Value** | **LIF Modified Value** | **Impact** | **Source** |
| --- | --- | --- | --- | --- | --- |
| d0_e | $d_{0,e}$ | (Material Default) | **$1.0 \times 10^6$** | drastically increases electron-initiated ionization rate at lower fields. | Design of energy-efficient LIF neuron... |
| d0_h | $d_{0,h}$ | (Material Default) | **$1.0 \times 10^6$** | Increases hole-initiated ionization rate. | Design of energy-efficient LIF neuron... |

**Physics Narrative:**

By artificially raising d0 to $10^6$, we are calibrating the simulation to mimic the specific "kink" observed in experimental FNSFETs. In the TCAD model, this parameter tuning is the "knob" that enables the neuron to fire at 1V. Without this adjustment, the device would simply act as a transistor, not a neuron.

## 4. Detailed "To-Do" List for SDE and S-Device

This section translates the theoretical data into actionable steps for the TCAD engineer.

### 4.1 Phase 1: Structure Generation (SDE)

**Objective:** Generate gaafet_lif_msh.tdr (grid file) and gaafet_lif_msh.cmd (doping file).

1. **Initialize Environment:**
    - Launch SDE.
    - Set the exact dimensions (L_g=100nm, T_{FNS}=15nm, etc.) as scheme variables.
2. **Draw Geometry:**
    - Create the Silicon Body rectangle. Coordinates: (-0.04, 0) to (0.14, 0.015) (assuming microns).
    - Create Top Oxide (SiO_2): (0, 0.015) to (0.1, 0.017).
    - Create Bottom Oxide (SiO_2): (0, 0) to (0.1, -0.002).
    - Create Top FE (HZO): (0, 0.017) to (0.1, 0.027).
    - Create Bottom FE (HZO): (0, -0.002) to (0, -0.012).
    - Create Contacts: Source (left edge), Drain (right edge), Gate (top/bottom of FE).
3. **Define Doping:**
    - **Baseline:** ConstantProfile "Boron" 1\times10^{16} applied to the Silicon Body.
    - **Source/Drain:** AnalyticProfile (Gaussian) "Arsenic".
        - Peak Concentration: 4\times10^{20}.
        - Standard Deviation (Lateral Decay): 0.003 \mu m (3 nm) for abruptness.
4. **Define Mesh:**
    - **Global:** Max element size 0.02 \mu m.
    - **Channel (Active):** Max element size x=0.005, y=0.001.
    - **Drain Junction (Crucial):** Define a refinement window at the Channel/Drain interface (x=0.1). Max element size x=0.001, y=0.0005 (0.5 nm). *Reason: This is where II happens.*
    - **HZO Layer:** Max element size y=0.001 (1 nm). *Reason: To resolve polarization gradients.*
5. **Build and Save:**
    - Run the mesh engine (snmesh). Ensure no obtuse angles or inverted elements.

### 4.2 Phase 2: Device Physics Setup (S-Device)

**Objective:** Configure the sdevice.cmd and sdevice.par files.

1. **File sdevice.par (Parameter File):**
    - Locate the Silicon material section.
    - Add/Modify Avalanche_Unibo2 block:
        
        Avalanche_Unibo2 {
        
        d0_e = 1.0e6
        
        d0_h = 1.0e6
        
        * Leave a_e, b_e, etc., as default or calibrated values if available
        
        }
        
    - Create/Modify Material = "HZO" section:
        
        Material = "HZO" {
        
        Epsilon = 33
        
        Ferroelectric {
        
        alpha = -9.889e10
        
        beta = 2.007e19
        
        g11 = 5e-7
        
        rho = 2.25e4
        
        ec = 1.1e6
        
        pr = 20e-6
        
        }
        
        }
        
2. **File sdevice.cmd (Command File) - Physics Section:**
    - Enable the following models:
        
        Physics {
        
        * Carrier Statistics
        
        Fermi
        
        EffectiveIntrinsicDensity( OldSlotboom )
        
        * Transport
        
        Mobility(
        
        DopingDep
        
        HighFieldSat
        
        Enormal
        
        )
        
        * Recombination
        
        Recombination(
        
        SRH( DopingDep )
        
        Auger
        
        Avalanche( Unibo2 ) * ACTIVATES THE LIF TRIGGER
        
        )
        
        * Ferroelectricity
        
        Ferroelectric( P_L( P_x P_y ) )
        
        }
        
3. **Simulation Strategy (Solve Section):**
    - **Quasistatic Initialization:** Ramp Gate to 0V, Drain to 0V.
    - **Hysteresis Check (Optional):** Ramp Gate from -3V to 3V and back to check Ferroelectric switching.
    - **LIF Operation (Transient):**
        - Fix Drain Voltage: V_{Drain} = 1.0 V.
        - Define Input Pulse: Use a piecewise linear (PWL) function for the Gate Voltage to simulate incoming spikes (e.g., pulses of 0.5V - 1.0V).
        - Time Stepping: Use very small initial steps (1 \times 10^{-12} s) because the firing event is extremely fast.

Transient (

InitialTime = 0 FinalTime = 100e-9

MaxStep = 1e-10 MinStep = 1e-14

) {

Coupled { Poisson Electron Hole Ferroelectric }

}

## 5. Analytical Insights and Interpretation of Results

Understanding the output of this simulation requires interpreting the interplay between the ferroelectric hysteresis and the floating body kinetics.

### 5.1 The Integration Phase (Leaky Behavior)

During the "Integration" phase, the gate voltage is low, or sub-threshold input pulses are arriving. The drain is biased at 1.0V.

- **Observation:** The drain current (I_d) should be low (leakage regime). However, inside the device, the electric field at the drain junction is generating a small number of holes via impact ionization.
- **Mechanism:** These holes drift towards the source but are trapped by the potential barrier of the source-channel junction (Floating Body Effect).
- **Data Signal:** Plot the "Hole Density" integral in the channel region vs. Time. You should see a stepwise or continuous increase in hole concentration. This corresponds to the rising "Membrane Potential" (V_{mem}) in a biological neuron.

### 5.2 The Firing Phase (Kink Effect)

As hole accumulation continues, the potential of the floating body rises. This lowers the source-channel potential barrier, allowing more electrons to inject from the source.

- **Feedback Loop:** More electrons \rightarrow higher current \rightarrow more impact ionization \rightarrow more holes \rightarrow even lower barrier.
- **Observation:** This positive feedback loop results in a sudden, sharp increase in drain current. This is the **Spike**.
- **Validation:** The current should jump by orders of magnitude (e.g., from nA to \muA) very rapidly. This matches the "Fire" characteristic. The threshold for this firing is determined by the d0 parameter in Unibo2 and the Drain Voltage.

### 5.3 The Role of Ferroelectricity (Memory & Adaptation)

The HZO layer adds a layer of plasticity to this neuron.

- **Mechanism:** If a high-voltage "write" pulse is applied to the gate, the polarization of the HZO flips. This changes the flat-band voltage and consequently the threshold voltage (V_{th}) of the transistor.
- **Neuromorphic Implication:** A "Depression" pulse (negative V_g) increases V_{th}, making it harder for the neuron to fire (requires more hole accumulation). A "Potentiation" pulse (positive V_g) lowers V_{th}, making the neuron more excitable.
- **Data Signal:** Extract the I_d-V_g curve before and after applying a program pulse. A shift in the curve (Memory Window) validates the synaptic weight storage capability.

### 5.4 Parasitics and 2D Limitations

While this 2D roadmap captures the core longitudinal physics, it neglects the gate capacitance contributions from the sidewalls (the vertical walls of the nanosheet).

- **Implication:** The computed I_{on}/I_{off} ratio might be slightly different from a full 3D simulation because the electrostatic control in 2D is effectively that of a double-gate device, not a quadruple-gate (all-around) device.
- **Correction:** When calculating energy per spike (E = \int I \cdot V dt), acknowledge that the gate capacitance (C_{gg}) in 2D is an underestimation. For precise power analysis, a geometric factor (approx 2x for the sidewalls) should be applied to the gate current.

## 6. Conclusion

This roadmap synthesizes the geometric specifications of LIF-optimized FNSFETs with the advanced material physics of Ferroelectric HZO. By approximating the 3D architecture with a calibrated 2D cross-section and employing the Unibo2 model with enhanced ionization coefficients (d_0 = 10^6), the simulation is engineered to replicate the low-voltage (1.0 V) firing dynamics characteristic of energy-efficient neuromorphic hardware. The integration of the Landau-Khalatnikov formulation further endows the device with non-volatile plasticity, enabling it to function as both a neuron and a synapse—a unified primitive for the next generation of brain-inspired computing. The successful execution of the SDE and S-Device protocols detailed herein will yield a virtual device capable of validating Spiking Neural Network architectures before fabrication.