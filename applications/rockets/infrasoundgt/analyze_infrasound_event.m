function infrasoundEvent = analyze_infrasound_event(dbpath, infrasoundEvent)
%analyze_infrasound_event Perfrom a suite of analyses on a single
%infrasound event recorded on an infrasound array (or network of arrays)
%
% results = analyze_infrasound_event(dbpath, infrasoundEvent) given a CSS3.0
% database path containing a wfdisc table, attempt to load waveform data
% for the event and perform additional analyses.
 
    %% load waveform data from an infrasound array
    disp('Loading waveform data...')
    ds = datasource('antelope', dbpath);
    pretrigger = 10; % seconds before first arrival time
    posttrigger = 10; % seconds after last arrival time
    snum = infrasoundEvent.firstArrivalTime - pretrigger/86400;
    enum = infrasoundEvent.lastArrivalTime + posttrigger/86400;
    ctag = unique([arrivals.channelinfo]);
    event_waveform_vector = waveform(ds,ctag,snum,enum);
    numInfrasoundChannels = numel(w);

    %% high-pass filter 
    event_waveform_vector = butterworthFilter(event_waveform_vector, 'h', 0.5, 3); % highpass at 0.5 Hz
    infrasoundEvent.waveform_vector = detrend(event_waveform_vector);
    clear event_waveform_vector
    
    %% cross-correlate to find best time delays
    infrasoundEvent = xcorr_all_components(w, infrasoundEvent, pretrigger);

    %% solve for best fitting direction & sound speed given time delays and coordinates
    infrasoundEvent = solve_for_direction(infrasoundEvent, easting(1:numInfrasoundChannels), northing(1:numInfrasoundChannels)); 
    
%     %% solve for best distance and elevation in best fitting direction
%     infrasoundEvent = solve_for_location(infrasoundEvent, easting(1:numInfrasoundChannels), northing(1:numInfrasoundChannels)); 
    
    %% compute amplitude, energy, frequency waveform parameters
    % compute distance from source to array channels
    for chanNum = 1:numInfrasoundChannels
        array_distance_in_km(chanNum) = sqrt(easting(chanNum).^2 + northing(chanNum).^2)/1000.0;
    end
    %infrasoundEvent = auto_measure_amplitudes(infrasoundEvent, wevent, 'auto_measure_event1', predicted_traveltime_seconds, figureOutDirectory);
    infrasoundEvent.reducedPressure = infrasoundEvent.p2p(1:numInfrasoundChannels).*array_distance_in_km(1:numInfrasoundChannels);
    infrasoundEvent = compute_energy(infrasoundEvent, array_distance_in_km)
end

