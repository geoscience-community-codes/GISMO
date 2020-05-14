%POSITION the blueprint for Position objects in GISMO
% Create with p=Position(lat, lon, elev)
% Properties are latitude, longitude and elevation, e.g.
%   lat = p.latitude;
classdef Position

    properties
        latitude;
        longitude;
        elevation;
    end
    
    properties(Dependent) % need get methods

    end

    methods

        function lobj = Position(varargin)
            %Position.Position constructor for Position object
            % lobj = Position(latitude, longitude, elevation)
            
            % Blank constructor
            if nargin==0
                return
            end
     
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addOptional('latitude', [], @isnumeric) % positional
            p.addOptional('longitude', [], @isnumeric)
            p.addOptional('elevation', [], @isnumeric) % positional
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('lobj.%s = val;',field));
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
