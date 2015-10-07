classdef TraceData
   %TraceData handles the data associated with timeseries.  
   %   Tracedata might be considered a "light" version of the timeseries
   %   class. Whereas the timeseries class has lots of functionality, it
   %   suffers from much slower execution times.
   
   % trying new tactic.  I won't try to anticipate all the various ways
   % someone can provide incompatible data. Instead, I'm going to provide a
   % comment with my expectations which will show up automatically in the
   % displayed error.
   
   properties
      data
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
            obj.data = values(:);
      end
      
      function obj = plus(obj, B)
         % PLUS add something to the TraceData's data,
         %   This will return a TraceData object
         %
         %   valid combinations (let TD represent any TraceData object)
         %      TraceData + TraceData;  % as long as both have same length of data
         %      TraceData + N; % where N is a column of numbers same length as td.data
         %      TraceData + Scalar;
         %
         %   efficiency note:
         %     slightly more efficient when TraceData is first.
         %     e.g.   TD + X   instead of   X + TD
         
         % apparently, have a 10% improvement over waveform +
         if ~isa(obj, 'TraceData')
            [obj, B] = deal(B, obj); % swap values
         end
         if isnumeric(B)
            obj.data = obj.data + B; % add to either a scalar or a COLUMN of numbers (same length as TraceData's data)
         else
            switch class(B)
               case 'TraceData'
                  assert(numel(obj.data) == numel(B.data), 'TraceData:plus:incorrectSize', 'Both data fields need to be the same size')
                  assert(isempty(B.units) || strcmp(obj.units, B.units), 'TraceData:plus:missmatchedUnits', 'TraceData only adds items with the same units');
                  obj.data = obj.data + B.data;
               case 'waveform'
                  disp('mix and match of TraceData and waveform. Not really recommended');
                  assert(get(B,'data_length') == numel(obj.data), 'TraceData:plus:incorrectSize',...
                     'waveform''s data has to be same size as TraceData (%d vs %d',get(w,'data_length'), numel(obj.data));
                  obj.data = obj.data + get(B,'data'); 
               otherwise
                  error('TraceData:plus:unknownClass','do not know how to add a %s to a TraceData object', class(B));
            end
         end
      end
      
       
      function obj = minus(obj, B)
         % MINUS add something to the TraceData's data,
         %   This will return a TraceData object
         %
         %   valid combinations (let TD represent any TraceData object)
         %      TraceData - TraceData;  % as long as both have same data length and unit type
         %      TraceData - N; % where N is a column of numbers same length as td.data
         %      TraceData - Scalar;
         %
         % assume obj is the obj! Cannot subtract a TraceData from something
         if isnumeric(B)
            obj.data = obj.data - B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
         else
            switch class(B)
               case 'TraceData'
                  assert(numel(obj.data) == numel(B.data), 'TraceData:minus:incorrectSize', 'Both data fields need to be the same size');
                  assert(isempty(B.units) || strcmp(obj.units, B.units), 'TraceData:minus:missmatchedUnits', 'TraceData only subtracts items with the same units');
                  obj.data = obj.data - B.data;
               case 'waveform'
                  disp('mix and match of TraceData and waveform. Not really recommended');
                  assert(get(B,'data_length') == numel(obj.data), 'TraceData:minus:incorrectSize',...
                     'waveform''s data has to be same size as TraceData (%d vs %d',get(w,'data_length'), numel(obj.data));
                  obj.data = obj.data - get(B,'data'); 
               otherwise
                  error('TraceData:minus:unknownClass','do not know how to subtract a %s from a TraceData object', class(B));
            end
         end
      end
      
      function A = times(A,B)
         % TIMES element-by-element multiply TraceData with either a number or another TraceData
         %   A .* B or B .* A 
         if isnumeric(B)
            A.data = A.data .* B; % B should be either scalar or same size as obj.data
         elseif isnumeric(A)
            [A, B] = deal(B, A); % swap values
            A.data = A.data .* B;
         else
            if ~isa(A,'TraceData')
            [A, B] = deal(B, A); % swap values
            end
            switch class(B)
               case 'TraceData'
                  % multiply the elements of a Trace Data with the elements
                  % of another TraceData
                  assert(numel(A.data) == numel(B.data), 'TraceData:minus:incorrectSize', 'Both data fields need to be the same size');
                  A.data = A.data .* B.data;
                  if isempty(B.units)
                     % do no unit stuff
                  elseif isempty(A.units)
                     A.units = B.units;
                  else % multiplying units together
                     A.units = strcat(A.units, ' * ', B.units);
                  end
               otherwise
                  error('TraceData:minus:unknownClass','do not know how to multiply a %s with a TraceData object', class(B));
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

