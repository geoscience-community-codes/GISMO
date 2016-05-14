function plot_time(catalogObject)
    %CATALOG.PLOT_TIME Plot magnitude and depth against time
    %   catalogObject.plot_time()

    % Glenn Thompson 2014/06/01

    symsize = get_symsize(catalogObject); 
    timerange = catalogObject.gettimerange();
    xlims = [floor(timerange(1)) ceil(timerange(2))];

    % time-depth
    if all(isnan(catalogObject.depth))
        warning('No depth data to plot');
    else
        figure;
        set(gcf,'Color', [1 1 1]);
        subplot(2,1,1);
        scatter(catalogObject.otime, catalogObject.depth, symsize);
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
        scatter(catalogObject.otime, catalogObject.mag, symsize);
        %stem(catalogObject.otime, catalogObject.mag);
        set(gca, 'XLim', xlims);
        datetick('x');
        xlabel('Date');
        ylabel('Magnitude');
        grid on;
    end
end

