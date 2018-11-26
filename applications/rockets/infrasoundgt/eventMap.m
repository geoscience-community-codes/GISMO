%% plot array map & compute eastings and northings
if exist('make_figures','var') & make_figures
    disp('Plotting array map')
    close all
    cols = 'rwbggg'; % for spaceXplosion
    %cols = 'kkkkkkkkkkkk';
    for c=1:length(easting)
        chan = get(w(c),'channel');;
        plot(easting(c),northing(c),'o','MarkerFaceColor',cols(c),'MarkerSize',10)
        hold on
        quiver(easting(c),northing(c),-easting(c)/100,-northing(c)/100,0); % /100 just gives arrow length
        text(easting(c)+1,northing(c),chan(1:3));
    end
    grid on
    quiver(440,1325,wind_speed*sin(deg2rad(wind_direction)), wind_speed*cos(deg2rad(wind_direction)) ,0,'k');
    text(440,1325,'wind')
    hold off
    title('Beach House array position relative to SLC40');
    xlabel('metres east');
    ylabel('metres north');
    axis equal;
    outfile = sprintf('%s/arraymap.png',figureOutDirectory);
    feval('print', '-dpng', outfile); 
    close
end