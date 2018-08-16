%DRUMPLOT the blueprint for drumplot objects in GISMO
% A drumplot object is for making helicorder plots
% optionally detected events can be superimposed from a catalog object
classdef drumplot

    properties
        wave = waveform();
        catalog = Catalog();
        detections = Detection();
        arrivals = Arrival();
        mpl = 10;   % 10 Minutes per line
        trace_color = [0 0 0]; % black
        event_color = [1 0 0]; % red
        scale = 1;  
        ytick = 0;
        display = 'single';
        % not sure these are all used
    end

    methods

        function obj = drumplot(varargin)
            %drumplot.drumplot constructor for drumplot object
            %DRUMPLOT: Drumplot generates a multi-line display of input waveform
            %   data. Drumplot can display waveform data from multiple stations and 
            %   channels as long as the time range is the same for each. Drumplot
            %   can also display detected events over the raw data.
            %
            %USAGE: drumplot()----------------------- Empty drumplot
            %       drumplot(wave)------------------- Default properties
            %       drumplot(wave,prop_1,val_1,...)-- User-defined properties
            %
            %VALID PROP/VAL:
            %  'mpl'-->(Minutes Per Line)
            %     single numeric value specifying number of minutes per drumplot
            %     line. (This applies to all waveforms in the drumplot)
            %     DEFAULT = 10 
            %
            %  'ytick'-->(Y-Axis Ticks)
            %     single numeric value specifying number of minutes between y-axis 
            %     tick marks and labels. 'ytick' depends on 'mpl', for example, if 
            %     'mpl' is 20, an attempt to set 'ytick' to 10 will be result in 
            %     'ytick' rounded to nearest multiple of 'mpl' (20 in this case). Note
            %     also that manually setting 'mpl' will result in an automatic
            %     adjustment of 'ytick'.
            %     DEFAULT = 30
            %
            %  'catalog'-->(Catalog object from which event start/stop times are retrieved) 
            %     EXAMPLE: h = drumplot(w,'catalog',cobj) where w is a 1x2 waveform object
            %        cobj is a Catalog object
            %     DEFAULT = [] (No events)

            %  'trace_color'-->(Trace Color)
            %     If wave contains only one wavefrom object, 'trace_color' can be 
            %     entered as a 1x3 array of RGB values (between 0 and 1). For wave
            %     arguments longer than 1, 'trace_color' should be entered as a 1xN
            %     cell array, each containing a 1x3 array of RGB values.
            %
            %INPUTS: wave     - a waveform object to be plotted on multiple drumplot
            %                   trace lines
            %        varargin - user-defined drumplot properties (argument pairs)                  
            %
            %OUTPUTS: h - drumplot object
            %
            %   See also DRUMPLOT/DISP, DRUMPLOT/BUILD, DRUMPLOT/GET,
            %            DRUMPLOT/SET
            %
            % Author: Dane Ketner, Alaska Volcano Observatory
            % Modified: Glenn Thompson 2016-04-19 to work with Catalog objects
            % $Date$
            % $Revision$

            % Blank constructor
            if nargin==0
                return
            end
            
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addOptional('wave', obj.wave)
            p.addParameter('mpl', obj.mpl, @(i) floor(i)==i)
            p.addParameter('catalog', obj.catalog)
            p.addParameter('detections', obj.detections)
            p.addParameter('arrivals', obj.arrivals)
            p.addParameter('trace_color', obj.trace_color);
            p.addParameter('event_color', obj.event_color);
            p.addParameter('ytick', obj.ytick, @isnumeric);
            p.addParameter('scale', obj.scale, @isnumeric);
            p.addParameter('display', obj.display, @isstr);
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('obj.%s = val;',field));
            end            
            
            % Validation
            if ~isa(obj.wave, 'waveform') | numel(obj.wave)~=1
               error('Input waveform must be a single waveform object')
            end
            
            if ~isa(obj.catalog, 'Catalog') | numel(obj.catalog)~=1
               error('Input catalog must be a single Catalog object')
            end
            
            if ~isa(obj.detections, 'Detection') | numel(obj.detections)~=1
               error('Input detections must be a single Detection object')
            end
            
            if ~isa(obj.arrivals, 'Arrival') | numel(obj.arrivals)~=1
               error('Input arrivals must be a single Arrival object')
            end            
        end
        
        % Prototypes
        plot(obj)
%         val=get(obj, name)
%         obj=set(obj, val)
        
    end % methods
    
    methods(Static)
        % Prototypes
        cookbook(obj)
    end
end % classdef


  
