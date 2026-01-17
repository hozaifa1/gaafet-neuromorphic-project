import os

def parse_plt(filepath):
    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()
    
    data_start = -1
    for i, line in enumerate(lines):
        if line.strip() == 'Data {':
            data_start = i + 1
            break
            
    if data_start == -1: return []
    
    values = []
    for line in lines[data_start:]:
        if line.strip() == '}': break
        values.extend([float(x) for x in line.split()])
        
    # Format: time(0), drain_V(1), drain_I(7), gate_V(17)
    points = []
    for i in range(0, len(values), 25):
        if i+24 >= len(values): break
        points.append({
            'vg': values[i+17],
            'id': abs(values[i+7])
        })
    return points

# Use absolute path
filepath = r'f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\read_n5_des.plt'
points = parse_plt(filepath)

print(f"{'Vgs (V)':<10} {'Id (A)':<15} {'Id (uA)':<15}")
print("-" * 40)
for p in points:
    # Print points specifically around the turn-on region
    # Filter for Vgs between -0.5 and 1.5 to see the shift
    if -0.5 <= p['vg'] <= 1.5:
        print(f"{p['vg']:<10.3f} {p['id']:<15.3e} {p['id']*1e6:<15.4f}")
