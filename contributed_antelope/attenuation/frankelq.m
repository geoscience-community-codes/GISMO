function arrivalobj = frankelq(dbpath, varargin)
%expr, f1, f2, pretrigger, posttrigger, max_arrivals)
%FRANKELQ Estimate Q via the Frankel method (1982).
% FRANKELQ(dbpath) estimate seismic attenuation quality factor, Q, by the 
% via method described in A. Frankel (1982), "The Effects of Attenuation 
% and Site Response on the Spectra of Microearthquakes in the Northeastern
% Caribbean", BSSA, 72, 4, 1379-1402. The algorithm is as follows:
%   1. Arrival times are loaded from an Antelope CSS3.0 database, dbpath.
%   This must contain a seismic event catalog with arrival table. If assoc, 
%   origin, and event tables are present, those will be joined also, 
%   enabling more complex dbeval subset expressions (see 'expr' name-value
%   pair, below). There must also be a corresponding wfdisc table that links to
%   continuous waveform data stored in Miniseed or SAC format. * Dependencies
%   include Antelope, the Antelope toolbox for MATLAB, and GISMO *.
%   2. For each arrival time, the corresponding waveform data are loaded,
%   using a 0.5-s pre-trigger and 1.5-s post-trigger time window (2-s total).
%   3. For each arrival time, the travel time is also computed, using the
%       origin time of the seismic event.
%   4. Spectra (periodograms) are computed for each 2-s waveform.
%   5. A lower frequency in the range 3.3-7.5 Hz is randomly chosen.
%   6. A higher frequency in the range 13.3-30 Hz is randomly chosen.
%   7. For each spectrum, the spectral amplitude at the higher frequency 
%       is divided by the spectral amplitude at the lower frequency. Each
%       spectral ratio is saved.
%   8. The natural logarithm of each spectral ratio is plotted against the
%       corresponding travel time.
%   9. A linear regression line is fit to the spectral ratio versus travel
%       time graph. 
%   10. The slope of this line gives an estimate of Q.
%   11. Steps 5-10 are repeated 10 times for different choices of
%       lower and higher frequency, generating more estimates of Q.
%   12. The distribution of Q estimates is plotted, and the corresponding
%       average Q and uncertainty are estimated.
%
% Default parameters can be overriden with name-value pairs, e.g.
%  FRANKELQ(dbpath, 'expr', expr) allows the user to specify an Antelope
%  dbeval expression to subset the database with. Typically, it only makes
%  sense to run FRANKELQ on one station at a time, so an example is:
%   %       dbpath = 'home/heather/Desktop/PLUTONS/dbmerged'
%   %       dbeval_expr = 'sta==''PLWB'' && iphase==''P'''
%   %       FRANKELQ(dbpath, 'expr', dbeval_expr)
%  Additional filtering could be performed for a circular radius, a depth
%  range, and/or a time range.
%
%  FRANKELQ(dbpath, 'pretrigger', 1, 'posttrigger', 0.5) sets the
%  pretrigger window to 1-s and the posttrigger window to 0.5-s.
%
%  FRANKELQ(dbpath, 'f1', [3.0 7.0], 'f2', [13.0 30.0]) sets the lower
%  frequency range to 3-7 Hz and the upper frequency range to 13-30 Hz.
%
%  FRANKELQ(dbpath, 'max_arrivals', 10) sets the maximum number of arrivals
%  to load to 10 (Default: 999).
%
%  FRANKELQ(dbpath, 'num_iterations', 20) sets the number of iterations,
%  i.e. the number of different frequency pairs chosen, to 20. Default: 10
%
%  Boolean parameters:
%
%  FRANKELQ(dbpath, 'INTEGRATE', true) will cause waveform data to be 
%  integrated (e.g. from velocity to displacement seismograms), prior to 
%  computing spectra. Default: false.
%
%  FRANKELQ(dbpath, 'SMOOTH', true) will cause amplitude spectra to be 
%  smoothed, prior to computing spectral ratios, in the "Compute spectra" 
%  step. By default, spectra are not smoothed, but this can lead to less
%  stable spectral ratios, and therefore more scatter in plots of spectral
%  ratio vs. travel time. Default: true
%
%  FRANKELQ(dbpath, 'PLOT', true) will cause waveform data and spectra to 
%  be plotted in the "Compute spectra" step, and spectral ratio vs. travel
%  time plots for each iteration in "Estimate Q" step. These are important
%  for checking the quality of the waveform data, the stability of the
%  spectra, and the fit of the regression lines. Default: true
%
%
%  Example explicitly overriding all name-value pairs:
%       dbpath = 'home/heather/Desktop/PLUTONS/dbmerged'
%       dbeval_expr = 'sta==''PLWB'' && iphase==''P'''
%       FRANKELQ(dbpath, 'expr', dbeval_expr, 'f1', [3 7], 'f2' [13 30], ...
%           'pretrigger', 0.3, 'posttrigger', 1.28, 'max_arrivals', 100, ...
%           'num_iterations', 30, 'PLOT', true, 'SMOOTH', true, ...
%           'INTEGRATE', TRUE);

