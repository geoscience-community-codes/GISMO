function plot(rsam_vector, varargin)
    % RSAM/PLOT plot rsam data
    % handle = plot(rsam_vector, varargin)
    % Properties include:
    %   yaxistype, h, addgrid, addlegend, fillbelow, plotspikes, plottransients, plottremor
    % to change where the legend plots set the global variable legend_ypos
    % a positive value will be within the axes, a negative value will be below
    % default is -0.2. For within the axes, log(20) is a reasonable value.
    % yaxistype is like 'logarithmic' or 'linear'
    % h is an axes handle (or an array of axes handles)
    % use h = generatePanelHandles(numgraphs)

    % Glenn Thompson 1998-2009
    %
    % % GTHO 2009/10/26 Changed marker size from 5.0 to 1.0
    % % GTHO 2009/10/26 Changed legend position to -0.2

    % parse variable input arguments
    p = inputParser;
    p.addParameter('addgrid',false);
    p.addParameter('addlegend', true);
    p.addParameter('fillbelow', false);
    p.addParameter('existence', false);
    p.addParameter('yaxistype','linear'); % or log
    p.addParameter('symbol','-'); % or log
    p.addParameter('h', []);
    p.parse(varargin{:});
    addgrid = p.Results.addgrid;
    addlegend = p.Results.addlegend;
    fillbelow = p.Results.fillbelow;
    yaxistype = p.Results.yaxistype;
    existence = p.Results.existence;
    symbol = p.Results.symbol;
    h = p.Results.h;
    legend_ypos = -0.2;

    % colours to plot each station
    lineColour={[0 0 0]; [0 0 1]; [1 0 0]; [0 1 0]; [.4 .4 0]; [0 .4 0 ]; [.4 0 0]; [0 0 .4]; [0.5 0.5 0.5]; [0.25 .25 .25]};
    
    % units - so that we put different ones on different figures
    units = {rsam_vector.units};
    unique_units = unique(units);
    %previousfignum = get(gcf,'Number');
    previousfignum = get_highest_figure_number();
    floory=1e9; ceily = 0; % default values to be updated in log plots
    % Plot the data graphs
    for c = 1:length(rsam_vector)
        self = rsam_vector(c); 
        t = self.dnum;
        y = self.data;
       
        debug.print_debug(10,sprintf('Data length: %d',length(y)));
        
        if length(y)>0        
            %figure
            %if strcmp(rsam_vector(c).units, 'Hz')
            if existence
                y=cumsum(y>1)/numel(y);
            end
            if strcmp(yaxistype,'linear')
            try
                figure(previousfignum + c);
            catch
                figure;
            end
                % plot on a linear axis, with station name as a y label
                % datetick too, add measure as title, fiddle with the YTick's and add max(y) in top left corner
                if ~p.Results.fillbelow
                    %handlePlot = plot(t, y, symbol, 'Color', lineColour{c});
                    handlePlot = plot(t, y, symbol, 'Color', lineColour{1});
                else
                    %handlePlot = fill([min(t) t max(t)], [min([y 0]) y min([y 0])], lineColour{c});
                    handlePlot = fill([min(t) t max(t)], [min([y 0]) y min([y 0])], lineColour{1});
                end

                % if c ~= numel(rsam_vector)
                %     set(gca,'XTickLabel','');
                % end

                % yt=get(gca,'YTick');
                % ytinterval = (yt(2)-yt(1))/2; 
                % yt = yt(1) + ytinterval: ytinterval: yt(end);
                % ytl = yt';
                % ylim = get(gca, 'YLim');
                % set(gca, 'YLim', [0 ylim(2)],'YTick',yt);
                % %ylabelstr = sprintf('%s.%s %s (%s)', self.sta, self.chan, self.measure, self.units);
    %             ylabelstr = sprintf('%s', self.sta);
    %             ylabel(ylabelstr);
                ylabel(sprintf('%s',self.units))
    %             datetick('x','keeplimits');
                a = axis;
                datetick('x')
                set(gca,'XLim',[a(1) a(2)]);
                xlabel('Date/Time');
                if addlegend
                    legend();
                end

            else

                % make a logarithmic plot, with a marker size and add the station name below the x-axis like a legend
                y = log10(y);  % use log plots
                try
                    figure(previousfignum + 1);
                catch
                    figure(gcf);
                end                
                hold on;                
                if strfind(self.measure, 'dr')
                    
                    handlePlot = plot(t, y, symbol, 'Color', lineColour{c}, 'MarkerSize', 1.0);
                    %ylabel(sprintf('%s (cm^2)',self(c).measure));
                    %ylabel(sprintf('D_R (cm^2)',self(c).measure));
                    Yticks = [0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 20 50 ];
                    Ytickmarks = log10(Yticks);
                    for count = 1:length(Yticks)
                        Yticklabels{count}=num2str(Yticks(count),3);
                    end
                    set(gca, 'YLim', [min(Ytickmarks) max(Ytickmarks)],...
                       'YTick',Ytickmarks,'YTickLabel',Yticklabels);
                    grid on;
                else
                    %handlePlot = semilogy(t, y, symbol, 'Color', lineColour{1}, 'MarkerSize', 1.0);
                    %handlePlot = plot(t, y, symbol, 'Color', lineColour{1}, 'MarkerSize', 1.0);
                    handlePlot = scatter(t, y, 1, lineColour{c});
                    floory = min([floor(nanmin(y)) floory]);
                    ceily = max([ceil(nanmax(y)) ceily]);
                    Ytickmarks = floory:ceily;
                    Yticks = 10.^Ytickmarks;
                    Ytickmarks = log10(Yticks);
                    if length(Yticks)==0
                        continue
                    end
                    for count = 1:length(Yticks)
                        Yticklabels{count}=num2str(Yticks(count),3);
                    end
                    set(gca, 'YLim', [min(Ytickmarks) max(Ytickmarks)],...
                       'YTick',Ytickmarks,'YTickLabel',Yticklabels);
                    grid on; 
                    ylabel('RSAM counts');
                end
                legendstr{c} = self.ChannelTag.string();
                
%                  axis tight
%                  a = axis;
%                 %datetick('x')
%                 %fileexchange.datetickzoom('x')
%                 datetick('x')
%                 set(gca,'XLim',[a(1) a(2)]);
    %
                xlabel(sprintf('Date/Time starting at %s',datestr(self.snum)))
%                 ylabel(sprintf('log(%s)',self.units))

            end

            if p.Results.addgrid
                grid on;
            end
            if p.Results.addlegend && ~isempty(y)
                xlim = get(gca, 'XLim');
                legend_ypos = 0.9;
                legend_xpos = c/10;    
            end

            datetick('x','keeplimits')
%             if ~strcmp(self.ChannelTag.string(), '...')
%                 tstr = sprintf('%s %s\n%s %.0f s',self.ChannelTag.string(), datestr(t(1)), self.measure, round(self.sampling_interval) );
%             else
%                 tstr = sprintf('%s\n%s %.0f s',self.files.file, datestr(a(1)), round(self.sampling_interval) );
%             end
%             legend
%             title(tstr)
        end
        if exist('legendstr','var')
            try
            legend(legendstr, 'Location','southwest')
            catch ME
                warning(ME.message)
            end
        end
    end
end