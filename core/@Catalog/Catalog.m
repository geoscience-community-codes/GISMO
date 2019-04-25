%CATALOG the blueprint for Catalog objects in GISMO
% A Catalog object is a container for event metadata
% See also EventRate, readEvents, Catalog/Cookbook
classdef Catalog

    properties
        otime = [];% origin time
%         date = {};
%         time = {};
        lon = [];
        lat = [];
        depth = [];
        mag = [];
        magtype = {};
        etype = {};
        ontime = [];
        offtime = [];
        request = struct();
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
    
    properties(Dependent)
        numberOfEvents;
        duration;
        cum_mag;
        max_mag;
        peakrate;
    end


    methods

        %function obj = 
        function obj = Catalog(varargin)
            %Catalog.Catalog constructor for Catalog object
            % catalogObject = Catalog(otime, lon, lat, depth, mag, magtype, etype, varargin)
            
            % Blank constructor
            if nargin==0
                return
            end
            
%             % Table constructor
%             if nargin==1
%                 if isa(varargin{1},'table')
%                     obj.table = varargin{1};
%                 end
%                 return
%             end
            
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addOptional('otime', [], @isnumeric) % positional
            p.addOptional('lon', [], @isnumeric)
            p.addOptional('lat', [], @isnumeric)
            p.addOptional('depth', [], @isnumeric);
            p.addOptional('mag', [], @isnumeric);
            p.addOptional('magtype', {}, @iscell);
            p.addOptional('etype', {}, @iscell);
            p.addParameter('request', struct(), @isstruct); % optional name-param pairs
            p.addParameter('ontime', [], @isnumeric)
            p.addParameter('offtime', [], @isnumeric)
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
           
           if s1*s2 > 0
           
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

%                dstr = datestr(otime, 'yyyy_mm_dd');
%                tstr = datestr(otime, 'HH:MM:SS.fff'); 
%                tstr = tstr(:,1:10);
               obj.otime = otime;
               obj.lat = lat;
               obj.lon = lon;
               obj.depth = depth;
               obj.mag = mag;
               obj.magtype = magtype;
               obj.etype = etype;
               obj.ontime = ontime;
               obj.offtime = offtime;

                fprintf('Got %d events\n',obj.numberOfEvents);
           end

        end
        
%         function val = get.otime(obj)
%             val = obj.table.otime;
%         end 
%         
%         function val = get.lon(obj)
%             val = obj.table.lon;
%         end        
%         
%         function val = get.lat(obj)
%             val = obj.table.lat;
%         end
%         
%         function val = get.depth(obj)
%             val = obj.table.depth;
%         end        
%         
%         function val = get.mag(obj)
%             val = obj.table.mag;
%         end          
%         
%         function val = get.magtype(obj)
%             val = obj.table.magtype;
%         end        
%         
%         function val = get.etype(obj)
%             val = obj.table.etype;
%         end
%         
%         function val = get.ontime(obj)
%             val = obj.table.ontime;
%         end
%         
%         function val = get.offtime(obj)
%             val = obj.table.offtime;
%         end

        function val = get.duration(obj)
            val = 86400 * (obj.offtime - obj.ontime);
        end
        
        function val = get.numberOfEvents(obj)
            val = max([ numel(obj.otime) numel(obj.ontime)]);
        end

        function val = get.cum_mag(obj)
            val = magnitude.eng2mag( sum(magnitude.mag2eng(obj.mag)) );
        end 
        
        function mm = get.max_mag(obj)    
            % return max_mag as the real component & percentage through the
            % time series as the imaginary component (use real() & imag()
            % to separate these)
            t=obj.gettimerange();
            days = t(2) - t(1);
            [mm, mmi] = max(obj.mag);
            mmpercent = 100*(obj.otime(mmi) - t(1))/days;
            mm = mm + mmpercent * j;
        end
        
        function pr = get.peakrate(obj)
            t=obj.gettimerange();
            days = t(2) - t(1);
            binsize = days/100;
            erobj = obj.eventrate('binsize',binsize);
            [pr, pri] = max(erobj.counts);              
            pr = pr + 100*(erobj.time(pri) - erobj.snum)/(erobj.enum-erobj.snum) * j;
        end
            

        
        function t=gettimerange(obj)
            snum = nanmin([obj.otime; obj.ontime]);
            enum = nanmax([obj.otime; obj.offtime]);
            t = [snum enum];
        end
        
        function cobj3 = add(cobj1, cobj2)
% combine method already exists, but uses tables - Catalog isn't a table
% anymore
            cobj3 = cobj1;
            cobj3.otime = [cobj1.otime; cobj2.otime];
            cobj3.lon = [cobj1.lon; cobj2.lon];
            cobj3.lat = [cobj1.lat; cobj2.lat];
            cobj3.depth = [cobj1.depth; cobj2.depth];
            cobj3.mag = [cobj1.mag; cobj2.mag];
            cobj3.magtype = [cobj1.magtype; cobj2.magtype];
            cobj3.etype = [cobj1.etype; cobj2.etype];
            cobj3.ontime = [cobj1.ontime; cobj2.ontime];
            cobj3.offtime = [cobj1.offtime; cobj2.offtime];
            cobj3.arrivals = [cobj1.arrivals; cobj2.arrivals];
            cobj3.waveforms = [cobj1.waveforms; cobj2.waveforms];    
        end
          
        % Prototypes
        gr = bvalue_old(catalogObject, mcType, runmode) 
        gr = bvalue(catalogObject, runmode)
        [a,b,Mc,berror] = bvaluetimeseries(cobj, N, stepsize)
        [swarminess, magstd] = swarminess(cobj, N)
        spatial_density(cobj)
        catalogObject = addwaveforms(catalogObject, varargin);
        catalogObject = combine(catalogObject1, catalogObject2)
        catalogObject2 = subset(catalogObject, varargin)
        catalogObjects = subclassify(catalogObject, subclasses)         
        disp(catalogObject)
        eev(obj, eventnum)
        erobj = eventrate(catalogObject, varargin)
        hist(catalogObject)
        list_waveform_metrics(catalogObject);
        plot(catalogObject, varargin)
        plot3(catalogObject, varargin)
        plot_time(catalogObject)
        plot_waveform_metrics(catalogObject);
        plotprmm(catalogObject)
        summary(catalogObject)
        webmap(catalogObject)
        write(catalogObject, outformat, outpath, schema)
        arrivals_per_event(catalogObject)
        
    end
%% ---------------------------------------------------
    methods (Access=protected, Hidden=true)
        region = get_region(catalogObject, nsigma)
        symsize = get_symsize(catalogObject)
    end

    methods(Static)
        self = retrieve(dataformat, varargin)
    end
end
