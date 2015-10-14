%EVENTS the blueprint for Events objects in GISMO
% An Events object is a container for event metadata for events any type of
% seismic event catalog
% See also EventRate, readEvents, Events_Cookbook
classdef Events

    properties(GetAccess = 'public', SetAccess = 'public')
        time = [];
        lon = [];
        lat = [];
        depth = [];
        mag = [];
        magtype = {};
        etype = {};
        request = struct();
%         request.starttime = -Inf;
%         request.endtime = Inf;
%         request.dataformat = '';
%         request.minimumLongitude = -Inf;
%         request.maximumLongitude = Inf; 
%         request.minimumLatitude = -Inf;
%         request.maximumLatitude = Inf;  
%         request.minimumDepth = -Inf;
%         request.maximumDepth = Inf;
%         request.minimumRadius = 0;
%         request.maximumRadius = Inf;
%         request.minimumMagnitude = -Inf;
%         request.maximumMagnitude = Inf;
        arrivals = {};
%         magnitudes = {};
    end

    methods

        function obj = Events(time, lon, lat, depth, mag, magtype, etype, varargin)
            %Events.Events constructor for Events object
            % eventsObject = Events(lat, lon, depth, time, mag, etype, varargin)
            
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addRequired('time', @isnumeric);
            p.addRequired('lon', @isnumeric);
            p.addRequired('lat', @isnumeric);
            p.addRequired('depth', @isnumeric);
            p.addRequired('mag', @isnumeric);
            p.addRequired('magtype', @iscell);
            p.addRequired('etype', @iscell);
            p.addOptional('request',struct());
            p.parse(time, lon, lat, depth, mag, magtype, etype, varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                %obj = obj.set(field, val);
                eval(sprintf('obj.%s = val;',field));
            end
        end

        function val = snum(obj)
            val = min(obj.time());
        end
        
        function val = enum(obj)
            val = max(obj.time());
        end

%% ---------------------------------------------------

        function save(eventsObject, matfile)
            %Events.save save an eventsObject to a MAT file
            save eventsObject matfile
        end

%% ---------------------------------------------------
        function eventsObject = combine(eventsObject1, eventsObject2)
            %Events.combine combine two Events objects
            % eventsObject = combine(eventsObject1, eventsObject2)

            eventsObject = [];

            if nargin<2
                return
            end
            
            if isempty(eventsObject1)
                eventsObject = eventsObject2;
                return
            end
            
            if isempty(eventsObject2)
                eventsObject = eventsObject1;
                return
            end            

            if isempty(eventsObject1.time) & isempty(eventsObject2.time)
                return
            end

            if isempty(eventsObject1.time)
                eventsObject = eventsObject2;  
            elseif isempty(eventsObject2.time)
                eventsObject = eventsObject1;
            else
                eventsObject = eventsObject1; 
                props = {'time';'mag';'lat';'lon';'depth';'etype'};
                for i=1:length(props)
                    prop = props{i};
                    eventsObject.(prop) = [eventsObject1.(prop) eventsObject2.(prop)];
                end
            end
        end
        
%         function write(eventsObject, dbpath)
%             % Events.write Write a Catalog object to an Antelope
%             % CSS3.0 origin table. Requires Antelope & Antelope Toolbox.
%             
%             if admin.antelope_exists
%             
%                 % See if the database already exists
%                 db = dbopen(dbpath, 'r+');
%                 db = dblookup_table(db, 'origin')
%                 for i=1:numel(eventsObject.time)
%                     %db.record = i-1;
%                     db.record = dbaddnull(db);
%                     orid = dbnextid(db, 'orid');
%                     evid = dbnextid(db, 'evid');
%                     dbputv(db, 'orid', orid, 'evid', evid, 'time', datenum2epoch(eventsObject.time(i)), 'lat', eventsObject.lat(i), 'lon', eventsObject.lon(i), 'depth', eventsObject.depth(i), 'ml', eventsObject.mag(i));
%                 end
%                 dbclose(db)
%             else
%                 warning('Antelope toolbox not installed. Cannot write')
%             end
%         end
 
%% ---------------------------------------------------

%         function w=towaveform(obj)
%             % WHAT THE HELL IS THIS - SOMETHING TO DO WITH SEISAN - PERHAPS
%             % I NEED NEW CLASS EVENTS_SEISAN
%              w{1,1} = waveform();
%              if strcmp(get(obj,'method'), 'load_seisandb')
%                 % SEISAN FILE
%                 scnl = scnlobject('*', '*');
%                 ds = get(obj, 'datasource');
%                 sfile = get(obj, 'sfile');
%                 datestr([sfile.time])
%                 for k=1:numel([sfile.time])
%                     wavfiles = {sfile(k).wavfiles};
%                     yyyy = sfile(k).year;
%                     mm = sfile(k).month;
%                     time = sfile(k).time;
%                     dbpath = get(obj, 'dbpath');
%                     dbpath = strrep(dbpath, 'REA', 'WAV');
%                     for i=1:numel(wavfiles)
%                         wavpath = strtrim(fullfile(dbpath, sprintf('%04d', yyyy), sprintf('%02d', mm), wavfiles{i}));
%                         if exist(wavpath, 'file')
%                             %disp(sprintf('Loading %s',wavpath));
%                             ds = datasource('seisan', wavpath);
%                             w{k,i}=waveform(ds, scnl, time, time+300/86400);
%                         else
%                            disp(sprintf('Not found: %s',wavpath));
%                         end
%                     end         
%                 end
%              end
%         end
        
%% ---------------------------------------------------
		function plot(eventsObject, varargin)
            %Events.plot plot hypocenters in map view and cross-sections
            % 
            %
            %   Optional name/value pairs:
            %     'nsigma' - controls how zoomed-in the axes are (default
            %     5)            
            
            % Glenn Thompson 2014/06/01
            if all(isnan(eventsObject.lat))
                warning('No hypocenter data to plot');
                return
            end
            p = inputParser;
            p.addParamValue('nsigma', '5', @isstr);
            p.parse(varargin{:});
            nsigma = p.Results.nsigma;
            
			% change region
            region = get_region(eventsObject, nsigma);
      
            % Compute Marker Size
            symsize = get_symsize(eventsObject);
      
			figure;
            set(gcf,'Color', [1 1 1]);
            
			% lon-lat plot
			axes('position',[0.05 0.45 0.5 0.5]);
            scatter(eventsObject.lon, eventsObject.lat, symsize);
			grid on;
            %set(gca, 'XLim', [region(1) region(2)]);
            %set(gca, 'YLim', [region(3) region(4)]);
			xlabel('Longitude');

			% depth-longitude
			axes('position',[0.05 0.05 0.5 0.35]);
            scatter(eventsObject.lon, eventsObject.depth, symsize);
			ylabel('Depth (km)');
			xlabel('Longitude');
			grid on;
			set(gca, 'YDir', 'reverse');
			%set(gca, 'XLim', [region(1) region(2)]);

			% depth-lat
			axes('position',[0.6 0.45 0.35 0.5]);
            scatter(eventsObject.depth, eventsObject.lat, symsize);
			xlabel('Depth (km)');
			%set(gca, 'XDir', 'reverse');
			ylabel('Latitude');
			grid on;
			%set(gca, 'YLim', [region(3) region(4)]);

        end
%% ---------------------------------------------------        
		function plot3(eventsObject, varargin)
            %Events.plot3 plot hypocenters in 3-D
            %   eventsObject.plot3()
            %
            %   Optional name/value pairs:
            %     'nsigma' - controls how zoomed-in the axes are (default
            %     5)            
            
            % Glenn Thompson 2014/06/01
            if all(isnan(eventsObject.lat))
                warning('No hypocenter data to plot');
                return
            end
            p = inputParser;
            p.addParamValue('nsigma', '5', @isstr);
            p.parse(varargin{:});
            nsigma = p.Results.nsigma;            
            
			% change region
            region = get_region(eventsObject, nsigma);
      
            % Compute Marker Size
            symsize = get_symsize(eventsObject);
            
            % 3D plot
            figure
            set(gcf,'Color', [1 1 1]);
            scatter3(eventsObject.lon, eventsObject.lat, eventsObject.depth, symsize);
			set(gca, 'ZDir', 'reverse');
			grid on;
            set(gca, 'XLim', [region(1) region(2)]);
            set(gca, 'YLim', [region(3) region(4)]);
			xlabel('Longitude');
            ylabel('Latitude');
			zlabel('Depth (km)');
            
        end
  %% ---------------------------------------------------      
        %% PLOT_TIME
        function plot_time(eventsObject); 
            %PLOT_TIME plot magnitude and depth against time
            %   catlog_object.plot_time()
            
            % Glenn Thompson 2014/06/01
            
            symsize = get_symsize(eventsObject); 
            
            xlims = [floor(snum(eventsObject)) ceil(enum(eventsObject))];

			% time-depth
            if all(isnan(eventsObject.depth))
                warning('No depth data to plot');
            else
                figure;
                set(gcf,'Color', [1 1 1]);
                subplot(2,1,1);
                scatter(eventsObject.time, eventsObject.depth, symsize);
                set(gca, 'XLim', xlims);
                datetick('x');
                xlabel('Date');
                ylabel('Depth (km)');
                set(gca, 'YDir', 'reverse');
                grid on;
            
                % time-mag
                subplot(2,1,2);
            end
            if all(isnan(eventsObject.mag))
                warning('No magnitude data to plot');
            else
                scatter(eventsObject.time, eventsObject.mag, symsize);
                %stem(eventsObject.time, eventsObject.mag);
                set(gca, 'XLim', xlims);
                datetick('x');
                xlabel('Date');
                ylabel('Magnitude');
                grid on;
            end
        end

  %% ---------------------------------------------------              
        function helenaplot(obj)
            for c=1:length(obj)
                figure(gcf+1)
                set(gcf,'Color', [1 1 1]);
                [ax, h1, h2] = plotyy(obj(c).time, cumsum(obj(c).mag), obj(c).time, cumsum(obj(c).energy), @plot, @plot);
                datetick(ax(1), 'x','keeplimits');
                datetick(ax(2), 'x','keeplimits');
                set(ax(1), 'YLabel', 'Cumulative Magnitude');
                set(ax(2), 'YLabel', 'Cumulative Energy');
            end
        end
        
%% ---------------------------------------------------        
        %% OTHER MISC PLOTTING CODES
%         function mapexample(eventsObject)
%             % simple epicentral plot
%             latmin = min(eventsObject1.lat) - latrange/20;
% 			lonmin = min(eventsObject1.lon) - lonrange/20;
% 			latmax = max(eventsObject1.lat) + latrange/20;
% 			lonmax = max(eventsObject1.lon) + lonrange/20;
%             figure;
%             close all
%             h = worldmap([latmin latmax],[lonmin lonmax]);
%             load coast
%             plotm(lat, long)
% 
%             % Add some standard datasets from Matlab
%             geoshow('landareas.shp', 'FaceColor', [0.15 0.5 0.15])
%             geoshow('worldlakes.shp', 'FaceColor', 'cyan')
%             geoshow('worldrivers.shp', 'Color', 'blue')
%             geoshow('worldcities.shp', 'Marker', '.',...
%                 'MarkerEdgeColor', 'red')
% 
% 
%             % Add features with textm, e.g.
%             % textm(64.83778, -147.71639, 'Fairbanks')
%             % plotm(64.83778, -147.71639, 'ro')
% 
%             plotm(eventsObject.lat, eventsObject.lon, '*');
%         end
%% ---------------------------------------------------
        function bvalue(eventsObject, mcType)
            %BVALUE evaluate b-value, a-value and magnitude of completeness
            % of an earthquake catalog stored in a Catalog object.
            %
            % BVALUE(eventsObject, MCTYPE) produces a Gutenberg-Richter type plot 
            %    with the best fit line and display of b-,a-values and Mc 
            %    for the catalog object eventsObject. MCTYPE is a number from 1-5 
            %    to select the algorithm used for calculation of the 
            %    magnitude of completeness. Options are:
            %
            %    1: Maximum curvature
            %    2: Fixed Mc = minimum magnitude (Mmin)
            %    3: Mc90 (90% probability)
            %    4: Mc95 (95% probability)
            %    5: Best combination (Mc95 - Mc90 - maximum curvature)

            % Liberally adapted from original code in ZMAP.
            % Author: Silvio De Angelis, 27/07/2012 00:00:00
            % Modified and included in Catalog by Glenn Thompson,
            % 14/06/2014

            % This program is free software; you can redistribute it and/or modify
            % it under the terms of the GNU General Public License as published by
            % the Free Software Foundation; either version 2 of the License, or
            % (at your option) any later version.
            %
            % This program is distributed in the hope that it will be useful,
            % but WITHOUT ANY WARRANTY; without even the implied warranty of
            % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
            % GNU General Public License for more details.
            %
            % You should have received a copy of the GNU General Public License
            % along with this program; if not, write to the
            % Free Software Foundation, Inc.,
            % 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

            if nargin < 2
                disp('--------------------------------------------------------')
                disp('ERROR: Usage is: Catalog.bvalue(mcType). mcType not specified')
                disp('--------------------------------------------------------')
                disp('mcType can be:')
                disp('1: Maximum curvature')
                disp('2: Fixed Mc = minimum magnitude (Mmin)')
                disp('3: Mc90 (90% probability)')
                disp('4: Mc95 (95% probability)')
                disp('5: Best combination (Mc95 - Mc90 - maximum curvature)')
                return
            end

            % form magnitude vector - removing any NaN values with find
            good_magnitude_indices = find(eventsObject.mag > -3.0);
            mag = eventsObject.mag(good_magnitude_indices);
            %MIN AND MAX MAGNITUDE IN CATALOG
            minimum_mag = min(mag);
            maximum_mag = max(mag);

            %COUNT EVENTS IN EACH MAGNITUDE BIN
            [bval, xt2] = hist(mag, (minimum_mag:0.1:maximum_mag));

            %CUMULATIVE NUMBER OF EVENTS IN EACH MAGNITUDE BIN
            bvalsum = cumsum(bval);

            %NUMBER OF EVENTS IN EACH BIN IN REVERSE ORDER
            bval2 = bval(length(bval):-1:1);

            %NUMBER OF EVENTS IN EACH MAGNITUDE BIN IN REVERSE ORDER
            bvalsum3 = cumsum(bval(length(bval):-1:1));

            %BINS IN REVERSE ORDER
            xt3 = (maximum_mag:-0.1:minimum_mag);
            backg_ab = log10(bvalsum3);

            %CREATE FIGURE WINDOW AND MAKE FREQUENCY-MAGNITUDE PLOT
            figure('Color','w','Position',[0 0 600 600])

            pl = semilogy(xt3,bvalsum3,'sb'); % semilogy is same as plot, except a log (base10) scale is used for Y-axis
            set(pl, 'LineWidth', [1.0],'MarkerSize', [10],'MarkerFaceColor','r','MarkerEdgeColor','k');
            axis square
            hold on

            pl1 = semilogy(xt3,bval2,'^b');
            set(pl1, 'LineWidth',[1.0],'MarkerSize',[10],'MarkerFaceColor','w','MarkerEdgeColor','k');
            xlabel('Magnitude','Fontsize', 12)
            ylabel('Cumulative Number','Fontsize',12)
            set(gca,'visible','on','FontSize',12,'FontWeight','normal',...
                'FontWeight','bold','LineWidth',[1.0],'TickDir','in','Ticklength',[0.01 0.01],...
                'Box','on','Tag','cufi','color','w')

            %ESTIMATE B-VALUE (MAX LIKELIHOOD ESTIMATE)
            Nmin = 10;
            fMccorr = 0;
            fBinning = 0.1;

            if length(mag) >= Nmin

                %GOODNESS-OF-FIT TO POWER LAW
                %%%%%%%%%%%%%%%%%% mcperc_ca3.m start %%%%%%%%%%%%%%%%%%%%
                % This is a completeness determination test

                [bval,xt2] = hist(mag,-2:0.1:6);
                l = max(find(bval == max(bval)));
                magco0 =  xt2(l);

                dat = [];

                %for i = magco0-0.6:0.1:magco0+0.2
                for i = magco0-0.5:0.1:magco0+0.7
                    l = mag >= i - 0.0499;
                    nu = length(mag(l));
                    if length(mag(l)) >= 25;
                        %[bv magco stan av] =  bvalca3(catZmap(l,:),2,2);
                        [mw bv2 stan2 av] =  bvalue_lib.bmemag(mag(l));
                        bvalue_lib.synthb_aut;
                        dat = [ dat ; i res2];
                    else
                        dat = [ dat ; i nan];
                    end

                end

                j =  min(find(dat(:,2) < 10 ));
                if isempty(j) == 1; Mc90 = nan ;
                else;
                    Mc90 = dat(j,1);
                end

                j =  min(find(dat(:,2) < 5 ));
                if isempty(j) == 1; Mc95 = nan ;
                else;
                    Mc95 = dat(j,1);
                end

                j =  min(find(dat(:,2) < 10 ));
                if isempty(j) == 1; j =  min(find(dat(:,2) < 15 )); end
                if isempty(j) == 1; j =  min(find(dat(:,2) < 20 )); end
                if isempty(j) == 1; j =  min(find(dat(:,2) < 25 )); end
                j2 =  min(find(dat(:,2) == min(dat(:,2)) ));
                %j = min([j j2]);

                Mc = dat(j,1);
                magco = Mc;
                prf = 100 - dat(j2,2);
                if isempty(magco) == 1; magco = nan; prf = 100 -min(dat(:,2)); end
                %display(['Completeness Mc: ' num2str(Mc) ]);
                %%%%%%%%%%%%%%%%%% mcperc_ca3.m end %%%%%%%%%%%%%%%%%%%%%%

                %CALCULATE MC
                [fMc] = bvalue_lib.calc_Mc(mag, mcType, fBinning, fMccorr);
                l = mag >= fMc-(fBinning/2);
                if length(mag(l)) >= Nmin
                    [fMeanMag, fBValue, fStd_B, fAValue] =  bvalue_lib.calc_bmemag(mag(l), fBinning);
                else
                    [fMc, fBValue, fStd_B, fAValue] = deal(NaN);
                end

                %STANDARD DEV OF a-value SET TO NAN;
                [fStd_A, fStd_Mc] = deal(NaN);

            else
                [fMc, fStd_Mc, fBValue, fStd_B, fAValue, fStd_A, ...
                    fStdDevB, fStdDevMc] = deal(NaN);
            end

            magco = fMc;
            index_low=find(xt3 < magco+.05 & xt3 > magco-.05);
            mag_hi = xt3(1);
            index_hi = 1;
            mz = xt3 <= mag_hi & xt3 >= magco-.0001;
            mag_zone=xt3(mz);
            y = backg_ab(mz);

            %PLOT MC IN FIGURE
            Mc = semilogy(xt3(index_low),bvalsum3(index_low)*1.5,'vk');
            set(Mc,'LineWidth',[1.0],'MarkerSize',7)
            Mc = text(xt3(index_low)+0.2,bvalsum3(index_low)*1.5,'Mc');
            set(Mc,'FontWeight','normal','FontSize',12,'Color','k')

            %CREATE AND PLOT FIT LINE
            sol_type = 'Maximum Likelihood Solution';
            bw=fBValue;
            aw=fAValue;
            ew=fStd_B;
            p = [ -1*bw aw];
            f = polyval(p,mag_zone);
            f = 10.^f;
            hold on
            ttm= semilogy(mag_zone,f,'k');
            set(ttm,'LineWidth',[2.0])
            std_backg = ew;

            %ERROR CALCULATIONS
            %b = mag;
            bv = [];
            si = [];

            set(gca,'XLim',[min(mag)-0.5  max(mag+0.5)])
            %set(gca,'YLim',[0.9 length(mag+30)*2.5]);

            p=-p(1,1);
            p=fix(100*p)/100;
            tt1=num2str(bw,3);
            tt2=num2str(std_backg,1);
            tt4=num2str(bv,3);
            tt5=num2str(si,2);
            tmc=num2str(magco,2);
            rect=[0 0 1 1];
            h2=axes('position',rect);
            set(h2,'visible','off');
            a0 = aw-log10((max(eventsObject.time)-min(eventsObject.time))/365);

            text(.53,.88, ['b-value = ',tt1,' +/- ',tt2,',  a value = ',num2str(aw,3)],'FontSize',12);
            text(.53,.85,sol_type,'FontSize',12 );
            text(.53,.82,['Magnitude of Completeness = ',tmc],'FontSize',12);
        end 
%% ---------------------------------------------------        
        %% SUBCLASSIFY
        function c = subclassify(eventsObject, subclasses)
            % Events.subclassify Split eventsObject into multiple
            % eventsObjects where each one contains only a single etype
            % (event type). THIS NEED CHANGING BECAUSE ETYPE IS NOW A CELL
            % ARRAY OF STRINGS
            
            eventsObjects = subclassify(eventsObject, subclasses)
            if strcmp(subclasses, '*')==0
                for i = 1:length(subclasses);
                    c(i) = eventsObject;
                    subclass = subclasses(i);
                    index = strfind(eventsObject.etype, subclass); % previously findstr
                    if numel(eventsObject.lat)==numel(eventsObject.etype)
                        c(i).lat = eventsObject.lat(index);
                        c(i).lon = eventsObject.lon(index);
                        c(i).depth = eventsObject.depth(index);
                    end
                    c(i).time = eventsObject.time(index);
                    c(i).mag = eventsObject.mag(index);
                    c(i).etype = eventsObject.etype(index);
                end
            end     
        end
%% ---------------------------------------------------         
        function erobj=eventrate(eventsObject, varargin)
            %eventsObject.eventrate    
            % Create an EventRate object from an Events object
            % object, with a binsize determined automatically.
            %   erobj = eventsObject.eventrate()
            %
            % Specify a binsize (in days):
            %   erobj = eventsObject.eventrate('binsize', 1/24)
            %
            % Specify a stepsize (in days). Must be <= stepsize.
            %   erobj = eventsObject.eventrate(..., 'stepsize',1/24) 
                         
            p = inputParser;
            p.addParamValue('binsize', 0, @isnumeric);
            p.addParamValue('stepsize', 0, @isnumeric);
            p.parse(varargin{:});
            binsize = p.Results.binsize;
            stepsize = p.Results.stepsize;
            
            for i=1:numel(eventsObject)
            
                if ~(binsize>0)
                    binsize = autobinsize(eventsObject(i));
                end
                if ~(stepsize>0)
                    stepsize = binsize;
                end      
                if (stepsize > binsize)
                   disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
                   return;
                end          
                if ~(binsize>0)
                    binsize = autobinsize(eventsObject(i).enum-eventsObject(i).snum);
                end
                if ~(stepsize>0)
                    stepsize = binsize;
                end      
                if (stepsize > binsize)
                   disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
                   return;
                end 

                % Find out how many event types we have
                etypes = unique(eventsObject(i).etype);      

                % bin the data
                [time, counts, energy, smallest_energy, ...
                    median_energy, std, median_time_interval] = ...
                    matlab_extensions.bin_irregular(eventsObject(i).time, ...
                    magnitude.mag2eng(eventsObject(i).mag), ...
                    binsize, eventsObject(i).snum, eventsObject(i).enum, stepsize);

                % create the Event Rate object
                total_counts = length(eventsObject(i).time);
                numbins = numel(time);
                erobj(i) = EventRate(time, counts, energy, median_energy, ...
                    smallest_energy, biggest_energy, median_time_interval, total_counts, ...
                    eventsObject(i).snum, eventsObject(i).enum, etypes, binsize, stepsize, numbins);
            end
        end
%% --------------------------------------------------- 
        %% PLOT COUNTS / EVENTRATE
        function plot_counts(eventsObject)
            %Events.plot_counts Plot event counts - i.e. number of events
            %per unit time. See also the EventRate class.
            erobj = eventsObject.eventrate();
            erobj.plot()
        end
        
%% ---------------------------------------------------         
        %% PLOT Peak_rate and Max_mag
        function plotprmm(eventsObject)
            %Events.plotprmm Plot the peak rate and maximum magnitude of a
            %set of events
            figure
            symsize = get_symsize(eventsObject);            
            if all(isnan(eventsObject.mag))
                warning('No magnitude data to plot');
            else
                
                % plot magnitudes
                subplot(2,1,1), scatter(eventsObject.time, eventsObject.mag, symsize);
                %stem(eventsObject.time, eventsObject.mag);
                set(gca, 'XLim', [floor(eventsObject.snum) ceil(eventsObject.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Magnitude');
                grid on;
                
                % put 'MM' label by max mag event
                [mm, mmi] = max(eventsObject.mag);
                text(eventsObject.time(mmi), eventsObject.mag(mmi), 'MM','color','r');
                disp(sprintf('MM=%.1f occurs at %.1f%% of time series',mm,100*(eventsObject.time(mmi) - eventsObject.snum)/(eventsObject.enum-eventsObject.snum)));
                
                % plot event rate in 100 equal bins
                days = eventsObject.enum - eventsObject.snum;
                binsize = days/100;
                erobj = eventsObject.eventrate('binsize',binsize);
                subplot(2,1,2),plot(erobj.time, erobj.counts);
                set(gca, 'XLim', [floor(eventsObject.snum) ceil(eventsObject.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Event Rate');
                grid on; 
                
                % put 'PR' label by peak-rate
                [pr, pri] = max(erobj.counts);
                text(erobj.time(pri), erobj.counts(pri), 'PR','color','r');               
                disp(sprintf('PR=%d occurs at %.1f%% of time series',pr,100*(erobj.time(pri) - erobj.snum)/(erobj.enum-erobj.snum)));
            end
        end
%% ---------------------------------------------------         
%         function eev(obj)
%             % Events.eev - Browse an Events object one event at a time.
%             %  eventsObject.eev() Browse through an events object one event
%             %  at a time in a similar way to the Seisan program 'eev'.
%             %. Based on the Seisan program of the same name
%             PRETRIGGER = 10/86400;
%             POSTTRIGGER = (60+10)/86400;
%             eventnum = 1;
% 
%             while 1,
%                 
%                 % don't beyond start or end of this catalog object
%                 if eventnum<1
%                     eventnum=1;
%                 end
%                 if eventnum>numel(obj.time)
%                     eventnum=numel(obj.time);
%                 end           
%                 % display line for this event
%                 dstr=datestr(obj.time(eventnum),31);
%                 subclass=obj.etype{eventnum};
%                 mag=obj.mag(eventnum);
%                 outstr=sprintf('%s %s %5.2f',dstr,subclass,mag);
%                 choice=input([outstr,':  ?'],'s');           
%                 
%                 % process choice
%                 if isempty(choice)
%                     eventnum=eventnum+1; % ENTER goes to next event 
% 
%                 elseif (choice(1)=='c') % CLASSIFY
%                     classify_event(time);
% 
%                 elseif (choice(1)=='p') % PLOT
% %                     if strcmp(get(obj,'method'), 'import_aef_file')
% %                         % AEF SUMMARY FILE FOR MBWH
% %                         time = obj.time(eventnum);
% %                         sfilename = time2sfile(time);
% %                         % read the sfile
% %                         sfile = readCatalog.read_sfile(fullfile('/raid','data','seisan','MVOE_','REA'), sfilename,'*','*')
% % %                         wavfiles = {sfile(1).wavfiles};
% % %                         wavpath = fullfile('/raid','data','seisan','MVOE_', 'WAV', sprintf('%04d', wavfiles{1})
% % %                         ds = datasource('seisan', wavpath)
% % %                         w = waveform(ds, scnl, time-PRETRIGGER, time+POSTTRIGGER);
% %                     end    
%                     if strcmp(obj.request.dataformat, 'seisan')
%                         % SEISAN FILE
%                         scnl = scnlobject('*', '*');
%                         ds = obj.request.database;
%                         sfile = obj.request.sfilelist;
% 
%                         wavfiles = {sfile(eventnum).wavfiles};
%                         yyyy = sfile(eventnum).year;
%                         mm = sfile(eventnum).month;
%                         time = sfile(eventnum).time;
%                         dbpath = get(obj, 'dbpath');
%                         dbpath = strrep(dbpath, 'REA', 'WAV');
%                         for i=1:numel(wavfiles)
%                             wavpath = fullfile(dbpath, sprintf('%04d', yyyy), sprintf('%02d', mm), wavfiles{i});
%                             if ~exist(wavpath, 'file')
%                                 dbpath = strrep(dbpath, 'WAV', 'WAV2');
%                                 wavpath = fullfile(dbpath, sprintf('%04d', yyyy), sprintf('%02d', mm), wavfiles{i});
%                             end
%                             disp(sprintf('Loading %s',wavpath));
%                             ds = datasource('seisan', wavpath);
%                             datestr(time)
%                             w = waveform(ds, scnl, time-PRETRIGGER, time+POSTTRIGGER);
%                         end
%                         if exist('w','var')
%                             mulplt(w);
%                         end
%                     end
% 
%                 elseif (choice(1)=='f') % FORWARD N EVENTS
%                     num=1;
%                     if length(choice)>1
%                         num=str2num(choice(2:end));
%                     end
%                     eventnum=eventnum+num; 
% 
%                 elseif (choice(1)=='b') % BACKWARD N EVENTS
%                     num=1;
%                     if length(choice)>1
%                         num=str2num(choice(2:end));
%                     end
%                     eventnum=eventnum-num;
% 
%                 elseif (choice(1)=='t') % JUMP TO TIME
%                     month=1;dd=1;hr=0;
%                     if length(choice)>4
%                         year=str2num(choice(2:5));
%                     end
%                     if length(choice)>6
%                         month=str2num(choice(6:7));
%                     end
%                     if length(choice)>8
%                         dd=str2num(choice(8:9));
%                     end
%                     if length(choice)>10
%                         hr=str2num(choice(10:11));
%                     end
%                     jumptime=datenum(year,month,dd,hr,0,0);
%                     eventnum = min(find(obj.time > jumptime));
% 
%                 elseif (choice(1)=='s') % SUMMARISE - SHOW S FILE or similar data 
%                     try
%                         s = get(obj, 'sfile');
%                         disp(s(eventnum));                 
%                     catch
%                         disp('No Sfile');
%                     end
% 
%                 elseif (choice(1)=='x') % CLOSE ALL
%                     close all;
% 
%                 elseif (choice=='q') % QUIT
%                     break;
% 
%                 elseif (choice(1)=='h') % HELP
%                     disp(' ');
%                     disp('Options:');
%                     disp('________');
%                     disp(' ');
%                     disp('b[num]            - go backward 1 event (or N events)');
%                     disp('c                 - classify');
%                     disp('e                 - edit/generate S-file');
%                     disp('f[num]            - go forward 1 event (or N events)');
%                     disp('h                 - this help');
%                     disp('p                 - plot');
%                     disp('s                 - summarise');
%                     disp('tYYYY[MM[DD[HH]]] - jump to date/hour specified');
%                     disp('x                 - close all figure windows');
%                     disp('q                 - quit');
%                     disp(' ');
%                 end
%             end
%         end   
%         
% %% ---------------------------------------------------

        %% WRITE CATALOG TO AN ANTELOPE/DATASCOPE css3.0 or aefsam0.1 DATABASE
        function write(eventsObject, outformat, outpath, schema)
            %Events.write Write an Events object to disk
            %
            % eventsObject.write('antelope', 'mydb', 'css3.0') writes the
            % eventsObject to a CSS3.0 database called 'mydb' using
            % Antelope. Requires Antelope and Antelope Toolbox. Support for
            % aefsam0.1 schema will be added later.
            % 
            % Support for other output formats, e.g. Seisan, will be added
            % later.
            
            % Glenn Thompson, 4 February 2015
 0         
 outformat
            switch outformat
                case 'antelope'
                    
                    .5
                    if admin.antelope_exists
                        .6
                        dbpath = outpath;
            
                        % create new db
                        if ~exist('schema','var')
                            schema='css3.0';
                        end
                        dbcreate(dbpath, schema);
                        
                        system(sprintf('touch %s.event',dbpath));
                        system(sprintf('touch %s.origin',dbpath));
1
                        % open db
                        db = dbopen(dbpath, 'r+');
                        dbe = dblookup_table(db,'event');
                        dbo = dblookup_table(db,'origin');
                        dbn = dblookup_table(db,'netmag');
2
                        % write event to event and origin tables
                        if numel(eventsObject.time)>0
                            for eventidx = 1:numel(eventsObject.time)
                                event.evid = dbnextid(dbe,'evid');
                                origin.orid = dbnextid(dbo,'orid');
                                origin.time = datenum2epoch(eventsObject.time(eventidx));
                                origin.lon = eventsObject.lon(eventidx);
                                origin.lat = eventsObject.lat(eventidx);
                                origin.depth = eventsObject.depth(eventidx);
                                origin.etype = eventsObject.etype{eventidx};
                                
                                % Antelope etype can only be two characters
                                % Antelope uses 'eq' where IRIS use
                                % 'earthquake'
                                if strcmp(origin.etype,'earthquake')
                                    origin.etype = 'eq';
                                else
                                    if length(origin.etype)>2
                                        origin.etype=origin.etype(1:2);
                                    end
                                end
                                
                                netmag.magid = dbnextid(dbn,'magid');
                                netmag.magtype = eventsObject.magtype{eventidx};
                                netmag.magnitude = eventsObject.mag(eventidx);
                                
                                % Add new record to event table & write to
                                % it
                                dbe.record = dbaddnull(dbe);
                                dbputv(dbe, 'evid', event.evid, ...
                                    'prefor', origin.orid);
                                
                                % Add new record to origin table & write to
                                % it
                                dbo.record = dbaddnull(dbo);
                                dbputv(dbo, 'lat', origin.lat, ...
                                    'lon', origin.lon, ...
                                    'depth', origin.depth, ...
                                    'time', origin.time, ...
                                    'orid', origin.orid, ...
                                    'evid', event.evid, ...
                                    'etype', origin.etype );
                                
                                % Add new record to netmag table & write to
                                % it
                                dbn.record = dbaddnull(dbn);
                                dbputv(dbn, 'magid', netmag.magid, ...
                                    'orid', origin.orid, ...
                                    'evid', event.evid, ...
                                    'magtype', netmag.magtype, ...
                                    'magnitude', netmag.magnitude );                               
                               
                            end
                        end
                        dbclose(db);
                    end
                otherwise,
                    warning('format not supported yet')
            end % end switch
        end % function
        
    end
%% ---------------------------------------------------
    methods (Access=protected, Hidden=true)
        
        %% AUTOBINSIZE        
        function binsize = autobinsize(eventsObject)
        %autobinsize Compute the best bin size based on start and end times
            binsize = autobinsize(max(eventsObject.time) - min(eventsObject.time));
        end
%% ---------------------------------------------------        
        function region = get_region(eventsObject, nsigma)
        % region Compute the region to plot based on spread of lon,lat data
			medianlat = nanmedian(eventsObject.lat);
			medianlon = nanmedian(eventsObject.lon);
			cosine = cos(medianlat);
			stdevlat = nanstd(eventsObject.lat);
			stdevlon = nanstd(eventsObject.lon);
			rangeindeg = max([stdevlat stdevlon*cosine]) * nsigma;
			region = [(medianlon - rangeindeg/2) (medianlon + rangeindeg/2) (medianlat - rangeindeg/2) (medianlat + rangeindeg/2)];
        end
        
%% ---------------------------------------------------
        function symsize = get_symsize(eventsObject)
            %get_symsize Get symbol marker size based on magnitude of event
            % Compute Marker Size
            minsymsize = 3;
            maxsymsize = 50;
            symsize = (eventsObject.mag + 2) * 10; % -2- -> 1, 1 -> 10, 0 -> 20, 1 -> 30, 2-> 40, 3+ -> 50 etc.
            symsize(symsize<minsymsize)=minsymsize;
            symsize(symsize>maxsymsize)=maxsymsize;
            % deal with NULL (NaN) values
            symsize(isnan(symsize))=minsymsize;
        end
%% ---------------------------------------------------                      
                
    end

end