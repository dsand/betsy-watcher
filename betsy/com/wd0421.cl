procedure wd0421
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_wd0421", "slcproc.cl")
  copy ("dmag.cl_wd0421", "dmag.cl")
  back
end
