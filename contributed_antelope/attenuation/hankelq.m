function hankelq(dbpath, expr, f1, f2, pretrigger, posttrigger, max_arrivals)
%HANKELQ Compute spectral ratio in two frequency bands
%   HANKELQ(dbpath, expr, freq_high, freq_low, pretrigger_seconds, posttrigger_seconds, max_arrivals ) 
%   Loads arrivals from an arrival table (after subsetting with expr)
%   retrieves waveform data corresponding to those arrivals, cleans and
%   plots the waveform data. The spectral ratio in bands around freq_high
%   and freq_low is computed. When done for multiple earthquakes, a plot of this the 
%   natural log of this ratio versus travel time has a slope from which Q
%   can be measured.
%   pretrigger_seconds is the number of seconds before the arrival time to
%   get waveform data for.
%   posttrigger_seconds is the number of seconds after the arrival time to
%   get waveform data for.
%   max_arrivals is the maximum number of arrivals to process. 
%
%     Based on the method of Arthur Hankel, "The Effects of Attenuation and
%     Site Response on the Spectra of Microearthquakes in the Northeastern
%     Caribbean", BSSA, 72, 4, 1379-1402.
%
%   Example:
%       hankelq('/raid/data/antelope/databases/PLUTONS/dbmerged', 'sta==''PLWB'' && iphase==''P''', 20, 5, 0.3, 1.28, 10);
%
%   History:
%     April 2014: Glenn Thompson
%       Original version: load arrivals, load waveforms and plot waveforms
%     April-November 2014: Heather McFarlin
%       Modified to also plot amplitude spectra
%     November 20, 2014: Glenn Thompson
%       Completely overhauled & modularized.
%       Modified method to compute amplitude spectra. Now computes Q too. Now
%       also generic - works with input variables so it can be used on different
%       databases, for example.

    if ~admin.antelope_exists
	warning('Antelope not installed on this computer')
	return
    end

    if ~exist('max_arrivals','var')
        max_arrivals=Inf;
    end

    taper_seconds=pretrigger+posttrigger;

    arrivals = antelope.dbgetarrivals(dbpath, expr);
    w = antelope.arrivals2waveforms(dbpath, arrivals, pretrigger, posttrigger, taper_seconds, max_arrivals);
    %w = waveform_clean(w);
    [y, t]=plot_arrival_waveforms(arrivals, w, pretrigger, posttrigger, taper_seconds, max_arrivals, f1, f2);
    
    % This is the figure we use to derive q from spectral ratios for
    % earthquakes of different distances (travel times)
    % Q comes from the slope
    figure;
    plot(t, y, 'o');
    ylabel('ln(A_1/A_2)')
    xlabel('travel time (s)')
    p = polyfit(t,y,1);
    xlim=get(gca,'XLim');
    yline = polyval(p, xlim);
    hold on;
    plot(xlim, yline)
    
    slope = (yline(2) - yline(1)) / (xlim(2) - xlim(1));
    q = - pi * (f1 - f2) / slope;
    title(sprintf('Q = %.0f', q));
end

