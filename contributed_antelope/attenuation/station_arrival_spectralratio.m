function [y, t] = station_arrival_spectralratio(dbpath, expr, pretrigger, posttrigger, f1, f2, max_arrivals)
%   Loads arrivals from an arrival table (after subsetting with expr)
%   retrieves waveform data corresponding to those arrivals, cleans and
%   plots the waveform data. The spectral ratio in bands around freq_high
%   and freq_low is computed. 
%   expr is Antelope expression for subsetting the database
%   pretrigger_seconds is the number of seconds before the arrival time to
%   get waveform data for.
%   posttrigger_seconds is the number of seconds after the arrival time to
%   get waveform data for.
%   f1 and f2 are the frequencies to be used for the spectral ratios
%   max_arrivals is the maximum number of arrivals to process. 

%   Example:
%       dbpath = 'home/heather/Desktop/PLUTONS/dbmerged'
%       expr = 'sta==''PLWB'' && iphase==''P'''
%       singlestation_specrat(dbpath, expr, 20, 5, 0.3, 1.28, 10);
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
%     November 2017: Glenn Thompson
%       Fixed to work with updated GISMO classes
%                    Heather McFarlin
%       Added units to Y-axis on plots
%       Added amplitude spectrum of noise before waveform onto amplitude
%       spectrum plot
%     February 2019: Heather McFarlin
%       lines 206 and 207 have comments added-may need to change f1*## and
%       f2*## to account for difference frequencies used (testing for
%       frequency-dependence)
%       lines 86-90 may need to be altered to [p, S] or [p, S, mu] to get
%       standard deviations and R^2 values
%     November-January 2023: Heather McFarlin
%       Split the entire script into 2: 1 to read in the waveforms and
%       calculate the spectral ratios (station_arrival_spectralratio.m) and
%       one to plot the spectral ratios vs time, and calculate Q
%       (singlestation_Q.m)
%       Changed output file to be a .mat file
%%
%   First, make sure that Antelope exists
    if ~admin.antelope_exists
        warning('Antelope not installed on this computer')
        return
    end
%   Check to see if there is a limit to the number of arrivals
    if ~exist('max_arrivals','var')
        max_arrivals=Inf;
    end
%   Calculate the number of seconds for the cosine taper
    taper_seconds=pretrigger+posttrigger;
%   Read in the Antelope database    
    arrivalobj = Arrival.retrieve('antelope', dbpath, 'subset_expr', expr);
%   Add the waveforms to the Arrival Object
    arrivalobj = arrivalobj.addwaveforms(datasource('antelope', dbpath), pretrigger+taper_seconds, posttrigger+taper_seconds);
    close all
%   Set the station and Phase for the output file (.mat file) 
    sta = "PL03";
    phase = "S";
%   Set the minimum frequency
    FMIN = 1.0;
%   Calculate the percent of the cosine taper   
    taper_fraction = (taper_seconds * 2) / (taper_seconds * 2 + pretrigger + posttrigger);
    
%   Get travel time for p-wave
    p_time = arrivalobj.time - arrivalobj.otime;
    anum = arrivalobj.time;
    
%   Initialize arrays for the output file    
    w = arrivalobj.waveforms;
    A1 = zeros(1, numel(w));
    A2 = zeros(1, numel(w));
    A1_noise = zeros(1, numel(w));
    A2_noise = zeros(1, numel(w));
    spectra = [];
%   Clean up the waveforms (detrend, filter, integrate, taper), plot the
%   waveforms, calculate the spectra and plot it. Then write everything to
%   an output file
    for i=1:min([max_arrivals numel(w)])
        signal = get(w(i),'data');
        N = length(signal);
        if N>0
            
%   Taper, filter to remove long period noise, and cut out tapered signal to leave only
%   untapered signal
            wf = w(i);
            
            taperwin=tukeywin(N, taper_fraction); % defines what type of taper to use 
            signal=signal.*taperwin;   
            wf = set(wf, 'data', signal);
            fmax = get(wf, 'freq') * 0.4;
            fobj = filterobject('b', [FMIN fmax], 2); 
            wf = filtfilt(fobj, wf);
            [snum, enum]=gettimerange(wf);      
%   Get noise before event 
            wf_noise = extract(wf, 'time', snum, anum(i)-pretrigger/86400);
            wf=extract(wf, 'time', snum+taper_seconds/86400, enum-taper_seconds/86400);
%   Integrate
            dwf = integrate(wf);
%   Integrate noise
            dwf_noise = integrate(wf_noise);
%   Plot waveforms
%   Figure('visible', 'off'); turned off to make sure figures are
%   all correct
            close all
            figure
            ax(i,1)=subplot(3,1,1); 
%   Plot unfiltered signal
            plot(w(i), 'xunit', 'date', 'color', 'r', 'axeshandle', ax(i,1));
            datetick('x','HH:MM:SS', 'keeplimits')
            hold on;
%   Plot filtered signal 
            plot(wf, 'xunit', 'date', 'color', 'g', 'axeshandle', ax(i,1));
            datetick('x','HH:MM:SS','keeplimits')
            hold on
%   Plot the noise
            plot(wf_noise, 'xunit', 'date', 'color', 'k', 'axeshandle', ax(i,1)) 
            datetick('x','HH:MM:SS', 'keeplimits')
            xlabel(sprintf('Time with arrival at %s',datestr(anum(i), 'yyyy-mm-dd HH:MM:SS.FFF')));
            ylabel('Velocity (nm/s)'); 
            title(sprintf('%s',arrivalobj.channelinfo{i}));
