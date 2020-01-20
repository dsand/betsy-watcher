procedure watcher (datdir)

string  datdir          {prompt="data directory"}

# version for single-amp version of Mont4k
#  ie does not try to merge two amp sections, does not correct for
#  crosstalk, does not subtract overscan
# all it does is modify the extend header keyword (=F) to denote
#  no extensions in the fits file

begin
        string ddir
	string fnf = "/home/bigobs/ppfilenamefile"
	string fst
	string tt = "\033]0;watcher\007"
	string script

# move to data directory where AZCamTool will be sending images
        ddir = datdir
        if (access (ddir)) {
          cd ((ddir))
         } else {
          if(substr(ddir,1,13) != "/home/bigobs/") \
             ddir = "/home/bigobs/"//ddir
          if (access (ddir)) {
            cd ((ddir))
           } else {
            error(1,"Directory doesn't exist")
          }
        }
        pwd

	printf("%s", tt)
	print "watcher started"
#delete any existing instance of filenamefile
	if (access (fnf))  delete (fnf, verify = no)
#enter watcher loop
	while (yes) {
		if (access (fnf)) {
#next statement is equivalent to an open()
			list = fnf
			while (fscanf(list, "%s", fst) != EOF)
			{
                           hedit (fst, "extend", "F", verify=no, show=no, update=yes)
	  			printf("displaying %s\n", fst)
				printf("displaying %s\n", fst,  >> "/tmp/timestamps")
				display(fst, frame=1)
			}
			print "done"
#next statement is equivalent to a close()
			list = ""
			if (access (fnf)) delete(fnf, verify = no)
		}
		sleep (1)
	}
end
