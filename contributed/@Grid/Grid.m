classdef Grid
%GRID Generic 3-D geographic grid for source-location problems (GISMO)
%
% Originally developed for MVO amplitude & travel-time grids.
% Refactored for contributed use — no hard-coded volcano defaults.
%
% Optional Mapping Toolbox required only for plot().

    properties
        lat double = 0.0        % latitude of grid center
        lon double = 0.0        % longitude of grid center
        nx  double = 11         % number of X nodes
        ny  double = 11         % number of Y nodes
        xmin double = -0.0898   % degrees (≈10 km)
        xmax double =  0.0898
        ymin double = -0.0898
        ymax double =  0.0898
        depths double = -1:1:5
        x double = []
        y double = []
    end

    methods
        function obj = Grid(varargin)
            %GRID Constructor for Grid object
            %
            % obj = Grid() creates a default generic grid centered at 0,0
            % obj = Grid(lon,lat,nx,ny,xmin,xmax,ymin,ymax,depths)
            %
            % MVO preset available via Grid.presets.MVO()

            if nargin == 0
                obj = obj.make();
                return
            end

            p = inputParser;
            p.addOptional('lon',    obj.lon,    @isnumeric)
            p.addOptional('lat',    obj.lat,    @isnumeric)
            p.addOptional('nx',     obj.nx,     @isnumeric)
            p.addOptional('ny',     obj.ny,     @isnumeric)
            p.addOptional('xmin',  obj.xmin,   @isnumeric)
            p.addOptional('xmax',  obj.xmax,   @isnumeric)
            p.addOptional('ymin',  obj.ymin,   @isnumeric)
            p.addOptional('ymax',  obj.ymax,   @isnumeric)
            p.addOptional('depths',obj.depths, @isnumeric)

            p.parse(varargin{:});

            fields = fieldnames(p.Results);
            for i = 1:numel(fields)
                f = fields{i};
                obj.(f) = p.Results.(f);   % SAFE assignment
            end  

            obj = obj.make();
        end

        function obj = make(obj)
            %MAKE Generate grid coordinates

            assert(obj.nx > 1 && obj.ny > 1,'Grid must be at least 2x2');
            assert(obj.xmin < obj.xmax,'xmin must be < xmax');
            assert(obj.ymin < obj.ymax,'ymin must be < ymax');
            assert(~isempty(obj.depths),'depths must not be empty');

            obj.x = linspace(obj.lon + obj.xmin, obj.lon + obj.xmax, obj.nx);
            obj.y = linspace(obj.lat + obj.ymin, obj.lat + obj.ymax, obj.ny);
        end

        function plot(obj)
            %PLOT Visualize grid using Mapping Toolbox

            if ~license('test','map_toolbox')
                error('Grid.plot requires MATLAB Mapping Toolbox');
            end

            disp('Drawing webmap')
            webmap;
            wmlimits([obj.y(1) obj.y(end)], [obj.x(1) obj.x(end)]);

            nummarkers = numel(obj.y)*numel(obj.x);
            markernum = 0;

            for latnum = 1:numel(obj.y)
                for lonnum = 1:numel(obj.x)
                    markernum = markernum + 1;
                    wmmarker(obj.y(latnum), obj.x(lonnum));
                end
            end
        end
    end

    methods (Static)
        function obj = MVO()
            %MVO Preset for Soufriere Hills Volcano grid
            KM_PER_DEG = 111.32;

            obj = Grid( ...
                -62.1773, ...
                 16.7103, ...
                 11, 11, ...
                -10/KM_PER_DEG,  10/KM_PER_DEG, ...
                -10/KM_PER_DEG,  10/KM_PER_DEG, ...
                -1:1:5 );
        end
    end
end

