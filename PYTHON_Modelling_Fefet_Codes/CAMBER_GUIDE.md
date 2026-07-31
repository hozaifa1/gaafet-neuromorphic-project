# Camber Cloud Integration Guide

This guide explains how to access and use **Camber** directly from your Windows environment to manage data, upload code, scale computations, and download results for the Python modeling codes in this directory.

---

## 1. Quick Verification
The Camber CLI is fully installed and authenticated as `hozaifa` (`20hozaifa02@gmail.com`) in your WSL Ubuntu subsystem, and mapped directly to your Windows host via a wrapper script.

You can run this directly in **Windows PowerShell** or **Command Prompt** to verify your access:
```powershell
camber me
```
Output:
```
======================User Information======================
Email:               20hozaifa02@gmail.com
Username:            hozaifa
Stash:               stash://hozaifa/
============================================================
```

---

## 2. Managing Code and Datasets (Camber Stash)
**Camber Stash** is the cloud file system where your scripts and data live before you run them on Camber's compute nodes.

### Uploading this Directory to Stash:
To upload all modeling codes to a folder named `gaafet-modeling` in your Stash:
```powershell
camber stash cp "F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\PYTHON_Modelling_Fefet_Codes" stash://hozaifa/gaafet-modeling/ -r
```

### Viewing Files on Stash:
```powershell
camber stash ls stash://hozaifa/gaafet-modeling/
```

### Deleting Unused Cloud Files:
```powershell
camber stash rm stash://hozaifa/gaafet-modeling/old_file.py
```

---

## 3. Running Modeling Codes (Camber Jobs)
If a training script (e.g., training a surrogate model) takes too long on your local machine, you can run it on Camber's scalable cloud compute resources (CPU/GPU nodes).

### Creating a Job:
To run `main_ecg_8c_warmup ().py` on a standard cloud node using your uploaded Stash files:
```powershell
camber job create --engine mpi --size small --cmd "python \"main_ecg_8c_warmup ().py\"" --path stash://hozaifa/gaafet-modeling/
```
*Note: `--size` can be set to `xxsmall`, `xsmall`, `small`, `medium`, `large`, `xlarge`, or `xxlarge` depending on model size and resource needs.*

### Checking Job Status:
When you create a job, it returns a **Job ID** (e.g., `2080`). To monitor it:
```powershell
camber job get 2080
```

---

## 4. Downloading Results
After your cloud job completes and saves outputs (e.g., model weights, plots, logs) inside your Stash path, download them back to Windows:
```powershell
camber stash cp stash://hozaifa/gaafet-modeling/outputs/ "F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\PYTHON_Modelling_Fefet_Codes\outputs" -r
```

---

## 5. Using Camber MCP in Claude (Desktop / CLI)
Since the `camber-mcp` connection is active, you can use the `@camber-mcp` tag to direct Claude to interact with your cloud space:
*   `@camber-mcp Chat with my agent and ask it to list my active jobs.`
*   `@camber-mcp create a new agent to analyze the surrogate model outputs.`

---

## 6. Field notes (verified 2026-06-26) — READ THIS BEFORE RUNNING JOBS

These are hard-won facts from actually driving Camber for compute jobs from this Windows box.
The MCP tools (`agents_chat`/`agents_create`) are for **AI agents**, not batch compute — for
running scripts use the **`camber job`** CLI below.

### 6.1 The `.bat` wrapper mangles quotes — launch jobs via `wsl` directly
`C:\Users\User\.local\bin\camber.bat` is literally:
```
@echo off
wsl -d Ubuntu bash -l -c "camber %*"
```
Calling `camber job create ... --cmd "python foo.py bar"` from PowerShell/cmd makes `%*` **strip
the inner quotes**, so the node receives `--cmd python` (everything after the first token is
dropped). Symptom: `camber job get` shows `Command: python` and `camber job logs` is empty.

**Fix — bypass the .bat and call wsl yourself with correct quoting** (single-quote the whole
remote command, double-quote the `--cmd` value inside):
```bash
wsl -d Ubuntu bash -lc 'camber job create --engine base --size xxsmall \
  --path stash://hozaifa/<dir>/ --cmd "CONFIG=A EPOCHS=30 python -u run.py"'
```
All `camber` commands work this way: `wsl -d Ubuntu bash -lc 'camber job get 22910'`, etc.

### 6.2 Stash paths from Windows must be the WSL mount path
`camber stash cp` runs inside WSL, so a Windows path (`F:\...` or `C:/...`) gives
*"source path does not exist"*. Use the `/mnt/<drive>/...` form:
```bash
wsl -d Ubuntu bash -lc "camber stash cp '/mnt/c/Users/User/.../mydir' stash://hozaifa/mydir/ -r"
```
(A trailing exit code 255 during upload is spurious — verify with `camber stash ls`; the files
land fine.)

### 6.3 Reading job output: use `camber job logs`, and make Python UNBUFFERED
- There is **no separate output sync**. The job's working dir is `/home/camber/workdir` (a copy of
  the input stash path); files written there are **NOT** copied back to the stash, and
  `stash://<user>/hpc-outputs/` stays empty. To get results back either **print them** (read via
  `camber job logs <id>`) or have the job itself `camber stash cp` them out.
- `camber job logs <id>` shows **stdout/stderr** — but Python block-buffers stdout when not a TTY,
  so a long-running job shows **nothing** until it exits. **Always run `python -u`** (or set
  `PYTHONUNBUFFERED=1`) so you can watch progress live.

### 6.4 Node environment + sizing
- `base` engine node = **Python 3.11**, 16 vCPU, has numpy/pandas/matplotlib; **missing torch,
  scikit-learn, spikingjelly** → `pip install` them in-job (use the CPU wheel index for torch:
  `pip install torch --index-url https://download.pytorch.org/whl/cpu`). A thin `run.py` that does
  the pip installs then `runpy.run_path("train.py")` keeps the `--cmd` simple.
- `--gpu` defaults false (CPU). Sizes: `xxsmall|xsmall|small|medium|large`.
- **Per-core clock is modest**: a sequential (Python-loop / BPTT-over-time) workload can run
  *slower per step than a local 4-thread i5* because the 16 cores don't parallelize a serial loop.
  Camber wins for **parallel / embarrassingly-parallel** work, not for one long serial loop. For
  serial loops, either vectorize first, run locally, or fan many configs out as parallel jobs.

### 6.5 No CLI job cancel
`camber job` only has `create | get | logs | list` — there is **no stop/cancel**. A submitted job
runs to completion and bills the whole time, so **validate cheaply (1–3 epochs / xxsmall) before
launching long jobs**, and cancel from the web dashboard if needed.

### 6.6 Job lifecycle cheatsheet
```bash
# submit
wsl -d Ubuntu bash -lc 'camber job create --engine base --size xxsmall \
  --path stash://hozaifa/gaafet-stage1/ --cmd "CONFIG=A EPOCHS=30 python -u run.py"'
# poll  (Status: SUBMITTED -> PENDING -> RUNNING -> COMPLETED/FAILED)
wsl -d Ubuntu bash -lc 'camber job get <id>'
# stream logs (stdout; needs python -u to be live)
wsl -d Ubuntu bash -lc 'camber job logs <id>'
# list recent jobs
wsl -d Ubuntu bash -lc 'camber job list'
```
