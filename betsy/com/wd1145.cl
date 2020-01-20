procedure wd1145
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_wd1145", "slcproc.cl")
  copy ("dmag.cl_wd1145", "dmag.cl")
  back
end
