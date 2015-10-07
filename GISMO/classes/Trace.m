classdef Trace < TraceData
   % Trace is the new waveform
   properties
      channelInfo % channelTag
   end
   
   methods
      function obj = Trace(varargin)
         obj@TraceData(varargin{:});
         switch nargin
            case 1
               if isa(varargin{1}, 'waveform')
                  obj.channelInfo = get(varargin{1},'channeltag');
               end
               
         end %switch
      end
   end
end
