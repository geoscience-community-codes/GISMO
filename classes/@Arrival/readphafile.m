function self=readphafile(phafilename)
%READPHAFILE Read a Hypoellipse PHA pickfile
% ARRIVALS = READPHAFILE(PHAFILENAME) Read a Hypoellipse phase file into a
% structure.
%
% Example: 
%     gismopath = fileparts(which('startup_GISMO'));
%     arrivals = READPHAFILE(fullfile(gismopath, 'classes/@Arrival/examplePHAfile.PHA'))

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

self = [];
c=0;
%     %% read the headers and data
     fid = fopen(phafilename);
     %C = textscan(fid,'%4s%2c%1c%1d%1d%10d%5.2f%7c%5.2f%3c%1d%3c%4.0f%3.2f%10c%1d%1d%2c%1c%5.2f%5.0f%29c%1c%1c%1c%1c%1c');
     tline = fgetl(fid);
     while ischar(tline)
         tline = tline(1:min([50 length(tline)])); % ignore characters after 50th
         tline = deblank(tline);
         %2c%1c%1d%1d%10d%5.2f       %5.2f%3c%1d   %4.0f%3.2f          %1d%1d%2c%1c%5.2f%5.0f')
        %[sta,iphase,polarity,pweight,yrmodyhrmn,sec,ssec,srmk,sweight,maxamp,period,s,v,rmk,timecor,f_p_time]
        if length(tline)>=24
             clear a
                 a.stacode = tline(1:4);
                 a.p_eori = tline(5);
                 a.p_polarity = tline(7);
                 a.p_quality = str2num(tline(8));
                 a.p_time = str2datenum(tline(10:19), tline(20:24));
                 if length(tline)>=40
                    a.s_time = str2datenum(tline(10:19), tline(32:36));
                    a.s_quality = str2num(tline(40));
                 else
                     [a.s_time, a.s_quality] = deal(0);
                 end
                 if length(tline)>=50
                    a.maxamp = str2num(tline(44:47));
                    a.period = str2num(tline(48:50));
                 else
                     [a.maxamp, a.period] = deal(0);
                 end
                 c=c+1;
                 self = [self a];
        end
        tline = fgetl(fid);
     end
     fclose(fid);
self = self';
end

function dnum = str2datenum(yrmodyhrmn, sec);
    yr = yrmodyhrmn(1:2);
    if str2num(yr)<30
        yyyy = 2000 + str2num(yr);
    else
        yyyy = 1900 + str2num(yr);
    end
    mo = str2num(yrmodyhrmn(3:4));
    dy = str2num(yrmodyhrmn(5:6));
    hh = str2num(yrmodyhrmn(7:8));
    mi = str2num(yrmodyhrmn(9:10));
    dnum = datenum(yyyy, mo, dy, hh, mi, str2num(sec));
end
        