%   Plot arrival time as grey dotted line
            ylim=get(gca,'YLim');
            hold on
            plot([anum(i) anum(i)],ylim,'Color',[0.5 0.5 0.5], 'linestyle', '--')
            hold off            
%   Plot the integrated waveform (the waveform is only
%   integrated over the length of the signal defined in the
%   command line (i.e. 1.28 seconds after the phase arrival)
            ax(i,2)=subplot(3,1,2);
%   Plot the displacement waveform
            plot(dwf, 'xunit', 'date', 'color', 'b', 'axeshandle', ax(i,2)); 
            datetick('x','HH:MM:SS:FFF', 'keeplimits', 'keepticks')
            xlabel(sprintf('Time with arrival at %s',datestr(anum(i), 'yyyy-mm-dd HH:MM:SS.FFF')));
            ylabel('Displacement (nm)'); 
            title(sprintf('%s',arrivalobj.channelinfo{i}));
%   Plot arrival time as grey dotted line
            ylim=get(gca,'YLim');
            hold on
            plot([anum(i) anum(i)],ylim,'Color',[0.5 0.5 0.5], 'linestyle', '--')
            hold off  
%   Compute and plot amplitude spectrum
            s = amplitude_spectrum(dwf);
            A = s.amp;
            f = s.f;
            phi = s.phi;
%   log(A) is a natural log, not a log10. Do this instead of plotting on a
%   semilog plot so that curve-fitting/linear regression later on is easier
            A_log = log(A); 
            ax(i,3)=subplot(3,1,3);
            plot(f, A_log)
            size(f)
            xlabel('Frequency (Hz)')
            ylabel('ln(Amplitude) (nm)')
            hold on
%   Add noise spectrum
            s_noise = amplitude_spectrum(dwf_noise);
            A_noise = s_noise.amp;
            f_noise = s_noise.f;
            phi_noise = s_noise.phi;
            A_noise_log = log(A_noise);
            plot(f_noise, A_noise_log, 'color', 'r');
            size(f_noise)
            hold on
%   Evaluate the spectral ratio
%   For 20 Hz, this takes the average of 18-22 Hz
            A1(i)=mean(A(find(f>=f1*0.9 & f<=f1*1.1)));
%   For 5 Hz, this takes the average of 4-6 Hz
            A2(i)=mean(A(find(f>=f2*0.8 & f<=f2*1.2)));   
            patch([f1*0.9 f1*1.1 f1*1.1 f1*0.9],[A1(i) A1(i) A1(i) A1(i)],[0.9 0.9 0.9])
            patch([f2*0.8 f2*1.2 f2*1.2 f2*0.8],[A2(i) A2(i) A2(i) A2(i)],[0.9 0.9 0.9])
            
%   Evaluate spectral ratio of  noise
            A1_noise(i)= mean(A_noise(find(f_noise>=f1*0.9 & f_noise<=f1*1.1))); 
            A2_noise(i) = mean(A_noise(find(f_noise>=f2*0.8 & f_noise<=f2*1.2))); 
            patch([f1*0.9 f1*1.1 f1*1.1 f1*0.9],[ A1_noise(i) A1_noise(i) A1_noise(i) A1_noise(i)],[0.9 0.9 0.9])
            patch([f2*0.8 f2*1.2 f2*1.2 f2*0.8],[ A2_noise(i) A2_noise(i) A2_noise(i) A2_noise(i)],[0.9 0.9 0.9])
            snr1 = (A1(i))/(A1_noise(i));
            snr2 = (A2(i))/(A2_noise(i));
%                       
            spectra = [spectra s s_noise]; 
            if strcmp(phase,'P')
                save allspectra_P.mat spectra
            %disp('* Finished computing spectra corresponding to P arrivals *')
            elseif strcmp(phase,'S')
                save allspectra_S.mat spectra
            %disp('* Finished computing spectra corresponding to S arrivals *')
            end
            
%   Compute y=ln A1/A2 & t for formula 2 in Frankel (1982)
            y(i) = log(A1(i)/A2(i));
            [times, phasenames] = arrtimes(arrivalobj.delta(i), arrivalobj.depth(i));
            phase_index = 1;
            found = false;
            while phase_index <= length(times) & ~found
                thisphase = lower(phasenames{phase_index});
                thisphase = thisphase(1);
                if strcmp(lower(arrivalobj.iphase{i}), thisphase)
                    t(i)=times(phase_index);
                    found=true;
                end
                phase_index = phase_index + 1;
            end
            hold off
%   For saving into .mat file
            orid(i) = arrivalobj.orid(i);
            seaz(i) = arrivalobj.seaz(i);
            delta(i) = arrivalobj.delta(i);
            depth(i) = arrivalobj.depth(i);
   

%   Write out to files and save
            filename=sprintf('%s-%d.png',mfilename,i);
            print('-dpng','-f1',filename)
            station_arrival_spectralratio = matfile('station_arrival_spectralratio.mat','Writable', true)
            save('station_arrival_spectralratio.mat', 'sta', 'phase', 'orid', 'seaz', 't', 'delta', 'depth', 'A1', 'A2', 'A1_noise', 'A2_noise', 'y')  
          
        end
    end
end 

