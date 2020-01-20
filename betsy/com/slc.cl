# task to copy the latest images from the 
# observing directory to a reduction directory, 
# add the filter header keyword if necessary,
# then process them with slcproc+dmag to get lightcurves 

procedure slc (img0,filtname,addfilt)

string  img0          {prompt="image rootname "}
string  filtname      {prompt="filter to be plotted (U,B,V,R,I,S, or full name)"}
bool    addfilt	      {prompt="add filtername to all image headers? "}

struct *imglist

begin

    struct imgline
    string filt,flatimg,flatimgs,filtest,rdir,plfile
    string imgrt,imglst,img1,imdat,imdatfile,imgfile,img_ext0,imgc,imglast,imgnxt
    int i,j,k,ifirst,mergetime,imgtime,sleeptime
    real expt,yax,ccdbin,rdtime
    bool addf

    cache imgets


# find out which filter to use for lightcurve
    filt = ""
    filt = filtname
    if (filt == "") error(1, "filter name is required")
    if (filt == "Bessell-U" || filt == "U") {
        filt =  "Bessell-U"
        rdir = "../reduce_U"
        filtest = "filter == 'Bessell-U'"
        flatimg = "uflat.fits"
        flatimgs = "uflat*.fits"
      } else if (filt == "Harris-B" || filt == "Bessell-B" || filt == "B") {
        filt =  "Harris-B"
        rdir = "../reduce_B"
        filtest = "filter == 'Harris-B'"
        flatimg = "bflat.fits"
        flatimgs = "bflat*.fits"
      } else if (filt == "Harris-V" || filt == "Bessell-V" || filt == "V") {
        filt =  "Harris-V"
        rdir = "../reduce_V"
        filtest = "filter == 'Harris-V'"
        flatimg = "vflat.fits"
        flatimgs = "vflat*.fits"
      } else if (filt == "Harris-R" || filt == "Bessell-R" || filt == "R") {
        filt =  "Harris-R"
        rdir = "../reduce_R"
        filtest = "filter == 'Harris-R'"
        flatimg = "rflat.fits"
        flatimgs = "rflat*.fits"
      } else if (filt == "Arizona-I" || filt == "Bessell-I" || filt == "I") {
        filt =  "Arizona-I"
        rdir = "../reduce_I"
        filtest = "filter == 'Arizona-I'"
        flatimg = "iflat.fits"
        flatimgs = "iflat*.fits"
#      } else if (filt == "WFPC-555" || filt == "W555" || filt == "W") {
      } else if (filt == "WFPC-555" || filt == "W555") {
        filt =  "WFPC-555"
        rdir = "../reduce_W"
        filtest = "filter == 'WFPC-555'"
        flatimg = "wflat.fits"
        flatimgs = "wflat*.fits"
#      } else if (filt == "WFPC-606" || filt == "W606") {
      } else if (filt == "WFPC-606" || filt == "W606" || filt == "W") {
        filt =  "WFPC-606"
        rdir = "../reduce_W"
        filtest = "filter == 'WFPC-606'"
        flatimg = "wflat.fits"
        flatimgs = "wflat*.fits"
#      } else if (filt == "WFPC-814" || filt == "W814" || filt == "W") {
      } else if (filt == "WFPC-814" || filt == "W814") {
        filt =  "WFPC-814"
        rdir = "../reduce_W"
        filtest = "filter == 'WFPC-814'"
        flatimg = "wflat.fits"
        flatimgs = "wflat*.fits"
      } else if (filt == "Schott-8612" || filt == "S") {
        filt =  "Schott-8612"
        rdir = "../reduce_S"
        filtest = "filter == 'Schott-8612'"
        flatimg = "sflat.fits"
        flatimgs = "sflat*.fits"
      } else if (filt == "Stromgren-b" || filt == "b") {
        filt =  "Stromgren-b"
        rdir = "../reduce_b"
        filtest = "filter == 'Stromgren-b'"
        flatimg = "bflat.fits"
        flatimgs = "bflat*.fits"
      } else if (filt == "Stromgren-v" || filt == "v") {
        filt =  "Stromgren-v"
        rdir = "../reduce_v"
        filtest = "filter == 'Stromgren-v'"
        flatimg = "vflat.fits"
        flatimgs = "vflat*.fits"
      } else if (filt == "H-Alpha" || filt == "a") {
        filt = "H-Alpha"
        rdir = "../reduce_a"
        filtest = "filter == 'H-Alpha'"
        flatimg = "aflat.fits"
        flatimgs = "aflat*.fits"
      } else {
        rdir = "../reduce"
        filtest = "yes"
        flatimg = "flat.fits"
        flatimgs = "flat*.fits"
    }
    addf = addfilt
    hedit.add = no

