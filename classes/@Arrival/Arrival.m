%Arrival the blueprint for Arrival objects in GISMO
% An Arrival object is a container for phase arrival metadata
% See also Catalog
classdef Arrival
    properties(Dependent)
        channelinfo
        time
        arid
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
    end
    properties(Hidden)
        table
    end
    methods
        function obj = Arrival(sta, chan, time, iphase, varargin)
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            persistent arid;
            if isempty(arid)
                arid = 1;
            else
                arid = arid + 1;
            end  
            p = inputParser;
            p.addRequired('sta', @isstr);
            p.addRequired('chan', @isstr);
            p.addRequired('time', @(t) t>0 & t<now+1);
            p.addRequired('iphase', @isstr);
            
            p.addParamValue('arid', arid, @(i) floor(i)==i);
            %p.addParamValue('jdate', '0000000', @isstr);
            
            % Missed several properties out here just because of laziness.
            % Add them as needed.
            p.addParamValue('auth', '', @isstr);           
            p.parse(sta, chan, time, iphase, varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('%s = val;',field));
            end
            ctag = ChannelTag('',sta,'',chan);
            datestr(time,26)
            datestr(time,13)
            ctag.string()
            iphase
            obj.table = table(datestr(time,26), datestr(time,13), ctag.string(), iphase, ...
                'VariableNames', {'date' 'time' 'channelinfo' 'iphase'});
            
        end
    end
end