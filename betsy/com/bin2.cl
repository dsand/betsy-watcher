procedure bin2

begin

  display.xmag = 0.50
  display.ymag = 0.50
  imcombine.statsec = "[150:1900,150:1900]"
  rimexam.radius = 20
  rimexam.buffer = 7
  rimexam.width = 10
  rimexam.rplot = 25
  rimexam.magzero = 25.
  simexam.ncolumns = 30
  simexam.nlines = 30

 print ("")
 print (" ==> binning is now set to 2x2 <==")
 print ("")

end
