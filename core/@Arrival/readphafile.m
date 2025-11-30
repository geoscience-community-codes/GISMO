function self = readphafile(phafilename) %ARRIVAL.READPHAFILE Read a Hypoellipse PHA phase file into an Arrival object fid = fopen(phafilename); if fid < 0 error('Could not open PHA file'); end sta = {}; chan = {}; time = []; phase = {}; amp = []; per = []; while true tline = fgetl(fid); if ~ischar(tline), break; end tline = tline(1:min(50,length(tline))); tline = deblank(tline); if length(tline) >= 24 stacode = tline(1:4); iph = tline(6); ptime = str2datenum(tline(10:19), tline(20:24)); if length(tline) >= 50 aamp = str2double(tline(44:47)); aper = str2double(tline(48:50)); else aamp = NaN; aper = NaN; end sta{end+1,1} = stacode; chan{end+1,1} = ' '; time(end+1,1) = ptime; phase{end+1,1} = iph; amp(end+1,1) = aamp; per(end+1,1) = aper; end end fclose(fid); self = Arrival(sta,chan,time,phase,'amp',amp,'per',per); end end endfunction self = readphafile(phafilename)
%READPHAFILE Read Hypoellipse PHA file into Arrival object

fid = fopen(phafilename);

if fid < 0
    error('Could not open PHA file');
end

sta  = {};
chan = {};
time = [];
phase = {};
amp = [];
per = [];

while true

    tline = fgetl(fid);
    if ~ischar(tline), break; end

    tline = tline(1:min(50,length(tline)));
    tline = deblank(tline);

    if length(tline) >= 24

        stacode = tline(1:4);
        iph = tline(6);

        ptime = str2datenum(tline(10:19), tline(20:24));

        if length(tline) >= 50
            aamp = str2double(tline(44:47));
            aper = str2double(tline(48:50));
        else
            aamp = NaN;
            aper = NaN;
        end

        sta{end+1,1}   = stacode; %#ok<AGROW>
        chan{end+1,1}  = '  '; %#ok<AGROW>
        time(end+1,1)  = ptime; %#ok<AGROW>
        phase{end+1,1} = iph; %#ok<AGROW>
        amp(end+1,1)   = aamp; %#ok<AGROW>
        per(end+1,1)   = aper; %#ok<AGROW>
    end
end

fclose(fid);

self = Arrival(sta,chan,time,phase,'amp',amp,'per',per);
end
