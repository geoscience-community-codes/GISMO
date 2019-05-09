%MULTIPLETCHAN - the blueprint for a Peakmatch Multiplet Channel object in GISMO
%a multipletchan object is a container for the relevant information for a
%peakmatch multiplet set such as channeltag and filepaths to waveforms,
classdef MultipletChan
    
    properties 
       ctag
       filepaths = {}
    end
    
    properties (Dependent)
        numfiles
    end
    
    methods
        function obj = MultipletChan(varargin)
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
            
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('%s = val;',field));
            end
            
            
            obj.ctag = ctag
            obj.filepaths = filepaths
            
        end
        
        function val = get.numfiles(obj)
            for c = 1:numel(obj.ctag)
                val(c) = numel(obj.filepaths)
            end
        end
       
    end
end
    
   