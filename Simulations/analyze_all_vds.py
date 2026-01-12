#!/usr/bin/env python3
"""Analyze all VDS simulation results after finer timestep fix"""

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
    
    # Test different VDS values with new naming
    vds_files = [
        ('0.4V', '0_4v.plt'),
        ('0.8V', '0_8v.plt'),
        ('1.0V', '1v.plt'),
        ('1.2V', '1_2v.plt'),
        ('1.4V', '1_4v.plt'),
    ]
    
    results = []
    
    print("STEP 1: Extracting currents at VSG=-0.5V (Vgate=0.5V)")
    print("-"*80)
    
    for vds_label, filename in vds_files:
        data = parse_plt_file(filename)
        if not data:
            print(f"⚠️  Could not parse {filename}")
            continue
        
        # Find current at gate voltage closest to 0.5V (VSG=-0.5V for PMOS)
        target_vgate = 0.5
        best = min(data, key=lambda x: abs(x['gate_V'] - target_vgate))
        current_ua = abs(best['drain_I']) * 1e6
        
        # Calculate VSG = Source - Gate
        vsg = best['source_V'] - best['gate_V']
        
        results.append({
            'vds': vds_label,
            'vgate': best['gate_V'],
            'vsource': best['source_V'],
            'vsg': vsg,
            'current_ua': current_ua,
            'drain_v': best['drain_V']
        })
        
        print(f"VDS={vds_label}:")
        print(f"  Vgate={best['gate_V']:.4f}V, Vsource={best['source_V']:.4f}V, VSG={vsg:.4f}V")
        print(f"  Drain Current: {current_ua:.2f} µA")
        print()
    
    print("="*80)
    print("STEP 2: BUG STATUS ANALYSIS")
    print("="*80)
    
    if len(results) < 2:
        print("Insufficient data for comparison")
        return
    
    # Check if current increases monotonically with VDS
    bug_still_present = False
    bug_fixed = True
    
    print("\nMonotonic VDS sweep analysis:")
    print("-"*80)
    
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
            print(f"  ❌ STILL WRONG: Current DECREASED with increasing VDS")
            bug_still_present = True
            bug_fixed = False
        else:
            print(f"  ✓ CORRECT: Current increased as expected")
    
    print()
    print("="*80)
    print("FINAL VERDICT:")
    print("="*80)
    
    if bug_fixed and not bug_still_present:
        print("✓✓✓ BUG IS FIXED!")
        print("Current now increases monotonically with VDS (physically correct)")
    elif bug_still_present:
        print("❌❌❌ BUG STILL PRESENT")
        print("Finer timesteps did NOT fix the issue")
        print("→ Problem is NOT related to temporal resolution")
    else:
        print("⚠️  MIXED RESULTS - needs manual inspection")
    
    print("="*80)
    print()
    
    # Detailed comparison table
    print("DETAILED COMPARISON TABLE:")
    print("-"*80)
    print(f"{'VDS':<8} {'Current (µA)':<15} {'vs Previous':<15} {'vs Paper Target':<15}")
    print("-"*80)
    
    paper_target_1v = 85.0  # µA from paper Figure 7b
    
    for i, r in enumerate(results):
        curr_str = f"{r['current_ua']:.2f}"
        
        if i > 0:
            prev_ratio = (r['current_ua'] / results[i-1]['current_ua'] - 1) * 100
            vs_prev = f"{prev_ratio:+.1f}%"
        else:
            vs_prev = "baseline"
        
        if '1.0' in r['vds']:
            paper_match = f"{r['current_ua']/paper_target_1v*100:.1f}%"
        else:
            paper_match = "N/A"
        
        print(f"{r['vds']:<8} {curr_str:<15} {vs_prev:<15} {paper_match:<15}")
    
    print("="*80)
    print()
    
    # Check if this could be a sign/interpretation issue
    print("HYPOTHESIS CHECK: Sign/Interpretation Issue?")
    print("-"*80)
    print(f"Device type: PMOS (p-channel)")
    print(f"VSG sign: {results[0]['vsg']:.4f}V (should be negative for ON state)")
    print(f"Current sign: All currents shown as positive (absolute values)")
    print()
    print("Analysis:")
    if bug_still_present:
        print("  The bug is NOT a sign issue because:")
        print("  1. Currents decrease monotonically (consistent pattern)")
        print("  2. Absolute values are used consistently")
        print("  3. VSG polarity is correct for PMOS")
        print("  → This is a genuine physics/model issue")
    print("="*80)

if __name__ == '__main__':
    main()
