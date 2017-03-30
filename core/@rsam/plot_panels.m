function handlePlot = plot(rsam_vector, varargin)
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
    
    w = rsam2waveform(rsam_vector);
    plot_panels(w);
    
    % xticks currently in seconds 
    xticks=get(gca,'XTick');
    xlims = get(gca,'XLim');
    hfc = get(gcf,'Children');
    if xlims(2) >= 60 * 10 && xlims(2) < 60 * 100
        % change to minutes
        xticks = 0:60:xlims(2);
        divisor = 60;
        xlabel('Time (minutes)');
    end
    if xlims(2) >= 60 * 100 && xlims(2) < 60 * 60 * 100
        % change to hours
        xticks = 0:60*15:xlims(2);  %15 minute intervals
        divisor = 3600;     
        xlabel('Time (hours)');
    end
    if xlims(2) >= 60 * 60 * 100 && xlims(2) < 60 * 60 * 24 * 100
        % change to days
        xticks = 0:60*60*6:xlims(2);  %6 hour intervals      
        divisor = 3600 * 24;      
        xlabel('Time (days)');
    end    
    if xlims(2) >= 60 * 60 * 24 * 100
        % change to weeks
        xticks = 0:60*60*24*3.5:xlims(2);  %0.5 week intervals
        divisor = 3600 * 24 * 7;
        xlabel('Time (weeks)');
    end
    r = stepsize(xticks);
    xticks = xticks(1:r:end);
    xticklabels = xticks/divisor;
    set(hfc(2:end),'XTick',xticks,'XTickLabels',xticklabels);     
end


function r=stepsize(xticks)
    r = ceil(numel(xticks)/14);
end
