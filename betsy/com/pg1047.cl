procedure pg1047
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_std", "slcproc.cl")
  copy ("dmag.cl_pg1047", "dmag.cl")
  back
end
