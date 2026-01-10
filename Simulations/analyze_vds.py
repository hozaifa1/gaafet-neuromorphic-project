#!/usr/bin/env python3
"""Analyze VDS simulation results to check if bug is fixed"""

def parse_plt_file(filepath):
    """Parse Sentaurus PLT file and extract drain current vs gate voltage"""
    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()
    
    # Find the Data section
    data_start = None
    for i, line in enumerate(lines):
        if line.strip() == 'Data {':
            data_start = i + 1
            break
    
    if data_start is None:
        print(f"ERROR: Could not find Data section in {filepath}")
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
                'gate_V': values[i+17]
            }
            data_points.append(timestep)
    
    return data_points

def main():
    print("="*60)
    print("VERIFICATION: VDS BUG FIX (d0=1e5 -> 1e6)")
    print("="*60)
    print()
    
    # Parse both files
    data_1v = parse_plt_file('vds_1v.plt')
    data_1_5v = parse_plt_file('vds_1_5v.plt')
    
    if not data_1v or not data_1_5v:
        print("ERROR: Could not parse PLT files")
        return
    
    # Find current at gate voltage closest to 0.5V (VSG=-0.5V)
    target_vgate = 0.5
    
    best_1v = min(data_1v, key=lambda x: abs(x['gate_V'] - target_vgate))
    current_1v_ua = abs(best_1v['drain_I']) * 1e6
    
    best_1_5v = min(data_1_5v, key=lambda x: abs(x['gate_V'] - target_vgate))
    current_1_5v_ua = abs(best_1_5v['drain_I']) * 1e6
    
    print(f"VDS=1.0V @ Vgate={best_1v['gate_V']:.4f}V:")
    print(f"  Drain Current: {current_1v_ua:.2f} µA")
    print()
    print(f"VDS=1.5V @ Vgate={best_1_5v['gate_V']:.4f}V:")
    print(f"  Drain Current: {current_1_5v_ua:.2f} µA")
    print()
    
    ratio = current_1_5v_ua / current_1v_ua if current_1v_ua > 0 else 0
    diff_percent = (ratio - 1.0) * 100
    
    print(f"Ratio (VDS=1.5V / VDS=1.0V): {ratio:.4f}")
    print(f"Difference: {diff_percent:+.1f}%")
    print()
    print("="*60)
    
    if ratio > 1.0:
        print("STATUS: ✓✓✓ BUG FIXED! ✓✓✓")
        print(f"VDS=1.5V current is {diff_percent:.1f}% HIGHER than VDS=1.0V")
        print("Physics is now correct: higher drain voltage → higher current")
    elif ratio > 0.95:
        print("STATUS: ~ MOSTLY FIXED")
        print(f"Currents are nearly equal (within {abs(diff_percent):.1f}%)")
    else:
        print("STATUS: ✗✗✗ BUG STILL EXISTS ✗✗✗")
        print(f"VDS=1.5V current is {abs(diff_percent):.1f}% LOWER than VDS=1.0V")
        print("Need deeper investigation")
    
    print("="*60)
    print()
    print("Comparison to paper target (85 µA @ VSG=-0.5V, VDS=1.0V):")
    print(f"  VDS=1.0V: {current_1v_ua:.2f} µA ({current_1v_ua/85*100:.1f}% of target)")
    print(f"  VDS=1.5V: {current_1_5v_ua:.2f} µA ({current_1_5v_ua/85*100:.1f}% of target)")
    print()

if __name__ == '__main__':
    main()
