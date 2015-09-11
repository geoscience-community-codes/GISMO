classdef Catalog_full < Catalog_base
%CATALOG_FULL: A class that serves as a container for EVENT objects.
% 
%% USAGE
%   cobj = Catalog_full(event_list)
%      where event_list is a vector of Event objects.
%
%% EXAMPLE
%
%   % create an Origin object
%   lat = 62.5; lon = -120.0; depth = 15.2; time = now;
%   o = Origin(time, lon, lat, depth);
%   
%   % create an Event object
%   e = Event([o]); % [o] is a vector of Origin objects
%
%   % create a Catalog_full object
%   c = Catalog_full([e]); % [e] is a vector of Event objects
%
%   This is a trivial example with only 1 origin and 1 event. In general,
%   a Catalog_full contains multiple Event objects, and each Event object may
%   contain multiple Origin objects. 
%                 
% 
%% See also EVENT, ORIGIN, EVENTRATE, READEVENTS, CATALOG_COOKBOOK
%
% Author: Glenn Thompson (glennthompson1971@gmail.com)
% $Date: $
% $Revision: $  

    properties(GetAccess = 'public', SetAccess = 'public')
        event_list;
    end
    properties(GetAccess = 'public', SetAccess = 'private')
        % derived properties
        % I set these private properties so that I can define get.property
        % functions to get these from event_list.origins
        % These cannot be defined in Catalog_base as could not then define
        % getters for them in Catalog_full
        lat;
        lon;
        depth;
        time;
        mag;
        etype;
    end
    methods
        function obj = Catalog_full(event_list, varargin)
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addRequired('event_list', @(e) strcmp(class(e), 'Event') | isempty(e));
            p.addParamValue('description', '', @isstr);
            p.parse(event_list, varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                obj = obj.set(field, val);
            end
        end
        
        %% THE FOLLOWING METHODS POPULATE PRIVATE PROPERTIES FOR 
        %  ETYPE, LAT, LON, DEPTH, TIME, DNUM, SNUM, ENUM
        %  THESE PROVIDE COMPATIBILITY BETWEEN NEW AND OLD VERSIONS OF
        %  THE CATALOG CLASS
        function et = get.etype(obj)
            o = origins(obj);
            et = [o.etype];
        end
        function l = get.lat(obj)
            o = origins(obj);
            l = [o.lat];
        end
        function l = get.lon(obj)
            o = origins(obj);
            l = [o.lon];
        end            
        function z = get.depth(obj)
            o = origins(obj);
            z = [o.depth];
        end 
        function t = get.time(obj)
            o = origins(obj);
            t = [o.time];
        end
        function m = get.mag(obj)
            o = origins(obj);
            %m_list = [o.netmags];
            ml_list = [o.ml];
            mb_list = [o.mb];
            ms_list = [o.ms];
            for i=1:length(ml_list)
                m(i)=NaN;
                if ~isnan(ml_list(i))
                    m(i)=ml_list(i);
                end
                if mb_list(i) > m(i)
                    m(i)=mb_list(i);
                end                
                if ms_list(i) > m(i)
                    m(i)=ms_list(i);
                end 
            end
        end

        function cobj = plus(cobj1, cobj2)
            cobj = [];

            if nargin<2
                return
            end
            
            if isempty(cobj1)
                cobj = cobj2;
                return
            end
            
            if isempty(cobj2)
                cobj = cobj1;
                return
            end 

            if isempty(cobj1.event_list) & isempty(cobj2.event_list)
                return
            end

            if isempty(cobj1.event_list)
                cobj = cobj2;  
            elseif isempty(cobj2.event_list)
                cobj = cobj1;
            else
                cobj = cobj1; 
                cobj.event_list = [cobj1.event_list cobj2.event_list];
                return
            end
        end
        
    end
    %%
    methods (Access=protected, Hidden=true)
        
        function o = origins(obj)
            % assumes only 1 origin per event
            % ignores concept of preferred origin
            o = [obj.event_list.origins];
        end   
        
    end
end
