"""THE single width-normalization convention for the GAA-FeFET project.

No other file in this repository may define a width, an Areafactor, or a
current-normalization factor. Import from here.

--------------------------------------------------------------------------
THE CONVENTION (PLOT_PLAN.md Part I, option (a))
--------------------------------------------------------------------------
Currents are reported **per micron of gate perimeter**, with

    W_eff = TESW = 2*(W + T_si) = 2*(40 + 5) nm = 90 nm = 0.090 um

for the nominal optimized nanosheet (W = 40 nm, T_si = 5 nm).

Why the numbers below are what they are
---------------------------------------
Sentaurus solves the 2D cross-section per unit z-depth.  `Areafactor = A`
declares "this 2D slab is A um deep in z", so the .plt contact currents and
charges are  I_plt = I_2D * A.  It is a pure post-multiplier -- it never
enters the Poisson/continuity solve -- so any error in A is an exact
post-processing rescale, never a re-run.

The simulated slab is **double-gated** (sde_opt.cmd builds insulator/
ferroelectric/gate_metal on both the _top and _bottom faces, both bound to
gate_contact).  A slab of depth A therefore carries a total gate width 2A.
Matching the real nanosheet perimeter:  2A = 0.090  ->  A = 0.045 um.

Every run in this project was executed with `Areafactor = 0.071`, a leftover
from the first (superseded) calibration campaign, and every analysis script
then divided by 0.090.  So every published number is

    reported_old = I_plt * 1e6 / 0.090 = (0.071/0.090) * I_2D * 1e6
                 = 0.7889 * I_2D[uA/um]

while the correct value under this convention is I_2D/2.  Hence CORR below.

What this does and does not touch
---------------------------------
CHANGES: every absolute current, conductance, resistance, contact charge and
         energy number in the project.
UNCHANGED: every ratio (ON/OFF window, igain, DR), every voltage (V_t, MW,
         V_op), SS, and every polarization / electric-field quantity --
         Areafactor scales contact quantities only, never the field solve.

HONEST CAVEAT that must appear in the paper: the absolute current level was
never calibrated against experiment.  The Liao-2022 overlay applies a freely
fitted width scalar (autocal/pub_figure.py:42), which absorbs any constant
normalization error.  The paper may claim a calibrated memory window, V_t,
SS, on/off ratio and turn-on shape.  It may NOT claim that the absolute
uA/um is experimentally validated.
"""

# --- the four constants -------------------------------------------------
AREAFACTOR_USED = 0.071      # what every .cmd in this repo actually ran with
AREAFACTOR_CORRECT = 0.045   # W_eff/2, the geometrically correct value
W_EFF_UM = 0.090             # TESW = 2*(W + T_si) for W=40 nm, T_si=5 nm
CORR = AREAFACTOR_CORRECT / AREAFACTOR_USED   # 0.6338 -- the one rescale

# nominal nanosheet geometry the convention is built on
W_SHEET_NM = 40.0
T_SI_NOMINAL_NM = 5.0

# Planar ablation comparison (Planar_Device_Work/).  The planar deck runs with
# Areafactor = 1.0, i.e. its .plt current is already "per um of (single) gate
# width".  Once the GAA CSVs are regenerated under the convention above they are
# "per um of gate perimeter" -- the same physical normalization.  So no further
# factor is applied to the GAA CSVs when comparing.  (Before this module existed,
# Planar_Device_Work multiplied them by 0.090/0.071 = 1.2676 to reach convention
# (b), per um of z-depth; that is now obsolete.)
CORR_PLANAR_COMPARE = 1.0


def to_uA_per_um(I_amps):
    """Raw .plt contact current (A, carries Areafactor=0.071) -> uA/um of gate perimeter."""
    return I_amps * 1e6 / W_EFF_UM * CORR


def to_device_amps(I_amps):
    """Raw .plt contact current (A) -> true single-nanosheet current (A).

    Also the correct conversion for a .plt contact *charge* (C): both are
    scaled by Areafactor identically.
    """
    return I_amps * AREAFACTOR_CORRECT / AREAFACTOR_USED


def rescale_legacy(x_old):
    """Any already-published uA/um, A, C or J number (0.071-cmd / 0.090-py) -> corrected."""
    return x_old * CORR


def rescale_legacy_resistance(r_old):
    """Published resistance (ohm) -> corrected. Resistances take the reciprocal factor."""
    return r_old / CORR


def w_eff_um(t_si_nm, w_sheet_nm=W_SHEET_NM):
    """TESW = 2*(W + T_si) in um, for the geometry sweeps where T_si is not 5 nm.

    Areafactor was held at 0.071 across the whole T_si sweep (5..15 nm), so the
    true perimeter runs 90 -> 110 nm, a 22 % spread the constant factor does not
    capture.  Ratio metrics (window, DR, igain) cancel it; absolute uA/um does not.
    """
    return 2.0 * (w_sheet_nm + t_si_nm) * 1e-3


def to_uA_per_um_tesw(I_amps, t_si_nm):
    """Per-um normalization using that device's own TESW instead of the nominal 90 nm."""
    return I_amps * AREAFACTOR_CORRECT / AREAFACTOR_USED * 1e6 / w_eff_um(t_si_nm)


def _selftest():
    assert abs(CORR - 0.6338028169) < 1e-9, CORR
    assert round(CORR, 3) == 0.634

    # The headline rescale from PLOT_PLAN.md Part I.4.
    assert abs(rescale_legacy(29.5) - 18.7) < 0.05, rescale_legacy(29.5)
    assert abs(rescale_legacy(9.407e-3) - 5.96e-3) < 1e-5
    assert abs(rescale_legacy(13.1) - 8.31) < 0.01
    assert abs(rescale_legacy(1.007e-3) - 6.39e-4) < 1e-6

    # to_uA_per_um must equal to_device_amps normalized by the perimeter.
    i = 2.656e-06
    assert abs(to_uA_per_um(i) - to_device_amps(i) * 1e6 / W_EFF_UM) < 1e-12

    # The legacy pipeline was I*1e6/0.090; the new one must be exactly CORR times it.
    assert abs(to_uA_per_um(i) - (i * 1e6 / 0.090) * CORR) < 1e-12

    # Resistance goes the other way.
    assert abs(rescale_legacy_resistance(2.34e6) - 3.69e6) / 3.69e6 < 0.01
    assert abs(rescale_legacy_resistance(7.14e7) - 1.13e8) / 1.13e8 < 0.01

    # Nominal geometry must reproduce W_EFF_UM.
    assert abs(w_eff_um(T_SI_NOMINAL_NM) - W_EFF_UM) < 1e-12
    assert abs(w_eff_um(15.0) - 0.110) < 1e-12

    print(f"norm.py OK  CORR={CORR:.6f}  W_eff={W_EFF_UM*1e3:.0f} nm  "
          f"(Areafactor {AREAFACTOR_USED} -> {AREAFACTOR_CORRECT})")
    print(f"  29.5 uA/um (published) -> {rescale_legacy(29.5):.4g} uA/um")
    print(f"  9.407e-3   (published) -> {rescale_legacy(9.407e-3):.4g} uA/um")


if __name__ == "__main__":
    _selftest()
