classdef EventRate
%EventRate Event Rate class constructor.
% 
%    EventRate is a class that has been developed around plotting earthquake
%    counts - i.e. the rate of events per unit time. It has evolved to compute
%    other metrics such the hourly mean event rate, median event rate, mean 
%    magnitude and cumulative magnitude, which are important metrics for an AVO
%    swarm tracking system.
%
%    EventRate can import information from:
%    (1) a Catalog object. 
%    (2) a Datascope database written in the "swarms1.0" schema, defined at AVO. 
%        This is the format used by the swarm tracking system (Thompson &
%        West, 2010).
%
%    ER = EventRate(Catalog_OBJECT, 'binsize', BINSIZE) creates an eventrate object
%    from a Catalog object using non-overlapping bins of BINSIZE days. 
%
%    ER = EventRate(Catalog_OBJECT, 'binsize', BINSIZE, 'stepsize', STEPSIZE) creates an eventrate object
%    using overlapping bins. If omitted STEPSIZE==BINSIZE.
%
%%   EXAMPLES:
%
%       First create a catalog object from the demo database:
%           dbpath = demodb('avo')
%           catalogObject = readEvents('datascope', 'dbpath', dbpath, ...
%                  'dbeval', ...
%                  'deg2km(distance(lat, lon, 60.4853, -152.7431))<15.0' ...
%                  );
%
%       (1) Create an eventrate object using a binsize of 1 day:
%           erobj = catalogObject.eventrate('binsize', 1);
%
%       (2) Create an eventrate object using a binsize of 1 hour:
%           erobj = catalogObject.eventrate('binsize', 1/24);
%
%       (3) Create an eventrate object using a binsize of 1 hour but a stepsize of 5 minutes:
%           erobj = catalogObject.eventrate('binsize', 1/24, 'stepsize', 5/1440);
%
%       (4) Create a vector of eventrate objects subclassified using event types 'r', 'e', 'l', 'h', 't':
%               erobj = eventrate(catalogObject, 1, 'etypes', 'relht');
%           To plot counts on separate figures:
%               erobj.plot()
%           To plot counts and energy panels, each event type as a separate figure:
%               erobj.plot('metric', {'counts';'energy'});
%           To plot counts and energy panels on separate figures, each event type as panels:
%               erobj.plot('metric', {'counts';'energy'}, 'plotmode', 'panels'); 
%           To plot counts and energy panels on separate figures, each event type stacked:
%               erobj.plot('metric', {'counts';'energy'}, 'plotmode', 'stacked');
%
%       (5) A full example:
%               catalogObject = catalog(fullfile(MVO_DATA, 'mbwh_catalog'), 'seisan', 'snum', datenum(1996,10,1), 'enum', datenum(2004,3,1), 'region', 'Montserrat')
%               erobj = eventrate(catalogObject, 365/12, 'stepsize', 1, 'etypes', 'thlr');
%               erobj.plot('metric', {'counts';'energy'}, 'plotmode', 'stacked');
%
%
%%   PROPERTIES
%
%    For a list of all properties type properties(EventRate)
%
%    time                % (array) time of the center of each bin as a DATENUM
%
%    METRICS:
%        counts 		     % (array) number of events in each bin
%        mean_rate           % (array) number of events per hour in each bin
%        median_rate	     % (array) reciprocal of the median time interval between events. Represented as an hourly rate.
%        cum_mag		     % (array) total sum of energy in each bin, represented as a magnitude.
%        mean_mag		     % (array) mean magnitude of events in each bin 
%        median_mag          % (array) median magnitude of events in each bin
%        min_mag             % (array) smallest magnitude in each bin
%        max_mag             % (array) largest magnitude in each bin
%
%    SUMMARY DATA:
%        numbins             % (scalar) number of bins used for grouping
%                                events
%        total_counts        % (scalar) sum of counts
%        total_mag           % (scalar) total sum of energy of all catalogObjects, represented as a magnitude
%
%    METADATA:
%        etype               % event type/classification. 
%        snum                % (scalar) start date/time in DATENUM format
%        enum                % (scalar) end date/time in DATENUM format
%        binsize             % (scalar) bin size in days
%        stepsize            % (scalar) step size in days
%        region              % (4-element vector) [minlon maxlon minlat maxlat]
%        minmag              % (scalar) magnitudes smaller than this were eliminated
%        dbroot              % path to the original data on disk
%        archiveformat       % indicates if the source is a flat file, or
%                              'daily' or 'monthly' volumes
%        auth                % auth of the events
%
%%   METHODS
%
%    For a list of all methods type methods EventRate 
%
%
%%   See also Catalog, Catalog_lite
%
%% AUTHOR: Glenn Thompson

