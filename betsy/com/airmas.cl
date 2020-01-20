# task to run setairmass, setjd tasks, and add keywords STMIDDLE, HA (string), 
#   and HRS (real)

procedure airmas (images)

string	images		{prompt="image names"}
struct	*imagelist

begin
	string imgstring,imagel,imagen
        real dut,stime,x,hrs
        string dateobs,dateold,utmiddle,ut,st,ra,ha,s1
        int i,n

        cache imgets

        imgstring = images
        i = strlen(imgstring)
        if (substr(imgstring,i-3,i) != "fits") imgstring = imgstring//".fits"
        imagel = mktemp ("imgarm")
        files (imgstring, > imagel)

# set new date format back to old date format until setairmass task is Y2K'd
#	imagelist = imagel
#	while (fscan (imagelist,imagen) != EOF) {
#          imgets (imagen, "date-obs")
#          dateobs = imgets.value
#          if (substr(dateobs,5,5) == "-") {
#            dateold = substr(dateobs,9,10)//"/"//substr(dateobs,6,7)//"/"//substr(dateobs,3,4)
#            ccdhedit (imagen, "date-obs", dateold, type="string")
#          }
#        }

	imagelist = imagel
	while (fscan (imagelist,imagen) != EOF) {
           imagen = imagen//"[0]"

# run setairmass
          setairmass (imagen, intype="beginning", outtype="effective", \
              utmiddle="utmiddle", show=no, update=yes, override=yes)
# if utmiddle contains date and time, set it to contain time only
          imgets (imagen, "utmiddle")
          utmiddle = imgets.value
          utmiddle = substr(utmiddle,stridx("T",utmiddle)+1,strlen(utmiddle))
          ccdhedit (imagen, "utmiddle", utmiddle, type="string")
# run setjd
          setjd (imagen, time="utmiddle", exposure="", jd="", hjd="hjd", \
              ljd="", utdate=yes, uttime=yes, listonly=no)

# construct stmiddle and write in header
          imgets (imagen, "utmiddle")
          utmiddle = imgets.value
          imgets (imagen, "ut")
          ut = imgets.value
          dut = real(utmiddle)-real(ut)
          imgets (imagen, "st")
          st = imgets.value
          stime = real(st) + 1.00273791*dut
          if (stime < 0.0) stime += 24.0
          if (stime > 24.0) stime -= 24.0
          i = int(stime)
          st = str(i)//":"
          x = abs((stime - i)*60)
          i = int(x)
          s1 = str(i)
          if (strlen(s1) < 2) s1 = "0"//s1
          st = st//s1//":"
          x = (x - i)*600
          i = int(x)
          x = real(i)/10.0
          s1 = str(x)
          if (stridx(".",s1) == strlen(s1)) s1 = s1//"0"
          if (strlen(s1) < 4) s1 = "0"//s1
          st = st//s1
          ccdhedit (imagen, "stmiddle", st, type="string")

# calculate HA, write string, then put HA and decimal value HRS in header
          imgets (imagen, "ra")
          ra = imgets.value
          hrs = stime - real(ra)
          if (hrs < -12.0) hrs += 24.0
          if (hrs > 12.0) hrs -= 24.0
          ha = ""
          if (hrs < 0.0) {
            hrs = -1.*hrs
            ha = "-"
          }
          i = int(hrs)
          ha = ha//str(i)//":"
          x = abs((hrs - i)*60)
          i = int(x)
          s1 = str(i)
          if (strlen(s1) < 2) s1 = "0"//s1
          ha = ha//s1//":"
          x = (x - i)*600
          i = int(x)
          x = real(i)/10.0
          s1 = str(x)
          if (stridx(".",s1) == strlen(s1)) s1 = s1//"0"
          if (strlen(s1) < 4) s1 = "0"//s1
          ha = ha//s1
          if (substr(ha,1,1) == "-") hrs = -1.*hrs
          ccdhedit (imagen, "ha", ha, type="string")

          imgstring = "ST "//st//",  RA "//ra//",  HA "//ha//",  hrs "//hrs
#          print ((imgstring))
          ccdhedit (imagen, "hrs", hrs, type = "real")

	}
        imagel = ""
        delete ("imgarm*",verify=no)

end
