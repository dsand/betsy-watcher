procedure wd0507
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_wd0507", "slcproc.cl")
  copy ("dmag.cl_wd0507", "dmag.cl")
  back
end
