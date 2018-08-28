function [self, timeWindow] = tremorstalta(self, varargin)
    % rsam.detect Run an STA/LTA detector on a rsam object  
    %   [rsamobject, timeWindow] = rsam.detect(varargin)
    %   
    %   For sample N, the STA is calculated from samples
    %   N-stalen+1:N and the LTA from N-ltalen+1:N
    %   
    %   Optional input name/value pairs:
    %       'stalen'    - length of STA timeWindow in samples (minutes)
    %                       [Default 10]
    %       'ltalen'    - length of LTA timeWindow in samples (minutes)
    %                       [Default 120]
    %       'stepsize'  - number of samples to move sliding timeWindow
    %                       [Default stalen]
    %       'ratio_on'  - the STA/LTA ratio for which to trigger on
    %                       [Default 1.5]
    %       'ratio_off' - the STA/LTA ratio for which to trigger
    %                       off [Default 1.1]
    %       'boolplot'  - if set to true, plot the STA, LTA, ratio
    %           and trigger on & trigger off times (Default false)
    %       'boollist'  - if set to true, list the tremor event on 
    %           and off times (Default false) 
    %
    %   Outputs:
    %       timeWindow  - a structure with fields (all vectors):
    %           startSample - start sample number of each timeWindow
    %           endSample - end sample number of each timeWindow
    %           starttime - start time of each timeWindow
    %           endtime - end time of each timeWindow
    %           sta - short term average of each timeWindow
    %           lta - long term average of each timeWindow
    %           ratio - sta:lta ratio of each timeWindow
    %       rsamobject - the input rsamobject but with the 
    %                   continuousEvents property populated
    % NOTE: REQUIRES EXTRA PROPERTIES FOR RSAM OBJECTS
        %continuousData = []; % 
        %continuousEvents = []; % a vector of rsam objects that describe tremor

    % Process input variables
    p = inputParser;
    p.addParameter('stalen', 10);
    p.addParameter('ltalen', 120);
    p.addParameter('stepsize', 10);
    p.addParameter('ratio_on', 1.5);
    p.addParameter('ratio_off', 1.1);
    p.addParameter('boolplot', false, @islogical);
    p.addParameter('boollist', true, @islogical);

    p.parse(varargin{:}); % use p.Results.(paramName)


    % Initialize detector variables
    trigger_on=false; % no tremorEvent yet
    % Make sta & lta equal - no trigger
    sta_lastgood = eps; % some non-zero value so ratio ok
    lta_lastgood = eps; % some non-zero value so ratio ok

    % Create a timeWindow structure / initialize as empty
    timeWindowNumber = 0; % timeWindowNumber is based on how many times stepsize fits in to data length
    timeWindow.startSample = [];
    timeWindow.endSample = [];
    timeWindow.starttime = [];
    timeWindow.endtime = [];
    timeWindow.sta = [];
    timeWindow.lta = [];
    timeWindow.ratio = [];


    eventNumber = 0;

    % Loop over timeWindows
    % 
    for sampleNumber=p.Results.ltalen: p.Results.stepsize: length(self.data)
        timeWindowNumber=timeWindowNumber+1;
        startSample = sampleNumber-p.Results.ltalen+1;
        endSample = sampleNumber;
        timeWindow.startSample(timeWindowNumber) = startSample;
        timeWindow.endSample(timeWindowNumber) = endSample;        
        timeWindow.starttime(timeWindowNumber) = self.dnum(startSample);
        timeWindow.endtime(timeWindowNumber) = self.dnum(endSample);

        % Compute the long term average for this timeWindow
        if ~trigger_on % sticky lta
            timeWindow.lta(timeWindowNumber) = nanmean(self.data(startSample:endSample)) + eps; % add eps so never 0
        else
            timeWindow.lta(timeWindowNumber) = lta_lastgood;
        end

        % Compute the short term average for this timeWindow
        timeWindow.sta(timeWindowNumber) = nanmean(self.data(endSample-p.Results.stalen+1:endSample)) + eps; % add eps so never 0

        % Make sta & lta equal to last good values when NaN
        if isnan(timeWindow.sta(timeWindowNumber))
            timeWindow.sta(timeWindowNumber) = sta_lastgood;
        else
            sta_lastgood = timeWindow.sta(timeWindowNumber);
        end
        if isnan(timeWindow.lta(timeWindowNumber))
            timeWindow.lta(timeWindowNumber) = lta_lastgood;
        else
            lta_lastgood = timeWindow.lta(timeWindowNumber);
        end   

        % Compute the ratio
        timeWindow.ratio(timeWindowNumber) = timeWindow.sta(timeWindowNumber)./timeWindow.lta(timeWindowNumber);        

        if trigger_on % EVENT IN PROCESS, CHECK FOR DETRIGGER
            if timeWindow.ratio(timeWindowNumber) < p.Results.ratio_off
                % trigger off condition
                disp(sprintf('TREMOR EVENT: %s to %s, max amp %e', datestr(self.dnum(eventStartSample)), datestr(self.dnum(endSample)), max(self.data(eventStartSample:endSample)) ))
                %tremorEvent(eventNumber) = rsam_event(self.dnum(eventStartSample:endSample), self.data(eventStartSample:endSample), '', scnl, ltalen);
                tremordnum = self.dnum(eventStartSample:endSample);
                tremordata = self.data(eventStartSample:endSample);
                tremorEvent(eventNumber) = rsam('dnum', tremordnum, 'data', tremordata,  'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                trigger_on = false;
                eventStartSample = -1;
            end
        else % BACKGROUND, CHECK FOR TRIGGER
            if timeWindow.ratio(timeWindowNumber) > p.Results.ratio_on
                % trigger on condition
                eventNumber = eventNumber + 1;
                eventStartSample = endSample; % event is triggered at time of sample at end of timewindow
                trigger_on = true;
            end
        end

    end
    if exist('tremorEvent','var')
        self.continuousEvents = tremorEvent;
    end
end