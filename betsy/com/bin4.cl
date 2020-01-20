procedure bin4

begin

  display.xmag = 1.0
  display.ymag = 1.0
  imcombine.statsec = "[75:950,25:590]"
  rimexam.radius = 12
  rimexam.buffer = 4
  rimexam.width = 6
  rimexam.rplot = 14
  rimexam.magzero = 26.8
  simexam.ncolumns = 15
  simexam.nlines = 15

 print ("")
 print (" ==> binning is now set to 4x4 <==")
 print ("")

end
