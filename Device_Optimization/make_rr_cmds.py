"""Render every PLOT_PLAN re-run .cmd into runs/, in priority order.

  python make_rr_cmds.py          render all, print the queue order
  python make_rr_cmds.py --list   print the queue order only

Priority follows PLOT_PLAN Part IV: (reviewer value) / (sim cost).  The host has
one shared sdevice license, so queue_worker.sh runs them strictly in this order
and whatever does not finish is reported as not finished.
"""
import sys
from pathlib import Path

import ltdgen
import lifgen
import mfmgen
import rrgen

HERE = Path(__file__).resolve().parent
RUNS = HERE / "runs"
MESH = "fe07_msh.tdr"
PAR = "app_iv_fe07b.par"          # app.par rendered with TAU_P=1e-5
PROBEY = "0.00700"

# Dit / FixedCharge live in the .cmd Traps block, not in the .par, so the
# variability ensemble perturbs the rendered text.
DIT_NOM, FIXQ_NOM = "4e12", "7e12"


def _perturb(cmd, dit=None, fixq=None):
    if dit is not None:
        cmd = cmd.replace(f"Conc={DIT_NOM} EnergyMid=0.45", f"Conc={dit:.4g} EnergyMid=0.45")
        assert f"{dit:.4g}" in cmd
    if fixq is not None:
        cmd = cmd.replace(f"FixedCharge Conc={FIXQ_NOM}", f"FixedCharge Conc={fixq:.4g}")
        assert f"{fixq:.4g}" in cmd
    return cmd


