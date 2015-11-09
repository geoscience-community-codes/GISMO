function plot3(catalogObject, varargin)
    %CATALOG.PLOT3 Plot hypocenters in 3-D
    %   catalogObject.plot3()
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
    p.addParamValue('nsigma', '5', @isstr);
    p.parse(varargin{:});
    nsigma = p.Results.nsigma;            

    % change region
    region = get_region(catalogObject, nsigma);

    % Compute Marker Size
    symsize = get_symsize(catalogObject);

    % 3D plot
    figure
    set(gcf,'Color', [1 1 1]);
    scatter3(catalogObject.lon, catalogObject.lat, catalogObject.depth, symsize);
    set(gca, 'ZDir', 'reverse');
    grid on;
    set(gca, 'XLim', [region(1) region(2)]);
    set(gca, 'YLim', [region(3) region(4)]);
    xlabel('Longitude');
    ylabel('Latitude');
    zlabel('Depth (km)');

end