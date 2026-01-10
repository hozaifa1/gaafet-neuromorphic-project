# Sentaurus Workbench (SWB) - VDS Parameter Sweep Guide

## Objective
Run VDS=1.0V and VDS=1.5V simulations simultaneously in Sentaurus Workbench UI to generate two separate output files.

## Reference
Based on:
- **Tutorial:** https://ghzphy.github.io/Sentaurus_Training/swb/swb_04.html (Section 4.1-4.2)
- **Example Project:** `Sentaurus/sentaurus/V-2023.12/tcad/V-2023.12/Applications_Library/GettingStarted/swb/SimpleMOS/`
- **Example shows:** Parameter `Vd` with values `{0.05 1.0}` creating 2 experiments

---

## Step-by-Step UI Process in Sentaurus Workbench

### Step 1: Open Your Project in SWB

1. Launch Sentaurus Workbench:
   ```bash
   cd "f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations"
   swb
   ```

2. Either:
   - Create new project: `File > New Project`
   - Open existing: `File > Open Project`

3. Add your simulation files to the project if not already present:
   - Right-click in project area
   - Choose tool type (e.g., `Sentaurus Device`)
   - Add your `sdevice_des.cmd` file

---

### Step 2: Add VDS Parameter

**UI Actions:**

1. **Locate the Parameter Area:**
   - Look for gray boxes immediately below your tool icons in the project table

2. **Add Parameter:**
   - **Method A:** Menu bar → `Parameter > Add Parameter/Values`
   - **Method B:** Right-click the gray box below the `Sentaurus Device` icon → Choose `Add Parameter/Values`

3. **In the "Add Parameter/Values" Dialog Box:**
   - **Parameter Name:** `Vds`
   - **Default Value:** `1.0`
   - **Comment (optional):** `Drain voltage for hysteresis sweep`
   - Click **OK**

**What you'll see:**
- A new row appears with parameter name `Vds`
- Virtual nodes (light blue) appear representing future splits
- Default value `1.0` is shown

---

### Step 3: Modify sdevice_des.cmd to Use Parameter

**Before running, you need to replace the hardcoded voltage with the parameter:**

1. **Open your command file** (in SWB or external editor)

2. **Find the Electrode section** (around line 21):
   ```tcad
   { Name="drain_contact"  Voltage= 1.0  DistResist=1.5e-8 }
   ```

3. **Replace with parameter placeholder:**
   ```tcad
   { Name="drain_contact"  Voltage= @Vds@  DistResist=1.5e-8 }
   ```

4. **Save the file**

**Note:** The `@Vds@` syntax is how SWB substitutes parameter values during preprocessing.

---

### Step 4: Add Multiple Values for VDS Parameter

**UI Actions:**

1. **Right-click on the parameter name `Vds`** (in the parameter row)

2. **Choose `Add Parameter/Values`** from context menu

3. **In the "Add Parameter/Values" Dialog Box:**
   - **Method:** Select `List`
   - **List of Values:** Enter:
     ```
     1.0 1.5
     ```
     (space-separated or one per line)
   - **Sorting:** Leave default or select `Ascending`
   - Click **OK**

**What you'll see:**
- The project tree expands
- Two experiments appear (one for each VDS value)
- Node numbers may need cleanup

---

### Step 5: Clean Up Project Tree

**UI Actions:**

1. **Menu bar** → `Project > Operations > Clean Up`
   - **Keyboard shortcut:** `Ctrl+L`

2. **In "Cleanup Options" Dialog Box:**
   - ✅ Check `Renumber the Tree`
   - Click **OK**

**What this does:**
- Renumbers all nodes sequentially
- Removes unused virtual nodes
- Organizes the simulation tree properly

3. **Optional: View node numbers**
   - Press **F9** key to toggle node number display

---

### Step 6: Preprocess the Project

**UI Actions:**

1. **Menu bar** → `Project > Operations > Preprocess`
   - **Keyboard shortcut:** `Ctrl+P`

2. You'll be prompted to save if you haven't already

3. **Preprocessor Log dialog** appears showing:
   - Parameters being replaced
   - Files being generated for each experiment
   - Any errors/warnings

