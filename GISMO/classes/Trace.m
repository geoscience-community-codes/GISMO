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
      
      function obj = align(obj, alignTime, newFrequency, method)
         error('unimplemented function');
      end
      
      %function stack
      %function binstack
      %function combine
      %function extract
      %function gettimerange
      %function ismember
      %function isvertical (?) don't like this.
      
      %function calib_apply
      %function calib_remove
      
      %function plot
      %function legend
      %function linkedplot
      
      %function addfield
      %function delfield
      %function isfield
      %
      %function addhistory
      %function clearhistory
      %function history
      
   end
end
