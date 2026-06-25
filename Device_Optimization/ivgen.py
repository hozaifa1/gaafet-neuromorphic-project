"""Corrected retained-state memory-window I-V generator (frozen FE, proper switching).

Recipe (from the Liao calibration): tau_E=100us frozen (par app_frozen.par),
write holds 500us >> tau_E (FULL switch), read sweeps 5us << tau_E (frozen, DC).
erase(V_e) -> read I_D-V_G sweep ; program(V_p) -> read sweep.

gen(mesh, probe_y, ...) -> cmd string. Run with app_frozen.par.
"""

T = """*== Corrected memory-window I-V (ivgen.py): 500us writes, 5us frozen reads.
File {{
    Grid = "{mesh}_msh.tdr"
    Parameter = "app_frozen.par"
    Plot = "opt_outputs/iv_{mesh}_des.tdr"
    Current = "opt_outputs/iv_{mesh}_des.plt"
    Output = "opt_outputs/iv_{mesh}_des.log"
}}
Electrode {{
  {{ Name="source_contact" Voltage=0.0 }}
  {{ Name="drain_contact"  Voltage=0.0 }}
  {{ Name="gate_contact"   Voltage=0.0 Workfunction={WF} }}
}}
Physics {{
  Temperature=300 Areafactor=0.071 Fermi EffectiveIntrinsicDensity( OldSlotboom )
  Mobility( PhuMob Enormal )
  Recombination( SRH (DopingDependence TempDependence) Auger Band2Band(Model=Hurkx) )
}}
Physics(Material="HZO") {{ Polarization }}
Physics(MaterialInterface="Silicon/SiO2") {{
  Traps(
    (FixedCharge Conc=7e12 Level EnergyMid=0.0 fromMidBandGap)
    (Acceptor Gaussian fromCondBand Conc=4e12 EnergyMid=0.45 EnergySig=0.30
              eXsection=1e-15 hXsection=1e-15) )
}}
Math {{
  Extrapolate RelErrControl Digits=6 Notdamped=50 Iterations=50 Transient=BE
  FEPolarizationIP=1.0 Method=Blocked SubMethod=ParDiSo GeometricDistances Derivative
  ComputeGradQuasiFermiAtContacts= UseQuasiFermi
  RefDens_eGradQuasiFermi_ElectricField_HFS=1.000e+12
  RefDens_hGradQuasiFermi_ElectricField_HFS=1.000e+12
  Method = Bitlis (Restart=100, Tolerance=1e-6, Iterations=200)
}}
Plot {{ eDensity hDensity TotalCurrent/Vector ElectricField/Vector Potential
  SpaceCharge ConductionBand ValenceBand Doping Polarization/Vector }}
CurrentPlot {{
  Polarization/Vector (( 0 {py:.5f} ))
  ElectricField/Vector (( 0 {py:.5f} ))
}}
Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled (Iterations=100) {{ Poisson }} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal {{ Name="drain_contact" Voltage={VDS} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_rise_"
  Transient ( InitialTime=0 FinalTime=1.0e-06 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-11 Increment=1.4
    Goal {{ Name="gate_contact" Voltage={VE} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_hold_"
  Transient ( InitialTime=1.0e-06 FinalTime=5.0e-04 InitialStep=1e-9 MaxStep=2e-5 MinStep=1e-13 Increment=1.4 ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_set_"
  Transient ( InitialTime=5.0e-04 FinalTime=5.01e-04 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-11 Increment=1.4
    Goal {{ Name="gate_contact" Voltage={VLO} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_"
  Transient ( InitialTime=5.01e-04 FinalTime=5.06e-04 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-12 Increment=1.2
    Goal {{ Name="gate_contact" Voltage={VHI} }} ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=(5.01e-04 5.06e-04) Intervals=100) ) }}
  NewCurrentPrefix="pgm_rise_"
  Transient ( InitialTime=5.06e-04 FinalTime=5.07e-04 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-11 Increment=1.4
    Goal {{ Name="gate_contact" Voltage={VP} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="pgm_hold_"
  Transient ( InitialTime=5.07e-04 FinalTime=1.007e-03 InitialStep=1e-9 MaxStep=2e-5 MinStep=1e-13 Increment=1.4 ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="pgm_set_"
  Transient ( InitialTime=1.007e-03 FinalTime=1.008e-03 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-11 Increment=1.4
    Goal {{ Name="gate_contact" Voltage={VLO} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="pgm_"
  Transient ( InitialTime=1.008e-03 FinalTime=1.013e-03 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-12 Increment=1.2
    Goal {{ Name="gate_contact" Voltage={VHI} }} ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=(1.008e-03 1.013e-03) Intervals=100) ) }}
}}
"""


def gen(mesh, py, WF=4.35, VE=-3.0, VP=2.5, VLO=-1.5, VHI=1.5, VDS=0.05):
    return T.format(mesh=mesh, py=py, WF=WF, VE=VE, VP=VP, VLO=VLO, VHI=VHI, VDS=VDS)


if __name__ == "__main__":
    c = gen("fe07", 0.007)
    assert "@" not in c and c.count("NewCurrentPrefix") == 9
    print("ivgen OK", len(c), "chars")
