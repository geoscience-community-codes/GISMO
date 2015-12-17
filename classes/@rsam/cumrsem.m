function handles = plot(rsamobj, varargin)
    % RSAM/PLOT plot rsam data
    % handle = plot(rsamobj, yaxisType, h, addgrid, addlegend, fillbelow, plotspikes, plottransients, plottremor);
    % to change where the legend plots set the global variable legend_ypos
    % a positive value will be within the axes, a negative value will be below
    % default is -0.2. For within the axes, log(20) is a reasonable value.
    % yaxisType is 'logarithmic' or 'linear'
    % h is an axes handle (or an array of axes handles)
    % use h = generatePanelHandles(numgraphs)

    % Glenn Thompson 1998-2009
    %
    % % GTHO 2009/10/26 Changed marker size from 5.0 to 1.0
    % % GTHO 2009/10/26 Changed legend position to -0.2
    [yaxisType, h, addgrid, addlegend, fillbelow] = ...
        matlab_extensions.process_options(varargin, ...
        'yaxisType', 'linear', 'h', [], 'addgrid', false, ...
        'addlegend', false, 'fillbelow', false);
    legend_ypos = -0.2;

    % colours to plot each station
    lineColour={[0 0 0]; [0 0 1]; [1 0 0]; [0 1 0]; [.4 .4 0]; [0 .4 0 ]; [.4 0 0]; [0 0 .4]; [0.5 0.5 0.5]; [0.25 .25 .25]};

    % Plot the data graphs
    for c = 1:numel(rsamobj)
        self = rsamobj(c);
        hold on; 
        t = self.dnum;
        y = self.data;

        debug.print_debug(10,sprintf('Data length: %d',length(y)));
        handles(c) = subplot(numel(rsamobj), 1, c);

        %if ~strcmp(rsamobj(c).units, 'Hz') 
        if strcmp(yaxisType(1:3), 'log')
            % make a logarithmic plot, with a marker size and add the station name below the x-axis like a legend
            y = log10(y);  % use log plots
            plot(t, y, '.', 'Color', lineColour{c}, 'MarkerSize', 1.0);

            if strfind(self.measure, 'dr')
                %ylabel(sprintf('%s (cm^2)',self(c).measure));
                %ylabel(sprintf('D_R (cm^2)',self(c).measure));
                Yticks = [0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 20 50 ];
                Ytickmarks = log10(Yticks);
                for count = 1:length(Yticks)
                    Yticklabels{count}=num2str(Yticks(count),3);
                end
                set(gca, 'YLim', [min(Ytickmarks) max(Ytickmarks)],'YTick',Ytickmarks,'YTickLabel',Yticklabels);
            end
            axis tight
            datetick('x','keeplimits')
%
            xlabel(sprintf('Date/Time starting at %s',datestr(self.snum)))
            ylabel(sprintf('log(%s)',self.units))
        else

            % plot on a linear axis, with station name as a y label
            % datetick too, add measure as title, fiddle with the YTick's and add max(y) in top left corner
            if ~fillbelow
                plot(t, y, '.', 'Color', lineColour{c});
            else
                fill([min(t) t max(t)], [min([y 0]) y min([y 0])], lineColour{c});
            end

            if c ~= length(rsamobj)
                set(gca,'XTickLabel','');
            end
            datetick('x','keeplimits');
        end
        ylabel(sprintf('%s.%s',rsamobj(c).sta, rsamobj(c).chan));

        if addgrid
            grid on;
        end

        if addlegend && length(y)>0
            xlim = get(gca, 'XLim');
            legend_ypos = 0.9;
            legend_xpos = c/10;    
        end

    end

    linkaxes(handles,'x');
end