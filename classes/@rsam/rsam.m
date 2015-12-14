classdef rsam 
% RSAM Seismic Amplitude Measurement class constructor, version 1.0.
%
% RSAM is a generic term used here to represent any continuous data
% sampled at a regular time interval (usually 1 minute). This is a 
% format widely used within the USGS Volcano Hazards Programme which
% originally stems from the RSAM system (Endo & Murray, 1989)
%
% Written for loading and plotting RSAM data at the Montserrat Volcano 
% Observatory (MVO), and then similar measurements derived from the VME 
% "ltamon" program and ampengfft and rbuffer2bsam which took Seisan 
% waveform files as input. 
%
% s = rsam() creates an empty RSAM object.
%
% s = rsam(dnum, data, 'sta', sta, 'chan', chan, 'measure', measure, 'seismogram_type', seismogram_type, 'units', units)
%
%     dnum        % the dates/times (as datenum) corresponding to the start
%                   of each time window
%     data        % the value at each dnum
%     sta         % station
%     chan        % channel
%     measure     % statistical measure, default is 'mean'
%     seismogram_type % e.g. 'velocity' or 'displacement', default is 'raw'
%     units       % units to label y-axis, e.g. 'nm/s' or 'nm' or 'cm2', default is 'counts'
%
% Examples:
%
%     t = [0:60:1440]/1440;
%     y = randn(size(t)) + rand(size(t));
%     s = rsam(t, y);
%
% See also: read_bob_file, oneMinuteData, waveform>rsam
%
% % ------- DESCRIPTION OF FIELDS IN RSAM OBJECT ------------------
%   DNUM:   a vector of MATLAB datenum's
%   DATA:   a vector of data (same size as DNUM)
%   MEASURE:    a string describing the statistic used to compute the
%               data, e.g. "mean", "max", "std", "rms", "meanf", "peakf",
%               "energy"
%   SEISMOGRAM_TYPE: a string describing whether the RSAM data were computed
%                    from "raw" seismogram, "velocity", "displacement"
%   REDUCED:    a structure that is set is data are "reduced", i.e. corrected
%               for geometric spreading (and possibly attenuation)
%               Has 4 fields:
%                   REDUCED.Q = the value of Q used to reduce the data
%                   (Inf by default, which indicates no attenuation)
%                   REDUCED.SOURCELAT = the latitude used for reducing the data
%                   REDUCED.SOURCELON = the longitude used for reducing the data
%                   REDUCED.STATIONLAT = the station latitude
%                   REDUCED.STATIONLON = the station longitude
%                   REDUCED.DISTANCE = the distance between source and
%                   station in km
%                   REDUCED.WAVETYPE = the wave type (body or surface)
%                   assumed
%                   REDUCED.F = the frequency used for surface waves
%                   REDUCED.WAVESPEED = the S wave speed
%                   REDUCED.ISREDUCED = True if the data are reduced
%   UNITS:  the units of the data, e.g. nm / sec.
%   USE: use this rsam object in plots?
%   FILES: structure of files data is loaded from

% AUTHOR: Glenn Thompson, Montserrat Volcano Observatory
% $Date: $
% $Revision: $

    properties(Access = public)
        dnum = [];
        data = []; % 
        measure = 'mean';
        seismogram_type = 'raw';
        reduced = struct('Q', Inf, 'sourcelat', NaN, 'sourcelon', NaN, 'distance', NaN, 'waveType', '', 'isReduced', false, 'f', NaN, 'waveSpeed', NaN, 'stationlat', NaN, 'stationlon', NaN); 
        units = 'counts';
        use = true;
        files = '';
        sta = '';
        chan = '';
        snum = -Inf;
        enum = Inf;
        spikes = []; % a vector of rsam objects that describe large spikes
        % in the data. Populated after running 'despike' method. These are
        % removed simultaneously from the data vector.
        transientEvents = []; % a vector of rsam objects that describe
        % transient events in the data that might correspond to vt, rf, lp
        % etc. Populated after running 'despike' method with the
        % 'transientEvents' argument. These are not removed from the data
        % vector, but are instead returned in the continuousData vector.
        continuousData = []; % 
        continuousEvents = []; % a vector of rsam objects that describe tremor

    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = public)

        function self=rsam(dnum, data, varargin)
            if nargin==0
                return;
            end
            
            if nargin>1
                self.dnum = dnum;
                self.data = data;
                if nargin>2
                          
                    [self.sta, self.chan, self.measure, self.seismogram_type, self.units, self.snum, self.enum] = ...
                        matlab_extensions.process_options(varargin, 'sta', self.sta, ...
                        'chan', self.chan, 'measure', self.measure, 'seismogram_type', self.seismogram_type, 'units', self.units, 'snum', self.snum, 'enum', self.enum);
            
                end
            end
        end
        
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function fs = Fs(self)
            for c=1:length(self)
                l = length(self(c).dnum);
                s = self(c).dnum(2:l) - self(c).dnum(1:l-1);
                fs(c) = 1.0/(median(s)*86400);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function s=subset(self, snum, enum)
            s = self;
            i = find(self.dnum>=snum & self.dnum <= enum);
            s.dnum = self.dnum(i);
            s.data = self.data(i);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function toTextFile(self, filepath)
           % toTextFile(filepath);
            if numel(self)>1
                warning('Cannot write multiple RSAM objects to the same file');
                return
            end
            
            fout=fopen(filepath, 'w');
            for c=1:length(self.dnum)
                fprintf(fout, '%15.8f\t%s\t%5.3e\n',self.dnum(c),datestr(self.dnum(c),'yyyy-mm-dd HH:MM:SS.FFF'),self.data(c));
            end
            fclose(fout);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          
        function handles = plot(rsamobj, varargin)
            % RSAM/PLOT plot rsam data
            % handle = plot(rsamobj, yaxisType, h, addgrid, addlegend, fillbelow, plotspikes, plottransients, plottremor);
            % to change where the legend plots set the global variable legend_ypos
            % a positive value will be within the axes, a negative value will be below
            % default is -0.2. For within the axes, log(20) is a reasonable value.
            % yaxisType is 'logarithmic' or 'linear'
            % h is an axes handle (or an array of axes handles)
            % use h = generatePanelHandles(numgraphs)

            % Glenn Thompson 1998-2009
            %
            % % GTHO 2009/10/26 Changed marker size from 5.0 to 1.0
            % % GTHO 2009/10/26 Changed legend position to -0.2
            [yaxisType, h, addgrid, addlegend, fillbelow] = ...
                matlab_extensions.process_options(varargin, ...
                'yaxisType', 'linear', 'h', [], 'addgrid', false, ...
                'addlegend', false, 'fillbelow', false);
            legend_ypos = -0.2;

            % colours to plot each station
            lineColour={[0 0 0]; [0 0 1]; [1 0 0]; [0 1 0]; [.4 .4 0]; [0 .4 0 ]; [.4 0 0]; [0 0 .4]; [0.5 0.5 0.5]; [0.25 .25 .25]};

            % Plot the data graphs
            for c = 1:numel(rsamobj)
                self = rsamobj(c);
                hold on; 
                t = self.dnum;
                y = self.data;

                debug.print_debug(10,sprintf('Data length: %d',length(y)));
                handles(c) = subplot(numel(rsamobj), 1, c);
                
                %if ~strcmp(rsamobj(c).units, 'Hz') 
                if strcmp(yaxisType(1:3), 'log')
                    % make a logarithmic plot, with a marker size and add the station name below the x-axis like a legend
                    y = log10(y);  % use log plots
                    plot(t, y, '.', 'Color', lineColour{c}, 'MarkerSize', 1.0);

                    if strfind(self.measure, 'dr')
                        %ylabel(sprintf('%s (cm^2)',self(c).measure));
                        %ylabel(sprintf('D_R (cm^2)',self(c).measure));
                        Yticks = [0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 20 50 ];
                        Ytickmarks = log10(Yticks);
                        for count = 1:length(Yticks)
                            Yticklabels{count}=num2str(Yticks(count),3);
                        end
                        set(gca, 'YLim', [min(Ytickmarks) max(Ytickmarks)],'YTick',Ytickmarks,'YTickLabel',Yticklabels);
                    end
                    axis tight
                    datetick('x','keeplimits')
