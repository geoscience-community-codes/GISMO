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
        subplot(2,2,1), scatter(catalogObject.otime, catalogObject.mag, symsize);
        %stem(catalogObject.otime, catalogObject.mag);
        set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
        datetick('x');
        xlabel('Date');
        ylabel('Magnitude');
        grid on;

        % put 'MM' label by max mag event
        [mm, mmi] = max(catalogObject.mag);
        text(catalogObject.otime(mmi), catalogObject.mag(mmi), 'MM','color','r');
        title(sprintf('MaxMag %.1f occurs at %.1f%%',mm,100*(catalogObject.otime(mmi) - t(1))/days));

        % bin data, each bin is 1% wide and moves 0.1%      
        binsize = days/100;
        stepsize = binsize/10;
        erobj = catalogObject.eventrate('binsize',binsize,'stepsize',stepsize);
        
        % plot event rate in 100 equal bins 
        subplot(2,2,3),plot(erobj.time, erobj.counts);
        set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
        datetick('x');
        xlabel('Date');
        ylabel('Event Rate');
        grid on; 

        % put 'PR' label by peak-rate
        [pr, pri] = max(erobj.counts);
        text(erobj.time(pri), erobj.counts(pri), 'PR','color','r');               
        title(sprintf('Peak event rate %d occurs at %.1f%%',pr,100*(erobj.time(pri) - erobj.snum)/(erobj.enum-erobj.snum)));

        % find peaks in event rate
        [pks, locs, pkwidth, pkprom] = findpeaks(erobj.counts, erobj.time, ...
            'MinPeakHeight', max(erobj.counts)/5, 'SortStr', 'descend');
        minPeakProm = max(pkprom)/5;
        i = find(pkprom>=minPeakProm);
        pks=pks(i);
        locs=locs(i);
        pkwidth=pkwidth(i);
        datestr(locs)
        hold on
        plot(locs, pks, 'k*')
        
        % plot cum mag and plot peak cum mag
        subplot(2,2,2),plot(erobj.time, erobj.cum_mag);
        set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
        datetick('x');
        xlabel('Date');
        ylabel('Cum Mag');
        grid on;     
        
        % put 'PCumMag' label
        [pcm, pcmi] = max(erobj.cum_mag);
        text(erobj.time(pcmi), erobj.cum_mag(pcmi), 'PCM','color','r');               
        title(sprintf('Peak CumMag %.1f occurs at %.1f%%',pcm,100*(erobj.time(pcmi) - erobj.snum)/(erobj.enum-erobj.snum)));

        
        % find peaks in cum_mag
        [pks, locs, pkwidth, pkprom] = findpeaks(erobj.cum_mag, erobj.time, ...
            'MinPeakHeight', max(erobj.cum_mag)-1, 'SortStr', 'descend');
        minPeakProm = max(pkprom)/2;
        i = find(pkprom>=minPeakProm);
        pks=pks(i);
        locs=locs(i);
        pkwidth=pkwidth(i);
        
        %, 'NPeaks',3);
        datestr(locs)
        hold on
        plot(locs, pks, 'k*')
        
%         % plot mag trends
%         subplot(2,2,4)
%         plot(erobj.time, erobj.max_mag, 'ro');
%         hold on
%         plot(erobj.time, erobj.mean_mag, 'bo');
%         plot(erobj.time, erobj.median_mag, 'go');
%         plot(erobj.time, erobj.min_mag, 'co');
%         plot(erobj.time, smooth(erobj.max_mag), 'r')
%         plot(erobj.time, smooth(erobj.mean_mag), 'b');
%         plot(erobj.time, smooth(erobj.median_mag), 'g');
%         plot(erobj.time, smooth(erobj.min_mag), 'c');
%         hold off
%         set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
%         datetick('x');
%         xlabel('Date');
%         ylabel('Cum Mag');
%         grid on;    
 

        % plot mag trends
        subplot(2,2,4)
        plot(erobj.time, erobj.max_mag, 'r');
        hold on
        plot(erobj.time, erobj.mean_mag, 'b');
        plot(erobj.time, erobj.median_mag, 'g');
        plot(erobj.time, erobj.min_mag, 'c');
        hold off
        set(gca, 'XLim', [floor(t(1)) ceil(t(2))]);
        datetick('x');
        xlabel('Date');
        ylabel('Magnitude');
        grid on; 
        
        % put 'PCumMag' label               
        title('Magnitude stats');
        legend({'Max','Mean','Median','Min'},'Location','southwest', ...
            'NumColumns',2)

        
        save erobj.mat erobj
        
    end
end
