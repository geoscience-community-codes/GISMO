classdef oneMinuteData
% oneMinuteData Class constructor for generic data sampled once per minute.
% This might not be amplitude data - it could be energy or frequency too -
% or perhaps a metric like cumulative magnitude, or frequency index.
%
% s = oneMinuteData() creates an empty oneMinuteData object.
%
% Optional name/value pairs:
%   DNUM:   a vector of MATLAB datenum's
%   DATA:   a vector of data (same size as DNUM)
%   STA:    station
%   CHAN:   channel
%   MEASURE:    a string describing the statistic used to compute the
%               data, e.g. "mean", "max", "std", "rms", "meanf", "peakf",
%               "energy", default is 'mean' which indicates
%               that each 1 minute sample is the mean of a 60-s seismogram
%   SEISMOGRAM_TYPE: a string describing whether the data were computed
%                    from "raw" seismogram, "velocity", "displacement".
%                    default is 'raw'.
%   UNITS:  the units of the data, used to label the y-axis, e.g. nm / sec,
%                   'nm/s' or 'nm' or 'cm2', default is 'counts'
% Examples:
%     s = oneMinuteData('dnum', dnum, 'data', data, 'sta', 'MBWH', 'chan', 'SHZ')

% AUTHOR: Glenn Thompson, Montserrat Volcano Observatory
% $Date: $
% $Revision: $

    properties(Access = public)
        dnum = [];
        data = []; 
        measure = 'mean';
        seismogram_type = 'raw';
        units = 'counts';
        sta = ''
        chan = ''
        snum = -Inf;
        enum = Inf;
    end
    
    methods(Access = public)

       function self=oneMinuteData(varargin)
          
          p = inputParser;
          p.addParameter('dnum',[]);
          p.addParameter('data',[]);
          classFields = {'sta','chan','measure','seismogram_type','units'};
          for n=1:numel(classFields)
             p.addParameter(classFields{n}, self.(classFields{n}));
          end
          p.parse(varargin{:});
          
          % modify class values based on user-provided values
          for n = 1:numel(classFields)
             self.(classFields{n}) = p.Results.(classFields{n});
          end
          self.dnum = p.Results.dnum;
          self.data = p.Results.data;
          self.snum = min(self.dnum);
          self.enum = max(self.dnum);
       end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function fs = Fs(self) % check the sampling frequency
            l = length(self.dnum);
            s = self.dnum(2:l) - self.dnum(1:l-1);
            fs = 1.0/(median(s)*86400);
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
            %
            fout=fopen(filepath, 'w');
            for c=1:length(self.dnum)
                fprintf(fout, '%15.8f\t%s\t%5.3e\n',self.dnum(c),datestr(self.dnum(c),'yyyy-mm-dd HH:MM:SS.FFF'),self.data(c));
            end
            fclose(fout);
        end
