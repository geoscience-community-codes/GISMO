%CATALOG the blueprint for Catalog objects in GISMO
% An Catalog object is a container for event metadata
% See also EventRate, readEvents, Catalog_Cookbook
classdef Catalog

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

        function obj = Catalog(time, lon, lat, depth, mag, magtype, etype, varargin)
            %Catalog.Catalog constructor for Catalog object
            % catalogObject = Catalog(lat, lon, depth, time, mag, etype, varargin)
            
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
            
            % Fill empty vectors to size of time
            if isempty(obj.lon)
                obj.lon = NaN(size(obj.time));
            end
            if isempty(obj.lat)
                obj.lat = NaN(size(obj.time));
            end   
            if isempty(obj.depth)
                obj.depth = NaN(size(obj.time));
            end
            if isempty(obj.mag)
                obj.mag = NaN(size(obj.time));
            end  
            if isempty(obj.magtype) % 'u' for unknown
                obj.magtype = cellstr(repmat('u',size(obj.time)));
            end 
            if isempty(obj.etype)  % 'u' for unknown
                obj.etype = cellstr(repmat('u',size(obj.time)));
            end     
            
            % Check everything is same size - probably something involving
            % getting properties and then looping over them
            
        end
%% ---------------------------------------------------
        function val = snum(obj)
            val = min(obj.time());
        end
%% ---------------------------------------------------        
        function val = enum(obj)
            val = max(obj.time());
        end

%% ---------------------------------------------------
        function save(catalogObject, matfile)
            %Catalog.save save an catalogObject to a MAT file
            save(catalogObject,matfile)
        end

%% ---------------------------------------------------
        function catalogObject = combine(catalogObject1, catalogObject2)
            % SCAFFOLD: not tested & merge would be better name
            %Catalog.combine combine two Catalog objects
            % catalogObject = combine(catalogObject1, catalogObject2)

            catalogObject = [];

            if nargin<2
                return
            end
            
            if isempty(catalogObject1)
                catalogObject = catalogObject2;
                return
            end
            
            if isempty(catalogObject2)
                catalogObject = catalogObject1;
                return
            end            

            if isempty(catalogObject1.time) & isempty(catalogObject2.time)
                return
            end

            if isempty(catalogObject1.time)
                catalogObject = catalogObject2;  
            elseif isempty(catalogObject2.time)
                catalogObject = catalogObject1;
            else
                catalogObject = catalogObject1; 
                props = {'time';'mag';'lat';'lon';'depth';'etype'};
                for i=1:length(props)
                    prop = props{i};
                    catalogObject.(prop) = [catalogObject1.(prop) catalogObject2.(prop)];
                end
            end
        end
%% ---------------------------------------------------
		function webmap(catalogObject)
            %Catalog.webmap plot hypocenters in map view using webmap         
            
            if all(isnan(catalogObject.lat))
                warning('No hypocenter data to plot');
                return
            end
            lat = catalogObject.lat(~isnan((catalogObject.lat)));
            lon = catalogObject.lon(~isnan((catalogObject.lat)));
            webmap
            wmmarker(lat, lon)

        end
%% ---------------------------------------------------
		function plot(catalogObject, varargin)
            %Catalog.plot plot hypocenters in map view and cross-sections
            % 
            %
            %   Optional name/value pairs:
            %     'nsigma' - controls how zoomed-in the axes are (default
            %     5)            
            
            % Glenn Thompson 2014/06/01
            if all(isnan(catalogObject.lat))
                warning('No hypocenter data to plot');
                return
            end
            p = inputParser;
            p.addParamValue('nsigma', '5', @isstr);
            p.parse(varargin{:});
            nsigma = p.Results.nsigma;
            
			% change region
            region = get_region(catalogObject, nsigma);
      
            % Compute Marker Size
            symsize = get_symsize(catalogObject);
      
			figure;
            set(gcf,'Color', [1 1 1]);
            
			% lon-lat plot
			axes('position',[0.05 0.45 0.5 0.5]);
            scatter(catalogObject.lon, catalogObject.lat, symsize);
			grid on;
            %set(gca, 'XLim', [region(1) region(2)]);
            %set(gca, 'YLim', [region(3) region(4)]);
			xlabel('Longitude');

			% depth-longitude
			axes('position',[0.05 0.05 0.5 0.35]);
            scatter(catalogObject.lon, catalogObject.depth, symsize);
			ylabel('Depth (km)');
			xlabel('Longitude');
			grid on;
			set(gca, 'YDir', 'reverse');
			%set(gca, 'XLim', [region(1) region(2)]);

			% depth-lat
			axes('position',[0.6 0.45 0.35 0.5]);
            scatter(catalogObject.depth, catalogObject.lat, symsize);
			xlabel('Depth (km)');
			%set(gca, 'XDir', 'reverse');
			ylabel('Latitude');
			grid on;
			%set(gca, 'YLim', [region(3) region(4)]);

        end
