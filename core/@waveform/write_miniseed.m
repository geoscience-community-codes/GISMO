function write_miniseed(w)
    for c=1:numel(w)
        ctag = get(w(c),'ChannelTag');
        filename = [ctag.string(),'D'];
        d = get(w(c), 'data');
        tstart = get(w(c), 'start');
        fs = get(w(c),'freq');
        mkmseed(filename, d, tstart, fs)
    end
end
    
%     
% mkmseed Write data in miniSEED file format.
%  	mkmseed(FILENAME,D,T0,FS) writes miniSEED file FILENAME from strictly 
%  	monotonic data vector D, time origin T0 (a scalar in Matlab datenum
%  	compatible format) and sampling rate FS (in Hz). Encoding format will 
%  	depend on D variable class (see below).
%  
%  	mkmseed(FILENAME,D,T,FS) where T is a time vector of the same length as
%  	data vector D, will create data records of monotonic blocks of samples,
%  	splitting each time the sampling frequency FS is not equal to time  
%  	difference between two successive samples (with a 50% tolerency).
%  
%  	Network, Station, Channel and Location codes will be extracted from FILENAME
%  	which must respect the format "NN.SSSSS.LC.CCC.T" where:
%  		   NN = Network Code (2 characters max, see FDSN list)
%  		SSSSS = Station identifier (5 char max)
%  		   LC = Location Code (2 char max)
%  		  CCC = Channel identifier (3 char max)
%  		    T = Data type (1 char, optional, default is D)