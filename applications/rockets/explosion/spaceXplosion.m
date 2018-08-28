%% SPACEXPLOSION Analyze the SpaceX explosion that occurred on 1 Sep 2016
% All supporting functions are in the infrasoundGT directory (or GISMO)
% 

%% setup
clear all
close all
matfile = '/Users/glennthompson/Dropbox/Rockets/analysis/20160901_SpaceXplosion/explosion2.mat';
if exist(matfile,'file')
    load(matfile);
else

    % waveform data parameters
    %ds = datasource('antelope', '/raid/data/rockets/dbspacexplosion');
    ds = datasource('antelope', '/Users/glennthompson/Dropbox/Rockets/db/20160901_explosion');
    snum=datenum(2016,9,1,13,0,0);
    enum = snum + 1/24;
    scnl = scnlobject('BCHH', '*', 'FL');
    
    % Geographical coordinates
    % %%%%%%%%%%%%% SCAFFOLD - could load these from Antelope or Excel
    lat = [28.574182 28.573894 28.574004 28.574013 28.574013 28.574013];
    lon = [-80.572410 -80.572352 -80.572561 -80.572360  -80.572360 -80.572360];
    source.lat = 28.562106; % SLC40 - SpaceX launch complex
    source.lon = -80.57718;
    % Wind tower data - could read this from Excel instead
    relativeHumidity = 92; % percent from NASA weather tower data
    temperatureF = 80; % 80 Fahrenheit according to weather tower data from NASA
    wind_direction_from = 150; % degrees - this is the direction FROM according to NASA, see Lisa Huddleston email of Oct 10th
    wind_direction = mod(wind_direction_from + 180, 360);
    wind_speed_knots = 10; % knots
    wind_speed = wind_speed_knots * 0.514444; % m/s
    % rmpath(genpath('/raid/apps/src/GISMO'))
    
    %% compute speed of sound based on temperature & rel. humidity
    temperatureC = fahrenheit2celsius(temperatureF);
    speed_of_sound = computeSpeedOfSound(temperatureC, relativeHumidity);
    disp(sprintf('speed of sound at %.1f Celsius and %f percent relative humidity is %.1f',temperatureC, relativeHumidity, speed_of_sound));
    
    %% load waveform data
    disp('Loading waveform data...')
    w=waveform(ds,scnl,snum,enum);
    
    save(matfile);
end

make_figures = true
%addpath('infrasoundGT')
figureOutDirectory = '20160901_results';
mkdir('.',figureOutDirectory);


save(matfile)

%% plot raw waveform data
if make_figures
    figure
    plot_panels(w);
    outfile = sprintf('%s/waveforms_raw.png',figureOutDirectory);
    feval('print', '-dpng', outfile); 
    close
end

%% compute predicted travel times for infrasound waves based on GPS coords & wind
%% also add lat, lon, distance and bacaz fields to waveform objects
disp('Predicting travel times based on GPS coordinates and wind vector...')
fprintf('\n_______________________________________________\n');
fprintf('PREDICTED TRAVEL TIME BASED ON:\n');
fprintf('  sound speed    %.1fm/s\n', speed_of_sound);
fprintf('  wind speed     %.1fm/s\n', wind_speed);
fprintf('  wind direction %.1f degrees\n', wind_direction);
fprintf('------\t--------\t-----------\t----------\n');
fprintf('Channel\tDistance\tBackAzimuth\tTravelTime\n');
fprintf('------\t--------\t-----------\t----------\n');
for c=1:length(lat)
    [arclen(c), backaz(c)] = distance(lat(c), lon(c), source.lat, source.lon, 'degrees');
    arclen(c) = deg2km(arclen(c))*1000;
    effective_speed = speed_of_sound + wind_speed * cos(deg2rad( (180+backaz(c)) - wind_direction) );
    predicted_traveltime_seconds(c) = arclen(c)/effective_speed;
    fprintf('%s\t%.1fm\t\t%.1f degrees\t%.3fs\n',get(w(c),'channel'), arclen(c), backaz(c), predicted_traveltime_seconds(c));
    w(c) = addfield(w(c), 'lat', lat(c));
    w(c) = addfield(w(c), 'lon', lon(c));
    w(c) = addfield(w(c), 'distance', arclen(c));
    w(c) = addfield(w(c), 'backaz', backaz(c));
    
