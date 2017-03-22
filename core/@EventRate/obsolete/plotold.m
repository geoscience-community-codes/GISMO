        function plotold(obj, varargin) 
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
            colors = {[0.7 0.7 0] [0 0 1]};

            % plot each etype on a separate figure, each metric as a
            % subplot
           
            if strcmp(plotmode, 'figures') || length(obj)==1
            
                for c = 1 : numel(obj)
                    binsize_str = Catalog.binning.binsizelabel(obj(c).binsize);
                    numsubplots = length(metric);
                    %figure(get(gcf,'Number')+1)
                    figure
                    set(gcf,'Color', [1 1 1]);
                    for cc = 1: numsubplots % number of metrics to plot
                        %eval(  sprintf('data = obj(c).%s;',metric{cc} ) );
                        data = obj(c).(metric{cc});
                        if numel(data)>0 & ~all(isinf(data)) & ~all(isnan(data))
                            % replace -Inf values as they mess up plots
                            ydata = data; % ydata is the data we will plot, but we keep data for cumulative energy etc.
                            if smoothbins > 1
                                ydata = smooth(ydata, smoothbins);
                            end
%                             ydata(isinf(data))=NaN;
%                             mindata = nanmin(ydata); 
%                             ydata(isnan(ydata))=mindata; % we replace NaNs and Infs in data with nanmin(data) in ydata
                            if (obj(c).binsize == obj(c).stepsize) & ( strcmp(metric{cc}, 'counts') | strcmp(metric{cc}, 'energy') | strcmp(metric{cc}, 'cum_mag') )
                                if strfind(metric{cc}, 'mag')
                                    cumdata = magnitude.eng2mag(cumsum(magnitude.mag2eng(data)));           
                                    subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(obj(c).time, ydata, obj(c).time, cumdata, @stairs, @plot );
                                    set(h1, 'Color', colors{1});
                                else
                                    subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(obj(c).time, data, obj(c).time + obj(c).binsize/2, cumsum(data), @bar, @stairs );
                                    %subplot(numsubplots,1,cc), [ax, h1, h2] = plotyy(obj(c).time, ydata, obj(c).time, cumsum(data), @stairs, @plot );
                                    set(h1, 'FaceColor', colors{1}, 'EdgeColor', colors{1})
                                    set(h1, 'BarWidth', 1);
                                    set(h1, 'LineWidth', 0.1);
                                end
                                datetick(ax(1), 'x','keeplimits');
                                ylabel(ax(1), metric2label(metric{cc}, obj(c).binsize), 'Color', colors{1})
                                datetick(ax(2), 'x','keeplimits');
                                ylabel(ax(2),'Cumulative', 'Color', colors{2})
                                %set(h1, 'Color', colors{1});
                                %set(h2, 'Color', colors{2}, 'LineWidth', 2);
                                ylims = get(ax(1), 'YLim');
                                set(ax(1), 'YColor', colors{1}, 'YLim', [0 ylims(2)]);
                                ylims = get(ax(2), 'YLim');
                                set(ax(2), 'YColor', colors{2}, 'YLim', [0 ylims(2)]);
                                linkaxes(ax, 'x');
                            else

                                if strfind(metric{cc}, 'mag')           
                                    subplot(numsubplots,1,cc), stairs(obj(c).time, ydata, 'Color', colors{1});
                                else
                                    subplot(numsubplots,1,cc), bar(obj(c).time, data, 1, 'FaceColor', colors{1}, 'EdgeColor', colors{1}, 'BarWidth', 1, 'LineWidth', 0.1);
                                    %subplot(numsubplots,1,cc), stairs(obj(c).time, ydata, 'Color', colors{1});
                                end
                                datetick('x','keeplimits');
                                ylabel(metric2label(metric{cc}, obj(c).binsize))                        
                            end
                        end
