function write(w, fileformat)
%WRITE Write waveform objects to MINISEED or SAC files
%   WRITE(w, fileformat) where fileformat = 'miniseed' or 'sac'
%   Each waveform object is written to a file like
%   NET.STA.LOC.CHAN.D.YYYY.JJJJ.HHMMSS with the extension '.mseed' for
%   Miniseed or '.sac' for SAC output.
    for c=1:numel(w)
        ctag = get(w(c),'ChannelTag');
        d = get(w(c), 'data');
        tstart = get(w(c), 'start');
        yyyyjjj = num2str(datenum2julday(tstart));
        filebase = sprintf('%s.D.%s.%s.%s',ctag.string(), yyyyjjj(1:4), yyyyjjj(5:7), datestr(tstart, 'HHMMSS'  ) );
        
        fs = get(w(c),'freq');
        if strfind(lower(fileformat), 'seed')
            filename = sprintf('%s.mseed',filebase);
            mkmseed(filename, d, tstart, fs); % but mkmseed ignores this and saves as id.yyyy.jjj
            wrongname = sprintf('%s.%s.%s', ctag.string(), yyyyjjj(1:4), yyyyjjj(5:7));
            movefile(wrongname, filename);
            tend = get(w(c), 'end');
            if floor(tend)> floor(tstart)
               eyyyjjj = num2str(datenum2julday(tend)); 
               ewrongname = sprintf('%s.%s.%s', ctag.string(), eyyyjjj(1:4), eyyyjjj(5:7));
               efilebase = sprintf('%s.D.%s.%s.000000',ctag.string(), eyyyjjj(1:4), eyyyjjj(5:7) );
               movefile(ewrongname, efilename);
            end
            
        elseif lower(fileformat) == 'sac'
            filename = sprintf('%s.sac',filebase)
            try
                mksac(filename, d, tstart, 'DELTA', 1/fs, 'KNETWK', ctag.network, 'KSTNM', ctag.station, 'KHOLE', ctag.location, 'KCMPNM', ctag.channel);
            catch
                savesac(w, '.', sprintf('%s.savesac',filebase))
            end
        end
        fprintf('Created %s\n', filename); 
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