# Procedure to compute gain values.

# Run mscgain like this
#    task mscgain = /home/bigobs/betsy/com/mscgain.cl
#    cd raw
#    hsel r.*00.fits[0] $I,ut,exptime,filter,imagetyp,title yes
#    mscgain 
#       raw bias images (): r.00*fits
#       raw flat images (): r.01*fits

# if the number of biases is not = 100, change nb below

procedure gain (bimages,fimages)

string	bimages		{prompt="raw bias images"}
string	fimages		{prompt="raw flat images"}

struct	*imagelist
struct  *outpt1, *outpt2

begin
	string bim,fim,dataout
        string flat1,flat2,bias1,bias2,statsec
        real mb1,mb2,mb,mf1,mf2,mf,fn1,fn2,nb
        real noise1,gain1,rdnoise1,noise2,gain2,rdnoise2

        nb = 100
# if using full image, then set statsec = "[300:600,200:1165]"
        statsec = "[300:600,50:1000]"
        dataout = "gain.logfile"
        bim = bimages
        fim = fimages

        del ("b1,b2,f1,f2", >& "dev$null")
        imdelete ("bias_1,bias_2,flat_?1", >& "dev$null")

# combine the bias images to make a good bias image
        if (access ("bias.fits")) delete ("bias.fits", verify=no)
        combine (bim, "bias.fits", comb="median", reject="avsig", zero="median", \
          statsec=statsec, >& "dev$null")

# doesn't work because combine doesn't reliably put ncombine keyword in the headers
#        imgets ("bias.fits[0]","ncombine")
#        nb = int(imgets.value)

# Then subtract the combined bias from all the flats
        mscarith (fim, "-", "bias.fits", fim)


# CCD side 1

# find the two bias images with the least cosmic rays
        imstat ((bim//"[1]"//statsec), fie="image,mean,max", format=no) | \
           sort (col=3, numeric=yes, reverse=yes, >"b1")
        tail ("b1", nlines=2) | head (nlines=1) | field (field="1,2") | scan(bias1,mb1)
        bias1 = substr(bias1,1,stridx("[",bias1)+2)
        tail ("b1", nlines=1) | field (field="1,2") | scan(bias2,mb2)
        bias2 = substr(bias2,1,stridx("[",bias2)+2)
# get the mean bias level and the representative noise level in a single bias image
        mb = (mb1+mb2)/2.
        imarith (bias1, "-", bias2, "bias_1")
        imstat (("bias_1"//statsec), fie="stddev", format=no) | scan(noise1)
        noise1 = noise1/sqrt(2.)

# find the two flat images with the least cosmic rays
        imstat ((fim//"[1]"//statsec), fie="image,mean,max", format=no) | \
           sort (col=3, numeric=yes, reverse=yes, >"f1")
        tail ("f1", nlines=2) | head (nlines=1) | field (field="1,2") | scan(flat1,mf1)
        flat1 = substr(flat1,1,stridx("[",flat1)+2)
        tail ("f1", nlines=1) | field (field="1,2") | scan(flat2,mf2)
        flat2 = substr(flat2,1,stridx("[",flat2)+2)
        imarith (flat1, "/", flat2, "flat_11")
        imarith ("flat_11", "*", mf2, "flat_11")
        imstat (("flat_11"//statsec), fie="mean,stddev", format=no) | scan(mf,fn1)
        gain1 = mf / (0.5*fn1*fn1 - (1.+1./nb)*noise1*noise1)
        rdnoise1 = gain1*noise1

        print ("")
        print (" Side 1")
        print (("   bias images: "//bias1//", "//bias2))
        print (("      mean level = "//mb//",    read noise = "//noise1//" dN"))
        print ("")
        print (("   flat images: "//flat1//", "//flat2))
        print (("      mean level = "//mf//",     photon + read noise = "//fn1//" dN"))
        print ("")
        print (("   gain_1 = "//gain1//"      rdnoise_1 = "//rdnoise1))
        print ("")
        print ("")


# CCD side 2

# find the two bias images with the least cosmic rays
        imstat ((bim//"[2]"//statsec), fie="image,mean,max", format=no) | \
           sort (col=3, numeric=yes, reverse=yes, >"b2")
        tail ("b2", nlines=2) | head (nlines=1) | field (field="1,2") | scan(bias1,mb1)
        bias1 = substr(bias1,1,stridx("[",bias1)+2)
        tail ("b2", nlines=1) | field (field="1,2") | scan(bias2,mb2)
        bias2 = substr(bias2,1,stridx("[",bias2)+2)
# get the mean bias level and the representative noise level in a single bias image
        mb = (mb1+mb2)/2.
        imarith (bias1, "-", bias2, "bias_2")
        imstat (("bias_2"//statsec), fie="stddev", format=no) | scan(noise2)
        noise2 = noise2/sqrt(2.)

# find the two flat images with the least cosmic rays
        imstat ((fim//"[2]"//statsec), fie="image,mean,max", format=no) | \
           sort (col=3, numeric=yes, reverse=yes, >"f2")
        tail ("f2", nlines=2) | head (nlines=1) | field (field="1,2") | scan(flat1,mf1)
        flat1 = substr(flat1,1,stridx("[",flat1)+2)
        tail ("f2", nlines=1) | field (field="1,2") | scan(flat2,mf2)
        flat2 = substr(flat2,1,stridx("[",flat2)+2)
        imarith (flat1, "/", flat2, "flat_21")
        imarith ("flat_21", "*", mf2, "flat_21")
        imstat (("flat_21"//statsec), fie="mean,stddev", format=no) | scan(mf,fn2)
        gain2 = mf / (0.5*fn2*fn2 - (1.+1./nb)*noise2*noise2)
        rdnoise2 = gain2*noise2

        print ("")
        print (" Side 2")
        print (("   bias images: "//bias1//", "//bias2))
        print (("      mean level = "//mb//",    read noise = "//noise2//" dN"))
        print ("")
        print (("   flat images: "//flat1//", "//flat2))
        print (("      mean level = "//mf//",     photon + read noise = "//fn2//" dN"))
        print ("")
        print (("   gain_2 = "//gain2//"      rdnoise_2 = "//rdnoise2))
        print ("")
        print ("")

# Add the bias back to all the flats
        mscarith (fim, "+", "bias.fits", fim)

        del ("b1,b2,f1,f2")
        imdelete ("bias_?.fits,bias.fits,flat_?1.fits", >& "dev$null")

end
