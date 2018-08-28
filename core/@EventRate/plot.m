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
    p.addParameter('metric', {'counts'}, @(c) iscell(c)||isstr(c));
    p.addParameter('plotmode', 'figures', @isstr);
    p.addParameter('smooth', 1, @isnumeric);
    p.parse(varargin{:});
    metric = p.Results.metric;
    plotmode = p.Results.plotmode;
    smoothbins = p.Results.smooth; % NOT DOING ANYTHING WITH THIS YET BUT COULD SMOOTH COUNTS OVER SEVERAL BINS
    if ~iscell(metric)
        metric = {metric};
    end
    numMetrics = numel(metric);
    colors = {[0 0.8 0] [0 0 0.8]};

    % plot each etype on a separate figure, each metric as a
    % subplot

    fh = [];
    for c = 1 : numel(obj)
        binsize_str = Catalog.binning.binsizelabel(obj(c).binsize);
        numsubplots = numMetrics;

        switch numsubplots
            case 1, fontsize = 12;
            case 2, fontsize = 8;
            otherwise, fontsize = 6;
        end
        set(0, 'defaultTextFontSize',fontsize);

        fh(c) = figure;
        unique_subclasses = unique(char([obj(c).etype{:}])');
        if length(unique_subclasses)==1
            longname = Catalog.subclass2longname(unique_subclasses);
        else
            longname = Catalog.subclass2longname('*');
        end
        set(fh(c),'Color', [1 1 1], 'Name', sprintf('%s activity beginning %s',longname, datestr(obj(c).time(1),29) ) );
        for cc = 1: numsubplots % number of metrics to plot
            data = obj(c).(metric{cc});
            if numel(data)>0 & ~all(isinf(data)) & ~all(isnan(data))
                % replace -Inf values as they mess up plots
                y = data; % ydata is the data we will plot, but we keep data for cumulative energy etc.
                if smoothbins > 1
                    y = smooth(y, smoothbins);
                end
                y(isinf(y))=NaN;
                mindata = nanmin(y); 
                y(isnan(y))=mindata; % we replace NaNs and Infs in data with nanmin(data) in ydata
                
                labels = metric2label(metric{cc}, obj(c).binsize);
                t = [ obj(c).time - obj(c).binsize/2 ]; t = [t t(end)+obj(c).binsize];
                y = [y y(end)];
                clear ax h1 h2               

                % We will only use plotyy to plot 2 axis when we have a metric that can be cumulated
                % So the metric must be counts, energy or cumulative magnitude
                % and the bins must be non-overlapping      
                if (obj(c).binsize == obj(c).stepsize) & ( strcmp(metric{cc}, 'counts') | strcmp(metric{cc}, 'energy') | strcmp(metric{cc}, 'cum_mag') )

                    cumy = cumsum(data); cumy = [cumy cumy(end)];
                    subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(t, y, t, cumy, @stairs, @stairs );

                    % with plotyy the right hand label
                    % was off the page, so fix this
                    apos=get(ax(1),'Position');
                    apos(3)=0.75;
                    set(ax(1),'Position',apos);
                    set(ax(2),'Position',apos);

                    %% graph 1
                    set(h1, 'LineWidth', 3, 'Color', colors{1});
                    datetick(ax(1), 'x','keeplimits');
                    ylabel(ax(1), labels{1}, 'Color', colors{1}, 'FontSize', fontsize)
                    ylims = get(ax(1), 'YLim');
                    set(ax(1), 'YColor', colors{1}, 'YLim', [0 max([ylims(2) 1])], 'XLim', [t(1) t(end)]);
                    xticklabels = get(ax(1), 'XTickLabel');
                    set(ax(1), 'XTickLabel', xticklabels, 'FontSize', fontsize); 
                    yticklabels = get(ax(1), 'YTickLabel');
                    set(ax(1), 'YTickLabel', yticklabels, 'FontSize', fontsize); 

                    %% graph 2
                    set(h2, 'LineWidth', 3, 'Color', colors{2});
                    datetick(ax(2), 'x','keeplimits');
                    ylabel(ax(2),labels{2}, 'Color', colors{2}, 'FontSize', fontsize)
                    ylims = get(ax(2), 'YLim');
                    set(ax(2), 'YColor', colors{2}, 'YLim', [0 max([ylims(2) 1])], 'XLim', [t(1) t(end)]);
                    xticklabels = get(ax(2), 'XTickLabel');
                    set(ax(2), 'XTickLabel', xticklabels, 'FontSize', fontsize); 
                    yticklabels = get(ax(2), 'YTickLabel');
                    set(ax(2), 'YTickLabel', yticklabels, 'FontSize', fontsize); 

                    linkaxes(ax, 'x');

                else
                    
                    % So here we either have overlapping bins, or a metric
                    % that is not counts, energy or cum_mag
                    % In all these cases, we only have 1 graph per subplot


                    %% graph 1 (there is only 1 in this case)
                    if strfind(metric{cc}, 'mag')           
                        %subplot(numsubplots,1,cc), stairs(obj(c).time, data, 'Color', colors{1});
                        subplot(numsubplots,1,cc), ax(1)=stairs(t, y, 'Color', colors{1});
                    else
                        %subplot(numsubplots,1,cc), bar(obj(c).time, data, 1, 'FaceColor', colors{1}, 'EdgeColor', colors{1}, 'BarWidth', 1, 'LineWidth', 0.1);
                        subplot(numsubplots,1,cc), ax(1)=bar(t, y, 1, 'FaceColor', colors{1}, 'EdgeColor', colors{1}, 'BarWidth', 1, 'LineWidth', 0.1);
                        %subplot(numsubplots,1,cc), stairs(obj(c).time, ydata, 'Color', colors{1});
                    end

                    %ylabel(metric2label(metric{cc}, obj(c).binsize))    
                    datetick('x','keeplimits');
                    title(labels{1}, 'FontSize', fontsize)
                    ylims = get(gca, 'YLim');
                    set(gca, 'YLim', [0 max([ylims(2) 1])], 'XLim', [t(1) t(end)]);
                    xticklabels = get(gca, 'XTickLabels');
                    set(gca,'XTickLabels', xticklabels, 'FontSize', fontsize); 
                    yticklabels = get(gca, 'YTickLabels');
                    set(gca,'YTickLabels', yticklabels, 'FontSize', fontsize);                     
                end
            end

        end

        % fontsize for labels - this does not appear to work
        set(findall(gcf,'-property','FontSize'),'FontSize',fontsize)
        
        % fix yticklabels
        axish = get(gcf,'Children');
        for axisnum=1:numel(axish)
            if strcmp('matlab.graphics.axis.Axes',class(axish(1)))
                set(axish(axisnum),'YTickLabel',get(axish(axisnum),'YTick'));
            end
        end
        
    end
end

function labels = metric2label(metric, binsize)
    % label = metric2label(metric, binsize)
    labels={};
    blabel = Catalog.binning.binsizelabel(binsize);
    time_unit = blabel(4:end);
    if strcmp(metric, 'counts')
        labels{1} = sprintf('# Events %s',blabel);
        labels{2} = 'Cumulative # events';
    elseif strcmp(metric, 'energy')
        labels{1} = sprintf('Energy %s (J)',blabel);
        labels{2} = 'Cumulative energy (J)';
    elseif strcmp(metric, 'mean_rate')
        labels{1} = sprintf('Mean # events per hour\n(binsize %s)', time_unit);
    elseif strcmp(metric, 'median_rate')
        labels{1} = sprintf('Median # events per hour\n(binsize %s)', time_unit);
    elseif strcmp(metric, 'cum_mag')
        labels{1} = sprintf('Cumulative Magnitude per hour\n(binsize %s)', time_unit);;
    elseif strcmp(metric, 'mean_mag')
        labels{1} = sprintf('Mean Magnitude per hour\n(binsize %s)', time_unit);
    elseif strcmp(metric, 'median_mag')
        labels{1} = sprintf('Median Magnitude per hour\n(binsize %s)', time_unit);
    end
end