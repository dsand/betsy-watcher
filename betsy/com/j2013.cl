# for J20133+0928
procedure j2013
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_f46", "slcproc.cl")
  copy ("dmag.cl_f46", "dmag.cl")
  back
end
