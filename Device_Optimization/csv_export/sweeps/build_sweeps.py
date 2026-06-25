"""Build publication-ready tidy CSVs from the coordinate-descent TSV logs.

Reads docs/turn*.tsv (full precision) + curated baselines from OPT_LOG.md,
writes one tidy CSV per sweep + an optimization trajectory + a README.
Local-only. Creates files under csv_export/sweeps/. Does not modify inputs.
"""
import os
import pandas as pd

ROOT = r"F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Device_Optimization"
DOCS = os.path.join(ROOT, "docs")
OUT = os.path.join(ROOT, "csv_export", "sweeps")
os.makedirs(OUT, exist_ok=True)

# Convert uA/um current strings; values already in uA/um.
A2 = "id_off_uA_um"


def load_tsv(name):
    """Load a turn TSV, stripping KEY= prefixes from value cells."""
    df = pd.read_csv(os.path.join(DOCS, name), sep="\t", dtype=str)
    for col in df.columns:
        # strip "KEY=" prefix where present (e.g. WIN=5800 -> 5800)
        df[col] = df[col].apply(
            lambda v: v.split("=", 1)[1] if isinstance(v, str) and "=" in v and not v.startswith("-") else v
        )
    return df


def fnum(series):
    return pd.to_numeric(series, errors="coerce")


written = []


def save(df, fname, sort_col):
    df = df.sort_values(sort_col).reset_index(drop=True)
    path = os.path.join(OUT, fname)
    df.to_csv(path, index=False)
    written.append((fname, df, sort_col))


# ---- Turn 1: VREAD sweep (no WIN/IDon; carry DR + IDrest) ----
t1 = load_tsv("turn1_vread.tsv")
vread = pd.DataFrame({
    "vread_V": fnum(t1["VREAD"]),
    "dr": fnum(t1["DR"]),
    A2: fnum(t1["IDrest"]),
    "v_op_V": fnum(t1["Vop"]),
    "qg_C": fnum(t1["Qg"]),
})
save(vread, "vread_sweep.csv", "vread_V")

# ---- Turn 2: T_ox sweep. Map tags -> nm; keep fixed4V + subcoercive; add baseline ----
t2 = load_tsv("turn2_tox.tsv")
tox_map = {"tox05": 0.5, "tox10": 1.0, "tox15": 1.5}
rows = []
for _, r in t2.iterrows():
    tag = r["tag"]
    eval_kind = "subcoercive" if tag.startswith("t2b_") else "fixed4V"
    rows.append({
        "t_ox_nm": tox_map[r["mesh"]],
        "eval": eval_kind,
        "window": float("nan"),  # turn2 tsv has no WIN column
        A2: float(r["IDrest"]),
        "id_on_uA_um": float(r["IDp9"]),  # IDp9 = retained on-state at p9
        "v_op_V": float(r["Vop"]),
        "igain": float(r["igain"]),
        "qg_C": float(r["Qg"]),
    })
# baseline T_ox=2.0 nm (from OPT_LOG: WINDOW=2.6, IDoff=8.75e-5, V_op=4.0)
rows.append({
    "t_ox_nm": 2.0, "eval": "fixed4V", "window": 2.6,
    A2: 8.75e-5, "id_on_uA_um": float("nan"), "v_op_V": 4.0,
    "igain": float("nan"), "qg_C": float("nan"),
})
tox = pd.DataFrame(rows)
save(tox, "tox_sweep.csv", "t_ox_nm")

# ---- Turn 3: T_si sweep. Map tags -> nm; add baseline T_si=15 ----
t3 = load_tsv("turn3_tsi.tsv")
tsi_map = {"si05": 5, "si08": 8, "si10": 10, "si12": 12}
rows = []
for _, r in t3.iterrows():
    rows.append({
        "t_si_nm": tsi_map[r["mesh"]],
        "window": float(r["WIN"]),
        A2: float(r["IDrest"]),
        "id_on_uA_um": float(r["IDon"]),
        "v_op_V": float(r["Vop"]),
        "igain": float(r["igain"]),
        "qg_C": float(r["Qg"]),
    })
rows.append({  # baseline T_si=15 nm (OPT_LOG: WINDOW=5800, IDoff=2.85e-8, IDon=1.66e-4)
    "t_si_nm": 15, "window": 5800.0, A2: 2.85e-8,
    "id_on_uA_um": 1.66e-4, "v_op_V": 4.0, "igain": float("nan"), "qg_C": float("nan"),
})
tsi = pd.DataFrame(rows)
save(tsi, "tsi_sweep.csv", "t_si_nm")

# ---- Turn 4: N_sub sweep. Map tags -> cm^-3; add baseline N_sub=1e16 ----
t4 = load_tsv("turn4_nsub.tsv")
nsub_map = {"nsub15": 1e15, "nsub17": 1e17, "nsub5e17": 5e17}
rows = []
for _, r in t4.iterrows():
    rows.append({
        "n_sub_cm3": nsub_map[r["mesh"]],
        "window": float(r["WIN"]),
        A2: float(r["IDrest"]),
        "id_on_uA_um": float(r["IDon"]),
        "v_op_V": float(r["Vop"]),
        "igain": float(r["igain"]),
        "qg_C": float(r["Qg"]),
    })
