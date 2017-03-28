function self=sru(filename)
%readEvents.sru read a catalog sent by Seismic Research Unit, University of West
%Indies
%   Based on a Dominica catalog sent to Ophelia George
%   cObject = read_SRU(filename) will read the catalog file, and create a
%   Catalog object
%
%   File has lines like:
%   #EVENT_ID	P	S	LAT.	LONG	DEP.	DATE	TIME	RMSE	MAG.
%   9703120.002	3	3	15.4170N	61.2890W	3	19970322	658.23	0.347	2.5
%
% Glenn Thompson 2014/11/14

    %% read the headers and data
    fid = fopen(filename);
    headers = textscan(fid, '%s', 10); % header is just 10 strings
    data = textscan(fid, '%f%d%d%s%s%f%s%f%f%f'); % import the columns from each tab separated row as float, integer, integer, string, ...
    fclose(fid);
    
    %% wrangle the data into variables we can use
    evid=data{1}; % event id - like 9703120.002 - but we'll probably just renumber them from 1
    nassP=data{2}; % number of associated P arrivals - like 3
    nassS=data{3}; % number of associated S arrivals - like 3
    
    % latitude like '15.4170N'
    latstr = data{4};
    for c=1:numel(latstr)
        thislatstr = latstr{c};
        hemisphere = thislatstr(end);
        lat(c) = str2num(thislatstr(1:end-1));
        if lower(hemisphere)=='s'
            lat(c) = -lat(c);
        end
    end
    
    % longitude like '61.2890W'
    lonstr = data{5};
    for c=1:numel(lonstr)
        thislonstr = lonstr{c};
        hemisphere = thislonstr(end);
        lon(c) = str2num(thislonstr(1:end-1));
        if lower(hemisphere)=='w'
            lon(c) = -lon(c);
        end
    end
    
    % depth like 3
    depth = data{6};
    
    % date like 19970322
    yyyymmdd = data{7};
    for c=1:numel(yyyymmdd)
        thisyyyymmdd = yyyymmdd{c};
        yyyy(c) = str2num(thisyyyymmdd(:,1:4));
        mo(c) = str2num(thisyyyymmdd(:,5:6));
        dd(c) = str2num(thisyyyymmdd(:,7:8));
    end
    
    % time like 658.23 for 00:06:58.23 but really HHMMSS.MS
    hhmmss = data{8};
    for c=1:numel(hhmmss)
        thishhmmss = sprintf('%09.2f',hhmmss(c));
        hh(c) = str2num(thishhmmss(:,1:2));
        mm(c) = str2num(thishhmmss(:,3:4));
        ss(c) = str2num(thishhmmss(:,5:9));
    end
    
    dnum = datenum(yyyy, mo, dd, hh, mm, ss);
    datestr(dnum)
    
    % RMS Error
    rms = data{9};
    
    % Magnitude
    mag = data{10};
    
    
    %% Create an etype (assume type 'tectonic')
    etype = repmat('t',numel(dnum));
    
    %% Create our Catalog object
    self = Catalog(dnum, lon, lat, depth, mag, {}, etype);
end
