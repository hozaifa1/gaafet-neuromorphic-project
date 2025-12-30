import argparse
import numpy as np
from pathlib import Path


SAMPLES_PER_STEP = 25


def parse_plt_file(path: Path):
    """Return VGS and Id arrays extracted from a Sentaurus DF-ISE PLT file."""
    values = []
    records = []
    data_started = False

    with path.open("r", errors="ignore") as handle:
        for raw_line in handle:
            line = raw_line.strip()

            if not data_started:
                if line.startswith("Data"):
                    data_started = True
                continue

            if not line:
                continue

            if line.startswith("}"):
                break

            for token in line.split():
                try:
                    values.append(float(token))
                except ValueError:
                    continue

            while len(values) >= SAMPLES_PER_STEP:
                records.append(values[:SAMPLES_PER_STEP])
                values = values[SAMPLES_PER_STEP:]

    if not records:
        raise ValueError(f"No data records found in {path}")

    data = np.array(records)
    gate_voltage = data[:, 17]
    source_voltage = data[:, 9]
    drain_current = np.abs(data[:, 7])

    vgs = gate_voltage - source_voltage
    return vgs, drain_current


def find_kink(ids):
    """Detect kink by finding largest current ratio between adjacent points."""
    max_ratio = 1.0
    kink_idx = -1
    
    for i in range(1, len(ids)):
        if ids[i-1] > 1e-15:
            ratio = ids[i] / ids[i-1]
            if ratio > max_ratio and ratio > 2.0:
                max_ratio = ratio
                kink_idx = i
    
    return kink_idx, max_ratio


