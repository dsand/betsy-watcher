procedure mdisplay (Filnam)

string Filnam     {prompt="name of image to be displayed"}

begin

   string filnam

   filnam = Filnam
   mscdisplay(filnam, frame=1, erase=no, border_erase=yes, fill=yes, \
     zscale=yes, contrast=0.25, ztrans="linear", >& "dev$null")
   zoom

end
