function w = addmetrics(w, varargin)
%ADDMETRICS
% addmetrics(w) will add a metrics structure to each waveform object. This
% metrics structure compute some amplitude, energy and frequency metrics
% for each waveform in waveform vector w, and add them to the 'metrics'
% structure for that waveform. Note that the clean(waveform) method is
% applied before any calculations are made. These metrics are:
% - minAmp    = the minimum (most negative) amplitude
% - maxAmp    = the maximum amplitude
% - p2p       = the maximum peak-to-peak amplitude (maxAmp - minAmp)
% - stdev     = the standard deviation of the amplitude values. This uses
%               the std(waveform) method
% - minTime   = the time (datenum) corresponding to minAmp
% - maxTime   = the time (datenum) corresponding to maxAmp
% - duration  = the duration of the waveform in seconds
%
% addmetrics(w, maxTimeDiff) is a slight variation where the max and min
% found will correspond to the maximum peak to peak variation found within
% a maxTimeDiff timewindow. If not given, or set to 0, the max and min are 
% for the whole waveform. Note that maxTimeDiff should be about 1 to a 
% few periods of the signal you are interested in.
%
% addmetrics(..., 'spectral', 1) will add spectral metrics too. These are
% - peakf     = peak frequency of the waveform
% - meanf     = mean frequency of the waveform
% - freqindex = frequency index (Helena Buurman & Mike West)
% - freqratio = frequency ratio (Mel Rodgers)  
%
% addmetrics(..., 'distance', r) where r is the distance from source to
% sensor in metres allows other metrics to be added. These are:
% - ml        = the Richter magnitude, computed with magnitude.ml_richter(r)
% - energy    = the energy of the waveform in Joules (J). 
% - meanpower = the mean power of the waveform in Watts (W).
% - maxpower  = the maximum power of the waveform in Watts (W).
% - emag      = the energy magnitude, computed with magnitude.eng2mag(energy)
% All these measurements are based on equations in Johnson and Aster (2005).
% Note:
% # There are different correction factors for infrasound and seismic
%   waveforms:
%       Infrasound:   scale_factor = (4 * pi * r^2)/(c_air * rho_air)
%       Seismic:      scale_factor = (4 * pi * r^2)*(c_earth * rho_earth)
%
% # For infrasound, the second character in the waveform channel code must 
%   be 'D' and the waveform units must be 'Pa', otherwise the code is 
%   skipped.
% # For seismic, the waveform units must contain 'nm'. The data should be 
%   in nm / sec, otherwise the answer will be wrong.
% # The densities and speeds assumed are:
%   - rho_air = 1.2 kg / m^3
%   - c_air = 340 m/s
%   - rho_earth = 2500 kg/m3
%   - c_earth = 3000 m/s
% # Both of these equations assume far field body waves. So if you think
%   your waves are surface waves, interface waves, or in a waveguide, these
%   measurements are likely meaningless.
%
% 
% Glenn Thompson



% TO DO: a more efficient 1 period algorithm could use findpeaks, see
% bottom of the m-file
% addmetrics(w, maxTimeDiff, r, Q) will also compute measurements that are
% corrected for attenuation, Q.

p = inputParser;
p.addOptional('maxTimeDiff', 0, @isnumeric)
p.addParameter('spectral', 0, @isnumeric)
p.addParameter('distance', 0, @isnumeric)
p.parse(varargin{:});
% fields = fieldnames(p.Results)
% for i=1:length(fields)
%     field=fields{i};
%     val = p.Results.(field);
%     eval(sprintf('%s = val',field));
% end

    SECONDS_PER_DAY = 86400;
    % set defaults to -1
%     defaultvals = -ones(size(w));
%     maxTime = defaultvals;
%     minTime = defaultvals;
%     maxAmp = defaultvals;
%     minAmp = defaultvals;
%     p2p = defaultvals;
%     stdev = defaultvals;
%     energy = defaultvals;
%     amp = defaultvals;
    Nw = numel(w);
% duration = defaultvals;

    for wavnum=1:Nw
        fprintf('.');
        clear metrics
        
        %thisW = detrend(fillgaps(w(wavnum),'interp')); % make sure there is no trend or offset
        thisW = clean(w(wavnum));
        wstart = get(thisW,'start'); % waveform start time
        wend = get(thisW,'end'); % waveform end time
        wstd = std(thisW); % waveform standard deviation - for noise estimation
        fs = get(thisW,'freq');
        y = get(thisW,'data');
        u = get(thisW,'units');
        metrics.duration   = (wend   - wstart) * SECONDS_PER_DAY;
        