%   History:
%     April 2014: Glenn Thompson
%       Original version: load arrivals, load waveforms and plot waveforms
%     April-November 2014: Heather McFarlin
%       Modified to also plot amplitude spectra
%     November 20, 2014: Glenn Thompson
%       Modified method to compute amplitude spectra. Now computes Q too. Now
%       also generic - works with input variables so it can be used on different
%       databases, for example.
%     November 2017: Glenn Thompson
%       Fixed to work with updated GISMO classes
%     Heather McFarlin
%       Added units to Y-axis on plots
%       Added amplitude spectrum of noise before waveform onto amplitude spectrum plot
%       Tried to implement t* method (reference needed)
%
% To do:
%   * Estimate Q and uncertainty in Q by iterating over a range of lower
%       and upper frequency values.
%   * Implement azimuthal dependence. Filter using seaz parameter?

    close all, clc
    
    if ~admin.antelope_exists
        warning('Antelope not installed on this computer')
        return
    end

    % Parse input variables
    p = inputParser;
    p.addParameter('expr', '');
    p.addParameter('f1', [3.3 7.5]);
    p.addParameter('f2', [13.3 30]);
    p.addParameter('pretrigger', 0.5);
    p.addParameter('posttrigger', 1.5);
    p.addParameter('max_arrivals', 999);
    p.addParameter('PLOT', true);
    p.addParameter('INTEGRATE', false);
    p.addParameter('SMOOTH', true);
    p.parse(varargin{:});
    expr = p.Results.expr;
    f1 = p.Results.f1;
    f2 = p.Results.f2;
    pretrigger = p.Results.pretrigger;
    posttrigger = p.Results.posttrigger;
    max_arrivals = p.Results.max_arrivals;
    PLOT = p.Results.PLOT;
    INTEGRATE = p.Results.INTEGRATE;
    SMOOTH = p.Results.SMOOTH;
    iphases = {'P';'S'};
    taper_seconds=(pretrigger+posttrigger)*10+10;
    save frankelq_params.mat
    
    while 1,
        if PLOT
            plotstr = 'Toggle plotting OFF';
        else
            plotstr = 'Toggle plotting ON';
        end
        choice = menu('Choose wisely', ...
            'Load arrivals in GISMO Arrival object', ...
            'Add waveforms to arrivals', ...
            'Compute spectra', ...
            'Estimate Q', ...
            plotstr, ...
            'Close all figures', ...
            'Quit');
        switch choice
            case 1, arrivalobj = load_arrivals(dbpath, expr)
            case 2, load_waveforms()
            case 3, compute_spectra()
            case 4, estimate_Q()
            case 5, PLOT=~PLOT
            case 6, close all
            otherwise, break
        end
        
        % Load this here, so the program always returns most recent
        % arrivalobj
        if exist('frankelq_arrivals.mat')
            load frankelq_arrivals.mat arrivalobj
        end
    end
end

function arrivalobj = load_arrivals(dbpath, expr)
    % Load arrivals into a GISMO Arrival object
    if isempty(expr)
        arrivalobj = Arrival.retrieve('antelope', dbpath);
    else
        arrivalobj = Arrival.retrieve('antelope', dbpath, 'subset_expr', expr);
    end
    arrivalobj.otime = epoch2datenum(arrivalobj.otime);
    % Compute travel time.
    arrivalobj.traveltime = (arrivalobj.time - arrivalobj.otime)*86400; 
    save frankelq_arrivals.mat arrivalobj
    disp('* Finished loading arrivals *')
end

function load_waveforms()
    % subset into P and S
    load frankelq_params.mat
    load frankelq_arrivals.mat
    for iphase_num=1:numel(iphases)
        iphase = iphases{iphase_num};
        arrivalobj2 = arrivalobj.subset('iphase',iphase);

        % just use the first max_arrivals arrivals
        if length(arrivalobj2.time)>max_arrivals
            arrivalobj2 = arrivalobj2.subset(1:max_arrivals);
        end

        % Load corresponding waveform data for each arrival. 
        % We want to load a much longer time window so we can detrend, taper, 
        % filter & integrate with more stability. This is what taper_seconds is for.
        
        try
            arrivalobj2 = arrivalobj2.addwaveforms(datasource('antelope', dbpath), pretrigger+taper_seconds, posttrigger+taper_seconds);
        catch
            return
        end
        if strcmp(iphase,'P')
            save frankelq_waveforms_P.mat arrivalobj2
            disp('* Finished loading waveforms corresponding to P arrivals *')
        elseif strcmp(iphase,'S')
            save frankelq_waveforms_S.mat arrivalobj2
            disp('* Finished loading waveforms corresponding to S arrivals *')
        end
    end
    disp('* Finished loading waveforms corresponding to ALL arrivals *')