end
fprintf('_______________________________________________\n');
fprintf('Program name: %s\n',mfilename('fullpath'))
save spacexplosion.mat


%% plot array map & compute eastings and northings
if make_figures
    disp('Plotting array map')
    close all
    deg2m = deg2km(1) * 1000;
    cols = 'rwbggg';
    for c=1:length(lat)
        chan = get(w(c),'channel');
        easting(c) = distance(lat(c), lon(c), lat(c), source.lon) * deg2m;
        northing(c) = distance(lat(c), lon(c), source.lat, lon(c)) * deg2m;
        plot(easting(c),northing(c),'o','MarkerFaceColor',cols(c),'MarkerSize',10)
        hold on
        quiver(easting(c),northing(c),-easting(c)/100,-northing(c)/100,0); % /100 just gives arrow length
        text(easting(c)+1,northing(c),chan(1:3));
    end
    grid on
    quiver(440,1325,wind_speed*sin(deg2rad(wind_direction)), wind_speed*cos(deg2rad(wind_direction)) ,0,'k');
    text(440,1325,'wind')
    hold off
    title('Beach House array position relative to SLC40');
    xlabel('metres east');
    ylabel('metres north');
    axis equal;
    outfile = sprintf('%s/arraymap.png',figureOutDirectory);
    feval('print', '-dpng', outfile); 
    close
    save spacexplosion.mat
end

%% Load arrivals
disp('Loading arrivals...')
arrivals=Arrival.retrieve('antelope', '/raid/data/rockets/dbspacexplosion');
save spacexplosion.mat

%% Subset out X1 arrivals
disp('Subsetting arrivals...')
arrivals = arrivals.subset('iphase', 'X1');
save spacexplosion.mat

%% Associate events
disp('Associating arrivals into events...')
maxTimeDiff = 1; % seconds
eventOn = false;
eventNumber = 0;
for c=2:numel(arrivals.daynumber)
    if arrivals.daynumber(c-1) + maxTimeDiff/86400 > arrivals.daynumber(c)
        if ~eventOn % start new event
            eventOn = true;
            eventNumber = eventNumber + 1;
            infrasoundEvent(eventNumber).FirstArrivalTime = arrivals.daynumber(c-1);
        else % event already in progress
        end
        infrasoundEvent(eventNumber).LastArrivalTime = arrivals.daynumber(c);
    else 
        if eventOn % write out last event
            eventOn = false;
        end
    end
end
numEvents = numel(infrasoundEvent);
save spacexplosion.mat


%% Filter waveform data to center around zero
disp('Filtering waveform data...')
wfilt = detrend(w);
f=filterobject('h',[10],3);
wfilt=filtfilt(f,wfilt);
save spacexplosion.mat

%% Segment event waveforms
pretrigger = 1;
posttrigger = 1;
wevent = segment_event_waveforms(wfilt, infrasoundEvent, pretrigger, posttrigger);
save spacexplosion.mat

%% Plot infrasound events
if make_figures
    plot_events(wevent, 'waveforms_infrasoundEvent', figureOutDirectory);
end

%% correlate
% loop through infrasound channels
% take a 0.3-second snippet starting 0.1s before FirstArrivalTime, till 0.2s
% after it
% correlate this against the whole wevent for each infrasound
% trace
% this should result in a correlation matrix
% from this record the time lag matrix for each infrasound channel against each other
% infrasound channel
disp('CORRELATION ...')
disp('_______________')
%infrasoundEvent = xcorr3C(wevent, infrasoundEvent, make_figures, figureOutDirectory, pretrigger);
infrasoundEvent = xcorr3C(wevent, infrasoundEvent, false, figureOutDirectory, pretrigger);

