import os
import sys
import re

def parse_plt_file(filepath):
    """
    Parses a Sentaurus .plt file with multi-line data blocks.
    Returns Vgs and Id arrays.
    """
    vgs_list = []
    id_list = []
    
    if not os.path.exists(filepath):
        print(f"Error: File not found at {filepath}")
        return [], [], []

    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Parse Header to find indices
    # We look for the 'datasets' block
    datasets_match = re.search(r'datasets\s*=\s*\[(.*?)\]', content, re.DOTALL)
    if not datasets_match:
        print("Error: Could not find 'datasets' block.")
        return [], [], []
    
    # Clean up and split variable names
    # They are usually quoted strings
    raw_datasets = datasets_match.group(1)
    # Find all strings inside quotes
    variables = re.findall(r'"([^"]+)"', raw_datasets)
    
    # We also need to account for "time" which might be unquoted or the first element
    # In the file viewed: "datasets = [ "time" "drain_contact OuterVoltage" ... ]"
    # So 'time' is usually first.
    
    try:
        idx_gate = -1
        idx_drain = -1
        idx_pol = -1
        
        # Sentaurus variable names can be complex. We search for substrings.
        for i, var in enumerate(variables):
            if "gate_contact" in var and "OuterVoltage" in var:
                idx_gate = i
            if "drain_contact" in var and "TotalCurrent" in var:
                idx_drain = i
            # Check for generic "Polarization" (Official) or "FEPolarization" (Previous)
            if "Polarization" in var and "FEPolarization" not in var:
                # Standard Polarization
                if "/y" in var:
                    idx_pol = i
            if "FEPolarization" in var and idx_pol == -1:
                # Fallback to FEPolarization if found
                if "/y" in var:
                    idx_pol = i

        # Second pass to ensure we capture ANY polarization variable
        if idx_pol == -1:
            for i, var in enumerate(variables):
                if "Polarization" in var or "FEPolarization" in var:
                    if "/y" in var:
                        idx_pol = i
                        break

                
        # If 'time' was not in quotes but present, we might be off by 1?
        # Based on file view: "time" IS in quotes.
        # But wait, there are 25 items in datasets.
        # Let's verify against the file content I saw:
        # datasets = [ "time" "drain_contact OuterVoltage" ... ]
        # So index 0 is time.
        
        if idx_gate == -1 or idx_drain == -1:
            print(f"Error: Could not find required variables. Found: {variables[:5]}...")
            return [], [], []
            
        # print(f"Debug: Found GateV at index {idx_gate}, DrainI at index {idx_drain}")

    except Exception as e:
        print(f"Error parsing header: {e}")
        return [], [], []

    # 2. Parse Data Section
    # Data starts after 'Data {' and ends with '}'
    data_match = re.search(r'Data\s*\{(.*?)\}', content, re.DOTALL)
    if not data_match:
        print("Error: Could not find 'Data' block.")
        return [], [], []
        
    raw_data = data_match.group(1).strip()
    # The data is a sequence of numbers separated by whitespace/newlines.
    # We can just split by any whitespace to get a flat list of numbers.
    all_numbers = raw_data.split()
    
    # 3. Reconstruct Records
    # The number of variables tells us the block size.
    # However, 'time' is sometimes special in .plt files (appearing on its own line).
    # But usually, it's just N variables per record.
    # The 'functions' list in the file view showed 25 functions.
    # The 'datasets' list showed 25 datasets.
    # So we assume strict periodicity of len(variables).
    
    num_vars = len(variables)
    total_values = len(all_numbers)
    
    if total_values % num_vars != 0:
        print(f"Warning: Data count ({total_values}) not divisible by variable count ({num_vars}). parsing might fail.")
    
    num_records = total_values // num_vars
    
    # print(f"Debug: Parsing {num_records} records with {num_vars} variables each.")

    pol_list = []
    
    for i in range(num_records):
        base_idx = i * num_vars
        
        try:
            # Extract Vgs and Id
            # Note: indices found above are relative to the 'variables' list
            v_gate = float(all_numbers[base_idx + idx_gate])
            i_drain = float(all_numbers[base_idx + idx_drain])
            
            # Extract Polarization if available
            p_val = 0.0
            if 'idx_pol' in locals() and idx_pol != -1:
                 p_val = float(all_numbers[base_idx + idx_pol])

            # Filter for Vgs > -0.5 (The relevant sweep range)
            # And ignore the transient zeros if any
            vgs_list.append(v_gate)
            id_list.append(abs(i_drain))
            pol_list.append(p_val)
            
        except (ValueError, IndexError):
            continue

    return vgs_list, id_list, pol_list

