function [ w ] = pad( w, snum, enum, padvalue )
%PAD Pad a waveform from snum to enum
%   Sometimes it is useful to pad a waveform object
%   so it starts earlier and ends later
%   w = pad(w, snum, enum, 0) will add 0s before and after the data
%   currently in the waveform object

	for i=1:numel(w)
		y = get(w(i),'data');
		fs = get(w(i),'freq');
		[wsnum wenum] = gettimerange(w);
	
		nbefore = floor(86400*(wsnum-snum)*fs);
		nafter = floor(86400*(enum-wenum)*fs);
		
		if nbefore>0
		    y = [ones(nbefore, 1)*padvalue; y];
		end
		if nafter>0
		    y = [y; ones(nafter, 1)*padvalue];
		end
		startnum = wsnum - fs *nbefore;
		w=set(w(i),'start',startnum, 'data', y);
	end
end