def analyze_curve(plt_file, vds_label):
    """Comprehensive analysis of a single curve."""
    print(f"\n{'='*70}")
    print(f"ANALYZING: {plt_file.name} (VDS = {vds_label}V)")
    print(f"{'='*70}")
    
    vgs, ids = parse_plt_file(plt_file)
    vsg = -vgs
    
    mask = (-0.5 <= vsg) & (vsg <= 0.0)
    vsg_roi = vsg[mask]
    ids_roi = ids[mask]
    
    order = np.argsort(vsg_roi)
    vsg_sorted = vsg_roi[order]
    ids_sorted = ids_roi[order]
    
    ids_ua = ids_sorted * 1e6
    
    print(f"\n1. BASIC STATISTICS:")
    print(f"   VSG range: [{vsg_sorted.min():.4f}, {vsg_sorted.max():.4f}] V")
    print(f"   IDS range: [{ids_ua.min():.6f}, {ids_ua.max():.3f}] µA")
    print(f"   IDS range (A): [{ids_sorted.min():.3e}, {ids_sorted.max():.3e}] A")
    print(f"   Number of points: {len(vsg_sorted)}")
    
    print(f"\n2. KEY VOLTAGES:")
    idx_vsg_min = np.argmin(np.abs(vsg_sorted - (-0.5)))
    idx_vsg_0 = np.argmin(np.abs(vsg_sorted - 0.0))
    print(f"   IDS at VSG = -0.5V: {ids_ua[idx_vsg_min]:.6f} µA ({ids_sorted[idx_vsg_min]:.3e} A)")
    print(f"   IDS at VSG = 0.0V: {ids_ua[idx_vsg_0]:.6f} µA ({ids_sorted[idx_vsg_0]:.3e} A)")
    
    target_vth = -0.244
    idx_vth = np.argmin(np.abs(vsg_sorted - target_vth))
    vsg_at_vth = vsg_sorted[idx_vth]
    ids_at_vth = ids_sorted[idx_vth]
    ids_at_vth_ua = ids_ua[idx_vth]
    ids_at_vth_na = ids_at_vth * 1e9
    
    print(f"\n3. THRESHOLD ANALYSIS (Target: V_th = {target_vth}V, I_th = 94 nA):")
    print(f"   Closest VSG to -0.244V: {vsg_at_vth:.4f}V")
    print(f"   IDS at VSG ≈ {vsg_at_vth:.4f}V: {ids_at_vth_na:.3f} nA ({ids_at_vth_ua:.6f} µA)")
    print(f"   Error from 94 nA: {abs(ids_at_vth_na - 94):.3f} nA ({abs(ids_at_vth_na - 94)/94*100:.1f}%)")
    
    target_ith = 94e-9
    idx_near_94na = np.argmin(np.abs(ids_sorted - target_ith))
    vsg_at_94na = vsg_sorted[idx_near_94na]
    ids_at_94na_actual = ids_sorted[idx_near_94na] * 1e9
    
    print(f"\n4. FINDING VSG AT 94 nA:")
    print(f"   VSG where IDS ≈ 94 nA: {vsg_at_94na:.4f}V (actual: {ids_at_94na_actual:.3f} nA)")
    print(f"   Error from target V_th (-0.244V): {abs(vsg_at_94na - target_vth):.4f}V")
    
    kink_idx, kink_ratio = find_kink(ids_sorted)
    
    print(f"\n5. KINK DETECTION:")
    if kink_idx > 0:
        vsg_kink = vsg_sorted[kink_idx]
        ids_before = ids_ua[kink_idx-1]
        ids_after = ids_ua[kink_idx]
        print(f"   Kink detected at VSG ≈ {vsg_kink:.4f}V")
        print(f"   Current jump: {ids_before:.6f} → {ids_after:.6f} µA")
        print(f"   Jump ratio: {kink_ratio:.1f}×")
        
        if vsg_kink < -0.1:
            print(f"   ⚠️  Kink position looks reasonable")
        else:
            print(f"   ⚠️  Kink too close to VSG=0V (should be around -0.3V to -0.4V)")
    else:
        print(f"   ❌ NO significant kink detected")
    
    print(f"\n6. CURRENT GRADIENT ANALYSIS:")
    grad = np.gradient(ids_ua, vsg_sorted)
    max_grad_idx = np.argmax(np.abs(grad))
    print(f"   Maximum gradient at VSG = {vsg_sorted[max_grad_idx]:.4f}V")
    print(f"   Maximum gradient value: {grad[max_grad_idx]:.3e} µA/V")
    
    print(f"\n7. COMPARISON WITH PAPER (Fig 7b, VD = 1.0V):")
    paper_max_current_ua = 85.0
    paper_ith_na = 94.0
    paper_vth = -0.244
    
    max_current_ratio = ids_ua.max() / paper_max_current_ua
    ith_ratio = ids_at_vth_na / paper_ith_na
    
    print(f"   Paper max current: ~{paper_max_current_ua:.0f} µA at VSG = -0.5V")
    print(f"   Your max current: {ids_ua.max():.6f} µA")
    print(f"   Ratio: {max_current_ratio:.4f}× (need {1/max_current_ratio:.1f}× increase)")
    print(f"")
    print(f"   Paper I_th at V_th: {paper_ith_na} nA")
    print(f"   Your I at V_th: {ids_at_vth_na:.3f} nA")
    print(f"   Ratio: {ith_ratio:.4f}× (need {1/ith_ratio:.1f}× increase)")
    
    return {
        'vsg': vsg_sorted,
        'ids_ua': ids_ua,
        'max_current_ua': ids_ua.max(),
        'ids_at_vth_na': ids_at_vth_na,
        'vsg_at_94na': vsg_at_94na,
        'kink_position': vsg_sorted[kink_idx] if kink_idx > 0 else None,
        'kink_ratio': kink_ratio,
        'current_ratio_vs_paper': max_current_ratio,
        'ith_ratio_vs_paper': ith_ratio
    }


