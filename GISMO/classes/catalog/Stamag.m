classdef Stamag
    % Stamag
    properties
        magid;
        sta;
        arid;
        orid;
        evid;
        phase;
        magtype;
        magnitude;
        uncertainty;
        auth;
    end
    methods
        function obj = Stamag(sta, magnitude, varargin);
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            persistent magid;
            if isempty(magid)
                magid = 1;
            else
                magid = magid + 1;
            end  
            if magnitude==-999 % deal with Antelope NULL value
                magnitude=NaN;
            end
            p = inputParser;
            p.addRequired('sta', @isstr);
            p.addRequired('magnitude', @(m) (m>-3 & m<10) | isnan(m));
            p.addParamValue('magid', magid, @(i) floor(i)==i);
            p.addParamValue('arid', NaN, @(i) floor(i)==i);
            p.addParamValue('orid', NaN, @(i) floor(i)==i);
            p.addParamValue('evid', NaN, @(i) floor(i)==i);
            p.addOptional('phase', '', @isstr);
            p.addOptional('magtype', '', @isstr);
            p.addOptional('uncertainty', NaN, @isnumeric);
            p.addOptional('auth', '', @isstr);
            p.parse(sta, magnitude, varargin{:});
            for i=1:length(fields)
                field=fields{i};
                val = eval(sprintf('p.Results.%s;',field));
                obj = obj.set(field, val);
            end
        end
        function print(obj)
        end
    end
end