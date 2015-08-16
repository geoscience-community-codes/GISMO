classdef Catalog_base
%CATALOG_BASE: A base class that serves as a container for EVENT objects.
% This class is not to be used directly. Instead it is inherited by
% Catalog_lite and Catalog_full
%
%% See also Catalog_lite, Catalog_full, ReadCatalog, Event 
%
% Author: Glenn Thompson (glennthompson1971@gmail.com)
% $Date: $
% $Revision: $  
    properties(GetAccess = 'public', SetAccess = 'private')
        % properties set here cannot have getters defined on them in
        % subclasses
        dnum; % alias for time
        snum;
        enum;
    end
    properties(GetAccess = 'public', SetAccess = 'public')
        description;
        misc_fields = {};
        misc_values = {};
    end
    methods (Abstract)
        plus(cobj1, cobj2)
    end
    methods
%         function dnum = get.dnum(obj)
%             dnum = obj.time();
%         end
        function snum = get.snum(obj)
            snum = min(obj.time());
        end
        function enum = get.enum(obj)
            enum = max(obj.time());
        end
        %% ADDFIELD
        function cobj = addfield(cobj,fieldname,val)
            %ADDFIELD add fields and values to CATALOG object(s) 
            %   cobj = addfield(cobj, fieldname, value)
            %   This function creates a new user defined field, and fills it with the
            %   included value.  If fieldname exists, it will overwrite the existing
            %   value.
            %
            %   Input Arguments
            %       COBJ: a Catalog object   N-DIMENSIONAL
            %       FIELDNAME: a string name
            %       VALUE: a value to be added for those fields.  Value can be anything
            %
            %   CATALOG objects can hold user-defined fields.  To access the contents, 
            %   use Catalog/get.
            %
            %   Example:
            %       % add a field called "TESTFIELD", containing the numbers 1-45
            %       cobj = addfield(cobj,'TestField',1:45);
            %
            %       % add a cell field called "MISHMOSH"
            %       cobj = addfield(cobj,'mishmosh',{'hello';'world'});
            %
            %       % see the result
            %       disp(cobj) 
            %
            % See also CATALOG/SET, CATALOG/GET

            % AUTHOR: Glenn Thompson

            if isa(fieldname,'char')
                mask = strcmp(fieldname, properties(cobj));
                if any(mask)
                    cobj = cobj.set(fieldname, val);
                else
                    mask = strcmp(upper(fieldname),cobj.misc_fields);
                    if any(mask)
                        cobj = cobj.set(fieldname, val);
                    else
                        cobj.misc_fields = [cobj.misc_fields, upper(fieldname)];
                        cobj = cobj.set(upper(fieldname), val);
                    end
                end   
            else
                error('%s:addfield:invalidFieldname','fieldname must be a string', class(cobj))
            end

        end

        %% SET
        function cobj = set(cobj, varargin)
            %SET Set properties for Catalog object(s)
            %   cobj = set(cobj,'property_name', val, ['property_name2', val2])
            %   SET is one of the two gateway functions of an object, such as Catalog.
            %   Properties that are changed through SET are typechecked and otherwise
            %   scrutinized before being stored within the Catalog object.  This
            %   ensures that the other Catalog methods are all retrieving valid data,
            %   thereby increasing the reliability of the code.
            %
            %   Another strong advantage to using SET and GET to change and retrieve
            %   properties, rather than just assigning them to Catalog object directly,
            %   is that the underlying data structure can change and grow without
            %   harming the code that is written based on the Catalog object.
            %
            %   For a list of valid property names, type:
            %       properties(cobj)
            %   
            %   If user-defined fields were added to the Catalog object (ie, through
            %   addField), these fieldnames are also available through set.
            %
            %   Examples:
            %       (1) Change the description property
            %           cobj = cobj.set('description','hello world');
            %
            %       (2) Add new a field called CLOSEST_STATION with
            %           % the value 'MBLG'
            %           cobj = cobj.addfield('CLOSEST_STATION','MBLG');
            %
            %           % change the value of the CLOSEST_STATION field
            %           cobj = cobj.set('CLOSEST_STATION','MBWH');
            %
            %  See also CATALOG/GET

            Vidx = 1 : numel(varargin);

            while numel(Vidx) >= 2
                prop_name = upper(varargin{Vidx(1)});
                val = varargin{Vidx(2)};
                mask = strcmp(upper(prop_name),upper(properties(cobj)));
                if any(mask)
                    mc = metaclass(cobj);
                    i = find(mask);
                    prop_name = mc.PropertyList(i).Name;
                    if isempty(mc.PropertyList(i).GetMethod)
                        % The properties here need to have
                        % SetAccess==public
                        eval(sprintf('cobj.%s=val;',prop_name));
                        % This should work for SetAccess=private but
                        % actually causes a segmentation fault
                        %eval(sprintf('cobj = cobj.set(''%s'', val);',prop_name));
                    else
                        warning('Property %s is a derived property and cannot be set',prop_name);
                    end
                else
                    switch prop_name
                        case cobj.misc_fields
                            mask = strcmp(prop_name,cobj.misc_fields);
                            cobj.misc_values(mask) = {val};
                        otherwise
                            error('%s:set:unknownProperty',...
                                'can''t understand property name : %s', mfilename,prop_name);
                    end
                end
                Vidx(1:2) = []; %done with those parameters, move to the next ones...
            end 
        end 
        
        %% GET
        function val = get(cobj,prop_name)
            %GET Get Catalog properties
            %   val = get(Catalog_object,'property_name')
            %
            %   To see valid property names, type:
            %       properties(Catalog_object)
            %
            %       If additional fields were added to Catalog using ADDFIELD, then
            %       values from these can be retrieved using the fieldname
            %
            %       Example: Create a Catalog, get 'lon', add a field, then get the field
            %           cobj = Catalog;
            %           cobj = cobj.get('lon')
            %           cobj = cobj.addfield('closest_station', 'MBLG');
            %           cs = cobj.get('closest_station'); 
            %
            %   See also CATALOG/SET, CATALOG/ADDFIELD

            mask = strcmp(prop_name, properties(cobj));
            if any(mask)
                eval(sprintf('val=cobj.%s;',prop_name));
            else
                mask = strcmp(upper(prop_name),cobj.misc_fields);
                if any(mask)
                    val = cobj.misc_values{mask};
                else
                    warning('%s:get:unrecognizedProperty',...
                        'Unrecognized property name : %s',  class(cobj), prop_name);
                end
            end
        end
        
        %% PLOT
		function plot(cobj, varargin)
            %PLOT plot hypocenters in 3-D
            %   catlog_object.plot()
            %
            %   Optional name/value pairs:
            %     'nsigma' - controls how zoomed-in the axes are (default
            %     5)            
            
            % Glenn Thompson 2014/06/01
            if all(isnan(cobj.lat))
                warning('No hypocenter data to plot');
                return
            end
            p = inputParser;
            p.addParamValue('nsigma', '5', @isstr);
            p.parse(varargin{:});
            nsigma = p.Results.nsigma;
            
			% change region
            region = get_region(cobj, nsigma);
      
            % Compute Marker Size
            symsize = get_symsize(cobj);
      
			figure;
            set(gcf,'Color', [1 1 1]);
            
			% lon-lat plot
			axes('position',[0.05 0.45 0.5 0.5]);
            scatter(cobj.lon, cobj.lat, symsize);
			grid on;
            set(gca, 'XLim', [region(1) region(2)]);
            set(gca, 'YLim', [region(3) region(4)]);
			xlabel('Longitude');

			% depth-longitude
			axes('position',[0.05 0.05 0.5 0.35]);
            scatter(cobj.lon, cobj.depth, symsize);
			ylabel('Depth (km)');
			xlabel('Longitude');
			grid on;
			set(gca, 'YDir', 'reverse');
			set(gca, 'XLim', [region(1) region(2)]);

			% depth-lat
			axes('position',[0.6 0.45 0.35 0.5]);
            scatter(cobj.depth, cobj.lat, symsize);
			xlabel('Depth (km)');
			set(gca, 'XDir', 'reverse');
			ylabel('Latitude');
			grid on;
			set(gca, 'YLim', [region(3) region(4)]);

        end

        %% PLOT3
		function plot3(cobj, varargin)
            %PLOT3 plot hypocenters in 3-D
            %   catlog_object.plot3()
            %
            %   Optional name/value pairs:
            %     'nsigma' - controls how zoomed-in the axes are (default
            %     5)            
            
            % Glenn Thompson 2014/06/01
            if all(isnan(cobj.lat))
                warning('No hypocenter data to plot');
                return
            end
            p = inputParser;
            p.addParamValue('nsigma', '5', @isstr);
            p.parse(varargin{:});
            nsigma = p.Results.nsigma;            
            
			% change region
            region = get_region(cobj, nsigma);
      
            % Compute Marker Size
            symsize = get_symsize(cobj);
            
            % 3D plot
            figure
            set(gcf,'Color', [1 1 1]);
            scatter3(cobj.lon, cobj.lat, cobj.depth, symsize);
			set(gca, 'ZDir', 'reverse');
			grid on;
            set(gca, 'XLim', [region(1) region(2)]);
            set(gca, 'YLim', [region(3) region(4)]);
			xlabel('Longitude');
            ylabel('Latitude');
			zlabel('Depth (km)');
            
        end
        
        %% PLOT_TIME
        function plot_time(cobj); 
            %PLOT_TIME plot magnitude and depth against time
            %   catlog_object.plot_time()
            
            % Glenn Thompson 2014/06/01
            
            symsize = get_symsize(cobj);            

			% time-depth
            if all(isnan(cobj.depth))
                warning('No depth data to plot');
            else
                figure;
                set(gcf,'Color', [1 1 1]);
                subplot(2,1,1);
                scatter(cobj.time, cobj.depth, symsize);
                set(gca, 'XLim', [floor(cobj.snum) ceil(cobj.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Depth (km)');
                set(gca, 'YDir', 'reverse');
                grid on;
            
                % time-mag
                subplot(2,1,2);
            end
            if all(isnan(cobj.mag))
                warning('No magnitude data to plot');
            else
                scatter(cobj.time, cobj.mag, symsize);
                %stem(cobj.time, cobj.mag);
                set(gca, 'XLim', [floor(cobj.snum) ceil(cobj.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Magnitude');
                grid on;
            end
        end

                
        %% HELENAPLOT
        function helenaplot(obj)
            for c=1:length(obj)
                figure(gcf+1)
                set(gcf,'Color', [1 1 1]);
                [ax, h1, h2] = plotyy(obj(c).dnum, cumsum(obj(c).mag), obj(c).dnum, cumsum(obj(c).energy), @plot, @plot);
                datetick(ax(1), 'x','keeplimits');
                datetick(ax(2), 'x','keeplimits');
                set(ax(1), 'YLabel', 'Cumulative Magnitude');
                set(ax(2), 'YLabel', 'Cumulative Energy');
            end
        end
        
        
        %% OTHER MISC PLOTTING CODES
%         function mapexample(cobj)
%             % simple epicentral plot
%             latmin = min(cobj1.lat) - latrange/20;
% 			lonmin = min(cobj1.lon) - lonrange/20;
% 			latmax = max(cobj1.lat) + latrange/20;
% 			lonmax = max(cobj1.lon) + lonrange/20;
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
%             plotm(cobj.lat, cobj.lon, '*');
%         end
%%
        function bvalue(cobj, mcType)
            %BVALUE evaluate b-value, a-value and magnitude of completeness
            % of an earthquake catalog stored in a Catalog object.
            %
            % BVALUE(COBJ, MCTYPE) produces a Gutenberg-Richter type plot 
            %    with the best fit line and display of b-,a-values and Mc 
            %    for the catalog object COBJ. MCTYPE is a number from 1-5 
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
            good_magnitude_indices = find(cobj.mag > -3.0);
            mag = cobj.mag(good_magnitude_indices);
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
            a0 = aw-log10((max(cobj.time)-min(cobj.time))/365);

            text(.53,.88, ['b-value = ',tt1,' +/- ',tt2,',  a value = ',num2str(aw,3)],'FontSize',12);
            text(.53,.85,sol_type,'FontSize',12 );
            text(.53,.82,['Magnitude of Completeness = ',tmc],'FontSize',12);
        end 
        
        %% SUBCLASSIFY
        function c = subclassify(cobj, subclasses)
            % c = subclassify(cobj, subclasses)
            if strcmp(subclasses, '*')==0
                for i = 1:length(subclasses);
                    c(i) = cobj;
                    subclass = subclasses(i);
                    index = strfind(cobj.etype, subclass); % previously findstr
                    if numel(cobj.lat)==numel(cobj.etype)
                        c(i).lat = cobj.lat(index);
                        c(i).lon = cobj.lon(index);
                        c(i).depth = cobj.depth(index);
                    end
                    c(i).time = cobj.time(index);
                    c(i).mag = cobj.mag(index);
                    c(i).etype = cobj.etype(index);
                end
            end     
        end
        
        function erobj=eventrate(cobj, varargin)
            %eventrate    
            % Create an EventRate object from a Catalog
            % object, with a binsize determined automatically.
            %   erobj = cobj.eventrate()
            %
            % Specify a binsize (in days):
            %   erobj = cobj.eventrate('binsize', 1/24)
            %
            % Specify a stepsize (in days). Must be <= stepsize.
            %   erobj = cobj.eventrate(..., 'stepsize',1/24) 
                         
            p = inputParser;
            p.addParamValue('binsize', 0, @isnumeric);
            p.addParamValue('stepsize', 0, @isnumeric);
            p.parse(varargin{:});
            binsize = p.Results.binsize;
            stepsize = p.Results.stepsize;
            
            for i=1:numel(cobj)
            
                if ~(binsize>0)
                    binsize = autobinsize(cobj(i));
                end
                if ~(stepsize>0)
                    stepsize = binsize;
                end      
                if (stepsize > binsize)
                   disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
                   return;
                end          
                if ~(binsize>0)
                    binsize = autobinsize(cobj(i).enum-cobj(i).snum);
                end
                if ~(stepsize>0)
                    stepsize = binsize;
                end      
                if (stepsize > binsize)
                   disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
                   return;
                end 

                % Find out how many event types we have
                etypes = unique(cobj(i).etype);      

                % bin the data
                [dnum, counts, energy, smallest_energy, ...
                    median_energy, std, median_time_interval] = ...
                    matlab_extensions.bin_irregular(cobj(i).time, ...
                    magnitude.mag2eng(cobj(i).mag), ...
                    binsize, cobj(i).snum, cobj(i).enum, stepsize);

                % create the Event Rate object
                total_counts = length(cobj(i).dnum);
                numbins = numel(dnum);
                erobj(i) = EventRate(dnum, counts, energy, median_energy, ...
                    smallest_energy, median_time_interval, total_counts, ...
                    cobj(i).snum, cobj(i).enum, etypes, binsize, stepsize, numbins);
            end
        end

        %% PLOT COUNTS / EVENTRATE
        function plot_counts(cobj)
            erobj = cobj.eventrate();
            erobj.plot()
        end
        
        
        %% PLOT Peak_rate and Max_mag
        function plotprmm(cobj)
            figure
            symsize = get_symsize(cobj);            
            if all(isnan(cobj.mag))
                warning('No magnitude data to plot');
            else
                
                % plot magnitudes
                subplot(2,1,1), scatter(cobj.time, cobj.mag, symsize);
                %stem(cobj.time, cobj.mag);
                set(gca, 'XLim', [floor(cobj.snum) ceil(cobj.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Magnitude');
                grid on;
                
                % put 'MM' label by max mag event
                [mm, mmi] = max(cobj.mag);
                text(cobj.time(mmi), cobj.mag(mmi), 'MM','color','r');
                disp(sprintf('MM=%.1f occurs at %.1f%% of time series',mm,100*(cobj.time(mmi) - cobj.snum)/(cobj.enum-cobj.snum)));
                
                % plot event rate in 100 equal bins
                days = cobj.enum - cobj.snum;
                binsize = days/100;
                erobj = cobj.eventrate('binsize',binsize);
                subplot(2,1,2),plot(erobj.dnum, erobj.counts);
                set(gca, 'XLim', [floor(cobj.snum) ceil(cobj.enum)]);
                datetick('x');
                xlabel('Date');
                ylabel('Event Rate');
                grid on; 
                
                % put 'PR' label by peak-rate
                [pr, pri] = max(erobj.counts);
                text(erobj.dnum(pri), erobj.counts(pri), 'PR','color','r');               
                disp(sprintf('PR=%d occurs at %.1f%% of time series',pr,100*(erobj.dnum(pri) - erobj.snum)/(erobj.enum-erobj.snum)));
            end
        end
        
        %% EEV
        function eev(obj)
            % eev - Browse through a catalog. Based on the Seisan program of the same name
            PRETRIGGER = 10/86400;
            POSTTRIGGER = (60+10)/86400;
            eventnum = 1;

            while 1,
                
                % don't beyond start or end of this catalog object
                if eventnum<1
                    eventnum=1;
                end
                if eventnum>numel(obj.time)
                    eventnum=numel(obj.time);
                end           
                % display line for this event
                dstr=datestr(obj.time(eventnum),31);
                subclass=obj.etype(eventnum);
                mag=obj.mag(eventnum);
                outstr=sprintf('%s %s %5.2f',dstr,subclass,mag);
                choice=input([outstr,':  ?'],'s');           
                
                % process choice
                if isempty(choice)
                    eventnum=eventnum+1; % ENTER goes to next event 

                elseif (choice(1)=='c') % CLASSIFY
                    classify_event(time);

                elseif (choice(1)=='p') % PLOT
%                     if strcmp(get(obj,'method'), 'import_aef_file')
%                         % AEF SUMMARY FILE FOR MBWH
%                         dnum = obj.dnum(eventnum);
%                         sfilename = dnum2sfile(dnum);
%                         % read the sfile
%                         sfile = readCatalog.read_sfile(fullfile('/raid','data','seisan','MVOE_','REA'), sfilename,'*','*')
% %                         wavfiles = {sfile(1).wavfiles};
% %                         wavpath = fullfile('/raid','data','seisan','MVOE_', 'WAV', sprintf('%04d', wavfiles{1})
% %                         ds = datasource('seisan', wavpath)
% %                         w = waveform(ds, scnl, dnum-PRETRIGGER, dnum+POSTTRIGGER);
%                     end    
                    if strcmp(get(obj,'method'), 'load_seisandb')
                        % SEISAN FILE
                        scnl = scnlobject('*', '*');
                        ds = get(obj, 'datasource');
                        sfile = get(obj, 'sfile');

                        wavfiles = {sfile(eventnum).wavfiles};
                        yyyy = sfile(eventnum).year;
                        mm = sfile(eventnum).month;
                        dnum = sfile(eventnum).dnum;
                        dbpath = get(obj, 'dbpath');
                        dbpath = strrep(dbpath, 'REA', 'WAV');
                        for i=1:numel(wavfiles)
                            wavpath = fullfile(dbpath, sprintf('%04d', yyyy), sprintf('%02d', mm), wavfiles{i});
                            if ~exist(wavpath, 'file')
                                dbpath = strrep(dbpath, 'WAV', 'WAV2');
                                wavpath = fullfile(dbpath, sprintf('%04d', yyyy), sprintf('%02d', mm), wavfiles{i});
                            end
                            disp(sprintf('Loading %s',wavpath));
                            ds = datasource('seisan', wavpath);
                            datestr(dnum)
                            w = waveform(ds, scnl, dnum-PRETRIGGER, dnum+POSTTRIGGER);
                        end
                        if exist('w','var')
                            mulplt(w);
                        end
                    end

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
                    jumpdnum=datenum(year,month,dd,hr,0,0);
                    eventnum = min(find(obj.dnum > jumpdnum));

                elseif (choice(1)=='s') % SUMMARISE - SHOW S FILE or similar data 
                    try
                        s = get(obj, 'sfile');
                        disp(s(eventnum));                 
                    catch
                        disp('No Sfile');
                    end

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
                    disp('e                 - edit/generate S-file');
                    disp('f[num]            - go forward 1 event (or N events)');
                    disp('h                 - this help');
                    disp('p                 - plot');
                    disp('s                 - summarise');
                    disp('tYYYY[MM[DD[HH]]] - jump to date/hour specified');
                    disp('x                 - close all figure windows');
                    disp('q                 - quit');
                    disp(' ');
                end
            end
        end   
        
        %% WRITE CATALOG TO AN ANTELOPE/DATASCOPE css3.0 or aefsam0.1 DATABASE
        function toDatascope(cobj, dbpath, schema)
            % toDatascope Write a Catalog object to a CSS3.0 or aefsam0.1
            %   database. Requires Antelope and Antelope Toolbox for MATLAB
            % Usage: cobj.toDatascope('/home/t/thompson/mydb')
            % 
            % Glenn Thompson, 4 February 2015
            
            % create new db
            if ~exist('schema','var')
                schema='css3.0';
            end
            system(sprintf('dbcreate -s %s %s',schema, dbpath));
            system(sprintf('touch %s.event',dbpath));
            system(sprintf('touch %s.origin',dbpath));
            
            % open db
            db = dbopen(dbpath, 'r+');
            dbe = dblookup_table(db,'event');
            dbo = dblookup_table(db,'origin');

            % write event
            if numel(cobj.event_list)>0
                % long
                for eventidx = 1:numel(cobj.event_list)
                    evid = dbnextid(dbe,'evid');
                    for originidx = 1:numel(cobj.event_list(eventidx).origins)
                        % write origin record
                        orid = dbnextid(dbo,'orid');
                        dbo.record = dbaddnull(dbo);
                        thisorigin = cobj.event_list(eventidx).origins(originidx);
                        thisorigin.evid = evid; % force the evid to be consistent
                        thisorigin.orid = orid;
                        fieldlist = fields(thisorigin);
                        for fieldindex = 1:numel(fieldlist)
                            thisfield = fieldlist{fieldindex};
                            eval(sprintf('thisvalue = thisorigin.%s;',thisfield));
                            if strcmp(thisfield,'time')
                                thisvalue=datenum2epoch(thisvalue);
                            end
                            if isnumeric(thisvalue)
                                if ~isnan(thisvalue)
                                    if numel(thisvalue)==1
                                        try
                                            dbputv(dbo, thisfield, thisvalue);
                                        catch ME
                                            thisfield, thisvalue
                                            ME
                                        end
                                    end
                                end
                            elseif strcmp(class(thisvalue),'char')
                                if ~isempty(thisvalue)
                                    try
                                        dbputv(dbo, thisfield, thisvalue);
                                    catch ME
                                        thisfield, thisvalue
                                        ME
                                    end
                                end
                            end
                        end
                    end
                    
                    % write event record
                    dbe.record = dbaddnull(dbe);
                    thisevent = cobj.event_list(eventidx);
                    thisevent.evid = evid;
                    if isnan(thisevent.prefor)
                        thisevent.prefor = orid;
                    end
                    fieldlist = fields(thisevent);
                    for fieldindex = 1:numel(fieldlist)
                        thisfield = fieldlist{fieldindex};
                        eval(sprintf('thisvalue = thisevent.%s;',thisfield));
                        if isnumeric(thisvalue)
                            if ~isnan(thisvalue)
                                if numel(thisvalue)==1
                                    try
                                        dbputv(dbe, thisfield, thisvalue);
                                    catch ME
                                        ME
                                        thisfield, thisvalue
                                    end
                                end
                            end
                        elseif strcmp(class(thisvalue),'char')
                            if ~isempty(thisvalue)
                                try
                                    dbputv(dbe, thisfield, thisvalue);
                                catch ME
                                    ME
                                    thisfield, thisvalue
                                end
                            end
                        end
                    end      
                end
            end
            dbclose(db);
        end
        
    end

    methods (Access=protected, Hidden=true)
        
        %% AUTOBINSIZE        
        function binsize = autobinsize(cobj)
            binsize = autobinsize(cobj.enum - cobj.snum);
        end
        
        %%
        function region = get_region(cobj, nsigma)
			medianlat = nanmedian(cobj.lat);
			medianlon = nanmedian(cobj.lon);
			cosine = cos(medianlat);
			stdevlat = nanstd(cobj.lat);
			stdevlon = nanstd(cobj.lon);
			rangeindeg = max([stdevlat stdevlon*cosine]) * nsigma;
			region = [(medianlon - rangeindeg/2) (medianlon + rangeindeg/2) (medianlat - rangeindeg/2) (medianlat + rangeindeg/2)];
        end
        
        %%
        function symsize = get_symsize(cobj)
            % Compute Marker Size
            minsymsize = 3;
            maxsymsize = 50;
            symsize = (cobj.mag + 2) * 10; % -2- -> 1, 1 -> 10, 0 -> 20, 1 -> 30, 2-> 40, 3+ -> 50 etc.
            symsize(symsize<minsymsize)=minsymsize;
            symsize(symsize>maxsymsize)=maxsymsize;
            % deal with NULL (NaN) values
            symsize(isnan(symsize))=minsymsize;
        end
        
    end
end
