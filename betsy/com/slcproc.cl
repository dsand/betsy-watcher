# kuiper version!
# Task to process merged Mont4k time-series images, starting with subtraction
# of the merged combined bias image, division by a merged bias-subtracted
# imcombined normalized (in [100:1265,100:1265]) flat image, and then
# bad column interpolation.   After the preliminary processing, it
# finds image sky statistics (sky level and sky std deviation) for each image.  
# Next, it runs cosmicrays, daofind, and findbrt.  Once precise coords have been 
# found for the stars of interest, it determines the average and individual 
# stellar fwhm and writes a statistics line in the .stats file.
# Finally, runs apphot.phot using known coords and average stellar fwhm.
# Needs imdat<n>.pg0 file, where n = bin size and pg0 = rootname.

# This task works for all images with the same rootname or for specific images.

procedure slcproc (pg0)

string  pg0          {prompt="input image(s) "}

struct *pglist
struct *imdatfile

begin
    string imdat,imdatline,pg,root,pglst,pgfile,pgb,pgf,statfile,filt0,filt
    string imsect,pgraw,tit,ra,dec,flatimg,sect,ityp,rnds,avrnds
    string xy[3],txtline,statsec,crfile,crf,satfile,photlog,badpix,chkn,s1,s2
    real exptim,gain,rdnoise,m1,sky[3],sig[3],maxsig,avsig
    real thresh,avfw,avfw0,fw[20],aper,ann,dann,d1,d2,d3,d4,d5,d6,rfactr,afactr
    real ovscmed1,ovscmed2,xc,yc,max,av[13],av_factr,rnd,avrnd,ut,dut,avgtime
    bool first,biassub,flatdiv
    int i,i1,i2,i3,l1,l2,l3,j,k,bin,nt,ns,xmid,mx1,mx2,my1,my2
    int ncs,nc1,nc2,nrs,nr1,nr2,indf

    cache imgets

    pg = pg0
    i = strlen(pg)
    if (substr(pg,i-4,i) == ".fits") pg = substr(pg,1,i-5)
    if (substr(pg,i-3,i) == "fits") pg = substr(pg,1,i-4)

    root = pg
    i = stridx(".",root)
    ityp = substr(root,i-1,i-1)
    if (i > 0 ) {
      root = substr(root,1,i-1)
#      if (ityp == "b" || ityp == "f" || ityp == "c" || ityp == "d") \
      if (ityp == "c" || ityp == "d") \
        root = substr(root,1,i-2)
    }
    photlog = root//".log"
    statfile = root//".stats"

