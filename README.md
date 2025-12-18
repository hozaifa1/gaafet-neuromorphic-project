# GAA FeFET LIF Neuron - Sentaurus TCAD Simulation

## Overview

This repository contains Sentaurus TCAD simulation files for a **Gate-All-Around Ferroelectric Field-Effect Transistor (GAA FeFET)** designed as a **Leaky Integrate-and-Fire (LIF) Neuron** for neuromorphic computing applications.

The device combines:
- **GAA Nanosheet Architecture** for superior electrostatic control
- **HZO Ferroelectric Layer** for non-volatile synaptic weight storage
- **Floating Body Effect** with **Impact Ionization** for LIF neuron behavior

The simulation uses a **2D double-gate approximation** of the 3D GAA device, following the geometry/stack/doping values in `Workflow.md`.

## Device Architecture

| Parameter | Symbol | Value | Description |
|-----------|--------|-------|-------------|
| Gate Length | L_g | 100 nm | Optimized for impact ionization at low V_DS |
| Nanosheet Thickness | T_FNS | 15 nm | Floating body potential well |
| Fin Height (Width) | H_FNS | 90 nm | 2D normalization width |
| Interfacial Oxide | T_ox | 2 nm | SiO₂ interface layer |
| Ferroelectric Thickness | T_FE | 10 nm | HZO ferroelectric layer |
| Source/Drain Length | L_S/D | ~50 nm | Contact isolation |

### Gate Stack (Workflow.md Source of Truth)

The implemented device stack follows the **MFIS** stack defined in `Workflow.md`:

- **Silicon (channel)**
- **SiO₂ interfacial oxide** (`T_ox = 2 nm`)
- **HZO ferroelectric** (`T_FE = 10 nm`)
- **TiN gate metal**

There is **no internal TiN layer** between SiO₂ and HZO.

### Doping Profile

| Region | Dopant | Type | Concentration (cm⁻³) |
|--------|--------|------|---------------------|
| Channel | Boron | P-type | 1×10¹⁶ |
| Source | Arsenic | N-type | 1×10²⁰ |
| Drain | Arsenic | N-type | 1×10²⁰ |

## Repository Structure

```
GAAFet/
├── README.md                    # This file
├── Workflow.md                  # Detailed technical roadmap
├── Papers/                      # Reference literature
│   ├── Design of energy-efficient LIF neuron...pdf
│   ├── Physical modeling of HZO-based.pdf
│   └── ...
├── Reference_Codes/             # All reference implementations
│   ├── Working_Codes_MFMIS/     # PRIMARY: Syntax/structure reference (battle-tested)
│   │   ├── sde_dvs.cmd          # SDE Scheme syntax patterns (function usage, structure)
│   │   ├── sdevice_des.cmd      # S-Device command file
│   │   └── sdevice.par          # Material parameters
│   └── GAAFET_Coursework2/      # SECONDARY: 3D GAA FET reference (akdimitri repo)
│       ├── Ohmic_SDE.txt        # 3D cylindrical GAA SDE
│       ├── CIGAAFET.txt         # Core-insulated GAA variant
│       └── Ohmic_CIGAAFET_SDevice.txt
└── Simulations/                 # Active simulation files
    ├── sde_gaafet_lif.cmd       # GAA FeFET LIF neuron SDE
    ├── sdevice_gaafet_lif.cmd   # S-Device command file
    └── sdevice_gaafet_lif.par   # Material parameters
```

## Key Physics Models

### Ferroelectric (HZO) - Landau-Khalatnikov Model

| Parameter | Value | Unit |
|-----------|-------|------|
| α (alpha) | -9.889×10¹⁰ | cm/F |
| β (beta) | 2.007×10¹⁹ | cm⁵/FC² |
| γ (gamma) | 0 | cm⁹/FC⁴ |
| ε_r | 25-33 | - |

### Impact Ionization (UniBo2 Model)

`Workflow.md` specifies UniBo2 calibration for LIF firing at `V_DS = 1.0 V`.

Note: the current `Simulations/sdevice_gaafet_lif.cmd` file is primarily set up for FE hysteresis/initial checks; UniBo2 enablement and calibration should follow the workflow when moving to full LIF (impact-ionization-driven) transient runs.

## 2D Simulation Approach

The 3D GAA structure is approximated as a 2D Double-Gate FET (DGFET) with volumetric scaling:

- **AreaFactor = 0.09** (90 nm / 1000 nm default depth)
- Preserves floating body volume for accurate charge integration
- Maintains correct spiking timing for LIF neuron behavior

## Quick Start

1. **Structure Generation (SDE)**
   ```bash
   sde -e -l Simulations/sde_gaafet_lif.cmd
   ```

2. **Device Simulation (S-Device)**
   ```bash
   sdevice Simulations/sdevice_gaafet_lif.cmd
   ```

3. **Visualization (SVisual)**
   ```bash
   svisual n@node@_des.tdr
   ```

## Target Performance Metrics

- **Firing Threshold Current**: I_th ≈ 94 nA
- **Operating Voltage**: V_DS = 1.0 V
- **Energy per Spike**: ~4.88 fJ/spike
- **Gate Workfunction**: 4.6 eV (TiN)

## References

1. "Design of energy-efficient LIF neuron using CMOS compatible gate-all-around floating nanosheet FET for bio-inspired spiking neural networks"
2. "Physical modeling of HZO-based ferroelectric field-effect transistors"
3. [akdimitri/Advanced-Electronic-Devices](https://github.com/akdimitri/Advanced-Electronic-Devices) - GAAFET coursework reference

## License

Research use only. See individual papers for citation requirements.

## Author

Research Project - FeFET x ML / TCAD Simulations
