#!/bin/csh -f
source $HOME/.cshrc
cd /home/du/Sentaurus-files/Sami_Hozaifa/GAAFet
set LOG = h6_outputs/h6_sweep.log
echo "===== H6 sweep start `date` =====" >! $LOG
foreach VPGM (1.950 1.975 2.000 2.025 2.050)
  set TAG = h6_vpgm${VPGM}
  echo "[$TAG] start `date`" >>& $LOG
  sdevice h6_outputs/${TAG}_des.cmd >& h6_outputs/${TAG}_runlog.txt
  echo "[$TAG] done status=$status `date`" >>& $LOG
end
echo "===== H6 sweep done `date` =====" >>& $LOG
