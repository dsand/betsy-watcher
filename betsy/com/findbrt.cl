# task to select daofind coordinates for the fiducial bright stars
# only, in a standard order, for a set of eclipse monitoring images
# with a single root name or for a single image or subset of images
#    (takes about 1 sec per image, not including daophoting)

procedure findbrt (pg0,imdat)

string     pg0          {prompt="pg root name (i.e. pg1725) or image name(s) "}
string     imdat        {prompt="imdat data file containing star positions "}

struct *imdatfile
struct *coolist
struct *nextfile

begin
    struct imdatline,coofile,txtline
    string pg,root,filist,coolst,tmpfile,newfile
    int nt,i,id
    real xx,yy,fw,thr,dx,dy,x[20],y[20],xc,yc,mg,sh,sr,gr
    real xf[19],yf[19],mag[19],sharp[19],sround[19],ground[19]

    pg = pg0
    i = strlen(pg)
    if (substr(pg,i-4,i) == ".fits") pg = substr(pg,1,i-5)

# clean up old files before starting
    if ( access("errlog") ) delete ("errlog",verify=no)
    delete ("xyfile*",verify=no)
    delete (("*coo.*~"),verify=no)
    delete (("*coo.2"),verify=no)
    delete (("*tmp.coo.*"),verify=no)

    root = pg
    i = stridx(".",root)
    if (i  > 0) root = substr(root,1,i-3)

# allowable pixel error for star coords
    dx = 25.
    dy = 25.
#    dx = 50.
#    dy = 50.

# open imdat file and find star positions
    imdatfile = imdat
    for (i=1; i<=7; i+=1) {
      nt = fscan (imdatfile,imdatline)
    }      
    while (fscan (imdatfile,imdatline) != EOF) {
      if(substr(imdatline,1,1) != "#") {
        i = fscan(imdatline,nt,xx,yy)
        x[nt] = xx
        y[nt] = yy
       } else {
        i = fscan(imdatfile,imdatline)
      }
    }

# examine each *.coo.1 file in turn, and rewrite to a new .coo files with only the coords
# for the wanted stars

    coolst = mktemp ("pgfx")
    files ((pg//"*fits.coo.*"), > coolst)
    coolist = coolst

    while (fscan (coolist,coofile) != EOF) {
#      print ((coofile))
      nextfile = coofile
      while (fscan (nextfile,txtline) != EOF) {
        if (stridx("#",txtline) == 1)  {
          id = 0
          for (i=1; i<=nt; i+=1) {
            xf[i] = -999.
            yf[i] = -999.
          }
          tmpfile = root//".tmp.coo.1"
          print ((txtline), >>tmpfile)
        } else {
          print ((txtline)) | scan (xc,yc,mg,sh,sr,gr,i)
# check to see if coord matches one of the specified stars
          for (i=1; i<=nt; i+=1) {
            if (xc>x[i]-dx && xc<x[i]+dx && yc>y[i]-dy && yc<y[i]+dy) {
# if a second match is found, use the star closer to the nominal position
              if ( (xc-x[i])*(xc-x[i])+(yc-y[i])*(yc-y[i]) < \
                   (xf[i]-x[i])*(xf[i]-x[i])+(yf[i]-y[i])*(yf[i]-y[i]) ) {
                if (xf[i] < 0 && yf[i] < 0) id += 1
                xf[i] = xc
                yf[i] = yc
                mag[i] = mg
                sharp[i] = sh
                sround[i] = sr
                ground[i] = gr
              }
            }
          }
        }
      }

      if (id == nt) {
        for (i=1; i<=nt; i+=1) {
          printf("   %-10.3f%-10.3f%-9.3f%-12.3f%-12.3f%-12.3f%-6d\n",\
            xf[i],yf[i],mag[i],sharp[i],sround[i],ground[i],i)
          printf("   %-10.3f%-10.3f%-9.3f%-12.3f%-12.3f%-12.3f%-6d\n",\
            xf[i],yf[i],mag[i],sharp[i],sround[i],ground[i],i, >>tmpfile)
# write file "xyfile" for use in statcoords
          print ((xf[i]//"   "//yf[i]), >>"xyfile")
        }
        newfile = coofile
        i = stridx("i",substr(coofile,5,strlen(coofile)))+4
        newfile = substr(coofile,1,i-3)//".coo.1"
        if ( access ((newfile)) ) del (newfile,verify=no)
        ren (tmpfile, newfile)
        del ((coofile),verify=no)
      } else {
        print ("", >>"errlog")
        print ((coofile), >>"errlog")
        tail (tmpfile, nlines=nt+4, >>"errlog")
        del (tmpfile,verify=no)
      }
    }

    del (coolst,verify=no)
    if ( access("errlog") ) tail ("errlog")

 end
