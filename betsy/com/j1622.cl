procedure j1622
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_std", "slcproc.cl")
  copy ("dmag.cl_j1622", "dmag.cl")
  back
end