% for eventNumber=1:numEvents
%     fprintf('- processing event %d of %d\n', eventNumber, numEvents);
%     haystacks = wevent{eventNumber};
%     infrasoundEvent(eventNumber).maxCorr = eye(3);
%     infrasoundEvent(eventNumber).secsDiff = eye(3);
%     precorrtime = 0.1; % NEEDLE seconds of data to add before first arrival
%     postcorrtime = 0.2; % NEEDLE seconds of data to add after first arrival
%     for chanNumber=1:3
%         needle = extract(haystacks(chanNumber), 'time', infrasoundEvent(eventNumber).FirstArrivalTime-precorrtime/86400, infrasoundEvent(eventNumber).FirstArrivalTime+postcorrtime/86400);
%         for haystackNum = 1:3
%             fprintf('  - looking for needle %d in haystack %d\n', chanNumber, haystackNum);
%             haystack = haystacks(haystackNum);
%             [acor,lag] = xcorr(get(needle,'data'),get(haystack,'data'));
%             [m,I] = max(abs(acor));
%             infrasoundEvent(eventNumber).maxCorr(chanNumber,haystackNum) = m;
%             infrasoundEvent(eventNumber).secsDiff(chanNumber,haystackNum) = lag(I)/get(haystack,'freq') + pretrigger - precorrtime;            
%             if make_figures
%                 figure; 
%                 subplot(3,1,1),plot(haystack);
%                 subplot(3,1,2),plot(needle);
%                 subplot(3,1,3),plot(lag,acor);
%                 outfile = sprintf('figs/xcorr_infrasoundEvent%03d_%d_%d.png',eventNumber,chanNumber,haystackNum);
%                 feval('print', '-dpng', outfile); 
%                 close 
%             end
%         end
%     end
% end
save spacexplosion.mat

%% Construct a master infrasound event, from all the individual ones
disp('Constructing master infrasound event from individual event statistics')
masterEvent.FirstArrivalTime = infrasoundEvent(1).FirstArrivalTime;
masterEvent.LastArrivalTime = infrasoundEvent(1).LastArrivalTime;

% find the mean xcorr time lag difference for non-identical infrasound components - it should be close to zero if only one event in time window
% e.g. needle 1 and haystack 2 should have same magnitude but opposite sign
% time delay to needle 2 and haystack 1 if there is only one clear N wave
% in the haystacks
disp('- finding events with a mean time lag difference of close to 0 - these are the events we can use')
indexes = find(abs([infrasoundEvent.meanSecsDiff]) < 0.01); % these are events with probably only one event in wevent time window
fprintf('- found %d events we can use\n', numel(indexes));
disp('- event indexes to use');
disp(indexes)

masterEvent.secsDiff = zeros(3,3);
masterEvent.stdSecsDiff = zeros(3,3);
for row=1:3
    for column=1:3
        a = [];
        for eventNumber = indexes
            thisEvent = infrasoundEvent(eventNumber);
            a = [a thisEvent.secsDiff(row, column)];
        end
        
        % eliminate any events which have a difference from the mean of
        % greater than the standard deviation
        diffa = abs( (a-mean(a))/std(a) );
        
        % now set the mean and std for the master event
        masterEvent.secsDiff(row, column) = mean(a(diffa<1.0));
        masterEvent.stdSecsDiff(row, column) = std(a(diffa<1.0));
    end
end
disp('  - mean:');
disp(masterEvent.secsDiff)
disp('  - std:')
disp(masterEvent.stdSecsDiff)
disp('  - fractional std:')
disp(masterEvent.stdSecsDiff ./ masterEvent.secsDiff)

%% compute sound speed based on GPS coordinates and master event differential travel times
disp('- Estimating sound speed for each component pair using GPS coordinates')
clear speed
speed = zeros(3,3)*NaN;
for row=1:3
    for column = 1:3
        if row ~= column
            radialDistanceDifference = ( get(w(row),'distance') - get(w(column),'distance') );
            timeDifference = masterEvent.secsDiff(row, column);
            s = radialDistanceDifference / timeDifference;
            disp(sprintf('row %d column %d distance difference %.1f time difference %.4f speed %.1fm/s',row,column,radialDistanceDifference,timeDifference,s));
            speed(row,column) = s;
        end
    end
end
speed
meanspeed = nanmean(nanmean(abs(speed)));
stdspeed =  nanstd(nanstd(abs(speed)));
fprintf('- mean sound speed %.1f, std sound speed %.1f\n', meanspeed, stdspeed);
save spacexplosion.mat

