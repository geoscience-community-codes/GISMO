%SITE the blueprint for Site objects in GISMO
classdef Site

    properties
        network;
        station;
        position;
        ondate;
        offdate;
    end
    
    properties(Dependent) % need get methods

    end

    methods

        function sobj = Site(varargin)
            %Site.Site constructor for Site object
            % sobj = Site(ChannelTag, Location)
            
            % Blank constructor
            if nargin==0
                return
            end
     
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
%            p.addRequired('nscl', @(c) strcmp(class(c),'ChannelTag') ) % positional
            p.addRequired('network', @ischar ) % positional
            p.addRequired('station', @ischar ) % positional
            p.addRequired('position', @(p) strcmp(class(p),'Position'));
%             p.addOptional('ondate', [], @isnumeric)
%             p.addOptional('offdate', [], @isnumeric)
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