%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
   %
   
   % NOTE: this function is Exactly the same as rsam.plotyy
           p = inputParser;
           p.addParameter('snum',max([obj1.dnum(1) obj2.dnum(1)]));
           p.addParameter('enum', min([obj1.dnum(end) obj2.dnum(end)]));
           p.addParameter('fun1','plot');
           p.addParameter('fun2','plot');
           p.parse(varargin{:});
           Args = p.Results;
  
            [ax, ~, ~] = plotyy(obj1.dnum, obj1.data, obj2.dnum, obj2.data, Args.fun1, Args.fun2);
            datetick('x');
            set(ax(2), 'XTick', [], 'XTickLabel', {});
            set(ax(1), 'XLim', [Args.snum Args.enum]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
        function save(self, file)
            dnum = self.dnum;
            data = self.data;
            
            % substitute for station
            file = regexprep(file, 'SSSS', self.sta);
            
            % substitute for channel
            file = regexprep(file, 'CCC', self.chan);
            
            % substitute for measure
            file = regexprep(file, 'MMMM', self.measure);             
                
            % since dnum may not be ordered and contiguous, this function
            % should write data based on dnum only
            
            if length(dnum)~=length(data)
                    disp(sprintf('%s: Cannot save to %s because data and time vectors are different lengths',mfilename,filename));
                    size(dnum)
                    size(data)
                    return;
            end

            if length(data)<1
                    disp('No data. Aborting');
                return;
            end
            
            % filename

            % set start year and month, and end year and month
            [yyyy sm]=datevec(self.snum);
            [eyyy em]=datevec(self.enum);
            
            if yyyy~=eyyy
                error('can only save RSAM data to BOB file if all data within 1 year');
            end 
            
            % how many days in this year?
            daysperyear = 365;
            if (mod(yyyy,4)==0)
                    daysperyear = 366;
            end
            
            % Substitute for year        
            fname = regexprep(file, 'YYYY', sprintf('%04d',yyyy) );
            fprintf('Looking for file: %s\n',fname);

            if ~exist(fname,'file')
                    debug.print_debug(['Creating ',fname],2)
                    oneMinuteData.makebobfile(fname, daysperyear);
            end            

            datapointsperday = 1440;

            % round times to minute
            dnum = round((dnum-1/86400) * 1440) / 1440;

            % find the next contiguous block of data
            diff=dnum(2:end) - dnum(1:end-1);
            i = find(diff > 1.5/1440 | diff < 0.5/1440);        

            if length(i)>0
                % slow mode

                for c=1:length(dnum)

                    % write the data
                    startsample = round((dnum(c) - datenum(yyyy,1,1)) * datapointsperday);
                    offset = startsample*4;
                    fid = fopen(fname,'r+');
                    fseek(fid,offset,'bof');
                    debug.print_debug(sprintf('saving to %s, position %d',fname,startsample),3)
                    fwrite(fid,data(c),'float32');
                    fclose(fid);
                end
            else
                % fast mode

                % write the data
                startsample = round((dnum(1) - datenum(yyyy,1,1)) * datapointsperday);
                offset = startsample*4;
                fid = fopen(fname,'r+','l'); % little-endian. Anything written on a PC is little-endian by default. Sun is big-endian.
                fseek(fid,offset,'bof');
                debug.print_debug(sprintf('saving to %s, position %d of %d',fname,startsample,(datapointsperday*daysperyear)),3)
                fwrite(fid,data,'float32');
                fclose(fid);
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
        function self = resample(self, varargin)
        %RESAMPLE resamples a oneMinuteData object at over every specified crunchfactor
        %   oneMinuteDataobject2 = oneMinuteDataobject.resample('method', method, 'factor', crunchfactor)
        %  or
        %   oneMinuteDataobject2 = oneMinuteDataobject.resample(method, 'minutes', minutes)
        %
        %   Input Arguments
        %       oneMinuteDataobject: oneMinuteData object       N-dimensional
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
        %   oneMinuteDataobject.resample('method', 'mean')
        %       Downsample the oneMinuteData object with an automatically determined
        %           sampling period based on timeseries length.
        %   oneMinuteDataobject.resample('method', 'max', 'factor', 5) grab the max value of every 5
        %       samples and return that in a waveform of adjusted frequency. The output
        %       oneMinuteData object will have 1/5th of the samples, e.g. from 1
        %       minute sampling to 5 minutes.
        %   oneMinuteDataobject.resample('method', 'max', 'minutes', 10) downsample the data at
        %       10 minute sample period       
        %
        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            
            persistent STATS_INSTALLED;

            if isempty(STATS_INSTALLED)
              STATS_INSTALLED = ~isempty(ver('stats'));
            end

            hasIntegerValue = @(x) round(x) == x;  %can be used to validate parameter
            
            % NOTE: This parameter combo also exists in rsam/resample
            p = inputParser;
            p.addParameter('method',self.measure);
            p.addParameter('factor', 0); % crunchfactor
            p.addParameter('minutes', 0);
            
            p.parse(varargin{:});
            
            crunchfactor = p.Results.factor;
            method = p.Results.method;
            minutes = p.Results.minutes;
            
            if ~(hasIntegerValue(crunchfactor)) 
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
                    debug.print_debug(sprintf('Changing sampling interval to %d', minutes),3)
                
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
                            error('oneMinuteData:resample:UnknownResampleMethod',...
                              'Don''t know what you mean by resample via %s', method);

                    end
                    self(i).measure = method;
                end
            end  
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function self = save2wfmeastable(self, dbname) 
        % add save2wfmeas here
            datascopegt.save2wfmeas(self.scnl, self.dnum, self.data, self.measure, self.units, dbname);
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function w=toWaveform(self) 
            % oneMinuteData.toWaveform() Create a Waveform Object from a
            % oneMinuteData object. Use with caution!
            w = waveform;
            w = set(w, 'station', self.sta);
            w = set(w, 'channel', self.chan);
            w = set(w, 'units', self.units);
            w = set(w, 'data', self.data);
            w = set(w, 'start', self.snum);
            %w = set(w, 'end', self.enum);
            w = set(w, 'freq', self.Fs());
            w = addfield(w, 'measure', self.measure);
        end        
    end % end of methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FILE LOAD AND SAVE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%    
    methods(Access = public, Static)

       function self = loadwfmeastable(sta, chan, snum, enum, measure, dbname)
            self = oneMinuteData();
            [data, dnum, datafound, units] = datascopegt.load_wfmeas(station, snum, enum, measure, dbname);
            self.dnum = dnum;
            self.data = data;
            self.measure = measure;
            self.units = units;
        end

        function makebobfile(outfile, days);
            % makebobfile(outfile, days);
            datapointsperday = 1440;
            samplesperyear = days*datapointsperday;
            a = zeros(samplesperyear,1);
            fid = fopen(outfile,'w');
            fwrite(fid,a,'float32');
            fclose(fid);
        end 

    end % methods

end % classdef