%% beamforming
disp('Beamforming to estimate backazimuth of source from array')
[bestbackaz,bestsoundspeed,distanceDiff,speedMatrix] = beamform2(easting(1:3), northing(1:3), masterEvent.secsDiff, 199.0, 348.6); 
distanceDiff
speedMatrix
sourceDist = get(w(2),'distance');
[beamformingsourcelat, beamformingsourcelon] = reckon(lat(2), lon(2), km2deg(sourceDist/1000), bestbackaz);
distFromSLC40 = deg2km(distance(beamformingsourcelat, beamformingsourcelon, source.lat, source.lon)) * 1000;
disp(sprintf('- source location estimated to be lat = %.4f lon = %.4f, which is %1.fm from true position',beamformingsourcelat, beamformingsourcelon,distFromSLC40));

%%
if make_figures
    outfile = sprintf('%s/beamforming.png',figureOutDirectory);
    feval('print', '-dpng', outfile); 
    close
end
save spacexplosion.mat

%% estimate travel times from cross-correlation derived differential travel times and actual source location, wind speed, and predicted sound speed
[minimumPredictedTravelTime,index] =  min(predicted_traveltime_seconds);
for component=1:3
    traveltime_secs(component) = minimumPredictedTravelTime + mean([masterEvent.secsDiff(component,index) -masterEvent.secsDiff(index,component)]);
end
traveltime_secs(4) = minimumPredictedTravelTime + (get(w(4),'distance') - get(w(index),'distance')) / bestsoundspeed;
traveltime_secs(5) = traveltime_secs(4);
traveltime_secs(6) = traveltime_secs(4);
save spacexplosion.mat

%% Shift waveforms based on travel times  
wshift = wfilt;
for c=1:numel(wshift)
     starttime = get(w(c), 'start');
     newstarttime = starttime - traveltime_secs(c)/86400;
     disp(sprintf('moving channel %d from %s to %s\n', c, datestr(starttime, 'HH:MM:SS.FFF'), datestr(newstarttime, 'HH:MM:SS.FFF')));
     wshift(c)=set(wshift(c),'start', newstarttime);
     disp(sprintf('%s\n',datestr(get(wshift(c),'start'))));
end
save spacexplosion.mat

%% Segment time shifted event waveforms
disp('Segmenting traveltime-corrected event waveforms...')
arrivalTimeCorrection = minimumPredictedTravelTime;
preplot = 0.15;
postplot = 0.15;
weventshift = segment_event_waveforms(wshift, infrasoundEvent, preplot, postplot, arrivalTimeCorrection);
save spacexplosion.mat


%% Plot shifted events
if make_figures
    plot_events(weventshift, 'waveforms_infrasoundEvent_shifted', figureOutDirectory)
end



%% Pick events
close all
for eventNumber=1:numEvents
    
    % plot waveforms for this event
    w2=weventshift{eventNumber};
    fh=plot_panels(w2);
    ah=get(fh,'Children');
    set(fh, 'Position', [0 0 1600 1000]);
    infrasoundEvent(eventNumber).maxAmp=zeros(1,6);
    infrasoundEvent(eventNumber).minAmp=zeros(1,6);
    infrasoundEvent(eventNumber).maxTime=zeros(1,6);
    infrasoundEvent(eventNumber).minTime=zeros(1,6);

    for chanNum=1:6
        
        % scan over this event on this channel and find the greatest
        % max/min difference in 0.1s
        y = get(w2(chanNum),'data');
        fs = get(w2(chanNum),'freq');
        numSamples = length(y);
        windowSize = round(fs/25);
        maxA = 0;
        for startSamp = 1:windowSize:round(numSamples*0.7)-windowSize
            samples = startSamp:startSamp+windowSize-1;
            [maxy, maxindex] = max(y(samples));
            [miny, minindex] = min(y(samples));
            if (maxy-miny) > maxA
                maxSecs = ((maxindex+samples(1)-1)/fs);
                minSecs = ((minindex+samples(1)-1)/fs);
                maxA = maxy-miny;
               
                infrasoundEvent(eventNumber).maxTime(chanNum) = tstart + maxSecs/86400;
                infrasoundEvent(eventNumber).minTime(chanNum) = tstart + minSecs/86400;
                infrasoundEvent(eventNumber).maxAmp(chanNum) = maxy;
                infrasoundEvent(eventNumber).minAmp(chanNum) = miny;
            end
        end
        
        % plot max & min
        axisnum = 8 - chanNum;
        axes(ah(axisnum));
        hold on
        plot(ah(axisnum),maxSecs, infrasoundEvent(eventNumber).maxAmp(chanNum), 'g*');
        plot(ah(axisnum),minSecs, infrasoundEvent(eventNumber).minAmp(chanNum), 'r*');

    end
    feval('print', '-dpng', sprintf('%s/picked_event_%03d',figureOutDirectory, eventNumber) );
    close