% $Date: 2014-05-06 14:52:40 -0800 (Tue, 06 May 2014) $
% $Revision: 404 $

%% PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties(GetAccess = 'public', SetAccess = 'public')
        time = [];          % (array) in datenum format
        counts = []; 		% (array) number of events in each bin
		mean_rate = [];      % (array) number of events per hour in each bin
		median_rate = [];	% (array) reciprocal of the median time interval between events. Represented as an hourly rate.
		cum_mag = [];		% (array) total sum of energy in each bin, represented as a magnitude.
		mean_mag = [];		% (array)   
        median_mag = [];     % (array)
        energy = [];
        total_counts = [];   % (scalar) sum of counts
		total_mag = [];      % (scalar) total sum of energy of all catalogObjects, represented as a magnitude	
        numbins = [];        % (scalar)
        min_mag = [];
        max_mag = [];
        etype = '*';
        snum = 0;
        enum = now;
        binsize = 1;
        stepsize = 1;
        misc_fields = {};
        misc_values = {};
    end
    
 %% PUBLIC METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
	methods
        %% CONSTRUCTOR
        function self = EventRate(time, counts, energy, median_energy, ...
                smallest_energy, biggest_energy, median_time_interval, total_counts, ...
                snum, enum, etypes, binsize, stepsize, numbins)
            self.time = time;
            self.counts = counts;          
            self.median_rate = 1 ./ (median_time_interval * 24); 
            self.median_rate(counts<10) = 0;
            self.median_rate = max([self.counts / (24 * binsize); self.median_rate]);      
            self.median_mag = magnitude.eng2mag(median_energy);
            self.energy = energy;
            self.total_counts = total_counts;  	
            self.numbins = numbins;
            self.min_mag = magnitude.eng2mag(smallest_energy);
            self.max_mag = magnitude.eng2mag(biggest_energy);
            self.etype = etypes;
            self.snum = snum;
            self.enum = enum;
            self.binsize = binsize;
            self.stepsize = stepsize;
        end
        
        %% ----------------------------------------------
        %% GETTERS
        function cum_mag = get.cum_mag(erobj)
            cum_mag = magnitude.eng2mag(erobj.energy);
        end
        function mean_mag = get.mean_mag(erobj)
            mean_mag = magnitude.eng2mag(erobj.energy./erobj.counts);
        end
        function mean_rate = get.mean_rate(erobj)
            mean_rate = erobj.counts / (24 * erobj.binsize);
        end
        function total_mag = get.total_mag(erobj)
            total_mag = magnitude.eng2mag(sum(erobj.energy));
        end
       
        function plot(obj, varargin) 
            %EventRate/plot
            %   Plot metrics of an EventRate object
            %
            %   The following metrics are available:
            %  
            %        counts 		     % number of events in each bin
            %        mean_rate           % number of events per hour in each bin
            %        median_rate	     % reciprocal of the median time interval between events. Represented as an hourly rate.
            %        energy              % total sum of energy in each bin
            %        cum_mag		     % total sum of energy in each bin, represented as a magnitude.
            %        mean_mag		     % mean magnitude of events in each bin 
            %        median_mag          % median magnitude of events in each bin
            %        min_mag             % smallest magnitude in each bin   
            %
            %   erobj.plot() or plot(erobj) will produce a plot of event
            %   counts per unit time. The time unit is given by erobj.binsize
            %   days.
            %   
            %   erobj.plot('metric', list_of_metrics) will plot each metric
            %   requested in list_of_metrics in a separate panel.
            %   list_of_metrics should be a cell array of valid metric
            %   strings. However, it may be a string if only one metric is
            %   requested.
            %
            %   erobj.plot('metric', 'counts') is equivalent to
            %   erobj.plot() and erobj.plot('metric', {'counts'})
            %
            %   erobj.plot('metric', 'mean_rate') is similar, but the
            %   mean_rate is always events per hour, regardless of the
            %   binsize. So if erobj.binsize = 1 (day), counts will be
            %   exactly 24 * mean_rate.
            %
            %   erobj.plot('metric', {'counts';'cum_mag'}) will plot counts
            %   in one panel and the cumulative magnitude per bin in
            %   another panel. 
            %
            %   In general any number of metrics can be given in
            %   list_of_metrics.
            %
            %   If erobj is an array of eventrate structures (e.g. one per
            %   etype), each is plotted on a separate figure. However the 
            %   plotmode variable overrides this:
            % 
            %     plot(eventrate_vector, 'plotmode', 'panels') will plot them
            %     in separate panels on the same figure
            % 
            %     plot(eventrate_vector, 'plotmode', 'single') will plot them
            %     in a single panel
            
            p = inputParser;
            p.addParamValue('metric', {'counts'}, @(c) iscell(c)||isstr(c));
            p.addParamValue('plotmode', 'figures', @isstr);
            p.addParamValue('smooth', 1, @isnumeric);
            p.parse(varargin{:});
            metric = p.Results.metric;
            plotmode = p.Results.plotmode;
            smoothbins = p.Results.smooth; % NOT DOING ANYTHING WITH THIS YET BUT COULD SMOOTH COUNTS OVER SEVERAL BINS
            if ~iscell(metric)
                metric = {metric};
            end
            numMetrics = numel(metric);
            colors = {[0 0.5 0] [0 0 1]};

            % plot each etype on a separate figure, each metric as a
            % subplot
           
            if strcmp(plotmode, 'figures') || length(obj)==1
            
                for c = 1 : numel(obj)
                    binsize_str = Catalog.binning.binsizelabel(obj(c).binsize);
                    numsubplots = length(metric);
                    %figure(gcf+1)
                    figure
                    set(gcf,'Color', [1 1 1]);
                    for cc = 1: numsubplots % number of metrics to plot
                        %eval(  sprintf('data = obj(c).%s;',metric{cc} ) );
                        data = obj(c).(metric{cc});
                        % replace -Inf values as they mess up plots
                        ydata = data; % ydata is the data we will plot, but we keep data for cumulative energy etc.
                        if smoothbins > 1
                            ydata = smooth(ydata, smoothbins);
                        end
                        ydata(isinf(data))=NaN;
                        mindata = nanmin(ydata); 
                        ydata(isnan(ydata))=mindata; % we replace NaNs and Infs in data with nanmin(data) in ydata
                        if (obj(c).binsize == obj(c).stepsize) & ( strcmp(metric{cc}, 'counts') | strcmp(metric{cc}, 'energy') | strcmp(metric{cc}, 'cum_mag') )
                            if strfind(metric{cc}, 'mag')
                                cumdata = magnitude.eng2mag(cumsum(magnitude.mag2eng(data)));           
                                subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(obj(c).time, ydata, obj(c).time, cumdata, @stairs, @plot );
                                set(h1, 'Color', colors{1});
                            else
                                %subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(obj(c).time, data, obj(c).time, cumsum(data), @bar, @plot );
                                subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(obj(c).time, ydata, obj(c).time, cumsum(data), @stairs, @plot );
                                %set(h1, 'FaceColor', colors{1}, 'EdgeColor', colors{1})
                                %set(h1, 'BarWidth', 1);
                                %set(h1, 'LineWidth', 0.1);
                            end
                            datetick(ax(1), 'x','keeplimits');
                            title(ax(1), metric2label(metric{cc}, obj(c).binsize), 'Color', colors{1}, 'FontSize',12)
                            datetick(ax(2), 'x','keeplimits');
                            ylabel(ax(2),'Cumulative', 'Color', colors{2}, 'FontSize',12)
                            set(h1, 'Color', colors{1});
                            set(h2, 'Color', colors{2}, 'LineWidth', 2);
                            set(ax(1), 'YColor', colors{1});
                            set(ax(2), 'YColor', colors{2});
                            linkaxes(ax, 'x');
                        else

                            if strfind(metric{cc}, 'mag')           
                                subplot(numsubplots,1,cc), stairs(obj(c).time, ydata, 'Color', colors{1});
                            else
                                %subplot(numsubplots,1,cc), bar(obj(c).time, data, 'FaceColor', colors{1}, 'EdgeColor', colors{1}, 'BarWidth', 1, 'LineWidth', 0.1);
                                subplot(numsubplots,1,cc), stairs(obj(c).time, ydata, 'Color', colors{1});
                            end
                            datetick('x','keeplimits');
                            title(metric2label(metric{cc}, obj(c).binsize), 'FontSize',12)                        
                        end
                        axis tight;
                    end
                end
                
                %% FROM HERE ON THE PLOTMODES HAVE NOT BEEN UPDATED
            elseif strcmp(plotmode, 'panels')
                % Each metric on a separate figure, showing all requested 
                % subclasses on separate panels
                  for c = 1 : numel(metric)
                    figure(gcf+c)
                    
                    numsubplots = length(obj);

                    for cc = numsubplots: -1: 1
                        if strcmp(metric{c},'energy')
                            %data = cumsum(magnitude.mag2eng(obj(cc).cum_mag));
                            data = (magnitude.mag2eng(obj(cc).cum_mag));

                        else
                            % eval(  sprintf('data = obj(cc).%s;',metric{c} ) );
                            data = obj(cc).(metric{c});
                        end
                        if smoothbins > 1
                            data = smooth(data, smoothbins);
                        end                      
                        % where to position the axes
                        pos(1) = 0.1;
                        pos(2) = 0.1+(0.95-0.1)*(cc-1)/numsubplots;
                        pos(3) = 0.8;
                        pos(4) = (0.8*(0.95-0.1)/numsubplots);
                        axes('position', pos);
                        
                        % plot
                        bar( obj(cc).time, data, 'EdgeColor', 'none', 'FaceColor', [0 0 0] );