**What this does:**
- Creates separate input files for each experiment
- Replaces `@Vds@` with actual values (1.0, 1.5)
- Validates the setup

**Verify:**
- Use **Node Explorer** to inspect generated files
- Check that `Voltage= 1.0` appears in experiment 1
- Check that `Voltage= 1.5` appears in experiment 2

---

### Step 7: Run Both Simulations

**UI Actions:**

1. **Save project:**
   - `File > Save` or `Ctrl+S`

2. **Run all experiments:**
   - **Method A:** `Project > Run Project`
   - **Method B:** Click the "Run" button (play icon) in toolbar
   - **Method C:** Right-click project root → `Run`

3. **In "Run Project" Dialog Box:**
   - **Select which experiments to run:**
     - ✅ Check both VDS=1.0V and VDS=1.5V experiments
   - **Execution mode:**
     - Select `Run locally` (for single machine)
     - Or configure distributed computing if available
   - Click **OK**

**Note:** SWB automatically preprocesses again before running.

**What happens:**
- Both simulations run (may be sequential or parallel depending on licenses)
- Progress bars show status for each experiment
- Output files generated in separate node directories

---

### Step 8: Access Output Files

**After simulations complete:**

1. **Navigate to output directories:**
   ```
   Simulations/
   ├── n_node1/  (VDS=1.0V)
   │   ├── n2_des.log
   │   ├── n2_des.plt
   │   └── ...
   └── n_node2/  (VDS=1.5V)
       ├── n2_des.log
       ├── n2_des.plt
       └── ...
   ```

2. **In SWB UI:**
   - Right-click each node
   - Choose `Show Output Folder` to open directory
   - Or use **Node Explorer** to view files directly

3. **Copy outputs with meaningful names:**
   ```powershell
   Copy-Item Simulations/n_node1/n2_des.plt vds_1v.plt
   Copy-Item Simulations/n_node2/n2_des.plt vds_1_5v.plt
   ```

---

## Project Tree Structure (Example)

```
Project Root
├── Parameter: Vds = {1.0, 1.5}
├── Tool: Sentaurus Device
│   ├── Experiment 1: Vds=1.0
│   │   └── Output: n2_des.plt (VDS=1.0V results)
│   └── Experiment 2: Vds=1.5
│       └── Output: n2_des.plt (VDS=1.5V results)
```

---

## Key SWB Concepts from Tutorial

### Parameter Definition (from SimpleMOS example)
```tcl
# In gtree.dat:
sdevice Vd "0.05" {0.05 1.0}
```
- `Vd` = parameter name
- `"0.05"` = default value
- `{0.05 1.0}` = list of values (creates 2 experiments)

### Parameter Usage in Command Files
```tcad
Goal { Name="drain" Voltage=@Vd@ }
```
- `@Vd@` is replaced with actual value during preprocessing

### Multiple Parameters Create Matrix
If you add:
- Parameter 1: M values
- Parameter 2: N values
- **Total experiments:** M × N

---

## Troubleshooting

### Issue: "Parameter not found" during preprocessing
**Solution:** Check that:
1. Parameter name in UI matches placeholder: `@Vds@`
2. Spelling/capitalization is exact
3. File was saved after adding `@Vds@`

### Issue: Only one simulation runs
**Solution:** 
1. Verify both values are listed in parameter: `1.0 1.5`
2. Check both experiments are enabled (checked) in project tree
3. Clean up and preprocess again

### Issue: Wrong voltage in output
**Solution:**
1. Use Node Explorer to inspect preprocessed input file
2. Verify `@Vds@` was replaced correctly
3. Check output is from correct node directory

---

## Current Project Status

**Working configuration:**
- ✅ AreaFactor=4.0 gives correct 87 µA @ VSG=-0.5V, VDS=1.0V
- ❌ VDS bug persists: VDS=1.5V shows only 55 µA (should be > 87 µA)
- 🔧 Temperature equations confirmed incompatible with FE polarization

**After setting up SWB sweep:**
You'll be able to run both VDS simulations simultaneously and compare outputs directly to diagnose the VDS anomaly root cause.
