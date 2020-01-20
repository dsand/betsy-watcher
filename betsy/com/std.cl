procedure std
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_std", "slcproc.cl")
  copy ("dmag.cl_std", "dmag.cl")
  back
end
