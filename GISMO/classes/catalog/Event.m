classdef Event
%EVENT: A class that serves as a container for ORIGIN and other objects.
% 
% The class Event describes a seismic event which does not necessarily need 
% to be a tectonic earthquake. An event is usually associated with one or 
% more origins, which contain information about focal time and geographical
% location of the event. Multiple origins can cover automatic and manual 
% locations, a set of location from different agencies, locations generated
% with different location programs and earth models, etc. Furthermore, an 
% event is usually associated with one or more magnitudes, and with one or
% more focal mechanism determinations.

% Event is modelled after the ObsPy Event class:
%   http://docs.obspy.org/packages/autogen/obspy.core.event.Event.html
%
%% USAGE
%   e = Event([Origin1 Origin2 Origin3])
%      creates an Event object with 3 Origin objects
%
%% EXAMPLE
%
%   % create an Origin object
%   lat = 62.5; lon = -120.0; depth = 15.2; time = now;
%   o1 = Origin(time, lon, lat, depth);
%
%   % create a 2nd Origin object
%   lat = 62.4; lon = -119.87; depth = 12.8; time = now-1/86400;
%   o2 = Origin(time, lon, lat, depth);
%   
%   % create an Event object
%   e = Event([o1 o2]);  
%                 
% 
%% See also CATALOG, ORIGIN, EVENTRATE, READEVENTS, CATALOG_COOKBOOK
%
% Author: Glenn Thompson (glennthompson1971@gmail.com)
% $Date: $
% $Revision: $  

    properties
        evid;
        evname;
        prefor;
        auth;        
        origins; %[Origin()];
    end
    methods
        function obj = Event(origins, varargin)
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            persistent evid;
            if isempty(evid)
                evid = 1;
            else
                evid = evid + 1;
            end  
            p = inputParser;
            p.addRequired('origins', @(o) strcmp(class(o), 'Origin'));
            p.addParamValue('evid', evid, @(i) floor(i)==i);
            p.addParamValue('evname', '', @isstr);
            p.addParamValue('prefor', NaN, @(i) floor(i)==i);
            p.addParamValue('auth', '', @isstr);
            p.parse(origins, varargin{:})
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                obj = obj.set(field, val);
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
                        self.(prop_name) = val;
                    else
                        warning('Property %s is a derived property and cannot be set',prop_name);
                    end
                end
                Vidx(1:2) = []; %done with those parameters, move to the next ones...
            end 
        end 
    end
end
            
    