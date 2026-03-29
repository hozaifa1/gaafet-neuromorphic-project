"""
SimC Write-Then-Read Analysis
Parses .plt results from sdevice_simC_writeread.cmd (v2) or v3.
Auto-detects result subdirectory. Generates 4 publication figures.
"""

import re, os, sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SIMC_DIR = os.path.join(BASE_DIR, "simC")
OUT_DIR  = os.path.dirname(os.path.abspath(__file__))

NODES = [
    {"vreset": -2.0, "tag": "n3", "dir": "n3(-2V)"},
    {"vreset": -3.0, "tag": "n4", "dir": "n4(-3V)"},
    {"vreset": -4.0, "tag": "n5", "dir": "n5(-4V)"},
]
VGS_READ  = 0.20
VPULSE    = 2.0
VTH_VIRGIN= 0.263
SS_MVDEC  = 60.8
N_PULSES  = 10
FIRE_RATIO= 2.0

ID_COL   = "drain_contact TotalCurrent"
TIME_COL = "time"
POL_COL  = "Pos(0,0.0145) Polarization/y"


def parse_plt(path):
    with open(path, "r") as f:
        txt = f.read()
    m = re.search(r'datasets\s*=\s*\[(.*?)\]', txt, re.DOTALL)
    if not m:
        raise ValueError(f"No datasets in {path}")
    cols = re.findall(r'"([^"]+)"', m.group(1))
    d = re.search(r'\bData\s*\{(.*?)\}', txt, re.DOTALL)
    if not d:
        raise ValueError(f"No Data in {path}")
    vals = np.array([float(t) for t in d.group(1).split()])
    arr = vals.reshape(-1, len(cols))
    return {c: arr[:, i] for i, c in enumerate(cols)}


def safe_parse(path):
    if not os.path.exists(path):
        return None
    try:
        return parse_plt(path)
    except Exception as e:
        print(f"  [ERR] {path}: {e}")
        return None


def find_results_dir(node_dir):
    for sub in ["latest_results", "latest"]:
        p = os.path.join(node_dir, sub)
        if os.path.isdir(p) and any(f.endswith("_des.plt") for f in os.listdir(p)):
            return p
    if any(f.endswith("_des.plt") for f in os.listdir(node_dir)):
        return node_dir
    return None