%                         axis tight;
%                         a=axis;
%                         axis([a(1) a(2) 0 a(4)])
                    end
                end
                
                %% FROM HERE ON THE PLOTMODES HAVE NOT BEEN UPDATED
            elseif strcmp(plotmode, 'panels')
                % Each metric on a separate figure, showing all requested 
                % subclasses on separate panels
                  for c = 1 : numel(metric)
                    %figure(get(gcf,'Number')+c)
                    figure
                    numsubplots = numel(obj);

                    %for cc = numsubplots: -1: 1
                    for cc = 1:numsubplots
                        ccc = numsubplots-cc+1;
                        if strcmp(metric{c},'energy')
                            %data = cumsum(magnitude.mag2eng(obj(cc).cum_mag));
                            data = (magnitude.mag2eng(obj(ccc).cum_mag));

                        else
                            % eval(  sprintf('data = obj(cc).%s;',metric{c} ) );
                            data = obj(ccc).(metric{c});
                        end
                        if numel(data)>0 & ~all(isinf(data)) & ~all(isnan(data))
                            if smoothbins > 1
                                data = smooth(data, smoothbins);
                            end                      
                            % where to position the axes
                            pos(1) = 0.1;
                            pos(2) = 0.1+(0.95-0.1)*(cc-1)/numsubplots;
                            pos(3) = 0.8;
                            pos(4) = (0.8*(0.95-0.1)/numsubplots);
                            axes('position', pos);
                        end
                        
                        % plot
                        if numel(data)>0
                            bar( obj(ccc).time, data, 1, 'EdgeColor', 'none', 'FaceColor', [0 0 0] );
    %                         hold on;
    %                         sdata = smooth(data, 30, 'lowess');
    %                         plot( obj(cc).time, sdata, 'k-', 'linewidth', 2);


                            % range and label
                            datetick('x','keeplimits');
                            set(gca, 'XLim', [obj(ccc).snum obj(ccc).enum]);
                            ymax = nanmax(catmatrices(1, data));
    %                         ymax = min([max(sdata)*2 max(data)*1.01]);
                            set(gca, 'YLim', [0 ymax]);
                            ylabel(obj(ccc).etype);
                        end
                        
                        
                        
                    end
                    %title(metric{c});
                    fprintf('metric for figure %d is %s\n', get(gcf,'Number'), metric{c});
                  end               
                
                  
            elseif strcmp(plotmode, 'single')
                  % Each metric on a separate figure, showing all requested
                  % subclasses on the same panel
                  colour = 'rgbcm';
                  for c = 1 : numel(metric)
                    %figure(get(gcf,'Number')+c)
                    figure
                    for cc = 1: length(obj)
                        if strcmp(metric{c},'energy')
                            %data = cumsum(magnitude.mag2eng(obj(cc).cum_mag));
                            data = (magnitude.mag2eng(obj(cc).cum_mag));
                        else
                            % eval(  sprintf('data = obj(cc).%s;',metric{c} ) );
                            data = obj(cc).(metric{c});
                        end
                        
                        if numel(data)>0 & ~all(isinf(data)) & ~all(isnan(data))
                        
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
                    end
                    title(metric{c});
                  end         
                
                  
             elseif strcmp(plotmode, 'stacked')
                 % Each metric on a separate figure, showing all subclasses
                 % stacked on the same panel
                  colour = 'rgbcm';
                  for c = 1 : numel(metric)
                    figure(get(gcf,'Number')+c)
                    data =[];
                    for cc = 1: length(obj)
                        if strcmp(metric{c},'energy')
                            data = (magnitude.mag2eng(obj(cc).cum_mag));
                        else
                            %eval(  sprintf('data(:,cc) = obj(cc).%s;',metric{c} ) );
                            %data(:,cc) = obj(cc).(metric{c});
                            data = obj(cc).(metric{c});
                            if findstr(metric{c}, 'mag')
                                disp('Warning: It is meaningless to stack magnitude data');
                                data(data<0)=0;
                                data(isnan(data))=0;
                            end
                        end
                        if numel(data)>0 & ~all(isinf(data)) & ~all(isnan(data))
                            if smoothbins > 1
                                data = smooth(data, smoothbins);
                            end    

                            %bar( obj(cc).time, data, 1, 'stack' );
                            area(obj(cc).time, data);
                            datetick('x','keeplimits');
                            set(gca, 'XLim', [obj(cc).snum obj(cc).enum]);
                            title(metric{c});
                        end
                    end
                end               
            end        
        end

