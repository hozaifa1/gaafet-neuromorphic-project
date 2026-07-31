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
    csh -c "source ~/.cshrc && sdevice ${NODE}_des.cmd" > "opt_outputs/${NODE}_runlog.txt" 2>&1
    RC=$?
    ELAPSED=$(( $(date +%s) - START ))
    NPLT=$(ls opt_outputs/*${NODE}_des.plt 2>/dev/null | wc -l)
    echo "$(date '+%m-%d %H:%M:%S') END   $NODE rc=$RC ${ELAPSED}s plt=$NPLT" >> "$LOG"
done
