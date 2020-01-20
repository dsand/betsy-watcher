procedure bin1

begin

  display.xmag = 0.25
  display.ymag = 0.25
  imcombine.statsec = "[300:3800,300:3800]"
  rimexam.radius = 45
  rimexam.buffer = 10
  rimexam.width = 15
  rimexam.rplot = 50
  rimexam.magzero = 25.
  simexam.ncolumns = 60
  simexam.nlines = 60

 print ("")
 print (" ==> binning is now set to 1x1 <==")
 print ("")

end