end

function compute_spectra()
    load frankelq_params.mat
    for iphase_num=1:numel(iphases)
        iphase = iphases{iphase_num};
        if strcmp(iphase,'P')
            load frankelq_waveforms_P.mat arrivalobj2
        elseif strcmp(iphase,'S')
            load frankelq_waveforms_S.mat arrivalobj2
        end        

        taper_fraction = (taper_seconds * 2) / (taper_seconds * 2 + pretrigger + posttrigger); %this defines the perent of tapering for the cosine taper  
        w = arrivalobj2.waveforms;
        high_pass_freq = 0.5; % for detrending
        w = clean(w, high_pass_freq);
        %w = taper(w, taper_fraction);
        spectra = [];
        for i=1:numel(w)
            wf = w(i);

            % extract correct time window
            wf = extract(wf, 'TIME', arrivalobj2.time(i)-pretrigger/86400, arrivalobj2.time(i)+posttrigger/86400);
            [snum, enum]=gettimerange(w(i));
            datestr(arrivalobj2.time(i)-pretrigger/86400)
            wf_noise = extract(wf, 'time', snum, arrivalobj2.time(i)-pretrigger/86400);
            if INTEGRATE
                wf = integrate(wf);
                wf_noise = integrate(wf_noise);
            end

            % compute amplitude spectrum
            s = amplitude_spectrum(wf);
            s_noise = amplitude_spectrum(wf_noise);

            if SMOOTH
                s.amp = smooth(s.amp);
                s_noise.amp = smooth(s_noise.amp);
            end
            spectra = [spectra s s_noise]; 
            
            if PLOT
                plot_waveforms_and_spectrum(w(i), wf, s)
                choice = menu('Menu', 'show next plot', 'skip rest of plots');
                switch choice
                    case 1, continue
                    case 2, PLOT=false
                end      
            end
            
        end
        if strcmp(iphase,'P')
            save allspectra_P.mat spectra
            disp('* Finished computing spectra corresponding to P arrivals *')
        elseif strcmp(iphase,'S')
            save allspectra_S.mat spectra
            disp('* Finished computing spectra corresponding to S arrivals *')
        end
    end
    disp('* Finished computing spectra corresponding to ALL arrivals *')
end

function plot_waveforms_and_spectrum(w, wf, s)
    figure

    ti = get(w, 'timevector');
    tf = get(wf, 'timevector');
    subplot(2,1,1), plot(ti, get(w, 'data'), 'b');
    datetick('x','HH:MM:SS', 'keeplimits')
    hold on 
    plot(tf, get(wf, 'data'), 'r');

    subplot(2,1,2), plot(s.f, log(s.amp))
    xlabel('Frequency (Hz)')
    ylabel('ln(Amplitude)')
end

