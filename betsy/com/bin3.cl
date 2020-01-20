procedure bin3

begin

  display.xmag = 0.75
  display.ymag = 0.75
  imcombine.statsec = "[100:1265,100:1265]"
  rimexam.radius = 10
  rimexam.buffer = 5
  rimexam.width = 6
  rimexam.rplot = 17
  rimexam.magzero = 25.
  simexam.ncolumns = 20
  simexam.nlines = 20

 print ("")
 print (" ==> binning is now set to 3x3 <==")
 print ("")

end
