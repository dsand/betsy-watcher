procedure mexamine (Filnam)

string Filnam     {prompt="name of image to be examined"}

begin

   string filnam

   filnam = Filnam
   if (filnam != "") {
     mdisplay(filnam)
     zoom
   }
   mscexamine 

end