%% ---------------------------------------------------        
		function plot3(catalogObject, varargin)
            %Catalog.plot3 plot hypocenters in 3-D
            %   catalogObject.plot3()
            %
            %   Optional name/value pairs:
            %     'nsigma' - controls how zoomed-in the axes are (default
            %     5)            
            
            % Glenn Thompson 2014/06/01
            if all(isnan(catalogObject.lat))
                warning('No hypocenter data to plot');
                return
            end
            p = inputParser;
            p.addParamValue('nsigma', '5', @isstr);
            p.parse(varargin{:});
            nsigma = p.Results.nsigma;            
            
			% change region
            region = get_region(catalogObject, nsigma);
      
            % Compute Marker Size
            symsize = get_symsize(catalogObject);
            
            % 3D plot
            figure
            set(gcf,'Color', [1 1 1]);
            scatter3(catalogObject.lon, catalogObject.lat, catalogObject.depth, symsize);
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
        function plot_time(catalogObject); 
            %PLOT_TIME plot magnitude and depth against time
            %   catlog_object.plot_time()
            
            % Glenn Thompson 2014/06/01
            
            symsize = get_symsize(catalogObject); 
            
            xlims = [floor(snum(catalogObject)) ceil(enum(catalogObject))];

			% time-depth
            if all(isnan(catalogObject.depth))
                warning('No depth data to plot');
            else
                figure;
                set(gcf,'Color', [1 1 1]);
                subplot(2,1,1);
                scatter(catalogObject.time, catalogObject.depth, symsize);
                set(gca, 'XLim', xlims);
                datetick('x');
                xlabel('Date');
                ylabel('Depth (km)');
                set(gca, 'YDir', 'reverse');
                grid on;
            
                % time-mag
                subplot(2,1,2);
            end
            if all(isnan(catalogObject.mag))
                warning('No magnitude data to plot');
            else
                scatter(catalogObject.time, catalogObject.mag, symsize);
                %stem(catalogObject.time, catalogObject.mag);
                set(gca, 'XLim', xlims);
                datetick('x');
                xlabel('Date');
                ylabel('Magnitude');
                grid on;
            end
        end
  %% ---------------------------------------------------
        function hist(catalogObject); 
            %HIST plot histograms of magnitude distribution, depth
            %distribution etc
            %   catalog_object.hist()
            
            mmin = min(catalogObject.mag);
            mmax = max(catalogObject.mag);
            bincenters = floor(mmin*10)/10 + 0.05 : 0.1 : floor(mmax*10)/10 + 0.05;
            hist(catalogObject.mag, bincenters);

        end
          
%% ---------------------------------------------------        
        %% OTHER MISC PLOTTING CODES
%         function mapexample(catalogObject)
%             % simple epicentral plot
%             latmin = min(catalogObject1.lat) - latrange/20;
% 			lonmin = min(catalogObject1.lon) - lonrange/20;
% 			latmax = max(catalogObject1.lat) + latrange/20;
% 			lonmax = max(catalogObject1.lon) + lonrange/20;
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
%             plotm(catalogObject.lat, catalogObject.lon, '*');
%         end
%% ---------------------------------------------------
        function bvalue(catalogObject, mcType)
            %BVALUE evaluate b-value, a-value and magnitude of completeness
            % of an earthquake catalog stored in a Catalog object.
            %
            % BVALUE(catalogObject, MCTYPE) produces a Gutenberg-Richter type plot 
            %    with the best fit line and display of b-,a-values and Mc 
            %    for catalogObject. MCTYPE is a number from 1-5 
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
                disp('Usage is: catalogObject.bvalue(mcType)')
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
            good_magnitude_indices = find(catalogObject.mag > -3.0);
            mag = catalogObject.mag(good_magnitude_indices);
            %MIN AND MAX MAGNITUDE IN catalogObject
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
            a0 = aw-log10((max(catalogObject.time)-min(catalogObject.time))/365);

            text(.53,.88, ['b-value = ',tt1,' +/- ',tt2,',  a value = ',num2str(aw,3)],'FontSize',12);
            text(.53,.85,sol_type,'FontSize',12 );
            text(.53,.82,['Magnitude of Completeness = ',tmc],'FontSize',12);
        end 
