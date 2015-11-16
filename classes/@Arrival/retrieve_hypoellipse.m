function arrivalObj = retrieve_hypoellipse(phafilename)
%RETRIEVE_HYPOELLIPSE Read a Hypoellipse PHA pickfile
% ARRIVALOBJ = RETRIEVE_HYPOELLIPSE(PHAFILENAME) Read a Hypoellipse phase file into an
% arrival object. Wraps readphafile.
%
% Example: 
%     gismopath = fileparts(which('startup_GISMO'));
%     arrivalObj = RETRIEVE_HYPOELLIPSE(fullfile(gismopath, 'classes/@Arrival/examplePHAfile.PHA'))

%   PHA phase file has lines like:
%   MGHZEP 1 950814071436.76
%   MSPTIPU0 950814071437.96
%   MGATEPU0 950814071437.92                                              00011
%   MLGT PD0 950814071438.09       39.41 S 2
%   MWHTEPD1 950814071437.61       38.78 S 2                              00009
%   1-4: sta code
%   5:   E or I
%   6:   P (or blank)
%   7:   U or D
%   8:   quality 0-4
%  10-24: YYMMDDhhmmss.ii for P
%  32-36: ss.ii for S
%  38:   S (or blank)
%  40:   quality 0-4
%
% See also: READPHAFILE

    if nargin==1
        if exist(phafilename, 'file')
            arrivals_struct = Arrival.readphafile(phafilename);
            % now convert arrivals_struct into arrival object	
            sta = {arrivals_struct.stacode};
            ctag = ChannelTag.array('',sta,'','');
            ctag = ctag';

            ptime = [arrivals_struct.p_time]';
            idx = find(ptime>0);
            iphase = cellstr(repmat('P',size(idx)));
            pobj = Arrival(ctag(idx), ptime(idx), iphase(idx))

            stime = [arrivals_struct.s_time]';
            idx = find(stime>0);
            siphase = cellstr(repmat('S',size(idx)));
            sobj = Arrival(ctag(idx), stime(idx), siphase)
            
            arrivalObj = combine(pobj, sobj); % merge p and s arrivals (unsorted)
            %arrivalObj = sort(arrivalObj); % reorder by arrival time
        else
            error(sprintf('%s: hypoellipse PHA file %s not found',mfilename,phafilename));
        end
    else
        error(sprintf('%s: Wrong number of arguments',mfilename));
    end
end
