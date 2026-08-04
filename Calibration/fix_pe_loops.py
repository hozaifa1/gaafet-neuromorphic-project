"""Correct the sign convention of the MFIS P-V / P-E loops and recaption them.

Two separate defects in the deck's "HZO P-E loop" figures (PLOT_PLAN C5):

1. SIGN.  The probe sits in the TOP gate stack, where the local +y axis points
   away from the channel.  Everything measured there therefore carries the
   opposite sign to the channel-directed convention every reader assumes, which
   is why the published P-V loop has a NEGATIVE slope: at V_G = +4 V the raw
   probe reads P = -3.91 uC/cm2.  Flipping both P and E puts positive gate ->
   positive polarization, and the loop reads the way a P-E loop is supposed to.

2. CAPTION.  These are not the HZO material loop.  They are MFIS loops taken
   through the whole gate stack, so the 1 nm SiO2 and the depleted silicon body
   form a capacitive divider in series with the ferroelectric.  Over the entire
   +-4 V sweep the HZO never sees more than 0.773 MV/cm = 55 % of F_c = 1.4
   MV/cm, so the ferroelectric is never driven past coercion and the loop is an
   unsaturated MINOR loop peaking at ~3.9 uC/cm2 against a P_r of 32.  Presented
   as the material loop it is a reviewer-fatal error; presented as what it is --
   a direct measurement of the divider and of how little field reaches the HZO --
   it is one of the more useful figures in the deck, because it is exactly why
   the device operates sub-coercively and why the LTP staircase is gradual.

The saturated material loop comes from the standalone MFM capacitor (RR-1,
Device_Optimization/mfmgen.py), which has metal on both sides and no divider.

Outputs (csvs/):  pe_loop_up_signed.csv, pe_loop_down_signed.csv,
                  mfis_divider_summary.txt
"""
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
CSVS = HERE / "csvs"
F_C_MV_CM = 1.4          # calibrated HZO coercive field
P_R_UC_CM2 = 32.0        # calibrated remanent polarization
T_FE_NM = 7.0


def flip(name):
    """Raw top-stack probe -> channel-directed convention (both P and E negated)."""
    d = pd.read_csv(CSVS / f"{name}.csv")
    out = pd.DataFrame({
        "Vg_V": d.Vg_V,
        "P_uC_cm2": -d.P_uC_cm2,
        "E_MV_cm": -d.E_MV_cm,
        "E_over_Fc": -d.E_MV_cm / F_C_MV_CM,
    })
    out.to_csv(CSVS / f"{name}_signed.csv", index=False, float_format="%.6g")
    return out


def main():
    up, dn = flip("pe_loop_up"), flip("pe_loop_down")
    both = pd.concat([up, dn])

    e_max = float(np.abs(both.E_MV_cm).max())
    p_max = float(np.abs(both.P_uC_cm2).max())
    # remanent values of the corrected loops: P at V_G = 0 on each branch
    pr_up = float(np.interp(0.0, up.Vg_V, up.P_uC_cm2))
    pr_dn = float(np.interp(0.0, dn.Vg_V[::-1], dn.P_uC_cm2[::-1]))

    lines = [
        "MFIS P-V / P-E loops -- corrected sign, and what they actually measure",
        "=" * 72,
        f"sweep range              +-{float(np.abs(both.Vg_V).max()):.1f} V on the gate",
        f"max |E| reaching the HZO  {e_max:.3f} MV/cm",
        f"                          = {e_max / F_C_MV_CM * 100:.1f} % of F_c = {F_C_MV_CM} MV/cm",
        f"max |P| reached           {p_max:.2f} uC/cm2",
        f"                          = {p_max / P_R_UC_CM2 * 100:.1f} % of P_r = {P_R_UC_CM2} uC/cm2",
        f"apparent P at V_G = 0     up-branch {pr_up:+.3f}, down-branch {pr_dn:+.3f} uC/cm2",
        f"                          (loop opening {abs(pr_up - pr_dn):.3f} uC/cm2)",
        "",
        "The ferroelectric is never driven past coercion anywhere in this sweep, so",
        "this is an unsaturated MINOR loop.  It is a measurement of the MFIS voltage",
        "divider -- how little of the applied gate voltage reaches the HZO once the",
        f"{T_FE_NM:.0f} nm ferroelectric is in series with the 1 nm SiO2 and the depleted",
        "silicon body -- not of the HZO material.  The material loop requires an MFM",
        "capacitor with no semiconductor in the stack: see RR-1 / mfmgen.py.",
        "",
        "CAPTION TO USE:",
        "  Retained polarization of the MFIS gate stack versus gate voltage (a) and",
        "  versus the field actually developed across the ferroelectric (b), probed",
        f"  at the mid-HZO point.  Over the full +-4 V sweep the HZO sees at most",
        f"  {e_max:.2f} MV/cm, {e_max / F_C_MV_CM * 100:.0f} % of the coercive field, so the layer",
        "  operates entirely in the sub-coercive regime and the loop is a minor loop.",
        "  This is the origin of the device's gradual, multi-level potentiation: each",
        "  programming pulse switches only a small fraction of the available dipoles.",
        "  The saturated material loop of the same HZO is Fig. C1 (MFM capacitor).",
        "",
        "Sign convention: the current-plot probe lies in the top gate stack, whose",
        "local +y points away from the channel.  Both P and E are negated here so",
        "that positive gate bias corresponds to positive polarization, i.e. the",
        "channel-directed convention.  The raw probe values are unchanged in",
        "pe_loop_{up,down}.csv; the corrected ones are in *_signed.csv.",
    ]
    txt = "\n".join(lines)
    (CSVS / "mfis_divider_summary.txt").write_text(txt)
    print(txt)

    # the whole point of the correction: positive gate must give positive P
    assert float(np.interp(3.9, up.Vg_V, up.P_uC_cm2)) > 0, "sign flip did not take"
    assert e_max < F_C_MV_CM, "loop is NOT sub-coercive -- recheck the claim above"


if __name__ == "__main__":
    main()