# clean up old temp files before starting
    delete ("imgfx*,newimgs",verify=no, >& "dev$null")

# make list of images; check to make sure list is not empty and first image has finished merging
    imgrt = img0
    imglst = mktemp ("imgfx")
    if (addf) {
      hselect ((imgrt//".????.fits"), "$I", yes, >& imglst)
     } else {
      hselect ((imgrt//".????.fits"), "$I", (filtest), >& imglst)
    }
    img1 = ""
    head (imglst, nlines=1) | field (field=1) | scan (img1)

# merge check
    if (img1 == "Warning:") {
      img1 = ""
     } else {
      j = stridx(".",img1)
      k = strlen(img1)
# img_ext0 is the extended fits header file [0] during merging
      img_ext0 = substr(img1,1,k-5)//"_0"//".fits"
      if ( ( access(("raw")) && !access(("raw/"//img1)) ) || access((img_ext0)) ) img1 = ""
    }

    if (img1 == "") {
      if (addf) {
        error(1,"files "//imgrt//"*.fits not found or first file not in raw subdirectory")
       } else {
        error(1,"files "//imgrt//"*.fits "//filt//" not found or first file not in raw subdirectory")
      }
     } else {
      ifirst = int(substr(img1,j+1,j+4))
      if ((ifirst-0)*(10000-ifirst) < 0) error(1,"sequence nunber undefined?  "//ifirst)
    }

# save parameters for time calculation at end
    hselect (img1, "i_naxis[2]", yes) | scan (yax)
    hselect (img1, "ccdbin2", yes) | scan (ccdbin)
    if (ccdbin == 1) {
      rdtime = 48
      mergetime = 15
    }
    if (ccdbin == 2) {
      rdtime = 23
      mergetime = 5
    }
    if (ccdbin == 3) {
      rdtime = 18
      mergetime = 3
    }
    if (ccdbin == 4) {
      rdtime = 16
       mergetime = 3
    }

# check to see if corresponding imdat file exists
    imgets (img1, "ccdsum")
    imdat = imgets.value
    if (substr(imdat,1,3) == "1 1") {
      imdatfile = "imdat1."//imgrt
     } else if (substr(imdat,1,3) == "2 2") {
      imdatfile = "imdat2."//imgrt
     } else if (substr(imdat,1,3) == "3 3") {
      imdatfile = "imdat3."//imgrt
     } else if (substr(imdat,1,3) == "4 4") {
      imdatfile = "imdat4."//imgrt
     } else {
      imdatfile = "imdatx"
    }
    if (!access(imdatfile)) {
      print ("")
      error(1,("Need to create "//imdatfile//" file first"))
    }

# create reduce directory if none exists
    if (!access(rdir)) mkdir (rdir)
    rdir = rdir//"/"

# check to see if a pl file already exists for this target in the reduce directory
    cd (rdir)
    plfile = ""
    files (("pl."//imgrt//".d*")) | head (nlines=1) | scan (plfile)
    back >& "dev$null"

# if a pl file does exist, don't change the bias and flat in the middle of the light curve
    if (plfile == "") {
      del ((rdir//"round.log*"),verify=no)
# at the start of a new light curve, get rid of old bias and flats
# in the reduce area, and copy over new biases and flats (if they exist);
# the same for the imdat file
      del ((rdir//"bias*.fits"),verify=no)
      del ((rdir//flatimgs),verify=no)
      if ( access((rdir//imdatfil)) ) del ((rdir//imdatfil),verify=no)
# check to see if a bias file exists in the observing directory
      print ("")
      if (!access("bias.fits")) \
        print ("No bias file exists; will work with unbias-subtracted images")
      imcopy ("bias*.fits", rdir, >& "dev$null")
# check to see if the flat image exists in the observing directory
      if (!access(flatimg)) \
        print (("No "//flatimg//" file; will work with unflat-fielded images"))
      imcopy (flatimgs, rdir, >& "dev$null")
# check for other files of interest
      copy (imdatfil,rdir, >& "dev$null")
      del ((rdir//"b?.stats"),verify=no)
      del ((rdir//"f?.stats"),verify=no)
      del ((rdir//"bad*"),verify=no)
      copy ("??.stats,bad*",rdir)
    }

# reset the rimexam radius (if it's way off, slcproc won't run at all)
    rimexam.radius = 10.

# the first time through, ask which dmag residuals file should be plotted
    dmag.newres = yes

# loop through existing images, then copy and process new ones
#    add filter keyword if it's not there
#    merge any images that haven't yet been merged

    print (("copying images to "//rdir))
    ifirst = 0
    while (ifirst < 45) {
#    while (ifirst < 999) {
      ifirst = ifirst + 1
      imglist = imglst
      imgline = ""
      while (fscan (imglist,imgline) != EOF) {
        print ((imgline)) | field (field="1,8") | scan (imgfile,imgc)
        if (imgfile != "") {

# merge4k image now if not previously merged
          j = stridx(".",imgfile)
          k = strlen(imgfile)
          if (imgfile != "Warning:" && substr(imgfile,1,j-1) != imgrt) \
              print ((imgfile//" not Warning or filename !!"))
          if (imgfile == "Warning:") {
            sleeptime = mergetime
            sleep (sleeptime)
            i = strlen(imgc)
            imgfile = substr(imgc,2,i-1)
            print (("running merge4k on "//imgfile))
            merge4k (imgfile)
          }

# don't do anything more with this image if it has already been processed
          imgc = rdir//imgrt//"c"//substr(imgfile,j,k)
          if ( !access(imgc) ) {
# continue if image has been copied to reduce directory and not yet processed
            if ( access((rdir//imgfile)) ) {
              touch ("newimgs")
              imglast = imgfile
             } else {
# or copy the image to the reduce directory if it has finished merging
              img_ext0 = substr(imgfile,1,k-5)//"_0"//".fits"
              if ( ( !access(("raw")) || access(("raw/"//imgfile)) ) && !access((img_ext0)) ) {
                sleep (1)
                if (addf) hedit (imgfile, "filter", filt, addonly=yes, verify=no, show=no, update=yes, \ 
                   >& "dev$null")
                imcopy (imgfile,rdir, verbose=no)
                touch ("newimgs")
                imglast = imgfile
              }
            }
          }

        }
      }

      if (access ("newimgs")) {
# move to the reduce directory, process any new images and move back
        cd (rdir)

        img1 = imgrt//".????.fits"
        slcproc ((img1))
        dmag (imgrt)

        back >& "dev$null"
        delete ("newimgs")

# in case filter keyword didn't always get written in header when it should have
        if (addf) hedit ((imgrt//".????.fits"), "filter", filt, addonly=yes, verify=no, \
            show=no, update=yes, >& "dev$null")
      }

# check to see if new images have been written to disk yet
      hselect (imglast, "exptime", yes) | scan (expt)
      imgtime = expt + rdtime*yax/(4096./ccdbin)
      j = 0
      k = 0
      imgnxt = imglast
      while (imgnxt == imglast) {
        imglst = ""
        delete ("imgfx*",verify=no)
        imglst = mktemp ("imgfx")
        if (addf) {
          hselect ((imgrt//".????.fits"), "$I", yes, >& imglst)
         } else {
          hselect ((imgrt//".????.fits"), "$I", (filtest), >& imglst)
        }
        tail (imglst, nlines=1) | field (field=1) | scan (imgnxt)

# if next image hasn't come in yet, wait and try again
        if (imgnxt == imglast) {
          if (j > 3) {
            j = 0
            print ("")
            print ("   ****   CHECK that AZCamTool SEQUENCE IS STILL RUNNING   ****")
            print ("")
          }
          j = j+1
          sleeptime = imgtime/2
          sleep (sleeptime)

# if merge4k hasn't finished with imgnxt, wait and try again
         } else if (imgnxt == "Warning:") {
          imgnxt = imglast
          if (k > 2) {
            k = 0
            print ("")
            print ("       ****   CHECK that WATCHER IS STILL RUNNING   ****")
            print ("")
          }
          k = k+1
          sleeptime = mergetime
          sleep (sleeptime)
        }
      }

# set dmag to keep using the same residuals file from now on
      dmag.newres = no
    }
    delete ("imgfx*",verify=no)

    print ("")
    print ("       ****   TYPE UP-ARROW to RESTART SLC !!!   ****")
    print ("")
    delete ("imgfx*",verify=no)

end
