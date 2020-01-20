# Inputs an individual raw mont4k extended fits (file binned 1x1, 
# 2x2, 3x3, or 4x4) OR a group of extended fits images 
#    (specified as a*.fits, a.000*, or @f)
# and outputs the joined/merged fits image or images.
#
# The images must be the full width across, but a smaller number of
# rows may be selected
#
# The input images are saved unchanged in a subdirectory named raw
# 
# The only processing done to the joined image is 
#   1) removal of crosstalk, using a coefficient of 0.00264
#   2) overscan correction and trimming of each side in order to 
#      merge the two sides

procedure merge4k (rawimg)

string rawimg      {prompt="raw 3x3 mont4k images"}
struct  *imagelist

begin
     string rimgstr,rimg,mchk,rimg1,rimg2,rimge,imagel,bin
     string ysec,biassec,datasec,datasec2
     real xtcoef
     int i,l

     cache imgets

     xtcoef = 0.00264

#     mchk = msc
     mchk = "y"
     if (substr(mchk,1,1) != "y" && substr(mchk,1,1) != "Y") \
       error(1,"Load mscred package before running merge4k")

# create the raw directory if it doesn't exist
     if (!access("raw")) mkdir ("raw")

     colbias.median = yes
     colbias.interactive = no
     
     rimgstr = rawimg
     if (substr(rimgstr,1,1) != "@") {
       i = strlen(rimgstr)
       if (substr(rimgstr,i-3,i) != "fits") rimgstr = rimgstr//".fits"
     }
     imagel = mktemp ("img")
     files (rimgstr, > imagel)

# read and process each image in the list
     imagelist = imagel
     while (fscan (imagelist,rimg) != EOF) {

       i = strlen(rimg)
       rimg1 = substr(rimg,1,i-5)//"_1"//".fits"
       rimg2 = substr(rimg,1,i-5)//"_2"//".fits"

# check to see if an image with this name has been previously merged in this directory
       if (access ("raw/"//rimg)) \ 
          error(1,"an image named "//rimg//" already exists in the raw directory")

# split the input image into its two parts
       mscsplit (rimg, delete=no, verb=no)

# do the crosstalk correction for each half
       imar ((rimg//"[1]"), "*", xtcoef, "xt2.fits")
       imar ((rimg//"[2]"), "*", xtcoef, "xt1.fits")
       imar (rimg1, "-", "xt1.fits", rimg1)
       imar (rimg2, "-", "xt2.fits", rimg2)
       imdel ("xt1.fits")
       imdel ("xt2.fits")

# edit keywords
       hedit ((rimg//"[0]"), "xtkcoef", xtcoef, add=yes, verify=no, show=no, update=yes)

# get rows (in case the image doesn't use all of them)
       imgets ((rimg//"[1]"), "ccdsec")
       ysec = imgets.value
       ysec = substr(ysec,stridx(",",ysec),strlen(ysec))

# check the binning, then overscan correct and trim each half
       imgets ((rimg//"[0]"), "ccdsum")
       bin = imgets.value
       if (substr(bin,1,3) == "1 1") {
         biassec = "[2054:2068"//ysec
         datasec = "[1:2048"//ysec
         datasec2 = "[2049:4096"//ysec
        } else if (substr(bin,1,3) == "2 2") {
         biassec = "[1030:1044"//ysec
         datasec = "[1:1024"//ysec
         datasec2 = "[1025:2048"//ysec
        } else if (substr(bin,1,3) == "3 3") {
         biassec = "[688:702"//ysec
         datasec = "[1:682"//ysec
         datasec2 = "[683:1364"//ysec
        } else if (substr(bin,1,3) == "4 4") {
         biassec = "[518:532"//ysec
         datasec = "[1:512"//ysec
         datasec2 = "[513:1024"//ysec
       }
       colbias (rimg1,rimg1, bias=biassec, trim=datasec, func="spline3", order=2)
       colbias (rimg2,rimg2, bias=biassec, trim=datasec, func="spline3", order=2)

#  save the original in the raw subdirectory
       rename (rimg, ("raw/"//rimg)) 

# create a combined image using ccdproc on the raw image
       ccdproc (("raw/"//rimg), output=rimg, ccdtype="", noproc=no, xtalkcor=no, \
         fixpix=no, overscan=yes, trim=yes, zerocor=no, darkcor=no, \
         flatcor=no, sflatcor=no, split=no, merge=yes, biassec=biassec, \
         trimsec=datasec, interactive=no, func="spline3", order=2, \
         sample="*", naverage=-3)

# copy the crosstalk-corrected, overscan-corrected, trimmed images into a combined image
# (this procedure is needed because ccdproc will combine the raw images, but not 
#  images that have been split and rejoined with mscjoin, even though that ought to
#  work)
       imcopy (rimg1, (rimg//datasec), verbose=no)
       imcopy ((rimg2//"[-*,*]"), (rimg//datasec2), verbose=no)
       hedit (rimg, "imageid", delete=yes, verify=no, show=no, update=yes)

# delete the intermediate split images
       imdel ((substr(rimg,1,i-5)//"_*.fits"))

     }

     delete (imagel)
     delete ("amps,logfile")
  end