def extract_vth(vgs, ids, target_current=1e-7):
    """
    Extracts Vth at a specific constant current level (e.g., 100nA * W/L).
    """
    if not vgs:
        return 0.0

    # 1. Sort data by Vgs for analysis
    data_map = {}
    for v, i in zip(vgs, ids):
        # Handle duplicates by keeping the last one or averaging?
        # Simple overwrite is fine for now
        data_map[v] = i
        
    sorted_vgs = sorted(data_map.keys())
    sorted_ids = [data_map[v] for v in sorted_vgs]
    
    for i in range(len(sorted_vgs)-1):
        v1, i1 = sorted_vgs[i], sorted_ids[i]
        v2, i2 = sorted_vgs[i+1], sorted_ids[i+1]
        
        # Check crossing
        if (i1 < target_current and i2 >= target_current):
            # Log-linear interpolation
            try:
                import math
                log_i1 = math.log10(i1) if i1 > 0 else -15
                log_i2 = math.log10(i2)
                log_target = math.log10(target_current)
                
                fraction = (log_target - log_i1) / (log_i2 - log_i1)
                return v1 + fraction * (v2 - v1)
            except:
                return v1 # Fallback
            break
            
    return 0.0

def get_current_at_voltage(vgs, ids, target_voltage):
    if not vgs:
        return 0.0
        
    # Find points bracketing the target
    # Assuming sorted Vgs (mostly true for sweeps)
    # But for hysteresis loops, we should handle leg by leg (caller does this)
    
    # Simple check for exact match
    if target_voltage in vgs:
        return ids[vgs.index(target_voltage)]
        
    # Interpolation
    sorted_pairs = sorted(zip(vgs, ids))
    v_sorted = [p[0] for p in sorted_pairs]
    i_sorted = [p[1] for p in sorted_pairs]
    
    for k in range(len(v_sorted)-1):
        v1, i1 = v_sorted[k], i_sorted[k]
        v2, i2 = v_sorted[k+1], i_sorted[k+1]
        
        if v1 <= target_voltage <= v2 or v2 <= target_voltage <= v1:
            # Linear interp
            if v2 == v1: return i1
            fraction = (target_voltage - v1) / (v2 - v1)
            return i1 + fraction * (i2 - i1)
            
    # Extrapolation or failure (return closest)
    return min(ids, key=lambda x: abs(x - 0)) # Fallback, though rare if range covers it