%%
function infrasoundEvent = xcorr_all_components(w, infrasoundEvent, pretrigger)
%xcorr_all_components Cross-correlate an event recorded on n infrasound components
% infrasoundEvent = xcorr_all_components(infrasoundEvent)
%   Input:
%       wevent - a cell array where each component is a vector of n 
%           waveform objects, 1 per infrasound channel
%       infrasoundEvent is a structure containing two elements:
%           FirstArrivalTime
%           LastArrivalTime
%       make_figures - if true, a figure is generated for each xcorr pair
%
%   Output:
%       infrasoundEvent with some additional elements added
%           maxCorr - a nxn array of the maximum cross correlation values
%           secsDiff - a nxn array of the time lags corresponding to
%                      maxCorr
%           meanSecsDiff - the mean of secsDiff for non-diagonal components
%
%       each component is cross correlated with each component, hence nxn

    disp('CORRELATION ...')
    disp('_______________')
    haystacks = w;
    numchannels = numel(w);
    infrasoundEvent.maxCorr = eye(3);
    infrasoundEvent.secsDiff = eye(3);
    precorrtime = 0.1; % NEEDLE seconds of data to add before first arrival
    postcorrtime = 0.2; % NEEDLE seconds of data to add after first arrival
    for chanNumber=1:numchannels
        % needle has length precorrtime + postcorrtime, starting at
        % FirstArrivalTime - precorrtime
        needle = extract(haystacks(chanNumber), 'time', infrasoundEvent.FirstArrivalTime-precorrtime/86400, infrasoundEvent.FirstArrivalTime+postcorrtime/86400);
        needle_data = detrend(get(needle, 'data'));         
        for haystackNum = 1:numchannels
            fprintf('  - looking for needle %d in haystack %d\n', chanNumber, haystackNum);
            % haystack is a whole waveform
            haystack = haystacks(haystackNum);
            haystack_data = get(haystack,'data');
            [acor,lag] = xcorr(needle_data, haystack_data);
            cxx0 = sum(abs(needle_data).^2);
            cyy0 = sum(abs(haystack_data).^2);
            scale = sqrt(cxx0*cyy0);
            acor = acor./scale;
            [m,I] = max(abs(acor));
            infrasoundEvent.maxCorr(chanNumber,haystackNum) = m;
            infrasoundEvent.secsDiff(chanNumber,haystackNum) = lag(I)/get(haystack,'freq') + pretrigger - precorrtime;            
        end
    end
    infrasoundEvent.meanCorr = mean(infrasoundEvent.maxCorr(:));
    infrasoundEvent.stdCorr = std(infrasoundEvent.maxCorr(:));
    infrasoundEvent.meanSecsDiff = mean(infrasoundEvent.secsDiff(:));
    infrasoundEvent.stdSecsDiff = std(infrasoundEvent.secsDiff(:));
end


%%
function infrasoundEvent = solve_for_direction(infrasoundEvent, easting, northing, fixbackaz, fixspeed)
%SOLVE_FOR_DIRECTION compute back azimuth of source from travel time differences
%between each component. Plane waves are assumed (i.e. source at infinite
%distance). 2D assumes flat topography, does not search over a vertical
%incident angle.
%
%   infrasoundEvent = solve_for_direction(infrasoundEvent, easting, northing)
%       For each possible back azimuth, compute the distances between array 
%       components resolved in that direction.
%       Based on differential travel times (meanSecsDiff), compute
%       speedMatrix. Take average and stdev of speedMatrix, and compute
%       fractional deviation.
%       Choose the best back azimuth (bestbackaz) as the back azimuth for which the fractional
%       deviation is least. Return this and the mean speed (bestspeed).
%   
%       Inputs:
%           infrasoundEvent - a structure for this infrasound event, which
%                             contains secsDiff matrix (delay times between
%                             components)
%           easting, northing - GPS coordinates of array components
%
%       Outputs:
%           bestbackaz - back azimuth of the source that best fits inputs
%           bestspeed - pressure wave speed across array that best fits inputs 
%   
%   infrasoundEvent = solve_for_direction(infrasoundEvent, easting, northing, fixbackaz)
%           fixbackaz - fix the back azimuth to this value
%           Only iterate from fixbackaz-1 to fixbackaz+1, rather than from
%           0.1 to 360.
%
%
%   infrasoundEvent = solve_for_direction(infrasoundEvent, easting, northing, 0, fixspeed)
%           fixspeed - return the back azimuth that best fits this speed.

    meanSecsDiff =  infrasoundEvent.secsDiff;
    bestbackaz = NaN;
    bestspeed = NaN;

    % First we use travel time ratios to find back azimuthal angle of the beam
    % this means we do not need to know speed
    N=numel(easting);
    if numel(northing)~=N
        error('length of easting and northing must be same')
    end
    if (size(meanSecsDiff) ~= [N N])
        size(easting)
        size(northing)
        size(meanSecsDiff)
        error('wrong dimensions for meanSecsDiff')
    end    
    
    if exist('fixspeed','var')
        clear fixbackaz
        warning('You can only set fixbackaz or fixspeed, not both. Ignoring fixbackaz')
    end

    if exist('fixbackaz', 'var')
        backaz = fixbackaz - 1.0: 0.1: fixbackaz + 1.0;
    else
        backaz = 0.1:0.1:360;
    end
    unit_vector_easting = -sin(deg2rad(backaz));
    unit_vector_northing = -cos(deg2rad(backaz));

    for row=1:N
        for column=1:N
            eastingDiff(row, column) = easting(row) - easting(column);
            northingDiff(row, column) = northing(row) - northing(column);
        end
    end

    %for thisaz = backaz
    for c=1:length(backaz)
        thisaz = backaz(c);
        for row=1:N
            for column=1:N
                distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(c) unit_vector_northing(c)] );
            end
        end
        speedMatrix = distanceDiff ./ meanSecsDiff;
        a =[];
        for row=1:N
            for column=1:N      
                if row~=column
                    a = [a speedMatrix(row, column)];
                end
            end
        end
        %meanspeed(thisaz) = mean(a);
        %stdspeed(thisaz) = std(a);
        meanspeed(c) = mean(a);
        stdspeed(c) = std(a);
       
    end
    fractional_error = stdspeed ./ meanspeed;
