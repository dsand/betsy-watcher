# inputs a series of extended fits file calibration images (100 biases + 
# Nx100 flats + 100 biases) created by the AZCamTool multi-exposure sequence,
# turns them into normal fits images, and combines them

# Uses merge4k to correct for crosstalk and merge each extended
# fits image into a single normal fits image.   Then it combines
# the biases, subtracts the combined bias.fits image from the 
# individual flats, and outputs combined bias and flat images in 
# sets of 100.  First set of bias images is assumed to be numbered 
# 0000 to 0099, first 100 flats numbered 0100 to 0199, etc.

procedure calred (msc,calname,bias1,flatroot)

string msc      {prompt="Is mscred package loaded? "}
string calname  {prompt="Root name for the series of calibration images? "}
string bias1    {prompt="Name of first combined bias image? "}
string flatroot {prompt="Name of first combined flat image? "}

begin
     string mchk,cname,rawdir,s0,s1,ext,ityp,exp,bimg1,bimg2,f1,fimg
     string b1,b2,f0,froot,fout,filt,insfilt,bin
     string biassec,datasec,datasec2,statsec,statsec1,statsec2,rstatsec
     int i,j,nlast,fnum

     cache imgets

     print ("")
#     mchk = msc
     mchk = "y"
     if (substr(mchk,1,1) != "y" && substr(mchk,1,1) != "Y") \
       error(1,"Load mscred package before running calred")

     cname = calname
     i = strlen(cname)
     if (substr(cname,i,i) != ".") cname = cname//"."

