# define the task:
#   task stdexp = /home/bigobs/betsy/com/stdexp.cl

# the data file "land92best.list" exists in 
# /home/bigobs/betsy/com/
# feel free to copy it to your directory or print it

# use to calculate exposure times that will give about 325000 counts
#    for a Landolt standard star, given the catalog number and the
#    current airm

procedure stdexp (Ncat,airm)

  string  Ncat    {prompt="Landolt 1992 catalog number"}
  real    airm    {prompt="current airmass"}

  struct *imagelist

begin

       struct line   
       string obj,ra,dec,nc
       real a,u,b,v,r,i,ub,bv,vr,vi,t
       int counts,j

#       counts = 335000
#       counts = 300000
       counts = 250000

       nc = Ncat
       while (strlen(nc) < 3) nc = " "//nc
       a = airm
       imagelist = "/home/bigobs/betsy/com/land92best.list"
       obj = ""
       while (fscan (imagelist,line) != EOF) {
         if(substr(line,1,3) == nc) {
            print (line) | scan (j,obj,ra,dec,bv,ub,vr,vi,u,b,v,r,i)
            print ((obj//"    V = "//v//"   B-V = "//bv//"   V-R = "//vr//"   V-I = "//vi))
            print ("")
# U
            t = counts*10**(0.4*(u - 8.32 + 0.464*a - 0.103*ub))/325000.
            if (t >= 100.) {
               t = int(t + 0.5)
               print (("         U  "//t//"0"))
             } else if (t >= 10.) {
               t = int(t + 0.5)
               print (("         U   "//t//"0"))
             } else {
               t = int(t*10+0.5)/10.
               print (("         U    "//t))
            }
# B
            t = counts*10**(0.4*(b - 9.58 + 0.259*a - 0.004*bv))/325000.
            if (t >= 100.) {
               t = int(t + 0.5)
               print (("         B  "//t//"0"))
             } else if (t >= 10.) {
               t = int(t + 0.5)
               print (("         B   "//t//"0"))
             } else {
               t = int(t*10+0.5)/10. 
               print (("         B    "//t))
            }
# V
            t = counts*10**(0.4*(v - 9.56 + 0.163*a + 0.034*bv))/325000.
            if (t >= 100.) {
               t = int(t + 0.5)
               print (("         V  "//t//"0"))
             } else if (t >= 10.) {
               t = int(t + 0.5)
               print (("         V   "//t//"0"))
             } else {
               t = int(t*10+0.5)/10.
               print (("         V    "//t))
            }
# R
            t = counts*10**(0.4*(r - 9.39 + 0.122*a + 0.062*vr))/325000.
            if (t >= 100.) {
               t = int(t + 0.5)
               print (("         R  "//t//"0"))
             } else if (t >= 10.) {
               t = int(t + 0.5)
               print (("         R   "//t//"0"))
             } else {
               t = int(t*10+0.5)/10.
               print (("         R    "//t))
            }
# I
            t = counts*10**(0.4*(i - 8.20 + 0.075*a + 0.025*vi))/325000.
            if (t >= 100.) {
               t = int(t + 0.5)
               print (("         I  "//t//"0"))
             } else if (t >= 10.) {
               t = int(t + 0.5)
               print (("         I   "//t//"0"))
             } else {
               t = int(t*10+0.5)/10.
               print (("         I    "//t))
            }
            print ("")
         }
       }
       if (obj == "") {
         print (("#"//nc//" not found in land92best.list"))
         print ("")
       }
end