%                         hold on;
%                         sdata = smooth(data, 30, 'lowess');
%                         plot( obj(cc).time, sdata, 'k-', 'linewidth', 2);
                        
                        
                        % range and label
                        datetick('x','keeplimits');
                        set(gca, 'XLim', [obj(cc).snum obj(cc).enum]);
                        ymax = nanmax(catmatrices(1, data));
%                         ymax = min([max(sdata)*2 max(data)*1.01]);
                        set(gca, 'YLim', [0 ymax]);
                        ylabel(obj(cc).etype);
                        
                        
                        
                    end
                    %suptitle(metric{c});
                    fprintf('metric for figure %d is %s\n', gcf, metric{c});
                  end               
                
                  
            elseif strcmp(plotmode, 'single')
                  % Each metric on a separate figure, showing all requested
                  % subclasses on the same panel
                  colour = 'rgbcm';
                  for c = 1 : numel(metric)
                    figure(gcf+c)

                    for cc = 1: length(obj)
                        if strcmp(metric{c},'energy')
                            %data = cumsum(magnitude.mag2eng(obj(cc).cum_mag));
                            data = (magnitude.mag2eng(obj(cc).cum_mag));
                        else
                            % eval(  sprintf('data = obj(cc).%s;',metric{c} ) );
                            data = obj(cc).(metric{c});
                        end
                        
                        if smoothbins > 1
                            data = smooth(data, smoothbins);
                        end    
                        
                        plot( obj(cc).time, data, sprintf('-%c',colour(cc)) );
                        hold on;
                        datetick('x','keeplimits');
                        set(gca, 'XLim', [obj(cc).snum obj(cc).enum]);
                        %ymax = nanmax(catmatrices(1, data));
                        %set(gca, 'YLim', [0 ymax]);
                        %ylabel(obj(cc).etype);
                    end
                    suptitle(metric{c});
                  end         
                
                  
             elseif strcmp(plotmode, 'stacked')
                 % Each metric on a separate figure, showing all subclasses
                 % stacked on the same panel
                  colour = 'rgbcm';
                  for c = 1 : numel(metric)
                    figure(gcf+c)
                    data =[];
                    for cc = 1: length(obj)
                        if strcmp(metric{c},'energy')
                            data = (magnitude.mag2eng(obj(cc).cum_mag));
                        else
                            %eval(  sprintf('data(:,cc) = obj(cc).%s;',metric{c} ) );
                            data(:,cc) = obj(cc).(metric{c});
                            if findstr(metric{c}, 'mag')
                                disp('Warning: It is meaningless to stack magnitude data');
                                data(data<0)=0;
                                data(isnan(data))=0;
                            end
                        end
                        if smoothbins > 1
                            data = smooth(data, smoothbins);
                        end    
                    
                        %bar( obj(cc).time, data, 1, 'stack' );
                        area(obj(cc).time, data);
                        datetick('x','keeplimits');
                        set(gca, 'XLim', [obj(cc).snum obj(cc).enum]);
                        suptitle(metric{c});
                    end
                end               
            end        
        end

        %% PYTHONPLOT
        function pythonplot(obj)
            obj.plot('metric', {'counts';'cum_mag'});
        end
        
        %% HELENAPLOT
        function helenaplot(obj)
            for c=1:length(obj)
                figure
                set(gcf,'Color', [1 1 1]);
                cumcummag = magnitude.eng2mag(cumsum(magnitude.mag2eng(obj(c).cum_mag)));
                [ax, h1, h2] = plotyy(obj(c).time, cumcummag, obj(c).time, cumsum(obj(c).energy), @plot, @plot);
                datetick(ax(1), 'x','keeplimits');
                datetick(ax(2), 'x','keeplimits');
                ylabel(ax(1), 'Cumulative Magnitude', 'FontSize',12);
                ylabel(ax(2), 'Cumulative Energy', 'FontSize',12);
            end
        end

        
        function pvalue(obj)
            logt = log10(obj.time-obj.time(1));
            logc = log10(obj.counts);
            plot(logt, logc);
            p = logt \ logc'
