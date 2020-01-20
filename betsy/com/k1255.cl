procedure k1255
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_k1255", "slcproc.cl")
  copy ("dmag.cl_k1255", "dmag.cl")
  back
end
