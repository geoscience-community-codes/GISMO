def stream2matfile(st):
    '''
	stream2matfile 
		Convert an ObsPy Stream object into a set of MATLAB *.mat files (one per trace)

	Example:
	     import obspy
	     st = obspy.read("https://examples.obspy.org/BW.BGLD..EH.D.2010.037")
             import sys
             sys.path.append('/Users/glennthompson/src/GISMO/contributed/+obspy')
             import stream2matfile
             stream2matfile.stream2matfile(st)
    '''

    from scipy.io import savemat
    for i, tr in enumerate(st):
        mdict = {k: str(v) for k, v in tr.stats.iteritems()}
        mdict['data'] = tr.data
        savemat("obspy.stream.%s.%s.%s.%s.mat" % (tr.stats.network, tr.stats.station, tr.stats.location, tr.stats.channel), mdict)

# These lines allow the file to be called as a script with a command line argument
if __name__ == "__main__":

    import obspy, sys, os
    if len(sys.argv) > 0:
        if os.path.exists(sys.argv[1]):
            st = obspy.read(sys.argv[1])
    else:
        st = obspy.read("https://examples.obspy.org/BW.BGLD..EH.D.2010.037")

    # This is where the function is called
    stream2matfile(st)
