#!/bin/csh -f
# run_endurance.csh -- Phase 1D H4 endurance + variability sweep driver
#
# Substitutes @V_pgm@, @tdr@, @tdrdat@, @plot@, @log@ in
# ../sdevice_simH4_endurance.cmd into per-node preprocessed cmd files,
# then runs sdevice on each sequentially.
# Master template stays untouched.
#
# Sweep: V_pgm in { 1.95  1.975  2.0  2.025  2.05 } V  (L5, 25 mV step)
# Tags:  endurance_v195  endurance_v1975  endurance_v200  endurance_v2025  endurance_v205
#
# Per-cycle protocol (20 cycles):
#   9-pulse fire (100ns hold) + 10ns ramp to -6V + 10us hold + 10ns ramp to -0.5V + 70us relax
#   => ~81.838 us/cycle  |  Total 20 cycles = ~1636.760 us sim time
#
# Acceptance:
#   M1:     |drift_c10->c20| <= 1.0 %/cycle on ID_p9
#   M2:     fire_ratio >= 1.5 every cycle
#   M-rest: |drift_c10->c20| <= 1.0 %/cycle on ID_end_relax
#   M8:     sigma/mu of fire_ratio across V_pgm nodes (c10..c20) <= 5 %
#
# 2026-05-19

source $HOME/.cshrc

set SCRIPT_DIR = `dirname $0`
cd $SCRIPT_DIR/..      # run from GAAFet/ so n1_msh.tdr + sdevice_gaafet_lif.par resolve

set TEMPLATE = sdevice_simH4_endurance.cmd
set OUTDIR   = endurance_outputs
set GRID     = n1_msh.tdr

if ( ! -f $TEMPLATE ) then
    echo "ERROR: $TEMPLATE not found in `pwd`"
    exit 1
endif
if ( ! -f $GRID ) then
    echo "ERROR: $GRID not found in `pwd`"
    exit 1
endif

set V_LIST   = ( 1.95  1.975  2.0  2.025  2.05 )
set TAG_LIST = ( endurance_v195  endurance_v1975  endurance_v200  endurance_v2025  endurance_v205 )
set N        = $#V_LIST

echo "===================================================================="
echo "Phase 1D H4 endurance sweep -- start `date '+%F %T'`"
echo "Working dir : `pwd`"
echo "Template    : $TEMPLATE"
echo "Output dir  : $OUTDIR"
echo "Nodes       : $N   (V_pgm = $V_LIST V)"
echo "===================================================================="

# write sweep index
echo "# Phase 1D H4 endurance sweep  (2026-05-19)" > $OUTDIR/sweep_index.txt
@ k = 1
while ( $k <= $N )
    echo "  $TAG_LIST[$k]  ->  V_pgm = $V_LIST[$k] V" >> $OUTDIR/sweep_index.txt
    @ k ++
end

@ i = 1
while ( $i <= $N )
    set V   = $V_LIST[$i]
    set TAG = $TAG_LIST[$i]
    set CMD = $OUTDIR/${TAG}_des.cmd
    set PLT = $OUTDIR/${TAG}_des.plt
    set TDR = $OUTDIR/${TAG}_des.tdr
    set LOG = $OUTDIR/${TAG}_des.log
    set RUN = $OUTDIR/${TAG}_runlog.txt

    echo ""
    echo "--------------------------------------------------------------------"
    echo "[`date '+%F %T'`]  node $i / $N   V_pgm = $V V   tag = $TAG"
    echo "--------------------------------------------------------------------"

    sed \
        -e "s|@tdr@|$GRID|g" \
        -e "s|@tdrdat@|$TDR|g" \
        -e "s|@plot@|$PLT|g" \
        -e "s|@log@|$LOG|g" \
        -e "s|@V_pgm@|$V|g" \
        $TEMPLATE > $CMD

    # guardrail: any @...@ left unsubstituted?
    set LEFT = `grep -c '@[A-Za-z_]*@' $CMD`
    if ( $LEFT != 0 ) then
        echo "  *** $LEFT unsubstituted placeholder(s) in $CMD -- aborting"
        grep -n '@[A-Za-z_]*@' $CMD
        exit 2
    endif

    sdevice $CMD >& $RUN
    set rc = $status
    if ( $rc != 0 ) then
        echo "  *** sdevice exited status $rc on $TAG"
        echo "  --- last 30 lines of $RUN ---"
        tail -n 30 $RUN
        echo "  *** aborting sweep at node $i"
        exit $rc
    endif
    echo "  ok   ($TAG done at `date '+%F %T'`)"
    @ i ++
end

echo ""
echo "===================================================================="
echo "All $N nodes complete -- `date '+%F %T'`"
echo "Outputs in $OUTDIR/{endurance_v195,endurance_v1975,endurance_v200,endurance_v2025,endurance_v205}_des.{plt,tdr,log}"
echo "===================================================================="
