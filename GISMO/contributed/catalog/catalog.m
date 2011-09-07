classdef catalog
%
% CATALOG Seismic Catalog class constructor, version 1.0.
% 
%    CATALOG is a class that has been developed around loading and
%    manipulating earthquake catalogs at the Montserrat Volcano Observatory,
%    and more recently, the Alaska Volcano Observatory. 
%
%    CATALOG only imports catalog information from:
%    (1) a CSS3.0 database - the default format used by Antelope/Datascope.
%    (2) a Datascope database written in the "swarms1.0" schema, defined at AVO. 
%        This is the format used by the swarm tracking system.
%
%    It would be trivial to add new import methods, and some useful importers
%    might read:
%    - a Hypoinverse file, 
%    - a Hypoellipse file,
%    - a Seisan catalog,
%    - an AQMS database. 
%
%    C = CATALOG() creates an empty catalog object.
%
%    % ------- READING FROM A CSS3.0 DATASCOPE DATABASE --------
%
%    C = CATALOG(SNUM, ENUM, MINMAG, REGION, DBROOT, ARCHIVEFORMAT) creates
%    a catalog object with preferred origins subsetted between SNUM and ENUM,
%    above magnitude MINMAG, geographically filtered using REGION from the
%    database DBROOT which is archived in ARCHIVEFORMAT.
%    These variables are described in "FIELDS" section below. REGION can
%    either be a 4-element vector [LONMIN LONMAX LATMIN LATMAX] or it can
%    be a region described in avo_volcs.pf such as 'spurr' or 'redoubt'.
%
%    EXAMPLES: (these assume you are on the AVO Linux network)
%
%    1. Create a catalog object of the last 5 days of AEIC events from the region latitude = 55.0 to 65.0, longitude = -170.0 to -135.0
%    c = catalog(utnow-3, utnow, [], [-170.0 -135.0 55.0 65.0] , '/aerun/sum/run/dbsum/dbsum', 'daily');
%
%    2. Create a catalog object of all events with magnitude > 0.2 in the last 3 days of data from Redoubt:
%    c = catalog(utnow-3, utnow, 0.2, 'redoubt', '/avort/oprun/events/antelope/events_antelope', 'daily');
%
%    3. Create a catalog object of all events recorded at Spurr between 1989 and 2006:
%    c = catalog(datenum(1989,1,1), datenum(2006,1,1), [], 'spurr', '/Seis/Kiska4/picks/Total/Total', '');
%
%    % ------- DESCRIPTION OF FIELDS IN CATALOG OBJECT ------------------
%
%    The following are vectors, containing one element per origin:
%
%      DNUM:   a MATLAB datenum corresponding to origin time
%      LON:    origin longitude
%      LAT:    origin latitude
%      DEPTH:  origin depth
%      NASS:   number of associated arrivals
%      EVID:   a number which acts as an event identifier
%      AUTH:   a string which describes who or what computed the hypocenter
%      MAG:    the magnitude.
%      ETYPE:  the event type (subclassification). For example "t" = VT.
%
%     The following describe the catalog data source:
%
%      SNUM:   a datenum describing the start date/time of the catalog.
%      ENUM:   a datenum describing the end date/time of the catalog.
%      MINMAG: a magnitude threshold applied to catalog.
%      REGION: a [minlon maxlon minlat maxlat] filter applied to the catalog.
%      DBROOT: the root database name.
%      ARCHIVEFORMAT:  Either '' for a single database, 'daily' for a daily
%                      archive or 'monthly' for a monthly archive.
%
%    % ------- METHODS -------- %
%
%    plot(c):              - event magnitude versus time plot
%    volplot(c):           - basic lat-lon, lon-depth, lat-depth and depth-time plots.
%    volplotdiff(c1, c2):  - show the differences between origins in two
%                            catalog objects (based on matching evid)
%    plotmagdiff(c1, c2):  - show the differences between magnitudes in two
%                            catalog objects (based on matching evid)
%    plotdailymagstats(c): - plot max, min, mean and median magnitudes for
%                            each day in catalog.
%    compare(c1, c2):      - attempt to match origins in two catalogs based on
%                            small differences in hypocenter and origin time
%    sta = db2stations(region): - return a list of stations based on a region
%    plotbvalue(c):        - simple b-value plot for catalog.
%    plotstations(c):      - superimpose the locations of stations
%
%    % --------- Static Methods - should probably be in libgt instead --------- %
%    plotgrid(gridname):   - superimpose a detection grid (requires a grids database saved in places1.0 Datascope schema)  
%    plotbox(volcano):     - superimpose the region 
%
% See also eventrate

