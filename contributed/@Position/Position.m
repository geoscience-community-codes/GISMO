%POSITION  Legacy geographic position container (DEPRECATED)
%
%   This class represents a simple geographic position (latitude,
%   longitude, elevation). It predates the adoption of StationXML-based
%   metadata handling in GISMO and is retained only for backward
%   compatibility with legacy external workflows.
%
%   New code should use StationXML + ChannelTag metadata instead.
%
%   This class is intentionally located in:
%       contributed_legacy/
%
classdef Position

    properties
        latitude   = NaN
        longitude  = NaN
        elevation  = NaN
    end

    methods
        function pobj = Position(varargin)
            %POSITION  Constructor for Position object
            %
            %   p = Position()
            %   p = Position(lat, lon)
            %   p = Position(lat, lon, elev)

            if nargin == 0
                return
            end

            p = inputParser;
            p.addRequired('latitude',  @(x) isnumeric(x) && isscalar(x));
            p.addRequired('longitude', @(x) isnumeric(x) && isscalar(x));
            p.addOptional('elevation', NaN, @(x) isnumeric(x) && isscalar(x));
            p.parse(varargin{:});

            pobj.latitude  = p.Results.latitude;
            pobj.longitude = p.Results.longitude;
            pobj.elevation = p.Results.elevation;
        end
    end
end
