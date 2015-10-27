function self = readEvents(dataformat, varargin)
%READEVENTS Read seismic events from common file formats & data sources.
% readEvents can read events from many different earthquake catalog file 
% formats (e.g. Seisan, Antelope) and data sources (e.g. IRIS DMC) into a 
% GISMO Catalog object.
%
% Usage:
%       catalogObject = READEVENTS(dataformat, 'param1', _value1_, ...
%                                                   'paramN', _valueN_)
% 
% dataformat may be:
%
%   * 'iris' (for IRIS DMC, using irisFetch.m), 
%   * 'antelope' (for a CSS3.0 Antelope/Datascope database)
%   * 'seisan' (for a Seisan database with a REA/YYYY/MM/ directory structure)
%   * 'zmap' (converts a Zmap data strcture to a Catalog object)
%
% The name-value parameter pairs supported are the same as those supported
% by irisFetch.Events(). Currently these are:
%
%     startTime
%     endTime
%     eventId
%     fetchLimit
%     magnitudeType
%     minimumLongitude
%     maximumLongitude
%     minimumLatitude
%     maximumLatitude
%     minimumMagnitude
%     maximumMagnitude
%     minimumDepth
%     maximumDepth
% 
% And the two convenience parameters:
%
% radialcoordinates = [ centerLatitude, centerLongitude, maximumRadius ]
%
% boxcoordinates = [ minimumLatitude maximumLatitude minimumLongitude maximumLongitude ]
% 
% For examples, see Catalog_cookbook. Also available at:
% https://geoscience-community-codes.github.io/GISMO/tutorials/html/Catalog_cookbook.html
%
%
% See also CATALOG, IRISFETCH, CATALOG_COOKBOOK

% Author: Glenn Thompson (glennthompson1971@gmail.com)

%% To do:
% Implement name-value parameter pairs for all methods
% Test the Antelope method still works after factoring out db_load_origins
% Test the Seisan method more
% Add in support for 'get_arrivals'

    debug.printfunctionstack('>')

    switch lower(dataformat)
        case 'iris'
            if exist('irisFetch.m','file')
%                 try
                    ev = irisFetch.Events(varargin{:});
                    self = iris(ev);
%                 catch ME
%                     ME
%                     self = Catalog();
%                 end
            else
                warning('Cannot find irisFetch.m')
            end
        case {'css3.0','antelope', 'datascope'}
            self = antelope(varargin{:});
        case 'seisan'
            self = seisan(varargin{:});
        case 'aef'
            self = aef(varargin{:});
        case 'sru'
            self = sru(varargin{:});
        case 'vdap'
            self = vdap(varargin{:});
        case 'zmap'
            self = zmap(varargin{:});
        otherwise
            self = NaN;
            fprintf('format %s unknown\n\n',data_source);
    end
    
    debug.printfunctionstack('<')
end

%% ---------------------------------------------------