%     figure
%     subplot(2,1,1),bar(backaz, meanspeed);
%     xlabel('Back azimuth (degrees)')
%     ylabel('Sound speed (m/s)');
%     subplot(2,1,2),semilogy(backaz, abs(fractional_error));
%     xlabel('Back azimuth (degrees)')
%     ylabel('Sound speed fractional error');   
    
    
    % return variables
    fractional_error(meanspeed<0) = Inf; % eliminate -ve speeds as solutions
    if exist('fixspeed','var')
        [~,index] = min(abs(meanspeed-fixspeed));
        fractional_error(index) = 0; % force this speed to be used
    end
    [~,bestindex] = min(abs(fractional_error));
    bestbackaz = backaz(bestindex);
    bestspeed = meanspeed(bestindex);
    
    fprintf('Source is at back azimuth %.1f and wave travels at speed of %.1fm/s\n',bestbackaz,bestspeed);
    for row=1:N
        for column=1:N      
            %distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestbackaz) unit_vector_northing(bestbackaz)] );
            distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestindex) unit_vector_northing(bestindex)] );
        end
    end
    speedMatrix = distanceDiff ./ meanSecsDiff;
    
    % add these to the infrasoundEvent structure
    infrasoundEvent.bestbackaz = bestbackaz;
    infrasoundEvent.bestsoundspeed = bestsoundspeed;
    infrasoundEvent.distanceDiff = distanceDiff;
    infrasoundEvent.speedMatrix = speedMatrix;    
end

%%
function infrasoundEvent = compute_energy(infrasoundEvent, array_distance_in_km)
%COMPUTE_ENERGY
% infrasoundEvent = compute_energy(infrasoundEvent, array_distance_in_km)
    densityEarth = 2000; % (kg/m3) sandstone is 2000-2650, limestone 2000, wet sand 1950
    %pWaveSpeed = 2000; % (m/s) sandstone 2000-3500, limestone 3500-6000, wet sand 1500-2000
    densityAir = 1.225; % (kg/m3)
    pWaveSpeed = 885; % from onset sub-event
    for chanNum = 1:numInfrasoundChannels
        infrasoundEnergy(chanNum) = 2 * pi * (array_distance_in_km(chanNum).^2 * 1e6) * infrasoundEvent.energy(chanNum) / (densityAir * speed_of_sound);
    end
    seismicEnergy = sum(ev.energy(4:6)) * 2 * pi * (array_distance_in_km(6).^2 * 1e6) * densityEarth * pWaveSpeed *1e-18;

    % add to infrasoundEvent structure
    infrasoundEvent.infrasoundEnergy = median(infrasoundEnergy);
    infrasoundEvent.seismicEnergy = seismicEnergy;
end