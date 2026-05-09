"""Phase 1C full analysis: simD (4 tau_P nodes), simF (5 cycles), simG (CV).

Reuses parse_plt from analyze_phase1c.py."""
from __future__ import annotations
import os, re, sys, glob
import numpy as np

ROOT = os.path.dirname(os.path.abspath(__file__))


def parse_plt(path):
    with open(path, "r") as f:
        txt = f.read()
    m = re.search(r"datasets\s*=\s*\[(.*?)\]", txt, re.S)
    if not m:
        raise RuntimeError(f"No datasets block in {path}")
    ds_raw = m.group(1)
    ds = re.findall(r'"([^"]+)"', ds_raw)
    n_cols = len(ds)
    m2 = re.search(r"Data\s*\{(.*)", txt, re.S)
    if not m2:
        raise RuntimeError(f"No Data block in {path}")
    body = m2.group(1)
    end = body.rfind("}")
    if end >= 0:
        body = body[:end]
    nums = re.findall(r"-?\d+\.\d+E[+-]\d+|-?\d+\.\d+|-?\d+", body)
    if len(nums) % n_cols != 0:
        usable = (len(nums) // n_cols) * n_cols
        nums = nums[:usable]
    arr = np.array([float(x) for x in nums]).reshape(-1, n_cols)
    return ds, arr


def col(ds, name):
    for i, d in enumerate(ds):
        if d == name:
            return i
    raise KeyError(f"{name!r} not in datasets {ds}")


def steady_id(path, frac=0.5):
    ds, arr = parse_plt(path)
    i_id = col(ds, "drain_contact TotalCurrent")
    id_ = arr[:, i_id]
    n = int(len(id_) * (1 - frac))
    return float(np.mean(id_[n:]))


def fit_exp_decay(t, y):
    """Fit y(t) = y_inf + A*exp(-(t-t0)/tau).
    Returns (tau, y_inf, A, mask_count)."""
    t0 = t[0]
    tt = t - t0
    y_inf = float(np.mean(y[-max(5, len(y) // 20):]))
    delta = y - y_inf
    sign = 1 if delta[0] > 0 else -1
    mask = (sign * delta > abs(delta[0]) * 0.01) & (tt > 0)
    if mask.sum() < 5:
        return float("nan"), y_inf, float("nan"), int(mask.sum())
    yy = np.log(np.abs(delta[mask]))
    xx = tt[mask]
    slope, intercept = np.polyfit(xx, yy, 1)
    tau = -1.0 / slope
    A = float(np.exp(intercept) * sign)
    return float(tau), float(y_inf), A, int(mask.sum())


# ============================================================
# simG
# ============================================================
def analyze_simG():
    print("=" * 70)
    print("simG  Gate capacitance C_gg(VGS) at 1 MHz")
    print("=" * 70)
    out_dir = os.path.join(ROOT, "simG_capacitance", "outputs")
    f_v = os.path.join(out_dir, "cv_virgin_n2_ac_des.plt")
    f_p = os.path.join(out_dir, "cv_postfire_n2_ac_des.plt")

    results = {}
    for label, path in [("virgin", f_v), ("postfire", f_p)]:
        ds, arr = parse_plt(path)
        i_vg = col(ds, "v(g)")
        i_cgg = col(ds, "c(g,g)")
        vgs = arr[:, i_vg]
        cgg = arr[:, i_cgg]
        results[label] = (vgs, cgg)
        print(f"\n[{label}] rows={len(vgs)}  VGS=[{vgs.min():.3f},{vgs.max():.3f}] V")
        print(f"  C_gg min={cgg.min()*1e15:.4f} fF  max={cgg.max()*1e15:.4f} fF")
        # midpoint Vth proxy
        order = np.argsort(vgs)
        v_s = vgs[order]; c_s = cgg[order]
        c_mid = 0.5 * (c_s.max() + c_s.min())
        idx = int(np.argmin(np.abs(c_s - c_mid)))
        print(f"  Vth_proxy (C=mid) = {v_s[idx]:+.3f} V")

    return results


# ============================================================
# simD - all 4 tau_P nodes
# ============================================================
def analyze_simD_all():
    print("\n" + "=" * 70)
    print("simD  Leak (tau_P sweep)")
    print("=" * 70)
    nodes = ["1e-6", "1e-5", "1e-4", "1e-3"]
    results = {}
    print(f"\n{'tau_P':<8} {'rows':>5} {'t_window(us)':>12} {'ID(t0) uA':>11} {'ID_inf uA':>11} {'A uA':>9} {'tau_leak':>15} {'fit pts':>8}")
    print("-" * 90)
    for n in nodes:
        path = os.path.join(ROOT, "simD_leak", f"output_taup_{n}", "leak_monitor_n2_des.plt")
        if not os.path.exists(path):
            print(f"{n:<8} MISSING")
            continue
        ds, arr = parse_plt(path)
        t = arr[:, col(ds, "time")]
        id_ = arr[:, col(ds, "drain_contact TotalCurrent")]
        tau, y_inf, A, mc = fit_exp_decay(t, id_)
        tau_str = f"{tau*1e9:.2f} ns" if not np.isnan(tau) else "fit-FAIL"
        print(f"{n:<8} {len(t):>5} {(t[-1]-t[0])*1e6:>12.1f} "
              f"{id_[0]*1e6:>11.4f} {y_inf*1e6:>11.4f} {A*1e6:>9.4f} "
              f"{tau_str:>15} {mc:>8}")
        results[n] = (tau, y_inf, A, t, id_)

    print("\nInterpretation note:")
    print("  tau_P (input) = polarization relaxation time set in the Polarization block.")
    print("  tau_leak (fitted) = ID(t) decay constant in the read window.")
    print("  Expectation: tau_leak ~ tau_P (the FE relaxation drives the ID decay),")
    print("  but the dID/dP -> dID/dV mapping can stretch/shrink the visible decay.")
    return results


# ============================================================
# simF - actually ran with tau_P=0 (per par file bug)
# ============================================================
def analyze_simF():
    print("\n" + "=" * 70)
    print("simF  Multi-cycle endurance (5 cycles, tau_P=??)")
    print("=" * 70)
    # detect actual folder
    candidates = [
        os.path.join(ROOT, "simF_endurance", "tau_p_selected_1e-5"),
        os.path.join(ROOT, "simF_endurance", "tau_p_just_taken_0"),
        os.path.join(ROOT, "simF_endurance", "tau_p_just_taken_1e-6"),
    ]
    out_dir = next((d for d in candidates if os.path.isdir(d)), None)
    if out_dir is None:
        print("  no simF output dir found")
        return None
    print(f"  source: {os.path.basename(out_dir)}")

    rows = []
    for c in range(1, 6):
        f_pre = os.path.join(out_dir, f"c{c:02d}_basepre_read_n2_des.plt")
        f_p9 = os.path.join(out_dir, f"c{c:02d}_p09_read_n2_des.plt")
        f_post = os.path.join(out_dir, f"c{c:02d}_postreset_read_n2_des.plt")
        if not (os.path.exists(f_pre) and os.path.exists(f_p9) and os.path.exists(f_post)):
            print(f"  cycle {c}: MISSING (skipping)")
            continue
        id_pre = steady_id(f_pre)
        id_p9 = steady_id(f_p9)
        id_post = steady_id(f_post)
        ratio = id_p9 / id_pre if id_pre != 0 else float("nan")
        rows.append((c, id_pre, id_p9, id_post, ratio))
        print(f"  cycle {c}: ID_pre={id_pre*1e6:+.4f} ID_p9={id_p9*1e6:+.4f} "
              f"ID_post={id_post*1e6:+.4f} fire_ratio={ratio:.3f} "
              f"reset%={id_post/id_pre*100:.1f}")
    if not rows:
        print("  No usable cycles.")
        return

    cs = np.array([r[0] for r in rows], dtype=float)
    pre = np.array([r[1] for r in rows])
    p9 = np.array([r[2] for r in rows])
    post = np.array([r[3] for r in rows])
    rat = np.array([r[4] for r in rows])

    def slope(y):
        return float(np.polyfit(cs, y, 1)[0])

    print("\nDrift slopes (full c1->c5):")
    print(f"  ID_pre  : {slope(pre)*1e6:+.5f} uA/cycle ({slope(pre)/pre[0]*100:+.3f} %/cycle base)")
    print(f"  ID_p9   : {slope(p9)*1e6:+.5f} uA/cycle ({slope(p9)/p9[0]*100:+.3f} %/cycle base)")
    print(f"  ID_post : {slope(post)*1e6:+.5f} uA/cycle ({slope(post)/post[0]*100:+.3f} %/cycle base)")
    print(f"\nDrift slopes (post-break-in c2->c5):")
    if len(cs) >= 4:
        cs2 = cs[1:]; pre2 = pre[1:]; p92 = p9[1:]; post2 = post[1:]
        sp_pre = float(np.polyfit(cs2, pre2, 1)[0])
        sp_p9 = float(np.polyfit(cs2, p92, 1)[0])
        sp_post = float(np.polyfit(cs2, post2, 1)[0])
        print(f"  ID_pre  : {sp_pre*1e6:+.5f} uA/cycle ({sp_pre/pre2[0]*100:+.3f} %/cycle)")
        print(f"  ID_p9   : {sp_p9*1e6:+.5f} uA/cycle ({sp_p9/p92[0]*100:+.3f} %/cycle)")
        print(f"  ID_post : {sp_post*1e6:+.5f} uA/cycle ({sp_post/post2[0]*100:+.3f} %/cycle)")
    print(f"\n  Total c1->c5 drift: ID_pre {(pre[-1]-pre[0])/pre[0]*100:+.2f}%  "
          f"ID_p9 {(p9[-1]-p9[0])/p9[0]*100:+.2f}%  "
          f"ID_post {(post[-1]-post[0])/post[0]*100:+.2f}%")
    print(f"  Reset completeness (ID_post/ID_pre): c1={post[0]/pre[0]:.3f}  c5={post[-1]/pre[-1]:.3f}")


if __name__ == "__main__":
    analyze_simG()
    try:
        analyze_simD_all()
    except Exception as e:
        import traceback; traceback.print_exc()
    try:
        analyze_simF()
    except Exception as e:
        import traceback; traceback.print_exc()
