classdef catalog
%
% CATALOG Seismic Catalog class constructor, version 1.1.
% 
%    CATALOG is a class that for loading, manipulating and saving earthquake
%    catalogs.
%
%    CATALOG imports catalog information from a CSS3.0 database 
%    - the default format used by Antelope/Datascope.
%
%%   USAGE
%    cobj = catalog() creates an empty catalog object.
%
%    cobj = catalog(FILEPATH, FORMAT) loads the file at FILEPATH in the
%    format FORMAT. The only FORMAT currently implemented is 'antelope'.
%
%    cobj = catalog(FILEPATH, 'antelope', 'dbeval', EXPRESSION) subsets the
%    database with a dbeval EXPRESSION.
%
%    If the dbeval parameter name/value pair is omitted, a dbeval expression 
%    can also be formed from other name/value pairs. These are:
%       NAME       VALUE
%       'snum'     a datenum denoting the minimum origin time
%       'enum'     a datenum denoting the maximum origin time
%       'minmag'   the minimum magnitude
%       'mindepth' the minimum depth (in km)
%       'maxdepth' the maximum depth (in km)
%       'region'   a 4-element vector: [minlon maxlon minlat maxlat]
%   
%   'region' can also be entered as a volcano name like 'Redoubt' in which
%   case the appropriate 4-element vector will be loaded from avo_volcs.pf
%   in the demo directory.
%
%   If the database is stored in daily volumes, rather than a single
%   database like somedir/mydb_YYYY_MM_DD then use the 'archiveformat'
%   name/value pair, e.g.
%   cobj = catalog('somedir/mydb', 'antelope', 'archiveformat', 'daily');
%   For a monthly volume, set 'archiveformat' to 'monthly'.    
%    
%
%%   READING FROM A CSS3.0 DATASCOPE DATABASE
%
%    COBJ = CATALOG(SNUM, ENUM, MINMAG, REGION, DBROOT, ARCHIVEFORMAT) creates
%    a catalog object with preferred origins subsetted between SNUM and ENUM,
%    above magnitude MINMAG, geographically filtered using REGION from the
%    database DBROOT which is archived in ARCHIVEFORMAT.
%    These variables are described in "FIELDS" section below. REGION can
%    either be a 4-element vector [LONMIN LONMAX LATMIN LATMAX] or it can
%    be a region described in avo_volcs.pf such as 'spurr' or 'redoubt'.
%
%    EXAMPLES: (2-5 assume you are connected to the Seislab computer network at UAF/GI)
%
%      (1) Reading data from the demo database
%          dirname = fileparts(which('catalog')); % get the path to the catalog directory
%          dbroot = [dirname,'/demo/avodb200903']; 
%          cobj = catalog(dbroot, 'antelope', 'snum', datenum(2009,3,20), 'enum', datenum(2009,3,23), 'region', 'Redoubt')
%
%          Identical results could be obtained with:
%           
%          cobj = catalog(dbroot, 'antelope', 'dbeval','time >= "2009/3/20" && time <= "2009/3/23" && lon >= -153.0 && lon <= -152.2 && lat >= 60.3 && lat <= 60.7')
%
%      (2) Create a catalog object of all AEIC events greater than M=4.0 in 2009 from the region latitude = 55.0 to 65.0, longitude = -170.0 to -135.0
%          cobj = catalog('/Seis/catalogs/aeic/Total/Total', 'antelope', 'snum', datenum(2009,1,1), 'enum', datenum(2010,1,1), 'minmag', 4.0, 'region', [-170.0 -135.0 55.0 65.0]);
%
%      (3) Create a catalog object of all AEIC events greater than M=1.0 in August 2011 from the region latitude = 55.0 to 65.0, longitude = -170.0 to -135.0
%          but this time, using the daily summary databases.
%          cobj = catalog('/aerun/sum/run/dbsum/Quakes', 'antelope', 'snum', datenum(2011,8,1), 'enum', datenum(2011,9,1), 'minmag', 1.0, 'region', [-170.0 -135.0 55.0 65.0], 'archiveformat', 'daily');
%
%      (4) Create a catalog object of all events (regardless of magnitude) in the last 3 days of data from Redoubt:
%          cobj = catalog('/avort/oprun/events/antelope/events_antelope', 'antelope', 'snum', libgt.utnow-3, 'enum', libgt.utnow, 'region', 'redoubt');
%
%      (5) Create a catalog object of all AEIC events recorded within 10 km of Spurr [61.2989 -152.2539] between 1989 and 2006:
%          cobj = catalog('/Seis/catalogs/aeic/Total/Total', 'antelope', 'dbeval', 'time > "1989/1/1" && time < "2006/1/1" && deg2km(distance(61.2989, -152.2539, lat, lon))<10.0');
%
%
%%   PROPERTIES
%
%    For a list of properties type properties(catalog)
%
%    The following are vectors, containing one element per origin:
%
%      DNUM:   a MATLAB datenum corresponding to origin time
%      LON:    origin longitude
%      LAT:    origin latitude
%      DEPTH:  origin depth
%      NASS:   number of associated arrivals
%      EVID:   a number which acts as an event identifier
%      ORID:   a number which acts as an origin identifier
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
%     The final property is "ARRIVAL". This is a cell array containing 1
%     structure per origin in the catalog. Normally it is left blank
%     because it can be time consuming to load arrival data from big
%     catalogs. To populate it for a CSS3.0 Datascope database, call:
%       cobj=cobj.addArrivals();
%
%%   METHODS
%
%    For a list of methods type methods(catalog)
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
%    c = addfield(c, 'newfield', 'value):   - add a new field to a catalog
%                                               object.
%
%%   STATIC METHODS 
%    test:  - a simple test suite for the catalog class
%    css_import: - low-level routine for loading data from CSS3.0 database
%
%% See also EVENTRATE
%
%% AUTHOR: Glenn Thompson

% $Date$
% $Revision$

%% PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	properties (SetAccess=private)
		lon	= [];% longitude
		lat	= []; % latitude
		depth = [];	% depth (-ve is above sea level, +ve below)
		dnum = [];    % Matlab datenumber marking event origin time
		nass = [];	% number of associated arrivals
		evid = [];	% event id
        orid = []; % origin id
		mag	= []; % magnitude
        mb = [];
        ml = [];
        ms = [];
		etype = '';	% event classification/type
        snum = []; % start time of catalog
        enum = [];% end time of catalog
        minmag =[]; % mag threshold of catalog
        auth = {};
        region = [];
        dbroot = '';
        archiveformat ='';
        misc_fields = {};
        misc_values = {};
        arrival = {};
    end
    
    %% METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	methods
        
     	%------------------------------------------------------------------
        %% Constructor.    
        function cobj = catalog(filepath, format, varargin)
            % CATALOG/CATALOG
            %   CATALOG constructor. HELP CATALOG for information.
            switch nargin
                case 0, disp('Creating null catalog object'); return;
                case 1, format = 'css3.0'
            end
            %cobj = catalog;
            switch format
                case {'css3.0','antelope', 'datascope'}
                    cobj = cobj.css2catalog(filepath, varargin{:});
                case 'seisan'
                    cobj = cobj.seisan2catalog(filepath, varargin{:});
                otherwise
                    format
                    fprintf('format %s unknown',format);
            end      
        end

		%------------------------------------------------------------------
        %% CSS2CATALOG
        function cobj = css2catalog(cobj, dbpath, varargin)            
            % CATALOG/CSS2CATALOG
            %   Wrapper for loading CSS3.0 databases.
			%if ~admin.antelope_exists
			%	disp('Antelope not found');
            %    return;
            %end
            
            [dbeval, archiveformat, snum, enum, minmag, region, subclass, mindepth, maxdepth] = libgt.process_options(varargin, 'dbeval', '', 'archiveformat', '', 'snum', [], 'enum', [], 'minmag', [], 'region', [], 'subclass', '*', 'mindepth', [], 'maxdepth', []); 
  
			% Check if region is a char (string) or double (array) class
			if ischar(region)
                if strcmp(region(end-2:end), '_lo')
                    [region, source, lon, lat] = readavogrids(region);
                    leftlon = region(1); rightlon=region(2); lowerlat=region(3); upperlat=region(4);
                else
                    dirname = fileparts(which('catalog'));
                    pffile = [dirname,'/demo/avo_volcs.pf'];
                    [sourcelon, sourcelat, leftlon, rightlon, lowerlat, upperlat] = libgt.readavovolcs(region, pffile); 
                    region = [leftlon rightlon lowerlat upperlat];
                end                   
			else
				if strcmp(class(region),'double') & ~isempty(region)
					leftlon = region(1); rightlon=region(2); lowerlat=region(3); upperlat=region(4);
				end
            end
            
            % Create a dbeval expression if not already set.
            if isempty(dbeval)
                if nargin > 2
                    expr = '';
                    if ~isempty(snum)
                        expr = sprintf('%s && time >= %f',expr,datenum2epoch(snum));
                    end 
                    if ~isempty(enum)
                        expr = sprintf('%s && time <= %f',expr,datenum2epoch(enum));
                    end
                    if ~isempty(minmag)
                        expr = sprintf('%s && (ml >= %f || mb >= %f || ms >= %f)',expr,minmag,minmag,minmag);
                    end
                    if ~isempty(region)
                        expr = sprintf('%s && (lat >= %f && lat <= %f && lon >= %f && lon <= %f)',expr,lowerlat, upperlat, leftlon, rightlon);
                    end
                    if ~isempty(mindepth)
                        expr = sprintf('%s && (depth >= %f)', expr,mindepth); 
                    end
                    if ~isempty(maxdepth)
                        expr = sprintf('%s && (depth <= %f)', expr,maxdepth); 
                    end
                    dbeval = expr(4:end);
                    clear expr
                end
            end
            
 			% Append input parameters to structure
			if ~isempty(snum)
                cobj.snum = snum;
            else
                cobj.snum = floor(now-7);
            end
			if ~isempty(enum)
                cobj.enum = enum;
            else
                cobj.enum = ceil(now);
            end            
			cobj.minmag = minmag;
			cobj.region = region;
			cobj.dbroot = dbpath;
			cobj.archiveformat = archiveformat;
            
            cobj = cobj.css_load(dbpath, archiveformat, dbeval);
	
            cobj.snum = min([cobj.snum min(cobj.dnum)]);
            cobj.enum = max([cobj.enum max(cobj.dnum)]);            

            
            if exist('subclass', 'var')
                    if strcmp(subclass, '*')==0

                        index = findstr(cobj.etype, subclass);

                        cobj.lat = cobj.lat(index);
                        cobj.lon = cobj.lon(index);
                        cobj.depth = cobj.depth(index);
                        cobj.dnum = cobj.dnum(index);
                        cobj.evid = cobj.evid(index);
                        cobj.orid = cobj.orid(index);
                        cobj.nass = cobj.nass(index);
                        cobj.mag = cobj.mag(index);
                        cobj.etype = cobj.etype(index);
                        cobj.auth = {};
                    end
            end
            cobj = cobj.addfield('dbeval', dbeval);

        end

 

		%------------------------------------------------------------------
        %% PLOT
		function plot(cobj, varargin)
            % CATALOG/PLOT
			%   Plot a catalog object as event magnitude versus time
			%   plot(cobj) plots magnitude vs. date/time
			%   plot(cobj, 'splitby', 'etype') plots the same, but with each event type in a separate subplot
			%   plot(cobj, 'minmag', 1.0) plots magnitude vs. date/time after filtering out all events smaller than mag=1.0
			%   If cobj is an array of event structures, each will be plotted on a separate figure

			libgt.print_debug(sprintf('> %s', mfilename),2);
			[splitby, minmag] = libgt.process_options(varargin, 'splitby', 'none', 'minmag', -999.0);


			for c = 1 : length(cobj)
				i = find(cobj(c).mag >= minmag);
				figure(gcf+1);

				if strcmp(splitby, 'none')

					plot( cobj(c).dnum(i), cobj(c).mag(i), 'bo' );
					fprintf('Plotting mag vs dnum for %d events',length(i));
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

		%------------------------------------------------------------------
        %% VOLPLOT
		function cobj = volplot(cobj, varargin)
            % CATALOG/VOLPLOT(COBJ)
            %   COBJ.VOLPLOT creates a figure inspired by Guy Tytgat's VOLPLOT layout
            %   Optional name/value pairs are 'nsigma', 'volcano' and
            %   'gridname'.
            
            [nsigma, volcano, gridname] = libgt.process_options(varargin, 'nsigma', '5', 'volcano', '', 'gridname', '');

			% find stations in this region
            sta = db2stations(cobj);

			figure;

			% lon-lat
			axes('position',[0.05 0.45 0.5 0.5]);
			plot(cobj.lon, cobj.lat,'*');
			grid on;
			if ~isempty(sta.lon)
				hold on;
				plot(sta.lon, sta.lat, 'rv');
				text(sta.lon, sta.lat, sta.code);
			end
			axis(gca, cobj.region);
                        
            if ~isempty(volcano)
                %libgt.plotbox(volcano)
            end
            if ~isempty(gridname)
                %libgt.plotbox(gridname)
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
			%latrangeinkm = 111 * (cobj.region(4) - cobj.region(3));
			%lonrangeinkm = 111 * (cobj.region(2) - cobj.region(1)) * cos(mean(  cobj.region(3:4) ));
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

		%% ------------------------------------------------------------------
        %% VOLPLOTDIFF
		function volplotdiff(cobj1, cobj2)
            % CATALOG/VOLPLOTDIFF(COBJ1, COBJ2)
            %   Like CATALOG/VOLPLOT but plots differences between two
            %   catalog objects. Event ids must match for events to be
            %   considered the same event in the two catalog objects.
            %   See also CATALOG/COMPARE  

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
					fprintf('there are %d evids in %s matching evid %d in %s',length(j),cobj2.dbroot,cobj1.evid(i),cobj1.dbroot);
				end
			end
			if ~isempty(sta.lon)
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
				fprintf('Average change in longitude was %.2f km (std: %.2f km)',difflonmean*cos(deg2rad(cobj1.lat(1)))*111.0,difflonstd*cos(deg2rad(cobj1.lat(1)))*111.0);
				fprintf('Average change in latitude was %.2f km (std: %.2f km)',difflatmean*111.0,difflatstd*111.0);
				fprintf('Average change in depth was %.2f km (std: %.2f km)',diffdepthmean,diffdepthstd);
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
				fprintf('Average event moved from %.4f, %.4f, %.2f km to %.4f %.4f %.2f km', lonmean1, latmean1, depthmean1, lonmean2, latmean2, depthmean2);
				fprintf('std in longitude changed from %.2f km to %.2f km',lonstd1,lonstd2);
				fprintf('std in latitude changed from %.2f km to %.2f km',latstd1,latstd2);
				fprintf('std in depth changed from %.2f km to %.2f km',depthstd1,depthstd2);
				fprintf('source volume corresponding to 3d-std changed from %.3f km^3 to %.3f km^3', lonstd1*latstd1*depthstd1, lonstd2*latstd2*depthstd2);
			end
        end
        
        %------------------------------------------------------------------
        %% DB2STATIONS
        function sta = db2stations(cobj)
            % CATALOG/DB2STATIONS(COBJ)
            %   Load Alaska stations within COBJ.REGION
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
                        fprintf('%d stations were found in this cobj1.region',nstations);
                        [stalon, stalat, stacode] = dbgetv(db, 'lon', 'lat', 'sta');
                    end
                end
            end
            sta.lon = stalon; sta.lat = stalat; sta.code = stacode;
        end % function		
        
		%------------------------------------------------------------------
        %% COMPARE
        function [matches, total] = compare(cobj1, cobj2)
            % CATALOG/COMPARE(COBJ1, COBJ2)
            % Compares two catalog objects. Any events from the two
            % catalog objects within 0.2 degrees and 10 seconds of each
            % other are assumed to be alternate origins for the same event.
            % It is these alternate origins that are compared.
            figure;
            hold on;
            xlabel('Mag1');
            ylabel('Mag2');
            matches = 0; total = 0;
            mag_matched = [];
            mag_unmatched = [];
            for c1=1:length(cobj1.evid)
                total = total + 1;
                s = sprintf('Event %d (%d): %s %.3f %.3f %.1f',c1, cobj1.evid(c1), datestr(cobj1.dnum(c1),31), cobj1.lon(c1), cobj1.lat(c1), cobj1.mag(c1));
                x = deg2km(distance(cobj1.lat(c1), cobj1.lon(c1), cobj2.lat, cobj2.lon));
                i = find(x < 20); % within .2 degrees (20 km)
                %s = sprintf('%s\n There are %d events within 0.2 degrees of event %d', s, length(i), c1);
                if ~isempty(i)
                    t = abs(cobj1.dnum(c1) - cobj2.dnum(i));
                    j = find(t * 86400 < 10); % within 10s
                    %s = sprintf('%s: Of these, %d are within 10 seconds', s, length(j));
                    if ~isempty(j)
                        matches = matches + 1;
                        if length(j)==1
                            s = sprintf('%s\n= Event %d (%d): %s %.3f %.3f %.1f',s, i(j), cobj2.evid(i(j)), datestr(cobj2.dnum(i(j)),31), cobj2.lon(i(j)), cobj2.lat(i(j)), cobj2.mag(i(j)));
                            s = sprintf('%s (%.2f km, %.2f s)', s, x(i(j)), t(j));
                            plot(cobj1.mag(c1), cobj2.mag(i(j)), 'o');
                        else
                            s = sprintf('%s. More than 1 match\n',s);
                        end
                        mag_matched = [mag_matched cobj1.mag(c1)];
                    else
                        s = sprintf('%s. No time match',s);
                        mag_unmatched = [mag_unmatched cobj1.mag(c1)];
                    end
                    
                else
                    s = sprintf('%s. No distance match',s);
                    mag_unmatched = [mag_unmatched cobj1.mag(c1)];
                end
                disp(s);
            end
            set(gca, 'XLim', [-1 3], 'YLim', [-1 3]);
            plot([-1 3], [-1 3], ':');
            figure;
            subplot(2,1,1), hist(mag_matched, -1:0.25:3), xlabel('Mag1'),title('Matched events');
            subplot(2,1,2), hist(mag_unmatched, -1:0.25:3),xlabel('Mag1'),title('Unmatched events');
        end
                              
        %------------------------------------------------------------------
		%% PLOTDAILYMAGSTATS
        function plotdailymagstats(cobj)
            % CATALOG/PLOTDAILYMAGSTATS(COBJ)
			% plot the max, mean, min and various percentiles of the magnitude samples each day
			day = floor(cobj.dnum);
            i = find(cobj.mag < -9);
            cobj.mag(i)=NaN;
			c=1;
			time=[];
			for dnum=min(day):max(day)
				i = find(day == dnum);
				if (~isempty(i))
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
			if ~isempty(time)
				plot(time,maxmag,time,p95,time,meanmag,time,med,time,p5,time,minmag);
				ylabel('mag');
				legend('maximum','95th%ile','mean','median','5th%ile','minimum');
				datetick('x');
				%plot(time,stdev);
				%dateticklabel('x');
				%title('standard deviation in mag');ylabel('mag');
			end
		end
		
        %------------------------------------------------------------------
        %% PLOTMAGDIFF
        function plotmagdiff(cobj1, cobj2)
            % CATALOG/PLOTMAGDIFF
            %  Plot the difference in magnitude for events with identical
            %  event id.
            %  See also CATALOG/VOLPLOTDIFF.
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
            fprintf('Change: mean=%.1f, median=%.1f, std=%.1f, max=%.1f',mean(diff),median(diff),std(diff),max(diff));
        end
        
        %------------------------------------------------------------------
        %% PLOTBVALUE         
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
        
        %------------------------------------------------------------------
        %% MAPEXAMPLE
        function mapexample(cobj)
            % simple epicentral plot
            figure;
            close all
            h = worldmap([latmin latmax],[lonmin lonmax]);
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

            plotm(cobj.lat, cobj.lon, '*');
        end
        
        %------------------------------------------------------------------
        %% PLOTSTATIONS
        function plotstations(cobj)
            % CATALOG/PLOTSTATIONS(COBJ)
            %   Superimpose the stations within the cobj.region property on
            %   a figure. Note this isn't designed to work if cobj.region
            %   is not set.
            sta = db2stations(cobj);
			if ~isempty(sta.lon)
				hold on;
				plot(sta.lon, sta.lat, 'bv');
				text(sta.lon, sta.lat, sta.code);
			end
			axis(gca, cobj.region);
        end
        
        %------------------------------------------------------------------
        %% addArrivals
        function cobj = addArrivals(cobj)
            % CATALOG/ADDARRIVALS(COBJ) Populate the arrival property of a catalog object.
            %   cobj = cobj.addArrivals()
            %   WARNING: This can take a long time to run for big catalogs!
            %   The arrival field is a cell array with one element per
            %   origin in the catalog.
            %   Each element of the arrival field cell array is a structure
            %   with fields:
            %       station = station names with picks for this origin
            %       channel = channel names with picks for this origin
            %       arid = arrival ids
            %       atime = arrival times
            %       iphase = arrival phase name (e.g. 'P', 'S') 
            %       orid = the origin id this arrival element belongs to
                subset_expr = cobj.get('dbeval')
                if length(subset_expr) > 1                   
                    arrivalStruct = toArrivals(cobj, subset_expr);  
                else
                    arrivalStruct = toArrivals(cobj);
                end
                arrival ={};
                for c=1:length(cobj.orid)
                    thisorid = cobj.orid(c);
                    i = find(arrivalStruct.orid==thisorid);
                    l = length(i);
                    if l>0
                        arrival{c}.station = {arrivalStruct.sta{i}};
                        arrival{c}.channel = {arrivalStruct.chan{i}};
                        arrival{c}.arid = arrivalStruct.arid(i);
                        arrival{c}.atime = arrivalStruct.atime(i);
                        arrival{c}.iphase = {arrivalStruct.iphase{i}};
                        arrival{c}.orid = arrivalStruct.orid(i(1));
                    end
                end
                cobj.arrival = arrival;
        end
        

                
        %------------------------------------------------------------------
        %% toArrivals
        function arrival = toArrivals(cobj, subset_expr)
            % CATALOG/TOARRIVALS(COBJ, SUBSET_EXPR)
            % GET ARRIVALS CORRESPONDING TO A CATALOG OBJECT
            arrival.sta = {};
            arrival.chan = {};
            arrival.atime   = [];
            arrival.otime = [];
            arrival.orid = [];
            arrival.arid = [];
            arrival.etype = {};
            arrival.stype = {};
            arrival.seaz = [];
            arrival.unique_orids = [];
            arrival.iphase = {};

			libgt.print_debug(sprintf('archive format is %s',cobj.archiveformat),3);

			if strcmp(cobj.archiveformat,'')
				dbname = cobj.dbroot;
				if exist(sprintf('%s.arrival',dbname),'file')
					if exist('subset_expr', 'var')
                        arrival = load_arrivals(dbname, subset_expr);
                    else
                        arrival = load_arrivals(dbname); 
                    end
				else
					fprintf('%s.arrival not found\n',dbname);
				end
			else
				if strcmp(cobj.archiveformat,'daily')
      
					for dnum=floor(cobj.snum):floor(cobj.enum-1/1440)
						dbname = sprintf('%s_%s',cobj.dbroot,datestr(dnum, 'yyyy_mm_dd'));
						if exist(sprintf('%s.arrival',dbname),'file')
                            if exist('subset_expr', 'var')
                                a = load_arrivals(dbname, subset_expr);
                            else
                                a = load_arrivals(dbname); 
                            end
                            arrival.sta = cat(1,arrival.sta,  a.sta);
                            arrival.chan = cat(1,arrival.chan,  a.chan);
							arrival.atime   = cat(1,arrival.atime, a.atime);
                            arrival.otime   = cat(1,arrival.otime, a.otime);
                            arrival.orid   = cat(1,arrival.orid, a.orid);
                            arrival.arid   = cat(1,arrival.arid, a.arid);
							arrival.stype  = cat(1,arrival.stype,  a.stype);
							arrival.etype  = cat(1,arrival.etype,  a.etype);
							arrival.seaz  = cat(1,arrival.seaz,  a.seaz);
                            arrival.unique_orids  = cat(1,arrival.unique_orids,  a.unique_orids);
                            arrival.iphase = cat(1,arrival.iphase,  a.iphase);                            
						else
							fprintf('%s.arrival not found\n',dbname);
						end
					end
				else

					for yyyy=dnum2year(cobj.snum):1:dnum2year(cobj.enum)
						for mm=dnum2month(cobj.snum):1:dnum2month(cobj.enum)
							dnum = datenum(yyyy,mm,1);
							dbname = sprintf('%s%04d_%02d',cobj.dbroot,yyyy,mm);
							if exist(sprintf('%s.arrival',dbname),'file')
                                if exist('subset_expr', 'var')
                                    a = load_arrivals(dbname, subset_expr);
                                else
                                    a = load_arrivals(dbname); 
                                end

                                arrival.sta = cat(1,arrival.sta,  a.sta);
                                arrival.chan = cat(1,arrival.chan,  a.chan);
                                arrival.atime   = cat(1,arrival.atime, a.atime);
                                arrival.otime   = cat(1,arrival.otime, a.otime);
                                arrival.orid   = cat(1,arrival.orid, a.orid);
                                arrival.arid   = cat(1,arrival.arid, a.arid);
                                arrival.stype  = cat(1,arrival.stype,  a.stype);
                                arrival.etype  = cat(1,arrival.etype,  a.etype);
                                arrival.seaz  = cat(1,arrival.seaz,  a.seaz);
                                arrival.unique_orids  = cat(1,arrival.unique_orids,  a.unique_orids);
                                arrival.iphase = cat(1,arrival.iphase,  a.iphase);
                            else
                                fprintf('%s.arrival not found\n',dbname);
                            end        
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        %% toWaveforms
        function toWaveforms(cobj, subset_expr)
            % CATALOG/TOWAVEFORMS(COBJ, SUBSET_EXPR)
            if exist('subset_expr', 'var')
                arrival = toArrivals(cobj, subset_expr);
            else
                arrival = toArrivals(cobj);      
            end
            [sta_index, orid_index, eqtimes, eqindices, nstations, norigins] = arrivals_rearrange(arrivals, arrivals.sta);
            eqwf = arrival2waveform(arrivals, norigins, nstations, chanlist);
        end
        
        %------------------------------------------------------------------
        %% ADDFIELD
        function cobj = addfield(cobj,fieldname,value)
            %ADDFIELD add fields and values to CATALOG object(s) 
            %   cobj = addfield(cobj, fieldname, value)
            %   This function creates a new user defined field, and fills it with the
            %   included value.  If fieldname exists, it will overwrite the existing
            %   value.
            %
            %   Input Arguments
            %       COBJ: a catalog object   N-DIMENSIONAL
            %       FIELDNAME: a string name
            %       VALUE: a value to be added for those fields.  Value can be anything
            %
            %   CATALOG objects can hold user-defined fields.  To access the contents, 
            %   use catalog/get.
            %
            %   Example:
            %       cobj = catalog(); %start with a blank catalog object.
            %       N = 1:45;     %create a variable containing the numbers 1-45
            %       S = 'Thursday'; %create a string variable
            %       C = {'first', 'second', N, S}; % create a cell aray with a variety
            %                                               % of data
            %
            %       % add a field called "TESTFIELD", containing the numbers 1-45
            %       cobj = addfield(cobj,'TestField',N);
            %
            %       % add another field called "MISHMOSH" containing the cell 'C'
            %       cobj = addfield(cobj,'mishmosh',C);
            %
            %       % see the result
            %       disp(cobj) 
            %
            % See also CATALOG/SET, CATALOG/GET, WAVEFORM/ADDFIELD

            % AUTHOR: Glenn Thompson, based entirely on WAVEFORM/ADDFIELD by
            % Celso Reyes
            % $Date: $
            % $Revision: $

            if isa(fieldname,'char')
                fieldname = {upper(fieldname)}; %convert to cell
            else
                error('catalog:addfield:invalidFieldname','fieldname must be a string')
            end

            actualfields = upper(fieldnames(cobj)); %get the object's intrinsic fieldnames

            if ismember(fieldname,actualfields)
                cobj = set(cobj, fieldname{1}, value); %set the value of the actual field
                warning('catalog:addfield:fieldExists',...
                    'Attempted to add intrinsic field.\nNo field added, but Values changed anyway');
                return
            end

            % Fieldname isn't one that is intrinsic to the catalog object

            for n=1:numel(cobj)                
                miscF = cobj(n).misc_fields;   % grab the misc_fields (cell of fieldnames)
  
                if ~any(strcmp(fieldname,miscF)) % if the field doesn't already exist...
                    cobj(n).misc_fields = [miscF, fieldname]; %add the fieldname to the list
                end
                cobj(n) = set(cobj(n), fieldname{1},value);
            end
        end
    
        %------------------------------------------------------------------    
        %% SET
        function cobj = set(cobj, varargin)
        %SET Set properties for catalog object(s)
        %   cobj = set(cobj,'property_name', val, ['property_name2', val2])
        %   SET is one of the two gateway functions of an object, such as catalog.
        %   Properties that are changed through SET are typechecked and otherwise
        %   scrutinized before being stored within the catalog object.  This
        %   ensures that the other waveform methods are all retrieving valid data,
        %   thereby increasing the reliability of the code.
        %
        %   Another strong advantage to using SET and GET to change  and retrieve
        %   properties, rather than just assigning them to catalog object directly,
        %   is that the underlying data structure can change and grow without
        %   harming the code that is written based on the catalog object.
        %
        %   Valid property names:
        %
        %       'LON'	- longitude
		%       'LAT'	- latitude
		%       'DEPTH' - in km (-ve is above sea level, +ve below)
		%       'DNUM'  - Vector of MATLAB datenum times denoting origin
		%       times
		%       'NASS' - number of associated arrivals
		%       'EVID' - event id
        %       'ORID' - origin id
		%       'MAG' - magnitude
		%       'ETYPE' - event classification/type
        %       'SNUM' - start time of catalog in MATLAB datenum* format
        %       'ENUM' - end time of catalog
        %       'MINMAG' - magnitude threshold of catalog (events with
        %       smaller magnitude are/have been filtered out)
        %       'AUTH' - Name of the person, algorithm or method that
        %       created/classified/located the event.
        %       'REGION' - A vector of [MINLON MAXLON MINLAT MAXLAT]
        %   
        %       If user-defined fields were added to the catalog object (ie, through
        %       addField), these fieldnames are also available through set.
        %
        %       for example
        %           % create a catalog object, and add a field called CLOSEST_STATION with
        %           % the value 'MBLG'
        %           cobj = addfield(catalog,'CLOSEST_STATION','MBLG');
        %
        %           % change the value of the CLOSEST_STATION field to 'MBWH'
        %           cobj = set(cobj,'CLOSEST_STATION','MBWH');
        %
        %           % change the event type to 'h' (for hybrid) and
        %           magnitude to 2.3:
        %           cobj = set(cobj,'etype','h', 'mag', 2.3);
        %
        %   Batch changes can be made if input cobj is a matrix (use with care!)
        %
        %  See also CATALOG/GET, WAVEFORM/SET

        % AUTHOR: Glenn Thompson
        % LASTUPDATE: September 26, 2011

        Vidx = 1 : numel(varargin);

        while numel(Vidx) >= 2
            prop_name = upper(varargin{Vidx(1)});
            val = varargin{Vidx(2)};
  
            switch prop_name
            
                % LON
                case 'LON',
                if isa(val,'double')
                    if (val>=-180.0 & val<=180.0)
                        [cobj.lon] = deal(val);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from -180.0 to 180.0');
                    end
                end
            
                % LAT
                case 'LAT',
                if isa(val,'double')
                    if (val>=-90.0 & val<=90.0)
                        [cobj.lat] = deal(val);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from -90.0 to 90.0');
                    end
                end    
            
                % DEPTH
                case 'DEPTH',
                if isa(val,'double')
                    if (val>=-13.0 & val<=999.0)
                        [cobj.depth] = deal(val);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from -13.0 to 999.0');
                    end
                end            
            
            
                % DNUM
                case 'DNUM',
                if isa(val,'double')
                    if (val>=datenum(1900,1,1) & val<=datenum(2030,1,1))
                        [cobj.dnum] = deal(val);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',datenum(1900,1,1),datenum(2030,1,1));
                    end
                end  
                        
                % NASS
                case 'NASS',
                if isa(val,'double') || isinteger(val)
                    if (val>=0 & val<=999)
                        [cobj.nass] = deal(int16(val));
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected an INTEGER from 0 to 999');
                    end
                end    
            
                        
                % EVID
                case 'EVID',
                if isa(val,'double') || isinteger(val)
                    if (val>=0 & val<=2^32)
                        [cobj.evid] = deal(int32(val));
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected an INTEGER from 0 to %f',2^32);
                    end
                end  
            
                % ORID
                case 'ORID',
                if isa(val,'double') || isinteger(val)
                    if (val>=0 & val<=2^32)
                        [cobj.orid] = deal(int32(val));
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected an INTEGER from 0 to %f',2^32);
                    end
                end  
                                                
                % MAG
                case 'MAG',
                if isa(val,'double') 
                    if (val>=-2.0 & val<=9.9)
                        [cobj.mag] = deal(val);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from -2.0 to 9.9');
                    end
                end  
            
                                                
                % ETYPE
                case 'ETYPE',
                if isa(val,'char') 
                    %if (length(val)==1)
                        [cobj.etype] = deal(val);
                    %else
                    %    error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from -2.0 to 9.9');
                    %end
                end  
            
            
                % SNUM - results in data being filtered
                case 'SNUM',
                if isa(val,'double')
                    if (val>=cobj.snum & val<cobj.enum)
                        [cobj.snum] = deal(val);
                        % cobj = filterdata(cobj, 'snum', cobj.snum);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',cobj.snum,cobj.enum);
                    end
                end       
            
            
                % ENUM - results in data being filtered
                case 'ENUM',
                if isa(val,'double')
                    if (val>cobj.snum & val<=cobj.enum)
                        [cobj.enum] = deal(val);
                        % cobj = filterdata(cobj, 'enum', cobj.enum);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',cobj.snum,cobj.enum);
                    end
                end    
            
            
                % MINMAG - results in data being filtered
                case 'MINMAG',
                if isa(val,'double')
                    if (val>cobj.minmag & val<=9.9)
                        [cobj.minmag] = deal(val);
                        % cobj = filterdata(cobj, 'minmag', cobj.minmag);
                    else
                        error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',cobj.minmag,9.9);
                    end
                end               
            
                % AUTH
                case 'AUTH',
                if isa(val,'cell')
                    %if (val>cobj.minmag && val<=9.9)
                        [cobj.auth] = deal(val);
                    %else
                    %    error('CATALOG:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',cobj.minmag,9.9);
                    %end
                end  
            
                % REGION
                case 'REGION',
                if isa(val,'double')
                    if (length(val)==4)
                        if (  (val(1)>=cobj.region(1)) & (val(2)<=cobj.region(2)) & (val(3)>=cobj.region(3)) & (val(4)<=cobj.region(4)) )
                            [cobj.region] = deal(val);
                        else
                            error('CATALOG:set:propertyTypeMismatch','REGION must be a subset of existing region');
                        end
                    end
                end            
           
      
                otherwise
                    for n=1:numel(cobj)
                        switch prop_name
                            case cobj(n).misc_fields
                                %mask = ismember(cobj(n).misc_fields, prop_name);
                                mask = strcmp(prop_name,cobj(n).misc_fields);
                                cobj(n).misc_values(mask) = {val};
                            otherwise
                                error('CATALOG:set:unknownProperty',...
                                    'can''t understand property name : %s', prop_name);
                        end %switch
                    end %n
            end %switch
  
            Vidx(1:2) = []; %done with those parameters, move to the next ones...
        end % while loop
        end % function
        
        %------------------------------------------------------------------
        %% GET
        function val = get(cobj,prop_name)
            %GET Get catalog properties
            %   val = get(catalog_object,'property_name')
            %
            %   Valid property names:
            %       'LON'	- longitude
            %       'LAT'	- latitude
            %       'DEPTH' - in km (-ve is above sea level, +ve below)
            %       'DNUM'  - Vector of MATLAB datenum times denoting origin
            %       times
            %       'NASS' - number of associated arrivals
            %       'EVID' - event id
            %       'ORID' - origin id
            %       'MAG' - magnitude
            %       'ETYPE' - event classification/type
            %       'SNUM' - start time of catalog in MATLAB datenum* format
            %       'ENUM' - end time of catalog
            %       'MINMAG' - magnitude threshold of catalog (events with
            %       smaller magnitude are/have been filtered out)
            %       'AUTH' - Name of the person, algorithm or method that
            %       created/classified/located the event.
            %       'REGION' - A vector of [MINLON MAXLON MINLAT MAXLAT]
            %       
            %
            %   If catalog_object is N-dimensional, then VAL will be a cell of the same
            %   dimensions.  If GET would return single-values for the property, then
            %   VAL will be a matrix of type DOUBLE, arranged in the same dimensions.
            %
            %       If additional fields were added to catalog using ADDFIELD, then
            %       values from these can be retrieved using the fieldname
            %
            %       Example: Create a catalog, get 'LON', add a field, then get the field
            %           cobj = catalog;
            %           cobj = get(cobj, 'LON')
            %           cobj = addfield(cobj,'closest_station', 'MBLG');
            %           cs = get(cobj,'closest_station'); 
            %
            %   See also CATALOG/SET, CATALOG/ADDFIELD, WAVEFORM/GET

            % AUTHOR: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks
            % $Date: $
            % $Revision: $

            prop_name = upper(prop_name);
            switch prop_name
                
                case 'LON', val=cobj.lon;
                case 'LAT', val=cobj.lat;
                case 'DEPTH', val=cobj.depth;
                case 'DNUM', val=cobj.dnum;
                case 'NASS', val=cobj.nass;
                case 'EVID', val=cobj.evid;
                case 'ORID', val=cobj.orid;
                case 'MAG', val=cobj.mag;
                case 'ETYPE', val=cobj.etype;                    
                case 'SNUM', val=cobj.snum;
                case 'ENUM', val=cobj.enum;
                case 'MINMAG', val=cobj.minmag;
                case 'AUTH', val=cobj.auth;    
                case 'REGION', val=cobj.region;

                otherwise
                    %perhaps we're trying to get at one of the miscelleneous fields?
                    val = cell(size(cobj));
                    for n = 1 : numel(cobj)
                        %loc is the position...
                        %w(n).misc_fields should ALWAYS already be in uppercase
                        mask = strcmp(prop_name,cobj(n).misc_fields);
                        %fieldwasfound = any(mask);
                        %[fieldwasfound, loc] = ismember(prop_name, cobj(n).misc_fields);
                        if any(mask)
                
                            val{n} = cobj(n).misc_values{mask};
                            %val{n} = cobj(n).misc_values{m};
                        else
                            warning('CATALOG:get:unrecognizedProperty',...
                                'Unrecognized property name : %s',  prop_name);
                        end
                    end
        
                    %check to see if value can be returned as a numeric value instead
                    %of cell.  Only if all values are numeric AND scalar
                    numberize = true;
                    for n=1:numel(val)
                        if ~(isnumeric(val{n}) && isscalar(val{n}))
                            numberize = false;
                            usedcell = true;
                            break
                        end
                    end
                    if numberize,
                        Z = val;
                        val = nan(size(Z));
                        for n=1:numel(Z)
                            val(n) = Z{n};
                        end
                    end
        
            end % switch
            if (numel(val) == numel(cobj)) 
                val = reshape(val,size(cobj)); %return values in proper shape
            end

        end % function

        function equal=eq(cobj1, cobj2)
            equal = true;
            if ((cobj1.lon ~= cobj2.lon) | (cobj1.lat ~= cobj2.lat) | (cobj1.depth ~= cobj2.depth) | (cobj1.mag ~= cobj2.mag))
                equal = false;
            end
        end
    end % methods
    
    %% STATIC METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods(Static)
        
        %------------------------------------------------------------------
        %% TEST
        function test()
        % TEST
        %   A basic test suite to ensure CATALOG still works following
        %   updates

           libgt.test_helper('cobj = catalog');
           
           dirname = fileparts(which('catalog')); 
           dbroot = [dirname,'/demo/avodb200903']; 

           str = sprintf('cobj = catalog(''%s'', ''antelope'', ''snum'', datenum(2009,3,20), ''enum'', datenum(2009,3,23), ''region'', ''Redoubt'')',dbroot)
           libgt.test_helper(str);
           
           dbeval_expr = 'time > "2009/03/20" && time < "2009/03/23" && distance(lat, lon, 60.5, -152.6) < 0.2';
           str = sprintf('cobj = catalog(''%s'', ''antelope'', ''dbeval'', ''%s'')',dbroot, dbeval_expr);
           libgt.test_helper(str);
           
           str = 'cobj = catalog(''/avort/oprun/events/earthworm/events_earthworm'', ''antelope'' )';
           libgt.test_helper(str);
           
           str = sprintf('cobj = catalog(''/avort/oprun/events/earthworm/events_earthworm'', ''antelope'', ''dbeval'', ''time > %f'' )', datenum2epoch(now-7));
           libgt.test_helper(str);
         end
		%------------------------------------------------------------------
        %% CSS_IMPORT
		function [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = css_import(dbname, dbeval)
            % CSS_IMPORT Load event data object from CSS3.0 event database
            %   [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = css_import(dbname, dbeval)
            %
			%   INPUT:
            %     dbname = path to database
            %     dbeval = a dbeval expression. This can be '' if no
            %     subsetting is desired.
            %
			% 
			%   Example: Import all events from the demo database
            %     dirname = fileparts(which('catalog')); % get the path to the catalog directory
            %     dbroot = [dirname,'/demo/avodb200903']; 
            %     [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = css_import(dbroot, '')

			numorigins = 0;
            [lat, lon, depth, dnum, time, evid, orid, nass, mag, ml, mb, ms, etype, auth] = deal([]);
            auth = {};

			libgt.print_debug(sprintf('Loading data from %s',dbname),3);
          
            ORIGIN_TABLE_PRESENT = libgt.dbtable_present(dbname, 'origin');
            EVENT_TABLE_PRESENT = libgt.dbtable_present(dbname, 'event');           
            if (ORIGIN_TABLE_PRESENT)
                db = dblookup_table(dbopen(dbname, 'r'), 'origin');
                numorigins = dbquery(db,'dbRECORD_COUNT');
                libgt.print_debug(sprintf('Got %d records from %s.origin',numorigins,dbname),1);
                if numorigins > 0
                    if (EVENT_TABLE_PRESENT)
                        db = dbjoin(db, dblookup_table(db, 'event') );
                        numorigins = dbquery(db,'dbRECORD_COUNT');
                        if numorigins > 0
                            db = dbsubset(db, 'orid == prefor');
                            numorigins = dbquery(db,'dbRECORD_COUNT');
                            libgt.print_debug(sprintf('Got %d records after joining event with %s.origin',numorigins,dbname),1);
                            if numorigins > 0
                                db = dbsort(db, 'time');
                            else
                                return
                            end
                        else
                            return
                        end
                    end
                else
                    return
                end
            else
                return
            end

			numorigins = dbquery(db,'dbRECORD_COUNT');
			libgt.print_debug(sprintf('Got %d prefors prior to subsetting',numorigins),2);
	
			% Do the subsetting
            if ~isempty(dbeval)
                db = dbsubset(db, dbeval);
                numorigins = dbquery(db,'dbRECORD_COUNT');
                libgt.print_debug(sprintf('Got %d prefors after subsetting',numorigins),2);
			end

			if numorigins>0
                if EVENT_TABLE_PRESENT
                    [lat, lon, depth, time, evid, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'evid', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');
                else
                    [lat, lon, depth, time, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');  
                    disp('No event table. Setting evid == orid');
                    evid = orid;
                end
                etype0 = dbgetv(db,'etype');
     
 			   	if isempty(etype0)
			        	etype = char(ones(numorigins,1)*'R');
			    else
  			     	% convert etypes
					etype0=char(etype0);
					etype(etype0=='a')='t';
                    etype(etype0=='b')='l';
                    etype(etype0=='-')='u';
                    etype(etype0==' ')='u';
                end
                etype = char(etype); % sometimes etype gets converted to ASCII numbers

				% get mag
				mag = max([ml mb ms], [], 2);

 			   	% convert time from epoch to Matlab datenumber
				dnum = epoch2datenum(time);

            end

	
			% close database
			dbclose(db);
        end
    end % methods
  
    
    %% PRIVATE METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access=private)
        
        %% CSS_LOAD
        function cobj = css_load(cobj, dbroot, archiveformat, dbeval)
            
			if ~exist('minmag','var')
				minmag = -999.0;
			end

			if strcmp(archiveformat,'')
				dbname = dbroot;
				if exist(sprintf('%s.origin',dbname),'file')
					[cobj.lon, cobj.lat, cobj.depth, cobj.dnum, cobj.evid, cobj.orid, cobj.nass, cobj.mag, cobj.mb, cobj.ml, cobj.ms, cobj.etype, cobj.auth] = catalog.css_import(dbname, dbeval);                  
				else
					fprintf('%s.origin not found\n',dbname);
				end
			else
				if strcmp(archiveformat,'daily')
      
					for dnum=floor(cobj.snum):floor(cobj.enum-1/1440)
						dbname = sprintf('%s_%s',dbroot,datestr(dnum, 'yyyy_mm_dd'));
						if exist(sprintf('%s.origin',dbname),'file')
							[lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = catalog.css_import(dbname, dbeval);
							cobj.lon   = cat(1,cobj.lon,   lon);
							cobj.lat   = cat(1,cobj.lat,   lat);
							cobj.depth = cat(1,cobj.depth, depth);
							cobj.dnum  = cat(1,cobj.dnum,  dnum);
							cobj.evid  = cat(1,cobj.evid,  evid);
                            cobj.orid  = cat(1,cobj.orid,  orid);
							cobj.nass  = cat(1,cobj.nass,  nass);
							cobj.mag   = cat(1,cobj.mag,   mag);
                            cobj.mb   = cat(1,cobj.mb,   mb);
                            cobj.ml   = cat(1,cobj.ml,   ml);
                            cobj.ms   = cat(1,cobj.ms,   ms);
							cobj.etype  = cat(2,cobj.etype,  etype);
                            cobj.auth = cat(1, cobj.auth, auth);
						else
							fprintf('%s.origin not found\n',dbname);
						end
					end
				else

					for yyyy=dnum2year(cobj.snum):1:dnum2year(cobj.enum)
						for mm=dnum2month(cobj.snum):1:dnum2month(cobj.enum)
							dnum = datenum(yyyy,mm,1);
							dbname = sprintf('%s%04d_%02d',dbroot,yyyy,mm);
							if exist(sprintf('%s.origin',dbname),'file')
								[lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = catalog.css_import(dbname, dbeval);
								cobj.lon   = cat(1,cobj.lon,   lon);
								cobj.lat   = cat(1,cobj.lat,   lat);
								cobj.depth = cat(1,cobj.depth, depth);
								cobj.dnum  = cat(1,cobj.dnum,  dnum);
								cobj.evid  = cat(1,cobj.evid,  evid);
 								cobj.orid  = cat(1,cobj.orid,  orid);
								cobj.nass  = cat(1,cobj.nass,  nass);
								cobj.mag   = cat(1,cobj.mag,   mag);
                                cobj.mb   = cat(1,cobj.mb,   mb);
                                cobj.ml   = cat(1,cobj.ml,   ml);
                                cobj.ms   = cat(1,cobj.ms,   ms);
								cobj.etype  = cat(1,cobj.etype,  etype);
                                cobj.auth = cat(1, cobj.auth, auth);
							else
								fprintf('%s.origin not found\n',dbname);
							end
						end
					end
				end
			end

        end % function


   end % private methods
end

