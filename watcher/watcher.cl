procedure watcher (datdir)

string  datdir          {prompt="data directory"}

# If extra is set, the named script/task will be executed 
# It will be called with one parameter: the current merged file name
string  extra	= ""	{prompt="extra script to do"}

begin
        string ddir
	string fnf = "/home/bigobs/ppfilenamefile"
	string fst
	string tt = "\033]0;watcher\007"
	string script
        string s1,s2,root,seq
        int i,l,nwatch

        flpr; flpr; flpr

# move to data directory where AZCamTool will be sending images
        ddir = datdir
        if (ddir == ".") pwd | scan (ddir)
        watcher.datdir = ddir
        if (access (ddir)) {
          cd ((ddir))
         } else {
          if(substr(ddir,1,13) != "/home/bigobs/") \
             ddir = "/home/bigobs/"//ddir
          if (access (ddir)) {
            cd ((ddir))
           } else {
            error(1,"type the full directory pathname")
          }
        }
        pwd

# merge any unmerged fits files in directory and run auto_plot if it is
# enabled
        
        delete ("fitslst,FXfiles", >& "dev$null"); s1 = ""
#        print ("checking for unmerged images")
        imhead ("*.fits", >& "fitslst") ; grep ("FX", "fitslst", > "FXfiles")
        tail ("FXfiles", nlines=1) | scan(s1)
        if (s1 != "") print ("merging all unmerged images")
        while (s1 != "") {
          merge4k ("*.fits", >& "dev$null")
          l = strlen (s1)
          s1 = substr(s1,1,l-1)
# run auto_plot on any missed images
          if (watcher.extra == "auto_plot" && access ("auto_plot.log")) {
            print ("running auto_plot on missed images")
            tail ("auto_plot.log", nlines=1) | scan (s2)
            l = strlen(s2)
            root = substr(s2,1,l-4)
            i = real(substr(s2,l-3,l)) + 1
            seq = str(i)
            while (strlen(seq) < 4) seq = "0"//seq
            s2 = root//seq//".fits"
            while (access (s2) && s2 <= s1) {
              auto_plot (s2)
              i = i+1
              seq = str(i)
              while (strlen(seq) < 4) seq = "0"//seq
              s2 = root//seq//".fits"
            }
          }
          delete ("fitslst,FXfiles*"); s1 = ""
          imhead ("*.fits", >& "fitslst") ; grep ("FX", "fitslst", > "FXfiles")
          tail ("FXfiles", nlines=1) | scan(s1)
        }
        delete ("fitslst,FXfiles*")

	printf("%s", tt)
	print ("watcher started")

# delete any existing instance of filenamefile
	if (access (fnf))  delete (fnf, verify = no)
# enter watcher loop
        nwatch = 0
	while (yes && (nwatch < 200)) {
	    if (access (fnf)) {
# next statement is equivalent to an open()
	      list = fnf
	      while (fscanf(list, "%s", fst) != EOF)
	        {
	          if (access (fnf)) delete(fnf, verify = no)
		  printf( "running merge4k on %s\n", fst)
		  printf( "running merge4k on %s\n", fst,  >> "/tmp/timestamps")
		  merge4k(fst, >& "dev$null")
		  printf("displaying %s\n", fst)
		  printf("displaying %s\n", fst,  >> "/tmp/timestamps")
		  display(fst, frame=1)
		  if (fscan(extra, script) == 1) {
# there's an extra script to run
		    if (access("/home/bigobs/watcher/watcher_extra.cl")) \
			delete ("/home/bigobs/watcher/watcher_extra.cl")

# make a watcher_extra procedure that calls the script specified
		    print("procedure watcher_extra \n begin\n  ", \
			script, "(\"", fst, "\")\n end", \
			>"/home/bigobs/watcher/watcher_extra.cl")

#		    print("Executing ", script, "(\"", fst, "\")")
		    watcher_extra
		  }
	      }
	      print "done"
# next statement is equivalent to a close()
	      list = ""
              nwatch = nwatch + 1
	    }
            flpr; flpr
	    sleep (2)
        }

      print ("")
      print ("   ****   TYPE UP-ARROW to RESTART WATCHER !!!   ****")
      print ("")

end