%         %% THIS IS THE START OF AN ATTEMPT TO FIND THE EVENT START AND END TIME BY RUNNING AN STA/LTA
%         close all
%         %plot(thisW)
%         % set the STA/LTA detector
%         sta_seconds = 0.7; % STA time window 0.7 seconds
%         lta_seconds = 10.0; % LTA time window 7 seconds
%         thresh_on = 2.0; % Event triggers "ON" with STA/LTA ratio exceeds 3
%         thresh_off = 1.0; % Event triggers "OFF" when STA/LTA ratio drops below 1.5
%         minimum_event_duration_seconds = 1.0; % Trigger must be on at least 2 secs
%         pre_trigger_seconds = 0; % Do not pad before trigger
%         post_trigger_seconds = 0; % Do not pad after trigger
%         event_detection_params = [sta_seconds lta_seconds thresh_on thresh_off ...
%             minimum_event_duration_seconds];
%         [cobj,sta,lta,sta_to_lta] = Detection.sta_lta(thisW, 'edp', event_detection_params, ...
%             'lta_mode', 'frozen');
% %         h3 = drumplot(thisW, 'mpl', 1, 'catalog', cobj);
% %         plot(h3)
%         input('any key')
%         % Several events may be detected. Need to pick the one at the
%         % expected time, considering the travel time

        
        % WHAT TYPE OF MAXIMUM & MINIMUM DO WE WANT?
        if exist('maxTimeDiff', 'var')
            % compute largest peak to peak amplitude
            % (Note a different algorithm could be added here, using
            % findpeaks)
            metrics.maxTimeDiff = maxTimeDiff;
            
            % Define time window
            numSamples = length(y);
            
            sample_to_end_at   = min( [round( duration   * fs) numSamples]);

            % Loop over subwindows
            % find p2p amplitude in each, compare to highest p2p found so far
            N = round(fs * maxTimeDiff); 

            % COMPUTING AMPLITUDE METRICS
            try
                [vamin, vamax] = running_min_max(y, N);
                vap2p = vamax-vamin; % biggest peak to peak in each timewindow of length N
                [maxap2p, maxap2pindex] = max(vap2p);         
                amin = vamin(maxap2pindex);
                amax = vamax(maxap2pindex);
                amaxindex = find(y==amax);
                aminindex = find(y==amin);
            catch
                [amax, amaxindex] = max(thisW);
                [amin, aminindex] = min(thisW);               
            end
            
        else
            [amax, amaxindex] = max(thisW);
            [amin, aminindex] = min(thisW);
        end
        
        maxSecs = amaxindex/fs;
        minSecs = aminindex/fs;
        maxTime = wstart + maxSecs/SECONDS_PER_DAY;
        minTime = wstart + minSecs/SECONDS_PER_DAY;    
        %amp(wavnum) = round(nanmax(abs([amax amin])), 4, 'significant'); 
        %energy = sum(y.^2)/fs;

        % ADD ALL METRICS TO THE WAVEFORM OBJECT
        metrics.minTime = minTime;
        metrics.maxTime = maxTime;
        metrics.minAmp = round(amin, 4, 'significant'); % round to 4 sigfigs
        metrics.maxAmp = round(amax, 4, 'significant');
        metrics.p2p = round(amax-amin, 4, 'significant');
        metrics.stdev = round(wstd, 4, 'significant'); % stdev of whole trace - noise level estimate
        %metrics.energy = round(energy, 4, 'significant');
        metrics.units = u;
        
        % some new metrics added 2019/03/20 based on energygt class used by
        % Cassandra
        if p.Results.distance > 0
            r=p.Results.distance;
            channel = get(thisW, 'channel');
            units = get(thisW, 'units');
            scale_factor = -1;
            % Scale factor to convert to real energy units (J)
            if channel(2)== 'D'
                if strcmp(units, 'Pa')
                    % pressure sensor - spherical waves
                    rho_air = 1.2; % kg/m3
                    c_air = 340; % m/s
                    scale_factor = (4 * pi * r^2)/(c_air * rho_air);
                else
                    warning(sprintf('Units %s not recognised for pressure. Energy not computed.',units));
                end
            else
                % seismometer - assuming body waves
                if strfind(units, 'nm')
                    rho_earth = 2500; % kg/m3
                    c_earth = 3000; % m/s
                    scale_factor = (4 * pi * r^2)*(c_earth * rho_earth)*1e-18; % 1e-18 converts from (nm/s)^2 to (m/s)^2
                else
                    warning(sprintf('Units %s not recognised for seismogram. Energy not computed.',units));
                end
            end
            if scale_factor > 0 & r > 0
                watts = (y.*y) * scale_factor;
                metrics.energy = round( sum(watts)/fs * scale_factor, 4, 'significant'); % J
                metrics.meanpower = round(mean(watts), 4, 'significant'); % W
                metrics.maxpower = round(max(watts), 4, 'significant'); % W  
                metrics.emag = round(magnitude.eng2mag(metrics.energy), 3, 'significant');
                metrics.ml = round(magnitude.ml_richter(max( [abs(amax) abs(amin)]), r), 3, 'significant');
            end
            
            
        end
        
        % Now add spectral metrics
        if p.Results.spectral > 0
            try
                s = amplitude_spectrum(thisW);
                metrics.peakf = s.peakf;
                metrics.meanf = s.meanf;
                metrics.freqratio = s.freqratio;
                metrics.freqindex = s.freqindex;
            end
        end
        
        % Now add metrics field to waveform object
        thisW = addfield(thisW, 'metrics', metrics);
        w(wavnum) = thisW;
        
        if mod(wavnum,30) == 0
            fprintf('\nDone %d out of %d\n',wavnum, Nw);
        end

    end
    %fprintf('\n(Complete)\n');
end


function [amin,amax]=running_min_max(y, N)
    startsamp=1;
    for endsamp=1:N
        amax(endsamp) = max(y(startsamp:endsamp));
        amin(endsamp) = min(y(startsamp:endsamp));
    end
    for startsamp=2:length(y)-N+1
        endsamp=startsamp+N-1;
        amax(endsamp) = max(y(startsamp:endsamp));
        amin(endsamp) = min(y(startsamp:endsamp));
    end
end

% function [amin, aminindex, amax, amaxindex] = find_biggest_peak2peak(y, N)
% % SKELETON: NOT USED
% % there are options in findpeaks to ignore small adjacent peaks i should be
% % using here but don't
%     [pos_pks, pos_locs] = findpeaks(y);
%     [neg_pks, neg_locs] = findpeaks(-y);
%     % now we just need to look for neg_pks which occur within 
% end

function [amin, aminindex, amax, amaxindex] = find_biggest_peak2peak(y, N)
    [pos_pks, pos_locs] = findpeaks(detrend(y),'MinPeakProminence', max(y)/3, 'Threshold', max(y)/10);

    % now we just need to look for neg_pks which occur within 
end
