classdef Arrival
    properties
        sta;
        time;
        arid;
        jdate;
        chan;
        iphase;
        deltim;
        azimuth;
        delaz;
        slow;
        delslo;
        ema;
        rect;
        amp;
        per;
        clip;
        fm;
        snr;
        qual;
        auth;
    end
    methods
        function obj = Arrival(sta, chan, time, varargin)
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
            p.addParamValue('arid', arid, @(i) floor(i)==i);
            p.addParamValue('jdate', '0000000', @isstr);
            p.addParamValue('iphase', '', @isstr);
            % Missed several properties out here just because of laziness.
            % Add them as needed.
            p.addParamValue('auth', '', @isstr);           
            p.parse(sta, chan, time, varargin{:});
            for i=1:length(fields)
                field=fields{i};
                % val = eval(sprintf('p.Results.%s;',field));
                val = p.Results.(field);
                obj = obj.set(field, val);
            end
        end
    end
end