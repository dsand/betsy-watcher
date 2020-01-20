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
				printf( "running merge4k on %s\n", fst)
				printf( "running merge4k on %s\n", fst,  >> "/tmp/timestamps")
				merge4k(fst)
				printf("displaying %s\n", fst)
				printf("displaying %s\n", fst,  >> "/tmp/timestamps")
				display(fst, frame=1)
				if (fscan(extra, script) == 1) {
# There's an extra script to run
				    if (access("/home/bigobs/watcher/watcher_extra.cl")) \
						delete ("/home/bigobs/watcher/watcher_extra.cl")

# Make a watcher_extra procedure that calls the script specified
				    print("procedure watcher_extra \n begin\n  ", \
						script, "(\"", fst, "\")\n end", \
						>"/home/bigobs/watcher/watcher_extra.cl")

#				    print("Executing ", script, "(\"", fst, "\")")
				    watcher_extra
				}
			}
			print "done"
#next statement is equivalent to a close()
			list = ""
			if (access (fnf)) delete(fnf, verify = no)
		}
		sleep (2)
	}
end