%             p = polyfit(logt, logc, 1)
%             hold on
%             logt1 = min(logt);
%             logc1 = polyval(p, logt1);
%             logt2 = max(logt);
%             logc2 = polyval(p, logt2);  
%             line([logt1 logt2], [logc1 logc2]);
        end
            
            
        %% SAUSAGEPLOT
        function sausageplot(obj, numBinsToUse, varargin)
            %sausageplot
            %    Under development, this function attempts to replicate the
            %    capabilities of sausageplot.xpy written by Glenn Thompson
            %    at AVO.
            p = inputParser;
            p.addRequired('numBinsToUse', @isnumeric);
            p.addOptional('numPoints', 1, @isnumeric);
            p.addOptional('radii', [], @isnumeric);
            p.parse(numBinsToUse, varargin{:});
            numBinsToUse = p.Results.numBinsToUse;
            numPoints = p.Results.numPoints;
            radii = p.Results.radii;
%             % Page size, dots-per-inch and scale settings
%             fh = figure()
%             if numBinsToUse > NUMPOINTS
%                 dpi = 6*(numBinsToUse+1);
%                 axes_width = 0.8 * (NUMPOINTS + 1) / (numBinsToUse + 1);
%                 axes_height = 0.8;
%             else
%                 dpi = 6*(NUMPOINTS+1);
%                 axes_width = 0.8;
%                 axes_height = 0.8 * (numBinsToUse + 1) / (NUMPOINTS + 1);
%             end
%             fh.set_dpi(dpi)
%             fh.set_size_inches((10.0,10.0),forward=True)
%             fig2ax1 = fig2.add_axes([0.1, 0.85-axes_height, axes_width, axes_height]);
%             print_pixels(fig2, fig2ax1, numBinsToUse, NUMPOINTS);
%             colormapname = 'hot_r';
            MAXMAGCOLORBAR = 5.0;
            MINMAGCOLORBAR = 1.0;
            % Marker size configuration