%
                    xlabel(sprintf('Date/Time starting at %s',datestr(self.snum)))
                    ylabel(sprintf('log(%s)',self.units))
                else

                    % plot on a linear axis, with station name as a y label
                    % datetick too, add measure as title, fiddle with the YTick's and add max(y) in top left corner
                    if ~fillbelow
                        plot(t, y, '.', 'Color', lineColour{c});
                    else
                        fill([min(t) t max(t)], [min([y 0]) y min([y 0])], lineColour{c});
                    end

                    if c ~= length(rsamobj)
                        set(gca,'XTickLabel','');
                    end
                    datetick('x','keeplimits');
                end
                ylabel(sprintf('%s.%s',rsamobj(c).sta, rsamobj(c).chan));

                if addgrid
                    grid on;
                end
                
                if addlegend && length(y)>0
                    xlim = get(gca, 'XLim');
                    legend_ypos = 0.9;
                    legend_xpos = c/10;    
                end

            end
            
            linkaxes(handles,'x');
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function scrollplot(s)

            % Created by Steven Lord, slord@mathworks.com
            % Uploaded to MATLAB Central
            % http://www.mathworks.com/matlabcentral
            % 7 May 2002
            %
            % Permission is granted to adapt this code for your own use.
            % However, if it is reposted this message must be intact.

            % Generate and plot data
            x=s.dnum();
            y=s.data();
            dx=1;
            %% dx is the width of the axis 'window'
            a=gca;
            p=plot(x,y);

            % Set appropriate axis limits and settings
            set(gcf,'doublebuffer','on');
            %% This avoids flickering when updating the axis
            set(a,'xlim',[min(x) min(x)+dx]);
            set(a,'ylim',[min(y) max(y)]);

            % Generate constants for use in uicontrol initialization
            pos=get(a,'position');
            Newpos=[pos(1) pos(2)-0.1 pos(3) 0.05];
            %% This will create a slider which is just underneath the axis
            %% but still leaves room for the axis labels above the slider
            xmax=max(x);
            xmin=min(x);
            xmin=0;
            %gs = get(gcbo,'value')+[min(x) min(x)+dx]
            S=sprintf('set(gca,''xlim'',get(gcbo,''value'')+[%f %f])',[xmin xmin+dx])
            %% Setting up callback string to modify XLim of axis (gca)
            %% based on the position of the slider (gcbo)
            % Creating Uicontrol
            h=uicontrol('style','slider',...
                'units','normalized','position',Newpos,...
                'callback',S,'min',xmin,'max',xmax-dx);
                %'callback',S,'min',0,'max',xmax-dx);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function plotyy(obj1, obj2, varargin)   
            [snum, enum, fun1, fun2] = matlab_extensions.process_options(varargin, 'snum', max([obj1.dnum(1) obj2.dnum(1)]), 'enum', min([obj1.dnum(end) obj2.dnum(end)]), 'fun1', 'plot', 'fun2', 'plot');
            [ax, h1, h2] = plotyy(obj1.dnum, obj1.data, obj2.dnum, obj2.data, fun1, fun2);
            datetick('x');
            set(ax(2), 'XTick', [], 'XTickLabel', {});
            set(ax(1), 'XLim', [snum enum]);
        end
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
        function save(self, filepattern)
            % RSAM/SAVE - save an rsam-like object to an RSAM/BOB binary
            % file
            %
            %
            % Examples:
            %   1. save data to myfile.bob
            %       r.save('myfile.bob')
            %
            %   2. save to file like YEAR_STATION_CHANNEL_MEASURE.bob
            %       r.save('YYYY_SSSS_CCC_MMMM.bob')
            %
            
            for c=1:numel(self)

                dnum = self(c).dnum;
                data = self(c).data;
                file = filepattern; 

                % substitute for station
                file = regexprep(file, '%station', upper(self(c).sta));

                % substitute for channel
                file = regexprep(file, '%channel', upper(self(c).chan));

                % substitute for measure
                file = regexprep(file, '%measure', self(c).measure);             

                % since dnum may not be ordered and contiguous, this function
                % should write data based on dnum only

                if length(dnum)~=length(data)
                        debug.print_debug(0,sprintf('%s: Cannot save to %s because data and time vectors are different lengths',mfilename,filename));
                        size(dnum)
                        size(data)
                        return;
                end

                if length(data)<1
                        debug.print_debug(0,'No data. Aborting');
                    return;
                end

                % filename

                % set start year and month, and end year and month
                [syyy sm]=datevec(self(c).snum);
                [eyyy em]=datevec(self(c).enum);

                if syyy~=eyyy
		    if ~strfind(filepattern, '%year')
                    	error('can only save RSAM data to BOB file if all data within 1 year (or you can add YYYY in your file pattern)');
		    end
                end 

		for yyyy=syyy:eyyy

                	% how many days in this year?
                	daysperyear = 365;
                	if (mod(yyyy,4)==0)
                	        daysperyear = 366;
                	end

                	% Substitute for year        
                	fname = regexprep(file, '%year', sprintf('%04d',yyyy) );
                	debug.print_debug(2,sprintf('Looking for file: %s\n',fname));

                	if ~exist(fname,'file')
                	        debug.print_debug(2, ['Creating ',fname])
                	        rsam.makebobfile(fname, daysperyear);
                	end            

                	datapointsperday = 1440;

                	% round times to minute
                	dnum = round((dnum-1/86400) * 1440) / 1440;
	
			% subset for current year
			dnumy = dnum(dnum < datenum(yyyy + 1, 1, 1));
			datay = data(dnum < datenum(yyyy + 1, 1, 1));
	
	                % find the next contiguous block of data
	                diff=dnumy(2:end) - dnumy(1:end-1);
	                i = find(diff > 1.5/1440 | diff < 0.5/1440);        
	
	                if length(i)>0
	                    % slow mode
	
	                    for c=1:length(dnumy)
	
	                        % write the data
	                        startsample = round((dnumy(c) - datenum(yyyy,1,1)) * datapointsperday);
	                        offset = startsample*4;
	                        fid = fopen(fname,'r+');
	                        fseek(fid,offset,'bof');
	                        debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at position %d',nanmean(datay),fname,startsample,(datapointsperday*daysperyear)))
	                        fwrite(fid,datay(c),'float32');
	                        fclose(fid);
	                    end
	                else
	                    % fast mode
	
	                    % write the data
	                    startsample = round((dnumy(1) - datenum(yyyy,1,1)) * datapointsperday);
	                    offset = startsample*4;
	                    fid = fopen(fname,'r+','l'); % little-endian. Anything written on a PC is little-endian by default. Sun is big-endian.
	                    fseek(fid,offset,'bof');
	                    debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at position %d/%d',nanmean(datay),fname,startsample,(datapointsperday*daysperyear)))
	                    fwrite(fid,datay,'float32');
	                    fclose(fid);
	                end
		end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
        function self = resample(self, varargin)
        %RESAMPLE resamples a rsam object at over every specified intercrunchfactor
        %   rsamobject2 = rsamobject.resample('method', method, 'factor', crunchfactor)
        %  or
        %   rsamobject2 = rsamobject.resample(method, 'minutes', minutes)
        %
        %   Input Arguments
        %       rsamobject: rsam object       N-dimensional
        %
        %       METHOD: which method of sampling to perform within each sample
        %                window
        %           'max' : maximum value
        %           'min' : minimum value
        %           'mean': average value
        %           'median' : mean value
        %           'rms' : rms value (added 2011/06/01)
        %           'absmax': absolute maximum value (greatest deviation from zero)
        %           'absmin': absolute minimum value (smallest deviation from zero)
        %           'absmean' : mean deviation from zero (added 2011/06/01)
        %           'absmedian' : median deviation from zero (added 2011/06/01)
        %           'builtin': Use MATLAB's built in resample routine
        %
        %       CRUNCHFACTOR : the number of samples making up the sample window
        %       MINUTES:       downsample to this sample period
        %       (CRUNCHFACTOR will be calculated internally)
        %
        % Examples:
        %   rsamobject.resample('method', 'mean')
        %       Downsample the rsam object with an automatically determined
        %           sampling period based on timeseries length.
        %   rsamobject.resample('method', 'max', 'factor', 5) grab the max value of every 5
        %       samples and return that in a waveform of adjusted frequency. The output
        %       rsam object will have 1/5th of the samples, e.g. from 1
        %       minute sampling to 5 minutes.
        %   rsamobject.resample('method', 'max', 'minutes', 10) downsample the data at
        %       10 minute sample period       
        
            [method, crunchfactor, minutes] = matlab_extensions.process_options(varargin, 'method', self.measure, 'factor', 0, 'minutes', 0);
        
            persistent STATS_INSTALLED;

            if isempty(STATS_INSTALLED)
              STATS_INSTALLED = ~isempty(ver('stats'));
            end

            if ~(round(crunchfactor) == crunchfactor) 
                disp ('crunchfactor needs to be an integer');
                return;
            end

            for i=1:numel(self)
                samplingIntervalMinutes = 1.0 / (60 * self(i).Fs());
                if crunchfactor==0 & minutes==0 % choose automatically
                    choices = [1 2 5 10 30 60 120 240 360 ];
                    days = max(self(i).dnum) - min(self(i).dnum);
                    choice=max(find(days > choices));
                    minutes=choices(choice);
                end

                if minutes > samplingIntervalMinutes
                    crunchfactor = round(minutes / samplingIntervalMinutes);
                end

                if isempty(method)
                    method = 'mean';
                end
                
                if crunchfactor > 1
                    debug.print_debug(3, sprintf('Changing sampling interval to %d', minutes))
                
                    rowcount = ceil(length(self(i).data) / crunchfactor);
                    maxcount = rowcount * crunchfactor;
                    if length(self(i).data) < maxcount
                        self(i).dnum(end+1:maxcount) = mean(self(i).dnum((rowcount-1)*maxcount : end)); %pad it with the avg value
                        self(i).data(end+1:maxcount) = mean(self(i).data((rowcount-1)*maxcount : end)); %pad it with the avg value 
                    end
                    d = reshape(self(i).data,crunchfactor,rowcount); % produces ( crunchfactor x rowcount) matrix
                    t = reshape(self(i).dnum,crunchfactor,rowcount);
                    self(i).dnum = mean(t, 1);
                    switch upper(method)

                        case 'MAX'
                            if STATS_INSTALLED
                                        self(i).data = nanmax(d, [], 1);
                            else
                                        self(i).data = max(d, [], 1);
                            end

                        case 'MIN'
                            if STATS_INSTALLED
                                        self(i).data = nanmin(d, [], 1);
                            else
                                        self(i).data = min(d, [], 1);
                            end

                        case 'MEAN'
                            if STATS_INSTALLED
                                        self(i).data = nanmean(d, 1);
                            else
                                        self(i).data = mean(d, 1);
                            end

                        case 'MEDIAN'
                            if STATS_INSTALLED
                                        self(i).data = nanmedian(d, 1);
                            else
                                        self(i).data = median(d, 1);
                            end

                        case 'RMS'
                            if STATS_INSTALLED
                                        self(i).data = nanstd(d, [], 1);
                            else
                                        self(i).data = std(d, [], 1);
                            end

                        case 'ABSMAX'
                            if STATS_INSTALLED
                                        self(i).data = nanmax(abs(d),[],1);
                            else
                                        self(i).data = max(abs(d),[],1);
                            end


                        case 'ABSMIN'
                            if STATS_INSTALLED
                                        self(i).data = nanmin(abs(d),[],1);
                            else	
                                        self(i).data = min(abs(d),[],1);
                            end

                        case 'ABSMEAN'
                            if STATS_INSTALLED
                                        self(i).data = nanmean(abs(d), 1);
                            else
                                        self(i).data = mean(abs(d), 1);
                            end

                        case 'ABSMEDIAN'
                            if STATS_INSTALLED
                                        self(i).data = nanmedian(abs(d), 1);
                            else
                                        self(i).data = median(abs(d), 1);
                            end 

                        otherwise
                            error('rsam:resample:UnknownResampleMethod',...
                              'Don''t know what you mean by resample via %s', method);

                    end
                    self(i).measure = method;
                end
            end  
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function save2wfmeastable(self, dbname)
            datascopegt.save2wfmeas(self.scnl, self.dnum, self.data, self.measure, self.units, dbname);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function self = despike(self, spiketype, maxRatio)
            % rsam.despike Despike a rsam object by comparing ratios of
            % concurrent samples. Checks for spikes lasting 1 or 2 samples.
            %   rsamdespiked = rsamobject.despike(spiketype, maxRatio)
            
            %   Example 1: Remove spikes which are at least 10 times
            %   adjacent samples. Store these in s.spikes.
            %        s = s.despike('spikes', 10)
            %
            %   Example 2: Remove spikes which are at least 3 times
            %   adjacent samples. Store these in s.events.
            %        s = s.despike('events', 3)            
            %
            %   Inputs: 
            %       maxRatio - Maximum ratio that defines "normal" data
            %                       compared to surrounding samples
            %   Outputs:
            %       s = rsam object with spikes removed
            
            % find spikes lasting 1 sample only
            y= self.data;
            spikeNumber = 0;
            for i=2:length(self.data)-1
                if self.data(i)>maxRatio*self.data(i-1)
                    if self.data(i)>maxRatio*self.data(i+1)
                        %sample i is an outlier
                        y(i) = mean([self.data(i-1) self.data(i+1)]);
                        spikeNumber = spikeNumber + 1;
                        %spikes(spikeNumber) = spike(self.dnum(i), self.data(i) - y(i), y(i), '');
                        spikes(spikeNumber) = rsam('dnum', self.dnum(i), 'data', self.data(i) - y(i),  'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                        disp(sprintf('%s: sample %d, time %s, before %f, this %f, after %f. Replacing with %f',upper(spiketype),i, datestr(self.dnum(i)), self.data(i-1), self.data(i), self.data(i+1), y(i)));
                    end
                end
            end
            
            % find spikes lasting 2 samples
            for i=2:length(self.data)-2
                if self.data(i)>maxRatio*self.data(i-1) & self.data(i+1)>maxRatio*self.data(i-1)
                    if self.data(i)>maxRatio*self.data(i+2) & self.data(i+1)>maxRatio*self.data(i+2) 
                        %samples i & i+1 are outliers
                        y(i:i+1) = mean([self.data(i-1) self.data(i+2)]);
                        spikeNumber = spikeNumber + 1;
                        % spikes(spikeNumber) = spike( ...
                        %     self.dnum(i:i+1), ...
                        %     self.data(i:i+1) - y(i:i+1), ...
                        %     y(i:i+1), '' );
                        spikes(spikeNumber) = rsam('dnum', self.dnum(i:i+1), 'data', self.data(i:i+1) - y(i:i+1),  'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                        disp(sprintf('%s: sample %d, time %s, before %f, these %f %f, after %f. Replacing with %f',upper(spiketype), i, datestr(self.dnum(i)), self.data(i-1), self.data(i), self.data(i+1), self.data(i+2), y(i)));
                    end
                end
            end
            
            % find spikes lasting 3 samples - could be a short as 62
            % seconds
            if exist('spikes', 'var')
                if ~strcmp(spiketype, 'spikes') % only makes sense for events - an actual telemetry spike will be 1 or 2 samples long only (a few seconds)
                    for i=2:length(self.data)-3
                        if self.data(i)>maxRatio*self.data(i-1) & self.data(i+1)>maxRatio*self.data(i-1) & self.data(i+2)>maxRatio*self.data(i-1) 
                            if self.data(i)>maxRatio*self.data(i+3) & self.data(i+1)>maxRatio*self.data(i+3) & self.data(i+2)>maxRatio*self.data(i+3)
                                %samples i & i+1 are outliers
                                y(i:i+2) = mean([self.data(i-1) self.data(i+3)]);
                                spikeNumber = spikeNumber + 1;
                                % spikes(spikeNumber) = spike( ...
                                %     self.dnum(i:i+1), ...
                                %     self.data(i:i+1) - y(i:i+1), ...
                                %     y(i:i+1), '' );
                                spikes(spikeNumber) = rsam('dnum', self.dnum(i:i+2), 'data', self.data(i:i+2) - y(i:i+2), 'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                                disp(sprintf('%s: sample %d, time %s, before %f, these %f %f %f, after %f. Replacing with %f',upper(spiketype), i, datestr(self.dnum(i)), self.data(i-1), self.data(i), self.data(i+1), self.data(i+2), self.data(i+3), y(i)));
                            end
                        end
                    end            
                end
            end
            
            self.data = y; 
            if exist('spikes', 'var')
                if strcmp(spiketype, 'spikes')
                    self.spikes = spikes;
                else
                    self.transientEvents = spikes;
                end
            end
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [lambda, r2] = duration_amplitude(self, law, min_amplitude, mag_zone)
        %DURATION_AMPLITUDE Use the duration-amplitde
        %Compute the fraction of a data series above each
        %amplitude level, plot the duration vs amplitude data, and then
        %allow user input to fit a regression line.
        %   rsamObject.duration_amplitude(law, min_amplitude)
        %   
        %   Inputs: 
        %       law = 'exponential' or 'power'
        %       min_amplitude = (Optional) the smallest amplitude to use on
        %       the x-axis. Otherwise will be 10^10 times smallest than the
        %       largest amplitude.
        %
        %   Outputs:
        %       (None) A graph is plotted, the user clicks two points, and
        %       from that slope, the characteristic amplitude is computed
        %       and shown on the screen.
 
            y = self.data;
            n = length(y);
            a = abs(y);
            max_amplitude = max(a);
            if ~exist('min_amplitude', 'var')
                min_amplitude = max([min(a) max(a)*1e-10]);
            end
            
            % Method 1
            index=0;
            x = min_amplitude;
            while x < max_amplitude,
                i = find(a>x);
                f = length(i);
                index = index+1;
                frequency(index) = f;
                threshold(index) = x;
                x = x * 1.2;
            end
            clear x y a  f  n  min_amplitude max_amplitude index ;
            
%             % Method 2
%             threshold = [0.0 logspace(min_amplitude, max_amplitude, 50)];
%             nsamples=[];
%             for d = 1:length(threshold)
%                 i = find(a > threshold(d));
%                 frequency(d) = length(i)/length(y);
%             end 
%             clear d, nsamples, i, y

            %% PLOT_DURATION_AMPLITUDE 
            % plot graph, user select two points, compute
            % characteristic from slope.
            % Use different method depending on whether it is a
            % power law or exponential.
            
            % define x and y
            switch law
                case {'exponential'}
                    x = threshold;
                    xlabelstr = 'RMS Displacement(nm)';
                case {'power'}
                    x = log10(threshold);
                    xlabelstr = 'log10(RMS Displacement(nm))';
                otherwise
                    error('law unknown')
            end
            y=log10(frequency);

            % plot duration-amplitude data as circles
            figure
            plot(x,y,'o');
            xlabel(xlabelstr);
            ylabel('log10(Cumulative Minutes)');
            hold on;
            %set(gca,'XLim',[xmin xmax]);

            lambda=0;
            r2=0;

            % check if we have pre-set the magnitude range, effectively
            % our x1 and x2 click points with ginput
            if exist('mag_zone','var') % no user select
                switch law
                    case {'power'}
                        x1=min(mag_zone);
                        x2=max(mag_zone);
                    case {'exponential'}
                        x1=10^min(mag_zone);
                        x2=10^max(mag_zone);

                    otherwise
                        error('law unknown')
                end      
                if x1<min(x)
                    x2=min(x);
                end
                y1=interp1(x,y,x1);
                if x2>max(x)
                    x2=max(x);
                end
                y2=interp1(x,y,x2); 

                % draw a dotted line to show where user selected	
                %plot([x1 x2], [y1 y2], '-.');

                % select requested data range and do a least squares fit
                ii = find(x >= x1 & x <= x2);
                wx = x(ii);
                wy = y(ii);
                [p,S]=polyfit(wx,wy,1);
                yfit = polyval(p,wx);
                thiscorr = corrcoef(wy, yfit)
                %try
                if numel(thiscorr)>1
                    r2 = thiscorr(1,2);

                    % compute lambda
                    switch law
                        case {'exponential'}
                            lambda = -p(1)/log10(exp(1));
                        case {'power'}
                            lambda = -p(1); 
                        otherwise
                            error('law unknown')
                    end

                    disp(sprintf('characteristic D_R_S=%.2f cm^2, R^2=%.2f',lambda,r2));

                    % draw the fitted line
                    xf = [min(wx) max(wx)];
                    yf = xf * p(1) + p(2);
                    plot(xf, yf,'-');

                    %ylabel('log10(t/t0)');
                    %xlabel(sprintf('D_R_S (%s) (cm^2)',measure));


                    % Add legend
                    yrange=get(gca,'YLim');
                    xlim = get(gca,'XLim');
                    xmax=max(xlim);

                    xpos = xmax*0.65;
                    ypos = (yrange(2)-yrange(1))*0.8;
                    r2str=sprintf('%.2f',r2);
                    lambdastr=sprintf('%.2f',lambda);
                    if strcmp(law,'exponential')
                        tstr = [' \lambda=',lambdastr,' R^2=',r2str];
                    else
                        tstr = [' \gamma=',lambdastr,' R^2=',r2str];
                    end

                    text(xpos, ypos, tstr, ...
                        'FontName','Helvetica','FontSize',[14],'FontWeight','bold');   
                else
                    lambda=NaN;
                    r2=NaN;
                end

            else

                % user select a range of data
                disp('Left-click Select lowest X, any other mouse button to ignore this station')
                [x1, y1, button1]=ginput(1);
                if button1==1
                    disp('Left-click Select highest X, any other mouse button to ignore this station')
                    [x2, y2, button2]=ginput(1);    
                    if button2==1
                        if x2>x1
                           % draw a dotted line to show where user selected	
                            plot([x1 x2], [y1 y2], '-.');

                            % select requested data range and do a least squares fit
                            ii = find(x >= x1 & x <= x2);
                            wx = x(ii);
                            wy = y(ii);
                            [p,S]=polyfit(wx,wy,1);
                            yfit = polyval(p,wx);
                            thiscorr = corrcoef(wy, yfit)

                            r2 = thiscorr(1,2);

                            % compute lambda
                            switch law
                                case {'exponential'}
                                    lambda = -p(1)/log10(exp(1));
                                case {'power'}
                                    lambda = -p(1); 
                                otherwise
                                    error('law unknown')
                            end

                            disp(sprintf('characteristic D_R_S=%.2f cm^2, R^2=%.2f',lambda,r2));

                            % draw the fitted line
                            xf = [min(wx) max(wx)];
                            yf = xf * p(1) + p(2);
                            plot(xf, yf,'-');

                            %ylabel('log10(t/t0)');
                            %xlabel(sprintf('D_R_S (%s) (cm^2)',measure));


                            % Add legend
                            yrange=get(gca,'YLim');
                            xlim = get(gca,'XLim');
                            xmax=max(xlim);

                            xpos = xmax*0.65;
                            ypos = (yrange(2)-yrange(1))*0.8;
                            r2str=sprintf('%.2f',r2);
                            lambdastr=sprintf('%.2f',lambda);
                            if strcmp(law,'exponential')
                                tstr = [self.sta,' \lambda=',lambdastr,' R^2=',r2str];
                            else
                                tstr = [self.sta,' \gamma=',lambdastr,' R^2=',r2str];
                            end

                            text(xpos, ypos, tstr, ...
                                'FontName','Helvetica','FontSize',[14],'FontWeight','bold');


                        end
                    end
                end
            end	
            
        end    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [aw,tt1, tt2, tmc, mag_zone]=bvalue(this, mcType, method)
            %BVALUE evaluate b-value, a-value and magnitude of completeness
            % of an earthquake catalog stored in a Catalog object.
            %
            % BVALUE(COBJ, MCTYPE) produces a Gutenberg-Richter type plot 
            %    with the best fit line and display of b-,a-values and Mc 
            %    for the catalog object COBJ. MCTYPE is a number from 1-5 
            %    to select the algorithm used for calculation of the 
            %    magnitude of completeness. Options are:
            %
            %    1: Maximum curvature
            %    2: Fixed Mc = minimum magnitude (Mmin)
            %    3: Mc90 (90% probability)
            %    4: Mc95 (95% probability)
            %    5: Best combination (Mc95 - Mc90 - maximum curvature)

            % Liberally adapted from original code in ZMAP.
            % Author: Silvio De Angelis, 27/07/2012 00:00:00
            % Modified and included in Catalog by Glenn Thompson,
            % 14/06/2014

            % This program is free software; you can redistribute it and/or modify
            % it under the terms of the GNU General Public License cobj.magas published by
            % the Free Software Foundation; either version 2 of the License, or
            % (at your option) any later version.
            %
            % This program is distributed in the hope that it will be useful,
            % but WITHOUT ANY WARRANTY; without even the implied warranty of
            % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
            % GNU General Public License for more details.
            %
            % You should have received a copy of the GNU General Pucobj.magblic License
            % along with this program; if not, write to the
            % Free Software Foundation, Inc.,
            % 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

            if nargin < 2
                disp('--------------------------------------------------------')
                disp('ERROR: Usage is: bvalue(cobj, mcType). mcType not specified')
                disp('--------------------------------------------------------')
                disp('mcType can be:')
                disp('1: Maximum curvature')
                disp('2: Fixed Mc = minimum magnitude (Mmin)')
                disp('3: Mc90 (90% probability)')
                disp('4: Mc95 (95% probability)')
                disp('5: Best combination (Mc95 - Mc90 - maximum curvature)')
                return
            end

            % form magnitude vector - removing any NaN values with find
            good_magnitude_indices = find(this.data > 0.0);
            if strcmp(method, 'power')
                mag = log10(this.data(good_magnitude_indices));
            elseif strcmp(method, 'exponential')
                mag = this.data(good_magnitude_indices);
            end   
                
            %MIN AND MAX MAGNITUDE IN CATALOG
            minimum_mag = min(mag);
            maximum_mag = max(mag);

            %COUNT EVENTS IN EACH MAGNITUDE BIN
            if strcmp(method, 'power')
                magrange = minimum_mag:0.1:maximum_mag;
            elseif strcmp(method, 'exponential')
                magrange = 10.^(log10(minimum_mag):0.1:log10(maximum_mag));
            end  
            [bval, xt2] = hist(mag, magrange);

            %CUMULATIVE NUMBER OF EVENTS IN EACH MAGNITUDE BIN
            bvalsum = cumsum(bval);

            %NUMBER OF EVENTS IN EACH BIN IN REVERSE ORDER
            bval2 = bval(length(bval):-1:1);

            %NUMBER OF EVENTS IN EACH MAGNITUDE BIN IN REVERSE ORDER
            bvalsum3 = cumsum(bval(length(bval):-1:1));

            %BINS IN REVERSE ORDER
            xt3 = fliplr(magrange);
            backg_ab = log10(bvalsum3);

            %CREATE FIGURE WINDOW AND MAKE FREQUENCY-MAGNITUDE PLOT
            figure('Color','w','Position',[0 0 600 600])
            
            pl = semilogy(xt3,bvalsum3,'sb'); 
         
            set(pl, 'LineWidth', [1.0],'MarkerSize', [10],'MarkerFaceColor','r','MarkerEdgeColor','k');
            axis square
            hold on

            %pl1 = semilogy(xt3,bval2,'^b');
            %set(pl1, 'LineWidth',[1.0],'MarkerSize',[10],'MarkerFaceColor','w','MarkerEdgeColor','k');
            if strcmp(method, 'power')
                %xlabel('Log_1_0(Amplitude)','Fontsize', 12)
                xlabel('Magnitude','Fontsize', 12)
            elseif strcmp(method, 'exponential')
                xlabel('Amplitude','Fontsize', 12)
            end             
            
            ylabel('Cumulative Minutes','Fontsize',12)
            set(gca,'visible','on','FontSize',12,'FontWeight','normal',...
                'FontWeight','bold','LineWidth',[1.0],'TickDir','in','Ticklength',[0.01 0.01],...
                'Box','on','Tag','cufi','color','w')

            %ESTIMATE B-VALUE (MAX LIKELIHOOD ESTIMATE)
            Nmin = 10;
            fMccorr = 0;
            fBinning = 0.1;

            if length(mag) >= Nmin

                %GOODNESS-OF-FIT TO POWER LAW
                %%%%%%%%%%%%%%%%%% mcperc_ca3.m start %%%%%%%%%%%%%%%%%%%%
                % This is a completeness determination test

                
                if strcmp(method, 'power')
                    [bval,xt2] = hist(mag,-2:0.1:6);
                elseif strcmp(method, 'exponential')
                    [bval,xt2] = hist(log10(mag),-2:0.1:6);
                end  
                l = max(find(bval == max(bval)));
                magco0 =  xt2(l)

                dat = [];

                %for i = magco0-0.6:0.1:magco0+0.2
                for i = magco0-0.5:0.1:magco0+0.7
                    if strcmp(method, 'power')
                        l = mag >= i - 0.0499;
                    elseif strcmp(method, 'exponential')
                        l = mag >= 10^(i - 0.0499);
                    end
                    nu = length(mag(l));
                    if length(mag(l)) >= 25;
                        %[bv magco stan av] =  bvalca3(catZmap(l,:),2,2);
                        if strcmp(method, 'power')
                            [mw bv2 stan2 av] =  bvalue_lib.bmemag(mag(l));
                        elseif strcmp(method, 'exponential')
                            [mw bv2 stan2 av] =  bvalue_lib.bmemag(log10(mag(l)));
                        end
                        bvalue_lib.synthb_aut;
                        dat = [ dat ; i res2];
                    else
                        dat = [ dat ; i nan];
                    end

                end

                j =  min(find(dat(:,2) < 10 ));
                if isempty(j) == 1; Mc90 = nan ;
                else;
                    Mc90 = dat(j,1);
                end

                j =  min(find(dat(:,2) < 5 ));
                if isempty(j) == 1; Mc95 = nan ;
                else;
                    Mc95 = dat(j,1);
                end

                j =  min(find(dat(:,2) < 10 ));
                if isempty(j) == 1; j =  min(find(dat(:,2) < 15 )); end
                if isempty(j) == 1; j =  min(find(dat(:,2) < 20 )); end
                if isempty(j) == 1; j =  min(find(dat(:,2) < 25 )); end
                j2 =  min(find(dat(:,2) == min(dat(:,2)) ));
                %j = min([j j2]);

                Mc = dat(j,1);
                magco = Mc;
                prf = 100 - dat(j2,2);
                if isempty(magco) == 1; magco = nan; prf = 100 -min(dat(:,2)); end
                %display(['Completeness Mc: ' num2str(Mc) ]);
                %%%%%%%%%%%%%%%%%% mcperc_ca3.m end %%%%%%%%%%%%%%%%%%%%%%

                %CALCULATE MC
                [fMc] = bvalue_lib.calc_Mc(mag, mcType, fBinning, fMccorr);
                l = mag >= fMc-(fBinning/2);
                if length(mag(l)) >= Nmin
                    [fMeanMag, fBValue, fStd_B, fAValue] =  bvalue_lib.calc_bmemag(mag(l), fBinning);
                else
                    [fMc, fBValue, fStd_B, fAValue] = deal(NaN);
                end

                %STANDARD DEV OF a-value SET TO NAN;
                [fStd_A, fStd_Mc] = deal(NaN);

            else
                [fMc, fStd_Mc, fBValue, fStd_B, fAValue, fStd_A, ...
                    fStdDevB, fStdDevMc] = deal(NaN);
            end

            magco = fMc; % magnitude of completeness?
            index_low=find(xt3 < magco+.05 & xt3 > magco-.05);
            mag_hi = xt3(1);
            index_hi = 1;
            mz = xt3 <= mag_hi & xt3 >= magco-.0001;
            mag_zone=xt3(mz);
            y = backg_ab(mz);

            %PLOT MC IN FIGURE
            Mc = semilogy(xt3(index_low),bvalsum3(index_low)*1.5,'vk');
            set(Mc,'LineWidth',[1.0],'MarkerSize',7)
            Mc = text(xt3(index_low)+0.2,bvalsum3(index_low)*1.5,'Mc');
            set(Mc,'FontWeight','normal','FontSize',12,'Color','k')

            %CREATE AND PLOT FIT LINE
            sol_type = 'Maximum Likelihood Solution';
            bw=fBValue;
            aw=fAValue;
            ew=fStd_B;
            p = [ -1*bw aw];
            f = polyval(p,mag_zone);
            f = 10.^f;
   
            hold on
            ttm= semilogy(mag_zone,f,'k');
            set(ttm,'LineWidth',[2.0])
            std_backg = ew;

            %ERROR CALCULATIONS
            %b = mag;
            bv = [];
            si = [];

            set(gca,'XLim',[min(mag)-0.5  max(mag+0.5)])
            %set(gca,'YLim',[0.9 length(mag+30)*2.5]);

            p=-p(1,1);
            p=fix(100*p)/100;
            tt1=num2str(bw,3);
            tt2=num2str(std_backg,1);
            tt4=num2str(bv,3);
            tt5=num2str(si,2);
            tmc=num2str(magco,2);
            rect=[0 0 1 1];
            h2=axes('position',rect);
            set(h2,'visible','off');
            a0 = aw-log10((max(this.dnum)-min(this.dnum))/365);

            text(.53,.88, ['b-value = ',tt1,' +/- ',tt2,',  a value = ',num2str(aw,3)],'FontSize',12);
            %text(.53,.85,sol_type,'FontSize',12 );
            text(.53,.82,['Magnitude of Completeness = ',tmc],'FontSize',12);
            
            
            % Glenn 20150111 add R^2 value
            thiscorr = corrcoef(mag_zone, f)
            r2 = thiscorr(1,2);
            thiscorr2 = corrcoef(mag_zone, log10(f))
            r22 = thiscorr2(1,2);
            %text(.53,.76,['R^2 = ',num2str(r2)],'FontSize',12);
            %text(.53,.70,['R^2 = ',num2str(r22)],'FontSize',12);

        end         
    end % end of dynamic methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    methods(Access = public, Static)

       function self = loadwfmeastable(sta, chan, snum, enum, measure, dbname)
            self = rsam();
            [data, dnum, datafound, units] = datascopegt.load_wfmeas(station, snum, enum, measure, dbname);
            self.dnum = dnum;
            self.data = data;
            self.measure = measure;
            self.units = units;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function makebobfile(outfile, days);
            % makebobfile(outfile, days);
            datapointsperday = 1440;
            samplesperyear = days*datapointsperday;
            a = zeros(samplesperyear,1);
            % ensure host directory exists
            mkdir(fileparts(outfile));
            % write blank file
            fid = fopen(outfile,'w');
            fwrite(fid,a,'float32');
            fclose(fid);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [data]=remove_calibration_pulses(dnum, data)

            t=dnum-floor(dnum); % time of day vector
            y=[];
            for c=1:length(dnum)
                sample=round(t(c)*1440)+1;
                if length(y) < sample
                    y(sample)=0;
                end
                y(sample)=y(sample)+data(c);
            end
            t2=t(1:length(y));
            m=nanmedian(y);
            calibOn = 0;
            calibNum = 0;
            calibStart = [];
            calibEnd = [];
            for c=1:length(t2)-1
                if y(c) > 10*m && ~calibOn
                    calibOn = 1;
                    calibNum = calibNum + 1;
                    calibStart(calibNum) = c;
                end
                if y(c) <= 10*m && calibOn
                    calibOn = 0;
                    calibEnd(calibNum) = c-1;
                end
            end

            if length(calibStart) > 1
                disp(sprintf('%d calibration periods found: nothing will be done',length(calibStart)));
                %figure;
                %c=1:length(y);
                %plot(c,y,'.')
                %i=find(y>10*m);
                %hold on;
                %plot([c(1) c(end)],[10*m 10*m],':');
                %calibStart = input('Enter start sample');
                %calibEnd = input('Enter end sample');
            end
            if length(calibStart) > 0
                % mask the data according to time of day
                tstart = (calibStart - 2) / 1440
                tend = (calibEnd ) / 1440
                i=find(t >= tstart & t <=tend);
                data(i)=NaN;
            end
        end  
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
        function [rsamobjects, ah]=plotrsam(sta, chan, snum, enum, DATAPATH)
        % [rsamobjects, ah]=plotrsam_wrapper(sta, chan, snum, enum, DATAPATH)
        % 
        %   Inputs:
        %       sta - station code
        %       chan - channel code
        %       snum - start datenum
        %       enum - end datenum
        %       DATAPATH - path to data, including pattern
        %
        %   Outputs:
        %       rsamobjects - vector of rsam objects
        %       ah - vector of axes handles
        %
        %   Examples:
        %       1. Data from the digital seismic network, Montserrat
        %           DP = fullfile('/raid','data','antelope','mvo','SSSS_CCC_YYYY.DAT');
        %           [rsamobjects, ah] = rsam.plotrsam('MBWH','SHZ',datenum(2001,2,24), datenum(2001,3,3), DP);
        %       2. Data from the analog seismic network, Montserrat
        %           DP = fullfile(DROPBOX, 'DOME', 'SEISMICDATA', 'RSAM_1', 'SSSSYYYY.DAT');
        %           [rsamobjects, ah] = rsam.plotrsam('MWHZ','',datenum(1996,7,1), datenum(1996,8,13), DP);
        %   Could use the following logic in a wrapper to decide DP:
        %       strfind(sta{i},'MB') & ~strcmp(sta{i},'MBET')
            
            % validate
            if nargin ~= 5
                help rsam>plotrsam()
                return
            end
        
            % initialise
            if ~iscell(sta)
                sta={sta};
            end
            if ~iscell(chan)
                chan={chan};
            end
            numsta = length(sta);
            numrsams = 0;
            rsamobjects = [];
            ah = [];
            
            % load data
            for i=1:numsta
                s = rsam('file', DATAPATH, 'snum', snum, 'enum', enum, 'sta', sta{i},'chan',chan{i});
                if ~isempty(s.data)
                    numrsams = numrsams + 1;
                    rsamobjects = [rsamobjects resample(s.despike(100))];
                    %ah(i)=subplot(numsta,1,i),plot(resample(s.despike(10)));
                end
            end
            
            % plot data
            if numrsams > 0
                figure
                for i=1:numrsams
                    ah(i) = subplot(numrsams, 1, i), plot(rsamobjects(i))
                end
                linkaxes(ah, 'x')
                %datetick('x','keeplimits')
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rsamobj = detectTremorEvents(stationName, chan, DP, snum, enum, spikeRatio, transientEventRatio, STA_minutes, LTA_minutes, stepsize, ratio_on, ratio_off, plotResults)
        % detectTremorEvents Load RSAM data, remove spikes, remove
        % transient events, and run STA/LTA detector on continuous data to
        % identify tremor events.
        %   rsamobj = detectTremorEvents(stationName, snum, enum, spikeRatio, transientEventRatio, STA_minutes, LTA_minutes, stepsize, ratio_on, ratio_off, plotResults)
        %
        %   Example:
        %       DP = fullfile('/raid','data','antelope','mvo','SSSS_CCC_YYYY.DAT');
        %       rsamobj = detectTremorEvents('MBWH', 'SHZ', DP, datenum(2001,2,26), datenum(2001,3,23), 100, 3, 20, 180, 1, 1.5, 1.0, true)
        %   
        %   This will:
        %   * load data for MBWH between the dates given
        %   * remove spikes lasting 1 or 2 samples that are at least 100 times adjacent samples
        %   * remove transient events lasting 1 or 2 samples that are at least 3 times adjacent samples
        %   * run an STA/LTA detector using STA_minutes, LTA_minutes,
        %      stepsize, ratio_on and ratio_off (help rsam>detect for more)
        %   * if plotResults==true, the results will be plotted in 3
        %       figures
        %   
        %
        %   Glenn Thompson 2014

            % validate inputs
            if nargin ~=13
                warning(sprintf('Wrong number of input arguments. Expected %d, got %d',13, nargin))
                help rsam>detectTremorEvents
                return
            end

            % load RSAM data into a RSAM object
            disp('load rsam object')
            rsamobj = rsam('file', DP, 'snum', snum, 'enum', enum, 'sta', stationName, 'chan', chan);
            rsamobj_raw = rsamobj;
            
            % Find really bad telemetry spikes in the data
            % This populates the spikes property and removes bad
            % spikes from data property            
            rsamobj = rsamobj.despike('spikes', spikeRatio);
            rsamobj_despiked = rsamobj;

            % Now find smaller spikes, corresponding to events
            % This populates the transientEvents property and removes event
            % spikes from data property
            rsamobj = rsamobj.despike('events', transientEventRatio);

            %% Now we have a RSAM object we can run tremor detections on
            % STA/LTA detector to find "continuous" events
            % This populates the continuousEvents property
            [rsamobj, windows] = rsamobj.tremorstalta('stalen', STA_minutes, 'ltalen', LTA_minutes, 'stepsize', stepsize, 'ratio_on', ratio_on, 'ratio_off', ratio_off);
            
            %% plot results if asked
            if plotResults
                
                %% plot the results from despiking bad & transient spikes
                figure
                
                % plot raw data
                ah(1)=subplot(3,1,1);
                rsamobj_raw.plot('h', ah(1));
                title('Raw')
                
                % plot despiked data
                ah(2)=subplot(3,1,2);     
                rsamobj_despiked.plot('h', ah(2));
                title('Despiked')
                
                % plot data after transient events removed
                ah(3)=subplot(3,1,3);     
                rsamobj.plot('h', ah(3));
                title('Transient events removed')
                linkaxes(ah,'x');

                %% Plot the STA/LTA diagnosticsnicole_paper.m
                figure;
                ha(1)=subplot(4, 1 ,1);plot(rsamobj.dnum, rsamobj.data );
                datetick('x')

                ha(2)=subplot(4, 1 ,2);plot(windows.endtime, windows.sta);
                datetick('x')
                ylabel(sprintf('STA\n(%s mins)',STA_minutes))

                ha(3)=subplot(4, 1,3); plot(windows.endtime, windows.lta);
                datetick('x')
                ylabel(sprintf('LTA\n(%s mins)',LTA_minutes))

                ha(4)=subplot(4,1,4);plot(windows.endtime, windows.ratio);
                datetick('x')
                hold on;
                for j=1:length(rsamobj.continuousEvents)
                    i =( windows.endtime >= rsamobj.continuousEvents(j).dnum(1) & windows.endtime <= rsamobj.continuousEvents(j).dnum(end) );
                    area(windows.endtime(i), windows.ratio(i),'FaceColor', 'r')
                end
                plot(windows.endtime, ones(1,length(windows.endtime))*ratio_on, ':')
                plot(windows.endtime, ones(1,length(windows.endtime))*ratio_off, ':')
                hold off
                ylabel('STA:LTA')
                linkaxes(ha,'x');
                suptitle('STA/LTA detector diagnostics')

                %% Plot the tremor events superimposed on the background signal RSAM
                % object 
                figure;
                rsamobj.plot();
                hold on
                for i=1:length(rsamobj.continuousEvents);
                    plot(rsamobj.continuousEvents(i).dnum, rsamobj.continuousEvents(i).data,'r')
                end
                hold off
                datetick('x')
                title('Tremor events')
            end

        end
    end
    
    methods(Static)
        rsamobj = load(varargin);
        test();
    end

end % classdef

