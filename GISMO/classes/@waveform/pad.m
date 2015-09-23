function [ w ] = pad( w, snum, enum, padvalue )
%PAD Pad a waveform from snum to enum
%   Sometimes it is useful to pad a waveform object
%   so it starts earlier and ends later
%   For example, you have 6 waveform objects, and you
%   want to pad them so they all start and end at the same time
%   This can be achieved with:
%       [snum enum] = gettimerange(w) % assume gaps already filled, signal
%       already detrended
%       w2 = pad(w, min(snum), max(enum), 0)

% Glenn Thompson USF

    if ~exist('padvalue','var')
        padvalue=0; % could also be nanmean?
    end
	for waveform_num=1:numel(w)
        thisw = w(waveform_num);
		y = get(thisw,'data');
		fs = get(thisw,'freq');
		[wsnum wenum] = gettimerange(thisw);
	
		nbefore = round(86400*(wsnum-snum)*fs);
		nafter = round(86400*(enum-wenum)*fs);
	
		if nbefore>0
		    y = [ones(nbefore, 1)*padvalue; y];
		end
		if nafter>0
		    y = [y; ones(nafter, 1)*padvalue];
        end
		w(waveform_num)=set(thisw,'start',snum, 'data', y);
	end
end