end
save spacexplosion.mat

%% Compute relative calibrations of infrasound sensors
clc
tolerance = 0.02; % times have to be within 2 hundreds of a second
component_pairs = [ [1,3]; [1,2]; [2,3] ];

for component_pair_num = 1:length(component_pairs)
    chanNum = nan(2,1);
    chanNum(1) = component_pairs(component_pair_num, 1);
    chanNum(2) = component_pairs(component_pair_num, 2);
    maxA = nan(2, numEvents);
    minA = nan(2, numEvents);
    for eventNum = 1:numEvents
        ev = infrasoundEvent(eventNum);
        if std(ev.maxTime) < tolerance/86400 & std(ev.minTime) < tolerance/86400
            for c=1:2
                maxA(c, eventNum) = ev.maxAmp(chanNum(c));
                minA(c, eventNum) = ev.minAmp(chanNum(c));
            end
        end
    end
    avA = (maxA - minA)/2;

    % first compute raw ratio, mean and std
    ratio = avA(1,:)./avA(2,:);
    m=nanmean(ratio);
    s=nanstd(ratio);

    % now recompute after throwing out any measurement that has an error larger
    % than the standard deviation
    ratio2 = ratio(ratio>m-s & ratio<m+s);
    m2=nanmean(ratio2);
    s2=nanstd(ratio2);
    distratio = get(w(chanNum(2)),'distance') / get(w(chanNum(1)), 'distance')
    
    fprintf('relative amplitude of signals on sensors %d and %d: %f (+/- %f)\n',chanNum(1), chanNum(2), m2, s2);
    fprintf('distance ratio = %f\n', distratio );
    
    relAmp(component_pair_num) = m2/distratio;
    fprintf('relative amplitude of signals corrected for distance is %f\n', m2/distratio);
    
end

%% compute new calibration constants assume sensor 3 has correct calib
oldcalib = get(w,'calib');
newcalib(1) = oldcalib(1) / relAmp(1);
newcalib(2) = oldcalib(2) / relAmp(3); 
newcalib(3) = get(w(3),'calib');
for chanNum=1:3
    fprintf('Using channel 3 as a reference, channel 1 calib old = %f, new = %f\n',oldcalib(chanNum),newcalib(chanNum))
end

%% compute reduced pressures
for eventNum = 1:numEvents
    for chanNum = 1:3
        ev = infrasoundEvent(eventNum);
        pchange = ev.maxAmp(chanNum) - ev.maxAmp(chanNum);
        distanceInKm = get(w(chanNum),'distance') / 1000.0;
        infrasoundEvent(eventNum).pchange(chanNum) = pchange;
        infrasoundEvent(eventNum).preduced(chanNum) = pchange / 2 * distanceInKm;
    end
end
% add origin time - time of earliest arrival corrected for travel time


%% 

SCAFFOLD

%% write out events
fout = fopen(sprintf('%s/eventlist.csv',figureOutDirectory),'w'); 
for eventNum = 1:numEvents
    ev = infrasoundEvent(eventNum);
    % event number
    fprintf(fout, '%d,', eventNum);
    % origin time
    fprintf(fout, '%s,', datestr(ev.originTime));
    % pressure change (from stack)
    fprintf(fout, '%.1f,', nanmean(ev.pchange));
    % reduced pressure (from stack)
    fprintf(fout, '%.1f,', nanmean(ev.preduced));
    % energy (from stack)
    fprintf(fout, '%.1f\n', nanmean(ev.preduced)*some_correction_factor);
    % by component
        % arrival time (not time corrected)
        % maxA
        % minA
end
fclose(fout)
    
    
%% Particle motion analysis
thisw = wevent{1};
t = threecomp(thisw([6 5 4])',backaz(1));
tr = t.rotate()
tr2 = tr.particlemotion();
tr2.plotpm()
tr2.plot3()




