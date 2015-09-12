classdef Origin
%ORIGIN: A class that serves as a container for ORIGIN and other objects.
% 
% This class represents the focal time and geographical location of an 
% earthquake hypocenter, as well as additional meta-information. Origin can
% have objects of type Origerr and Arrival as child elements. 
%
%% USAGE
%   o = Origin(time, longitude, latitude, depth)
%      creates an Origin object with the time and co-ordinates specified.
%
%% EXAMPLE
%
%   % create an Origin object
%   lat = 62.5; lon = -120.0; depth = 15.2; time = now;
%   o = Origin(time, lon, lat, depth);
%                 
% 
%% See also CATALOG, EVENT, EVENTRATE, READEVENTS, CATALOG_COOKBOOK
%
% Author: Glenn Thompson (glennthompson1971@gmail.com)
% $Date: $
% $Revision: $  
    properties
        lat;
        lon;
        depth;
        time;
        orid;
        evid;
        jdate;
        nass;
        ndef;
        ndp;
        grn;
        srn;
        etype;
        review;
        depdp;
        dtype;
        mb;
        mbid;
        ms;
        msid;
        ml;
        mlid;
        algorithm;
        auth;
        netmags;
        origerrs;
        arrivals;
    end
    methods
        function obj = Origin(time, lon, lat, depth, varargin)
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            persistent orid;
            if isempty(orid)
                orid = 1;
            else
                orid = orid + 1;
            end  
            p = inputParser;
            p.addRequired('time', @(t) t>0 & t<now+1);
            p.addRequired('lon', @(x) (x>=-180.0 & x<=180.0) | isnan(x));
            p.addRequired('lat', @(x) (x>=-90.0 & x<=90.0) | isnan(x));
            p.addRequired('depth', @(x) (x>=-10.0 & x<=7000.0) | isnan(x)); % km?
            p.addParamValue('orid', orid, @(i) floor(i)==i);
            p.addParamValue('evid', NaN, @(i) floor(i)==i);
            p.addParamValue('jdate', '0000000', @isstr);
            p.addParamValue('nass', NaN, @(i) floor(i)==i);  
            p.addParamValue('ndef', NaN, @(i) floor(i)==i); 
            p.addParamValue('ndp', NaN, @(i) floor(i)==i); 
            p.addParamValue('grn', NaN, @(i) floor(i)==i); 
            p.addParamValue('srn', NaN, @(i) floor(i)==i); 
            p.addParamValue('etype', '_', @isstr);
            p.addParamValue('review', '', @isstr); 
            p.addParamValue('depdb', NaN, @(i) floor(i)==i); 
            p.addParamValue('dtype', '', @isstr);
            p.addParamValue('mb', NaN, @isnumeric);
            p.addParamValue('mbid', NaN, @(i) floor(i)==i);
            p.addParamValue('ms', NaN, @isnumeric);
            p.addParamValue('msid', NaN, @(i) floor(i)==i);
            p.addParamValue('ml', NaN, @isnumeric);
            p.addParamValue('mlid', NaN, @(i) floor(i)==i);            
            p.addParamValue('algorithm', '', @isstr);
            p.addParamValue('auth', '', @isstr);
            p.addParamValue('netmags', []);
            p.addParamValue('origerrs', []);
            p.addParamValue('arrivals', []);           
            p.parse(time, lon, lat, depth, varargin{:});
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