#!/bin/sh
# Sequential sdevice worker for the paper re-runs (PLOT_PLAN Part IV).
#
# The host has ONE sdevice license and it is shared, so every job in Phases 2-5
# has to run one at a time.  Driving that from Windows over ssh is hopeless --
# each plink connect costs tens of seconds and a dropped channel orphans a
# license-holding sdevice.  Instead this worker lives on the host, reads node
# names from opt_outputs/QUEUE.txt one line at a time, and runs them serially.
# New work is appended to QUEUE.txt at any time; the worker picks it up.
#
# Contract:
#   opt_outputs/QUEUE.txt   one node name per line; <node>_des.cmd must exist
#   opt_outputs/QUEUE.log   append-only progress log (START / END / rc)
#   opt_outputs/QUEUE.stop  create this file to stop the worker after the
#                           current job finishes
#
# Exits by itself after MAX_IDLE seconds with an empty queue, so it can never be
# left running forever by accident.

cd ~/Sentaurus-files/Sami_Hozaifa/GAAFet || exit 1
Q=opt_outputs/QUEUE.txt
LOG=opt_outputs/QUEUE.log
STOP=opt_outputs/QUEUE.stop
MAX_IDLE=14400        # 4 h of an empty queue and the worker retires
JOB_TIMEOUT=${JOB_TIMEOUT:-7200}   # 2 h hard cap per job (see below)
IDLE=0

touch "$Q"
echo "$(date '+%m-%d %H:%M:%S') WORKER-UP pid=$$" >> "$LOG"

while true; do
    if [ -f "$STOP" ]; then
        echo "$(date '+%m-%d %H:%M:%S') WORKER-STOP (stop file)" >> "$LOG"
        rm -f "$STOP"
        exit 0
    fi

    NODE=$(grep -v '^[[:space:]]*$' "$Q" 2>/dev/null | head -1)
    if [ -z "$NODE" ]; then
        IDLE=$((IDLE + 30))
        if [ "$IDLE" -ge "$MAX_IDLE" ]; then
            echo "$(date '+%m-%d %H:%M:%S') WORKER-STOP (idle ${MAX_IDLE}s)" >> "$LOG"
            exit 0
        fi
        sleep 30
        continue
    fi
    IDLE=0

    # pop the line we just read (first non-blank)
    grep -v '^[[:space:]]*$' "$Q" | tail -n +2 > "$Q.tmp" && mv "$Q.tmp" "$Q"

    if [ ! -f "${NODE}_des.cmd" ]; then
        echo "$(date '+%m-%d %H:%M:%S') SKIP $NODE (no ${NODE}_des.cmd)" >> "$LOG"
        continue
    fi

    echo "$(date '+%m-%d %H:%M:%S') START $NODE" >> "$LOG"
    START=$(date +%s)
    # Hard wall-clock cap. A non-converging job does not fail, it crawls: the
    # first RR-0 attempt collapsed to 1e-15 s steps and wrote a 71 MB log while
    # holding the only license. timeout turns that into rc=124 and lets the
    # queue move on instead of stalling the whole night on one bad deck.
    # Clear this node's previous .plt before running. The host accumulates output
    # across runs of the same node name, so a re-run that fails or times out part
    # way leaves a MIX of old and new files under one name -- and the mix looks
    # like a complete result. That happened to t14_end10: the 15-pulse train run
    # hit the 2 h cap before reaching cycle 10, the previous single-pulse run's
    # w10_* files survived, and the two got averaged into one endurance CSV.
    rm -f opt_outputs/*_${NODE}_des.plt "opt_outputs/${NODE}_des.plt"

    timeout -s KILL "$JOB_TIMEOUT" csh -c "source ~/.cshrc && sdevice ${NODE}_des.cmd"         > "opt_outputs/${NODE}_runlog.txt" 2>&1
    RC=$?
    ELAPSED=$(( $(date +%s) - START ))
    NPLT=$(ls opt_outputs/*${NODE}_des.plt 2>/dev/null | wc -l)
    echo "$(date '+%m-%d %H:%M:%S') END   $NODE rc=$RC ${ELAPSED}s plt=$NPLT" >> "$LOG"
done
