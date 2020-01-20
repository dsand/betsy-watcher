procedure css
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_css", "slcproc.cl")
  copy ("dmag.cl_css", "dmag.cl")
  back
end
