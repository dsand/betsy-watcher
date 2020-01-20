# Find the scaling factor for removing fringes from the input file(s)
# Scale the <fringe> image by this factor and subtract it from the original
# Write the result into a file named the same as the input file except that
# the suffix letter of the root name is changed to "d" (usually from "c").
# The factor chosen is put in the header as "frng_fac"
# To skip pixels around the edges when calculating the factor, set 
# edge_skip to the number of pixels to skip

procedure defringe(Input)

string Input 			{prompt="Input file/template"}
string fringe = "ifringe.fits"	{prompt="Fringe file name"}
int edge_skip = 4		{prompt="Width of edges to ignore"}
struct *img_list

begin

	string input, fname, cname, dname, zfringe, expression, what_reg
	real rms, thresh, factor, mean
	int xorder, yorder, i, n, maxrow, maxcol

	input = Input
	n = strlen(fringe)

	zfringe = fringe
	if (substr(zfringe,n-4,n) == ".fits") zfringe = substr(zfringe,1,n-5)
	zfringe = zfringe//"_zero.fits"
	if (substr(fringe,n-4,n) != ".fits") fringe = fringe//".fits"

	if (!access(fringe))
	  error(1, "Cannot access fringe file: "//fringe)

	if (!access(zfringe)) {
# Make a fringe file with pixels < 0.1 amplitude of the fringe set to zero
	  imstat(fringe, fields="stddev", format-) | scan(rms)
# Calculate what should be 0.1 x amplitude of the fringes
	  thresh = 0.25*rms
# Substitute 0 for any values less than this threshold
	  expression = str(thresh)//"< abs(a) ? a : 0"
	  imexpr(expression, zfringe, fringe, >& "dev$null") 
	}
	
# imsurfit order for a fit of a plane to the input image
	xorder = 2
	yorder = 2

        if (access("tmp.fits")) delete("tmp.fits", verify=no)
        if (access("tmpf.fits")) delete("tmpf.fits", verify=no)
        if (access("tmp.sec")) delete("tmp.sec", verify=no)
        if (access("tmp.input")) delete("tmp.input", verify=no)

	if (edge_skip <= 0)
	  what_reg = "all"		# Not skipping edges
	else {
# Get image size for edge skipping
          imgets(fringe, "naxis1")
          maxcol = int(imgets.value)
          imgets(fringe, "naxis2")
          maxrow = int(imgets.value)
# Write for imsurfit
	  print((edge_skip+1), (maxcol-edge_skip), (edge_skip+1), \
					(maxrow-edge_skip), >"tmp.sec")
	  what_reg = "section"
	}

        files(input, >"tmp.input")

	img_list = "tmp.input"
	while (fscan(img_list, fname) != EOF) {

# Delete these 2 when not debugging
#          if (access("tmp.fits")) delete("tmp.fits", verify=no)
#          if (access("tmpf.fits")) delete("tmpf.fits", verify=no)

	  n = strlen(fname)
          if (substr(fname, n-4, n) != ".fits") {
            fname = fname//".fits"              # Assume .fits
	    n = n + 5
	  }

          if (!access(fname)) 
            error(1, "No input image found: "//fname//" (template="//input//")")
	  cname = "cln"//fname
	  i = stridx(".", fname)
	  dname = substr(fname,1,i-2)//"d"//substr(fname,i,n)

	  if (access(cname)) delete(cname, verify=no)
	  imsurfit(fname, cname, xorder, yorder, type_output="clean", \
		function="chebyshev", xmedian=1, ymedian=1, lower=4, \
		upper=4, ngrow=5, niter=5, regions=what_reg, sections="tmp.sec")
	  imstat(cname, fields="mean", format-) | scan(mean)
	  imarith(cname, "-", mean, "tmp.fits")
	  imarith("tmp.fits", "/", zfringe, "tmp.fits", divzero = -999)
	  imstat("tmp.fits", fields="mean", lower=-998, format-) | scan(factor)
	  imarith(fringe, "*", factor, "tmpf.fits")
	  if (access(dname)) delete(dname, verify=no)
	  imarith(fname, "-", "tmpf.fits", dname)
	  hedit(dname, "frng_fac", (factor), add+, show+, verify-, update+)

# Remove comment #'s when done debugging
          delete("tmp.fits", verify=no)
          delete("tmpf.fits", verify=no)
	}
        delete("tmp.input", verify=no)
	if (edge_skip > 0) delete("tmp.sec", verify=no)
end
