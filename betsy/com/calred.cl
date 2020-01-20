# Inputs a series of normal fits file calibration images (100 biases + 
# Nx100 flats + Mx100 biases, for M <=7) that were created by the 
# AZCamTool multi-exposure sequence, and are already merged (either by 
# watcher or manually). 
#
# The first set of bias images is assumed to be numbered 0000 to 0099,
# and the first 100 flats numbered 0100 to 0199, etc.  Images may
# be missing within a sequence

# This task combines
# the two bias sets taken before and after the flats, subtracts that
# combined bias.fits image from the individual flats, outputs combined 
# bias and flat images in sets of 100, and creates a superbias and a
# normalized superflat ready for image processing with slcproc

# The initial processing should have been done with merge4k, which 
# corrects for crosstalk and merges each extended fits image into a 
# single normal fits image.   

procedure calred (calname,bias1,flat1)

string calname  {prompt="Root name for the series of calibration images? "}
string bias1    {prompt="Name of first combined bias image? "}
string flat1    {prompt="Name of first combined flat image? "}

begin
     string cname,rawdir,s0,s1,ext,ityp,lasttyp,exp
     string bimg1,bimg2,bimg3,bimg4,bimg5,bimg6,bimg7,bimg8
     string f1,fimg,b1,b2,b3,b4,b5,b6,b7,b8,broot,bout,froot,fout,filt,insfilt
     string statsec,lstatsec,rstatsec,dum,merr
# nb=starting sequence number of final biases
# nf=final sequence number of flats
     int i,j,nb,nf,nlast,fnum,ncs,nc1,nc2,ncl,ncr,rc1,rc2,nrs,nr1,nr2
     real mf

     cache imgets

     bimg3 = "" ; bimg4 = "" ; bimg5 = "" ; bimg6 = "" ; bimg7 = "" ; bimg8 = ""

     print ("")

     cname = calname
     i = strlen(cname)
     if (substr(cname,i,i) != ".") cname = cname//"."

     if (access("xxx")) delete ("xxx",verify=no)
