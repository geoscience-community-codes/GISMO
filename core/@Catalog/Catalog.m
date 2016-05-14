%CATALOG the blueprint for Catalog objects in GISMO
% A Catalog object is a container for event metadata
% See also EventRate, readEvents, Catalog/Cookbook
classdef Catalog

    properties(Dependent) % These all come from table, computed on the fly
        otime = [];% origin time
        date = {};
        time = {};
        lon = [];
        lat = [];
        depth = [];
        mag = [];
        magtype = {};
        etype = {};
        ontime = [];
        offtime = [];
        
        numberOfEvents = 0;
  
    end
    
    properties % These are properties of the catalog itself
        request = struct();
%         request.startTime = -Inf;
%         request.endTime = Inf;
%         request.dataformat = '';
%         request.minimumLongitude = -Inf;
%         request.maximumLongitude = Inf; 
%         request.minimumLatitude = -Inf;
%         request.maximumLatitude = Inf;  
%         request.minimumDepth = -Inf;
%         request.maximumDepth = Inf;
%         request.minimumRadius = 0;
%         request.maximumRadius = Inf;
%         request.minimumMagnitude = -Inf;
%         request.maximumMagnitude = Inf;
        arrivals = {};
%         magnitudes = {};
        waveforms = {}; % cell array with one vector waveform objects per event
    end
    
    properties(Hidden) % internal, external code cannot access them
        table = table([], [], [],[], [], [], [], {}, {}, [], [], ...
                'VariableNames', ...
                {'otime' 'date' 'time' 'lon' 'lat' 'depth' 'mag' 'magtype' 'etype' 'ontime' 'offtime'});
    end

    methods

        %function obj = Catalog(otime, lon, lat, depth, mag, magtype, etype, varargin)
        function obj = Catalog(varargin)
            %Catalog.Catalog constructor for Catalog object
            % catalogObject = Catalog(lat, lon, depth, time, mag, etype, varargin)
            
            % Blank constructor
            if nargin==0
                return
            end
            
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addOptional('otime', [], @isnumeric)
            p.addOptional('lon', [], @isnumeric)
            p.addOptional('lat', [], @isnumeric)
            p.addOptional('depth', [], @isnumeric);
            p.addOptional('mag', [], @isnumeric);
            p.addOptional('magtype', {'un'}, @iscell);
            p.addOptional('etype', {'u'}, @iscell);
            p.addOptional('request',struct());
            p.addOptional('ontime', [], @isnumeric)
            p.addOptional('offtime', [], @isnumeric)
            %p.parse(otime, lon, lat, depth, mag, magtype, etype, varargin{:});
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('%s = val;',field));
            end

           % If we only have trigger on (&off) times but not origin times,
           % set origin times equal to ontimes
           if isempty(otime) & ~isempty(ontime)
               otime = ontime;
           end
           
           % reshape
           s=size(otime);
           s1=min(s);
           s2=max(s);
           otime = reshape(otime, [s2 s1]);
           
            % Fill empty vectors to size of time
            if isempty(lon)
                lon = NaN(s2,s1);
            end
            if isempty(lat)
                lat = NaN(s2,s1);
            end   
            if isempty(depth)
                depth = NaN(s2,s1);
            end
            if isempty(mag)
                mag = NaN(s2,s1);
            end  
            if isempty(magtype) % 'u' for unknown
                magtype = cellstr(repmat('u',[s2 s1]));
            end 
            if isempty(etype)  % 'u' for unknown
                etype = cellstr(repmat('u',[s2 s1]));
            end   

            if isempty(ontime)  % 'u' for unknown
                ontime = NaN(s2,s1);
            end   
            if isempty(offtime)  % 'u' for unknown
                offtime = NaN(s2,s1);
            end   
           lon = reshape(lon, [s2 s1]);
           lat = reshape(lat, [s2 s1]);
           depth = reshape(depth, [s2 s1]);
           mag = reshape(mag, [s2 s1]);
           magtype = reshape(magtype, [s2 s1]);
           if numel(ontime)==s1*s2
               ontime = reshape(ontime, [s2 s1]);
               offtime = reshape(offtime, [s2 s1]);
           end
           clear s s1 s2
           
           dstr = datestr(otime, 'yyyy_mm_dd');
           tstr = datestr(otime, 'HH:MM:SS.fff'); 
           tstr = tstr(:,1:10);

           obj.table = table(otime, dstr, tstr, ...
               lon, lat, depth, mag, magtype, etype, ontime, offtime, ...
                'VariableNames', {'otime' 'yyyy_mm_dd' 'hh_mm_ss' 'lon' 'lat' 'depth' 'mag' 'magtype' 'etype' 'ontime' 'offtime'});   
            
            obj.table = sortrows(obj.table, 'otime', 'ascend'); 
            fprintf('Got %d events\n',obj.numberOfEvents);

        end
        
        function val = get.otime(obj)
            val = obj.table.otime;
        end 
        
        function val = get.lon(obj)
            val = obj.table.lon;
        end        
        
        function val = get.lat(obj)
            val = obj.table.lat;
        end
        
        function val = get.depth(obj)
            val = obj.table.depth;
        end        
        
        function val = get.mag(obj)
            val = obj.table.mag;
        end          
        
        function val = get.magtype(obj)
            val = obj.table.magtype;
        end        
        
        function val = get.etype(obj)
            val = obj.table.etype;
        end
        
        function val = get.ontime(obj)
            val = obj.table.ontime;
        end
        
        function val = get.offtime(obj)
            val = obj.table.offtime;
        end
        
        function val = get.numberOfEvents(obj)
            val = height(obj.table);
        end
        
        function t=gettimerange(obj)
            snum = nanmin([obj.table.otime; obj.table.ontime]);
            enum = nanmax([obj.table.otime; obj.table.offtime]);
            t = [snum enum];
        end
          
        % Prototypes
        summary(obj)
        disp(catalogObject)
        catalogObject = combine(catalogObject1, catalogObject2)
        webmap(catalogObject)
        plot(catalogObject, varargin)
        plot3(catalogObject, varargin)
        plot_time(catalogObject)
        hist(catalogObject)
        bvalue(catalogObject, mcType)     
        subclassify(catalogObject, subclasses)         
        erobj=eventrate(catalogObject, varargin)
        plotprmm(catalogObject)
        eev(obj, eventnum)
        write(catalogObject, outformat, outpath, schema)
        catalogObject2 = subset(catalogObject, indices)
        catalogObject = addwaveforms(catalogObject, w);
    end
