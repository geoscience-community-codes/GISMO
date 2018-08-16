%Detection the blueprint for Detection objects in GISMO
% An Detection object is a container for sta/lta detection metadata
% See also Arrival, Catalog
classdef Detection
    properties
        channelinfo
        time
        state
        filterString 
        signal2noise
        traveltime
    end
    properties(Dependent)
        numel
    end
    methods
        function obj = Detection(sta, chan, time, state, filterString, signal2noise)
            
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
            p.addOptional('state', {}, @iscell);
            p.addOptional('filterString', {}, @iscell);
            p.addOptional('signal2noise', [], @isnumeric);
            
            % Missed several properties out here just because of laziness.
            % Add them as needed.
            p.parse(sta, chan, time, state, filterString, signal2noise);
            ctag = ChannelTag.array('',p.Results.sta,'',p.Results.chan)';            
            obj.channelinfo = ctag.string();
            obj.time = p.Results.time;
            obj.state = p.Results.state;  
            obj.filterString = p.Results.filterString; 
            obj.signal2noise = p.Results.signal2noise; 
            N = numel(obj.time);
            fprintf('\nGot %d detections\n',N);
            if numel(obj.state) == 0
                obj.state = repmat({''},1,N);
            end
            if numel(obj.filterString) == 0
                obj.filterString = repmat({''},1,N);
            end
            if numel(obj.signal2noise) == 0
                obj.signal2noise = repmat({''},1,N);
            end    
            if numel(obj.traveltime) == 0
                obj.traveltime = repmat(NaN,1,N);
            end               
                
        end
        
        function val = get.time(obj)
            val = obj.time;
        end
        
        function val = get.numel(obj)
            val = numel(obj.time);
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
        
        function plot(obj)
            ctaguniq = unique(obj.channelinfo)
            N = numel(ctaguniq);
            hf1=figure;
            suptitle('Cumulative detections vs time')
            hf2=figure;
            suptitle('Percentage of detections captured by signal2noise')
            disp(sprintf('Detections: %d',numel(obj.time)))
            for c=1:N
               indexes = find(strcmp(obj.channelinfo,ctaguniq{c})==1);
%                size(indexes)
%                indexes(1:10)
               figure(hf1)
               %subplot(N,1,c);
               hold on
               t = obj.time(indexes);
               y = cumsum(ones(size(t)));
plot(t,y,'LineWidth',5);
               %ylabel(ctaguniq{c});
               ylabel(sprintf('Cumulative #\nDetections'))
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
plot(x,100-cumsum(n)/sum(n)*100,'LineWidth',5);
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

        function summary(obj, showall)
        % DETECTION.SUMMARY Summarise Detection object
            for c=1:numel(obj)
                obj(c)
                numrows = numel(obj(c).time);
                fprintf('Number of detections: %d\n',numrows);
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
            fprintf('%s\t%s\t%s\t%e\n', ...
                self.channelinfo(rownum), ...
                datestr(self.time(rownum)), ...
                self.state(rownum), ...
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
%             if isa(self.channelinfo,'cell')
%                 self2.channelinfo = self.channelinfo{indexes};
%             else
                 self2.channelinfo = self.channelinfo(indexes);
%             end
            self2.time = self.time(indexes);
            self2.state = self.state(indexes);
            if numel(self.filterString)==N
                self2.filterString = self.filterString(indexes);
            end
            if numel(self.signal2noise)==N
                self2.signal2noise = self.signal2noise(indexes);
            end
            if numel(self.traveltime)==N
                self2.traveltime = self.traveltime(indexes);
            end            
        end 
        
        function self = append(self1, self2)
            disp('Appending...')
            [newtime, indices] = sort([self1.time self2.time]);
            size(cellstr(self1.channelinfo))
            size(cellstr(self2.channelinfo))
            newchannelinfo = [cellstr(self1.channelinfo); cellstr(self2.channelinfo)];
            newchannelinfo = newchannelinfo(indices);
            newstate = [cellstr(self1.state); cellstr(self2.state)];
            newstate = newstate(indices);
            newfs = [cellstr(self1.filterString); cellstr(self2.filterString)];
            newfs = newfs(indices); 
            newsnr = [self1.signal2noise self2.signal2noise];
            newsnr = newsnr(indices);
            ctags = ChannelTag(newchannelinfo);
            %self = Detection(cellstr([get(ctags,'station')]), cellstr([get(ctags,'channel')]), newtime, cellstr([newstate]), cellstr([newfs]), newsnr)
            self = Detection([get(ctags,'station')], ...
                [get(ctags,'channel')], ...
                newtime, ...
                newstate, ...
                [newfs], ...
                newsnr)
        end
        
        % prototypes
         catalogobj = associate(self, maxTimeDiff, sites, source)
%         write(detectionobj, FORMAT, PATH);
    end
    methods(Static)
        function self = retrieve(dbname, subset_expr)
        %DETECTION.RETRIEVE Read detections from an Antelope CSS3.0 table
        %
        % Usage:
        %       detectionObj = DETECTION.RETRIEVE(dbname, subset_expr)

        % Author: Glenn Thompson (glennthompson1971@gmail.com)

           
            debug.printfunctionstack('>')
            self = [];
            if ~(antelope.dbtable_present(dbname, 'detection'))
                fprintf('No detection table belonging to %s\n',dbname);
                return
            end
            
            fprintf('Loading detections from %s\n',dbname);

            % Open database
            db = dbopen(dbname,'r');
            disp('- database opened');

            % Apply subset expression
            db = dblookup_table(db,'detection');
            disp('- detection table opened');
            if exist('subset_expr','var')
                db = dbsubset(db,subset_expr);
                disp('- subsetted database')
            end
            
            nrows = dbnrecs(db);
            if nrows > 0

                % Sort by arrival time
                db = dbsort(db,'time');
                disp('- sorted detection table')

                % Get the values
                fprintf('- reading %d rows\n',nrows);
                [sta,chan,time,state,filterString,signal2noise] = dbgetv(db,'sta','chan','time','state', 'filter','snr');

                % Close database link
                dbclose(db);
                disp('- database closed')

                % Create detection object
                disp('- creating detection object')
                self = Detection(cellstr(sta), cellstr(chan), epoch2datenum(time), cellstr(state), cellstr(filterString), signal2noise);
                
                disp('- complete!')
            else
                fprintf('No detections found matching request\n');
            end

            debug.printfunctionstack('<')
        end
        
        %cookbook()
    end
end