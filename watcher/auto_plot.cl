# Task to display radial plots of the sdB star and 2 or 3 of the 
# standard stars in the image 
# The pixel coordinates in the specified imdat file are used.
# The difference of the two FWHM's from the radial fit is printed.  
# Also prints the position error of the sdB star in arcsec

procedure auto_plot(image0)

string image0		{prompt="Input image"}

string imdat_file	{prompt="Imdat file"}
string left	= "North" {prompt="Image left direction [NSEW]", \
				enum="North|South|East|West"}
int star1st	=1	{prompt="# of the 1st standard star in the imdat file"}
int star2nd	=2	{prompt="# of the 2nd standard star in the imdat file"}
int star3rd	=3	{prompt="# of the 3rd standard star in the imdat file (0=none)"}
int magstar     =0	{prompt="Which mag in log: 0=sdB, 1=1st, 2=2nd, 3=3rd",min=0,max=3}
int pause	=2	{prompt="Number of seconds to pause between plots"}
struct *starfile
struct *iexmlog

begin

	real SCALE1 = 0.143	# Arcsec per pixel in 1x1 binning

# Margin (pixels) around image to exclude from sky MIDPT
	int MARGIN = 10

# Half-width (in 3x3 binning) for sanity check before calling imexam
# If the maximum value in a box of this size centered on the star is not
# bigger than MINPEAK, imexam will not be called to fit a radial profile for
# that star  (If the star is the sdB star, no further processing is done.)
# (Scaled up or down according to the actual CCD binning used)
	int BIN3RAD = 15
	int MINPEAK = 35

	string image, iname, tname, fname, s1, s2, s3, s4, xdir, ydir
	string right, up, down
	int bin, sdb_num, i, j, nstar, nymax, iymax, ndf[2], last_imexam
	int imin, imax, jmin, jmax, nxpix, nypix, chk_rad, nmax_star
	real scale, x, y, sdbx, sdby = -1
	real x_star[15] = 15(0)
	real y_star[15] = 15(0)
	real avfwhm, df, fwhm[0:3] = 4(0)
	real mag2log, sky, smax
	int dfwhm[2],maxdim
	real mag, flux, peak, enclosed, moffat, direct, dx, dy, test
	struct txtline
	bool heading

        maxdim = 15

	image = image0
	i = strlen(image)
	if (substr(image,i-4,i) != ".fits") image = image//".fits"
	if (!access(image)) error(1, "Cannot access image file "//image)
	i = strlen(image)
	iname = substr(image, 1, i-5)		# Get rid of ".fits"

# Check image type
	imgets(image, "imagetyp")
        tname = substr(image,1,4)
	if ((tname == "test" || substr(image,1,5) == "focus" \
            || substr(image,1,3) == "ifr") || imgets.value != "object") {
	  print("Skipping auto_plot for ", (image))
	  return
	 } else {
	  print("Executing autoplot (\"", image, "\")")
	}

# Get CCD binning
	imgets(image, "ccdsum")
	i = fscan(imgets.value, bin)
	scale = bin*SCALE1
	chk_rad = nint(BIN3RAD*3/bin)

# Get image size
	imgets(image, "naxis1")
	i = fscan(imgets.value, nxpix)
	imgets(image, "naxis2")
	i = fscan(imgets.value, nypix)

# Open the imdat file
	fname = imdat_file
	if (!access(fname)) {
          print ("Cannot access imdat file ", fname)
	  return
        }
	starfile = fname

# Get the image orientation
	s1 = substr(left, 1, 1)
	if (s1 == "N") {
	  up = "West"
	  right = "South"
	  down = "East"
	} else if (s1 == "E") {
	  up = "North"
	  right = "West"
	  down = "South"
	} else if (s1 == "S") {
	  up = "East"
	  right = "North"
	  down = "West"
	} else if (s1 == "W") {
	  up = "South"
	  right = "East"
	  down = "North"
	} else
	  error (1, "Illegal value for left: "//left)

# Get star coordinates from imdat file
	for (j=0; j<7; j+=1) {
	  if (fscan (starfile, txtline) == EOF) {
	    error(1, "Error skipping to stars in "//fname)
	  }
	}
	sdb_num = -1
	nstar = 0
	while (fscan (starfile, txtline) != EOF) {
	  j = fscan(txtline, i, x, y)
	  if (j == 3 && i > 0 && i <= maxdim) {
	    x_star[i] = x		# It's a star coordinate
	    y_star[i] = y
	    nstar = max(nstar, i)
	  } else if (j == 1) {
	    sdb_num = i			# It's the sdB star number
	  }
	}
	if (nstar == 0) error(1, "No star coords found in "//fname)
	if (sdb_num == -1) error(1, "No sdB star number found in "//fname)

# Make sure the star numbers are legal
	if (sdb_num > nstar) error(1, "Illegal sdB star number in "//fname)

	if (star1st <= 0 || star1st > nstar) \
			error(1, "star1st #("//str(star1st)//") illegal")
	if (star2nd <= 0 || star2nd > nstar) \
			error(1, "star2nd #("//str(star2nd)//") illegal")
	if (star3rd < 0 || star3rd > nstar) \
			error(1, "star3rd #("//str(star3rd)//") illegal")

	if (star3rd == 0 && magstar == 3) {
	  print("Can't use 3rd star for magnitude if it is skipped.  Using sdB instead")
	  magstar = 0
	}

# Make sure all the stars were found in the file
	if (x_star[sdb_num] == 0)
	    	error(1, "sdB star coordinates not found in "//fname);
	if (x_star[star1st] == 0)
	    	error(1, "star1st #("//str(star1st)//") not found in "//fname);
	if (x_star[star2nd] == 0)
	    	error(1, "star2nd #("//str(star2nd)//") not found in "//fname);
	if (star3rd != 0 && x_star[star3rd] == 0)
	    	error(1, "star3rd #("//str(star3rd)//") not found in "//fname);

# We will need a heading if auto_plot.log doesn't exist or is empty
	heading = !access("auto_plot.log")
	if (!heading) {
	  starfile = "auto_plot.log"
          if (fscan(starfile, txtline) == EOF)
	    heading = yes			# It's an empty file
	}
	if (heading) {
# Put in a heading
	  printf("sdB is #%d, 1st star is #%d, 2nd star is #%d, 3rd star is #%d\n",
		sdb_num, star1st, star2nd, star3rd, >>"auto_plot.log")
	  if (magstar == 0)
	    s1 = "sdB"
	  else
	    s1 = "#"//str(magstar)//" "
	  if (star3rd == 0) {
	    print("                            ", s1, "   ----- FWHM -----",\
	  						>>"auto_plot.log")
	    s1 = "   File    Center (arcsec)  Mag     sdB     #%d    #%d"
	    s1 = s1//"    FWHM difference\n"
	    printf(s1, star1st, star2nd, >>"auto_plot.log")
	  } else {
	    print("                            ", s1, "   -------- FWHM --------",\
	  						>>"auto_plot.log")
	    s1 = "   File    Center (arcsec)  Mag     sdB     #%d    #%d    #%d"
	    s1 = s1//"         FWHM differences\n"
	    printf(s1, star1st, star2nd, star3rd, >>"auto_plot.log")
	  }
	}

# Get the mean sky value
	imin = 1 + MARGIN
	jmin = imin
	imax = nxpix - MARGIN
	jmax = nypix - MARGIN
	s1 = "["//str(imin)//":"//str(imax)//","//str(jmin)//":"//str(jmax)//"]"
	imstat(image//s1, field="midpt", format=no) | scan(sky)

# Check that there's a star at the sdB star position
	i = nint(x_star[sdb_num])
	imin = i - chk_rad
	imax = i + chk_rad
	j = nint(y_star[sdb_num])
	jmin = j - chk_rad
	jmax = j + chk_rad
	s1 = "["//str(imin)//":"//str(imax)//","//str(jmin)//":"//str(jmax)//"]"
	imstat(image//s1, field="max", format=no) | scan(smax)
	if (smax-sky < MINPEAK) {
	  beep
	  print(iname, " No star found at sdB star position.  Clouds?", \
							>>"auto_plot.log")
	  return
	}
	nmax_star = sdb_num
	
# Fit and plot the radial profiles of the sdB star and the specified stars
	if (access("ilog")) del ("ilog",verify=no)
	if (access("xydat")) del ("xydat",verify=no)

# sdB star radial profile
	print ("sdB star [ #", sdb_num, "]", >>"ilog")
	print (x_star[sdb_num], y_star[sdb_num], >"xydat")
	last_imexam = sdb_num
	imexam(image, defkey="r", imagecur="xydat", use_display=no, display="", \
		logfile="ilog", keeplog=yes, >& "dev$null")

	del ("xydat",verify=no)

        if (y_star[star1st] > y_star[star2nd]) { 
          nymax = star1st
          iymax = 1
        } else {
          nymax = star2nd
          iymax = 2
	}

# Check that there's a star at the star1st position
	i = nint(x_star[star1st])
	imin = i - chk_rad
	imax = i + chk_rad
	j = nint(y_star[star1st])
	jmin = j - chk_rad
	jmax = j + chk_rad
	s1 = "["//str(imin)//":"//str(imax)//","//str(jmin)//":"//str(jmax)//"]"
	imstat(image//s1, field="max", format=no) | scan(peak)
	if (peak-sky < MINPEAK) {
	  beep
	  print(iname, " No star found at star1st position.  Clouds?", \
							>>"auto_plot.log")
	  printf("# DUMMY IMEXAM COORDINATES OUTPUT\n 0\n", >>"ilog")
	  sleep(pause)
	} else {
	  if (smax < peak) {
	    smax = peak			# Remember the one with the most counts
	    nmax_star = star1st
	  }
# OK to do star1st radial profile
          print (x_star[star1st], y_star[star1st], >"xydat")
          print ("Star #", star1st, >>"ilog")
#         beep
          sleep(pause)
	  last_imexam = star1st
          imexam(image, defkey="r", imagecur="xydat", use_display=no, display="", \
                  logfile="ilog", keeplog=yes, >& "dev$null")

#         beep
          del ("xydat",verify=no)
	}
# Check that there's a star at the star2nd position
	i = nint(x_star[star2nd])
	imin = i - chk_rad
	imax = i + chk_rad
	j = nint(y_star[star2nd])
	jmin = j - chk_rad
	jmax = j + chk_rad
	s1 = "["//str(imin)//":"//str(imax)//","//str(jmin)//":"//str(jmax)//"]"
	imstat(image//s1, field="max", format=no) | scan(peak)
	if (peak-sky < MINPEAK) {
	  beep
	  print(iname, " No star found at star2nd position.  Clouds?", \
							>>"auto_plot.log")
	  printf("# DUMMY IMEXAM COORDINATES OUTPUT\n 0\n", >>"ilog")
	  sleep(pause)
	} else {
	  if (smax < peak) {
	    smax = peak			# Remember the one with the most counts
	    nmax_star = star2nd
	  }
# OK to do star2nd radial profile
          print (x_star[star2nd], y_star[star2nd], >"xydat")
          print ("Star #", star2nd, >>"ilog")
          sleep(pause)
	  last_imexam = star2nd
          imexam(image, defkey="r", imagecur="xydat", use_display=no, display="", \
                  logfile="ilog", keeplog=yes, >& "dev$null")

#         beep
          del ("xydat",verify=no)
	}
  	if (star3rd != 0) {
# Check that there's a star at the star3rd position
          i = nint(x_star[star3rd])
          imin = i - chk_rad
          imax = i + chk_rad
          j = nint(y_star[star3rd])
          jmin = j - chk_rad
          jmax = j + chk_rad
          s1 = "["//str(imin)//":"//str(imax)//","//str(jmin)//":"//str(jmax)//"]"
          imstat(image//s1, field="max", format=no) | scan(peak)
          if (peak-sky < MINPEAK) {
            beep
            print(iname, " No star found at star3rd position.  Clouds?", \
                                                          >>"auto_plot.log")
            printf("# DUMMY IMEXAM COORDINATES OUTPUT\n 0\n", >>"ilog")
            sleep(pause)
          } else {
  	    if (smax < peak) {
	      smax = peak		# Remember the one with the most counts
	      nmax_star = star3rd
	    }
# OK to do star3rd radial profile
            print (x_star[star3rd], y_star[star3rd], >"xydat")
            print ("Star #", star3rd, >>"ilog")
            if (y_star[nymax] < y_star[star3rd]) { 
              nymax = star3rd
              iymax = 3
            }
            sleep(pause)
	    last_imexam = star3rd
            imexam(image, defkey="r", imagecur="xydat", use_display=no, \
                  display="", logfile="ilog", keeplog=yes, >& "dev$null")

#           beep
    	    del ("xydat",verify=no)
          }
	}
	if (last_imexam != nmax_star) {
# Display the brightest star again
	  print(x_star[nmax_star], y_star[nmax_star], >"xydat")
	  sleep(pause)
          imexam(image, defkey="r", imagecur="xydat", use_display=no, \
                  display="", logfile="", keeplog=no, >& "dev$null")
    	  del ("xydat",verify=no)
	}
# Read back the results
	iexmlog = "ilog"
	j = 0
	while (fscan(iexmlog, txtline) != EOF) {
	  i = fscan(txtline, s1, s2, s3, s4)
	  if (i == 4 && s4 == "COORDINATES") {
# Get the radial fit parameters for the next star
	    if (fscan(iexmlog, txtline) != EOF) {
	      i = fscan(txtline, x,y, s1,s1,s1, mag, flux, s1, peak, \
			s1,s1,s1, enclosed, moffat, direct)
	      if (i > 6 && j == magstar) mag2log = mag	 # This magnitude in log

# Get the sdB star coordinates
	      if (i >= 2 && j == 0) {
		sdbx = x
		sdby = y
	      }
	      if (i > 14) {
	        test = mag + flux + peak + enclosed + moffat + direct
	        if (test != INDEF && flux > 100 && peak > 100) {
#		  fwhm[j] = moffat
		  fwhm[j] = direct
	        }
	      }
	      if (j == 3 || (j == 2 && star3rd == 0) )
	        break				# All done
	      j += 1
	    }
	  }
	}
# Convert the pointing error to arcsec
	if (sdby > 0) {
	  dx = scale*(sdbx - x_star[sdb_num])
	  dy = scale*(sdby - y_star[sdb_num])
      	  if (dx < 0) {
    	    xdir = left
    	    dx = -dx
    	  } else
    	    xdir = right
      	  if (dy < 0) {
    	    ydir = down
    	    dy = -dy
    	  } else
    	    ydir = up
  	} else
	  dy = INDEF

# Calculate the mean FWHM and the differences
	dfwhm[1] = INDEF
	dfwhm[2] = INDEF
	j = 0
	if (fwhm[iymax] != 0) {
          avfwhm = (fwhm[1] + fwhm[iymax])/2.  
          if (star1st != nymax && fwhm[1] != 0) {
            j += 1
            df = 100.*(fwhm[1]-fwhm[iymax])/avfwhm
            if (df > 0)
              dfwhm[j] = int(df+.5)
            else
              dfwhm[j] = int(df-.5)
            ndf[j] = star1st
          }
          avfwhm = (fwhm[2] + fwhm[iymax])/2.  
          if (star2nd != nymax && fwhm[2] != 0) {
            j += 1
            df = 100.*(fwhm[2]-fwhm[iymax])/avfwhm
            if (df > 0)
              dfwhm[j] = int(df+.5)
            else
              dfwhm[j] = int(df-.5)
            ndf[j] = star2nd
          }
          avfwhm = (fwhm[3] + fwhm[iymax])/2.  
          if (star3rd != 0 && fwhm[3] != 0 && star3rd != nymax) {
            j += 1
            df = 100.*(fwhm[3]-fwhm[iymax])/avfwhm
            if (df > 0)
              dfwhm[j] = int(df+.5)
            else
              dfwhm[j] = int(df-.5)
            ndf[j] = star3rd
          }
  	}
	if (j == 0) {
	  if (star3rd == 0) {
	    s1 = "%s  %.1f %c, %.1f %c   %5.2f   %5.2f %5.2f %5.2f\n"
	    printf(s1, iname, dx, substr(xdir,1,1), dy, substr(ydir,1,1), \
			mag2log, fwhm[0], fwhm[1], fwhm[2], >>"auto_plot.log")
	  } else {
	    s1 = "%s  %.1f %c, %.1f %c   %5.2f   %5.2f %5.2f %5.2f %5.2f\n"
	    printf(s1, iname, dx, substr(xdir,1,1), dy, substr(ydir,1,1), \
			mag2log, fwhm[0], fwhm[1], fwhm[2], fwhm[3], \
			>>"auto_plot.log")
	  }
	} else if (j == 1) {
	  if (star3rd == 0) {
	    s1 = "%s  %.1f %c, %.1f %c   %5.2f   %5.2f %5.2f %5.2f    "
	    s1 = s1//"#%d-#%d: %3d%%\n"
	    printf(s1, iname, dx, substr(xdir,1,1), dy, substr(ydir,1,1), \
			mag2log, fwhm[0], fwhm[1], fwhm[2], ndf[1], nymax, \
			dfwhm[1], >>"auto_plot.log")
	  } else {
	    s1 = "%s  %.1f %c, %.1f %c   %5.2f   %5.2f %5.2f %5.2f %5.2f    "
	    s1 = s1//"#%d-#%d: %3d%%\n"
	    printf(s1, iname, dx, substr(xdir,1,1), dy, substr(ydir,1,1), \
			mag2log, fwhm[0], fwhm[1], fwhm[2], fwhm[3], ndf[1], \
			nymax, dfwhm[1], >>"auto_plot.log")
	  }
	} else {
	  s1 = "%s  %.1f %c, %.1f %c   %5.2f   %5.2f %5.2f %5.2f %5.2f    "
	  s1 = s1//"#%d-#%d: %3d%%   #%d-#%d: %3d%%\n"
	  printf(s1, iname, dx, substr(xdir,1,1), dy, substr(ydir,1,1), mag2log,\
		fwhm[0], fwhm[1], fwhm[2], fwhm[3], ndf[1], nymax, dfwhm[1], \
		ndf[2], nymax, dfwhm[2], >>"auto_plot.log")
	}
# Equivalent to a close
	starfile = ""
	iexmlog = ""

# clean up files
        delete ("ilog")
end