function [y, t] = plot_arrival_waveforms(arrivals, w, pretrigger, posttrigger, taper_seconds, max_arrivals, f1, f2)
    FMIN = 1.0;
    close all
    
    %% open an output file
    fid=fopen([mfilename,'.txt'],'w');
    
    taper_fraction = (taper_seconds * 2) / (taper_seconds * 2 + pretrigger + posttrigger);
    
    % get travel time for p-wave
    p_time = arrivals.time-arrivals.otime;

    % time conversion
    anum = epoch2datenum(arrivals.time);

    for i=1:min([max_arrivals numel(w)])
        signal = get(w(i),'data');
        N = length(signal);
        if N>0
            
            % taper, filter to remove long period noise, and cut out tapered signal to leave only
            % untapered signal
            wf = w(i);
            
            taperwin=tukeywin(N, taper_fraction);
            signal=signal.*taperwin;   
            wf = set(wf, 'data', signal);
            fmax = get(wf, 'freq') * 0.4;
            fobj = filterobject('b', [FMIN fmax], 2); 
            wf = filtfilt(fobj, wf);
            [snum, enum]=gettimerange(wf);
            wf=subtime(wf, snum+taper_seconds/86400, enum-taper_seconds/86400);
            
            % integrate
            dwf = integrate(wf);

            % Plot waveform
            figure(i)
            subplot(3,1,1);
            plot(w(i), 'xunit', 'date', 'color', 'r'); %unfiltered signal
            hold on;
            plot(wf, 'xunit', 'date', 'color', 'g'); %filtered signal
            xlabel(sprintf('Time with arrival at %s',datestr(anum(i), 'yyyy-mm-dd HH:MM:SS.FFF')));
            ylabel('Velocity'); 
            title(sprintf('%s.%s',arrivals.sta{i},arrivals.chan{i}));
            % plot arrival time as grey dotted line
            ylim=get(gca,'YLim');
            plot([anum(i) anum(i)],ylim,'Color',[0.5 0.5 0.5], 'linestyle', '--')
            hold off            
            
            subplot(3,1,2);
            plot(dwf, 'xunit', 'date', 'color', 'b'); %filtered & integrated signal
            xlabel(sprintf('Time with arrival at %s',datestr(anum(i), 'yyyy-mm-dd HH:MM:SS.FFF')));
            ylabel('Displacement'); 
            title(sprintf('%s.%s',arrivals.sta{i},arrivals.chan{i}));
            % plot arrival time as grey dotted line
            ylim=get(gca,'YLim');
            hold on
            plot([anum(i) anum(i)],ylim,'Color',[0.5 0.5 0.5], 'linestyle', '--')
            hold off  
            
            % compute and plot amplitude spectrum
            [A, phi, f] = amplitude_spectrum(dwf);
            subplot(3,1,3)
            plot(f,A);
            %loglog(f, A)
            xlabel('Frequency (Hz)')
            ylabel('Displacement Amplitude Spectrum')
            
            % evaluate the spectral ratio
            A1=mean(A(find(f>=f1*0.9 & f<=f1*1.1))); %  for 20 Hz, this is 18-22 Hz
            A2=mean(A(find(f>=f2*0.8 & f<=f2*1.2 ))); % for 5 Hz this is 4-6 Hz
            disp(sprintf('A1 = %6.3f, A2 = %6.3f, A1/A2 = %5.2f',A1, A2, A1/A2));

            % add title
            outstr=sprintf('phase=%s orid=%d seaz=%6.2f delta=%5.3f depth=%5.1f\nA1=%5.3f A2=%5.3f A1/A2=%5.2f\n',arrivals.phase{i}, arrivals.orid(i), arrivals.seaz(i), arrivals.delta(i), arrivals.depth(i), A1, A2, A1/A2);
            title(outstr)

            % write out to file & close plot
            filename=sprintf('%s-%d',mfilename,i);
            print('-dpng', figure(i),filename)
            close
            
            % compute y=ln A1/A2 & t for formula 2 in Hankel (1982)
            y(i) = log(A1/A2);
            [times, phasenames] = arrtimes(arrivals.delta(i), arrivals.depth(i));
            phase_index = 1;
            found = false;
            while phase_index <= length(times) & ~found
                thisphase = lower(phasenames{phase_index});
                thisphase = thisphase(1);
                if strcmp(lower(arrivals.phase{i}), thisphase)
                    t(i)=times(phase_index);
                    found=true;
                end
                phase_index = phase_index + 1;
            end
             
            %% write out to file
            fprintf(fid,'%14.2f %8.2f %6.3f %5.1f %4.1f %4.1f %e %e\n', p_time(i), t(i), arrivals.delta(i), arrivals.depth(i), f1, f2, A1, A2);
               
        end

    end
    
    %% close output file
    fclose(fid);
end 











