# task to extract magnitudes from pg*mag.1 files and calculate
# differential magnitudes (sdB - average of comparison stars)
# for up to 13 reference stars

procedure dmag (pg0,resfile)

string     pg0          {prompt="pg root name (i.e. pg0025) "}
string     resfile      {prompt="alternate residuals file (<enter>, if not) "}

bool newres
struct *imdatfile
struct *magsfile
struct *coofile
struct *dmaglist

begin
    struct magsline
    string imdat,imdatline
    string pg,imlist,coolist,maglist,tmpfile,img,sect,flds,boo,xn,jlist,joinfile,txt
    string xcn,jclist
    string filt,mag0,mag1,mags,title,magfile,dmagfile,sigfile,resf,resfalt,refn,plfile,xm
    string f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19
    string f20,f21,f22,f23,f24,f25,f26
    int bin,nt,ns,i,n,hrnd,j,m[14],l[14]
    real xc,yc,max,hjd0,hjd,hlast,mag[14],e[14],amag[14],tmp,cmp,diff,ws,w,sig,x[14],y[14]
    real v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11,v12,e12,v13,e13
    real h1,h2,gain,xairm,datamax,ymin,ymax

    cache imgets

# 90" ccd21big:
#    datamax = 60500
# 61" 4kccd (saturation value depends on position on chip, due to flat fielding):
    datamax = 100000


    f1 = INDEF; f2 = INDEF; f3 = INDEF; f4 = INDEF; f5 = INDEF; f6 = INDEF; f7 = INDEF
    f8 = INDEF; f9 = INDEF; f10 = INDEF; f11 = INDEF; f12 = INDEF; f13 = INDEF; f14 = INDEF
    f15 = INDEF; f16 = INDEF; f17 = INDEF; f18 = INDEF; f19 = INDEF; f20 = INDEF
    f21 = INDEF; f22 = INDEF; f23 = INDEF; f24 = INDEF ; f25 = INDEF; f26 = INDEF
    v1 = INDEF; v2 = INDEF; v3 = INDEF; v4 = INDEF; v5 = INDEF; v6 = INDEF; v7 = INDEF
    v8 = INDEF; v9 = INDEF; v10 = INDEF; v11 = INDEF; v12 = INDEF; v13 = INDEF
    e1 = INDEF; e2 = INDEF; e3 = INDEF; e4 = INDEF; e5 = INDEF; e6 = INDEF; e7 = INDEF
    e8 = INDEF; e9 = INDEF; e10 = INDEF; e11 = INDEF; e12 = INDEF; e13 = INDEF

    pg = pg0

