procedure hd
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_hd265435", "slcproc.cl")
  copy ("dmag.cl_hd265435", "dmag.cl")
  back
end
