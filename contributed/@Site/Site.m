%SITE  Legacy site/station metadata container (DEPRECATED)
%
%   This class was an early prototype for representing station site
%   metadata (network, station, position, operational dates) in GISMO.
%   It predates the use of StationXML and is no longer used by the GISMO
%   core. It is retained only for backward compatibility with legacy
%   external workflows.
%
%   New code should use:
%       • ChannelTag for NSLC identity
%       • StationXML for geometry, epochs, and response
%
%   This class is intentionally located in:
%       contributed_legacy/
%
classdef Site

    properties
        network   = ''
        station   = ''
        position  = Position()
        ondate    = []
        offdate   = []
    end

    properties(Dependent)
        % duration in seconds (if ondate/offdate exist)
        duration
    end

    methods
        function sobj = Site(varargin)
            %SITE  Constructor for Site object
            %
            %   s = Site()
            %   s = Site(network, station, position)
            %   s = Site(network, station, position, ondate)
            %   s = Site(network, station, position, ondate, offdate)

            if nargin == 0
                return
            end

            p = inputParser;

            p.addRequired('network',  @(x) ischar(x) || isstring(x));
            p.addRequired('station',  @(x) ischar(x) || isstring(x));
            p.addRequired('position', @(p) isa(p,'Position'));

            p.addOptional('ondate',  [], @(t) isempty(t) || ...
                (isnumeric(t) && isscalar(t) && t > datenum(1900,1,1) && t < now+365));

            p.addOptional('offdate', [], @(t) isempty(t) || ...
                (isnumeric(t) && isscalar(t) && t > datenum(1900,1,1)));

            p.parse(varargin{:});

            sobj.network  = char(p.Results.network);
            sobj.station  = char(p.Results.station);
            sobj.position = p.Results.position;
            sobj.ondate   = p.Results.ondate;
            sobj.offdate  = p.Results.offdate;
        end

        %------------------------
        % Dependent property
        %------------------------
        function val = get.duration(obj)
            if isempty(obj.ondate) || isempty(obj.offdate)
                val = NaN;
            else
                val = 86400 * (obj.offdate - obj.ondate);
            end
        end
    end

end

