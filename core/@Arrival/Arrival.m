%Arrival the blueprint for Arrival objects in GISMO
% An Arrival object is a container for phase arrival metadata
% See also Catalog
classdef Arrival
    properties
        channelinfo
        time
        arid
        %jdate
        iphase
        deltim
        %azimuth
        %delaz
        %slow
        %delslo
        %ema
        %rect
        amp
        per
        %clip
        %fm
        signal2noise
        %qual
        %auth
        seaz
        delta
        otime
        orid
        evid
        timeres
        traveltime
        depth
        waveforms
    end
    methods
        function obj = Arrival(sta, chan, time, iphase, varargin)

            % Blank constructor
            if ~exist('sta','var')
                return
            end
            
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions             
            p = inputParser;
            p.addRequired('sta', @iscell);
            p.addRequired('chan', @iscell);
            %p.addRequired('time', @(t) t>0 & t<now+1);
            p.addRequired('time', @isnumeric);
            p.addRequired('iphase', @iscell);
            p.addParameter('amp', [], @isnumeric);
            p.addParameter('per', [], @isnumeric);
            p.addParameter('signal2noise', [], @isnumeric);
            p.addParameter('arid', [], @isnumeric);
            p.addParameter('seaz', [], @isnumeric);  
            p.addParameter('deltim', [], @isnumeric);
            p.addParameter('delta', [], @isnumeric);
            p.addParameter('otime', [], @isnumeric);
            p.addParameter('orid', [], @isnumeric);
            p.addParameter('evid', [], @isnumeric);  
            p.addParameter('timeres', [], @isnumeric);
            p.addParameter('depth', [], @isnumeric);
            
            % Missed several properties out here just because of laziness.
            % Add them as needed.
            p.parse(sta, chan, time, iphase, varargin{:});
            ctag = ChannelTag.array('',p.Results.sta,'',p.Results.chan)';            
            obj.channelinfo = ctag.string();
            obj.time = p.Results.time;
            obj.iphase = p.Results.iphase;  
            obj.amp = p.Results.amp; 
            obj.per = p.Results.per; 
            obj.signal2noise = p.Results.signal2noise; 
            obj.arid = p.Results.arid;
            obj.seaz = p.Results.seaz;
            obj.deltim = p.Results.deltim;
            obj.delta = p.Results.delta;
            obj.otime = p.Results.otime;
            obj.orid = p.Results.orid;
            obj.evid = p.Results.evid;
            obj.timeres = p.Results.timeres;
            obj.depth = p.Results.depth;
            debug.print_debug(1,sprintf('\nGot %d arrivals\n',numel(obj.time)));
                
        end
        
        function val = get.time(obj)
            val = obj.time;
        end 
        
%         function val = get.channelinfo(obj)
%             val = obj.channelinfo;
%         end        
%         
%         function val = get.iphase(obj)
%             val = obj.iphase;
%         end
%  
%         function val = get.amp(obj)
%             val = obj.amp;
%         end            
%         
%         function val = get.signal2noise(obj)
%             val = obj.signal2noise;
%         end
%         
%         function obj = set.amp(obj, amp)
%             obj.amp = amp;
%         end       
        
        function summary(obj, showall)
        % ARRIVAL.SUMMARY Summarise Arrival object
            for c=1:numel(obj)
                numrows = numel(obj(c).time);
                fprintf('Number of arrivals: %d\n',numarrs);
                if numrows > 0
                    if ~exist('showall','var')
                            showall = false;
                    end
                    if numel(obj) == 1
                        if numrows <= 50 || showall
                            for rownum=1:numrows
                                summarize_row(obj, rownum);
                            end
                        else
                            for rownum=1:50
                                summarize_row(obj, rownum);
                            end
                            disp('* Only showing first 50 rows/arrivals - to see all rows/arrivals use:')
                            disp('*      arrivalObject.disp(true)')
                        end
                    end
                end
            end
        end
        
        function summarize_row(self, rownum)
            fprintf('%s\t%s\t%s\t%e\t%e\t%e\n', ...
                self.channelinfo(rownum), ...
                datestr(self.time(rownum)), ...
                self.iphase(rownum), ...
                self.amp(rownnum), ...
                self.per(rownum), ...
                self.signal2noise(rownum)); 
        end
        
        function self2 = subset(self, columnname, findval)
            self2 = self;
            N = numel(self.time);
            indexes = [];
            if ~exist('findval','var')
                % assume columnname is actually row numbers
                indexes = columnname;
            else

                for c=1:N
                    gotval = eval(sprintf('self.%s(c);',columnname));
                    if isa(gotval,'cell')
                        gotval = cell2mat(gotval);
                    end
                    if isnumeric(gotval)
                        if gotval==findval
                            indexes = [indexes c];
                        end
                    else
                        if strcmp(gotval,findval)
                            indexes = [indexes c];
                        end
                    end
                end
            end
            self2.channelinfo = self.channelinfo(indexes);
            self2.time = self.time(indexes);
            self2.iphase = self.iphase(indexes);
            if numel(self.amp)==N
                self2.amp = self.amp(indexes);
            end
            if numel(self.per)==N
                self2.per = self.per(indexes);
            end
            if numel(self.signal2noise)==N
                self2.signal2noise = self.signal2noise(indexes);
            end
            if numel(self.traveltime)==N
                self2.traveltime = self.traveltime(indexes);
            end
            if numel(self.arid)==N
                self2.arid = self.arid(indexes);
            end
            if numel(self.seaz)==N
                self2.seaz = self.seaz(indexes);
            end
             if numel(self.deltim)==N
                self2.deltim = self.deltim(indexes);
            end
            if numel(self.delta)==N
                self2.delta = self.delta(indexes);
            end
            if numel(self.otime)==N
                self2.otime = self.otime(indexes);
            end           
            if numel(self.orid)==N
                self2.orid = self.orid(indexes);
            end
            if numel(self.evid)==N
                self2.evid = self.evid(indexes);
            end            
            if numel(self.waveforms)==N
                self2.waveforms = self.waveforms(indexes);
            end 
             if numel(self.timeres)==N
                self2.timeres = self.timeres(indexes);
             end  
              if numel(self.depth)==N
                self2.depth = self.depth(indexes);
            end            
        end 
         function plot(obj)
            ctaguniq = unique(obj.channelinfo)
            N = numel(ctaguniq);
            hf1=figure;
            suptitle('Cumulative arrivals vs time')
            hf2=figure;
            suptitle('Percentage of arrivals captured by signal2noise')
            disp(sprintf('Arrivals: %d',numel(obj.time)))
            for c=1:N
               indexes = find(strcmp(obj.channelinfo,ctaguniq{c})==1);
