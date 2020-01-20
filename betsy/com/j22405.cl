# for J22405+5437
procedure j22405
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_j22405", "slcproc.cl")
  copy ("dmag.cl_j22405", "dmag.cl")
  back
end