# make list of possible images; try *d.nnnn.fits first, in case defringed I images exist
    img = ""
    imlist = mktemp ("chk")
    files ((pg//"d.*.fits"), >imlist)
    head ((imlist), nlines=1) | scan (img)
    del (imlist,verify=no)
# if no *d.nnnn.fits images, then look for the usual *c.nnnn.fits images
    if (img == "") {
      files ((pg//"c.*.fits"), >imlist)
      head ((imlist), nlines=1) | scan (img)
      del (imlist,verify=no)
      if (img == "") error(1,"no "//pg//"*fits files found")
    }

# determine which imdat file to use (using header info in first image only)
    imdat = "imdat"
    imgets (img, "ccdsum")
    imdatline = imgets.value
    if (substr(imdatline,1,3) == "1 1") {
      bin = 1
      imdat = imdat//"1."//pg
     } else if (substr(imdatline,1,3) == "2 2") {
      bin = 2
      imdat = imdat//"2."//pg
     } else if (substr(imdatline,1,3) == "3 3") {
      bin = 3
      imdat = imdat//"3."//pg
     } else if (substr(imdatline,1,3) == "4 4") {
      bin = 4
      imdat = imdat//"4."//pg
     } else {
      imdat = "imdat"
    }
    if (!access(imdat)) error(1,(imdat//" file not found"))

# open imdat file and get title, total # of stars, and sdB #
    imdatfile = imdat
    for (i=1; i<=7; i+=1) {
      nt = fscan (imdatfile,imdatline)
      if (i == 2) title = imdatline
    }
    while (fscan (imdatfile,imdatline) != EOF) {
      if(substr(imdatline,1,1) != "#")  {
        nt = int(imdatline)
       } else {
        i = fscan(imdatfile,imdatline)
        ns = int(imdatline)
      }
    }

    if (nt < 2 || nt > 13) \
      error(1,"total number of stars is not between 2 and 13, or there are extra lines in imdat file")

# look up electrons/adu in image header
    imgets (img, "gain")
    gain = real(imgets.value)

# clean up old files before starting
    tmpfile = pg//".mag?,"//pg//".mag1?"
    delete ((tmpfile),verify=no)
    tmpfile = pg//".co?nts"
    delete ((tmpfile),verify=no)
    if (access ("hjd")) delete ("hjd",verify=no)
    if (access ("airm")) delete ("airm",verify=no)
    delete ("x?,x1?,pgf*,pgc*,d??.r*",verify=no)

# get coords of stars from coordinate file; if brightest pixel
#  of any listed star is starting to saturate, delete the corresponding
#  magnitude files .mag.1, .mag.2, etc,  so that image won't be used
#    coolist = mktemp ("coo")
#    files ((pg//"*.????.coo.1"), >coolist)
#    coofile = coolist
#    while (fscan (coofile,txt) != EOF) {
#      i = strlen(pg)
#      img = substr(txt,1,i+stridx("oo",substr(txt,i+1,strlen(txt)))-3)
#      mag0 = img//".mag.0"
#      if ( !access (mag0) ) {
#        i = 1
#        while (i <= nt) {
#          tail (txt,nl=i) | head (n=1) | scan (xc,yc,v1,v2,e1,e2,j)
#          m[1] = int(xc - 4 + 0.5) ; m[2] = int(xc + 4 + 0.5)
#          l[1] = int(yc - 4 + 0.5) ; l[2] = int(yc + 4 + 0.5)
#          sect = img//"["//str(m[1])//":"//str(m[2])//","//str(l[1])//":"//str(l[2])//"]"
#          imstat (sect, field="max", form=no) | scan (max)
#          if (max > datamax) {
#            mag1 = img//".mag.?"
#            del (mag1,verify=no)
#            i = i + nt
#          }
#          i += 1
#        }
# create .mag.0 file for all images where brightness has been checked, 
# so won't have to check again (saves a lot of time)
#        touch (mag0)
#      }
#    }
#    delete (coolist,verify=no)

# get filter name used in these images (actually checks only the last image)
    imgets (img,"filter")
    filt = imgets.value

# look for photometry errors and print any that are found
    !egrep " Err" *.????.mag.?
    !egrep "INDEF" *.????.mag.?

# use txdump to list individual magnitude files, then select magnitude and mag 
# error columns; do the same for total star counts
    for (n=1; n<=nt; n+=1) {
      tmpfile = pg//".mag"//str(n)
      maglist = pg//"*.????.mag.?"
      flds = "image,xc,yc,ifilter,xairmass,otime,mag,merr,pier,perror,flux"
      boo = "(id == "//str(n)//")"
      txdump (maglist, flds, boo, > tmpfile)
      if(n == 1) {
        fields (tmpfile, field="6") | scan (hjd)
        hrnd = 10*int(hjd/10)
        fields (tmpfile, field="6,5,7-8", >"x1")
        jlist = "x1"
        fields (tmpfile, field="6,5,11", >"xc1")
        jclist = "xc1"
      } else {
        xn = "x"//str(n)
        fields (tmpfile, field="7-8", >xn)
        jlist = jlist//","//xn
        xcn = "xc"//str(n)
        fields (tmpfile, field="11", >xcn)
        jclist = jclist//","//xcn
      }
    }

# join count files and format them
    mags = pg//".counts"
    joinfile = mktemp ("pgc")
    txt = "#hjd-"//hrnd//"   X    "
    for (n=1; n<=nt; n+=1) {
      txt = txt//"       "//filt//str(n)//"     "
    }
    print((txt), >joinfile)
    print((txt), >mags)
    join (jclist, maxchars=300, >>joinfile)

    magsfile = joinfile
    hlast = 0.
    hjd0 = 0.
    while (fscan (magsfile,magsline) != EOF) {
      if (nt == 2) {
           i = fscan(magsline,txt,xm,f1,f2)
       } else if (nt == 3) {
           i = fscan(magsline,txt,xm,f1,f2,f3)
       } else if (nt == 4) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4)
       } else if (nt == 5) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5)
       } else if (nt == 6) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6)
       } else if (nt == 7) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7)
       } else if (nt == 8) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8)
       } else if (nt == 9) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9)
       } else if (nt == 10){
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10)
       } else if (nt == 11){
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11)
       } else if (nt == 12){
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12)
       } else if (nt == 13){
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13)
	}
  
      
      if (substr(txt,1,1) != "#") {
        hjd = real(txt)
        if (hjd < hlast) {
          error (1,"HJD glitch starting at HJD = "//hjd)
        }
        hlast = hjd
        hjd -= hrnd
        if (hjd0 == 0.) hjd0 = hjd
        if (hjd < hjd0) hjd = hjd + 10.
        xairm = real(xm)
        if (f1 == "INDEF") {
          v1 = 0.0
        } else {
          v1 = gain*real(f1)
        }
        if (f2 == "INDEF") {
          v2 = 0.0
        } else {
          v2 = gain*real(f2)
        }
        if (f3 == "INDEF") {
          v3 = 0.0
        } else {
          v3 = gain*real(f3)
        }
        if (f4 == "INDEF") {
          v4 = 0.0
        } else {
          v4 = gain*real(f4)
        }
        if (f5 == "INDEF") {
          v5 = 0.0
        } else {
          v5 = gain*real(f5)
        }
        if (f6 == "INDEF") {
          v6 = 0.0
        } else {
          v6 = gain*real(f6)
        }
        if (f7 == "INDEF") {
          v7 = 0.0
        } else {
          v7 = gain*real(f7)
        }
        if (f8 == "INDEF") {
          v8 = 0.0
        } else {
          v8 = gain*real(f8)
        }
        if (f9  == "INDEF") {
          v9 = 0.0
        } else {
          v9 = gain*real(f9)
        }
        if (f10 == "INDEF") {
          v10 = 0.0
        } else {
          v10 = gain*real(f10)
        }
        if (f11 == "INDEF") {
          v11 = 0.0
        } else {
          v11 = gain*real(f11)
        }
        if (f12 == "INDEF") {
          v12 = 0.0
        } else {
          v12 = gain*real(f12)
        }
        if (f13 == "INDEF") {
          v13 = 0.0
        } else {
          v13 = gain*real(f13)
        }

        if (nt == 2) {
          printf("%10.7f%7.3f%15.1f%14.1f\n",\
             hjd,xairm,v1,v2, >>mags)
         } else if (nt == 3) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3, >>mags)
         } else if (nt == 4) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4, >>mags)
         } else if (nt == 5) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5, >>mags)
         } else if (nt == 6) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6, >>mags)
         } else if (nt == 7) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7, >>mags)
         } else if (nt == 8) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7,v8, >>mags)
         } else if (nt == 9) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7,v8,v9, >>mags)
         } else if (nt == 10) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10, >>mags)
         } else if (nt == 11) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11, >>mags)
         } else if (nt == 12) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12, >>mags)
         } else if (nt == 13) {
          printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
             hjd,xairm,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13, >>mags)
      	}
   	 }
	}
    delete ((joinfile//",xc?,xc??"),verify=no)

# join magnitude files and format them
    mags = pg//".mags"
    joinfile = mktemp ("pgf")
    txt = "#hjd-"//hrnd//"   X    "
    for (n=1; n<=nt; n+=1) {
      txt = txt//"   "//filt//str(n)//"     "//filt//"err"//str(n)//"    "
    }
    print((txt), >joinfile)
    print((txt), >mags)
    join (jlist, maxchars=350, >>joinfile)

    magsfile = joinfile
    hlast = 0.
    hjd0 = 0.
    while (fscan (magsfile,magsline) != EOF) {
      if (nt == 2) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4)
       } else if (nt == 3) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6)
       } else if (nt == 4) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8)
       } else if (nt == 5) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10)
       } else if (nt == 6) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12)
       } else if (nt == 7) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14)
       } else if (nt == 8) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16)
       } else if (nt == 9) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18)
       } else if (nt == 10) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19,f20)
       } else if (nt == 11) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19,f20,f21,f22)
       } else if (nt == 12) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19,f20,f21,f22,f23,f24)
       } else if (nt == 13) {
           i = fscan(magsline,txt,xm,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19,f20,f21,f22,f23,f24,f25,f26)
      }

      if (substr(txt,1,1) != "#") {
        hjd = real(txt)
        hlast = hjd
        hjd -= hrnd
        if (hjd0 == 0.) hjd0 = hjd
        if (hjd < hjd0) hjd = hjd + 10.
        xairm = real(xm)
        if (f1 == "INDEF" || f2 == "INDEF") {
          v1 = 99.0
          e1 = 99.0
        } else {
          v1 = real(f1)
          e1 = real(f2)
        }
        if (f3 == "INDEF" || f4 == "INDEF") {
          v2 = 99.0
          e2 = 99.0
        } else {
          v2 =  real(f3)
          e2 =  real(f4)
        }
        if (f5 == "INDEF" || f6 == "INDEF") {
          v3 = 99.0
          e3 = 99.0
        } else {
          v3 =  real(f5)
          e3 =  real(f6)
        }
        if (f7 == "INDEF" || f8 == "INDEF") {
          v4 = 99.0
          e4 = 99.0
        } else {
          v4 =  real(f7)
          e4 =  real(f8)
        }
        if (f9 == "INDEF" || f10 == "INDEF") {
          v5 = 99.0
          e5 = 99.0
        } else {
          v5 =  real(f9)
          e5 =  real(f10)
        }
        if (f11 == "INDEF" || f12 == "INDEF") {
          v6 = 99.0
          e6 = 99.0
        } else {
          v6 =  real(f11)
          e6 =  real(f12)
        }
        if (f13 == "INDEF" || f14 == "INDEF") {
          v7 = 99.0
          e7 = 99.0
        } else {
          v7 =  real(f13)
          e7 =  real(f14)
        }
        if (f15 == "INDEF" || f16 == "INDEF") {
          v8 = 99.0
          e8 = 99.0
        } else {
          v8 =  real(f15)
          e8 =  real(f16)
        }
        if (f17 == "INDEF" || f18 == "INDEF") {
          v9 = 99.0
          e9 = 99.0
        } else {
          v9 =  real(f17)
          e9 =  real(f18)
        }
         if (f19 == "INDEF" || f20 == "INDEF") {
          v10 = 99.0
          e10 = 99.0
        } else {
          v10 =  real(f19)
          e10 =  real(f20)
        }
         if (f21 == "INDEF" || f22 == "INDEF") {
          v11 = 99.0
          e11 = 99.0
        } else {
          v11 =  real(f21)
          e11 =  real(f22)
        }
         if (f23 == "INDEF" || f24 == "INDEF") {
          v12 = 99.0
          e12 = 99.0
        } else {
          v12 =  real(f23)
          e12 =  real(f24)
        }
         if (f25 == "INDEF" || f26 == "INDEF") {
          v13 = 99.0
          e13 = 99.0
        } else {
          v13 =  real(f25)
          e13 =  real(f26)
        }
        if (nt == 2) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2, >>mags)
         } else if (nt == 3) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3, >>mags)
         } else if (nt == 4) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4, >>mags)
         } else if (nt == 5) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5, >>mags)
         } else if (nt == 6) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6, >>mags)
         } else if (nt == 7) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7, >>mags)
         } else if (nt == 8) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8, >>mags)
         } else if (nt == 9) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9, >>mags)
         } else if (nt == 10) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10, >>mags)
         } else if (nt == 11) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11, >>mags)
         } else if (nt == 12) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11,v12,e12, >>mags)
         } else if (nt == 13) {
          printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
             hjd,xairm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11,v12,e12,v13,e13, >>mags)
	}
      }
    }
    delete ((joinfile//",x?,x1?"),verify=no)

# find average magnitude for each star
    field (mags, fie="1", >"hjd")
    field (mags, fie="2", >"airm")
    field (mags, fie="3") | average | field (fie="1") | scan (amag[1])
    field (mags, fie="5") | average | field (fie="1") | scan (amag[2])
    if (nt >= 3) field (mags, fie="7") | average | field (fie="1") | scan (amag[3])
    if (nt >= 4) field (mags, fie="9") | average | field (fie="1") | scan (amag[4])
    if (nt >= 5) field (mags, fie="11") | average | field (fie="1") | scan (amag[5])
    if (nt >= 6) field (mags, fie="13") | average | field (fie="1") | scan (amag[6])
    if (nt >= 7) field (mags, fie="15") | average | field (fie="1") | scan (amag[7])
    if (nt >= 8) field (mags, fie="17") | average | field (fie="1") | scan (amag[8])
    if (nt >= 9) field (mags, fie="19") | average | field (fie="1") | scan (amag[9])    
    if (nt >= 10) field (mags, fie="21") | average | field (fie="1") | scan (amag[10])    
    if (nt >= 11) field (mags, fie="23") | average | field (fie="1") | scan (amag[11])    
    if (nt >= 12) field (mags, fie="25") | average | field (fie="1") | scan (amag[12])    
    if (nt >= 13) field (mags, fie="27") | average | field (fie="1") | scan (amag[13])    

# sort average magnitudes by brightness and save original star numbers
    for (n=1; n<=nt; n+=1) {
      m[n] = n
    }
    for (n=1; n<=nt-1; n+=1) {
      tmp = amag[n]
      for (i=n+1; i<=nt; i+=1) {
        if (amag[i] < tmp) {
          tmp = amag[i]
          amag[i] = amag[n]
          amag[n] = tmp
          j = m[i]
          m[i] = m[n]
          m[n] = j
        }
      }
    }

    magsfile = mags
    while (fscan (magsfile,magsline) != EOF) {
      if (nt == 2) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2)
       } else if (nt == 3) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3)
       } else if (nt == 4) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4)
       } else if (nt == 5) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5)
       } else if (nt == 6) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6)
       } else if (nt == 7) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7)
       } else if (nt == 8) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8)
       } else if (nt == 9) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9)
       } else if (nt == 10) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10)
       } else if (nt == 11) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11)
       } else if (nt == 12) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11,v12,e12)
       } else if (nt == 13) {
           i = fscan(magsline,txt,xm,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11,v12,e12,v13,e13)
       }
      if (substr(txt,1,1) != "#") {
# enter values in arrays
        hjd = real(txt)
        xairm = real(xm)
        mag[1] = v1
        mag[2] = v2
        mag[3] = v3
        mag[4] = v4
        mag[5] = v5
        mag[6] = v6
        mag[7] = v7
        mag[8] = v8
        mag[9] = v9
        mag[10]= v10
        mag[11]= v11
        mag[12]= v12
        mag[13]= v13
        e[1] = e1
        e[2] = e2
        e[3] = e3
        e[4] = e4
        e[5] = e5
        e[6] = e6
        e[7] = e7
        e[8] = e8
        e[9] = e9
        e[10] = e10
        e[11] = e11
        e[12] = e12
        e[13] = e13
# subtract average from each magnitude (to get values centered about zero);
#   also fix zero errors, to avoid dividing by zero below
        for (n=1; n<=nt; n+=1) {
          mag[m[n]] = mag[m[n]] - amag[n]
          if (e[n] <= 0.0005) e[n] = 0.0005
        }
# calculate various weighted average comparison magnitudes, starting with the 
#   brightest comparison stars and adding a fainter star each time
        for (n=1; n<=nt; n+=1) {
          if (m[n] != ns) {
            ws = 0.
            w = 0.
            for (i=1; i<=nt; i+=1) {
              l[m[i]] = 0
              if (i <=n && m[i] != ns) {
                l[m[i]] = 1
                ws = ws + mag[m[i]]/(e[m[i]])
                w = w + 1./(e[m[i]])
              }
            }
            cmp = ws/w
            magfile = "r"
            for (i=1; i<=nt; i+=1) {
              if (l[i] == 1) magfile = magfile//str(i) 
            }
            dmagfile = "d"//filt//str(ns)//"."//magfile
            diff = cmp - mag[ns]
            printf ("%-9.5f\n", diff, >>dmagfile)
          }
        }
      }
    }