% AUTHOR: Glenn Thompson, Montserrat Volcano Observatory
% $Date: 2000-09-11 $
% $Revision: 0 $


	properties
		lon	% longitude
		lat	% latitude
		depth	% depth (-ve is above sea level, +ve below)
		dnum    % Matlab datenumber marking event origin time
		nass	% number of associated arrivals
		evid	% event id
		mag	% magnitude
		etype	% event classification/type
        snum % start time of catalog
        enum % end time of catalog
        minmag % mag threshold of catalog
        auth
        region
        dbroot
        archiveformat
	end
	methods
        
     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        function cobj = catalog(varargin)
            switch nargin
                case {5, 6, 7}, cobj = cobj.css2catalog(varargin{:});
                case 10, cobj.css_load(varargin{:});
                case 11, cobj.css_import(varargin{:});
                otherwise, disp('Number of input arguments to constructor not recognized');
            end        
        end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		%function cobj = css2catalog(someobj, snum, enum, magthresh, region, db, archiveformat, subclass) % 5 or 6 arguments
        function cobj = css2catalog(cobj, snum, enum, magthresh, region, db, archiveformat, subclass) % 5 or 6 arguments
			% This is the main, high-level constructor for a catalog object from an Antelope database
			% This constructor is based on the m-file db2event and is used to load a catalog from an Antelope database
			%
			% PARAMETERS:  
			% snum = start time/date in datenumber format  
			% enum = end time/date in datenumber format  
			% magthresh will cut out events smaller than this magnitude  
			% region - examples are 'redoubt', 'spurr' and 'alaska' (must be defined in avo_volcs.pf) 
			% Alternatively region can be a 4-element vector like: [leftlon rightlon lowerlat upperlat].
			% db - path of the database (root path to a monthly or daily database)
			% archiveformat	- leave blank if its a normal database, otherwise 'daily' for a daily archive, 'monthly' for a monthly archive
			% 
			% Example:
			%   Last 3 days of data from a daily archive
			%   mycatalogobj = catalog(utnow-3, utnow, -0.5, 'redoubt', 'dbquakes/quakes', 'daily');
			%
			% Author: Glenn Thompson, 2002-2009
  
			%if ~antelope_exists
			%	disp('Antelope not found');
			%end
           
            
            
			if nargin < 6
				error('Not enough arguments');
				return;
			end
  
			if ~exist('archiveformat','var')  
			    archiveformat = '';  
			end

			libgt.print_debug(sprintf('archive format is %s',archiveformat),5);
  
			% Check if region is a char (string) or double (array) class
			if ischar(region)
                if strcmp(region(end-2:end), '_lo')
                    [region, source, lon, lat] = readavogrids(region);
                    leftlon = region(1); rightlon=region(2); lowerlat=region(3); upperlat=region(4);
                else
                    dirname = fileparts(which('catalog'));
                    pffile = [dirname,'/demo/avo_volcs.pf'];
                    [sourcelon, sourcelat, leftlon, rightlon, lowerlat, upperlat] = libgt.readavovolcs(region, pffile); 
                end
                    
			else
				if strcmp(class(region),'double')
					leftlon = region(1); rightlon=region(2); lowerlat=region(3); upperlat=region(4);
				end
			end
			mindepth = -3; % the minimum depth for an AVO catalog event
			maxdepth = 800;
			cobj = cobj.css_load(db, archiveformat, snum, enum, leftlon, rightlon, lowerlat, upperlat, mindepth, maxdepth, magthresh);

			% Append input parameters to structure
			cobj.snum = snum;
			cobj.enum = enum;
			cobj.minmag = magthresh;
			cobj.region = [leftlon rightlon lowerlat upperlat];
			cobj.dbroot = db;
			cobj.archiveformat = archiveformat;

            
            if exist('subclass', 'var')
                    if ~isempty(subclass)

                        index = findstr(cobj.etype, subclass);

                        cobj.lat = cobj.lat(index);
                        cobj.lon = cobj.lon(index);
                        cobj.depth = cobj.depth(index);
                        cobj.dnum = cobj.dnum(index);
                        cobj.evid = cobj.evid(index);
                        cobj.nass = cobj.nass(index);
                        cobj.mag = cobj.mag(index);
                        cobj.etype = cobj.etype(index);
                        cobj.auth = {};
                    end
            end
            
		end



 		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		function cobj = css_load(cobj, dbroot,archiveformat,snum,enum,leftlon,rightlon,lowerlat,upperlat,minz,maxz,minmag)
			% This is called by both constructors above
			% It is a copy of the old 'loadevent' function
			%
			% INPUT:
			%	dbroot			the path of the database
			%	archiveformat		leave blank if its a normal database, otherwise 'daily' for a daily archive, 'monthly' for a monthly archive
			%	snum,enum		start and end datenumbers (Matlab time format, see 'help datenum')
			%	leftlon, rightlon	longitude range in decimal degrees (west is negative, range is -180 to 180)
			%	lowerlat, upperlat	latitude range in decimal degrees (southern hemisphere is negative, range is -90 to 90)
			%	minz, maxz		depth range (below sea level) in kilometres
			%	minmag			minimum magnitude (mb, ml, ms)
			%
			%
			% OUTPUT:
			%	event			a structure containing the fields lat, lon, depth, time, evid, nass and mag for each event meeting the selection criteria
			%
			% Example:
			%	e = css_load('dbseg/Quakes','daily',datenum(2009,1,25),datenum(2009,7,1),-179,179,-89,89,0,30,-0.5);
			%
			% Glenn Thompson, 2007-04-06

			cobj.lon   = [];
			cobj.lat   = [];
			cobj.depth = [];
			cobj.dnum  = [];
			cobj.nass  = [];
			cobj.evid  = [];
			cobj.mag   = [];
			cobj.etype  = '';
            cobj.auth = {};

			if ~exist('minmag','var')
				minmag = -999.0;
			end

			libgt.print_debug(sprintf('archive format is %s',archiveformat),3);

			if strcmp(archiveformat,'')
				dbname = dbroot;
				if exist(sprintf('%s.origin',dbname),'file')
					cobj = cobj.css_import(snum, enum, dbname, leftlon, rightlon, lowerlat, upperlat, minz, maxz, minmag);
				else
					fprintf('%s.origin not found',dbname);
				end
			else
				if strcmp(archiveformat,'daily')
      
					for dnum=floor(snum):floor(enum-1/1440)
						dbname = sprintf('%s_%s_%s_%s',dbroot,datestr(dnum, 'yyyy_mm_dd'));
						if exist(sprintf('%s.origin',dbname),'file')
							e = cobj.css_import(max([dnum snum]),min([dnum+1 enum]),dbname,leftlon,rightlon,lowerlat,upperlat,minz,maxz,minmag);
							cobj.lon   = cat(1,cobj.lon,   e.lon);
							cobj.lat   = cat(1,cobj.lat,   e.lat);
							cobj.depth = cat(1,cobj.depth, e.depth);
							cobj.dnum  = cat(1,cobj.dnum,  e.dnum);
							cobj.evid  = cat(1,cobj.evid,  e.evid);
							cobj.nass  = cat(1,cobj.nass,  e.nass);
							cobj.mag   = cat(1,cobj.mag,   e.mag);
							cobj.etype  = cat(2,cobj.etype,  e.etype);
                            cobj.auth = cat(1, cobj.auth, e.auth);
						else
							fprint('%s.origin not found',dbname);
						end
					end
				else

					for yyyy=dnum2year(snum):1:dnum2year(enum)
						for mm=dnum2month(snum):1:dnum2month(enum)
							dnum = datenum(yyyy,mm,1);
							dbname = sprintf('%s%04d_%02d',dbroot,yyyy,mm);
							if exist(sprintf('%s.origin',dbname),'file')
								e = cobj.css_import(max([dnum snum]),min([ datenum(yyyy,mm+1,1) enum]),dbname,leftlon,rightlon,lowerlat,upperlat,minz,maxz,minmag);
								cobj.lon   = cat(1,cobj.lon,   e.lon);
								cobj.lat   = cat(1,cobj.lat,   e.lat);
								cobj.depth = cat(1,cobj.depth, e.depth);
								cobj.dnum  = cat(1,cobj.dnum,  e.dnum);
								cobj.evid  = cat(1,cobj.evid,  e.evid);
								cobj.nass  = cat(1,cobj.nass,  e.nass);
								cobj.mag   = cat(1,cobj.mag,   e.mag);
								cobj.etype  = cat(1,cobj.etype,  e.etype);
                                cobj.auth = cat(1, cobj.auth, e.auth);
							else
								fprintf('%s.origin not found',dbname);
							end
						end
					end
				end
			end

			% eliminate bogus magnitudes
			i = find(cobj.mag > 10.0);
			cobj.mag(i)=NaN;
		end



		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		function cobj = css_import(cobj, snum,enum,dbname,leftlon,rightlon,lowerlat,upperlat,minz,maxz,minmag)

			% This code was previously a separate function called dbimport2event
			
			lon=[];lat=[];depth=[];dnum=[];evid=[];nass=[];mag=[];etype=[];auth={};

			% create blank event structure
			cobj.lon   = lon;
			cobj.lat   = lat;
			cobj.depth = depth;
			cobj.dnum  = dnum;
			cobj.nass  = nass;
			cobj.evid  = evid;
			cobj.mag   = mag;
			cobj.etype  = etype;
            cobj.auth = auth;

			libgt.print_debug(sprintf('Loading data from %s',dbname),1);

			% First, lets get a summary of origins
			try
				db = dbopen(dbname, 'r');
            catch ME
				if ~exist(dbname, 'file')
					libgt.print_debug(sprintf('%s does not exist',dbname),1);
				else
					rethrow(ME);
				end
 			   	return;
			end

			db = dblookup_table(db, 'origin');
			if (dbquery(db, 'dbRECORD_COUNT')==0)
				if ~exist([dbname,'.origin'], 'file')
					libgt.print_debug(sprintf('%s.origin does not exist',dbname),1);
				else
					libgt.print_debug(sprintf('Could not open %s.origin',dbname),1);
				end
				return;
			end
			db = dbjoin(db, dblookup_table(db, 'event') );
			db = dbsubset(db, 'orid == prefor');
			db = dbsort(db, 'time');

			numprefors = dbquery(db,'dbRECORD_COUNT');
			libgt.print_debug(sprintf('Got %d prefors prior to subsetting',numprefors),2);
	
			% Do the subsetting
			if exist('minmag','var')
                if ~isempty(minmag)
                    expression_mag  = sprintf(' mb    >= %f  || ml    >=  %f || ms >=  %f',minmag,minmag,minmag);
                    db = dbsubset(db, expression_mag);
                    numevents = dbquery(db,'dbRECORD_COUNT');
                    libgt.print_debug(sprintf('Got %d prefors after mag subsetting (%s)',numevents, expression_mag),2);
                end
			end


			minepoch = datenum2epoch(snum);
			maxepoch = datenum2epoch(enum);
			expression_time = '';
			expression_time = sprintf('time  >= %f && time  <= %f',minepoch,maxepoch);
			try
				db = dbsubset(db, expression_time);
			catch
				error(sprintf('%s: dbsubset: %s',mfilename, expression_time));
			end


			numevents = dbquery(db,'dbRECORD_COUNT');
			libgt.print_debug(sprintf('Got %d prefors after time subsetting',numevents),2);
			if exist('upperlat','var')
				expression_lat  = sprintf('lat   >= %f  && lat   <= %f',lowerlat,upperlat);
				db = dbsubset(db, expression_lat);
			end

			if exist('rightlon','var')
				if (leftlon < rightlon) 
					% does not span the 180 degree discontinuity
					expression_lon  = sprintf('lon   >= %f  && lon   <= %f',leftlon,rightlon);
				else
					% does span the 180 degree discontinuity
					expression_lon  = sprintf('lon   >= %f  || lon   <= %f',leftlon,rightlon);
				end
				db = dbsubset(db, expression_lon);
			end


			numevents = dbquery(db,'dbRECORD_COUNT');

			libgt.print_debug(sprintf('Got %d prefors after region subsetting (%s && %s)',numevents,expression_lon,expression_lat),2);

			if exist('maxz','var')
				expression_z    = sprintf('depth >= %f    && depth <=  %f',minz,maxz);
				db = dbsubset(db, expression_z);
			end

			numevents = dbquery(db, 'dbRECORD_COUNT');
			libgt.print_debug(sprintf('Got %d prefors after depth subsetting (%s)',numevents,expression_z),2);
			libgt.print_debug(sprintf('Reading %d events from %s between  %s and %s', numevents, dbname, datestr(snum,0), datestr(enum, 0)),1); 


			if numevents>0
				[lat, lon, depth, time, evid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'evid', 'nass', 'ml', 'mb', 'ms', 'auth');
				try
					etype0 = dbgetv(db,'etype');
			    end
     
 			   	if isempty(etype0)
			        	etype = char(ones(numevents,1)*'R');
			    else
  			     	% convert etypes
					etype0=char(etype0);
					i=find(etype0=='a');
					etype(i)='t';
					i=find(etype0=='b');
					etype(i)='l';
					i=find(etype0=='-');
					etype(i)='u';  
					i=find(etype0==' ');
					etype(i)='u';
  			  	end

				% get mag
				mag = max([ml mb ms], [], 2);

 			   	% convert time from epoch to Matlab datenumber
				dnum = epoch2datenum(time);

			end

	
			% close database
			dbclose(db);

			% create event structure
			cobj.lon   = lon;
			cobj.lat   = lat;
			cobj.depth = depth;
			cobj.dnum  = dnum;
			cobj.nass  = nass;
			cobj.evid  = evid;
			cobj.mag   = mag;
			cobj.etype  = etype;
            cobj.auth = auth;
		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		function plot(cobj, varargin)

			% Plot a catalog object as event magnitude versus time
			% plot(cobj) plots magnitude vs. date/time
			% plot(cobj, 'splitby', 'etype') plots the same, but with each event type in a separate subplot
			% plot(cobj, 'magthresh', 1.0) plots magnitude vs. date/time after filtering out all events smaller than mag=1.0
			% If cobj is an array of event structures, each will be plotted on a separate figure
			%
			% Author: Glenn Thompson
			libgt.print_debug(sprintf('> %s', mfilename),2);
			[splitby, magthresh] = libgt.process_options(varargin, 'splitby', 'none', 'magthresh', -999.0);


			for c = 1 : length(cobj)
				i = find(cobj(c).mag >= magthresh);
				figure(gcf+1);

				if strcmp(splitby, 'none')

					plot( cobj(c).dnum(i), cobj(c).mag(i), 'bo' );
					disp(sprintf('Plotting mag vs dnum for %d events',length(i)));
					datetick('x', 'keeplimits');
					ymax = nanmax(libgt.catmatrices(1, cobj(c).mag(i)));
					set(gca, 'YLim', [0 ymax]);
					ylabel('mag');
				else
					if strcmp(splitby, 'etype')
						etypes = unique(cobj(c).etype(i));
						numetypes = length(etypes); 

						for count=1:numetypes
							j=find(ismember(cobj(c).etype(i), etypes(count))==1);
							subplot(numetypes, 1, count), plot( cobj(c).dnum(j), cobj(c).mag(j), 'bo' );
							%disp(sprintf('Plotting mag vs dnum for %d events for etype %s',length(j),etypes(count)));
							datetick('x', 'keeplimits');
							ymax = nanmax(libgt.catmatrices(1, cobj(c).mag(j)));
							set(gca, 'YLim', [0 ymax]);
							ylabel('mag');
							title(etypes(count));
						end
					end
				end
			end
		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		function cobj = volplot(cobj, varargin)
            [nsigma, volcano, gridname] = libgt.process_options(varargin, 'nsigma', '5', 'volcano', '', 'gridname', '');

			% find stations in this region
            sta = db2stations(cobj);

			figure;

			% lon-lat
			axes('position',[0.05 0.45 0.5 0.5]);
			plot(cobj.lon, cobj.lat,'*');
			grid on;
			if length(sta.lon) > 0
				hold on;
				plot(sta.lon, sta.lat, 'rv');
				text(sta.lon, sta.lat, sta.code);
			end
			axis(gca, cobj.region);
                        
            if ~isempty(volcano)
                %plotbox(volcano)
            end
            if ~isempty(gridname)
                %plotbox(gridname)
            end

			% depth-longitude
			axes('position',[0.05 0.05 0.5 0.35]);
			plot(cobj.lon, cobj.depth, '*');
			ylabel('Depth (km)');
			xlabel('Longitude');
			grid on;
			set(gca, 'YDir', 'reverse');
			set(gca, 'XLim', [cobj.region(1) cobj.region(2)]);

			% depth-lat
			axes('position',[0.6 0.45 0.35 0.5]);
			plot(cobj.depth, cobj.lat, '*');
			xlabel('Depth (km)');
			set(gca, 'XDir', 'reverse');
			ylabel('Latitude');
			grid on;
			set(gca, 'YLim', [cobj.region(3) cobj.region(4)]);

			% time-depth
			figure;
			plot(cobj.dnum, cobj.depth, '*');
			datetick('x');
			xlabel('Date');
			ylabel('Depth (km)');
			set(gca, 'YDir', 'reverse');
			grid on;

			% change region
			latrangeinkm = 111 * (cobj.region(4) - cobj.region(3));
			lonrangeinkm = 111 * (cobj.region(2) - cobj.region(1)) * cos(mean(  cobj.region(3:4) ));
			medianlat = median(cobj.lat);
			medianlon = median(cobj.lon);
			cosine = cos(medianlat);
			stdevlat = std(cobj.lat);
			stdevlon = std(cobj.lon);
			rangeindeg = max([stdevlat stdevlon*cosine]) * nsigma;
			cobj.region = [(medianlon - rangeindeg/2) (medianlon + rangeindeg/2) (medianlat - rangeindeg/2) (medianlat + rangeindeg/2)];

			% some other potential useful mapping ideas
			%latmin = min(cobj1.lat) - latrange/20;
			%lonmin = min(cobj1.lon) - lonrange/20;
			%latmax = max(cobj1.lat) + latrange/20;
			%lonmax = max(cobj1.lon) + lonrange/20;
			%h = worldmap([latmin latmax],[lonmin lonmax])
			%load coast
			%plotm(lat, long)
			% Add some standard datasets from Matlab
			%geoshow('landareas.shp', 'FaceColor', [0.15 0.5 0.15])
			%geoshow('worldlakes.shp', 'FaceColor', 'cyan')
			%geoshow('worldrivers.shp', 'Color', 'blue')
			%geoshow('worldcities.shp', 'Marker', '.',...
				%'MarkerEdgeColor', 'red')
			% Add features with textm, e.g.
			% textm(64.83778, -147.71639, 'Fairbanks')
			% plotm(64.83778, -147.71639, 'ro')
			%plotm(cobj1.lat, cobj1.lon, '*');
		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		function volplotdiff(cobj1, cobj2)

            sta = db2stations(cobj1);

			figure;

			% lon-lat
			l=1;
			axes('position',[0.05 0.45 0.5 0.5]);
			for i=1:length(cobj1.evid)
				j=find(cobj2.evid==cobj1.evid(i));
				if length(j)==1
					hold on;
					plot(cobj1.lon(i), cobj1.lat(i), 'ro');
					plot(cobj2.lon(j), cobj2.lat(j), 'cs');
					plot([cobj1.lon(i) cobj2.lon(j)], [cobj1.lat(i) cobj2.lat(j)], 'k:');
				        diff.lon(l) = cobj2.lon(j) - cobj1.lon(i);
				        diff.lat(l) = cobj2.lat(j) - cobj1.lat(i);
				        diff.depth(l) = cobj2.depth(j) - cobj1.depth(i);
				        l=l+1;
				else
					disp(sprintf('there are %d evids in %s matching evid %d in %s',length(j),cobj2.dbroot,cobj1.evid(i),cobj1.dbroot));
				end
			end
			if length(sta.lon) > 0
				hold on;
				plot(sta.lon, sta.lat, 'bv');
				text(sta.lon, sta.lat, sta.code);
			end
			axis(gca, cobj1.region);

			% lon-depth
			axes('position',[0.05 0.05 0.5 0.35]);
			for i=1:length(cobj1.evid)
				j=find(cobj2.evid==cobj1.evid(i));
				if length(j)==1
					hold on;
					plot(cobj1.lon(i), cobj1.depth(i), 'ro');
					plot(cobj2.lon(j), cobj2.depth(j), 'cs');
					plot([cobj1.lon(i) cobj2.lon(j)], [cobj1.depth(i) cobj2.depth(j)], 'k:');
				end
			end
			ylabel('Depth (km)');
			xlabel('Longitude');
			set(gca, 'YDir', 'reverse');
			set(gca, 'XLim', [cobj1.region(1) cobj1.region(2)]);

			% depth-lat
			axes('position',[0.6 0.45 0.35 0.5]);
			for i=1:length(cobj1.evid)
				j=find(cobj2.evid==cobj1.evid(i));
				if length(j)==1
					hold on;
					plot(cobj1.depth(i), cobj1.lat(i), 'ro');
					plot(cobj2.depth(j), cobj2.lat(j), 'cs');
					plot([cobj1.depth(i) cobj2.depth(j)], [cobj1.lat(i) cobj2.lat(j)], 'k:');
				end
			end
			xlabel('Depth (km)');
			set(gca, 'XDir', 'reverse');
			ylabel('Latitude');
			set(gca, 'YLim', [cobj1.region(3) cobj1.region(4)]);

			figure;
			[dummy,ii,jj]=intersect(cobj1.evid,cobj2.evid);
			if exist('diff','var')
				subplot(2,1,1), plot(diff.lon, diff.lat, '*'); xlabel('dLongitude'); ylabel('dLatitude'); axis equal;axis square;
				subplot(2,1,2), plot(diff.depth, cobj1.depth(ii), '*'); xlabel('dDepth'); ylabel('Depth'); set(gca, 'YDir', 'reverse'); set(gca, 'XDir', 'reverse');
				difflonmean = mean(diff.lon);
				difflonstd = std(diff.lon);
				difflatmean = mean(diff.lat);
				difflatstd = std(diff.lat);
				diffdepthmean = mean(diff.depth);
				diffdepthstd = std(diff.depth);
				disp(sprintf('Average change in longitude was %.2f km (std: %.2f km)',difflonmean*cos(deg2rad(cobj1.lat(1)))*111.0,difflonstd*cos(deg2rad(cobj1.lat(1)))*111.0));
				disp(sprintf('Average change in latitude was %.2f km (std: %.2f km)',difflatmean*111.0,difflatstd*111.0));
				disp(sprintf('Average change in depth was %.2f km (std: %.2f km)',diffdepthmean,diffdepthstd));
				lonmean1 = mean(cobj1.lon(ii));
				lonmean2 = mean(cobj2.lon(jj));
				latmean1 = mean(cobj1.lat(ii));
				latmean2 = mean(cobj2.lat(jj));
				depthmean1 = mean(cobj1.depth(ii));
				depthmean2 = mean(cobj2.depth(jj));
				lonstd1 = std(cobj1.lon(ii))*cos(deg2rad(latmean1))*111.0;
				lonstd2 = std(cobj2.lon(jj))*cos(deg2rad(latmean1))*111.0;
				latstd1 = std(cobj1.lat(ii))*111.0;
				latstd2 = std(cobj2.lat(jj))*111.0;
				depthstd1 = std(cobj1.depth(ii));
				depthstd2 = std(cobj2.depth(jj));
				disp(sprintf('Average event moved from %.4f, %.4f, %.2f km to %.4f %.4f %.2f km', lonmean1, latmean1, depthmean1, lonmean2, latmean2, depthmean2));
				disp(sprintf('std in longitude changed from %.2f km to %.2f km',lonstd1,lonstd2));
				disp(sprintf('std in latitude changed from %.2f km to %.2f km',latstd1,latstd2));
				disp(sprintf('std in depth changed from %.2f km to %.2f km',depthstd1,depthstd2));
				disp(sprintf('source volume corresponding to 3d-std changed from %.3f km^3 to %.3f km^3', lonstd1*latstd1*depthstd1, lonstd2*latstd2*depthstd2));
			end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function sta = db2stations(cobj)
            stalon = []; stalat = []; stacode = [];
            
            DBMASTER = getenv('DBMASTER');
            
            if ~isempty(DBMASTER)
                if exist(DBMASTER, 'file')
                    db = dbopen(DBMASTER, 'r');
                    db = dblookup_table(db, 'site');
                    db = dbsubset(db, 'offdate==NULL');
                    db = dbsubset(db, sprintf('lat > %f && lat < %f', cobj.region(3), cobj.region(4)));
                    db = dbsubset(db, sprintf('lon > %f && lon < %f', cobj.region(1), cobj.region(2)));
                    nstations = dbquery(db, 'dbRECORD_COUNT');
                    if nstations > 0
                        disp(sprintf('%d stations were found in this cobj1.region',nstations));
                        [stalon, stalat, stacode] = dbgetv(db, 'lon', 'lat', 'sta');
                    end
                end
            end
            sta.lon = stalon; sta.lat = stalat; sta.code = stacode;
        end % function		
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [matches, total] = compare(cobj1, cobj2)
            figure;
            hold on;
            xlabel('Mag1');
            ylabel('Mag2');
            matches = 0; total = 0;
            mag.matched = [];
            mag.unmatched = [];
            for c1=1:length(cobj1.evid)
                total = total + 1;
                s = sprintf('Event %d (%d): %s %.3f %.3f %.1f',c1, cobj1.evid(c1), datestr(cobj1.dnum(c1),31), cobj1.lon(c1), cobj1.lat(c1), cobj1.mag(c1));
                x = deg2km(distance(cobj1.lat(c1), cobj1.lon(c1), cobj2.lat, cobj2.lon));
                i = find(x < 20); % within .2 degrees (20 km)
                %s = sprintf('%s\n There are %d events within 0.2 degrees of event %d', s, length(i), c1);
                if length(i) > 0
                    t = abs(cobj1.dnum(c1) - cobj2.dnum(i));
                    j = find(t * 86400 < 10); % within 10s
                    %s = sprintf('%s: Of these, %d are within 10 seconds', s, length(j));
                    if length(j)>0
                        matches = matches + 1;
                        if length(j)==1
                            s = sprintf('%s\n= Event %d (%d): %s %.3f %.3f %.1f',s, i(j), cobj2.evid(i(j)), datestr(cobj2.dnum(i(j)),31), cobj2.lon(i(j)), cobj2.lat(i(j)), cobj2.mag(i(j)));
                            s = sprintf('%s (%.2f km, %.2f s)', s, x(i(j)), t(j));
                            plot(cobj1.mag(c1), cobj2.mag(i(j)), 'o');
                        else
                            s = sprintf('%s. More than 1 match\n',s);
                        end
                        mag.matched = [mag.matched cobj1.mag(c1)];
                    else
                        s = sprintf('%s. No time match',s);
                        mag.unmatched = [mag.unmatched cobj1.mag(c1)];
                    end
                    
                else
                    s = sprintf('%s. No distance match',s);
                    mag.unmatched = [mag.unmatched cobj1.mag(c1)];
                end
                disp(s);
            end
            set(gca, 'XLim', [-1 3], 'YLim', [-1 3]);
            plot([-1 3], [-1 3], ':');
            figure;
            subplot(2,1,1), hist(mag.matched, -1:0.25:3), xlabel('Mag1'),title('Matched events');
            subplot(2,1,2), hist(mag.unmatched, -1:0.25:3),xlabel('Mag1'),title('Unmatched events');
        end
                         
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		function plotdailymagstats(cobj)

			% plot the max, mean, min and various percentiles of the magnitude samples each day
			day = floor(cobj.dnum);
			c=1;
			time=[];
			for dnum=min(day):max(day)
				i = find(day == dnum);
				if (length(i)>0)
					minmag(c)=nanmin(cobj.mag(i));
					maxmag(c)=nanmax(cobj.mag(i));
					meanmag(c)=nanmean(cobj.mag(i));
					stdev(c)=std(cobj.mag(i));
					med(c)=nanmedian(cobj.mag(i));
					p95(c)=prctile(cobj.mag(i),95);
					p5(c)=prctile(cobj.mag(i),5);
				else
					minmag(c)=NaN;
					maxmag(c)=NaN;
					meanmag(c)=NaN;
					stdev(c)=NaN;
					med(c)=NaN;
					p95(c)=NaN;
						p5(c)=NaN;
				end
				time(c)=dnum;
				c=c+1;
			end
			if length(time)>0
				plot(time,maxmag,time,p95,time,meanmag,time,med,time,p5,time,minmag);
				ylabel('mag');
				legend('maximum','95th%ile','mean','median','5th%ile','minimum');
				datetick('x');
				%plot(time,stdev);
				%dateticklabel('x');
				%title('standard deviation in mag');ylabel('mag');
			end
		end
		
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function plotmagdiff(cobj1, cobj2)
            figure;
            hold on;
            
            diff=[];
 			for i=1:length(cobj1.evid)
				j=find(cobj2.evid==cobj1.evid(i));
				if length(j)==1
                    plot(cobj1.mag(i), cobj2.mag(j),'*');
                    diff = [diff (cobj2.mag(j)-cobj1.mag(i))];
                end
            end
            xlabel('First magnitude');
            ylabel('Second magnitude');
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            axmin = min([xlim ylim]);
            axmax = max([xlim ylim]);
            plot([axmin axmax],[axmin axmax],':');
            disp(sprintf('Change: mean=%.1f, median=%.1f, std=%.1f, max=%.1f',mean(diff),median(diff),std(diff),max(diff)));
        end
                    
        function plotbvalue(cobj);
            minmag = floor(min(cobj.mag) * 10)/10;
            maxmag = floor(max(cobj.mag) * 10)/10;
            threshold = minmag:0.1:maxmag;
            sortmag = sort(cobj.mag);
            for c=1:length(threshold)
                count(c)=sum(find(sortmag > threshold(c)));
            end
            figure;
            plot(threshold, count); 
        end
        
        function mapexample()
            % simple epicentral plot
            figure;
            close all
            h = worldmap([latmin latmax],[lonmin lonmax])
            load coast
            plotm(lat, long)

            % Add some standard datasets from Matlab
            geoshow('landareas.shp', 'FaceColor', [0.15 0.5 0.15])
            geoshow('worldlakes.shp', 'FaceColor', 'cyan')
            geoshow('worldrivers.shp', 'Color', 'blue')
            geoshow('worldcities.shp', 'Marker', '.',...
                'MarkerEdgeColor', 'red')


            % Add features with textm, e.g.
            % textm(64.83778, -147.71639, 'Fairbanks')
            % plotm(64.83778, -147.71639, 'ro')

            plotm(event.lat, event.lon, '*');
        end
        
        
        function plotstations(cobj)
            sta = db2stations(cobj);
			if length(sta.lon) > 0
				hold on;
				plot(sta.lon, sta.lat, 'bv');
				text(sta.lon, sta.lat, sta.code);
			end
			axis(gca, cobj.region);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods Static
        function plotgrid(gridname)
            [region, source, lon, lat] = readavogrids(gridname);
			if length(region) > 0
				hold on;
				plot(source.lon, source.lat, 'b^');
                plot([min(lon) max(lon) max(lon) min(lon) min(lon)], [min(lat) min(lat) max(lat) max(lat) min(lat)], '-');
                %axis(gca, region);
			end
        end        
        
        function plotbox(volcano)
            [sourcelon, sourcelat, minlon, maxlon, minlat, maxlat] = libgt.readavovolcs(volcano);
            hold on;
            plot(sourcelon, sourcelat, 'r^');
            text(sourcelon, sourcelat, volcano);
            plot([minlon maxlon maxlon minlon minlon], [minlat minlat maxlat maxlat minlat], '-');
        end
	end
end