function estimate_Q()
    load frankelq_params.mat

    for iphase_num=1:numel(iphases)
        iphase = iphases{iphase_num};  
        if strcmp(iphase,'P')
            load frankelq_waveforms_P.mat arrivalobj2
            load allspectra_P.mat spectra
        elseif strcmp(iphase,'S')
            load frankelq_waveforms_S.mat arrivalobj2
            load allspectra_S.mat spectra
        end   
        
        % Compute spectral ratio based on multiple random choices of f_low and f_high
        numFreqTrials=100;
        allQ = [];
        for freqTrialNum=1:numFreqTrials
            thisFreqQ = [];
            spectral_ratios = [];
            f_low = f1(1) + (f1(2)-f1(1)).*rand(1,1);
            f_high = f2(1) + (f2(2)-f2(1)).*rand(1,1);
            for i=1:numel(arrivalobj2.time)
                s = spectra(i*2-1);
                s_noise = spectra(i*2);
                sr = compute_spectral_ratio(s, s_noise, f_low, f_high);
                spectral_ratios = [spectral_ratios sr];
            end
            
            if PLOT
                figure
                plot(arrivalobj2.traveltime, spectral_ratios,'o')
                xlabel('Travel time (s)')
                ylabel(sprintf('Log(A(%.1fHz)/A(%.1fHz))',f_low, f_high))
                %title(sprintf('iphase = %s',iphases{iphase_num}))
                %xlim=get(gca,'XLim');
            end     
            
            % linear regression and Q estimate 
            numJackKnifeTrails = 100;
            numArrivals = length(arrivalobj2.time);
            jackKnifeNumArrivals = round(numArrivals*0.5);
            for jackKnifeTrialNum=1:numJackKnifeTrails
                % choose 50% of samples
                indices = randperm(numArrivals);
                indices = indices(1:jackKnifeNumArrivals);
                [p,S] = polyfit(arrivalobj2.traveltime(indices), spectral_ratios(indices),1);
                xlim=[min(arrivalobj2.traveltime) max(arrivalobj2.traveltime)];
                [yline,delta] = polyval(p, xlim, S);
                delta = mean(delta); % not sure why delta has two elements
                slope = (yline(2) - yline(1)) / (xlim(2) - xlim(1));
                steepest_slope = (   (yline(2) - delta) - (yline(1)+delta) ) / (xlim(2) - xlim(1));
                shallowest_slope = ( (yline(2) + delta) - (yline(1)-delta) ) / (xlim(2) - xlim(1));
                Q = -pi * (f_high - f_low) / slope;
                maxQ = -pi * (f_high - f_low) / steepest_slope;
                minQ = -pi * (f_high - f_low) / shallowest_slope;
                thisFreqQ = [thisFreqQ Q]; % Q maxQ minQ]; % weight central value twice
            
                if PLOT
                    hold on;
                    plot(xlim, yline) 
                    % could add 1 or 2 stdev lines here
                end
            end
            if PLOT
                title(sprintf('Q_{%s} = %.0f', iphase, nanmean(thisFreqQ), nanstd(thisFreqQ)));
                choice = menu('Menu', 'show next plot', 'skip rest of plots');
                switch choice
                    case 1, continue
                    case 2, PLOT=false
                end
            end
            allQ = [allQ thisFreqQ];
            
        end
        fprintf('Q_{%s}:\n\tmean = %.0f\n\tstdev = %.0f\n', iphase, nanmean(allQ), nanstd(allQ) )
        fprintf('\tmedian = %.0f\n\t68%% chance in range %.0f to %.0f\n', nanmedian(allQ), prctile(allQ, 16), prctile(allQ, 84) )
        fprintf('\t95%% chance in range %.0f to %.0f\n', prctile(allQ, 2.5), prctile(allQ, 97.5) )
        n = length(allQ(allQ>10 & allQ<2000));
        fprintf('\t%.0f%% of Q estimates are in range 10-2000\n', 100*n/length(allQ) ) 


        figure
        plot(1:99, prctile(allQ, 1:99))
        hold on
        plot(50,nanmedian(allQ),'*')
        text(50,nanmedian(allQ),'median')
        plot([0 100],[nanmean(allQ) nanmean(allQ)])
        text(30,nanmean(allQ),'mean')
                
        text(10,prctile(allQ,99), ...
            sprintf('mean = %.0f\nstdev = %.0f\nmedian = %.0f\n68%% chance in range %.0f to %.0f\n95%% chance in range %.0f to %.0f\n', ...
            nanmean(allQ), nanstd(allQ), nanmedian(allQ), ...
            prctile(allQ, 16), prctile(allQ, 84), prctile(allQ, 2.5), ...
            prctile(allQ, 97.5) ), ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top')
        xlabel('Percentile')
        ylabel(sprintf('Q_{%s}',iphase))
        title(sprintf('Distribution of Q_{%s} estimates', iphase))
    end
end

function sr = compute_spectral_ratio(s, s_noise, f_low, f_high)

    % evaluate the spectral ratio
    A1=nanmean(s.amp(find(s.f>=f_low*0.9 & s.f<=f_low*1.1))); 
    A2=nanmean(s.amp(find(s.f>=f_high*0.9 & s.f<=f_high*1.1 )));   
    sr = log(A1/A2);
%     disp(sprintf('A1 = %6.3f, A2 = %6.3f, A1/A2 = %5.2f', A1, A2, A1/A2));
% 
%     % predicted arrival times
%     %[times, phasenames] = arrtimes(arrivalobj.delta(i), arrivalobj.depth(i));
% 
%     %evaluate spectral ratio of  noise
%     A1_noise = nanmean(s_noise.amp(find(s_noise.f>=f_low*0.9 & s_noise.f<=f_low*1.1)));
%     A2_noise = nanmean(s_noise.amp(find(s_noise.f>=f_high*0.9 & s_noise.f<=f_high*1.1))); 
%     snr1 = A1/A1_noise;
%     snr2 = A2/A2_noise;
%     disp(sprintf('SNR1 = %6.3f, SNR2 = %6.3f', snr1, snr2));

end
