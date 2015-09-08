classdef Netmag
    % Netmag
    properties
        magid;
        net;
        orid;
        evid;
        magtype;
        nsta;
        magnitude;
        uncertainty;
        auth;
        stamags;
    end
    methods
        function self = Netmag(magnitude, varargin);
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            persistent magid;
            if isempty(magid)
                magid = 1;
            else
                magid = magid + 1;
            end  
            p = inputParser;
            if magnitude==-999 % deal with Antelope NULL value
                magnitude=NaN;
            end
            p.addRequired('magnitude', @(m) (m>-3 & m<10) | isnan(m));
            p.addParamValue('magid', magid, @(i) floor(i)==i);
            p.addParamValue('net', '_', @isstr);
            p.addParamValue('orid', NaN, @(i) floor(i)==i);
            p.addParamValue('evid', NaN, @(i) floor(i)==i); 
            p.addParamValue('magtype', '', @isstr);
            p.addParamValue('nsta', NaN, @(i) floor(i)==i);
            p.addParamValue('uncertainty', NaN, @isnumeric);  
            p.addParamValue('auth', '', @isstr);
            p.addParamValue('stamags', []);          
            p.parse(magnitude, varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = eval(sprintf('p.Results.%s;',field));
                self = self.set(field, val);
            end                        
        end
        %% SET
        function self = set(self, varargin)
            %SET Set properties
            %   self = set(self,'property_name', val, ['property_name2', val2])
            %   For a list of valid property names, type:
            %       properties(self)

            Vidx = 1 : numel(varargin);

            while numel(Vidx) >= 2
                prop_name = upper(varargin{Vidx(1)});
                val = varargin{Vidx(2)};
                mask = strcmp(upper(prop_name),upper(properties(self)));
                if any(mask)
                    mc = metaclass(self);
                    i = find(mask);
                    prop_name = mc.PropertyList(i).Name;
                    if isempty(mc.PropertyList(i).GetMethod)
                        % The properties here need to have
                        % SetAccess==public
                        eval(sprintf('self.%s=val;',prop_name));
                    else
                        warning('Property %s is a derived property and cannot be set',prop_name);
                    end
                end
                Vidx(1:2) = []; %done with those parameters, move to the next ones...
            end 
        end 
    end
end