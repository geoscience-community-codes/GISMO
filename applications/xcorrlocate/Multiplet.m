%MULTIPLETCHAN - the blueprint for a Peakmatch Multiplet Channel object in GISMO
%a multipletchan object is a container for the relevant information for a
%peakmatch multiplet set such as channeltag and filepaths to waveforms,
classdef Multiplet
    
    properties 
       ctag
       filepaths = {}
       waveforms
       arrivals
    end
    
    properties (Dependent)
        numfiles
    end
    
    methods
        function obj = Multiplet(varargin)
            % Constructor for the MultipletChan object
            
            % if no arguments passed
            if nargin == 0
                return
            end
            
            % create parser object
            p = inputParser;
            
            % positional arguments - may change to parameter arguments idk
            p.addOptional('ctag', @ChannelTag)
            p.addOptional('filepaths', {}, @iscell)
            p.addOptional('waveforms', @waveform)
            p.addOptional('arrivals',@Arrival)
            
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('%s = val;',field));
            end
            
            % if no waveform is passed make it an empty waveform object
            if isempty(waveforms)
               waveforms = waveform();
            end
            
            % if no arrival object passed make it an empty Arrival object
            if isempty(arrivals)
               arrivals = Arrival();
            end
            
            % assign properties
            obj.ctag = ctag;
            obj.filepaths = filepaths;
            obj.waveforms = waveforms;
            obj.arrivals = arrivals;
            
        end
        
        function val = get.numfiles(obj)
            for c = 1:numel(obj.ctag)
                val(c) = numel(obj.filepaths);
            end
        end
       
    end
end
    
   