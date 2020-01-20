# for J23265+1230
procedure j23265
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_j23265", "slcproc.cl")
  copy ("dmag.cl_j23265", "dmag.cl")
  back
end
