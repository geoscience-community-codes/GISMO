function plot_time(catalogObject, varargin)
    %CATALOG.PLOT_TIME Plot magnitude and depth against time
    %   catalogObject.plot_time()
    % Glenn Thompson 2014/06/01
    if all(isnan(catalogObject.lat))
        warning('No hypocenter data to plot');
        return
    end
    p = inputParser;
    p.addParameter('etypes', {});
    p.addParameter('symbols', {});
    p.parse(varargin{:});
    etypes = p.Results.etypes;
    symbols = p.Results.symbols;
    if isempty(etypes)
        etypes = unique(catalogObject.etypes);
    end
    if isempty(symbols)
        symbols = repmat('bo', numel(etypes), 1);
    end
    
    symsize = get_symsize(catalogObject); 
    timerange = catalogObject.gettimerange();
    xlims = [floor(timerange(1)) ceil(timerange(2))];
    figure;
    set(gcf,'Color', [1 1 1]);
    
% ORIGINAL VERSION?
    % time-depth
    if all(isnan(catalogObject.depth))
        warning('No depth data to plot');
        return
    else
        if ~exist('fh','var')
            figure;
        else
            figure(fh)
        end
        set(gcf,'Color', [1 1 1]);
        subplot(2,1,1);
        scatter(catalogObject.otime, catalogObject.depth, symsize,'k');
        set(gca, 'XLim', xlims);
        datetick('x');
        xlabel('Date');
        ylabel('Depth (km)');
        set(gca, 'YDir', 'reverse');
        grid on;

    end 
    ax1 = subplot(2,1,1);
    %scatter(catalogObject.otime, catalogObject.depth, symsize);

    % time-mag
    if all(isnan(catalogObject.mag))
        warning('No magnitude data to plot');
        return
    else
        scatter(catalogObject.otime, catalogObject.mag, symsize,'k');
        %stem(catalogObject.otime, catalogObject.mag);
        set(gca, 'XLim', xlims);
        datetick('x');
        xlabel('Date');
        ylabel('Magnitude');
        grid on;
    end
    ax2 = subplot(2,1,2);

% VERSION MADE FOR HEATHER's CODE?
    for i = 1:length(etypes)
        this_etype = etypes{i};
        this_symbol = symbols{i}
        these_indices = find(strcmp(catalogObject.etype,this_etype));
        this_cobj = catalogObject.subset('indices', these_indices);
        fprintf('There are %d of etype %s', length(this_cobj.lat), this_etype)

        % Compute Marker Size
        symsize = get_symsize(this_cobj);

        % time-depth plot
        if isgraphics(ax1)
            hold(ax1, 'on')
            scatter(ax1,  this_cobj.otime, this_cobj.depth, symsize, this_symbol(1), this_symbol(2), 'filled');
            grid(ax1, 'on');
            datetick(ax1, 'x');
            xlabel(ax1, 'Date');
            ylabel(ax1, 'Depth (km)');
            set(ax1, 'YDir', 'reverse');
            set(ax1, 'XLim', xlims);
        end

        % time_mag
        if isgraphics(ax2)
        hold(ax2, 'on')
            scatter(ax2, this_cobj.otime, this_cobj.mag, symsize, this_symbol(1), this_symbol(2), 'filled');
            grid(ax2, 'on');
            xlabel(ax2, 'Date');
            ylabel(ax2, 'Magnitude');
            datetick(ax2, 'x');
            set(ax2, 'XLim', xlims);

        end

   
    end
end  
