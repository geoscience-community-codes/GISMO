function thisEvent = auto_measure_minmax(thisW, thisEvent, relative_traveltimes)
% for each channel find the minimum and maximum value that lie within
% MAX_TIME_DIFF seconds of each other

MAX_TIME_DIFF = 0.03; % max time diff between min & max amp is MAX_TIME_DIFF seconds
SECONDS_PER_DAY = 86400;
SECONDS_BEFORE_FIRST_ARRIVAL_FOR_TIMEWINDOW_START = 0.05;
SECONDS_AFTER_FIRST_ARRIVAL_FOR_TIMEWINDOW_END = 0.15;

thisW = detrend(thisW); % make sure there is no trend or offset
wstart = get(thisW,'start'); % vector of waveform start times
wstd = std(thisW); % vector of waveform standard deviations - for noise estimation

% plot waveforms for this event
fh=plot_panels(thisW);
ah=get(fh,'Children');
set(fh, 'Position', [0 0 1600 1000]);
thisEvent.maxAmp=zeros(1,6);
thisEvent.minAmp=zeros(1,6);
thisEvent.maxTime=zeros(1,6);
thisEvent.minTime=zeros(1,6);

for chanNum=1:6
    
    % GET THE DATA
    y = get(thisW(chanNum),'data');
%     ydiff = [0; diff(y)];
    
    % DEFINE THE MAIN TIME WINDOW TO SEARCH OVER
    time_to_begin_at = thisEvent.FirstArrivalTime + relative_traveltimes(chanNum)/SECONDS_PER_DAY - SECONDS_BEFORE_FIRST_ARRIVAL_FOR_TIMEWINDOW_START/SECONDS_PER_DAY;
    time_to_end_at = time_to_begin_at + SECONDS_AFTER_FIRST_ARRIVAL_FOR_TIMEWINDOW_END/SECONDS_PER_DAY;
    fs = get(thisW(chanNum),'freq');
    numSamples = length(y);
    seconds_begin_offset = (time_to_begin_at - wstart(chanNum)) * SECONDS_PER_DAY;
    seconds_end_offset   = (time_to_end_at   - wstart(chanNum)) * SECONDS_PER_DAY;
    sample_to_begin_at = max( [round( seconds_begin_offset * fs) 1]);
    sample_to_end_at   = min( [round( seconds_end_offset   * fs) numSamples]);
    
    % LOOP OVER SUBWINDOWS
    % find p2p amplitude in each, compare to highest p2p found so far
    subWindowSize = round(fs * MAX_TIME_DIFF); 
    maxA = 0;
    for startSamp = sample_to_begin_at:1:sample_to_end_at - subWindowSize
        samples = startSamp:startSamp + subWindowSize-1;
        [maxy, maxindex] = max(y(samples));
        [miny, minindex] = min(y(samples));
        if (maxy-miny) > maxA % THE BIGGEST PEAK2PEAK SO FAR - SO UPDATE THE INFRASOUND OBJECT
            maxSecs = ((maxindex+samples(1)-1)/fs);
            minSecs = ((minindex+samples(1)-1)/fs);
            maxA = maxy-miny;

            % SAVE THE MIN AND MAX VALUES & CORRESPONDING TIMES
            thisEvent.maxTime(chanNum) = wstart(chanNum) + maxSecs/SECONDS_PER_DAY;
            thisEvent.minTime(chanNum) = wstart(chanNum) + minSecs/SECONDS_PER_DAY;
            thisEvent.maxAmp(chanNum) = maxy;
            thisEvent.minAmp(chanNum) = miny;
            thisEvent.p2p(chanNum) = maxy - miny;
        end
        
    end
    
%     % second algorithm - find the greatest number of consecutive points
%     % with a positive gradient, and with a negative gradient
%     a = (ydiff>0);
%     [pos, neg] = longest_sequence(a(sample_to_begin_at:sample_to_end_at));
%     pos.Start = pos.Start - 1 + sample_to_begin_at;
%     pos.End = pos.End - 1 + sample_to_begin_at;
%     neg.Start = neg.Start - 1 + sample_to_begin_at;
%     neg.End = neg.End - 1 + sample_to_begin_at; 
    
    % ADD OTHER METRICS TO THE INFRASOUND OBJECT
    thisEvent.rms(chanNum) = wstd(chanNum); % stdev of whole trace - noise level estimate
    thisEvent.energy(chanNum) = sum(y(sample_to_begin_at:sample_to_end_at).^2)/fs; 

    % MARK THE MIN AND MAX TIMES ON THE WAVEFORM PANEL PLOT
    axisnum = 8 - chanNum;
    axes(ah(axisnum));
    hold on
    plot(ah(axisnum),maxSecs, thisEvent.maxAmp(chanNum), 'g*');
    plot(ah(axisnum),minSecs, thisEvent.minAmp(chanNum), 'r*');
%     plot(ah(axisnum),[pos.Start/fs pos.End/fs], [0 0], 'b-');
%     plot(ah(axisnum),[neg.Start/fs neg.End/fs], [0 0], 'k-');
end