%             SCALEFACTOR = 84.0 / dpi;
%             MAXMARKERSIZE = 43.0 * SCALEFACTOR;
%             MINMARKERSIZE = 4.0 * SCALEFACTOR;
            PTHRESHOLD = 50;
            for c = 1:length(obj)
                % set up weekending list for yticklabels
                binendstr = {};
                for bin_index=numel(obj.time)-numBinsToUse+1: numel(obj.time)
                    bin_index
                    dstr = datestr(obj.time(bin_index))
                    binendstr{bin_index} = dstr;
                end
                pointlabels = {};
                for i=1:length(numPoints)
                    % filter here based on points and radii
                    j = 1:length(obj(c).counts); % replace this
                    counts = obj(c).counts(j);
                    cummag = obj(c).cum_mag(j);
                    prcntile = percentiles(obj(c).counts);
                    %pointlabels{i} = sprintf('%s(%d)', point_label{i}, counts(-1));
                    pointlabels{i}='';
                    for bin_index=numel(obj.time)-numBinsToUse+1: numel(obj.time)%-numBinsToUse-1: 1: 0
                        y = obj(c).counts(bin_index);
                        magnitude = obj(c).cum_mag(bin_index);
                        p = y2percentile(y,prcntile);
                        if y>0
                            colorVal = scalarMap.to_rgba(magnitude)
                            msize = MINMARKERSIZE + (p-PTHRESHOLD) * (MAXMARKERSIZE - MINMARKERSIZE) / (100-PTHRESHOLD);
                            if msize<MINMARKERSIZE
                                msize=MINMARKERSIZE;
                            end