def main():
    parser = argparse.ArgumentParser(description="Analyze Id–VSG curves from PLT files.")
    parser.add_argument(
        "plt_files",
        nargs="*",
        help="PLT files to analyze (default: vds_1v.plt and vds_5v.plt)",
    )
    parser.add_argument(
        "--base",
        type=Path,
        default=Path(r"f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations"),
        help="Base directory for PLT files",
    )
    args = parser.parse_args()

    base_path = args.base
    if args.plt_files:
        files = [base_path / name for name in args.plt_files]
    else:
        files = [base_path / "vds_1v.plt", base_path / "vds_5v.plt"]

    existing_files = []
    for file in files:
        if not file.exists():
            print(f"Error: {file} not found")
            return
        existing_files.append(file)

    results = []
    for file in existing_files:
        label = file.stem.replace("vds_", "").replace("_", ".")
        stats = analyze_curve(file, label)
        results.append((label, stats))
    
    if len(results) >= 2:
        (label_a, stats_a), (label_b, stats_b) = results[0], results[1]
        print(f"\n{'='*70}")
        print(f"CROSS-COMPARISON: VDS = {label_a}V vs {label_b}V")
        print(f"{'='*70}")
        
        print(f"\nMax Current:")
        print(f"  VDS = {label_a}V: {stats_a['max_current_ua']:.6f} µA")
        print(f"  VDS = {label_b}V: {stats_b['max_current_ua']:.6f} µA")
        
        if stats_b['max_current_ua'] < stats_a['max_current_ua']:
            print(f"  ⚠️  WARNING: VDS={label_b}V has LOWER current than VDS={label_a}V!")
            print(f"  This is physically incorrect. Check your VDS={label_b}V simulation setup.")
        else:
            print(f"  ✓ VDS={label_b}V has higher current (as expected)")
        
        print(f"\nCurrent at V_th (-0.244V):")
        print(f"  VDS = {label_a}V: {stats_a['ids_at_vth_na']:.3f} nA")
        print(f"  VDS = {label_b}V: {stats_b['ids_at_vth_na']:.3f} nA")
        
        print(f"\nVSG at 94 nA:")
        print(f"  VDS = {label_a}V: {stats_a['vsg_at_94na']:.4f}V (target: -0.244V)")
        print(f"  VDS = {label_b}V: {stats_b['vsg_at_94na']:.4f}V (target: -0.244V)")
        
        stats_1v = stats_a
        stats_5v = stats_b
    else:
        stats_1v = results[0][1]
        stats_5v = results[0][1]
    
    print(f"\n{'='*70}")
    print(f"RECOMMENDED FIXES (Priority Order):")
    print(f"{'='*70}")
    
    fix_num = 1
    
    if stats_1v['current_ratio_vs_paper'] < 0.1:
        needed_increase = 1 / stats_1v['current_ratio_vs_paper']
        print(f"\n{fix_num}. CURRENT MAGNITUDE TOO LOW")
        print(f"   Current status: {needed_increase:.0f}× too low")
        print(f"   ")
        print(f"   Fix A: Change Areafactor from 0.09 to 1.0")
        print(f"          Expected improvement: 11× increase")
        print(f"   ")
        print(f"   Fix B: Reduce contact resistivity in SDE file")
        print(f"          Current: 7 Ω·μm² (from Table 1)")
        print(f"          Try: 1e-8 Ω·cm² (then regenerate mesh)")
        print(f"   ")
        print(f"   Fix C: Change mobility model:")
        print(f"          From: ConstantMobility")
        print(f"          To: DopingDependence + HighFieldSaturation")
        fix_num += 1
    
    if stats_5v['max_current_ua'] < stats_1v['max_current_ua']:
        print(f"\n{fix_num}. VDS=1.5V SIMULATION ERROR")
        print(f"   VDS=1.5V shows LOWER current than VDS=1.0V")
        print(f"   ")
        print(f"   Action: Verify electrode definition in sdevice file:")
        print("           { Name=\"drain_contact\" Voltage= 1.5 }")
        print(f"   Re-run VDS=1.5V simulation")
        fix_num += 1
    
    if stats_1v['kink_position'] is None or stats_1v['kink_position'] > -0.2:
        print(f"\n{fix_num}. KINK POSITION INCORRECT")
        print(f"   Current kink: {stats_1v['kink_position']:.4f}V if detected" if stats_1v['kink_position'] else "   No kink detected")
        print(f"   Target kink: -0.3V to -0.4V")
        print(f"   ")
        print(f"   Fix A: Add BandgapDependence to Avalanche:")
        print(f"          Avalanche(UniBo2 BandgapDependence)")
        print(f"   ")
        print(f"   Fix B: Verify .par file has:")
        print(f"          UniBo2 {{ d0_e = 1.0e6, d0_h = 1.0e6 }}")
        fix_num += 1
    
    vth_error_1v = abs(stats_1v['vsg_at_94na'] - (-0.244))
    if vth_error_1v > 0.05:
        print(f"\n{fix_num}. THRESHOLD VOLTAGE MISMATCH")
        print(f"   VSG at 94 nA: {stats_1v['vsg_at_94na']:.4f}V")
        print(f"   Target V_th: -0.244V")
        print(f"   Error: {vth_error_1v:.4f}V")
        print(f"   ")
        print(f"   Fix: Adjust gate workfunction (after current magnitude is fixed)")
        print(f"        Current: 4.6 eV")
        print(f"        Try: 4.5, 4.55, 4.6, 4.65 eV")
        fix_num += 1
    
    print(f"\n{'='*70}")


if __name__ == "__main__":
    main()