function self = iris(ev)
    %readEvents.iris
    % convert an events structure from irisfetch into an Catalog object
    
    debug.printfunctionstack('>')
  
    for i=1:length(ev) % Loop over each element in vector

        time(i) = datenum(ev(i).PreferredTime);
        lon(i) = ev(i).PreferredLongitude;
        lat(i) = ev(i).PreferredLatitude;
        depth(i) = ev(i).PreferredDepth;
        
        if ~isnan(ev(i).PreferredMagnitudeValue)
            mag(i) = ev(i).PreferredMagnitude.Value;
            magtype{i} = ev(i).PreferredMagnitude.Type;
        else
            mag(i) = NaN;
            magtype{i} = '';
        end
        
        etype{i} = ev(i).Type;

    end
    
    request.dataformat = 'iris';
    self = Catalog(time', lon', lat', depth', mag', magtype', etype', 'request', request);
    
    debug.printfunctionstack('<')
    
end

%% ---------------------------------------------------

function self = antelope(varargin)   
% readEvents.antelope load events from a CSS3.0 database using Antelope.
% Requires Antelope and the Antelope toolbox from BRTT.

    debug.printfunctionstack('>')

    if ~admin.antelope_exists
        error('This function requires the Antelope toolbox for Matlab'); 
        return;
    end

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', @isstr);
    p.addParamValue('startTime', []);  
    p.addParamValue('endTime', []);
    p.addParamValue('minimumMagnitude', [], @isnumeric);
    p.addParamValue('maximumMagnitude', [], @isnumeric);
    p.addParamValue('minimumLatitude', [], @isnumeric);
    p.addParamValue('maximumLatitude', [], @isnumeric);
    p.addParamValue('minimumLongitude', [], @isnumeric);
    p.addParamValue('maximumLongitude', [], @isnumeric);  
    p.addParamValue('minimumDepth', [], @isnumeric);
    p.addParamValue('maximumDepth', [], @isnumeric); 
    p.addParamValue('minimumRadius', [], @isnumeric);
    p.addParamValue('maximumRadius', [], @isnumeric);     
    p.addParamValue('boxcoordinates', @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
    p.addParamValue('radialcoordinates', @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
    p.addParamValue('addarrivals', false, @islogical);
    
    % CUSTOM PARAMETERS
    p.addParamValue('subset_expression', '', @isstr);    
    p.addParamValue('subclass', '*', @ischar);
    
    p.parse(varargin{:});
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end 
    
    if exist('boxcoordinates','var')
        minimumLatitude = boxcoordinates(1);
        maximumLatitude = boxcoordinates(2);
        minimumLongitude = boxcoordinates(3);
        maximumLongitude = boxcoordinates(4);            
    end
    
    if exist('radialcoordinates','var')
        centerLatitude = radialcoordinates(1);
        centerLongitude = radialcoordinates(2);
        maximumRadius = radialcoordinates(3);
        %minimumRadius = radialcoordinates(4);            
    end
    
    % Check start & end times
    snum = ensure_dateformat(startTime);
    enum = ensure_dateformat(endTime);

    % Create a dbeval subset_expression if not already set.
    if ~exist('subset_expression', 'var') | isempty(subset_expression)
        if nargin > 2
            expr = '';
            if ~isempty(snum) & isnumeric(snum) 
                expr = sprintf('%s && time >= %f',expr,datenum2epoch(snum));
            end 
            if ~isempty(enum) & isnumeric(enum) 
                expr = sprintf('%s && time <= %f',expr,datenum2epoch(enum));
            end
            if ~isempty(minimumMagnitude) & isnumeric(minimumMagnitude)
                expr = sprintf('%s && (ml >= %f || mb >= %f || ms >= %f)',expr,minimumMagnitude,minimumMagnitude,minimumMagnitude);
            end
            if ~isempty(maximumMagnitude) & isnumeric(maximumMagnitude)
                expr = sprintf('%s && (ml >= %f || mb >= %f || ms >= %f)',expr,maximumMagnitude,maximumMagnitude,maximumMagnitude);
            end
            if ~isempty(minimumLatitude) & isnumeric(minimumLatitude)
                expr = sprintf('%s && (lat >= %f)',expr, minimumLatitude);
            end
            if ~isempty(maximumLatitude) & isnumeric(maximumLatitude)
                expr = sprintf('%s && (lat <= %f)',expr, maximumLatitude);
            end            
            if ~isempty(minimumLongitude) & isnumeric(minimumLongitude)
                expr = sprintf('%s && (lon >= %f)',expr, minimumLongitude);
            end
            if ~isempty(maximumLongitude) & isnumeric(maximumLongitude)
                expr = sprintf('%s && (lon <= %f)',expr, maximumLongitude);
            end            
            if ~isempty(minimumDepth) & isnumeric(minimumDepth)
                expr = sprintf('%s && (depth >= %f)', expr,minimumDepth); 
            end
            if ~isempty(maximumDepth) & isnumeric(maximumDepth)
                expr = sprintf('%s && (depth <= %f)', expr,maximumDepth); 
            end
            if ~isempty(maximumRadius) & isnumeric(maximumRadius)
                expr = sprintf('%s && (distance(lat, lon, %f, %f) <= %f)', ...
                    expr, centerLatitude, centerLongitude, maximumRadius); 
            end            
            subset_expression = expr(4:end);
            clear expr
        end
    end

    % BUILD DBNAMELIST
    dbpathlist = {};
    
    % Loop over databases split into day, month or year volumes
    if strfindbool(dbpath, '%DD') ||  strfindbool(dbpath, '%MM') || strfindbool(dbpath, '%YYYY') % strfind returns [] if false
        if snum < enum
            for dnum=floor(snum):floor(enum-1/1440)
                dv = datevec(dnum);
                thisdb = dbpath;
                thisdb = regexprep(thisdb, '%YYYY', sprintf('%04d',dv(1)) );
                thisdb = regexprep(thisdb, '%MM', sprintf('%02d',dv(2)) );
                thisdb = regexprep(thisdb, '%DD', sprintf('%02d',dv(3)) );
                if exist(sprintf('%s.origin',thisdb),'file')
                    dbpathlist{end+1} = thisdb; % Add here
                end
            end
            dbpathlist = unique(dbpathlist);
        else
            debug.print_debug(0,'when using %YYYY, %MM or %DD in dbpath, must also specify startTime and endTime')
        end
    else
        dbpathlist = {dbpath};
    end

    if isempty(dbpathlist)
        debug.print_debug(0, 'no database found');
    end
    
    % Initialize to empty
    [lat, lon, depth, time, evid, orid, nass, mag, ml, mb, ms] = deal([]);
    [etype, auth, magtype]] = deal({});

    % Loop over databases
    for dbpathitem = dbpathlist
        % Load vectors
        origins = db_load_origins(dbpath, subset_expression);
        if length(origins.lon) == length(origins.mag)
            % Concatentate vectors
            time  = cat(1, time,  origins.time);           
            lon   = cat(1, lon,   origins.lon);
            lat   = cat(1, lat,   origins.lat);
            depth = cat(1, depth, origins.depth);
            evid  = cat(1, evid,  origins.evid);
            orid  = cat(1, orid,  origins.orid);
            nass  = cat(1, nass,  origins.nass);
            mag   = cat(1, mag,   origins.mag);
            mb   = cat(1, mb,   origins.mb);
            ml   = cat(1, ml,   origins.ml);
            ms   = cat(1, ms,   origins.ms);
            etype  = cat(1, etype, origins.etype);
            auth = cat(1,  auth, origins.auth);
            magtype = cat(1, magtype, origins.magtype);
        end
    end
    mag(mag<-3.0)=NaN; % I think Antelope uses a dummy value like -9.9
    self = Catalog(time, lon, lat, depth, mag, magtype, etype);
    
    debug.printfunctionstack('<')
end

%% ---------------------------------------------------

function self = load_aef(varargin)     
    % readEvents.load_aef
    %   Wrapper for loading dat files generated from Seisan S-FILES (REA) databases.
    %   DAT file name is like YYYYMM.dat
    %   DAT file format is like:
    %   
    %   YYYY MM DD HH MM SS c  MagE
    %
    %   where YYYY MM DD HH MM SS is time in UTC
    %         c is subclass
    %              r = rockfall
    %              e = lp-rockfall
    %              l = long period (lp)
    %              h = hybrid
    %              t = volcano-tectonic
    %              R = regional
    %              u = unknown
    %         MagE is equivalent magnitude, based on energy
    %         produced by the program ampengfft. These values come
    %         from magnitude database that formed part of a
    %         real-time alarm system, but these deleted were
    %         maliciously deleted in June 2003. A magnitude was
    %         computed for each event, assuming a location at sea
    %         level beneath the dome. Regardless of type. This was
    %         particularly helpful for understanding trends in
    %         cumulative energy for different types from week to
    %         week or month to month, and for real-time alarm
    %         messages about pyroclastic flow signals where an
    %         indication of event size was very important.
    %
    %  
  
    debug.printfunctionstack('>')

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', '', @isstr);
    p.addParamValue('startTime', 0, @isnumeric);  
    p.addParamValue('endTime', now, @isnumeric);
    p.addParamValue('minimumMagnitude', [], @isnumeric);
    p.addParamValue('subclass', '*', @ischar);
    p.addParamValue('minimumDepth', [], @isnumeric);
    p.addParamValue('maximumDepth', [], @isnumeric);
    p.parse(varargin{:});
    
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found. Perhaps you need to generate from S files?\n',dbpath);
        return;
    end
    
    lnum=snum;

    % loop over all years and months selected
    while (  lnum <= enum ),
        [yyyy, mm] = datevec(lnum);

        % concatenate catalogs
        Object0 = import_aef_file(dbpath,yyyy,mm,snum,enum,p.Results.RUNMODE);
        if exist('self', 'var')
            self = self + Object0;
        else
            self = Object0;
        end
        clear Object0;
        
        % ready for following month
        lnum=datenum(yyyy,mm+1,1);
    end

    self.mag(self.mag<-3)=NaN;

    if ~isempty(self.dnum)

        % cut data according to threshold mag
        if ~isempty(minimumMagnitude)
            disp('Applying minimum magnitude filter')
            m = find(self.mag > minimumMagnitude);
            fprintf('Accepting %d events out of %d\n',length(m),length(self.dnum));
            self.event_list = self.event_list(m);
        end    
    end
    
    debug.printfunctionstack('<')
end

%% ---------------------------------------------------
      
function self = import_aef_file(dirpath, yyyy, mm, snum, enum, RUNMODE)
% readEvents.import_aef_file Read an individual aef_file. Used only by
% readEvents.load_aef
    %   Wrapper for loading dat files generated from Seisan S-FILES (REA) databases.
    %   DAT file name is like YYYYMM.dat
    %   DAT file format is like:
    %   
    %   YYYY MM DD HH MM SS c  MagE
    %
    %   where YYYY MM DD HH MM SS is time in UTC
    %         c is subclass
    %              r = rockfall
    %              e = lp-rockfall
    %              l = long period (lp)
    %              h = hybrid
    %              t = volcano-tectonic
    %              R = regional
    %              u = unknown
    %         MagE is equivalent magnitude, based on energy
    %         produced by the program ampengfft. These values come
    %         from magnitude database that formed part of a
    %         real-time alarm system, but these were deleted in June 2003.
    %
    %         A magnitude was
    %         computed for each event, assuming a location at sea
    %         level beneath the dome. Regardless of type. This was
    %         particularly helpful for understanding trends in
    %         cumulative energy for different types from week to
    %         week or month to month, and for real-time alarm
    %         messages about pyroclastic flow signals where an
    %         indication of event size was very important.

    debug.printfunctionstack('>')
    
    self = [];
    fprintf('\nAPPEND SEISAN %4d-%02d\n',yyyy,mm)
    datfile = fullfile(dirpath,sprintf('%4d%02d.dat',yyyy,mm));
    if exist(datfile,'file') 
        disp(['loading ',datfile]);
        [yr,mn,dd,hh,mi,ss,etype0,mag0] = textread(datfile,'%d %d %d %d %d %d %s %f');
        dnum = datenum(yr,mn,dd,hh,mi,ss)';
        mag = mag0';
        etype = char(etype0)';
        self = Catalog(dnum, [], [], [], mag, {}, etype); 
    else
        disp([datfile,' not found']);
    end
    
    debug.printfunctionstack('<')

end

%% ---------------------------------------------------

function self = seisan(varargin)
    % readEvents.seisan Read a Seisan event database - consisting of
    % S-files. Gathers a list of S-files matching the request and then uses
    % the read_sfile function, to return a structure for each S-file.

    debug.printfunctionstack('>')
    
    % Process input arguments
    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', @isstr);
    p.addParamValue('startTime', []);  
    p.addParamValue('endTime', []);
    p.addParamValue('minimumMagnitude', [], @isnumeric);
    p.addParamValue('maximumMagnitude', [], @isnumeric);
    p.addParamValue('minimumLatitude', [], @isnumeric);
    p.addParamValue('maximumLatitude', [], @isnumeric);
    p.addParamValue('minimumLongitude', [], @isnumeric);
    p.addParamValue('maximumLongitude', [], @isnumeric);  
    p.addParamValue('minimumDepth', [], @isnumeric);
    p.addParamValue('maximumDepth', [], @isnumeric); 
    p.addParamValue('minimumRadius', [], @isnumeric);
    p.addParamValue('maximumRadius', [], @isnumeric);     
    p.addParamValue('boxcoordinates', @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
    p.addParamValue('radialcoordinates', @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
    p.addParamValue('addarrivals', false, @islogical);
    
    % CUSTOM PARAMETERS  
    p.addParamValue('subclass', '*', @ischar);
    
    p.parse(varargin{:});
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end 
    
    if exist('boxcoordinates','var')
        minimumLatitude = boxcoordinates(1);
        maximumLatitude = boxcoordinates(2);
        minimumLongitude = boxcoordinates(3);
        maximumLongitude = boxcoordinates(4);            
    end
    
    if exist('radialcoordinates','var')
        centerLatitude = radialcoordinates(1);
        centerLongitude = radialcoordinates(2);
        maximumRadius = radialcoordinates(3);
        %minimumRadius = radialcoordinates(4);            
    end
    
    % Check start & end times
    snum = ensure_dateformat(startTime);
    enum = ensure_dateformat(endTime);
    
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found\n',dbpath);
        self = struct;
        return;
    end
    
    % get dir list of matching sfiles
    sfiles = seisan_sfile.list_sfiles(dbpath, snum, enum);
    
    % loop over sfiles
    for i=1:length(sfiles)
        % read 
        fprintf('Processing %s\n',fullfile(sfiles(i).dir, sfiles(i).name));
        thiss = seisan_sfile(fileread(fullfile(sfiles(i).dir, sfiles(i).name)));
        try
            s(i)=thiss;
        catch
            s(i)
            thiss
            error('Wrong number of fields?')
        end

        % add to catalog
        dnum(i)  = s(i).otime;
        etype{i} = s(i).subclass;
        lat(i) = s(i).latitude;
        lon(i) = s(i).longitude;
        depth(i) = s(i).depth;
        
        % SCAFFOLD
        mag(i) = NaN;
        try
            sfile_mags = [s(i).magnitude.value];
            if ~isempty(sfile_mags)
                disp('**************** ********************')
                mag(i) = max(sfile_mags);
            end
        end

        % SCAFFOLD also use durations (bbdur) and ampengfft info
        % Compute a magnitude from amp & eng, but need to know where
        % stations are. I can save these as MA and ME, to distinguish from
        % Ml, Ms, Mb, Mw if those exist
    end
    magtype = {};
    self = Catalog(dnum', lon', lat', depth', mag', magtype', etype');
    
    debug.printfunctionstack('<')
end

%% ---------------------------------------------------

function self=vdap(filename)
%readEvents.vdap read Hypoellipse summary files and PHA pickfiles
%   based on Montserrat analog network
%   cObject = read_vdap(filename) will read the catalog file, and create a
%   Catalog object
%
%   Summary file has lines like:
%
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

    %% read the headers and data
    fid = fopen(phafilename);
    tline = fgetl(fid);
    while ischar(tline)
        tline = fgetl(fid);
        stacode = tline(1:4);
        p_eori = tline(5);
        p = tline(6);
        p_uord = tline(7);
        p_qual = tline(8);
        p_datetime = tline(10:24);
        s_datetime = tline(31:35);
        s = tline(37);
        s_qual = tline(39);
    end
    fclose(fid);


end

%% ---------------------------------------------------

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

%% ---------------------------------------------------

function self = zmap(zmapdata)
%readEvents.zmap Translate a ZMAP-format data matrix into a Catalog object
% ZMAP format is 10 columns: longitude, latitude, decimal year, month, day,
% magnitude, depth, hour, minute, second
    lon = zmapdata(:,1);
    lat = zmapdata(:,2);
    time = datenum( floor(zmapdata(:,3)), zmapdata(:,4), zmapdata(:,5), ...
        zmapdata(:,8), zmapdata(:,9), zmapdata(:,10) );
    mag = zmapdata(:,6);
    depth = zmapdata(:,7);
    self = Catalog(time, lon, lat, depth, mag, {}, {});
end

%% ---------------------------------------------------

function out = ensure_dateformat(t)
% stolen from waveform
   % returns a matrix of datenums of same shape as t
   if isnumeric(t)
      out = t;
   elseif ischar(t),
      for n = size(t,1) : -1 : 1
         out(n) = datenum(t(n,:));
      end
   elseif iscell(t)
      out(:) = datenum(t);
   end
   % previously implemented as:
   % if ischar(startt), startt = {startt}; end
   % if ischar (endt), endt = {endt}; end;
   % startt = reshape(datenum(startt(:)),size(startt));
   % endt = reshape(datenum(endt(:)),size(endt));
end

function found = strfindbool(haystack, needle)
    found = strfind(haystack, needle);
    if isempty(found)
        found = false;
    end
end
