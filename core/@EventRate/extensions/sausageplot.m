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

function pvalue(obj)
    logt = log10(obj.time-obj.time(1));
    logc = log10(obj.counts);
    plot(logt, logc);
    p = logt \ logc'
%     p = polyfit(logt, logc, 1)
%     hold on
%     logt1 = min(logt);
%     logc1 = polyval(p, logt1);
%     logt2 = max(logt);
%     logc2 = polyval(p, logt2);  
%     line([logt1 logt2], [logc1 logc2]);
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
    figure(get(gcf,'Number')+1, 'Color', [1 1 1])
    plot(1:100, p);
end