%                             fig2ax1.plot(i+0.5, w, 's', color=colorVal, markersize=msize, linewidth=0 );
                            scatter(i+0.5, bin_index, msize, y, 's', 'filled')
                            if msize > MAXMARKERSIZE * 0.3
                                text(i+0.5, bin_index, num2str(y))
%                                fig2ax1.text(i+0.5, w, '%d', y, horizontalalignment='center', verticalalignment='center', fontsize = 8 * SCALEFACTOR)
                            end
                        end
                    end
                end

                % Adding xticks, yticks, labels, grid
%                 fig2ax1.set_axisbelow(True) % I think this puts grid and tickmarks below actual data plotted

                % x-axis
%                 fig2ax1.set_xticks(np.arange(.5,NUMVOLCANOES+.5,1))
                set(gca, 'XTick', 0.5:1:numPoints+0.5);
%                 fig2ax1.set_xlim([-0.5, NUMVOLCANOES+0.5])
                set(gca, 'XLim', [-0.5 numPoints+0.5])
%                 fig2ax1.xaxis.grid(True, linestyle='-', color='gray')
                grid on;
                set(gca, 'XTickLabel', pointlabels)
%                 fig2ax1.xaxis.set_ticks_position('top')
%                 fig2ax1.xaxis.set_label_position('top')
                %plt.setp( fig2ax1.get_xticklabels(), rotation=45, horizontalalignment='left', fontsize=10*SCALEFACTOR )

                % y-axis
%                 fig2ax1.set_yticks(np.arange(-number_of_weeks_to_plot-0.5, 0, 1))
                set(gca, 'YTick', -numBinsToUse-0.5: 1: 0)
%                 fig2ax1.set_yticklabels(weekending)
                set(gca, 'YTickLabel', binendstr)
%                 fig2ax1.set_ylim([-number_of_weeks_to_plot - 0.5, -0.5])
                set(gca, 'YLim', -numBinsToUse -0.5 : 1 : -0.5)