# print out list of residual files
    print ("")
    if (newres) print ("  file     rms residuals")
    tmpfile = mktemp ("pgf")
    dmagfile = "d"//filt//str(ns)//".*"
    files (dmagfile, >tmpfile)
    sigfile = pg//".sig"
    if (access (sigfile)) delete (sigfile,verify=no)
    touch (sigfile)
    if (access ("maglog")) delete ("maglog",verify=no)

    dmaglist = tmpfile
    i = 0
    while (fscan (dmaglist,dmagfile) != EOF) {
      type (dmagfile) | average | fields (fie=2) | scan (sig)
      if (nt < 6) {
        printf ("%-12d%7.5f\n", dmagfile,sig, >>sigfile)
        printf ("%-12d%7.5f\n", dmagfile,sig, >>"maglog") 
       } else if (nt < 10) {
        printf ("%-13d%9.5f\n", dmagfile,sig, >>sigfile)
        printf ("%-13d%9.5f\n", dmagfile,sig, >>"maglog")
       } else if (nt < 11) {
        printf ("%-15d%9.5f\n", dmagfile,sig, >>sigfile)
        printf ("%-15d%9.5f\n", dmagfile,sig, >>"maglog")
      } else if (nt < 12) {
        printf ("%-17d%9.5f\n", dmagfile,sig, >>sigfile)
        printf ("%-17d%9.5f\n", dmagfile,sig, >>"maglog")
      } else {
        printf ("%-19d%9.5f\n", dmagfile,sig, >>sigfile)
        printf ("%-19d%9.5f\n", dmagfile,sig, >>"maglog")
      }
      j = strlen(dmagfile)
      if (j > i) {
        i = j
        resf = dmagfile
        if (access("magline")) del ("magline")
        tail ("maglog", nlines=1, >"magline")
      }
    }
    delete (tmpfile,verify=no)
    print ("", >>"maglog")
    if (newres) {
      type ("maglog")
    } else {
      type ("magline")
    }
    del ("magline"
    print ("")

    sort ("hjd", reverse=no) | head (n=1) | scan (h1)
    sort ("hjd", reverse=yes) | head (n=1) | scan (h2)
# estimate reasonable xaxis
    h1 = int(h1*100+0.5)/100. - 0.03
    h2 = int(h2*100+0.5)/100. + 0.03
    tmp = (h1+h2)/2.
    if (tmp-0.1 < h1) h1 = tmp-0.075
    if (tmp+0.1 > h2) h2 = tmp+0.075

# standard xaxis, 6.0 hrs long
#    h1 = tmp-3./24.-0.04
#    h2 = tmp+3./24.+0.04
# standard long xaxis, 7.5 hrs long
#    h1 = tmp-3.75/24.-0.04
#    h2 = tmp+3.75/24.+0.04
# longer xaxis, 8.5 hrs long
#    h1 = tmp-4.25/24.-0.04
#    h2 = tmp+4.25/24.+0.04
# extra long xaxis, 9.5 hrs long
#    h1 = tmp-4.75/24.-0.04
#    h2 = tmp+4.75/24.+0.04
# extra short xaxis
#    h1 = tmp-2./24.-0.04
#    h2 = tmp+2./24.+0.04
# enable the following for a 32 hr axis (eg to plot two nights on the same graph)
#     h1 = tmp-16./24.
#     h2 = tmp+16./24.
# enable the following for a 4.8 hr axis (short)
#     h1 = tmp-0.1-0.01
#     h2 = tmp+0.1+0.01

# the following commands scroll along at the end of the light
#  curve to see higher time resolution over the last 1.5 hrs
#    h1 = h1 - 0.01
#    h2 = h2 + 0.01
#    if (h2 - h1 > 0.063) h1 = h2 - 0.073

# make file of points to graph a 10 minute bar
    tmp = 0.0025
    x[1] = h1+0.2*(h2-h1) ; y[1] = 0.06 + tmp
    x[2] = x[1] ; y[2] = 0.06 - tmp
    x[3] = x[1] ; y[3] = 0.06
    x[4] = x[1] + 10./(60*24) ; y[4] = 0.06

# the following is the line to plot a 1.0 hour bar, for long x-axis time periods
#    x[4] = x[1] + 60./(60*24) ; y[4] = 0.06
#    x[5] = x[4] ; y[5] = 0.06 + tmp
#    x[6] = x[4] ; y[6] = 0.06 - tmp



# choose/change the following yaxis values 
#    ymin = -1.45
#    ymax = 0.65

#    ymin = -1.0
#    ymax = 0.5

    ymin = -0.15
    ymax = 0.15

#    ymin = -0.05
#    ymax = 0.05

    ymin = -0.1
    ymax = 0.1

    ymin = -6.00
    ymax = 0.60

#u    for (i=1; i<=6; i+=1) {
#u      y[i] = y[i] +0.06
#u    }

#    if (access ("10min.bar")) delete ("10min.bar",verify=no)
#    for (i=1; i<=6; i+=1) {
#      printf ("%-7.4f%-7.4f\n", x[i],y[i], >>"10min.bar")
#    }

# plot the residual file requested (resfile)
    beep
    if (newres) {
      print (("default residuals file = "//resf))
      resfalt = resfile
      resfile = ""
      if (resfalt != "") resf = resfalt
    }
    i = stridx (".",resf)
    refn = substr(resf,i+2,strlen(resf))
    graph.marker = "circle"
    graph.szmarker = 0.002
    txt = "join "//pg//".hjd "//pg//"."//resf//" | graph xlabel=""HJD-"//str(hrnd)//""" ylab="""//filt//"(sdB) - "//filt//refn//""" title="""//title//""" wx1="//h1//" wx2="//h2//" wy1="//ymin//" wy2="//ymax//" point+ fill+"
#    txt = "join "//pg//".hjd "//pg//"."//resf//" | graph xlabel=""HJD-"//str(hrnd)//""" ylab="""//filt//"(WD) - "//filt//refn//""" title="""//title//""" wx1="//h1//" wx2="//h2//" wy1="//ymin//" wy2="//ymax//" point+ fill+"
#   txt = "join "//pg//".hjd "//pg//"."//resf//" | graph xlabel=""HJD-"//str(hrnd)//""" ylab="""//filt//"(sdO) - "//filt//refn//""" title="""//title//""" wx1="//h1//" wx2="//h2//" wy1="//ymin//" wy2="//ymax//" point+ fill+"

    print ((txt), >>& "maglog")

#    txt = "graph "//pg//".10min.bar app+ point-"
#    print ((txt), >>& "maglog")

    if (pg == "j2348") {
      txt = "join j2348.hjd j2348."//resf//" | graph app+ poi-"
      print ((txt), >>& "maglog")
     } else if (pg == "j22405") {
      txt = "join j22405.hjd j22405."//resf//" | graph app+ poi-"
      print ((txt), >>& "maglog")
     } else {
      print ("", >>& "maglog")
    }

    plfile = "pl."//pg//"."//resf

    if (access ((pg//".maglog"))) delete ((pg//".maglog"),verify=no)
    if (access ((pg//".hjd"))) delete ((pg//".hjd"),verify=no)
    if (access ((pg//".airm"))) delete ((pg//".airm"),verify=no)
    if (access ((pg//".10min.bar"))) delete ((pg//".10min.bar"),verify=no)
    if (access ((pg//"."//resf))) delete ((pg//"."//resf),verify=no)
    if (access (plfile)) delete (plfile,verify=no)
    if (access ("plfile")) delete ("plfile",verify=no)
    ren ("hjd",(pg//".hjd"))
    ren ("airm",(pg//".airm"))
#    ren ("10min.bar",(pg//".10min.bar"))
    ren (resf,(pg//"."//resf))
    tail ("maglog",nlines=2, > plfile)
    ren ("maglog",(pg//".maglog"))
    copy (plfile,"plfile")
    cl < "plfile"
    delete ("plfile",verify=no)
#    delete (dmagfile,verify=no)
    delete ("x?,x1?,pgf*,pgc*,d??.r*",verify=no)

 end
