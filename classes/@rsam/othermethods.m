        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function self = reduce(self, waveType, sourcelat, sourcelon, stationlat, stationlon, varargin)
            % s.reduce('waveType', 'surface', 'waveSpeed', 2000, 'f', 2.0, );
            % s.distance and waveSpeed assumed to be in metres (m)
            % (INPUT) s.data assumed to be in nm or Pa
            % (OUTPUT) s.data in cm^2 or Pa.m
            [self.reduced.waveSpeed, f] = matlab_extensions.process_options(varargin, 'waveSpeed', 2000, 'f', 2.0);
            if self.reduced.isReduced == true
                disp('Data are already reduced');
                return;
            end

            self.reduced.distance = deg2km(distance(sourcelat, sourcelon, stationlat, stationlon)) *1000; % m

            switch self.units
                case 'nm'  % Displacement
                    % Do computation in cm
                    self.data = self.data / 1e7;
                    r = self.reduced.distance * 100; % cm
                    ws = waveSpeed * 100; % cm/2
                    self.measure = sprintf('%sR%s',self.measure(1),self.measure(2:end));
                    switch self.reduced.waveType
                        case 'body'
                            self.data = self.data * r; % cm^2
                            self.units = 'cm^2';
                        case 'surface'
                            wavelength = ws / f; % cm
                            try
                                    self.data = self.data .* sqrt(r * wavelength); % cm^2
                            catch
                                    debug.print_debug(5, 'mean wavelength instead')
                                    self.data = self.data * sqrt(r * mean(wavelength)); % cm^2            
                            end
                            self.units = 'cm^2';
                            self.reduced.isReduced = true;
                        otherwise
                            error(sprintf('Wave type %s not recognised'), self.reduced.waveType); 
                    end
                case 'Pa'  % Pressure
                    % Do computation in metres
                    self.data = self.data * self.reduced.distance; % Pa.m    
                    self.units = 'Pa m';
                    self.reduced.isReduced = true;
                    self.measure = sprintf('%sR%s',self.measure(1),self.measure(2:end));
                otherwise
                    error(sprintf('Units %s for measure %s not recognised', self.units, self.measure));
            end
            self.reduced.sourcelat = sourcelat;
            self.reduced.sourcelon = sourcelon;
            self.reduced.stationlat = stationlat;
            self.reduced.stationlon = stationlon;
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
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
            
            % Process input variables
            [stalen, ltalen, stepsize, ratio_on, ratio_off, boolplot, boollist] = matlab_extensions.process_options(varargin, ...
                'stalen', 10, 'ltalen', 120, 'stepsize', 10, 'ratio_on', 1.5, 'ratio_off', 1.1, ...
                'boolplot', false, 'boollist', true);
            
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
            for sampleNumber=ltalen: stepsize: length(self.data)
                timeWindowNumber=timeWindowNumber+1;
                startSample = sampleNumber-ltalen+1;
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
                timeWindow.sta(timeWindowNumber) = nanmean(self.data(endSample-stalen+1:endSample)) + eps; % add eps so never 0

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
                    if timeWindow.ratio(timeWindowNumber) < ratio_off
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
                    if timeWindow.ratio(timeWindowNumber) > ratio_on
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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function save2wfmeastable(self, dbname)
            datascopegt.save2wfmeas(self.scnl, self.dnum, self.data, self.measure, self.units, dbname);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function self = remove_calibs(self)    
             for c=1:numel(self)
            % run twice since there may be two pulses per day
                    self(c).data = remove_calibration_pulses(self(c).dnum, self(c).data);
                    self(c).data = remove_calibration_pulses(self(c).dnum, self(c).data);
             end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function self = correct(self)    
             ref = 0.707; % note that median, rms and std all give same value on x=sin(0:pi/1000:2*pi)
             for c=1:numel(self)
                if strcmp(self(c).measure, 'max')
                    self(c).data = self(c).data * ref;
                end
                if strcmp(self(c).measure, '68')
                    self(c).data = self(c).data/0.8761 * ref;
                end
                if strcmp(self(c).measure, 'mean')
                    self(c).data = self(c).data/0.6363 * ref;
                end 
             end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function self=rsam2energy(self, r)
            % should i detrend first?
            e = energy(self.data, r, get(self.scnl, 'channel'), self.Fs(), self.units);
                self = set(self, 'energy', e);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function w=rsam2waveform(self)
            w = waveform;
            w = set(w, 'station', self.sta);
            w = set(w, 'channel', self.chan);
            w = set(w, 'units', self.units);
            w = set(w, 'data', self.data);
            w = set(w, 'start', self.snum);
            %w = set(w, 'end', self.enum);
            w = set(w, 'freq', 1/ (86400 * (self.dnum(2) - self.dnum(1))));
            w = addfield(w, 'reduced', self.reduced);
            w = addfield(w, 'measure', self.measure);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function w=getwaveform(self, datapath)
        % rsam.getwaveform() Get the waveform corresponding to the RSAM data
        %   w = rsamobject.getwaveform() will attempt to get the waveform
        %       data corresponding to a rsam object. Three locations are
        %       tried:
        %           1. MVO Seisan data
        %           2. MVO Antelope data
        %           3. AVO/AEIC data
        %   Alternatively, the user may optionally provide a datasource object
            if isempty(self.sta)
                self.sta = '*';
            end
            if isempty(self.chan)
                self.chan = '*';
            end           
            scnl = scnlobject(self.sta, self.chan)
            w = load_seisan_waveforms(datapath, min(self.dnum), max(self.dnum), scnl);
        end
        
        
        %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         function [data]=remove_calibration_pulses(dnum, data)
