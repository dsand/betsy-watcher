procedure pg1336
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_pg1336", "slcproc.cl")
  copy ("dmag.cl_pg1336", "dmag.cl")
  back
end
