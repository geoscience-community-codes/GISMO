%% HELENAPLOT
function helenaplot(obj)
    for c=1:length(obj)
        figure
        set(gcf,'Color', [1 1 1]);
        cumcummag = magnitude.eng2mag(cumsum(magnitude.mag2eng(obj(c).cum_mag)));
        [ax, h1, h2] = plotyy(obj(c).time, cumcummag, obj(c).time, cumsum(obj(c).energy), @plot, @plot);
        datetick(ax(1), 'x','keeplimits');
        datetick(ax(2), 'x','keeplimits');
        ylabel(ax(1), 'Cumulative Magnitude');
        ylabel(ax(2), 'Cumulative Energy');
    end
end