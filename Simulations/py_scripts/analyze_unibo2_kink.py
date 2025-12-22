import numpy as np
import matplotlib.pyplot as plt
import re

def parse_plt_file(filename):
    """Parse Sentaurus DF-ISE PLT file and extract I-V data"""
    with open(filename, 'r', errors='ignore') as f:
        lines = f.readlines()
    
    # Find where Data section starts
    data_start = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('Data {'):
            data_start = i + 1
            break
    
    if data_start == -1:
        print(f"Could not find Data section in {filename}")
        return None, None
    
    # Parse data - each time step has multiple lines
    # Based on the Info section, we have 24 datasets (1 time + 23 contact values)
    # Format: time, then 8 drain values, 8 source values, 8 gate values
    # We want gate voltage (gate OuterVoltage) and drain current (drain TotalCurrent)
    
    vg_data = []
    id_data = []
    
    i = data_start
    while i < len(lines):
        line = lines[i].strip()
        if line == '}' or line == '':
            i += 1
            continue
        
        # Try to read this as a data block
        try:
            # Read all values in this block
            values = []
            while i < len(lines):
                line = lines[i].strip()
                if line == '}':
                    break
                if line == '':
                    i += 1
                    continue
                
                parts = line.split()
                for part in parts:
                    try:
                        values.append(float(part))
                    except ValueError:
                        pass
                
                i += 1
                
                # Check if we have enough values for one time step (25 values total)
                if len(values) >= 25:
                    break
            
            if len(values) >= 25:
                # time = values[0]
                # drain_contact values: [1-8]
                # source_contact values: [9-16]
                # gate_contact values: [17-24]
                
                gate_outer_voltage = values[17]  # gate OuterVoltage
                drain_total_current = values[7]  # drain TotalCurrent
                
                vg_data.append(gate_outer_voltage)
                id_data.append(abs(drain_total_current))
        except:
            i += 1
            continue
    
    return np.array(vg_data), np.array(id_data)

def calculate_kink_metric(vg, id_log):
    """Calculate kink effect metric by looking at derivative changes"""
    # Calculate first derivative (transconductance in log scale)
    dvg = np.diff(vg)
    did = np.diff(id_log)
    
    # Avoid division by zero
    dvg[dvg == 0] = 1e-10
    derivative = did / dvg
    
    # Calculate second derivative to find inflection points
    second_deriv = np.diff(derivative)
    
    # Kink metric: standard deviation of second derivative in saturation region
    # Higher std means more "kinking" behavior
    if len(second_deriv) > 10:
        # Focus on latter half where saturation happens
        sat_region = second_deriv[len(second_deriv)//2:]
        kink_metric = np.std(sat_region)
        max_second_deriv = np.max(np.abs(sat_region))
    else:
        kink_metric = 0
        max_second_deriv = 0
    
    return kink_metric, max_second_deriv

# Parse both files
print("Parsing 1e5 PLT file...")
vg_1e5, id_1e5 = parse_plt_file(r'f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\dod1_1e5.plt')

print("Parsing 1e6 PLT file...")
vg_1e6, id_1e6 = parse_plt_file(r'f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\dod1_1e6.plt')

if vg_1e5 is None or vg_1e6 is None:
    print("ERROR: Could not parse one or both files")
    exit(1)

print(f"\n1e5 data points: {len(vg_1e5)}")
print(f"1e6 data points: {len(vg_1e6)}")

# Calculate kink metrics
id_log_1e5 = np.log10(id_1e5 + 1e-20)  # Avoid log(0)
id_log_1e6 = np.log10(id_1e6 + 1e-20)

kink_1e5, max_deriv_1e5 = calculate_kink_metric(vg_1e5, id_log_1e5)
kink_1e6, max_deriv_1e6 = calculate_kink_metric(vg_1e6, id_log_1e6)

print(f"\n=== KINK EFFECT ANALYSIS ===")
print(f"1e5 kink metric (std of 2nd derivative): {kink_1e5:.6f}")
print(f"1e6 kink metric (std of 2nd derivative): {kink_1e6:.6f}")
print(f"1e5 max 2nd derivative: {max_deriv_1e5:.6f}")
print(f"1e6 max 2nd derivative: {max_deriv_1e6:.6f}")

if kink_1e5 > kink_1e6:
    print(f"\n✓ EXPECTED: 1e5 shows LARGER kink effect (ratio: {kink_1e5/kink_1e6:.2f}x)")
else:
    print(f"\n✗ UNEXPECTED: 1e6 shows larger or equal kink effect")

# Create comparison plot
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# Linear scale
ax1.plot(vg_1e5, id_1e5, 'b-', linewidth=2, label='1e5 (higher kink)', alpha=0.7)
ax1.plot(vg_1e6, id_1e6, 'r-', linewidth=2, label='1e6 (lower kink)', alpha=0.7)
ax1.set_xlabel('Gate Voltage (V)', fontsize=12)
ax1.set_ylabel('Drain Current (A)', fontsize=12)
ax1.set_title('I-V Characteristics - Linear Scale', fontsize=13, fontweight='bold')
ax1.legend(fontsize=10)
ax1.grid(True, alpha=0.3)

# Log scale
ax2.semilogy(vg_1e5, id_1e5, 'b-', linewidth=2, label='1e5 (higher kink)', alpha=0.7)
ax2.semilogy(vg_1e6, id_1e6, 'r-', linewidth=2, label='1e6 (lower kink)', alpha=0.7)
ax2.set_xlabel('Gate Voltage (V)', fontsize=12)
ax2.set_ylabel('Drain Current (A)', fontsize=12)
ax2.set_title('I-V Characteristics - Log Scale', fontsize=13, fontweight='bold')
ax2.legend(fontsize=10)
ax2.grid(True, alpha=0.3, which='both')

plt.tight_layout()
plt.savefig(r'f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\output_curves\unibo2_comparison_1e5_vs_1e6.png', 
            dpi=150, bbox_inches='tight')
print(f"\nPlot saved: output_curves/unibo2_comparison_1e5_vs_1e6.png")

# Create derivative plot to visualize kink
fig, ax = plt.subplots(figsize=(10, 6))

# Calculate and plot transconductance (derivative)
gm_1e5 = np.diff(id_log_1e5) / np.diff(vg_1e5)
gm_1e6 = np.diff(id_log_1e6) / np.diff(vg_1e6)

ax.plot(vg_1e5[:-1], gm_1e5, 'b-', linewidth=2, label='1e5 transconductance', alpha=0.7)
ax.plot(vg_1e6[:-1], gm_1e6, 'r-', linewidth=2, label='1e6 transconductance', alpha=0.7)
ax.set_xlabel('Gate Voltage (V)', fontsize=12)
ax.set_ylabel('d(log Id)/dVg', fontsize=12)
ax.set_title('Transconductance Comparison (Kink Visibility)', fontsize=13, fontweight='bold')
ax.legend(fontsize=10)
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(r'f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\output_curves\unibo2_transconductance.png', 
            dpi=150, bbox_inches='tight')
print(f"Plot saved: output_curves/unibo2_transconductance.png")

# Summary statistics
print(f"\n=== SUMMARY STATISTICS ===")
print(f"1e5: Vg range [{vg_1e5.min():.2f}, {vg_1e5.max():.2f}] V")
print(f"1e6: Vg range [{vg_1e6.min():.2f}, {vg_1e6.max():.2f}] V")
print(f"1e5: Id range [{id_1e5.min():.2e}, {id_1e5.max():.2e}] A")
print(f"1e6: Id range [{id_1e6.min():.2e}, {id_1e6.max():.2e}] A")

plt.show()
