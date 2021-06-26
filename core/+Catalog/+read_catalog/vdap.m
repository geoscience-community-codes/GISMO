function self=vdap(filename)
%readEvents.vdap read hypo71/hypoellipse summary files and PHA pickfiles
%   based on Montserrat analog network
%   cObject = read_vdap(filename) will read the catalog file, and create a
%   Catalog object
%
%   Summary file has lines like:
% DATE    ORIGIN    LAT N    LONG W    DEPTH    MAG NO GAP DMIN  RMS  ERH  ERZ QM
% 691005 1112 52.83 38-28.59 122-41.94   8.41   1.81 19  59  1.2  .16   .5  1.1 B1
% 691005 12 6 44.56 38-28.53 122-42.09   3.85   2.05 17  59  1.4  .03   .1   .1 A1
% 691005  612  4.22 38-28.40 122-40.88   7.82   2.55 14  67   .4  .07   .3   .5 A1
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
%  31-35: ss.ii for S
%  37:   S (or blank)
%  39:   quality 0-4
% Glenn Thompson 2014/11/14

if filename(end-3:end)=='.PHA'

    %% read the headers and data
    % this should be read as arrival objects, no?
    fid = fopen(filename);
    tline = fgetl(fid);
    while ischar(tline)
        if length
        stacode = tline(1:4);
        p_eori = tline(5);
        p = tline(6);
        p_uord = tline(7);
        p_qual = tline(8);
        p_datetime = tline(10:24);
        s_datetime = tline(31:35);
        s = tline(37);
        s_qual = tline(39);
        tline = fgetl(fid);
    end
    fclose(fid);
else
    %% assume this is a hypo71 summary file
    fid = fopen(filename);
    tline = fgetl(fid);
    events=[];
    counter=0;
    while ischar(tline)

        tline = sprintf(' %s',tline);
        disp(tline)
        disp(repmat('1234567890',1,8))        
        try
            yy = str2num(tline(2:3));
        catch
            break
        end
        if yy>30
            yyyy=yy+1900;
        else
            yyyy=yy+2000;
        end
        mm = str2num(tline(4:5));
        dd = str2num(tline(6:7));
        hh = str2num(tline(9:10));
        mi = str2num(tline(11:12));
        ss = str2num(tline(14:18));
        counter = counter + 1;
%         if counter>10
%             break
%         end
        events(counter).otime = datenum(yyyy,mm,dd,hh,mi,ss);
        %disp(datestr(otime,'yyyy-mm-dd HH:MM:SS.FFF'))
        events(counter).latn = str2num(tline(20:21)) + str2num(tline(23:27))/60;
        events(counter).lonw = str2num(tline(29:31)) + str2num(tline(33:37))/60;
        events(counter).depth = str2num(tline(39:44));
        events(counter).mag = str2num(tline(48:51));
        if isempty(events(counter).mag)
            events(counter).mag = -9.9;
        end
        events(counter).n = str2num(tline(53:54));
        events(counter).gap = str2num(tline(56:58));
        events(counter).dmin = str2num(tline(60:63));
        events(counter).rmse = str2num(tline(65:68));
        events(counter).erh = str2num(tline(70:73));
        events(counter).erz = str2num(tline(75:78));
        events(counter).qm = tline(80:81);
        events(counter).magtype = 'hypo71';
        events(counter).etype ='t';
        tline = fgetl(fid);
        %thisevent = Catalog(otime, -lonw, latn, depth, mag, {}, {});
        
%         if strcmp(class(self),'Catalog')
%             self = combine(self, thisevent);
%         else
%             self = thisevent;
%         end
    end
    self = Catalog([events.otime], -[events.lonw], [events.latn], [events.depth], [events.mag], {events.magtype}, {events.etype});
    
end

