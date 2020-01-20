# task to help fix saturated magnitudes of saturated comparison stars #7 and #10
# in HS0702+6043 .mags and .counts files by correcting the mag and count values
# of the selected star by the amount that its differential magnitude differs from
# its typical average at that approx HJD.

# input file Satlist should be a list of the processed images that have saturated
# pixels for one particular star (#7 or #10, so there need to be two lists, one
# each), in increasing order, eg:
#    hs0702c.0425.fits
#    hs0702c.0426.fits
#    hs0702c.0439.fits
#    hs0702c.0504.fits
#    hs0702c.0505.fits
#    etc

procedure fixsat (Satfile,Nref)

string     Satfile      {prompt="name of text file containing names of saturated images "}
int        Nref         {prompt="reference star to be fixed, eg 7 or 10 "}

struct *satlist
struct *magsfile
struct *countsfile

begin
    string satfile,satimg,img,im[10],okimg,magsline,countsline
    int Nr,satnum[300],Nsat,npts,i,j,N,N1,Ntry,Nlast,Nlow,Nhigh,nmag
    real delt,hjd0,hjd,h[10],dmag0,dmag[10],dratio,dd,xair
    real v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10,v11,e11,v12,e12

 
    for (i=1; i<=4; i+=1) { 
      dmag[i] = INDEF
    }
 
    Nr = Nref
    satfile = Satfile

# make a list of the image numbers of the saturated images, and get the 
# total number
    i = 0
    satlist = satfile
    while (fscan (satlist,satimg) != EOF) {
      i = i+1
      satnum[i] = int(substr(satimg,9,12))
    }
    Nsat = i

    field("hs0702.mags", fie=2) | aver | field (fie=3) | scan (npts)

# create the differential magnitude files if they don't exist, and create
# a joined listing of the image names, hjd, and diff mags
    if (access("f")) del ("f")
    if (access("z")) del ("z")
    if (access("zz")) del ("zz")
    if (access("z3")) del ("z3")
    if (access("z4")) del ("z4")
#    if (access("hs0702c.list")) del ("hs0702c.list")
    if (access("dmaglist")) del ("dmaglist")

