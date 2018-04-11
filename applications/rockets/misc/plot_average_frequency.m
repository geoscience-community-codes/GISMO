function plot_average_frequency(w)
    figure
    sp=spectralobject(1024,924,100,[]);
    % Plot a spectrogram with superposed frequency metrics
    [Tcell,meanF,peakF]=spectrogram(w,'spectralobject',sp,'plot_metrics',1);
    % Plot the frequency metrics on their own
    for c=1:numel(w)
        subplot(numel(w),1,c)
        plot(Tcell{c},smooth(peakF{c}),'g')
        hold on
        plot(Tcell{c},meanF{c},'k')
        datetick('x')
        ylabel('Hz')
        sta= get(w(c),'station');
        chan= get(w(c),'channel');
        th=text(0.1,0.9, sprintf('%s %s.%s',datestr(Tcell{c}(1),30),sta,chan),'Units','normalized')
    end

end