%% ---------------------------------------------------
    methods (Access=protected, Hidden=true)
        
        %% AUTOBINSIZE        
        function binsize = autobinsize(catalogObject)
        %autobinsize Compute the best bin size based on start and end times
            binsize = binning.autobinsize(catalogObject.enum - catalogObject.snum);
        end
%% ---------------------------------------------------        
        function region = get_region(catalogObject, nsigma)
        % region Compute the region to plot based on spread of lon,lat data
			medianlat = nanmedian(catalogObject.lat);
			medianlon = nanmedian(catalogObject.lon);
			cosine = cos(medianlat);
			stdevlat = nanstd(catalogObject.lat);
			stdevlon = nanstd(catalogObject.lon);
			rangeindeg = max([stdevlat stdevlon*cosine]) * nsigma;
			region = [(medianlon - rangeindeg/2) (medianlon + rangeindeg/2) (medianlat - rangeindeg/2) (medianlat + rangeindeg/2)];
        end
        
%% ---------------------------------------------------
        function symsize = get_symsize(catalogObject)
            %get_symsize Get symbol marker size based on magnitude of event
            % Compute Marker Size
            minsymsize = 3;
            maxsymsize = 50;
            symsize = (catalogObject.mag + 2) * 10; % -2- -> 1, 1 -> 10, 0 -> 20, 1 -> 30, 2-> 40, 3+ -> 50 etc.
            symsize(symsize<minsymsize)=minsymsize;
            symsize(symsize>maxsymsize)=maxsymsize;
            % deal with NULL (NaN) values
            symsize(isnan(symsize))=minsymsize;
        end
%% ---------------------------------------------------                      
                
    end

    methods(Static)
        function self = retrieve(dataformat, varargin)
        %CATALOG.RETRIEVE Read seismic events from common file formats & data sources.
        % readEvents can read events from many different earthquake catalog file 
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
                    self = Catalog.read_catalog.antelope(varargin{:});
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
        
        cookbook()
    end
end