#    files ("hs0702c.????.fits", > "hs0702c.list")
    if (!access("hs0702.hjd")) error(1,"hs0702.hjd not found")
    if (Nr == 7) {
      if (!access("hs0702.dS7.r1234589")) {
        field ("hs0702.mags", fie="15,3,5,7,9,11,17,19", >"z")
        !awk '{d=($2+$3+$4+$5+$6+$7+$8)/7.-$1; print d}' z >zz
        type ("zz") | aver | field (fie="1") | scan (delt)
        delt = int(delt*10000.+0.5)/10000.
        for (i=1; i<=npts; i+=1) { 
          print ((delt), >>"z3")
        }
        join ("zz,z3", >"z4")
        !awk '{d=$1-$2; print d}' z4 >"hs0702.dS7.r1234589" 
        del ("z,zz,z3,z4")
stop
      }
      join ("hs0702c.list,hs0702.hjd,hs0702.dS7.r1234589", >> "dmaglist")
     } else if (Nr == 10) {
      if (!access("hs0702.dS10.r1234589")) error(1,"hs0702.dS10.r1234589 not found")
      join ("hs0702c.list,hs0702.hjd,hs0702.dS10.r1234589", >> "dmaglist")
    }

    satlist = satfile
    while (fscan (satlist,satimg) != EOF) {
      print ((satimg))
      N = int(substr(satimg,9,12))
      grep (satimg, "dmaglist") | scan (img,hjd0,dmag0)


# find two images on each side of Nsat image where the Nref star isn't saturated
# and get their dmag values; if two good images can't be found on one side, then 
# use three (or four) on the other side

      head ("hs0702c.list", nlines=1) | scan(img)
      N1 = int(substr(img,9,12))
      tail ("hs0702c.list", nlines=1) | scan(img)
      Nlast = int(substr(img,9,12))

      im[1] = ""; im[2] = ""; im[3] = ""; im[4] = ""
      j = -1
      Nlow = N
      Nhigh = N
      Ntry = Nlow + j
      nmag = 0
      while (Ntry >= N1 && Ntry <= Nlast && nmag < 4) {
        i = 1
        while (satnum[i] < Ntry) i = i+1
        if (satnum[i] > Ntry) {
          okimg = str(Ntry)
          while (strlen(okimg) < 4) okimg = "0"//okimg
          okimg = "hs0702c."//okimg//".fits"
          nmag = nmag+1
          grep (okimg, "dmaglist") | scan (im[nmag],h[nmag],dmag[nmag])
          if (j < 0 ) {
            Nlow = Ntry
            Ntry = Nhigh
           } else if (j > 0) {
            Nhigh = Ntry
            Ntry = Nlow
          }
          j = -1*j
        }
        if (Ntry > N1 && Ntry < Nlast) {
          Ntry = Ntry + j
         } else if (Ntry == N1) {
          j = 1
          Ntry = Nhigh + 1
         } else if (Ntry == Nlast) {
          j = -1
          Ntry = Nlow - 1
        }
      }
      print ((im[3]//","//im[1]//","//im[2]//","//im[4]))

# sort dmag[n], then find difference between dmag0 and average of two central values
      for (i=1; i<=(nmag-1); i+=1) {
        for (j=i+1; j<=nmag; j+=1) {
           if (dmag[j] < dmag[i]) {
              dd = dmag[i]
              dmag[i] = dmag[j]
              dmag[j] = dd
           }
        }
      }
      if (nmag == 4) {
        dmag0 = dmag0 - (dmag[2]+dmag[3])/2.
       } else if (nmag == 3) {
        dmag0 = dmag0 - dmag[2]
       } else if (nmag == 2) {
        dmag0 = dmag0 - (dmag[1]+dmag[2])/2
       } else if (nmag == 1) {
        dmag0 = dmag0 - dmag[1]
       } else {
        error(1,("nmag = "//nmag))
      }

# rename .mags file; read it in line by line, modify the mag corresponding to the saturated
# Nref, and print it back out

      if (access("hs0702.mags_old")) del ("hs0702.mags_old")
      rename ("hs0702.mags", "hs0702.mags_old")
      head ("hs0702.mags_old", nlines=1, >"hs0702.mags")
      magsfile = "hs0702.mags_old"
      i = fscan(magsfile,magsline)
      while (fscan (magsfile,hjd,xair,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10) != EOF) {
        if (hjd == hjd0) {
          if (Nr == 7) {
            v7 = v7 + dmag0
           } else if (Nr == 10) {
            v10 = v10 + dmag0
          }
        }
        printf("%10.7f%7.3f%10.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f%11.3f%8.3f\n",\
           hjd,xair,v1,e1,v2,e2,v3,e3,v4,e4,v5,e5,v6,e6,v7,e7,v8,e8,v9,e9,v10,e10, >>"hs0702.mags")
      }

# do the same for the .counts file
      if (access("hs0702.counts_old")) del ("hs0702.counts_old")
      rename ("hs0702.counts", "hs0702.counts_old")
      head ("hs0702.counts_old", nlines=1, >"hs0702.counts")
      countsfile = "hs0702.counts_old"
      i = fscan(countsfile,countsline)
      dratio = 10**(0.4*dmag0)
      while (fscan (countsfile,hjd,xair,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10) != EOF) {
        if (hjd == hjd0) {
          if (Nr == 7) {
            v7 = v7 / dratio
           } else if (Nr == 10) {
            v10 = v10 / dratio
          }
        }
        printf("%10.7f%7.3f%15.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f%14.1f\n",\
           hjd,xair,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10, >>"hs0702.counts")
      }

    }

    del ("hs0702c.list,dmaglist")
#    del ("hs0702.*s_old")

 end