%% ---------------------------------------------------        
        %% SUBCLASSIFY
        function c = subclassify(catalogObject, subclasses)
            % Catalog.subclassify Split catalogObject into multiple
            % catalogObjects where each one contains only a single etype
            % (event type). THIS NEED CHANGING BECAUSE ETYPE IS NOW A CELL
            % ARRAY OF STRINGS
            
            catalogObjects = subclassify(catalogObject, subclasses)
            if strcmp(subclasses, '*')==0
                for i = 1:length(subclasses);
                    c(i) = catalogObject;
                    subclass = subclasses(i);
                    index = strfind(catalogObject.etype, subclass); % previously findstr
                    if numel(catalogObject.lat)==numel(catalogObject.etype)
                        c(i).lat = catalogObject.lat(index);
                        c(i).lon = catalogObject.lon(index);
                        c(i).depth = catalogObject.depth(index);
                    end
                    c(i).time = catalogObject.time(index);
                    c(i).mag = catalogObject.mag(index);
                    c(i).etype = catalogObject.etype(index);
                end
            end     
        end
%% ---------------------------------------------------         
        function erobj=eventrate(catalogObject, varargin)
            %catalogObject.eventrate    
            % Create an EventRate object from an Catalog object
            % object, with a binsize determined automatically.
            %   erobj = catalogObject.eventrate()
            %
            % Specify a binsize (in days):
            %   erobj = catalogObject.eventrate('binsize', 1/24)
            %
            % Specify a stepsize (in days). Must be <= stepsize.
            %   erobj = catalogObject.eventrate(..., 'stepsize',1/24) 
                         
            p = inputParser;
            p.addParamValue('binsize', 0, @isnumeric);
            p.addParamValue('stepsize', 0, @isnumeric);
            p.parse(varargin{:});
            binsize = p.Results.binsize;
            stepsize = p.Results.stepsize;
            
            for i=1:numel(catalogObject)
            
                if ~(binsize>0)
                    binsize = autobinsize(catalogObject(i));
                end
                if ~(stepsize>0)
                    stepsize = binsize;
                end      
                if (stepsize > binsize)
                   disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
                   return;
                end          
                if ~(binsize>0)
                    binsize = autobinsize(catalogObject(i).enum-catalogObject(i).snum);
                end
                if ~(stepsize>0)
                    stepsize = binsize;
                end      
                if (stepsize > binsize)
                   disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
                   return;
                end 

                % Find out how many event types we have
                etypes = unique(catalogObject(i).etype);      

                % bin the data
                [time, counts, energy, smallest_energy, ...
                    biggest_energy, median_energy, stdev, median_time_interval] = ...
                    bin_irregular(catalogObject(i).time, ...
                    magnitude.mag2eng(catalogObject(i).mag), ...
                    binsize, catalogObject(i).snum, catalogObject(i).enum, stepsize);

                % create the Event Rate object
                total_counts = length(catalogObject(i).time);
                numbins = numel(time);
                erobj(i) = EventRate(time, counts, energy, median_energy, ...
                    smallest_energy, biggest_energy, median_time_interval, total_counts, ...
                    catalogObject(i).snum, catalogObject(i).enum, etypes, binsize, stepsize, numbins);
            end
        end
%% --------------------------------------------------- 
        %% PLOT COUNTS / EVENTRATE
        function plot_counts(catalogObject)
            %Catalog.plot_counts Plot event counts - i.e. number of events
            %per unit time. See also the EventRate class.
            erobj = catalogObject.eventrate();
            erobj.plot()
        end
        