% 
%             t=dnum-floor(dnum); % time of day vector
%             y=[];
%             for c=1:length(dnum)
%                 sample=round(t(c)*1440)+1;
%                 if length(y) < sample
%                     y(sample)=0;
%                 end
%                 y(sample)=y(sample)+data(c);
%             end
%             t2=t(1:length(y));
%             m=nanmedian(y);
%             calibOn = 0;
%             calibNum = 0;
%             calibStart = [];
%             calibEnd = [];
%             for c=1:length(t2)-1
%                 if y(c) > 10*m && ~calibOn
%                     calibOn = 1;
%                     calibNum = calibNum + 1;
%                     calibStart(calibNum) = c;
%                 end
%                 if y(c) <= 10*m && calibOn
%                     calibOn = 0;
%                     calibEnd(calibNum) = c-1;
%                 end
%             end
% 
%             if length(calibStart) > 1
%                 disp(sprintf('%d calibration periods found: nothing will be done',length(calibStart)));
%                 %figure;
%                 %c=1:length(y);
%                 %plot(c,y,'.')
%                 %i=find(y>10*m);
%                 %hold on;
%                 %plot([c(1) c(end)],[10*m 10*m],':');
%                 %calibStart = input('Enter start sample');
%                 %calibEnd = input('Enter end sample');
%             end
%             if length(calibStart) > 0
%                 % mask the data according to time of day
%                 tstart = (calibStart - 2) / 1440
%                 tend = (calibEnd ) / 1440
%                 i=find(t >= tstart & t <=tend);
%                 data(i)=NaN;
%             end
%         end 



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         function scrollplot(s)
% 
%             % Created by Steven Lord, slord@mathworks.com
%             % Uploaded to MATLAB Central
%             % http://www.mathworks.com/matlabcentral
%             % 7 May 2002
%             %
%             % Permission is granted to adapt this code for your own use.
%             % However, if it is reposted this message must be intact.
% 
%             % Generate and plot data
%             x=s.dnum();
%             y=s.data();
%             dx=1;
%             %% dx is the width of the axis 'window'
%             a=gca;
%             p=plot(x,y);
% 
%             % Set appropriate axis limits and settings
%             set(gcf,'doublebuffer','on');
%             %% This avoids flickering when updating the axis
%             set(a,'xlim',[min(x) min(x)+dx]);
%             set(a,'ylim',[min(y) max(y)]);
% 
%             % Generate constants for use in uicontrol initialization
%             pos=get(a,'position');
%             Newpos=[pos(1) pos(2)-0.1 pos(3) 0.05];
%             %% This will create a slider which is just underneath the axis
%             %% but still leaves room for the axis labels above the slider
%             xmax=max(x);
%             xmin=min(x);
%             xmin=0;
%             %gs = get(gcbo,'value')+[min(x) min(x)+dx]
%             S=sprintf('set(gca,''xlim'',get(gcbo,''value'')+[%f %f])',[xmin xmin+dx])
%             %% Setting up callback string to modify XLim of axis (gca)
%             %% based on the position of the slider (gcbo)
%             % Creating Uicontrol
%             h=uicontrol('style','slider',...
%                 'units','normalized','position',Newpos,...
%                 'callback',S,'min',xmin,'max',xmax-dx);
%                 %'callback',S,'min',0,'max',xmax-dx);
%         end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%         function plotyy(obj1, obj2, varargin)   
%             [snum, enum, fun1, fun2] = matlab_extensions.process_options(varargin, 'snum', max([obj1.dnum(1) obj2.dnum(1)]), 'enum', min([obj1.dnum(end) obj2.dnum(end)]), 'fun1', 'plot', 'fun2', 'plot');
%             [ax, h1, h2] = plotyy(obj1.dnum, obj1.data, obj2.dnum, obj2.data, fun1, fun2);
%             datetick('x');
%             set(ax(2), 'XTick', [], 'XTickLabel', {});
%             set(ax(1), 'XLim', [snum enum]);
%         end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        