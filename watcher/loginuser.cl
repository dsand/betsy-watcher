# User package definitions
#
# select your favorite editor here
#
 set editor = emacs
# set editor = vi
 set printer = lp
 set cmbuflen = 6144000
 set min_lenuserarea = 128000
 set stdimage = imt1024
 set stdplot = lw17
 set imtype = "fits"

 task name = $/home/bigobs/.name >& "dev$null"
 task $bin1 = /home/bigobs/betsy/com/bin1.cl >& "dev$null"
 task $bin2 = /home/bigobs/betsy/com/bin2.cl >& "dev$null"
 task $bin3 = /home/bigobs/betsy/com/bin3.cl >& "dev$null"
 task $bin4 = /home/bigobs/betsy/com/bin4.cl >& "dev$null"
 task $d0 = /home/bigobs/betsy/com/d0.cl
 task merge4k = /home/bigobs/watcher/merge4k.cl >& "dev$null"
 task watcher = /home/bigobs/watcher/watcher.cl >& "dev$null"
 task $watcher_extra = /home/bigobs/watcher/watcher_extra.cl >& "dev$null"
 task auto_plot = /home/bigobs/watcher/auto_plot.cl >& "dev$null"
 task $postprocess = "$foreign" >& "dev$null"

 task $egrep $lpp $lpw $lpd $lwd $lwt $lp1 $lw1 $rm $rmdir $ssh $sftp $scp = "$foreign"
 task $tex $latex $xdvi $dvips $tar $gzip $gunzip $ds9 $firefox = "$foreign"
 task $acroread $calendar $ping $ftime $prstat $name $keepalive = "$foreign"
 task $nc $xpdf $f77 $gv = "$foreign"

 del tmp$iraf*

 unlearn watcher
 watcher.extra = "auto_plot"
#watcher.extra = ""

# load more packages

astutil
imred
bias
crutil
fitsutil
ctio

 display.frame.p_mode="h"
 imexam.frame.p_mode="h" 

 bin3

 postprocess on
 print ('by typing "watcher"')
 print ("")

keep
