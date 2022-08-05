function [axs latitudeLimits longitudeLimits] = plot(catalogObject, varargin)
    %CATALOG.PLOT Plot hypocenters in map view and cross-sections
    % 
    %
    %   Optional name/value pairs:
    %     'nsigma' - controls how zoomed-in the axes are (default
    %     5)            

    % Glenn Thompson 2014/06/01
    if all(isnan(catalogObject.lat))
        warning('No hypocenter data to plot');
        return
    end
    p = inputParser;
    p.addParameter('nsigma', 5);
    p.addParameter('region', []);
    p.addParameter('etypes', {});
    p.addParameter('symbols', {});
    p.addParameter('depthrange', []);
    p.parse(varargin{:});
    nsigma = p.Results.nsigma;
    region = p.Results.region;
    etypes = p.Results.etypes;
    symbols = p.Results.symbols;
    depthrange = p.Results.depthrange;
    if isempty(etypes)
        etypes = unique(catalogObject.etype);
    end
    if isempty(symbols)
        symbols = repmat({'bo'}, numel(etypes), 1);
    end

    % change region
    if isempty(region)
        region = get_region(catalogObject, nsigma);
    end
    %disp(region)
    
    fh = figure()
    fh.Position(3:4)=[800 800];
%     ax1 = geoaxes('position',[0.05 0.45 0.5 0.5], 'Basemap', 'satellite');
%     ax2 = axes('position',[0.05 0.05 0.5 0.35]);
%     ax3 = axes('position',[0.63 0.45 0.32 0.5]);
%     ax4 = axes('position',[0.63 0.05 0.32 0.35]);
    spw = 0.35;
    sph = 0.35;
    xoff = 0.1;
    yoff = 0.1;
    ax1 = geoaxes('position',[xoff yoff*2+sph spw sph], 'Basemap', 'satellite');
    ax2 = axes('position',[xoff yoff spw sph]);
    ax3 = axes('position',[xoff*2+spw yoff*2+sph spw sph]);
    ax4 = axes('position',[xoff*2+spw yoff spw sph]);
    axs = [ax1 ax2 ax3 ax4];
    set(gcf,'Color', [1 1 1]);    


    minmag = nanmin(catalogObject.mag);
    maxmag = nanmax(catalogObject.mag); 
    mags = [];
    this_m = -0.5;
    while this_m < minmag,
        this_m = this_m + 0.5;
    end
    while this_m < maxmag,
        mags = [mags this_m];
        this_m = this_m + 0.5;
    end

    for i = 1:length(etypes)
        this_etype = etypes{i};
        this_symbol = symbols{i};
        these_indices = find(strcmp(catalogObject.etype,this_etype));
        this_cobj = catalogObject.subset('indices', these_indices);
        fprintf('There are %d of etype %s', length(this_cobj.lat), this_etype)

        % Compute Marker Size
        symsize = get_symsize(this_cobj);

        % lon-lat plot
        hold(ax1, 'on')
        geoscatter(ax1,  this_cobj.lat, this_cobj.lon, symsize, this_symbol(1), this_symbol(2), 'filled');
        grid on;
        geolimits(ax1, [region(3) region(4)], [region(1) region(2)]);
        [latitudeLimits,longitudeLimits] = geolimits(ax1)    
        %xlabel(ax1, 'Longitude');
        %continue

        % depth-longitude
        hold(ax2, 'on')
        scatter(ax2, this_cobj.lon, this_cobj.depth, symsize, this_symbol(1), this_symbol(2), 'filled');
        ylabel(ax2, 'Depth (km)');
        xlabel(ax2, 'Longitude');
        set(ax2, 'YDir', 'reverse');
        set(ax2, 'XLim', longitudeLimits);
        if ~isempty(depthrange)
            set(ax2, 'YLim', depthrange);
        end        
        grid(ax2, 'on');
        

        % depth-lat 
        hold(ax3, 'on')
        scatter(ax3, this_cobj.depth, this_cobj.lat, symsize, this_symbol(1), this_symbol(2), 'filled');
        xlabel(ax3, 'Depth (km)');
        ylabel(ax3, 'Latitude');
        %set(ax3, 'XDir', 'reverse');        
        grid(ax3, 'on'); 
        set(ax3, 'YLim', latitudeLimits);
        if ~isempty(depthrange)
            set(ax3, 'XLim', depthrange);
        end
        ytickangle(ax3, 60)
        
        % legend
        hold(ax4, 'on')
        grid(ax4, 'off')
        
        this_x = [1:length(mags)] * 0.1 + 0.5;
        this_y = ones(1, length(mags)) * (0.1 * i + 0.5);
        set(ax4,'XLim',[0.3 1.3],'YLim',[0.3 1.3])
        cobjleg = Catalog(this_x*0, this_x, this_y, this_x*0, mags);
        symsize = get_symsize(cobjleg);
        scatter(ax4, this_x+0.05, this_y, symsize, this_symbol(1), this_symbol(2), 'filled'); 
        set(ax4, 'XColor', 'none', 'YColor', 'none')
        
    end


    hold(ax4, 'on')
    this_x = [1:length(mags)] * 0.1 + 0.5;
    this_y = (0.1 * (length(etypes)+1) + 0.5);  
    text(this_x(1)-0.2, this_y+0.16, 'LEGEND', 'fontsize', 16)
    text(this_x(1), this_y+0.08, 'Magnitude', 'fontsize', 16)
    for c = 1:length(mags)
        text(ax4, this_x(c), this_y, sprintf('%.1f',mags(c)), 'fontsize', 12 )
    end
    
    this_x = 0.5;
    text(this_x(1)-0.1, 0.6, 'Class', 'Rotation', 90, 'fontsize', 16)
    for c = 1:length(etypes)
        this_y = (0.1 * c + 0.5);  
        subclasstxt = upper(etypes{c});
        if strcmp(subclasstxt,'L1')
            subclasstxt = 'LP1';
        elseif strcmp(subclasstxt,'L2')
            subclasstxt = 'LP2';
        end      
        text(ax4, this_x, this_y, subclasstxt, 'fontsize', 12);
    end    
    
    [latitudeLimits,longitudeLimits] = geolimits(ax1)  
end