# check that the specified input calibration images exist
     files ((cname//"????.fits"), >"xxx")
     s0 = ""
     head ("xxx", nlines=1) | scan (s0)
     i = strlen(s0)
     if(i == 0 || substr(s0,i-4,i) != ".fits") \ 
        error(1,"No fits files with numbered extensions exist for this root name")

# define image sections
       hselect ((s0), "naxis[1]", yes) | scan (ncs)
       nc1 = 0.1*ncs + 0.5
       ncl = 0.45*ncs + 0.5
       ncr = 0.55*ncs
       nc2 = 0.9*ncs
       hselect ((s0), "naxis[2]", yes) | scan (nrs)
       nr1 = 0.1*nrs + 0.5
       nr2 = 0.9*nrs

       statsec = "["//str(nc1)//":"//str(nc2)//","//str(nr1)//":"//str(nr2)//"]"
       lstatsec = "["//str(nc1)//":"//str(ncl)//","//str(nr1)//":"//str(nr2)//"]"
       rstatsec = "["//str(ncr)//":"//str(nc2)//","//str(nr1)//":"//str(nr2)//"]"
       print (("  statsec = "//statsec))


# check that first 100 images (0000 to 0099) are biases
     for (j=0; j<100; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       if (!access (s1)) {
         if (j == 0) error(1,("the sequence doesn't start with image "//s1))
         print ((s1//" doesn't exist"))
        } else {
         imgets ((s1), "imagetyp")
         ityp = imgets.value
         if (ityp != "zero") error(1,(s1//" isn't a zero"))
         lasttyp = "zero"
       }
     }
     print ("")
     print ((s0//" to "//s1//" are zeros"))
     bimg1 = cname//"00??.fits"

# check that images from 100 to nf are all flats and that the final images 
# from nb to nlast are all biases
     tail ("xxx", nlines=1)  | scan (s1)
     delete ("xxx",verify=no)
     i = strlen(s1)
     nlast = int(substr(s1,i-8,i-5))
     if (nlast < 199) error(1, "the second set of 100 images aren't flats")

     for (j=100; j<=nlast; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       if (!access (s1)) {
         print ((s1//" doesn't exist"))
        } else {
         imgets ((s1), "imagetyp")
         ityp = imgets.value
         if (ityp == "flat") {
           if (lasttyp == "zero") {
             s0 = s1
             imgets ((s1), "exptime")
             exp = int(imgets.value)
             imgets ((s1), "filter")
             filt = imgets.value
             insfilt = filt
             if (insfilt == "0") error(1,"no filter keyword in images")
             i = strlen(filt)
             if (substr(filt,1,7) == "Bessell") filt = substr(filt,i,i)
             if (substr(filt,1,6) == "Harris") filt = substr(filt,i,i)
             if (substr(filt,1,7) == "Arizona") filt = substr(filt,i,i)
             if (substr(filt,1,4) == "WFPC") filt = "W"
             if (substr(filt,1,6) == "Schott") filt = "S"
           }
           imgets ((s1), "filter")
           s1 = imgets.value
           if (s1 != insfilt) error(1,"filter name changed in middle of flat series")
           nf = j
           nb = 100*(1 + j/100)
          } else if (ityp == "zero") {
           if (j == 100) error(1,("image "//s1//" isn't a flat")
           if (lasttyp == "flat") {
             if (nb > nf+100) error(1,"the first image of the final zeros isn't a multiple of 100")
             nb = j
           }
           i = 100*(nb/100)
           ext = str(j/100)
           while (strlen(ext) < 2) ext = "0"//ext
           if(j >= i && j < i+100) bimg2 = cname//ext//"??.fits"
           if (j >= i+100 && j < i+200) bimg3 = cname//ext//"??.fits"
           if (j >= i+200 && j < i+300) bimg4 = cname//ext//"??.fits"
           if (j >= i+300 && j < i+400) bimg5 = cname//ext//"??.fits"
           if (j >= i+400 && j < i+500) bimg6 = cname//ext//"??.fits"
           if (j >= i+500 && j < i+600) bimg7 = cname//ext//"??.fits"
           if (j >= i+600 && j < i+700) bimg8 = cname//ext//"??.fits"
          } else {
           if (j < nb) error(1,(s1//" isn't a flat"))
           if (j > nb) error(1,(s1//" isn't a zero"))
         }
         lasttyp = ityp
       }
     }

# list the flat images
     ext = str(nf)
     while (strlen(ext) < 4) ext = "0"//ext
     s1 = cname//ext//".fits"
     print ((s0//" to "//s1//" are "//exp//" sec "//filt//" flats"))

# the following are executed only if the sequence started with 0000
     i = 100*(nlast/100)
     ext = str(i)
     while (strlen(ext) < 4) ext = "0"//ext
     s1 = cname//ext//".fits"
     imgets ((s1), "imagetyp")
     ityp = imgets.value
     if(ityp != "zero") error(1, "the last set of 100 images aren't zeros")

# list the final bias images
     ext = str(nb)
     while (strlen(ext) < 4) ext = "0"//ext
     s0 = cname//ext//".fits"
     ext = str(nlast)
     while (strlen(ext) < 4) ext = "0"//ext
     s1 = cname//ext//".fits"
     print ((s0//" to "//s1//" are zeros"))
     print ("")


# get names for output images; check that bias images
# and flat images do not already exist
     b1 = bias1
     i = strlen(b1)
     if(substr(b1,i-4,i) == ".fits") {
       s0 = b1
       b1 = substr(b1,1,i-5)
      } else {
       s0 = b1//".fits"
     }
     if (access (s0)) error(1,(s0//" already exists"))

     i = strlen(b1)
     broot = substr(b1,1,i-1)
     if (substr(b1,i-2,i-2) == "1") {
       broot = substr(b1,1,i-2)
      } else if (substr(b1,i-2,i-2) == "2") {
       broot = substr(b1,1,i-2)
      } else if (substr(b1,i-2,i-2) == "3") {
       broot = substr(b1,1,i-2)
     }

     f1 = flat1
     i = strlen(f1)
     if(substr(f1,i-4,i) == ".fits") {
       s0 = substr(f1,1,i-5)
      } else {
       s0 = f1
     }
     i = strlen(s0)
     froot = substr(s0,1,i-1)
     fnum = int(substr(s0,i,i))
     if (substr(s0,i-2,i-2) == "1") {
       froot = substr(s0,1,i-2)
       fnum = fnum + 10
      } else if (substr(s0,i-2,i-2) == "2") {
       froot = substr(s0,1,i-2)
       fnum = fnum + 20
      } else if (substr(s0,i-2,i-2) == "3") {
       froot = substr(s0,1,i-2)
       fnum = fnum + 30
     }
     s0 = s0//".fits"
     if (access (s0)) error(1,(s0//" already exists"))

     print ("")

# run imstats on individual merged images
     imstat.fields = "image,mean,midpt,stddev,min,max"
     imstat ((bimg1//lstatsec), >>"b1.stats")
     imstat ((bimg1//rstatsec), >>"b2.stats")

     imstat ((bimg2//lstatsec), >>"b1.stats")
     imstat ((bimg2//rstatsec), >>"b2.stats")

     if (bimg3 != "") {
       imstat ((bimg3//lstatsec), >>"b1.stats")
       imstat ((bimg3//rstatsec), >>"b2.stats")
     }

     if (bimg4 != "") {
       imstat ((bimg4//lstatsec), >>"b1.stats")
       imstat ((bimg4//rstatsec), >>"b2.stats")
     }

     if (bimg5 != "") {
       imstat ((bimg5//lstatsec), >>"b1.stats")
       imstat ((bimg5//rstatsec), >>"b2.stats")
     }

     if (bimg6 != "") {
       imstat ((bimg6//lstatsec), >>"b1.stats")
       imstat ((bimg6//rstatsec), >>"b2.stats")
     }

     if (bimg7 != "") {
       imstat ((bimg7//lstatsec), >>"b1.stats")
       imstat ((bimg7//rstatsec), >>"b2.stats")
     }

     if (bimg8 != "") {
       imstat ((bimg8//lstatsec), >>"b1.stats")
       imstat ((bimg8//rstatsec), >>"b2.stats")
     }

     i = (nb)/100 - 1
     for (j=1; j<=i; j+=1) {
       if (j<10) {
         fimg = froot//".0"//str(j)//"??.fits"
        } else {
         fimg = froot//"."//str(j)//"??.fits"
       }
#       imstat ((fimg//lstatsec), >>"f1.stats")
#       imstat ((fimg//rstatsec), >>"f2.stats")
     }

# combine biases in groups of 100
     i = strlen(b1)
     if (substr(b1,i-4,i) != ".fits") b1 = b1//".fits"
     i = strlen(b1)
     if (access (b1)) delete ((b1),verify=no)
     imcombine (bimg1, b1, combine="median", reject="avsigclip", outtype="real", \
       scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
     imstat ((b1//lstatsec))
     print ("")
     imstat ((b1//rstatsec))
     print ("")

     j = stridx(".",b1)
     s0 = substr(b1,1,j-2)
     j = int(substr(b1,j-1,j-1))+1
     b2 = s0//str(j)//substr(b1,i-4,i)
     if (access (b2)) delete ((b2),verify=no)
     imcombine (bimg2, b2, combine="median", reject="avsigclip", outtype="real", \
       scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
     imstat ((b2//lstatsec))
     print ("")
     imstat ((b2//rstatsec))
     print ("")

     j = j+1
     b3 = s0//str(j)//substr(b1,i-4,i)
     if (bimg3 != "") {
       if (access (b3)) delete ((b3),verify=no)
       imcombine (bimg3, b3, combine="median", reject="avsigclip", outtype="real", \
         scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
       imstat ((b3//lstatsec))
       print ("")
       imstat ((b3//rstatsec))
       print ("")
     }

     j = j+1
     b4 = s0//str(j)//substr(b1,i-4,i)
     if (bimg4 != "") {
       if (access (b4)) delete ((b4),verify=no)
       imcombine (bimg4, b4, combine="median", reject="avsigclip", outtype="real", \
         scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
       imstat ((b4//lstatsec))
       print ("")
       imstat ((b4//rstatsec))
       print ("")
     }

     j = j+1
     b5 = s0//str(j)//substr(b1,i-4,i)
     if (bimg5 != "") {
       if (access (b5)) delete ((b5),verify=no)
       imcombine (bimg5, b5, combine="median", reject="avsigclip", outtype="real", \
         scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
       imstat ((b5//lstatsec))
       print ("")
       imstat ((b5//rstatsec))
       print ("")
     }

     j = j+1
     b6 = s0//str(j)//substr(b1,i-4,i)
     if (bimg6 != "") {
       if (access (b6)) delete ((b6),verify=no)
       imcombine (bimg6, b6, combine="median", reject="avsigclip", outtype="real", \
         scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
       imstat ((b6//lstatsec))
       print ("")
       imstat ((b6//rstatsec))
       print ("")
     }

     j = j+1
     b7 = s0//str(j)//substr(b1,i-4,i)
     if (bimg7 != "") {
       if (access (b7)) delete ((b7),verify=no)
       imcombine (bimg7, b7, combine="median", reject="avsigclip", outtype="real", \
         scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
       imstat ((b7//lstatsec))
       print ("")
       imstat ((b7//rstatsec))
       print ("")
     }

     j = j+1
     b8 = s0//str(j)//substr(b1,i-4,i)
     if (bimg8 != "") {
       if (access (b8)) delete ((b8),verify=no)
       imcombine (bimg8, b8, combine="median", reject="avsigclip", outtype="real", \
         scale="none", zero="median", weight="none", statsec=statsec, >>"flog")
       imstat ((b8//lstatsec))
       print ("")
       imstat ((b8//rstatsec))
       print ("")
     }

     hedit (b1, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
     hedit (b1, "filter", filt, del=no, ver=no, updat=yes, show=no)

     hedit (b2, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
     hedit (b2, "filter", filt, del=no, ver=no, updat=yes, show=no)

     if (access (b3)) {
       hedit (b3, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
       hedit (b3, "filter", filt, del=no, ver=no, updat=yes, show=no)
     }

     if (access (b4)) {
       hedit (b4, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
       hedit (b4, "filter", filt, del=no, ver=no, updat=yes, show=no)
     }

     if (access (b5)) {
       hedit (b5, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
       hedit (b5, "filter", filt, del=no, ver=no, updat=yes, show=no)
     }

     if (access (b6)) {
       hedit (b6, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
       hedit (b6, "filter", filt, del=no, ver=no, updat=yes, show=no)
     }

     if (access (b7)) {
       hedit (b7, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
       hedit (b7, "filter", filt, del=no, ver=no, updat=yes, show=no)
     }

     if (access (b8)) {
       hedit (b8, "insfilte", insfilt, add=yes, del=no, ver=no, updat=yes, show=no)
       hedit (b8, "filter", filt, del=no, ver=no, updat=yes, show=no)
     }

# create temporary bias from two sets of biases right before and after the flats
     if (access("bias.fits")) delete ("bias.fits",verify=no)
     imcombine ((bimg1//","//bimg2), "bias.fits", combine="median", \
       reject="avsigclip", outtype="real", scale="none", zero="median", \
       weight="none", statsec=statsec, >>"flog")

# subtract combined bias from all flats
     for (j=100; j<=nb-1; j+=1) {
       ext = str(j)
       while (strlen(ext) < 4) ext = "0"//ext
       s1 = cname//ext//".fits"
       imarith (s1, "-", "bias.fits", s1)
       hedit (s1, "biassub", "bias image\"bias.fits\" was subtracted", \
         add=yes, del=no, ver=no, update=yes, show=no)
     }

# run imstats on bias-subtracted flats and combine in sets of 100
     print ("", >>"f1.stats")
     print ("   after bias subtraction", >>"f1.stats")
     print ("", >>"f1.stats")
     print ("", >>"f2.stats")
     print ("   after bias subtraction", >>"f2.stats")
     print ("", >>"f2.stats")

     nlast = nf/100
     for (j=1; j<=nlast; j+=1) {
       ext = str(j)
       while (strlen(ext) < 2) ext = "0"//ext
       fimg = cname//ext//"??.fits"
       imstat ((fimg//lstatsec), >>"f1.stats")
       imstat ((fimg//rstatsec), >>"f2.stats")

       fout = froot//str(fnum)//".fits"
       fnum += 1
       if (access (fout)) delete ((fout),verify=no)
       imcombine (fimg, fout, combine="median", reject="avsigclip", \
         outtype="real", scale="median", zero="none", weight="none", \
         statsec=statsec, >>"flog")
       hedit (fout, "exptime", "5.", del=no, ver=no, updat=yes, show=no)
       hedit (fout, "insfilte", insfilt, add=yes, del=no, ver=no, \
         updat=yes, show=no)

       imstat ((fout//lstatsec))
       print ("")
       imstat ((fout//rstatsec))
       print ("")
     }

# create superbias from all bias?.fits
     bout = broot//".fits"
     if (access (bout)) imdel (bout,verify=no)
     imcombine ((broot//"?.fits,"//broot//"??.fits"), bout, combine="median", reject="avsigclip", \
       outtype="real", scale="none", zero="median", weight="none", \
       statsec=statsec, >>"flog")
     hedit ("*bias*fits", "imcmb*", del=yes)

# create combined normalized superflat
     fout = froot//".fits"
     if (access (fout)) imdel (fout,verify=no)
     imcombine ((froot//"?.fits,"//froot//"??.fits"), fout, combine="median", reject="avsigclip", \
       outtype="real", scale="median", zero="none", weight="none", \
       statsec=statsec, >>"flog")
     imstat ((fout//statsec), field="midpt", format=no) | scan (mf)
     imar (fout, "/", mf, fout)
     hedit ("*flat*fits", "imcmb*", del=yes)

 end