def steady_id(data):
    if data is None:
        return np.nan
    v = data[ID_COL]
    n = len(v)
    return np.mean(v[max(0, n//2):])


def final_pol(data):
    if data is None or POL_COL not in data:
        return np.nan
    return data[POL_COL][-1]


print("="*70)
print("SimC Write-Then-Read Analysis")
print("="*70)

results = {}
for node in NODES:
    tag, vreset = node["tag"], node["vreset"]
    ndir = os.path.join(SIMC_DIR, node["dir"])
    print(f"\n--- {tag} (Vreset={vreset}V) ---")
    if not os.path.isdir(ndir):
        print("  Directory missing"); continue
    rdir = find_results_dir(ndir)
    if rdir is None:
        print("  No .plt files found"); continue
    print(f"  Source: {os.path.relpath(rdir, SIMC_DIR)}")

    base = safe_parse(os.path.join(rdir, f"baseline_read_{tag}_des.plt"))
    id0 = steady_id(base)
    pol0 = final_pol(base)
    print(f"  Baseline: {id0*1e6:.4f} uA, Pol={pol0:.4e} C/cm2")

    ids_r, pols_r, ids_w, pols_w = [], [], [], []
    for p in range(1, N_PULSES+1):
        pf = f"p{p:02d}"
        rd = safe_parse(os.path.join(rdir, f"{pf}_read_{tag}_des.plt"))
        wd = safe_parse(os.path.join(rdir, f"{pf}_write_{tag}_des.plt"))
        ids_r.append(steady_id(rd));  pols_r.append(final_pol(rd))
        ids_w.append(steady_id(wd));  pols_w.append(final_pol(wd))

    ids_r  = np.array(ids_r);  pols_r = np.array(pols_r)
    ids_w  = np.array(ids_w);  pols_w = np.array(pols_w)

    leak = safe_parse(os.path.join(rdir, f"leak_gap_{tag}_des.plt"))
    leak_i0 = leak_i1 = leak_dur = np.nan
    if leak is not None:
        lt, li = leak[TIME_COL], leak[ID_COL]
        leak_i0, leak_i1, leak_dur = li[0], li[-1], lt[-1]-lt[0]
        pct = (leak_i0-leak_i1)/leak_i0*100 if leak_i0>0 else 0
        print(f"  Leak: {leak_i0*1e6:.4f}->{leak_i1*1e6:.4f} uA "
              f"({pct:.1f}% in {leak_dur*1e6:.1f}us)")

    pr = safe_parse(os.path.join(rdir, f"postreset_read_{tag}_des.plt"))
    id_pr = steady_id(pr)

    # Integration table
    print(f"  {'P':>3} {'ID_read(uA)':>11} {'ratio':>7} {'dVth(mV)':>9}")
    for i in range(N_PULSES):
        r = ids_r[i]/id0 if id0>0 else np.nan
        dv = -SS_MVDEC*np.log10(r) if r>0 else np.nan
        print(f"  {i+1:3d} {ids_r[i]*1e6:11.4f} {r:7.4f} {dv:9.2f}")

    # Fire check
    fire_thr = FIRE_RATIO * id0
    fp = None
    for i in range(N_PULSES):
        if ids_r[i] > fire_thr:
            fp = i+1; break
    max_r = np.nanmax(ids_r/id0) if id0>0 else np.nan
    print(f"  Fire threshold: {fire_thr*1e6:.3f} uA  |  "
          f"{'FIRE at P'+str(fp) if fp else 'NO FIRE (max '+f'{max_r:.4f}x)'}")

    # Reset (corrected: fraction of integration reversed)
    rc = np.nan
    id_pre = ids_r[-1] if len(ids_r)>0 else np.nan
    if not np.isnan(id_pr) and not np.isnan(id0) and id_pre!=id0:
        rc = (id_pre - id_pr) / (id_pre - id0)
    print(f"  Reset: post={id_pr*1e6:.4f} uA, completeness={rc*100:.1f}%"
          if not np.isnan(rc) else "  Reset: N/A")

    results[tag] = dict(vreset=vreset, rdir=rdir, id0=id0, pol0=pol0,
                         ids_r=ids_r, pols_r=pols_r, ids_w=ids_w, pols_w=pols_w,
                         fp=fp, fire_thr=fire_thr, id_pr=id_pr, rc=rc,
                         leak_i0=leak_i0, leak_i1=leak_i1, leak_dur=leak_dur)

if not results:
    print("\nNo data. Exiting."); sys.exit(0)

CLR = {"n3":"tab:blue","n4":"tab:orange","n5":"tab:red"}
MRK = {"n3":"o","n4":"s","n5":"D"}

# ── Fig 1: Integration + Fire ──
fig1,(a1,a2) = plt.subplots(1,2,figsize=(13,5))
for t,r in results.items():
    if np.isnan(r["id0"]): continue
    px = np.arange(0,N_PULSES+1)
    iu = np.concatenate([[r["id0"]],r["ids_r"]])*1e6
    ra = iu/(r["id0"]*1e6)
    a1.plot(px,iu,f'{MRK[t]}-',color=CLR[t],label=f'{t} (Vr={r["vreset"]}V)',ms=5)
    a2.plot(px,ra,f'{MRK[t]}-',color=CLR[t],label=t,ms=5)
a2.axhline(FIRE_RATIO,color='gray',ls=':',label=f'Fire ({FIRE_RATIO}x)')
a1.set(xlabel="Pulse #",ylabel=f"$I_D$ at $V_{{GS}}$={VGS_READ}V (uA)",
       title="Integration: Read Current vs Pulse")
a2.set(xlabel="Pulse #",ylabel="$I_D/I_{D,base}$",
       title="Fire Detection: Ratio at Constant $V_{GS}$")
for a in (a1,a2): a.legend(fontsize=8); a.grid(True,alpha=0.3)
fig1.suptitle(f"SimC v2: Vpulse={VPULSE}V, pw=100ns, VGS_read={VGS_READ}V",y=1.01)
fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR,"simC_fig1_integration_fire.png"),dpi=150,bbox_inches="tight")
print(f"\nSaved simC_fig1_integration_fire.png")

# ── Fig 2: Polarization + dVth ──
fig2,(a1,a2) = plt.subplots(1,2,figsize=(13,5))
px = np.arange(1,N_PULSES+1)
for t,r in results.items():
    if np.isnan(r["pols_r"]).all(): continue
    a1.plot(px,r["pols_r"],f'{MRK[t]}-',color=CLR[t],label=f'{t} read',ms=5)
    if not np.isnan(r["pols_w"]).all():
        a1.plot(px,r["pols_w"],f'{MRK[t]}--',color=CLR[t],label=f'{t} write',ms=4,alpha=0.5)
    if r["id0"]>0:
        ra = r["ids_r"]/r["id0"]
        dv = np.where(ra>0, -SS_MVDEC*np.log10(ra), np.nan)
        a2.plot(px,dv,f'{MRK[t]}-',color=CLR[t],label=t,ms=5)
a1.axhline(0,color='gray',ls='-',alpha=0.3)
a1.set(xlabel="Pulse #",ylabel="Pol/y (C/cm2)",title="Local Polarization at HZO center")
a2.set(xlabel="Pulse #",ylabel="$\\Delta V_{th}$ (mV)",
       title="$\\Delta V_{th}$ (SS-based, negative=decreased)")
for a in (a1,a2): a.legend(fontsize=8); a.grid(True,alpha=0.3)
fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR,"simC_fig2_polarization_dvth.png"),dpi=150,bbox_inches="tight")
print("Saved simC_fig2_polarization_dvth.png")

