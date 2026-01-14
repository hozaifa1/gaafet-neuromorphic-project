#!/usr/bin/env python3
"""Analyze all VDS simulation results after finer timestep fix"""

def parse_plt_file(filepath):
    """Parse Sentaurus PLT file and extract drain current vs gate voltage"""
    try:
        with open(filepath, 'r', encoding='latin-1') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"DEBUG: File not found: {filepath}")
        return None
    except Exception as e:
        print(f"DEBUG: Error reading file {filepath}: {e}")
        return None
    
    # Find the Data section
    data_start = None
    for i, line in enumerate(lines):
        if line.strip() == 'Data {':
            data_start = i + 1
            break
    
    if data_start is None:
        print(f"DEBUG: 'Data {{' not found in {filepath}")
        print("DEBUG: First 10 lines:")
        for l in lines[:10]:
            print(f"  {l.strip()}")
        return None
    
    # Parse data values
    values = []
    for line in lines[data_start:]:
        if line.strip() == '}':
            break
        parts = line.split()
        values.extend([float(x) for x in parts])
    
    # Data format: 25 values per timestep
    # [0]=time, [1]=drain_OuterV, [7]=drain_TotalI, [17]=gate_OuterV
    data_points = []
    for i in range(0, len(values), 25):
        if i + 24 < len(values):
            timestep = {
                'time': values[i],
                'drain_V': values[i+1],
                'drain_I': values[i+7],
                'gate_V': values[i+17],
                'source_V': values[i+13]  # Add source voltage
            }
            data_points.append(timestep)
    
    return data_points

def main():
    print("="*80)
    print("TEST 2 RESULTS: VDS BUG AFTER 10x FINER TIMESTEPS")
    print("="*80)
    print()
    
    # Test different VDS values with Workbench naming conventions
    # User specified mapping: 3->0.4V, 4->0.8V, 5->1.0V, 6->1.2V, 7->1.4V
    vds_files = [
        ('0.4V', 'read_n3_des.plt'),
        ('0.8V', 'read_n4_des.plt'),
        ('1.0V', 'read_n5_des.plt'),
        ('1.2V', 'read_n6_des.plt'),
        ('1.4V', 'read_n7_des.plt'),
    ]
    
    results = []
    
    # Get the directory of the current script to build absolute paths
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))

    print("STEP 1: Extracting currents at VSG=-0.5V (Paper Target) and Vgs=0V")
    print("-"*80)
    
    for vds_label, filename in vds_files:
        # Construct full path to file
        full_path = os.path.join(script_dir, filename)
        data = parse_plt_file(full_path)
        if not data:
            print(f"⚠️  Could not parse {filename} (checked: {full_path})")
            continue
        
        # Find current at Vgs = -0.5V (Target: High Current)
        # We search for the point with gate_V closest to -0.5
        target_vg_calib = -0.5
        best_calib = min(data, key=lambda x: abs(x['gate_V'] - target_vg_calib))
        current_calib = abs(best_calib['drain_I']) * 1e6
        
        # Find current at Vgs = 0.0V
        best_zero = min(data, key=lambda x: abs(x['gate_V'] - 0.0))
        current_zero = abs(best_zero['drain_I']) * 1e6

        # Find current at max gate voltage (2.0V) - ON State
        best_high = max(data, key=lambda x: x['gate_V'])
        current_high = abs(best_high['drain_I']) * 1e6
        
        results.append({
            'vds': vds_label,
            'current_calib': current_calib, # @ -0.5V
            'current_zero': current_zero,   # @ 0.0V
            'current_high': current_high,   # @ 2.0V
        })
        
        print(f"VDS={vds_label}:")
        print(f"  Id @ Vgs=-0.5V: {current_calib:.4f} µA (Target: High)")
        print(f"  Id @ Vgs= 0.0V: {current_zero:.4f} µA")
        print(f"  Id @ Vgs= 2.0V: {current_high:.2f} µA")
        print()
    
    print("="*80)
    print("STEP 2: CALIBRATION CHECK (Target: Vth ~ -0.244V)")
    print("="*80)
    
    print(f"{'VDS':<8} {'Id @ -0.5V':<15} {'Id @ 0.0V':<15} {'Status':<15}")
    print("-"*80)
    
    for r in results:
        vds = r['vds']
        c_calib = f"{r['current_calib']:.4f}"
        c_zero = f"{r['current_zero']:.4f}"
        
        # Check if device is ON at -0.5V (Should be > 1 uA roughly)
        status = "OFF ❌"
        if r['current_calib'] > 1.0:
            status = "ON ✅"
            
        print(f"{vds:<8} {c_calib:<15} {c_zero:<15} {status:<15}")
    
    print("="*80)
    print()
    print("FINAL VERDICT:")
    print("="*80)
    
    print("Check the 'Status' column above.")
    print("If 'ON ✅' appears for VDS=1.0V, calibration is successful.")
    
    print("="*80)
    print()

if __name__ == '__main__':
    main()