%                 plt.setp( fig2ax1.get_yticklabels(), fontsize=10*SCALEFACTOR )
            end
        end


         
        %% IMPORTSWARMDB
        function obj = importswarmdb(obj, dbname, auth, snum, enum)
            % IMPORTSWARMDB
            % Load a swarm database metrics table into an EventRate object
            % eventrate = importswarmdb(erobj, dbname, auth, snum, enum);  
            %
            % INPUT:
            %	dbname		the path of the database (must have a 'metrics' table)
            %	auth		name of the grid to load swarm tracking metrics for
            %	snum,enum	start and end datenumbers (Matlab time format, see 'help datenum')
            %
            % OUTPUT:
            %	obj		an eventrate object
            %
            % Example:
            %	erobj = importswarmdb('/avort/devrun/dbswarm/swarm_metadata', 'RD_lo', datenum(2010, 7, 1), datenum(2010, 7, 14) );

            % Glenn Thompson, 20100714

            % initialize
            obj.dbroot = dbname;
            obj.snum = snum;
            obj.enum = enum;
            obj.auth = auth;

            % check that database exists
            dbtablename = sprintf('%s.metrics',dbname);
            if exist(dbtablename,'file')
                % load the data
                try
                    db = dbopen(dbname, 'r');
                catch me
                    fprintf('Error: Could not open %s for reading',dbname);
                        return;
                end
                db = dblookup_table(db, 'metrics');
                if (dbquery(db, 'dbRECORD_COUNT')==0)
                    fprintf('Error: Could not open %s for reading',dbtablename);
                    return;
                end
                db = dbsubset(db, sprintf('auth ~= /.*%s.*/',auth));
                numrows = dbquery(db,'dbRECORD_COUNT');
                debug.print_debug(sprintf('Got %d rows after auth subset',numrows),2);
                sepoch = datenum2epoch(snum);
                eepoch = datenum2epoch(enum);
                db = dbsubset(db, sprintf('timewindow_starttime >= %f && timewindow_endtime <= %f',sepoch,eepoch));
                numrows = dbquery(db,'dbRECORD_COUNT');
                debug.print_debug(sprintf('Got %d rows after time subset',numrows),2);

                if numrows > 0
                    % Note that metrics are only saved when mean_rate >= 1.
                    % Therefore there will be lots of mean_rate==0 timewindows not in
                    % database.
                    [tempsepoch, tempeepoch, mean_rate, median_rate, mean_mag, cum_mag] = dbgetv(db,'timewindow_starttime', 'timewindow_endtime', 'mean_rate', 'median_rate', 'mean_ml', 'cum_ml');
                    obj.binsize = (tempeepoch(1) - tempsepoch(1))/86400;
                    obj.stepsize = min(tempsepoch(2:end) - tempsepoch(1:end-1))/86400;
                    obj.time = snum+obj.stepsize:obj.stepsize:enum;
                    obj.numbins = length(obj.time);
                    obj.mean_rate = zeros(obj.numbins, 1);
                    obj.counts = zeros(obj.numbins, 1);
                    obj.median_rate = zeros(obj.numbins, 1);
                    obj.mean_mag = zeros(obj.numbins, 1);
                    obj.cum_mag = zeros(obj.numbins, 1);
                    for c=1:length(tempeepoch)
                        tempenum = epoch2datenum(tempeepoch(c));
                        i = find(obj.time == tempenum);
                        obj.mean_rate(i) = mean_rate(c);
                        obj.counts(i) = mean_rate(c) * (obj.binsize * 24);
                        obj.median_rate(i) = median_rate(c); 
                        obj.mean_mag(i) = mean_mag(c);
                        obj.cum_mag(i) = cum_mag(c);
                    end
                end
                dbclose(db);

            else
                % error - table does not exist
                fprintf('Error: %s does not exist',dbtablename);
                return;
            end

            obj.total_counts = sum(obj.counts)*obj.stepsize/obj.binsize;

        end
        
        %% ADDFIELD
        function obj = addfield(obj,fieldname,val)
            %ADDFIELD add fields and values to object(s) 
            %   obj = addfield(obj, fieldname, value)
            %   This function creates a new user defined field, and fills it with the
            %   included value.  If fieldname exists, it will overwrite the existing
            %   value.
            %
            %   Input Arguments
            %       obj: an EventRate object
            %       fieldname: a string name
            %       value: a value to be added for those fields.  Value can be anything
            %
            %   EventRate objects can hold user-defined fields.  To access the contents, 
            %   use EventRate/get.
            %
            %   Example:
            %       % add a field called "TESTFIELD", containing the numbers 1-45
            %       obj = addfield(obj,'TestField',1:45);
            %
            %       % add a cell field called "MISHMOSH"
            %       obj = addfield(obj,'mishmosh',{'hello';'world'});
            %
            %       % see the result
            %       disp(obj) 
            %
            % See also EventRate/set, EventRate/get

            % AUTHOR: Glenn Thompson

            if ischar(fieldname)
                mask = strcmp(fieldname, properties(obj));
                if any(mask)
                    obj = obj.set(fieldname, val);
                else
                    mask = strcmp(upper(fieldname),obj.misc_fields);
                    if any(mask)
                        obj = obj.set(fieldname, val);
                    else
                        obj.misc_fields = [obj.misc_fields, upper(fieldname)];
                        obj = obj.set(upper(fieldname), val);
                    end
                end   
            else
                error('%s:addfield:invalidFieldname','fieldname must be a string', class(catalogObject))
            end

        end

        %% SET
        function obj = set(obj, varargin)
            %SET Set properties for EventRate object(s)
            %   obj = set(obj,'property_name', val, ['property_name2', val2])
            %   SET is one of the two gateway functions of an object, such as EventRate.
            %   Properties that are changed through SET are typechecked and otherwise
            %   scrutinized before being stored within the EventRate object.  This
            %   ensures that the other EventRate methods are all retrieving valid data,
            %   thereby increasing the reliability of the code.
            %
            %   Another strong advantage to using SET and GET to change and retrieve
            %   properties, rather than just assigning them to EventRate object directly,
            %   is that the underlying data structure can change and grow without
            %   harming the code that is written based on the EventRate object.
            %
            %   For a list of valid property names, type:
            %       properties(obj)
            %   
            %   If user-defined fields were added to the EventRate object (ie, through
            %   addField), these fieldnames are also available through set.
            %
            %   Examples:
            %       (1) Change the description property
            %           obj = obj.set('description','hello world');
            %
            %       (2) Add new a field called CLOSEST_STATION with
            %           % the value 'MBLG'
            %           obj = obj.addfield('CLOSEST_STATION','MBLG');
            %
            %           % change the value of the CLOSEST_STATION field
            %           obj = obj.set('CLOSEST_STATION','MBWH');
            %
            %  See also EventRate/get, EventRate/addfield

            Vidx = 1 : numel(varargin);

            while numel(Vidx) >= 2
                prop_name = upper(varargin{Vidx(1)});
                val = varargin{Vidx(2)};
                mask = strcmp(upper(prop_name),upper(properties(obj)));
                if any(mask)
                    mc = metaclass(obj);
                    i = find(mask);
                    prop_name = mc.PropertyList(i).Name;
                    if isempty(mc.PropertyList(i).GetMethod)
                        %eval(sprintf('obj.%s=val;',prop_name));
                        obj.(prop_name) = val;
                    else
                        warning('Property %s is a derived property and cannot be set',prop_name);
                    end
                else
                    switch prop_name
                        case obj.misc_fields
                            mask = strcmp(prop_name,obj.misc_fields);
                            obj.misc_values(mask) = {val};
                        otherwise
                            error('%s:set:unknownProperty',...
                                'can''t understand property name : %s', mfilename,prop_name);
                    end
                end
                Vidx(1:2) = []; %done with those parameters, move to the next ones...
            end 
        end     
        
        %% GET
        function val = get(obj,prop_name)
            %GET Get EventRate properties
            %   val = get(EventRate_object,'property_name')
            %
            %   To see valid property names, type:
            %       properties(EventRate_object)
            %
            %       If additional fields were added to EventRate using ADDFIELD, then
            %       values from these can be retrieved using the fieldname
            %
            %   See also EventRate/SET, EventRate/ADDFIELD, Catalog/GET

            mask = strcmp(prop_name, properties(obj));
            if any(mask)
                % eval(sprintf('val=obj.%s;',prop_name));
                val = obj.(prop_name);
            else
                mask = strcmp(upper(prop_name),obj.misc_fields);
                if any(mask)
                    val = obj.misc_values{mask};
                else
                    warning('%s:get:unrecognizedProperty',...
                        'Unrecognized property name : %s',  class(obj), prop_name);
                end
            end
        end

    
    end % methods 

   
    methods(Static)
        cookbook()
    end

