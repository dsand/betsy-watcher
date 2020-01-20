procedure j1920
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_j1920", "slcproc.cl")
  copy ("dmag.cl_j1920", "dmag.cl")
  back
end