# clean up old temporary files before starting
    delete ("pgfx*",verify=no)
    delete ((root//"b.????"//".fits"),verify=no)
    delete ((root//"f.????"//".fits"),verify=no)
    delete ((root//"*.mag.*~"),verify=no)
    delete ((root//"*.mag.2"),verify=no)
    delete ((root//"*.mag.3"),verify=no)

    pglst = mktemp ("pgfx")
    files ((pg//".fits"), > pglst)
    s1 = ""
    head (pglst, nlines=1) | scan (s1)
    if (s1 == "") {
      print (("no "//pg//".fits files to process"))
    } else {
    pglist = pglst

# select appropriate imdat file, open it, and read in sky positions;
#  reset rimexam parameters in case they are too far off
    imdat = "imdat"
    rimexam.radius = 10.
#    rimexam.radius = 20.
    i = fscan (pglist,pgfile)
      imgets (pgfile, "ccdsum")
      imdatline = imgets.value
      if (substr(imdatline,1,3) == "1 1") {
        bin = 1
        imdat = imdat//"1."//root
        rimexam.buffer = 12
        rimexam.width = 20
        if(access ("badpixels.1x1.dat")) {
           badpix = "badpixels.1x1.dat"
         } else {
           badpix = "/home/bigobs/betsy/com/badpixels.1x1.dat"
        }
       } else if (substr(imdatline,1,3) == "2 2") {
        bin = 2
        imdat = imdat//"2."//root
        rimexam.buffer = 7
        rimexam.width = 12
        if(access ("badpixels.2x2.dat")) {
           badpix = "badpixels.2x2.dat"
         } else {
           badpix = "/home/bigobs/betsy/com/badpixels.2x2.dat"
        }
       } else if (substr(imdatline,1,3) == "3 3") {
        bin = 3
        imdat = imdat//"3."//root
        rimexam.buffer = 4
        rimexam.width = 7
        if(access ("badpixels.3x3.dat")) {
           badpix = "badpixels.3x3.dat"
         } else {
           badpix = "/home/bigobs/betsy/com/badpixels.3x3.dat"
        }
       } else if (substr(imdatline,1,3) == "4 4") {
        bin = 4
        imdat = imdat//"4."//root
        rimexam.buffer = 3
        rimexam.width = 5
        if(access ("badpixels.4x4.dat")) {
           badpix = "badpixels.4x4.dat"
         } else {
           badpix = "/home/bigobs/betsy/com/badpixels.4x4.dat"
        }
      }
    rimexam.iterations = 5
    imdatfile = imdat
    i = 0
    for (j=1; j<=7; j+=1) {
      k = fscan (imdatfile,imdatline)
      if (substr(imdatline,1,1) == "[") {
        i += 1
        xy[i] = imdatline
      }
    }
    while (fscan (imdatfile,imdatline) != EOF) {
      if(substr(imdatline,1,1) != "#") {
        nt = int(imdatline)
       } else {
        k = fscan(imdatfile,imdatline)
        ns = int(imdatline)
      }
    }

# define phot parameters
# Saturation needs to be measured in the raw merged images, to find out
# whether any pixel values equal or exceed (65535 - bias level)
#  (note that raw datamax is set conservatively)

    findpars.threshold = 5.
    findpars.nsigma = 1.5
    findpars.ratio = 1.
    findpars.theta = 0.
    findpars.sharplo = 0.2
    findpars.sharphi = 1.
    findpars.roundlo = -1.
    findpars.roundhi = 1.

    datapars.scale = 1.
    datapars.emission = yes
    datapars.datamin = -60.
    datapars.datamax = 150000.
    datapars.noise = "constant"
    datapars.ccdread = "rdnoise"
    datapars.gain = "gain"
    datapars.exposure = "exptime"
    datapars.airmass = "airmass"
    datapars.filter = "filter"
    datapars.obstime = "hjd"

    centerpars.calgorithm = "centroid"
    centerpars.cbox = 15.0*3/bin
    centerpars.cthreshold = 0.
    centerpars.maxshift = 0.05
    centerpars.cmaxiter = 10

    fitskypars.salgorithm = "median"

    photpars.weighting = "constant"
    photpars.zmag = 23.2

# alternate parameters, originally for use if bright stars aren't being found
#  but often needed with 61" NGS due to poor tracking/jumps in middle of exposures
    findpars.sharplo = 0.1
    findpars.sharphi = 2.0
    findpars.roundlo = -3.0
    findpars.roundhi = 3.0
    centerpars.maxshift = 3.0

    av_factr = 0.7
    avfw = -1.
    if ( access (statfile) ) {
      tail (statfile, nlines=1) | fields (fie="8") | scan (avfw)
      avfw = av_factr * avfw
    }
#    if (avfw < 0.) avfw = 1.8 * 3./bin
    if (avfw < 0.) avfw = 5.0 * 3./bin

# print header lines in statistics file
    i1  = stridx(",",xy[1])
    i2  = stridx(",",xy[2])
    i3  = stridx(",",xy[3])
    l1 = strlen(xy[1])
    l2 = strlen(xy[2])
    l3 = strlen(xy[3])

    if ( !access (statfile) ) {
      txtline = "#                     sky midpts                   sky sigmas           average"
      print ((txtline), >statfile)
      txtline = "#                                                                         fwhm   "
#      for (i=1; i<=nt; i+=1) {
#        txtline = txtline//"   fw["//str(i)//"]"
#      }
      print ((txtline), >>statfile)
      print ("#", >>statfile)
      txtline = "#            "//substr(xy[1],1,i1)//" "//substr(xy[2],1,i2)//" "//substr(xy[3],1,i3)
      print ((txtline), >>statfile)
      txtline = "#             "//substr(xy[1],i1+1,l1)//"  "//substr(xy[2],i2+1,l2)//"  "//substr(xy[3],i3+1,l3)//"            (same)"
      print ((txtline), >>statfile)
      print ("#", >>statfile)
    }

    pglist = pglst
    while (fscan (pglist,pgfile) != EOF) {
      print(" ")
      print ((pgfile))
      print(" ")
      first = yes
      imgets (pgfile, "ut")
      ut = real(imgets.value)
      imgets (pgfile, "exptime")
      exptim = real(imgets.value)

# skip this image if shutter didn't open
      if (exptim > 0.) {

        biassub = no
        flatdiv = no
        i = stridx(".",pgfile)
        pgb = root//"b"//substr(pgfile,i,strlen(pgfile))
        pgf = root//"f"//substr(pgfile,i,strlen(pgfile))

        ityp = substr(pgfile,i-1,i-1)
        if(ityp == "b") {
          biassub = yes
         } else if(ityp == "f") {
          biassub = yes
          flatdiv = yes
         } else if(ityp == "c" || ityp == "d" ) {
          biassub = yes
          flatdiv = yes
        }

# if images are being run for the first time, fix header info
        s1 = ""
        hsel (pgfile, "hjd", yes) | scan (s1)
        if (s1 == "" ) {
          imgets (pgfile, "filter")
          s1 = imgets.value
          if (s1 == "Bessell-U" || s1 == "U") {
              filt = "U"
              filt0 = "Bessell-U"
            } else if (s1 == "Harris-B" || s1 == "Bessell-B" || s1 == "B") {
              filt = "B"
              filt0 = "Harris-B"
            } else if (s1 == "Harris-V" || s1 == "Bessell-V" || s1 == "V") {
              filt = "V"
              filt0 = "Harris-V"
            } else if (s1 == "Harris-R" || s1 == "Bessell-R" || s1 == "R") {
              filt = "R"
              filt0 = "Harris-R"
            } else if (s1 == "Bessell-I" || s1 == "Arizona-I" || s1 == "I") {
              filt = "I"
              filt0 = "Arizona-I"
            } else if (s1 == "WFPC-555" || s1 == "WFPC-F555W" || s1 == "W") {
              filt = "W"
              filt0 = "WFPC-F555W"
            } else if (s1 == "WFPC-606" || s1 == "WFPC-F606W" || s1 == "W") {
              filt = "W"
              filt0 = "WFPC-F606W"
            } else if (s1 == "Schott-8612" || s1 == "S") {
              filt = "S"
              filt0 = "Schott-8612"
            } else if (s1 == "Stromgren-b" || s1 == "b") {
              filt = "b"
              filt0 = "Stromgren-b"
            } else if (s1 == "Stromgren-v" || s1 == "v") {
              filt = "v"
              filt0 = "Stromgren-v"
            } else if (s1 == "H-Alpha" || s1 == "a") {
              filt = "a"
              filt0 = "H-Alpha"
            } else if (s1 == "") {
              filt = ""
              filt0 = ""
          }
          hedit (pgfile, "filter", delete=yes, verify=no, update=yes, show=no)
          hedit (pgfile, "insfilte", filt0, add=yes, del=no, verify=no, update=yes, show=no)
          hedit (pgfile, "filter", filt, add=yes, del=no, verify=no, update=yes, show=no)

          imgets (pgfile, "title")
          s1 = imgets.value
          s2 = substr(s1,1,1)
          if (s2 == "" || s2 == " ") error(1,("the image title for "//pgfile//" is undefined"))
          k = -1
          if (substr(root,1,3) != "std") {
            grep  (s1, "/home/bigobs/betsy/com/sdb.list") | scan (k,tit,ra,dec)
            s2 = s1//" not found in sdb.list (l="//str(k)//")"
            if (k < 0 || k > 2000) error(1,s2)
           } else {
            grep (s1, "/home/bigobs/betsy/com/land92best.list") | scan (k,tit,ra,dec)
            s2 = s1//" not found in land92best.list (l="//str(k)//")"
            if (k < 0 || k > 1000) error(1,s2)
          }

# write catalog values of RA, Dec, and epoch, and create other keywords if they don't exist
          imgets (pgfile, "gain1")
          gain = real(imgets.value)
          imgets (pgfile, "gain2")
          gain = (gain + real(imgets.value))/2.
          ccdhedit (pgfile, "gain", gain, type="real")
          imgets (pgfile, "rdnoise1")
          rdnoise = real(imgets.value)
          imgets (pgfile, "rdnoise2")
          rdnoise = (rdnoise + real(imgets.value))/2.
          ccdhedit (pgfile, "rdnoise", rdnoise, type="real")

          ccdhedit (pgfile, "st", "00:00:00.0", type="string")
          ccdhedit (pgfile, "ra", ra, type="string")
          ccdhedit (pgfile, "dec", dec, type="string")
          ccdhedit (pgfile, "epoch", 2000., type="real")

          ccdhedit (pgfile, "airmass", 1., type="real")
  
# recalculate st from UT, run setairmass, setjd (which creates HJD keywored), etc.
          stcoox (pgfile, "yes", >& "dev$null")
          airmas (pgfile, >& "dev$null")
        }

# subtract the bias
        if (biassub == no) {
          if (first == yes) {
            if(access ("bias.fits")) {
              if(access (pgb)) imdel (pgb,verify=no)
              imar (pgfile, "-", "bias.fits", pgb)
              hedit (pgb, "biassub", "bias image \"bias.fits\" was subtracted", \
                add=yes, del=no, verify=no, update=yes, show=no)
             } else {
              imcopy (pgfile, pgb, verb=no)
              hedit (pgb, "biassub", "NO BIAS IMAGE WAS SUBTRACTED", \
                add=yes, del=no, verify=no, update=yes, show=no)
            }
          }
          pgraw = pgfile
          pgfile = pgb
          ityp = "b"
        }

# divide by the flat
        if (flatdiv == no) {
          if (first == yes) {
# select flat for the group of images being processed
            flatimg = ""
            imgets (pgfile, "filter")
            s1 = imgets.value
            if (s1 == "U") {
              flatimg = "uflat.fits"
             } else if (s1 == "B") {
              flatimg = "bflat.fits"
             } else if (s1 == "V") {
              flatimg = "vflat.fits"
             } else if (s1 == "R") {
              flatimg = "rflat.fits"
             } else if (s1 == "I") {
              flatimg = "iflat.fits"
             } else if (s1 == "W") {
              flatimg = "wflat.fits"
             } else if (s1 == "S") {
              flatimg = "sflat.fits"
             } else {
              flatimg = "flat.fits"
            }
            if(!access (flatimg)) flatimg = "flat.fits"
            if(access (flatimg)) {
# check to make sure that flat is normalized in a reasonable image section
#    first define image section
              hselect ((flatimg), "naxis[1]", yes) | scan (ncs)
              nc1 = 0.1*ncs + 0.5
              nc2 = 0.9*ncs
              hselect ((flatimg), "naxis[2]", yes) | scan (nrs)
              nr1 = 0.1*nrs + 0.5
              nr2 = 0.9*nrs
              imsect = "["//str(nc1)//":"//str(nc2)//","//str(nr1)//":"//str(nr2)//"]"

              imstat ((flatimg//imsect), field="mean", format=no) | scan (m1)
              if (m1 < 0.96 || m1 > 1.04) error(1,(flatimg//" is not normalized"))
            }
          }
          if(access (flatimg)) {
            if(access (pgf)) imdel (pgf,verify=no)
            imar (pgfile, "/", flatimg, pgf)
            hedit (pgf, "flatdiv", ("flat image \""//flatimg//"\" was divided"), \
              add=yes, del=no, verify=no, update=yes, show=no)
           } else {
            imcopy (pgfile, pgf, verb=no)
            hedit (pgf, "flatdiv", ("NO FLAT IMAGE WAS AVAILABLE"), \
              add=yes, del=no, verify=no, update=yes, show=no)
          }
          imdel (pgfile,verify=no)
          pgfile = pgf
          ityp = "f"

# run fixpix
          fixpix (pgfile,badpix)
        }
        if (ityp == "f") ityp = "c"

# get sky stats for each image in turn 
        i = strlen(pgfile)
        pg = substr(pgfile,1,i-5)
        chkn = substr(pg,i-9,i-9)
        crfile = pgfile

        j = stridx("f",substr(pg,4,i))+3
        if (j > 3) crfile = substr(crfile,1,j-1)//ityp//substr(crfile,j+1,strlen(crfile))
        crf = substr(crfile,1,i-5)
        satfile = crf//".sat.fits"

# find sky stats in defined sky sections 
        if ( chkn == "." && !access ((crf//".coo.1")) ) {
          for (i=1; i<=3; i+=1) {
            statsec = pg//xy[i]
            imstat (statsec,field="midpt,stddev",form=no) | scan (sky[i],sig[i])
          }
          avsig = (sig[1]+sig[2]+sig[3]) / 3.

          if (pgfile != crfile) {
# replace sky sigs that are grossly out of line (due to cosmicrays) with 110% of theoretical
# count error ( 1.10 * sqrt( n/gain + (rdnoise/gain)^2) )
            maxsig = 1.10*sqrt( (sky[1]+sky[2]+sky[3])/(3.*3.4) + 6.25)
            for (i=1; i<=3; i+=1) {
              if (sig[i] > maxsig) sig[i] = maxsig
            }
            avsig = (sig[1]+sig[2]+sig[3]) / 3.
# run cosmicrays
            if (j > 0) {
              thresh = 4.5 * avsig
              if ( access (crfile) ) imdel ((crfile),verify=no)
# the first pass of cosmicrays gets rid of the negative depressions
              imar (pgfile, "*", -1., crfile)
              cosmicrays (crfile,"",inter=no,window=7,npass=1000,flux=5.,thresh=thresh, crmask="crmask")
              imar (crfile, "*", -1., crfile)
              hedit (crfile, "crcor", delete=yes)

              cosmicrays (crfile,"", inter=no,window=7,npass=1000,flux=5.,thresh=thresh, crmask="crmask")
              imdel (pgfile,verify=no)
            }
          }

# run daofind
         rfactr = 2.25
         afactr = 1.15
         rimexam.radius = rfactr * avfw
         rimexam.fittype = "moffat"
#         rimexam.fittype = "gaussian"
         avfw0 = 0.75 * avfw
          thresh = 5.
#          thresh = 25.
#          thresh = 100

          printf ("% 5.2f  % 5.2f \n",(avfw),(rimexam.radius))
          while (avfw > afactr*avfw0 ) {
            avfw0 = avfw
            while (avfw > 0.) {
              pg = crfile//".coo.1"
              if ( access (pg) ) delete ((pg),verify=no)
              if ( access ("findbrt.out") ) delete ("findbrt.out",verify=no)
              datapars.fwhmpsf = avfw
              datapars.sigma = avsig
              if (avfw > avfw0) printf ("% 5.2f  % 5.2f\n",(avfw),(rimexam.radius))
              daofind (crfile, output="default", thresh=thresh, interactive=no, \
                verify=no)
              findbrt ((crfile),(imdat), >& "findbrt.out" ) 
              if ( access ("errlog") ) {
                delete ("errlog",verify=no)
                if (avfw <= 5.5) thresh = 5.
                avfw =avfw * afactr
                rimexam.radius = rfactr * avfw
                if (avfw > 17.) \
                  error (1,"daofind failed to find all the designated stars")
               } else {
                avfw =-1.
              }
            }

# run imexam to find average fwhm for the cursor positions in "xyfile"
#  ("xyfile" is written by findbrt)
# iterate using somewhat different trial avfw and rfactr if any fwhm are INDEF (ie < 0.)

#            rimexam.fittype = "gaussian"
            imexam (crfile,defkey=",",imagecur="xyfile",use_display=no,display="", \
                >>& "afw")

            avfw = 0.
            j = 0

            for (k=nt; k>=1; k-=1) {
              indf = -1
              tail ("afw", nlines=k) | head (nlines=1) | field (fie="6,11") | grep ("INDE") | fields (fie="1") | scan (indf)
              if (indf == -1  ) {
                tail ("afw", nlines=k) | head (nlines=1) | fields (fie="11") | scan (av[k])
                if( (av[k]) < 25.) {
#                  print ((av[k]))
# standard version, using fwhm's from target and all ref stars to get avfm
                  avfw = avfw + av[k]
                  j = j+1

# special version for J1426, using only fwhm's from ref stars to get avfm
#                if (k == 1 || k == 3 || k == 4) {
#                  avfw = avfw + av[k]
#                  j = j+1
#                }
# special version for J2200, using only fwhm's from ref stars to get avfm
#                if (k == 1 || k == 2 || k == 4) {
#                  avfw = avfw + av[k]
#                  j = j+1
#                }
# special version for J2348, using only fwhm's from brightest ref stars to get avfm
#                if (k == 1 || k == 3 || k == 5 || k == 7 || k == 9 || k == 10) {
#                  avfw = avfw + av[k]
#                  j = j+1
#                }
# special version for SDSS1104, using only fwhm's from brightest ref stars to get avfm
#                if (k == 4 || k == 5 || k == 7 || k == 8) {
#                  avfw = avfw + av[k]
#                  j = j+1
#                }
# special version for SDSS1200, using only fwhm's from brightest ref stars to get avfm
#                if (k == 2 || k == 3 || k == 5 || k == 8) {
#                  avfw = avfw + av[k]
#                  j = j+1
#                }
#
                }
              }
            }

# standard test
            if (j == nt) {

# test for J1426 and J2200
#            if (j == 3) {
# test for SDSS1104 and SDSS1200
#            if (j == 4) {
# test for J2348
#            if (j == 6) {

              avfw = avfw/j 

# if any fwhm were INDEF, adjust starting avfw and rimexam radius, and try again
             } else {
              if (avfw > 0.9*avfw0 && rimexam.radius < 30.) {
                avfw = avfw0
                rfactr = rfactr * 1.025
               } else {
                avfw = 1.8 * 3./bin
                rfactr = 2.00
              }
              avfw0 = 0.75 * avfw
              rimexam.radius = rfactr * avfw
            }

            del ("afw",verify=no)
          }

# get round parameter for current image, save value in ongoing log,
# and calculate rolling average over the last ~4 minutes
          avgtime = 4.
          type ("findbrt.out")
          fie ("findbrt.out", fie=5) | aver | fie (fie=1) | scan (rnd)
          rnds = str(int(1000*rnd+0.5)/1000.)
          if (rnd >= 0.) while (strlen(rnds) < 5) rnds = rnds//"0"
          if (rnd < 0.) while (strlen(rnds) < 6) rnds = rnds//"0"
          printf ("%10.6f %7.3f\n", ut,rnd, >>"round.log")
          dut = 1.
          j = 30
          while (dut > avgtime/60.) {
            tail ("round.log", nlines=j) | head (nlines=1) | fie (field=1) | scan (dut)
            dut = dut - ut
            j = j-1
          }
          tail ("round.log", nlines=j) | fie (field=2) | aver | fie (field=1) | scan (avrnd)
          avrnds = str(int(1000*avrnd+0.5)/1000.)
          if (avrnd >= 0.) while (strlen(avrnds) < 5) avrnds = avrnds//"0"
          if (avrnd < 0.) while (strlen(avrnds) < 6) avrnds = avrnds//"0"
          print ("                                            ------")
          print (("                            current round = "//rnds// \
              ",   rolling avg = "//avrnds))
          delete ("findbrt.out",verify=no)

# test the original, merged, but otherwise unprocessed image to see if any of the
# stars at the positions given in xyfile are saturated (not yet implemented)
#        if (biassub == no) {
#          if (access (pgraw)) {
#            hselect (pgraw, "naxis[1]", yes) | scan (xmid)
#            xmid = xmid/2
#            imgets (pgraw, "ovscmed1")
#            ovscmed1 = real(imgets.value)
#            imgets (pgraw, "ovscmed2")
#            ovscmed2 = real(imgets.value)
#  print ((xmid))
#  print ((ovscmed1))
#  print ((ovscmed2))
#  stop
#            i = 1
#            while (i <= nt) {
#              tail ("xyfile",nlines=i) | head (nlines=1) | scan (xc,yc)
#              mx1 = int(xc - 4 + 0.5) ; mx2 = int(xc + 4 + 0.5)
#              my1 = int(yc - 4 + 0.5) ; my2 = int(yc + 4 + 0.5)
#              sect = pgraw//"["//str(mx1)//":"//str(mx2)//","//str(my1)//":"//str(my2)//"]"
#              imstat (sect, field="max", form=no) | scan (max)
#              if ((xc < xmid && max+ovscmed1 > datamax) || (xc > xmid && max+ovscmed2 > datamax)) {
#                ren (crfile,satfile)
#                i = i + nt
#              }
#              i += 1
#            }
#          }
#        }


# write a line in the skystats file
          print(" ")
          printf("%11s  %8.1f%8.1f%8.1f    %8.3f%8.3f%8.3f       %-6.3f\n", \
             crf,sky[1],sky[2],sky[3],sig[1],sig[2],sig[3],avfw, >>statfile)
          printf("%11s  %8.1f%8.1f%8.1f    %8.3f%8.3f%8.3f       %-6.3f\n", \
             crf,sky[1],sky[2],sky[3],sig[1],sig[2],sig[3],avfw
#          printf("%11s  %8.1f%8.1f%8.1f    %8.3f%8.3f%8.3f       %-6.3f     %-8.3f%-8.3f%-8.3f%-8.3f\n", \
#             crf,sky[1],sky[2],sky[3],sig[1],sig[2],sig[3],avfw,fw[1],fw[2],fw[3],fw[4], >>statfile)
#          printf("%11s  %8.1f%8.1f%8.1f    %8.3f%8.3f%8.3f       %-6.3f     %-8.3f%-8.3f%-8.3f%-8.3f\n", \
#             crf,sky[1],sky[2],sky[3],sig[1],sig[2],sig[3],avfw,fw[1],fw[2],fw[3],fw[4])

        }

# read fwhm from stats file
        if ( chkn == "." && !access ((crf//".mag.1")) ) {
          if ( access ("grepstats.cl") ) delete ("grepstats.cl",verify=no)
          print (("grep "//crf//" "//statfile), >"grepstats.cl")
          grepstats (>>"gstats")
          tail ("gstats",nl=1) | scan (pg,d1,d2,d3,d4,d5,d6,avfw)
          delete ("grepstats.cl,gstats",verify=no)

# run phot (inner annulus radius = (4 + 0.5(aper factor - 2.5)) * avfw)
# use 2.25 most of time; sometimes 2.50 or 2.75 are better:
# for very faint stars, can go as low as 1.5 to 2.0, carefully!

# special case for 17th to 19th mag targets (like faint white dwarfs)
#          aper = 2.0 * avfw
#          if (aper > 8.0) aper = 8.0
#          ann = 4.00 * avfw

# KPD0629: special case to include close companion (4" N) to avoid systematic errors
#          aper = 4.0/0.43 + 1.3*avfw
#          if (aper > 10.0) aper = 10.0
#          ann = 4.00 * avfw

# std cases
          aper = 2.25 * avfw
          ann = 4.00 * avfw
          if (aper > 10.0) aper = 10.0

#  OR
#          aper = 2.50 * avfw
#          ann = 4.25 * avfw
#          if (aper > 15.0) aper = 15.0

#  OR
#          aper = 2.75 * avfw
#          if (aper > 10.125) aper = 10.125
#          ann = 4.50 * avfw


          dann = sqrt(ann*ann + 4.0*aper*aper) - ann
          centerpars.cbox = 2.5*avfw

          phot (crf, fwhmpsf=avfw, annulus=ann, dannulus=dann, \ 
               aperture=aper, >>& photlog)
 
          avfw = av_factr * avfw

        }
        first = no
        if (biassub == no) {
          if (access (pgraw)) imdel (pgraw,verify=no)
        }
        del ("xyfile*",verify=no)

      }

# if filter keyword somehow didn't get written in header initially, 
# skip this image until the next auto_plot cycle
      j = stridx (".",pgfile)
      k = strlen(pgfile)
      pgfile = substr(pgfile,1,j-2)//"c"//substr(pgfile,j,k)
      imgets (pgfile, "filter")
      s1 = imgets.value
      if (s1 == "") {
        s1 = substr(pgfile,1,j-2)//"?"//substr(pgfile,j,j+5)//"*"
        del ((s1))
      }
        
    }

    if (access ((pglst)) ) delete ((pglst),verify=no)
    if (access ("crmask.pl")) delete ("crmask.pl",verify=no)
    if (access ("logfile")) delete ("logfile",verify=no)
    if (access ("pixels")) rmdir ("pixels")

    }
end
