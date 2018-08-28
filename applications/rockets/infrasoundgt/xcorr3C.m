function infrasoundEvent = xcorr3C(wevent, infrasoundEvent, make_figures, figureOutDirectory, pretrigger)
%XCORR3C Cross-correlation an event recorded on 3 infrasound components
% infrasoundEvent = xcorr3C(infrasoundEvent)
%   Input:
%       wevent - a cell array where each component is a vector of 3 
%           waveform objects, 1 per infrasound channel
%       infrasoundEvent is a structure containing two elements:
%           FirstArrivalTime
%           LastArrivalTime
%       make_figures - if true, a figure is generated for each xcorr pair
%
%   Output:
%       infrasoundEvent with some additional elements added
%           maxCorr - a 3x3 array of the maximum cross correlation values
%           secsDiff - a 3x3 array of the time lags corresponding to
%                      maxCorr
%           meanSecsDiff - the mean of secsDiff for non-diagonal components
%
%       each component is cross correlated with each component, hence 3x3

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
    numEvents = numel(infrasoundEvent);
    for eventNumber=1:numEvents
        fprintf('- processing event %d of %d\n', eventNumber, numEvents);
        haystacks = wevent{eventNumber};
        infrasoundEvent(eventNumber).maxCorr = eye(3);
        infrasoundEvent(eventNumber).secsDiff = eye(3);
        precorrtime = 0.1; % NEEDLE seconds of data to add before first arrival
        postcorrtime = 0.2; % NEEDLE seconds of data to add after first arrival
        %postcorrtime = 0.4;
        for chanNumber=1:3
            needle = extract(haystacks(chanNumber), 'time', infrasoundEvent(eventNumber).FirstArrivalTime-precorrtime/86400, infrasoundEvent(eventNumber).FirstArrivalTime+postcorrtime/86400);
            needle_data = detrend(get(needle, 'data'));
%             % upsample by a factor of 8
%             nx = get(needle,'timevector');
%             nxx = nx(1):(nx(2) - nx(1))/8:nx(end);
%             nyy = spline(nx,needle_data,nxx);            
            for haystackNum = 1:3
                fprintf('  - looking for needle %d in haystack %d\n', chanNumber, haystackNum);
                haystack = haystacks(haystackNum);
                haystack_data = get(haystack,'data');
%                 % upsample by a factor of 8
%                 hx = get(haystack,'timevector');
%                 hxx = hx(1):(hx(2) - hx(1))/8:hx(end);
%                 hyy = spline(hx,haystack_data,hxx);
                [acor,lag] = xcorr(needle_data, haystack_data);
%                 [acor,lag] = xcorr(nyy, hyy);
                cxx0 = sum(abs(needle_data).^2);
                cyy0 = sum(abs(haystack_data).^2);
%                  cxx0 = sum(abs(nyy).^2);
%                  cyy0 = sum(abs(hyy).^2);
                scale = sqrt(cxx0*cyy0);
                acor = acor./scale;
                [m,I] = max(abs(acor));
                infrasoundEvent(eventNumber).maxCorr(chanNumber,haystackNum) = m;
                infrasoundEvent(eventNumber).secsDiff(chanNumber,haystackNum) = lag(I)/get(haystack,'freq') + pretrigger - precorrtime;            
                if make_figures
                    figure; 
                    subplot(3,1,1),plot(haystack,'axeshandle',gca);
                    subplot(3,1,2),plot(needle,'axeshandle',gca);
                    subplot(3,1,3),plot(lag,acor);
                    outfile = sprintf('%s/xcorr_infrasoundEvent%03d_%d_%d.png',figureOutDirectory,eventNumber,chanNumber,haystackNum);
                    feval('print', '-dpng', outfile); 
                    close 
                end
            end
        end
        infrasoundEvent(eventNumber).meanCorr = mean(infrasoundEvent(eventNumber).maxCorr([2 3 4 6 7 8]));
        infrasoundEvent(eventNumber).stdCorr = std(infrasoundEvent(eventNumber).maxCorr([2 3 4 6 7 8]));
        infrasoundEvent(eventNumber).meanSecsDiff = mean(infrasoundEvent(eventNumber).secsDiff([2 3 4 6 7 8]));
        infrasoundEvent(eventNumber).stdSecsDiff = std(infrasoundEvent(eventNumber).secsDiff([2 3 4 6 7 8]));
    end
end