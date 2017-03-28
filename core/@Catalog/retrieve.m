function self = retrieve(dataformat, varargin)
%CATALOG.RETRIEVE Read seismic events from common file formats & data sources.
% retrieve can read events from many different earthquake catalog file 
% formats (e.g. Seisan, Antelope) and data sources (e.g. IRIS DMC) into a 
% GISMO Catalog object.
%
% Usage:
%       catalogObject = CATALOG.RETRIEVE(dataformat, 'param1', _value1_, ...
%                                                   'paramN', _valueN_)
% 
% dataformat may be:
%
%   * 'iris' (for IRIS DMC, using irisFetch.m), 
%   * 'antelope' (for a CSS3.0 Antelope/Datascope database)
%   * 'seisan' (for a Seisan database with a REA/YYYY/MM/ directory structure)
%   * 'zmap' (converts a Zmap data strcture to a Catalog object)
%
% The name-value parameter pairs supported are the same as those supported
% by irisFetch.Events(). Currently these are:
%
%     startTime
%     endTime
%     eventId
%     fetchLimit
%     magnitudeType
%     minimumLongitude
%     maximumLongitude
%     minimumLatitude
%     maximumLatitude
%     minimumMagnitude
%     maximumMagnitude
%     minimumDepth
%     maximumDepth
% 
% And the two convenience parameters:
%
% radialcoordinates = [ centerLatitude, centerLongitude, maximumRadius ]
%
% boxcoordinates = [ minimumLatitude maximumLatitude minimumLongitude maximumLongitude ]
% 
% For examples, see Catalog_cookbook. Also available at:
% https://geoscience-community-codes.github.io/GISMO/tutorials/html/Catalog_cookbook.html
%
%
% See also CATALOG, IRISFETCH, CATALOG_COOKBOOK

% Author: Glenn Thompson (glennthompson1971@gmail.com)

%% To do:
% Implement name-value parameter pairs for all methods
% Test the Antelope method still works after factoring out db_load_origins
% Test the Seisan method more
% Add in support for 'get_arrivals'

    debug.printfunctionstack('>')

    switch lower(dataformat)
        case 'iris'
            if exist('irisFetch.m','file')
                    ev = irisFetch.Events(varargin{:});
                    self = Catalog.read_catalog.iris(ev);
            else
                warning('Cannot find irisFetch.m')
            end
        case {'css3.0','antelope', 'datascope'}
            if admin.antelope_exists()
                self = Catalog.read_catalog.antelope(varargin{:});
            else
                warning('Sorry, cannot read event Catalog from Antelope database as Antelope toolbox for MATLAB not found')
                self = Catalog();
            end
        case 'seisan'
            self = Catalog.read_catalog.seisan(varargin{:});
        case 'aef'
            self = Catalog.read_catalog.aef(varargin{:});
        case 'sru'
            self = Catalog.read_catalog.sru(varargin{:});
        case 'vdap'
            self = Catalog.read_catalog.vdap(varargin{:});
        case 'zmap'
            self = Catalog.read_catalog.zmap(varargin{:});
        otherwise
            self = NaN;
            fprintf('format %s unknown\n\n',data_source);
    end
    if isempty(self)
        self=Catalog();
    end

    debug.printfunctionstack('<')
end