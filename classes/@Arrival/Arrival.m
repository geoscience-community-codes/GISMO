%Arrival the blueprint for Arrival objects in GISMO
% An Arrival object is a container for phase arrival metadata
% See also Catalog
classdef Arrival
% help is here
    properties
        arid;
        orid;
        evid;
    end
    properties(Dependent)
        datenum
        channelinfo
        date
        time
        %jdate
        iphase
        %deltim
        %azimuth
        %delaz
        %slow
        %delslo
        %ema
        %rect
        %amp
        %per
        %clip
        %fm
        %snr
        %qual
        auth
        snum
        enum
        numberOfArrivals
    end
    properties(Hidden)
        table
    end
    methods
        function obj = Arrival(chantag, time, iphase, varargin)
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            persistent lastarid;
            if isempty(lastarid)
                lastarid = 0;
            end
            persistent lastorid;
            if isempty(lastorid)
                lastorid = 0;
            end
            persistent lastevid;
            if isempty(lastevid)
                lastevid = 0;
            end
            p = inputParser;
            p.addRequired('chantag', @isobject);
            %p.addRequired('time', @(t) t>0 & t<now+1);
            p.addRequired('time', @isnumeric);
            p.addRequired('iphase', @iscell);
            
            %p.addParamValue('arid', arid, @(i) floor(i)==i);
            p.addParamValue('arid', [], @isnumeric);
            p.addParamValue('orid', [], @isnumeric);
            p.addParamValue('evid', [], @isnumeric);
            %p.addParamValue('jdate', '0000000', @isstr);
            
            % Missed several properties out here just because of laziness.
            % Add them as needed.
            p.addParamValue('auth', '', @isstr);           
            p.parse(chantag, time, iphase, varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('%s = val;',field));
            end
            if exist('arid','var')
                obj.arid = arid;
            else
                obj.arid = lastarid + [1:numel(time)]';
            end
            lastarid = max(obj.arid);
            if exist('orid','var')
                obj.orid = orid;
            else
                obj.orid = lastorid + [1:numel(time)]';
            end
            lastorid = max(obj.orid);
            if exist('evid','var')
                obj.evid = evid;
            else
                obj.evid = lastevid + [1:numel(time)]';
            end            
            lastevid = max(obj.evid);

%             try 
                obj.table = table(time, cellstr(chantag.string()), cellstr(datestr(time,26)), cellstr(datestr(time, 'HH:MM:SS.FFF')), cellstr(iphase), ...
                    'VariableNames', {'datenum' 'channelinfo' 'date' 'time' 'iphase'});
%             catch ME
%                  tmpcell = {time, cellstr(chantag.string()), cellstr(datestr(time,26)), cellstr(datestr(time, 'HH:MM:SS.FFF')), cellstr(iphase)};
%                  obj.table = cell2table(tmpcell, 'VariableNames', {'datenum' 'channelinfo' 'date' 'time' 'iphase'});               
%             end
                    
            obj.table = sortrows(obj.table, 'datenum', 'ascend'); 
            fprintf('Got %d arrivals\n',obj.numberOfArrivals);
            
        end

                
        function val = get.date(obj)
            val = floor(obj.table.date);
        end
 
        function val = get.time(obj)
            val = datenum(obj.table.time);
        end
        
        function val = get.datenum(obj)
            val = obj.table.datenum;
        end 
        
        function val = get.channelinfo(obj)
            val = obj.table.channelinfo;
        end         
        
        function val = get.iphase(obj)
            val = obj.table.iphase;
        end
        
        function val = get.numberOfArrivals(obj)
            val = height(obj.table);
        end

        function val = get.snum(obj)
            val = min(obj.datenum);
        end
        
        function val = get.enum(obj)
            val = max(obj.datenum);
        end        
        obj = combine(obj1, obj2);
        disp(obj);
    end
	methods(Static)
		obj = retrieve(format, filepath)
		obj = retrieve_antelope(filepath)
		obj = retrieve_seisan(filepath)
		obj = retrieve_hypoellipse(filepath)
        arrivals_struct = readphafile(filepath)
	end
end