%                size(indexes)
%                indexes(1:10)
               figure(hf1)
               %subplot(N,1,c);
               hold on
               t = obj.time(indexes);
               y = cumsum(ones(size(t)));
               plot(t,y);
               %ylabel(ctaguniq{c});
               ylabel(sprintf('Cumulative #\nArrivals'))
               xlabel('Date/Time')
               datetick('x')
               set(gca,'XLim',[min(obj.time) max(obj.time)]);
               disp(sprintf('- %s: %d',ctaguniq{c},length(indexes==1)));
               
               figure(hf2) 
               %subplot(N,1,c);
               hold on
               s = obj.signal2noise(indexes);
               s(s>101)=101;
               [n x]=hist(s, 1:0.1:100);
               plot(x,100-cumsum(n)/sum(n)*100);
               xlabel('signal2noise');
               %ylabel(ctaguniq{c});
               ylabel('%age')
               set(gca, 'XLim', [2.4 20]);
            end
            figure(hf1)
            legend(ctaguniq)
            figure(hf2)
            legend(ctaguniq)            
         end       
        
         
        % prototypes
        [catalogobj,arrivalobj] = associate(self, maxTimeDiff, sites, source)
        %arrivalobj = setminman(self, w, pretrig, posttrig, maxtimediff)
        arrivalobj = addmetrics(self, maxtimediff)
        arrivalobj = addwaveforms(self, datasourceobj, pretrigsecs, posttrigsecs);
        write(arrivalobj, FORMAT, PATH);
    end
    methods(Static)
        function self = retrieve(dataformat, varargin)
        %ARRIVAL.RETRIEVE Read arrivals from common file formats & data sources.
        % retrieve can read phase arrivals from different earthquake catalog file 
        % formats (e.g. Seisan, Antelope) and data sources (e.g. IRIS DMC) into a 
        % GISMO Catalog object.
        %
        % Usage:
        %       arrivalObject = ARRIVAL.RETRIEVE(dataformat, 'param1', _value1_, ...
        %                                                   'paramN', _valueN_)
        % 
        % dataformat may be:
        %
        %   * 'iris' (for IRIS DMC, using irisFetch.m), 
        %   * 'antelope' (for a CSS3.0 Antelope/Datascope database)
        %   * 'seisan' (for a Seisan database with a REA/YYYY/MM/ directory structure)
        %   * 'zmap' (converts a Zmap data strcture to a Catalog object)
        %
        % See also CATALOG, IRISFETCH, CATALOG_COOKBOOK

        % Author: Glenn Thompson (glennthompson1971@gmail.com)

        %% To do:
        % Implement name-value parameter pairs for all methods
        % Test the Antelope method still works after factoring out db_load_origins
        % Test the Seisan method more
        % Add in support for 'get_arrivals'
            
            debug.printfunctionstack('>')
            self = [];
            switch lower(dataformat)
                case {'css3.0','antelope', 'datascope'}
                    if admin.antelope_exists()
                        switch nargin
                            case 2
                                self = Arrival.read_arrivals.antelope(varargin{1});
                            case 4
                                if strcmp(varargin{2}, 'subset_expr')
                                    self = Arrival.read_arrivals.antelope(varargin{1}, varargin{3});
                                end
                        end
                    else
                        warning('Antelope toolbox for MATLAB not found')
                    end
                case 'hypoellipse'
                    self = read_hypoellipse(varargin{:});
                otherwise
                    self = NaN;
                    fprintf('format %s unknown\n\n',dataformat);
            end

            debug.printfunctionstack('<')
        end
        
        %cookbook()
    end
end