end
%% PERCENTILES
function p=percentiles(vals)
    lenVals = length(vals);
    for i=1:100
        p(i) = vals(floor(i/100 * (lenVals-1))+1);
    end
end

%% PLOT_PERCENTILES
function plot_percentiles(p)
    figure(gcf+1, 'Color', [1 1 1])
    plot(1:100, p);
end

function label = metric2label(metric, binsize)
    % label = metric2label(metric, binsize)
    label=metric;
    blabel = Catalog.binning.binsizelabel(binsize);
    time_unit = blabel(4:end);
    if strcmp(metric, 'counts')
        label = sprintf('# Events %s',blabel);
    elseif strcmp(metric, 'energy')
        label = sprintf('Energy %s',blabel);
    elseif strcmp(metric, 'mean_rate')
        label = sprintf('Mean # events per hour (binsize %s)', time_unit);
    elseif strcmp(metric, 'median_rate')
        label = sprintf('Median # events per hour (binsize %s)', time_unit);
    elseif strcmp(metric, 'cum_mag')
        label = sprintf('Cumulative Magnitude per hour (binsize %s)', time_unit);;
    elseif strcmp(metric, 'mean_mag')
        label = sprintf('Mean Magnitude per hour (binsize %s)', time_unit);
    elseif strcmp(metric, 'median_mag')
        label = sprintf('Median Magnitude per hour (binsize %s)', time_unit);
    end
end

