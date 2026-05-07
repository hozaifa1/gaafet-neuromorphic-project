"""Phase 1C analysis: simG (C_gg), simD (tau_leak partial), simF (drift).

DF-ISE .plt parser tailored to the column layout written by Sentaurus 2023.12.
"""
from __future__ import annotations
import os, re, sys, glob
import numpy as np

ROOT = os.path.dirname(os.path.abspath(__file__))


def parse_plt(path):
    """Return (datasets:list[str], data:np.ndarray of shape (N_rows, N_cols))."""
    with open(path, "r") as f:
        txt = f.read()
    m = re.search(r"datasets\s*=\s*\[(.*?)\]", txt, re.S)
    if not m:
        raise RuntimeError(f"No datasets block in {path}")
    ds_raw = m.group(1)
    ds = re.findall(r'"([^"]+)"', ds_raw)
    n_cols = len(ds)
    # Lenient: tolerate truncated files (no closing brace) by reading from
    # "Data {" to end-of-file.
    m2 = re.search(r"Data\s*\{(.*)", txt, re.S)
    if not m2:
        raise RuntimeError(f"No Data block in {path}")
    body = m2.group(1)
    end = body.rfind("}")
    if end >= 0:
        body = body[:end]
    nums = re.findall(r"-?\d+\.\d+E[+-]\d+|-?\d+\.\d+|-?\d+", body)
    if len(nums) % n_cols != 0:
        # Sometimes leftover chars; trim trailing
        usable = (len(nums) // n_cols) * n_cols
        nums = nums[:usable]
    arr = np.array([float(x) for x in nums]).reshape(-1, n_cols)
    return ds, arr


def col(ds, name):
    for i, d in enumerate(ds):
        if d == name:
            return i
    raise KeyError(f"{name!r} not in datasets {ds}")


# ============================================================
# simG — C_gg(VGS) extraction
# ============================================================
def analyze_simG():
    print("=" * 70)
    print("simG — Gate capacitance C_gg(VGS) at 1 MHz")
    print("=" * 70)
    out_dir = os.path.join(ROOT, "simG_capacitance", "outputs")
    f_v = os.path.join(out_dir, "cv_virgin_n2_ac_des.plt")
    f_p = os.path.join(out_dir, "cv_postfire_n2_ac_des.plt")

    results = {}
    for label, path in [("virgin", f_v), ("postfire", f_p)]:
        ds, arr = parse_plt(path)
        i_vg  = col(ds, "v(g)")
        i_cgg = col(ds, "c(g,g)")
        vgs = arr[:, i_vg]
        cgg = arr[:, i_cgg]
        results[label] = (vgs, cgg)
        print(f"\n[{label}]  rows={len(vgs)}  VGS range=[{vgs.min():.3f}, {vgs.max():.3f}] V")
        print(f"  C_gg min = {cgg.min()*1e15:.4f} fF  ({cgg.min()*1e18:.2f} aF)")
        print(f"  C_gg max = {cgg.max()*1e15:.4f} fF  ({cgg.max()*1e18:.2f} aF)")
        # Vth via dC/dV peak
        if len(vgs) >= 5:
            order = np.argsort(vgs)
            v_s, c_s = vgs[order], cgg[order]
            dcdv = np.gradient(c_s, v_s)
            vth_proxy = float(v_s[int(np.argmax(dcdv))])
            print(f"  V at max dC/dV (Vth proxy) = {vth_proxy:+.3f} V")

    vgs_v, c_v = results["virgin"]
    vgs_p, c_p = results["postfire"]
    c_v_peak = float(c_v.max())
    c_p_peak = float(c_p.max())

    R_total = 7830.0  # R_h+R_s from Step 2 v1 (5250+2580)
    tau_native_v = R_total * c_v_peak
    tau_native_p = R_total * c_p_peak
    print("\n--- Headline numbers ---")
    print(f"  Peak C_gg (virgin)   = {c_v_peak*1e15:.3f} fF")
    print(f"  Peak C_gg (postfire) = {c_p_peak*1e15:.3f} fF")
    print(f"  Delta peak C_gg      = {(c_p_peak-c_v_peak)*1e15:+.3f} fF")
    print(f"  R_total*C_gg_peak (virgin)   = {tau_native_v*1e9:.4f} ns  (natural tau)")
    print(f"  R_total*C_gg_peak (postfire) = {tau_native_p*1e9:.4f} ns")
    print(f"  Step 2 v1 C_mem = 1.419 uF -> ratio C_mem/C_gg = {1.419e-6/c_v_peak:.2e}")
    return results


# ============================================================
# simD — tau_leak from leak_monitor (partial run, tau_P=1e-6)
# ============================================================
def analyze_simD_leak():
    print("\n" + "=" * 70)
    print("simD — Leak monitor (tau_P = 1e-6 s, partial run)")
    print("=" * 70)
    path = os.path.join(ROOT, "simD_leak", "output_taup_1e-6", "leak_monitor_n2_des.plt")
    ds, arr = parse_plt(path)
    i_t  = col(ds, "time")
    i_id = col(ds, "drain_contact TotalCurrent")
    i_vg = col(ds, "gate_contact OuterVoltage")
    t  = arr[:, i_t]
    id_ = arr[:, i_id]
    vg = arr[:, i_vg]
    print(f"  rows={len(t)}  t range=[{t[0]:.3e}, {t[-1]:.3e}] s")
    print(f"  Vg held at: {vg[0]:.3f} -> {vg[-1]:.3f} V (read level)")
    print(f"  ID(t0) = {id_[0]*1e6:+.4f} uA  (post-fire current at start of leak window)")
    print(f"  ID(t_end) = {id_[-1]*1e6:+.4f} uA  (asymptote ID_inf)")

    # Fit ID(t) = ID_inf + A * exp(-(t-t0)/tau)
    t0 = t[0]
    tt = t - t0
    # Two-parameter linear fit on log(ID-ID_inf) using late-time average as ID_inf estimate
    id_inf = float(np.mean(id_[-max(5, len(id_)//20):]))
    delta = id_ - id_inf
    # Restrict to early-time decay where delta has consistent sign and magnitude well above noise
    sign = 1 if delta[0] > 0 else -1
    mask = (sign * delta > abs(delta[0]) * 0.01) & (tt > 0)
    if mask.sum() < 5:
        print("  WARN: not enough decay points to fit reliably.")
        tau_fit = float("nan")
    else:
        y = np.log(np.abs(delta[mask]))
        x = tt[mask]
        slope, intercept = np.polyfit(x, y, 1)
        tau_fit = -1.0 / slope
        A0 = float(np.exp(intercept) * sign)
        print(f"  Exponential fit:  ID_inf = {id_inf*1e6:+.4f} uA, A = {A0*1e6:+.4f} uA")
        print(f"  tau_leak (fitted) = {tau_fit*1e9:.3f} ns  ({tau_fit*1e6:.4f} us)")
    print(f"  Sanity: tau_P (input) was 1e-6 s = 1000 ns")
    return tau_fit


# ============================================================
# simF — per-cycle drift across c01..c05
# ============================================================
def analyze_simF():
    print("\n" + "=" * 70)
    print("simF — Multi-cycle endurance (5 cycles, tau_P=1e-6)")
    print("=" * 70)
    out_dir = os.path.join(ROOT, "simF_endurance", "tau_p_just_taken_1e-6")

    def steady_id(path):
        """Return mean drain TotalCurrent over latter half of the read window."""
        ds, arr = parse_plt(path)
        i_id = col(ds, "drain_contact TotalCurrent")
        i_t  = col(ds, "time")
        t = arr[:, i_t]
        id_ = arr[:, i_id]
        # latter 50% as steady-state
        n = len(t) // 2
        return float(np.mean(id_[n:]))

    rows = []
    for c in range(1, 6):
        f_pre = os.path.join(out_dir, f"c{c:02d}_basepre_read_n2_des.plt")
        f_p9  = os.path.join(out_dir, f"c{c:02d}_p09_read_n2_des.plt")
        f_post= os.path.join(out_dir, f"c{c:02d}_postreset_read_n2_des.plt")
        id_pre  = steady_id(f_pre)
        id_p9   = steady_id(f_p9)
        id_post = steady_id(f_post)
        ratio = id_p9 / id_pre if id_pre != 0 else float("nan")
        rows.append((c, id_pre, id_p9, id_post, ratio))
        print(f"  cycle {c}: ID_pre={id_pre*1e6:+.4f} uA  ID_p9={id_p9*1e6:+.4f} uA  "
              f"ID_post={id_post*1e6:+.4f} uA  fire_ratio={ratio:.3f}")

    cs = np.array([r[0] for r in rows], dtype=float)
    pre = np.array([r[1] for r in rows])
    p9  = np.array([r[2] for r in rows])
    post= np.array([r[3] for r in rows])

    def slope(y):
        return float(np.polyfit(cs, y, 1)[0])

    print("\n--- Per-cycle drift slopes (per cycle) ---")
    print(f"  d ID_pre  / dcycle  = {slope(pre)*1e6:+.5f} uA/cycle  ({slope(pre)/pre[0]*100:+.3f} %/cycle)")
    print(f"  d ID_p9   / dcycle  = {slope(p9)*1e6:+.5f} uA/cycle  ({slope(p9)/p9[0]*100:+.3f} %/cycle)")
    print(f"  d ID_post / dcycle  = {slope(post)*1e6:+.5f} uA/cycle  ({slope(post)/post[0]*100:+.3f} %/cycle)")
    print(f"  ID_post / ID_pre    : c1={post[0]/pre[0]:.3f}  c5={post[-1]/pre[-1]:.3f}  "
          f"(reset completeness)")

    # Total drift across 5 cycles (relative)
    print(f"\n  Drift c1->c5:  ID_pre  {(pre[-1]-pre[0])/pre[0]*100:+.3f}%  "
          f"ID_p9 {(p9[-1]-p9[0])/p9[0]*100:+.3f}%  "
          f"ID_post {(post[-1]-post[0])/post[0]*100:+.3f}%")


if __name__ == "__main__":
    analyze_simG()
    try:
        analyze_simD_leak()
    except Exception as e:
        print(f"simD analysis failed: {e}")
    try:
        analyze_simF()
    except Exception as e:
        print(f"simF analysis failed: {e}")
