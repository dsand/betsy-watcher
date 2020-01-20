procedure wd1015
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_wd1015", "slcproc.cl")
  copy ("dmag.cl_wd1015", "dmag.cl")
  back
end
