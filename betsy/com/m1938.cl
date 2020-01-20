# for 2M1938+5609
procedure m1938
int dummy
begin
  cd ("/home/bigobs/betsy/com")
  del ("slcproc.cl, dmag.cl")
  copy ("slcproc.cl_2m1938+56", "slcproc.cl")
  copy ("dmag.cl_2m1938+56", "dmag.cl")
  back
end