# check that the specified input calibration images exist
     if (access("xxx")) delete ("xxx")
     files ((cname//"????.fits"), >"xxx")
     s0 = ""
     head ("xxx", nlines=1) | scan (s0)
     i = strlen(s0)
     if(i == 0 || substr(s0,i-4,i) != ".fits") \ 
        error(1,"No fits files with numbered extensions exist for this root name")

# check binning and define image sections
       imgets ((s0//"[0]"), "ccdsum")
       bin = imgets.value
       if (substr(bin,1,3) == "1 1") {
         biassec = "[2054:2067,1:4096]"
         datasec = "[1:2048,1:4096]"
         datasec2 = "[2049:4096,1:4096]"
         statsec = "[600:3500,600:3500]"
         statsec1 = "[300:1800,600:3500[]"
         statsec2 = "[2054:2067,600:3500]"
         rstatsec = "[2297:3797,600:3500]"
        } else if (substr(bin,1,3) == "2 2") {
         biassec = "[1030:1043,1:2048]"
         datasec = "[1:1024,1:2048]"
         datasec2 = "[1025:2048,1:2048]"
         statsec = "[300:1750,300:1750]"
         statsec1 = "[150:900,300:1750]"
         statsec2 = "1030:1043[,300:1750]"
         rstatsec = "[1149:1899,300:1750]"
        } else if (substr(bin,1,3) == "3 3") {
         biassec = "[688:701,1:1365]"
         datasec = "[1:682,1:1365]"
         datasec2 = "[683:1364,1:1365]"
         statsec = "[200:1150,200:1150]"
         statsec1 = "[100:600,200:1150]"
         statsec2 = "[688:701,200:1150]"
         rstatsec = "[765:1265,200:1150]"
        } else if (substr(bin,1,3) == "4 4") {
         biassec = "[518:531,1:1024]"
         datasec = "[1:512,1:1024]"
         datasec2 = "[513:1024,1:1024]"
         statsec = "[150:875,150:875]"
         statsec1 = "[75:450,150:875]"
         statsec2 = "[518:531,150:875]"
         rstatsec = "[575:950,150:875]"
       }

# check that first 100 images (0000 to 0099) are biases
     if (int(substr(s0,i-8,i-5)) != 0) error(1,"first image isn't numbered 0000")
     for (j=0; j<100; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       if (!access (s1)) error(1,(s1//" doesn't exist"))
       imgets ((s1//"[0]"), "imagetyp")
       ityp = imgets.value
       if (ityp != "zero") error(1,(s1//" isn't a bias"))
     }
     print ("")
     print ((s0//" to "//s1//" are zeros"))
     i = strlen(s1)
     bimg1 = substr(s1,1,i-7)//"??.fits"

# check that middle images (100 to nlast-100) are flats
     tail ("xxx", nlines=1)  | scan (s1)
     delete ("xxx")
     i = strlen(s1)
     nlast = int(substr(s1,i-8,i-5))
     for (j=100; j<=nlast-100; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       if (j == 100) {
         s0 = s1
         imgets ((s1//"[0]"), "exptime")
         exp = int(imgets.value)
         imgets ((s1//"[0]"), "filter")
         filt = imgets.value
         insfilt =filt
         i = strlen(filt)
         if (substr(filt,1,7) == "Bessell") filt = substr(filt,i,i)
         if (substr(filt,1,7) == "Harris") filt = substr(filt,i,i)
         if (substr(filt,1,7) == "Arizona") filt = substr(filt,i,i)
         if (substr(filt,1,4) == "WFPC") filt = "W"//substr(filt,i-2,i)
         if (substr(filt,1,6) == "Schott") filt = "S"
       }
       if (!access (s1)) error(1,(s1//" doesn't exist"))
       imgets ((s1//"[0]"), "imagetyp")
       ityp = imgets.value
       if (ityp != "flat") error(1,(s1//" isn't a flat"))
     }
     print ((s0//" to "//s1//" are "//exp//" sec "//filt//" flats"))
     i = strlen(s1)
     f1 = substr(s1,1,i-8)

# check that last 100 images (nlast-99 to nlast) are biases
     for (j=nlast-99; j<=nlast; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       if (j == nlast-99) s0 = s1
       if (!access (s1)) error(1,(s1//" doesn't exist"))
       imgets ((s1//"[0]"), "imagetyp")
       ityp = imgets.value
       if (ityp != "zero") error(1,(s1//" isn't a bias"))
      }
      print ((s0//" to "//s1//" are zeros"))
      i = strlen(s1)
      bimg2 = substr(s1,1,i-7)//"??.fits"
      print ("")

# get names for output images
      b1 = bias1

      s0 = flatroot
      i = strlen(s0)
      froot = substr(s0,1,i-1)
      fnum = int(substr(s0,i,i))
      if (substr(s0,i-2,i-2) == "1") {
        froot = substr(s0,1,i-2)
        fnum = fnum + 10
       } else if (substr(s0,i-2,i-2) == "2") {
        froot = substr(s0,1,i-2)
        fnum = fnum + 20
      }

      print ("")

# run imstats on original images
     imstat.fields = "image,mean,midpt,stddev,min,max"
     imstat ((bimg1//"[1]"//statsec1), >>"b1.stats")
     imstat ((bimg1//"[1]"//statsec2), >>"b1.stats")
     imstat ((bimg1//"[2]"//statsec1), >>"b2.stats")
     imstat ((bimg1//"[2]"//statsec2), >>"b2.stats")

     imstat ((bimg2//"[1]"//statsec1), >>"b1.stats")
     imstat ((bimg2//"[1]"//statsec2), >>"b1.stats")
     imstat ((bimg2//"[2]"//statsec1), >>"b2.stats")
     imstat ((bimg2//"[2]"//statsec2), >>"b2.stats")

     i = (nlast-99)/100 - 1
     for (j=1; j<=i; j+=1) {
       fimg = f1//str(j)//"??.fits"
       imstat ((fimg//"[1]"//statsec1), >>"f1.stats")
       imstat ((fimg//"[1]"//statsec2), >>"f1.stats")
       imstat ((fimg//"[2]"//statsec1), >>"f2.stats")
       imstat ((fimg//"[2]"//statsec2), >>"f2.stats")
     }

# use merge4k to correct for crosstalk, convert extended fits to normal 
# and save original extended images in a subdirectory called raw
     for (j=0; j<=nlast; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       merge4k (s1)
     }

# combine biases
     i = strlen(b1)
     if (substr(b1,i-4,i) != ".fits") b1 = b1//".fits"
     i = strlen(b1)
     if (access (b1)) delete ((b1))
     imcombine (bimg1, b1, combine="median", reject="avsigclip", outtype="real", \
       scale="none", zero="median", weight="none", statsec=statsec, \
       >>"flog")
     imstat ((b1//statsec1))
     print ("")
     imstat ((b1//rstatsec))
     print ("")

     j = stridx(".",b1)
     s0 = substr(b1,1,j-2)
     j = int(substr(b1,j-1,j-1))+1
     b2 = s0//str(j)//substr(b1,i-4,i)
     if (access (b2)) delete ((b2))
     imcombine (bimg2, b2, combine="median", reject="avsigclip", outtype="real", \
       scale="none", zero="median", weight="none", statsec=statsec, \
       >>"flog")
     imstat ((b2//statsec1))
     print ("")
     imstat ((b2//rstatsec))
     print ("")

     if (access("bias.fits")) delete ("bias.fits")
     imcombine ((bimg1//","//bimg2), "bias.fits", combine="median", \
       reject="avsigclip", outtype="real", scale="none", zero="median", \
       weight="none", statsec=statsec, >>"flog")

     hedit (b1, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
     hedit (b2, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
     hedit ("bias.fits", "insfilte", insfilt, add=yes, del=no, ver=no, \
       updat=yes, show=no)
     hedit (b1, "filter", filt, del=no, ver=no, updat=yes, show=no)
     hedit (b2, "filter", filt, del=no, ver=no, updat=yes, show=no)
     hedit ("bias.fits", "filter", filt, del=no, ver=no, updat=yes, show=no)

# subtract combined bias from all flats
     for (j=100; j<=nlast-100; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       imarith (s1, "-", "bias.fits", s1)
     }

# run imstats on bias-subtracted flats and combine in sets of 100
     print ("", >>"f1.stats")
     print ("   after bias subtraction", >>"f1.stats")
     print ("", >>"f1.stats")
     print ("", >>"f2.stats")
     print ("   after bias subtraction", >>"f2.stats")
     print ("", >>"f2.stats")
 
     nlast = (nlast-99)/100
     for (j=1; j<=nlast; j+=1) {
       f0 = f1//str(j)//"00.fits"
       if (access (f0)) {
         imgets (f0, "imagetyp")
         ityp = imgets.value
         if (ityp == "flat") {
           fimg = f1//str(j)//"??.fits"
           imstat ((fimg//statsec1), >>"f1.stats")
           imstat ((fimg//rstatsec), >>"f2.stats")

           fout = froot//str(fnum)//".fits"
           fnum += 1
           if (access (fout)) delete ((fout))
           imcombine (fimg, fout, combine="median", reject="avsigclip", \
             outtype="real", scale="median", zero="none", weight="none", \
             statsec=statsec, >>"flog")
           hedit (fout, "exptime", "5.", del=no, ver=no, updat=yes, show=no)
           hedit (fout, "insfilte", insfilt, add=yes, del=no, ver=no, \
             updat=yes, show=no)
           hedit (fout, "filter", filt, del=no, ver=no, updat=yes, show=no)
           imstat ((fout//statsec1))
           print ("")
           imstat ((fout//rstatsec))
           print ("")
         }
         delete ((f1//str(j)//"??.fits"))
       }
     }


 end
