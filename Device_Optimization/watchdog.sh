#!/bin/sh
# Poll the Sentaurus host every INTERVAL seconds, print one status line, and
# RESTART the queue worker if it has died.
#
# Written after a 5-hour stall on 2026-08-01.  Three things went wrong at once
# and each is guarded here:
#   * a non-converging deck crawled at 1e-15 s steps instead of failing, holding
#     the only license  -> queue_worker.sh now wraps sdevice in `timeout`;
#   * the persistent ssh tail used for notifications dropped silently, so the
#     stall was invisible -> this script re-connects on every poll instead of
#     holding one long-lived channel;
#   * killing the stalled job also killed the worker, because the worker's own
#     `csh -c "... sdevice <node>_des.cmd"` wrapper matches a pkill on the node
#     name -> this script restarts the worker whenever it is missing.
#
# Emitting a line every poll is deliberate: silence must never again be
# indistinguishable from progress.
#
#   sh watchdog.sh [INTERVAL_SECONDS]

ROOT="$(cd "$(dirname "$0")" && pwd)"
PW=$(cat "$ROOT/../Calibration/autocal/.pw")
HOST="du@103.28.121.70"
REMOTE="Sentaurus-files/Sami_Hozaifa/GAAFet"
PLINK="/c/Program Files/PuTTY/plink.exe"
INTERVAL="${1:-1800}"

probe() {
    "$PLINK" -batch -ssh -pw "$PW" "$HOST" "
        cd ~/$REMOTE || exit 1
        W=\$(pgrep -c -f queue_worker.sh)
        S=\$(pgrep -c -x sdevice)
        P=\$(grep -c . opt_outputs/QUEUE.txt 2>/dev/null)
        D=\$(grep -c 'END ' opt_outputs/QUEUE.log 2>/dev/null)
        L=\$(tail -1 opt_outputs/QUEUE.log 2>/dev/null)
        if [ \"\$W\" -eq 0 ]; then
            setsid sh queue_worker.sh > /dev/null 2>&1 < /dev/null &
            sleep 3
            W2=\$(pgrep -c -f queue_worker.sh)
            echo \"WORKER-RESTARTED (was down, now \$W2) done=\$D pending=\$P | \$L\"
        else
            echo \"ok worker=\$W sdevice=\$S done=\$D pending=\$P | \$L\"
        fi
    " 2>&1 | tail -1
}

while true; do
    OUT=$(probe)
    [ -z "$OUT" ] && OUT="PROBE-FAILED (ssh unreachable)"
    echo "$(date '+%H:%M:%S') $OUT"
    # stop once the queue is drained and nothing is left running
    case "$OUT" in
        *"pending=0"*sdevice=0*) echo "QUEUE-DRAINED"; exit 0 ;;
    esac
    sleep "$INTERVAL"
done
