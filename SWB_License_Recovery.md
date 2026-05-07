# SWB License Recovery Guide

When the Sentaurus Workbench (swb) license is stuck and shows another user/session holding it, use this procedure to kill the orphaned process and recover the license.

## Quick Check — Which Session Has the License?

```sh
swb
```

If you get this output:
```
Currently no/not enough license(s) of type swb available. Users are:
        du at hostname1 on /dev/pts/1 (swb, 2021.12), started on Monday 5/4 at 0:36, 1 licenses(s)
```

The license is held by a different session (in this example, `/dev/pts/1`). Proceed to recovery.

---

## Step 1 — Check Active Sessions

```sh
w
```

Look at the output. If you only see your current session but the `swb` error showed a different `pts/X`, that session is orphaned and needs cleanup.

---

## Step 2 — Find the Stuck swb Process

```sh
ps -ef | grep -i -E 'swb|sentaurus|gtkwave' | grep -v grep
```

Look for processes like:
```
du        33623      1 86 May03 ?        13:06:34 /home/du/Sentaurus/sentaurus/V-2023.12/bin/../tcad/current/linux64/bin/swb
```

Note the **PID** (first number after `du` — in this example, `33623`).

---

## Step 3 — Kill the Orphaned Process

**Try graceful kill first:**
```sh
kill <PID>
```

Replace `<PID>` with the number from Step 2. Example:
```sh
kill 33623
```

Wait 10 seconds.

**Check if it's gone:**
```sh
ps -p <PID>
```

If it says "no such process" — success! Go to Step 4.

If the process is still there, force-kill it:
```sh
kill -9 <PID>
```

---

## Step 4 — Verify the License is Free

```sh
swb
```

You should now get the license and launch the GUI. If it still waits, the license server may need manual intervention — contact your IT/license admin.

---

## Fallback (If kill doesn't work)

If the process is truly stuck and `kill -9` doesn't release the license, the license server may need manual removal:

```sh
lmutil lmremove -c <license_file_path> swb du hostname1
```

This requires admin access and knowledge of your license file path. Contact your IT/license admin if you get here.
