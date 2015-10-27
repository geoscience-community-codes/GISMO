function w = arrivals2waveforms(dbpath, arrivals, pretrig, posttrig, taper_seconds, nwaveforms)
% ARRIVALS2WAVEFORMS Load waveform objects corresponding to an arrivals structure
%	w = ARRIVALS2WAVEFORMS(dbpath, arrivals, pretrig, posttrig, taper_seconds, maxNumberOfWaveforms)
	w = waveform(); % Initialize output

	% Check input variables. 
	if nargin<4
		disp('Incorrect number of input variables')
		return
	end

	% Create datasource
	ds = datasource('antelope', dbpath);
	% Loop over arrivals structure
	for i=1:min([nwaveforms numel(arrivals.arid)])
        scnl = scnlobject(arrivals.sta{i}, arrivals.chan{i});
		snum = epoch2datenum(arrivals.atime(i) - pretrig - taper_seconds);
		enum = epoch2datenum(arrivals.atime(i) + posttrig + taper_seconds);
        try
            thisw = waveform(ds, scnl, snum, enum);
        end
        if numel(thisw)==1
            w(i) = thisw;
        else
            w(i)=waveform();
        end
	end
end