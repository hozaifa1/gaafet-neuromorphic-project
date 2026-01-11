#!/usr/bin/env python3
"""Check if VDS bug exists across different drain voltages"""

def parse_plt_file(filepath):
    """Parse Sentaurus PLT file and extract drain current vs gate voltage"""
    try:
        with open(filepath, 'r', encoding='latin-1') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return None
    
    # Find the Data section
    data_start = None
    for i, line in enumerate(lines):
        if line.strip() == 'Data {':
            data_start = i + 1
            break
    
    if data_start is None:
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
    print("="*70)
    print("VDS BUG INVESTIGATION - Multi-Voltage Analysis")
    print("="*70)
    print()
    
    # Test different VDS values
    vds_files = [
        ('0.4V', '0_4plot.plt'),
        ('0.8V', '0_8plot.plt'),
        ('1.0V', '1plot.plt'),
    ]
    
    results = []
    
    for vds_label, filename in vds_files:
        data = parse_plt_file(filename)
        if not data:
            print(f"⚠️  Could not parse {filename}")
            continue
        
        # Find current at gate voltage closest to 0.5V (VSG=-0.5V for PMOS)
        target_vgate = 0.5
        best = min(data, key=lambda x: abs(x['gate_V'] - target_vgate))
        current_ua = abs(best['drain_I']) * 1e6
        
        results.append({
            'vds': vds_label,
            'vgate': best['gate_V'],
            'current_ua': current_ua,
            'drain_v': best['drain_V']
        })
        
        print(f"VDS={vds_label} @ Vgate={best['gate_V']:.4f}V:")
        print(f"  Drain Current: {current_ua:.2f} µA")
        print()
    
    print("="*70)
    print("ANALYSIS:")
    print("="*70)
    
    if len(results) < 2:
        print("Insufficient data for comparison")
        return
    
    # Check if current increases monotonically with VDS
    bug_detected = False
    for i in range(1, len(results)):
        prev = results[i-1]
        curr = results[i]
        
        vds_prev = float(prev['vds'].replace('V', ''))
        vds_curr = float(curr['vds'].replace('V', ''))
        
        ratio = curr['current_ua'] / prev['current_ua']
        diff_percent = (ratio - 1.0) * 100
        
        print(f"\n{prev['vds']} → {curr['vds']}:")
        print(f"  Current: {prev['current_ua']:.2f} µA → {curr['current_ua']:.2f} µA")
        print(f"  Change: {diff_percent:+.1f}%")
        
        if ratio < 1.0:
            print(f"  ❌ BUG DETECTED: Current DECREASED when VDS increased!")
            bug_detected = True
        else:
            print(f"  ✓ OK: Current increased as expected")
    
    print()
    print("="*70)
    
    if bug_detected:
        print("⚠️⚠️⚠️  VDS BUG EXISTS at tested voltage levels!")
    else:
        print("✓✓✓  NO BUG at tested voltage levels (0.4V, 0.8V, 1.0V)")
        print("     Bug likely manifests only at VDS ≥ 1.4V")
    
    print("="*70)
    print()
    
    # Show comparison to paper target
    print("Paper target: 85 µA @ VSG=-0.5V, VDS=1.0V")
    for r in results:
        if '1.0' in r['vds']:
            match_percent = r['current_ua'] / 85.0 * 100
            print(f"  Our VDS=1.0V: {r['current_ua']:.2f} µA ({match_percent:.1f}% of target)")
            if abs(match_percent - 100) < 5:
                print("  ✓ Excellent match!")
            break

if __name__ == '__main__':
    main()
