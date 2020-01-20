# full version with observatory set to "mtbigelow"
# define with 
#   task stcoox = /home/bigobs/betsy/com/stcoox.cl

# use to calculate ST from UT in header, request and create keywords
# for RA, Dec, and Epoch

procedure stcoox (images,coords,ra,dec,epoch)

string        images                {prompt="image filenames"}
string        coords                {prompt="Use coords in header?"}
string        ra                    {prompt="RA"}
string        dec                   {prompt="Dec"}
string        epoch                 {prompt="Epoch"}

struct        *imagelist

begin
        
        string imgstring,imglist,line,imagen,ltime,UT0,UT,ST,s1,RA,Dec,Epoch
        string oldcoords
        real ut,x,rtime
        int i,j,year,mon,day,lastday[12]

        cache imgets

        lastday[4]=30; lastday[6]=30; lastday[9]=30; lastday[11]=30
        lastday[1]=31; lastday[3]=31; lastday[5]=31; lastday[7]=30
        lastday[8]=31; lastday[10]=31; lastday[12]=31; lastday[2]=28


# set observatory
#        observatory.observatory = "obspars"
#        observatory.observatory = "mmto"

        observatory.observatory = "mtbigelow"
#        observatory.longitude = 110:44:04.3
#        observatory.latitude = 32:24:59.3
#        observatory.altitude = 2510.
#        observatory.timezone = 7.

        oldcoords = substr(coords,1,1)
        Epoch = "2000.0"
        if (oldcoords != "y" && oldcoords != "Y") {
          print ("Enter the RA and Dec at epoch 2000.0 for this set of images")
          RA = ra
          Dec = dec
#          Epoch = epoch
        }

        imgstring = images
        i = strlen(imgstring)
        if (substr(imgstring,i-3,i) != "fits") imgstring = imgstring//".fits"
        imglist = mktemp ("imgst")
        files (imgstring, > imglist)
        imagelist = imglist
        while (fscan (imagelist,line) != EOF) {
            print ((line))
            imagen = line//"[0]"

# get the observed date (DATE-OBS)
            imgets (imagen, "date-obs")
            s1 = imgets.value
            year = int(substr(s1,1,4))
            if (year == 2004 || year == 2008 || year == 2012 || year == 2016 || year == 2020) lastday[2]=29
            if (year > 2023) stop
            mon = int(substr(s1,6,7))
            day = int(substr(s1,9,10))

# figure out what local time corresponds to the ut in the header
            imgets (imagen, "ut")
            UT0 = imgets.value
            i = stridx(":",UT0)
            j = int(substr(UT0,1,i-1))
# if ut < 7:00, then the local date is the previous day
            j = j - 7
            if (j < 0) {
              j = j + 24
              day = day - 1
            }
            if (day == 0) {
              mon = mon - 1
              if (mon == 0) {
                mon = 12
                year = year - 1
              }
              day = lastday[mon]
            }
            ltime = str(j)
            if (strlen(ltime) == 1) ltime = "0"//ltime
            ltime = ltime//substr(UT0,i,strlen(UT0))
            rtime = real(ltime)

# find st that corresponds to that local time and enter in header
            asttimes (year=year,month=mon,day=day,time=rtime,observatory=")_.observatory")  | field (fie="6,9") | scan (UT,ST)
            i = stridx(":",UT)
            s1 = substr(UT,1,i-1)
            if (strlen(s1) == 1) UT = "0"//UT
#            print ((UT0//"   "//UT)

            i = stridx(":",ST)
            s1 = substr(ST,1,i-1)
            if (strlen(s1) == 1) ST = "0"//ST
            hedit (imagen, "ST", ST, add=yes, verify=no, show=no, update=yes)
            ccdhedit (imagen, "ST", ST, type="string")

# create keywords for RA, Dec, and Epoch
            if (oldcoords == "y" || oldcoords == "Y") {
              imgets (imagen, "RA")
              s1 = imgets.value
              if (substr(s1,3,3) != ":") {
                RA = substr(s1,1,2)//":"//substr(s1,3,4)//":"//substr(s1,5,9)
               } else {
                RA = s1
              }
              imgets (imagen, "Dec")
              s1 = imgets.value
              if (substr(s1,4,4) != ":") {
                Dec = substr(s1,1,3)//":"//substr(s1,4,5)//":"//substr(s1,6,9)
               } else {
                Dec = s1
              }
               Epoch = "2000.0"
              imgets (imagen, "Epoch")
              Epoch = imgets.value
            }
#            hedit (imagen, "RA", RA, add=yes, verify=no, show=no, update=yes)
            ccdhedit (imagen, "RA", RA, type="string")
#            hedit (imagen, "DEC", Dec, add=yes, verify=no, show=no, update=yes)
            ccdhedit (imagen, "DEC", Dec, type="string")
            hedit (imagen, "EPOCH", Epoch, add=yes, verify=no, show=no, update=yes)
#            ccdhedit (imagen, "EPOCH", Epoch, type="real")
        }
        imglist = ""
        delete ("imgst*",verify=no)

end