def build():
    jobs = []       # (node, cmd_text, note)

    # ---- RR-1 MFM P-E loops (the reviewer-fatal defect) --------------------
    for vm, node in ((1.96, "mfm_pe196"), (3.0, "mfm_pe300")):
        jobs.append((node, mfmgen.gen(vm, node, par=PAR), f"RR-1 MFM P-E +-{vm} V"))

    # ---- RR-6 2D maps ------------------------------------------------------
    jobs.append(("t13_tdr", rrgen.tdr_states(node="t13_tdr", tdr=MESH, par=PAR,
                                             PROBEY=PROBEY), "RR-6 erased/programmed .tdr"))

    # ---- RR-2 output characteristics + DIBL --------------------------------
    jobs.append(("t11_idvd", rrgen.idvd(node="t11_idvd", tdr=MESH, par=PAR,
                                        PROBEY=PROBEY), "RR-2 I_D-V_DS family"))
    jobs.append(("t11_dibl", rrgen.dibl(node="t11_dibl", tdr=MESH, par=PAR,
                                        PROBEY=PROBEY), "RR-2 DIBL, two V_DS"))

    # ---- RR-3 LTD and the symmetric loop -----------------------------------
    jobs.append(("t10_ltd", ltdgen.gen_ltd(MESH, PAR, "t10_ltd", PROBEY=PROBEY),
                 "RR-3 15 LTP + 15 LTD, 1 us pulses"))
    jobs.append(("t10_cyc", ltdgen.gen_cycles(MESH, PAR, "t10_cyc", n_cycles=3,
                                              PROBEY=PROBEY),
                 "RR-3 3 x (15 LTP + 15 LTD)"))

    # ---- RR-4 retention ----------------------------------------------------
    jobs.append(("t12_ret", rrgen.retention(node="t12_ret", tdr=MESH, par=PAR,
                                            PROBEY=PROBEY),
                 "RR-4 programmed, 10 ms, 300 K"))
    jobs.append(("t12_ret400", rrgen.retention(node="t12_ret400", tdr=MESH, par=PAR,
                                               PROBEY=PROBEY, TEMP=400),
                 "RR-4 programmed, 10 ms, 400 K"))
    jobs.append(("t12_ret_l8", rrgen.retention(node="t12_ret_l8", n_pulse=8, t_max=1e-3,
                                               tdr=MESH, par=PAR, PROBEY=PROBEY),
                 "RR-4 LTP level 8, 1 ms, 300 K"))
    jobs.append(("t12_ret15", rrgen.ret_levels(node="t12_ret15", tdr=MESH, par=PAR,
                                               PROBEY=PROBEY),
                 "RR-4 all 15 levels, 1 ms each"))

    # ---- RR-7 programming design space, 5 x 5 ------------------------------
    for vp in (1.0, 1.5, 2.0, 2.5, 3.0):
        for tp_ns in (10, 30, 100, 300, 1000):
            node = f"g_v{int(vp * 10):03d}_t{tp_ns:04d}"
            cmd = lifgen.gen(MESH, PAR, node, 4.35, 0.0, vp, PROBEY, N=9,
                             t_p=tp_ns * 1e-9, t_read=100e-9,
                             V_erase=-2.0, t_erase=5e-6)
            jobs.append((node, cmd, f"RR-7 V_pgm={vp} V, t_p={tp_ns} ns"))

    # ---- RR-9 read disturb -------------------------------------------------
    jobs.append(("t15_disturb", rrgen.disturb(node="t15_disturb", tdr=MESH, par=PAR,
                                              PROBEY=PROBEY),
                 "RR-9 1e6-read equivalent (100 ms bias)"))

    # ---- RR-5 endurance ----------------------------------------------------
    for n in (10, 100, 1000):
        node = f"t14_end{n}"
        jobs.append((node, rrgen.endurance(node=node, n_cycles=n, tdr=MESH, par=PAR,
                                           PROBEY=PROBEY),
                     f"RR-5 {n} program/erase cycles"))

    # ---- RR-8 variability ensemble, 20 runs --------------------------------
    # Dit +-20 %, FixedCharge +-10 %, T_fe +-0.3 nm.  T_fe needs its own mesh, so
    # the T_fe axis uses the fe067 / fe073 meshes built alongside fe07.
    import itertools
    dits = [3.2e12, 4.0e12, 4.8e12]
    fixqs = [6.3e12, 7.0e12, 7.7e12]
    meshes = [("fe067_msh.tdr", "0.00670"), (MESH, PROBEY), ("fe073_msh.tdr", "0.00730")]
    combos = [c for c in itertools.product(range(3), repeat=3) if c != (1, 1, 1)]
    # 26 off-nominal corners; take a spread of 20 (drop the 6 that vary one axis
    # by one step only, which the sweeps already cover)
    combos = [c for c in combos if sum(1 for x in c if x != 1) >= 2][:20]
    for i, (di, fi, mi) in enumerate(combos, start=1):
        node = f"v_{i:02d}"
        mesh_i, probe_i = meshes[mi]
        cmd = lifgen.gen(mesh_i, PAR, node, 4.35, 0.0, 2.0, probe_i, N=15,
                         t_p=1e-6, t_read=100e-9, V_erase=-2.0, t_erase=5e-6)
        cmd = _perturb(cmd, dit=dits[di], fixq=fixqs[fi])
        jobs.append((node, cmd, f"RR-8 Dit={dits[di]:.1e} Q_f={fixqs[fi]:.1e} "
                                f"mesh={mesh_i.split('_')[0]}"))

    # ---- RR-10 Areafactor sanity ------------------------------------------
    # One node re-run at the geometrically correct Areafactor.  Every current in
    # it must equal the 0.071 run times 0.045/0.071 to machine precision, which
    # is the whole basis of the Phase 1 post-hoc rescale.
    import norm
    cmd = rrgen.tdr_states(node="t16_af045", tdr=MESH, par=PAR, PROBEY=PROBEY)
    cmd = cmd.replace(f"Areafactor= {norm.AREAFACTOR_USED}",
                      f"Areafactor= {norm.AREAFACTOR_CORRECT}")
    assert f"Areafactor= {norm.AREAFACTOR_CORRECT}" in cmd
    jobs.append(("t16_af045", cmd, "RR-10 same run at Areafactor=0.045"))

    return jobs


def main():
    jobs = build()
    if "--list" not in sys.argv:
        RUNS.mkdir(exist_ok=True)
        for node, cmd, _ in jobs:
            assert "@" not in cmd, f"{node}: stray @"
            (RUNS / f"{node}_des.cmd").write_text(cmd)
    total = sum(len(c) for _, c, _ in jobs)
    for i, (node, cmd, note) in enumerate(jobs, 1):
        print(f"{i:3d}. {node:14s} {len(cmd):8d} ch  {note}")
    print(f"\n{len(jobs)} jobs, {total / 1e6:.2f} MB of .cmd")
    print("\nqueue order:\n" + " ".join(n for n, _, _ in jobs))


if __name__ == "__main__":
    main()
