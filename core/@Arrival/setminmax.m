function arrivalobj = setminmax(arrivalobj, w, maxTimeDiff, pretrig, posttrig)
% for each arrival, find the minimum and maximum value that lie within
% the window from arrivaltime-pretrig:arrivaltime+pretrig are in within maxTimeDiff seconds of each other

if ~exist('pretrig', 'var')
    pretrig = Inf;
end
if ~exist('posttrig', 'var')
    posttrig = Inf;
end

disp('Computing waveform metrics for arrivals')
SECONDS_PER_DAY = 86400;
maxTime = -1;
minTime = -1;
maxAmp = -1;
minAmp = -1;
p2p = -1;
stdev = -1;
energy = -1;
amp = -ones(size(arrivalobj.amp));

for arrivalnum=1:numel(arrivalobj.amp)
    fprintf('.');
    thisA = arrivalobj.subset(arrivalnum);
    thisW = detrend(fillgaps(w(arrivalnum),'interp')); % make sure there is no trend or offset
    wstart = get(thisW,'start'); % waveform start time
    wend = get(thisW,'end'); % waveform end time
    wstd = std(thisW); % waveform standard deviation - for noise estimation
    
    % GET THE DATA
    y = get(thisW,'data');
    
    % COMPUTING AMPLITUDE METRICS
    
    % Define time window
    time_to_begin_at = max([wstart thisA.time - pretrig/SECONDS_PER_DAY]);
    time_to_end_at = min([wend thisA.time + posttrig/SECONDS_PER_DAY]);
    fs = get(thisW,'freq');
    numSamples = length(y);
    seconds_begin_offset = (time_to_begin_at - wstart) * SECONDS_PER_DAY;
    seconds_end_offset   = (time_to_end_at   - wstart) * SECONDS_PER_DAY;
    sample_to_begin_at = max( [round( seconds_begin_offset * fs) 1]);
    sample_to_end_at   = min( [round( seconds_end_offset   * fs) numSamples]);
    
    % Loop over subwindows
    % find p2p amplitude in each, compare to highest p2p found so far
    subWindowSize = round(fs * maxTimeDiff); 
    maxA = 0;
    for startSamp = sample_to_begin_at:1:sample_to_end_at - subWindowSize
        samples = startSamp:startSamp + subWindowSize-1;
        [maxy, maxindex] = nanmax(y(samples));
        [miny, minindex] = nanmin(y(samples));
        if (maxy-miny) > maxA % found the biggest peak-to-peak so far, update
            maxSecs = ((maxindex+samples(1)-1)/fs);
            minSecs = ((minindex+samples(1)-1)/fs);
            maxA = maxy-miny;

            % save max and min amplitudes and corresponding times
            maxTime = wstart + maxSecs/SECONDS_PER_DAY;
            minTime = wstart + minSecs/SECONDS_PER_DAY;
            maxAmp = maxy;
            minAmp = miny;
            p2p = maxy - miny;
            amp(arrivalnum) = nanmax(abs([maxy miny]));
        end
        
    end
    
    % COMPUTE METRICS OF THE WHOLE WAVEFORM
    stdev = wstd; % stdev of whole trace - noise level estimate
    energy = sum(y(sample_to_begin_at:sample_to_end_at).^2)/fs; 
    
    % ADD ALL METRICS TO THE WAVEFORM OBJECT
    thisW = addfield(thisW, 'maxTimeDiff', maxTimeDiff);
    thisW = addfield(thisW, 'timeDiff', (maxTime - minTime) * 86400);
    thisW = addfield(thisW, 'minTime', minTime);
    thisW = addfield(thisW, 'maxTime', maxTime);
    thisW = addfield(thisW, 'minAmp', minAmp);
    thisW = addfield(thisW, 'maxAmp', maxAmp);
    thisW = addfield(thisW, 'p2p', p2p);
    thisW = addfield(thisW, 'stdev', stdev);
    thisW = addfield(thisW, 'energy', energy);
    w(arrivalnum) = thisW;
    
    
    if amp(arrivalnum)==0
    	% plot waveform for arrival
        fh=plot_panels(thisW, false, thisA);
        ah=get(fh,'Children');
        set(fh, 'Position', [0 0 1600 1000]);
        hold on
        plot(maxSecs, misc_fields.maxAmp(arrivalnum), 'g*');
        plot(minSecs, misc_fields.minAmp(arrivalnum), 'r*');
    %     plot(ah,[pos.Start/fs pos.End/fs], [0 0], 'b-');
    %     plot(ah,[neg.Start/fs neg.End/fs], [0 0], 'k-');
        teststr = sprintf('maxTime = %s, minTime = %s, timeDiff = %.3f s\namp = %.2e, maxAmp = %.2e, minAmp = %.2e\n rms = %.2e, energy = %.2e',  ...
            datestr(maxTime,'HH:MM:SS.FFF'), ...
            datestr(minTime,'HH:MM:SS.FFF'), ...
            86400*(maxTime-minTime), ...
            amp, ...
            maxAmp, ...
            minAmp, ...
            stdev, ...
            energy);
        text(0.1, 0.1, teststr, 'units', 'normalized')
        dummy=input('Any key to continue');
        close
    end
end
fprintf('\n(Complete)\n');
arrivalobj.amp = amp;

