%SITE the blueprint for Calibration objects in GISMO
classdef Calibration

    properties
        nslc;
        calib;
        units;
        ondate;
        offdate;
    end
    
    properties(Dependent) % need get methods

    end

    methods

        function sobj = Calibration(varargin)
            %Calibration.Calibration constructor for Calibration object
            % sobj = Calibration(ChannelTag, calibration [[, ondate [, offdate])
            
            % Blank constructor
            if nargin==0
                return
            end
     
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addRequired('nslc', @(c) strcmp(class(c),'ChannelTag') ) % positional
            p.addRequired('calib', @isnumeric ) % positional
            p.addRequired('units', @isstr ) % positional
            p.addOptional('ondate', [], @(t1) t1>datenum(1900,1,1) & t1<now+365) % ondate should be reasonable
            p.addOptional('offdate', [], @(t2) t2>datenum(1900,1,1))
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('sobj.%s = val;',field));
            end

        end

%         % Get methods
%         function val = get.duration(obj)
%             val = 86400 * (obj.offtime - obj.ontime);
%         end
           
        % Prototypes
        
    end
%% ---------------------------------------------------
    methods (Access=protected, Hidden=true)
    end

    methods(Static)
    end

end