%% ---------------------------------------------------         
        %% PLOT Peak_rate and Max_mag
        function plotprmm(catalogObject)
            %Catalog.plotprmm Plot the peak rate and maximum magnitude of a
            %set of events
            figure
            symsize = get_symsize(catalogObject);            
            if all(isnan(catalogObject.mag))
                warning('No magnitude data to plot');
            else
                
                % plot magnitudes
                subplot(2,1,1), scatter(catalogObject.time, catalogObject.mag, symsize);
                %stem(catalogObject.time, catalogObject.mag);
                set(gca, 'XLim', [floor(catalogObject.snum) ceil(catalogObject.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Magnitude');
                grid on;
                
                % put 'MM' label by max mag event
                [mm, mmi] = max(catalogObject.mag);
                text(catalogObject.time(mmi), catalogObject.mag(mmi), 'MM','color','r');
                disp(sprintf('MM=%.1f occurs at %.1f%% of time series',mm,100*(catalogObject.time(mmi) - catalogObject.snum)/(catalogObject.enum-catalogObject.snum)));
                
                % plot event rate in 100 equal bins
                days = catalogObject.enum - catalogObject.snum;
                binsize = days/100;
                erobj = catalogObject.eventrate('binsize',binsize);
                subplot(2,1,2),plot(erobj.time, erobj.counts);
                set(gca, 'XLim', [floor(catalogObject.snum) ceil(catalogObject.enum)]);
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
        function catalogObject2 = subset(catalogObject, indices)
            %Catalog.subset Create a new catalogObject by subsetting based
            %on indices. 
            catalogObject2 = Catalog(catalogObject.time(indices), ...
                catalogObject.lon(indices), ...
                catalogObject.lat(indices), ...
                catalogObject.depth(indices), ...
                catalogObject.mag(indices), ...
                catalogObject.magtype(indices), ...
                catalogObject.etype(indices));
        end
        
%% ---------------------------------------------------

        function Event(obj, eventnum)
            % Catalog.Event - Browse an Catalog object one event at a time.
            %  catalogObject.Event() Browse through an Catalog object one event
            %  at a time in a similar way to the Seisan program 'eev'.

            
            if ~exist('eventnum','var')
                eventnum = 1;
            end

            while 1,
                
                % don't beyond start or end of this catalogObject object
                if eventnum<1
                    eventnum=1;
                end
                if eventnum>numel(obj.time)
                    eventnum=numel(obj.time);
                end           
                % display line for this event
                dstr=datestr(obj.time(eventnum),31);
                subclass=obj.etype{eventnum};
                mag=obj.mag(eventnum);
                outstr=sprintf('%s %7.2f %7.2f %7.2 %5.1f %s %s',dstr, obj.lon(eventnum), obj.lat(eventnum), obj.depth(eventnum), mag, obj.magtype{eventnum}, subclass);
                choice=input([outstr,':  ?'],'s');           
                
                % process choice
                if isempty(choice)
                    eventnum=eventnum+1; % ENTER goes to next event 

                elseif (choice(1)=='c') % CLASSIFY
                    classify_event(time);

                elseif (choice(1)=='f') % FORWARD N EVENTS
                    num=1;
                    if length(choice)>1
                        num=str2num(choice(2:end));
                    end
                    eventnum=eventnum+num; 

                elseif (choice(1)=='b') % BACKWARD N EVENTS
                    num=1;
                    if length(choice)>1
                        num=str2num(choice(2:end));
                    end
                    eventnum=eventnum-num;

                elseif (choice(1)=='t') % JUMP TO TIME
                    month=1;dd=1;hr=0;
                    if length(choice)>4
                        year=str2num(choice(2:5));
                    end
                    if length(choice)>6
                        month=str2num(choice(6:7));
                    end
                    if length(choice)>8
                        dd=str2num(choice(8:9));
                    end
                    if length(choice)>10
                        hr=str2num(choice(10:11));
                    end
                    jumptime=datenum(year,month,dd,hr,0,0);
                    eventnum = min(find(obj.time > jumptime));

                elseif (choice(1)=='s') % SUMMARISE - SHOW S FILE or similar data 
                    fprintf('\nTime:\t\t%s\n',dstr);
                    fprintf('Longitude:\t%7.2f degrees\n',obj.lon(eventnum));
                    fprintf('Latitude:\t%7.2f degrees\n',obj.lat(eventnum));
                    fprintf('Depth:\t\t%7.2f km\n',obj.depth(eventnum));
                    fprintf('Magnitude:\t%7.2f\n',obj.mag(eventnum));
                    fprintf('Magnitude Type:\t%s\n',obj.magtype{eventnum});
                    fprintf('Event Type:\t%s\n',obj.etype{eventnum});
                    fprintf('\n');

                elseif (choice(1)=='x') % CLOSE ALL
                    close all;

                elseif (choice=='q') % QUIT
                    break;

                elseif (choice(1)=='h') % HELP
                    disp(' ');
                    disp('Options:');
                    disp('________');
                    disp(' ');
                    disp('b[num]            - go backward 1 event (or N events)');
                    disp('c                 - classify');
                    %disp('e                 - edit/generate S-file');
                    disp('f[num]            - go forward 1 event (or N events)');
                    disp('h                 - this help');
                    %disp('p                 - plot');
                    disp('s                 - summarise');
                    disp('tYYYY[MM[DD[HH]]] - jump to date/hour specified');
                    disp('x                 - close all figure windows');
                    disp('q                 - quit');
                    disp(' ');
                end
            end
        end   
        
%% ---------------------------------------------------         
%         function eev(obj)
%             % Catalog.eev - Browse an Catalog object one event at a time.
% SAME AS EVENT FUNCTION EXCEPT ATTEMPTS TO USE SFILES TO LOAD WAVFILES
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
%         function w=towaveform(obj)
%             % WHAT THE HELL IS THIS - SOMETHING TO DO WITH SEISAN - PERHAPS
%             % I NEED NEW CLASS Catalog_SEISAN
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
       
        function write(catalogObject, outformat, outpath, schema)
            %Catalog.write Write an Catalog object to disk
            %
            % catalogObject.write('antelope', 'mydb', 'css3.0') writes the
            % catalogObject to a CSS3.0 database called 'mydb' using
            % Antelope. Requires Antelope and Antelope Toolbox. Support for
            % aefsam0.1 schema will be added later.
            % 
            % Support for other output formats, e.g. Seisan, will be added
            % later.
            
            % Glenn Thompson, 4 February 2015
 
            switch outformat
                case 'antelope'
                    
                    
                    if admin.antelope_exists
                        
                        dbpath = outpath;
            
                        % create new db
                        if ~exist('schema','var')
                            schema='css3.0';
                        end
                        dbcreate(dbpath, schema);
                        
                        system(sprintf('touch %s.event',dbpath));
                        system(sprintf('touch %s.origin',dbpath));

                        % open db
                        db = dbopen(dbpath, 'r+');
                        dbe = dblookup_table(db,'event');
                        dbo = dblookup_table(db,'origin');
                        dbn = dblookup_table(db,'netmag');

                        % write event to event and origin tables
                        if numel(catalogObject.time)>0
                            for eventidx = 1:numel(catalogObject.time)
                                event.evid = dbnextid(dbe,'evid');
                                origin.orid = dbnextid(dbo,'orid');
                                origin.time = datenum2epoch(catalogObject.time(eventidx));
                                origin.lon = catalogObject.lon(eventidx);
                                origin.lat = catalogObject.lat(eventidx);
                                origin.depth = catalogObject.depth(eventidx);
                                origin.etype = catalogObject.etype{eventidx};
                                
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
                                netmag.magtype = catalogObject.magtype{eventidx};
                                netmag.magnitude = catalogObject.mag(eventidx);
                                
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
        function binsize = autobinsize(catalogObject)
        %autobinsize Compute the best bin size based on start and end times
            binsize = autobinsize(max(catalogObject.time) - min(catalogObject.time));
        end
%% ---------------------------------------------------        
        function region = get_region(catalogObject, nsigma)
        % region Compute the region to plot based on spread of lon,lat data
			medianlat = nanmedian(catalogObject.lat);
			medianlon = nanmedian(catalogObject.lon);
			cosine = cos(medianlat);
			stdevlat = nanstd(catalogObject.lat);
			stdevlon = nanstd(catalogObject.lon);
			rangeindeg = max([stdevlat stdevlon*cosine]) * nsigma;
			region = [(medianlon - rangeindeg/2) (medianlon + rangeindeg/2) (medianlat - rangeindeg/2) (medianlat + rangeindeg/2)];
        end
        
%% ---------------------------------------------------
        function symsize = get_symsize(catalogObject)
            %get_symsize Get symbol marker size based on magnitude of event
            % Compute Marker Size
            minsymsize = 3;
            maxsymsize = 50;
            symsize = (catalogObject.mag + 2) * 10; % -2- -> 1, 1 -> 10, 0 -> 20, 1 -> 30, 2-> 40, 3+ -> 50 etc.
            symsize(symsize<minsymsize)=minsymsize;
            symsize(symsize>maxsymsize)=maxsymsize;
            % deal with NULL (NaN) values
            symsize(isnan(symsize))=minsymsize;
        end
%% ---------------------------------------------------                      
                
    end

end