rows.append({  # baseline N_sub=1e16 (OPT_LOG: WINDOW=47309, IDoff=3.7e-9; = si05 base)
    "n_sub_cm3": 1e16, "window": 47309.0, A2: 3.7e-9,
    "id_on_uA_um": 1.76e-4, "v_op_V": 4.0, "igain": float("nan"), "qg_C": float("nan"),
})
nsub = pd.DataFrame(rows)
save(nsub, "nsub_sweep.csv", "n_sub_cm3")

# ---- Turn 5: T_fe sweep. Map tags -> nm (fe10 row has mesh=si05 baseline) ----
t5 = load_tsv("turn5_tfe.tsv")
tfe_map = {"fe05": 5, "fe07": 7, "fe10": 10, "fe12": 12}
rows = []
for _, r in t5.iterrows():
    tag = r["tag"]  # t5_fe05 etc -> last token
    key = tag.split("_")[-1]
    rows.append({
        "t_fe_nm": tfe_map[key],
        "window": float(r["WIN"]),
        A2: float(r["IDrest"]),
        "id_on_uA_um": float(r["IDon"]),
        "v_op_V": float(r["Vop"]),
        "igain": float(r["igain"]),
        "qg_C": float(r["Qg"]),
    })
tfe = pd.DataFrame(rows)
save(tfe, "tfe_sweep.csv", "t_fe_nm")

# ---- Turn 6: L scaling (two one-off pts + fe07 reference) ----
t6 = load_tsv("turn6_lscaling.tsv")
# reference fe07 from turn5
fe07 = t5[t5["tag"].str.endswith("fe07")].iloc[0]
rows = [{
    "label": "fe07_reference", "l_gate_nm": 100, "l_ov_nm": 15,
    "window": float(fe07["WIN"]), A2: float(fe07["IDrest"]),
    "id_on_uA_um": float(fe07["IDon"]), "v_op_V": float(fe07["Vop"]),
    "igain": float(fe07["igain"]), "qg_C": float(fe07["Qg"]),
}]
for _, r in t6.iterrows():
    tag = r["tag"]
    if "lg50" in tag:
        lg, lov, lab = 50, 15, "lgate_50nm"
    else:  # lov0
        lg, lov, lab = 100, 0, "lov_0nm"
    rows.append({
        "label": lab, "l_gate_nm": lg, "l_ov_nm": lov,
        "window": float(r["WIN"]), A2: float(r["IDrest"]),
        "id_on_uA_um": float(r["IDon"]), "v_op_V": float(r["Vop"]),
        "igain": float(r["igain"]), "qg_C": float(r["Qg"]),
    })
lsc = pd.DataFrame(rows)
save(lsc, "lscaling.csv", "l_gate_nm")

# ---- Optimization trajectory (one row per turn, the coordinate-descent path) ----
# Values from OPT_LOG.md KEEP / CURRENT BEST lines.
traj = pd.DataFrame([
    {"turn": 1, "parameter": "VREAD", "chosen_value": "-0.5 V", "window": 2.6, "id_off_uA_um": 8.75e-5, "v_op_V": 4.0},
    {"turn": 2, "parameter": "T_ox", "chosen_value": "1.0 nm", "window": 5800.0, "id_off_uA_um": 2.85e-8, "v_op_V": 2.5},
    {"turn": 3, "parameter": "T_si", "chosen_value": "5 nm", "window": 47309.0, "id_off_uA_um": 3.7e-9, "v_op_V": 4.0},
    {"turn": 4, "parameter": "N_sub", "chosen_value": "1e16 cm^-3", "window": 47309.0, "id_off_uA_um": 3.7e-9, "v_op_V": 4.0},
    {"turn": 5, "parameter": "T_fe", "chosen_value": "7 nm", "window": 96240.0, "id_off_uA_um": 1.9e-9, "v_op_V": 2.5},
    {"turn": 6, "parameter": "L_gate / L_ov", "chosen_value": "100 nm / 15 nm", "window": 96240.0, "id_off_uA_um": 1.9e-9, "v_op_V": 2.5},
])
traj_path = os.path.join(OUT, "optimization_trajectory.csv")
traj.to_csv(traj_path, index=False)
written.append(("optimization_trajectory.csv", traj, "turn"))

# ---- Validate: load every CSV, check swept col has no NaN, print shape ----
print("=== Validation ===")
swept_cols = {
    "vread_sweep.csv": "vread_V", "tox_sweep.csv": "t_ox_nm",
    "tsi_sweep.csv": "t_si_nm", "nsub_sweep.csv": "n_sub_cm3",
    "tfe_sweep.csv": "t_fe_nm", "lscaling.csv": "l_gate_nm",
    "optimization_trajectory.csv": "turn",
}
for fname, _, _ in written:
    df = pd.read_csv(os.path.join(OUT, fname))
    sc = swept_cols[fname]
    nan_ct = df[sc].isna().sum()
    status = "OK" if nan_ct == 0 else f"FAIL ({nan_ct} NaN in {sc})"
    print(f"{fname:34s} shape={df.shape}  swept='{sc}' NaN={nan_ct}  [{status}]")
