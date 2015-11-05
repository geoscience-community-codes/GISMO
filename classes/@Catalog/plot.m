function plot(catalogObject, varargin)
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
    p.addParamValue('nsigma', '5', @isstr);
    p.parse(varargin{:});
    nsigma = p.Results.nsigma;

    % change region
    region = get_region(catalogObject, nsigma);

    % Compute Marker Size
    symsize = get_symsize(catalogObject);

    figure;
    set(gcf,'Color', [1 1 1]);

    % lon-lat plot
    axes('position',[0.05 0.45 0.5 0.5]);
    scatter(catalogObject.lon, catalogObject.lat, symsize);
    grid on;
    %set(gca, 'XLim', [region(1) region(2)]);
    %set(gca, 'YLim', [region(3) region(4)]);
    xlabel('Longitude');

    % depth-longitude
    axes('position',[0.05 0.05 0.5 0.35]);
    scatter(catalogObject.lon, catalogObject.depth, symsize);
    ylabel('Depth (km)');
    xlabel('Longitude');
    grid on;
    set(gca, 'YDir', 'reverse');
    %set(gca, 'XLim', [region(1) region(2)]);

    % depth-lat
    axes('position',[0.6 0.45 0.35 0.5]);
    scatter(catalogObject.depth, catalogObject.lat, symsize);
    xlabel('Depth (km)');
    %set(gca, 'XDir', 'reverse');
    ylabel('Latitude');
    grid on;
    %set(gca, 'YLim', [region(3) region(4)]);

%             % world map
%             load plotEarthquakes/plates.mat
%             coast = load('coast');
%             figure
%             worldmap world
%             setm(gca,'mlabelparallel',-90,'mlabellocation',90)
%             plotm(coast.lat,coast.long,'Color','k')
%             plotm(lat,lon,'LineWidth',2)
% 
%             %% Find the first plate
%             % Look for the first NaN and stop there.
%             ind = find(isnan(lat),1,'first')
%             plotm(lat(1:ind),lon(1:ind),'Color','red','Linewidth',3)

end