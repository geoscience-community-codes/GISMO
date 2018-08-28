function plotprmm(catalogObject)
    %CATALOG.PLOTPRMM Plot the peak rate and maximum magnitude of a
    %set of events
    figure
    symsize = get_symsize(catalogObject);   
    t=catalogObject.gettimerange();
    days = t(2) - t(1);
    if all(isnan(catalogObject.mag))
        warning('No magnitude data to plot');
    else

        % plot magnitudes
        subplot(2,1,1), scatter(catalogObject.otime, catalogObject.mag, symsize);
        %stem(catalogObject.otime, catalogObject.mag);
        set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
        datetick('x');
        xlabel('Date');
        ylabel('Magnitude');
        grid on;

        % put 'MM' label by max mag event
        [mm, mmi] = max(catalogObject.mag);
        text(catalogObject.otime(mmi), catalogObject.mag(mmi), 'MM','color','r');
        disp(sprintf('MM=%.1f occurs at %.1f%% of time series',mm,100*(catalogObject.otime(mmi) - t(1))/days));

        % plot event rate in 100 equal bins
        
        binsize = days/100;
        erobj = catalogObject.eventrate('binsize',binsize);
        %erobj = catalogObject.eventrate();
        subplot(2,1,2),plot(erobj.time, erobj.counts);
        set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
        datetick('x');
        xlabel('Date');
        ylabel('Event Rate');
        grid on; 

        % put 'PR' label by peak-rate
        [pr, pri] = max(erobj.counts);
        text(erobj.time(pri), erobj.counts(pri), 'PR','color','r');               
        disp(sprintf('PR=%d occurs at %.1f%% of time series',pr,100*(erobj.time(pri) - erobj.snum)/(erobj.enum-erobj.snum)));
    end
end