def main():
    if len(sys.argv) > 1:
        sim_dir = sys.argv[1]
    else:
        sim_dir = os.getcwd()

    print(f"Analyzing: {sim_dir}")
    
    # Try reading segmented files first (New Strategy)
    # NewCurrentPrefix="read_legX_" -> output is "read_legX_n5_des.plt"
    file_base = "read_leg{}_n5_des.plt"
    legs = [1, 2, 3]
    vgs_all = []
    ids_all = []
    pol_all = []
    
    found_segmented = False
    for leg in legs:
        fpath = os.path.join(sim_dir, file_base.format(leg))
        if os.path.exists(fpath):
            found_segmented = True
            print(f"Reading Leg {leg}: {fpath}")
            v, i, p = parse_plt_file(fpath)
            vgs_all.extend(v)
            ids_all.extend(i)
            pol_all.extend(p)
            
    # Fallback to single file (Legacy)
    if not found_segmented:
        plt_file = os.path.join(sim_dir, "read_n5_des.plt")
        print(f"Looking for single file: {plt_file}")
        v, i, p = parse_plt_file(plt_file)
        vgs_all = v
        ids_all = i
        pol_all = p
    
    if not vgs_all:
        print("No data found.")
        sys.exit(1)

    # For Analysis, we need to identify the loops.
    # If segmented, we know:
    # Leg 1: 0 -> -4V
    # Leg 2: -4V -> +4V (Forward Sweep)
    # Leg 3: +4V -> -4V (Reverse Sweep)
    
    # Initialize variables to avoid unbound errors
    vgs_2, ids_2, p2 = [], [], []
    vgs_3, ids_3, p3 = [], [], []

    if found_segmented:
        # Re-read explicitly to separate them for analysis
        vgs_1, ids_1, p1 = parse_plt_file(os.path.join(sim_dir, file_base.format(1)))
        vgs_2, ids_2, p2 = parse_plt_file(os.path.join(sim_dir, file_base.format(2))) # Forward
        vgs_3, ids_3, p3 = parse_plt_file(os.path.join(sim_dir, file_base.format(3))) # Reverse
        
        # Forward Sweep is Leg 2
        vgs_fwd = vgs_2
        ids_fwd = ids_2
        
        # Reverse Sweep is Leg 3
        vgs_rev = vgs_3
        ids_rev = ids_3
        
    else:
        # Legacy Split (Heuristic)
        # Split into Forward and Reverse Sweeps based on Peak Vgs
        max_vgs = max(vgs_all)
        max_idx = vgs_all.index(max_vgs)
        
        # Forward: Start to Peak
        vgs_fwd = vgs_all[:max_idx+1]
        ids_fwd = ids_all[:max_idx+1]
        
        # Reverse: Peak to End (if it exists)
        vgs_rev = []
        ids_rev = []
        if len(vgs_all) > max_idx + 1:
            vgs_rev = vgs_all[max_idx:]
            ids_rev = ids_all[max_idx:]
            
        # Assign to legacy variables for plotting compatibility (Best Effort)
        vgs_2, ids_2 = vgs_fwd, ids_fwd
        vgs_3, ids_3 = vgs_rev, ids_rev
        # Split polarization roughly
        if pol_all:
             p2 = pol_all[:max_idx+1]
             p3 = pol_all[max_idx:]

    # Metrics for Forward Sweep (Standard DC)
    # Filter for positive Vgs for Vth extraction if needed, or just pass all
    vth_fwd = extract_vth(vgs_fwd, ids_fwd, target_current=1e-7)
    ion = get_current_at_voltage(vgs_fwd, ids_fwd, 0.5)
    ioff = get_current_at_voltage(vgs_fwd, ids_fwd, 0.0)
    ipeak = max(ids_fwd) if ids_fwd else 0
    
    # Metrics for Reverse Sweep (Hysteresis)
    vth_rev = 0.0
    mw = 0.0
    
    if len(vgs_rev) > 5:
        vth_rev = extract_vth(vgs_rev, ids_rev, target_current=1e-7)
        mw = abs(vth_fwd - vth_rev)

    print("\n" + "="*40)
    print("  CALIBRATION METRICS REPORT")
    print("="*40)
    print(f"{'Metric':<20} | {'Extracted':<15} | {'Target':<15}")
    print("-" * 56)
    print(f"{'V_th (Fwd)':<20} | {vth_fwd*1000:>6.0f} mV       | +250 mV")
    
    if len(vgs_rev) > 5:
        print(f"{'V_th (Rev)':<20} | {vth_rev*1000:>6.0f} mV       | -")
        print(f"{'Memory Window':<20} | {mw*1000:>6.0f} mV       | > 0 mV")
    else:
        print(f"{'Memory Window':<20} | {'No Hysteresis':<15} | > 0 mV")
        
    print(f"{'I_off (@ 0V)':<20} | {ioff*1e6:.3f} uA        | < 0.1 uA")
    print(f"{'I_on (@ 0.5V)':<20} | {ion*1e6:.3f} uA        | > 1.0 uA")
    print(f"{'I_peak (@ 6.0V)':<20} | {ipeak*1e6:.1f} uA        | 600 uA")
    print("="*40)
    
    # Polarization Stats
    if pol_all:
        p_max = max(pol_all)
        p_min = min(pol_all)
        print(f"\n[INFO] Polarization Stats (C/cm^2):")
        print(f"       Max (+Pr): {p_max:.2e}")
        print(f"       Min (-Pr): {p_min:.2e}")
        print(f"       Delta P:   {p_max - p_min:.2e}")

    # Area Factor Tuning Recommendation
    target_peak = 600e-6
    current_af = 0.069 # Updated to current value in sdevice
    new_af = current_af * (target_peak / ipeak) if ipeak > 0 else current_af
    
    print(f"       Current Peak: {ipeak*1e6:.1f} uA")
    print(f"       Target Peak:  {target_peak*1e6:.1f} uA")
    print(f"       Recommended AF: {new_af:.3f}")
    
    # Export Loop Data for detailed inspection
    csv_path = os.path.join(sim_dir, "hysteresis_data.csv")
    print(f"\n[INFO] Exporting loop data to {csv_path}...")
    with open(csv_path, 'w') as f:
        f.write("Leg,Vg,Id,Pol\n")
        # Write Leg 2 (Fwd)
        if vgs_2:
            for v, i, p in zip(vgs_2, ids_2, p2):
                 f.write(f"Fwd,{v:.4f},{i:.4e},{p:.4e}\n")
        # Write Leg 3 (Rev)
        if vgs_3:
            for v, i, p in zip(vgs_3, ids_3, p3):
                 f.write(f"Rev,{v:.4f},{i:.4e},{p:.4e}\n")

    # --- Generate Plots ---
    try:
        # Add script dir to path to find generate_plots.py
        script_dir = os.path.dirname(os.path.abspath(__file__))
        if script_dir not in sys.path:
            sys.path.append(script_dir)
            
        from generate_plots import generate_plots
        
        # Prepare Parameters Dictionary for Annotation
        params = {
            "Run ID": "1 (Baseline)",
            "Workfunction": "3.9 eV", 
            "Fixed Charge": "5.15e12 cm-2",
            "Pr": "16 uC/cm2 (CW Loop)",
            "Ec": "1.2 MV/cm",
            "Vth (Fwd)": f"{vth_fwd*1000:.0f} mV",
            "Vth (Rev)": f"{vth_rev*1000:.0f} mV" if vth_rev else "N/A",
            "MW": f"{mw*1000:.0f} mV",
            "Ion": f"{ipeak*1e6:.1f} uA"
        }
        
        print("\n[INFO] Generating Plots...")
        generate_plots(sim_dir, "1", params)
        
    except ImportError:
        print("Warning: Could not import generate_plots.py. Skipping plot generation.")
    except Exception as e:
        print(f"Warning: Plot generation failed: {e}")

if __name__ == "__main__":
    main()
