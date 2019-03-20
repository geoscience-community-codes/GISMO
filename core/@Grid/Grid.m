%GRID the blueprint for Grid objects in GISMO
% A Grid object is a container for a 3-D grid
% and is used in processes that try to solve for
% source locations, based on travel-time differences
% or amplitude ratios. The Grid class is based on the
% variables used by ttgrid in Antelope.
classdef Grid

    properties
        lat = 16.7103;% latitude of grid center
        lon = -62.1773;% longitude of grid center
        nx = 11;% Number of X-axis distance grid nodes
        ny = 11;% Number of Y-axis distance grid nodes
        xmin = -km2deg(10.0); % Minimum value of X-axis distance grid in degrees
        xmax = km2deg(10.0); % Minimum value of X-axis distance grid in degrees
        ymin = -km2deg(10.0); % Minimum value of Y-axis distance grid in degrees
        ymax = km2deg(10.0); % Minimum value of Y-axis distance grid in degrees 
        depths = -1.0:1.0:5.0; % Depths at which to repeat each x-y grid layer
        x = [];
        y = [];
    end


    methods
        function obj = Grid(varargin)
            %Grid.Grid constructor for Grid object
            % gridObject = Grid(varargin) creates a default grid centered
            % on Soufriere Hills Volcano, with 11 nodes in the N-S direction,
            % and 11 nodes in the E-W direction on layers defined by the
            % depths vector. So there are 121 nodes on each layer and 7
            % layers, for a total of 847 trial nodes.
            
            % Blank constructor
            if nargin==0
                obj = make(obj);
                return
            end
            
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addOptional('lon', obj.lon, @isnumeric)
            p.addOptional('lat', obj.lat, @isnumeric)
            p.addOptional('nx', obj.nx, @isnumeric);
            p.addOptional('ny', obj.ny, @isnumeric);
            p.addOptional('xmin', obj.xmin, @isnumeric);
            p.addOptional('xmax', obj.xmax, @isnumeric);
            p.addOptional('ymin', obj.ymin, @isnumeric);
            p.addOptional('ymax', obj.ymax, @isnumeric);
            p.addOptional('depths', obj.depths, @isnumeric);
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('obj.%s = val;',field));
            end  
            obj = make(obj);
        end
        
        function obj = make(obj)
           obj.x = linspace(obj.lon + obj.xmin, obj.lon + obj.xmax, obj.nx);
           obj.y = linspace(obj.lat + obj.ymin, obj.lat + obj.ymax, obj.ny);
        end
        
        function plot(obj)
            disp('Drawing webmap')
            webmap;
%             disp('Centering')
%             wmcenter(obj.lat, obj.lon);
            disp('Imposing limits')
            wmlimits([obj.y(1) obj.y(end)], [obj.x(1) obj.x(end)]);
            nummarkers = numel(obj.y)*numel(obj.x);
            markernum = 0;
            for latnum = 1:numel(obj.y)
                for lonnum = 1:numel(obj.x)
                    markernum = markernum + 1;
                    disp(sprintf('Adding marker %d of %d at %f,%f',markernum, nummarkers, obj.y(latnum),obj.x(lonnum)));
                    wmmarker(obj.y(latnum), obj.x(lonnum));
                end
            end
        end

    end
end
