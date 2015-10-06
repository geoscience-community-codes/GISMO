classdef TraceData
   %TraceData handles the data associated with timeseries.  
   %   Tracedata might be considered a "light" version of the timeseries
   %   class. Whereas the timeseries class has lots of functionality, it
   %   suffers from much slower execution times.
   
   properties
      data
      start_time
      units
   end
   
   properties(Hidden=true)
      % when trust_assignments is false, then data
      trust_assignments = false; % if not trusted, then slows down computations somewhat, but is useful for debugging. 
      debug_level
   end
   
   methods
      
      
      % Mathamatical
      function obj = set.data(obj, values)
         % set.data ensures that data is always stored in a column
         disp('in set data')
         obj.data = values(:);
      end
      
      function obj = plus(obj, B)
         if ~isa(obj, 'TraceData')
            [obj, B] = deal(B, obj);
         end
         if isnumeric(B)
            obj.data(:) = obj.data + B(:);
         else
         switch class(B)
            case 'TraceData'
               obj.data = obj.data + B.data;
            case 'waveform'
               obj.data = obj.data + get(B,'data');
         end
         end
      end
      
               
   end
   
   methods(Static)
      function set_parameter(name, val)
         % set_parameter changes state behavior for the TraceData objects
         %
         %     TRUST_ASSIGNMENTS
         %     set_parameter('trust_assignments', true) will verify the
         %     shapes and types of each calculation before storing the data
         %     in the object
         %     set_parameter('trust_assignments', false) will not perform
         %     size/class checks. Use this only when you are looking for
         %     extra speed and tightly control the inputs to this class.
         %
         %     DEBUG_LEVEL
         %
         
         switch lower(name)
            case 'trust_assignments'
               % set the parameter trust_assignments to logical(val);
            case 'debug_level'
               % set the parameter debug_level to numerical val
            otherwise
         end
      end
            
   end
   
end