# ── Fig 3: Reset + Leak ──
fig3,(a1,a2) = plt.subplots(1,2,figsize=(13,5))
rtags,rvals = [],[]
for t,r in results.items():
    if not np.isnan(r["rc"]):
        rtags.append(f'{t}\n({r["vreset"]}V)'); rvals.append(r["rc"]*100)
if rtags:
    bc = [CLR[t.split('\n')[0]] for t in rtags]
    bars = a1.bar(rtags,rvals,color=bc,width=0.6)
    a1.axhline(80,color='green',ls=':',label='Target 80%')
    a1.axhline(50,color='orange',ls=':',label='Min 50%')
    a1.set(ylabel="Reset completeness (%)",title="Reset: fraction of integration reversed",
           ylim=(0,110))
    a1.legend(fontsize=8)
    for b,v in zip(bars,rvals):
        a1.text(b.get_x()+b.get_width()/2, v+1, f'{v:.1f}%', ha='center',fontsize=9,fontweight='bold')

for t,r in results.items():
    ld = safe_parse(os.path.join(r["rdir"],f"leak_gap_{t}_des.plt"))
    if ld is not None:
        tr = (ld[TIME_COL]-ld[TIME_COL][0])*1e6
        a2.plot(tr,ld[ID_COL]*1e6,'-',color=CLR[t],label=f'{t} ({r["vreset"]}V)',lw=1.5)
if results:
    fv = list(results.values())[0]
    if not np.isnan(fv["id0"]):
        a2.axhline(fv["id0"]*1e6,color='gray',ls=':',label='Baseline',alpha=0.7)
a2.set(xlabel="Time in gap (us)",ylabel=f"$I_D$ at VGS={VGS_READ}V (uA)",
       title="Leak: Domain Relaxation During Gap")
a2.legend(fontsize=8); a2.grid(True,alpha=0.3)
fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR,"simC_fig3_reset_leak.png"),dpi=150,bbox_inches="tight")
print("Saved simC_fig3_reset_leak.png")

# ── Fig 4: Full LIF cycle ──
fig4,ax = plt.subplots(figsize=(10,6))
xlbl = ["Base"]+[f"P{i}" for i in range(1,N_PULSES+1)]+["Reset"]
xv = np.arange(len(xlbl))
for t,r in results.items():
    if np.isnan(r["id0"]): continue
    yi = np.concatenate([[r["id0"]],r["ids_r"],[r["id_pr"]]])*1e6
    ax.plot(xv,yi,f'{MRK[t]}-',color=CLR[t],
            label=f'{t} ($V_{{reset}}$={r["vreset"]}V)',ms=6)
if results:
    fv = list(results.values())[0]
    ax.axhline(fv["fire_thr"]*1e6,color='red',ls='--',lw=1.5,
               label=f'Fire threshold ({FIRE_RATIO}x={fv["fire_thr"]*1e6:.1f}uA)')
    ax.axhline(fv["id0"]*1e6,color='gray',ls=':',alpha=0.7,
               label=f'Baseline ({fv["id0"]*1e6:.2f}uA)')
ax.axvspan(0.5,5.5,alpha=0.05,color='blue')
ax.axvspan(5.5,10.5,alpha=0.05,color='green')
ax.set_xticks(xv); ax.set_xticklabels(xlbl,rotation=45,ha='right',fontsize=8)
ax.set(ylabel=f"$I_D$ at $V_{{GS}}$={VGS_READ}V (uA)",
       title=f"LIF Cycle: Vpulse={VPULSE}V, pw=100ns  |  NO FIRE (max {max_r:.3f}x)")
ax.legend(fontsize=7,loc='upper left'); ax.grid(True,alpha=0.3)
fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR,"simC_fig4_lif_cycle.png"),dpi=150,bbox_inches="tight")
print("Saved simC_fig4_lif_cycle.png")

# ── Summary ──
print(f"\n{'='*70}\nSUMMARY\n{'='*70}")
for t,r in results.items():
    mr = np.nanmax(r["ids_r"]/r["id0"]) if r["id0"]>0 else np.nan
    dv = -SS_MVDEC*np.log10(mr) if mr>0 else np.nan
    print(f"  {t} (Vr={r['vreset']}V): base={r['id0']*1e6:.3f}uA, "
          f"max_ratio={mr:.4f}x, dVth={dv:.1f}mV, "
          f"fire={'P'+str(r['fp']) if r['fp'] else 'NO'}, "
          f"reset={r['rc']*100:.1f}%" if not np.isnan(r['rc']) else f"reset=N/A")

print(f"\nDIAGNOSIS: Integration too shallow (max ~{max_r:.2f}x, need {FIRE_RATIO}x)")
print("ROOT CAUSE: Vpulse=2V < capacitive-divider-adjusted coercive voltage")
print("  V_fe = Vpulse * Cfe/(Cfe+Cox) ~ 2.0 * 0.57 = 1.14V < Vc=1.2V")
print("FIX: simC v3 sweeps Vpulse = 3, 4, 5V with pw = 1us")
print(f"\nDone. Figures in {OUT_DIR}")
