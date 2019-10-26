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
        if isempty(thisw)
            continue;
        end
		y = get(thisw,'data');
		fs = get(thisw,'freq');
		[wsnum wenum] = gettimerange(thisw);
        if isnan(wsnum) || isnan(wenum)
            warning(sprintf('%s: start or end time is undefined. cannot pad',mfilename));
            w(waveform_num)=thisw;
            continue;
        end

        if wsnum~=snum | wenum~=enum
	
            nbefore = round(86400*(wsnum-snum)*fs);
            nafter = round(86400*(enum-wenum)*fs);

            if nbefore>0
                y = [ones(nbefore, 1)*padvalue; y];
            end
            if nafter>0
                y = [y; ones(nafter, 1)*padvalue];
            end
            w(waveform_num)=set(thisw,'start',snum, 'data', y);
            
            % clip in case some waveforms are longer than requested range
            w(waveform_num) = extract(w(waveform_num), 'time', snum, enum);
        end
    end
    

end

