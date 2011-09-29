classdef catalog
%
% CATALOG Seismic Catalog class constructor, version 1.0.
% 
%    CATALOG is a class that for loading, manipulating and saving earthquake
%    catalogs.
%
%    CATALOG imports catalog information from:
%    (1) a CSS3.0 database - the default format used by Antelope/Datascope.
%    (2) a Datascope database written in the "swarms1.0" schema, defined at AVO. 
%        This is the format used by the swarm tracking system.
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
%%   STATIC METHODS (should probably be in libgt instead!)
%    plotgrid(gridname):   - superimpose a detection grid (requires a grids 
%                            database saved in places1.0 Datascope schema)  
%    plotbox(volcano):     - superimpose the region 
%
%%   CREATING A BLANK CATALOG
%    COBJ = CATALOG() creates an empty catalog object.
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
%          cobj = catalog(datenum(2009,3,20),datenum(2009,3,23),[],'Redoubt',dbroot,'')
%
%      (2) Create a catalog object of all AEIC events greater than M=4.0 in 2009 from the region latitude = 55.0 to 65.0, longitude = -170.0 to -135.0
%          cobj = catalog(datenum(2009,1,1), datenum(2010,1,1), 4.0, [-170.0 -135.0 55.0 65.0] , '/Seis/catalogs/aeic/Total/Total', '');
%
%      (3) Create a catalog object of all AEIC events greater than M=1.0 in August 2011 from the region latitude = 55.0 to 65.0, longitude = -170.0 to -135.0
%          but this time, using the daily summary databases.
%          cobj = catalog(datenum(2011,8,1), datenum(2011,9,1), 1.0, [-170.0 -135.0 55.0 65.0] , '/aerun/sum/run/dbsum/Quakes', 'daily');
%
%      (4) Create a catalog object of all events (regardless of magnitude) in the last 3 days of data from Redoubt:
%          cobj = catalog(libgt.utnow-3, libgt.utnow, [], 'redoubt', '/avort/oprun/events/antelope/events_antelope', '');
%
%      (5) Create a catalog object of all events recorded at Spurr between 1989 and 2006:
%          cobj = catalog(datenum(1989,1,1), datenum(2006,1,1), [], 'spurr', '/Seis/Kiska4/picks/Total/Total', '');
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
		mag	= []; % magnitude
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
    end
    
    %% METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	methods
        
     	%------------------------------------------------------------------
        %% Constructor.    
        function cobj = catalog(varargin)
            % CATALOG constructor. HELP CATALOG for information.
            switch nargin
                case {5, 6, 7}, cobj = cobj.css2catalog(varargin{:});
                case 10, cobj.css_load(varargin{:});
                case 11, cobj.css_import(varargin{:});
                otherwise, disp('Number of input arguments to constructor not recognized');
            end        
        end

		%------------------------------------------------------------------
        %% CSS2CATALOG
        function cobj = css2catalog(cobj, snum, enum, magthresh, region, db, archiveformat, subclass) % 5 or 6 arguments
            % CSS2CATALOG Load catalog object from CSS3.0 database
            %
			%   PARAMETERS:  
			%     snum = start time/date in datenumber format  
			%     enum = end time/date in datenumber format  
			%     minmag will cut out events smaller than this magnitude  
			%     region - examples are 'redoubt', 'spurr' and 'alaska' (defined in avo_volcs.pf) 
			%     Alternatively region can be a 4-element vector like: [leftlon rightlon lowerlat upperlat].
			%     dbroot - path of the database (root path to a monthly or daily database)
			%     archiveformat	- leave blank if its a normal database, otherwise 'daily' for a daily archive, 'monthly' for a monthly archive
            %     subclass - event tyoe/subclassification e.g.'*'=all,
            %     'l'=long period, 'h'=hybrid, 't'=tectonic, 'r'=rockfall. 
			% 
			%   Example:
            %     dirname = fileparts(which('catalog')); % get the path to the catalog directory
            %     dbroot = [dirname,'/demo/avodb200903']; 
            %     cobj = catalog;
            %     cobj = cobj.css2catalog(datenum(2009,3,20),datenum(2009,3,23),[],'Redoubt',dbroot,'')
			%
			%   Author: Glenn Thompson, 2002-2009
  
			if ~antelope_exists
				disp('Antelope not found');
			end
            
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

 

		%------------------------------------------------------------------
        %% PLOT
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

			% plot the max, mean, min and various percentiles of the magnitude samples each day
			day = floor(cobj.dnum);
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
            % SUPERIMPOSE STATIONS ON A MAP
            sta = db2stations(cobj);
			if ~isempty(sta.lon)
				hold on;
				plot(sta.lon, sta.lat, 'bv');
				text(sta.lon, sta.lat, sta.code);
			end
			axis(gca, cobj.region);
        end
        
        %------------------------------------------------------------------
        %% toArrivals
        function arrival = toArrivals(cobj, subset_expr)
            % GET ARRIVALS CORRESPONDING TO A CATALOG OBJECT
            arrival.sta = {};
            arrival.atime   = [];
            arrival.otime = [];
            arrival.orid = [];
            arrival.etype = {};
            arrival.stype = {};
            arrival.seaz = [];
            arrival.unique_orids = [];

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
      
					for dnum=floor(snum):floor(enum-1/1440)
						dbname = sprintf('%s_%s',cobj.dbroot,datestr(dnum, 'yyyy_mm_dd'));
						if exist(sprintf('%s.arrival',dbname),'file')
                            if exist('subset_expr', 'var')
                                a = load_arrivals(dbname, subset_expr);
                            else
                                a = load_arrivals(dbname); 
                            end
                            arrival.sta = cat(2,cobj.sta,  a.sta);
							arrival.atime   = cat(1,arrival.atime, a.atime);
                            arrival.otime   = cat(1,arrival.otime, a.otime);
                            arrival.orid   = cat(1,arrival.orid, a.orid);
							arrival.stype  = cat(2,cobj.stype,  a.stype);
							arrival.etype  = cat(2,cobj.etype,  a.etype);
							arrival.seaz  = cat(1,cobj.seaz,  a.seaz);
                            arrival.unique_orids  = cat(1,cobj.unique_orids,  a.unique_orids);
						else
							fprintf('%s.arrival not found\n',dbname);
						end
					end
				else

					for yyyy=dnum2year(snum):1:dnum2year(enum)
						for mm=dnum2month(snum):1:dnum2month(enum)
							dnum = datenum(yyyy,mm,1);
							dbname = sprintf('%s%04d_%02d',cobj.dbroot,yyyy,mm);
							if exist(sprintf('%s.arrival',dbname),'file')
                                if exist('subset_expr', 'var')
                                    a = load_arrivals(dbname, subset_expr);
                                else
                                    a = load_arrivals(dbname); 
                                end
                                arrival.sta = cat(2,cobj.sta,  a.sta);
                                arrival.atime   = cat(1,arrival.atime, a.atime);
                                arrival.otime   = cat(1,arrival.otime, a.otime);
                                arrival.orid   = cat(1,arrival.orid, a.orid);
                                arrival.stype  = cat(2,cobj.stype,  a.stype);
                                arrival.etype  = cat(2,cobj.etype,  a.etype);
                                arrival.seaz  = cat(1,cobj.seaz,  a.seaz);
                                arrival.unique_orids  = cat(1,cobj.unique_orids,  a.unique_orids);
                            else
                                fprintf('%s.arrival not found\n',dbname);
                            end        
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        %% toWaveform
        function toWaveforms(cobj, subset_expr)
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

            actualfields = upper(fieldnames(catalog(1))); %get the object's intrinsic fieldnames

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
                                mask = strcmp(prop_name,cobj(n).misc_fields)
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


    end % methods
    
    %% STATIC METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods(Static)
        
        %% PLOTGRID
        function plotgrid(gridname)
            [region, source, lon, lat] = readavogrids(gridname);
			if length(region) > 0
				hold on;
				plot(source.lon, source.lat, 'b^');
                plot([min(lon) max(lon) max(lon) min(lon) min(lon)], [min(lat) min(lat) max(lat) max(lat) min(lat)], '-');
                %axis(gca, region);
			end
        end        
        
        %------------------------------------------------------------------
        %% PLOTBOX
        function plotbox(volcano)
            [sourcelon, sourcelat, minlon, maxlon, minlat, maxlat] = libgt.readavovolcs(volcano);
            hold on;
            plot(sourcelon, sourcelat, 'r^');
            text(sourcelon, sourcelat, volcano);
            plot([minlon maxlon maxlon minlon minlon], [minlat minlat maxlat maxlat minlat], '-');
        end
        
        %------------------------------------------------------------------
        %% TEST
        function test()
        % TEST
        %   A basic test suite to ensure CATALOG still works following
        %   updates

           libgt.test_helper('cobj = catalog');
           
           dirname = fileparts(which('catalog')); 
           dbroot = [dirname,'/demo/avodb200903']; 

           str = sprintf('cobj = catalog(datenum(2009,3,20),datenum(2009,3,23),[],''Redoubt'',''%s'','''')',dbroot);
           libgt.test_helper(str);
           
         end

    end % methods
  
    
    %% PRIVATE METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access=private)
        
        %% CSS_LOAD
		function cobj = css_load(cobj, dbroot,archiveformat,snum,enum,leftlon,rightlon,lowerlat,upperlat,minz,maxz,minmag)
            % CSS_LOAD Load catalog object from CSS3.0 database
            %
			%   PARAMETERS:  
			%     snum = start time/date in datenumber format  
			%     enum = end time/date in datenumber format  
			%     minmag will cut out events smaller than this magnitude  
			%     region - examples are 'redoubt', 'spurr' and 'alaska' (defined in avo_volcs.pf) 
			%     Alternatively region can be a 4-element vector like: [leftlon rightlon lowerlat upperlat].
			%     dbroot - path of the database (root path to a monthly or daily database)
			%     archiveformat	- leave blank if its a normal database, otherwise 'daily' for a daily archive, 'monthly' for a monthly archive
            %     subclass - event tyoe/subclassification e.g.'*'=all,
            %     'l'=long period, 'h'=hybrid, 't'=tectonic, 'r'=rockfall. 
			% 
			%   Example:
            %     dirname = fileparts(which('catalog')); % get the path to the catalog directory
            %     dbroot = [dirname,'/demo/avodb200903']; 
            %     cobj = catalog;
            %     cobj = cobj.css2catalog(datenum(2009,3,20),datenum(2009,3,23),[],'Redoubt',dbroot,'')
			%
			%   Author: Glenn Thompson, 2002-2009
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
					fprintf('%s.origin not found\n',dbname);
				end
			else
				if strcmp(archiveformat,'daily')
      
					for dnum=floor(snum):floor(enum-1/1440)
						dbname = sprintf('%s_%s',dbroot,datestr(dnum, 'yyyy_mm_dd'));
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
							fprintf('%s.origin not found\n',dbname);
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
								fprintf('%s.origin not found\n',dbname);
							end
						end
					end
				end
			end

			% eliminate bogus magnitudes
			cobj.mag(cobj.mag > 10.0)=NaN;
		end

		%------------------------------------------------------------------
        % CSS_IMPORT
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
			expression_time = sprintf('time  >= %f && time  <= %f',minepoch,maxepoch);
			try
				db = dbsubset(db, expression_time);
			catch
				error('%s: dbsubset: %s',mfilename, expression_time);
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
				
                etype0 = dbgetv(db,'etype');
     
 			   	if isempty(etype0)
			        	etype = char(ones(numevents,1)*'R');
			    else
  			     	% convert etypes
					etype0=char(etype0);
					%i=find(etype0=='a');
					%etype(i)='t';
					%i=find(etype0=='b');
					%etype(i)='l';
					%i=find(etype0=='-');
					%etype(i)='u';  
					%i=find(etype0==' ');
					%etype(i)='u';
					etype(etype0=='a')='t';
                    etype(etype0=='b')='l';
                    etype(etype0=='-')='u';
                    etype(etype0==' ')='u';
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
   end % private methods
end

