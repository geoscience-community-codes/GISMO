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
      freq
      units
   end
   
   properties(Hidden=true)
      % when trust_assignments is false, then data
      trust_assignments = false; % if not trusted, then slows down computations somewhat, but is useful for debugging. 
      debug_level
   end
   
   methods
      
      
      
      function obj = set.data(obj, values)
         % set.data ensures that data is always stored in a column
            obj.data = values(:);
      end
      %% Mathamatical - BASIC
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
                  assert(abs(A.freq - B.freq) < (min(A.freq, B.freq) / 100),...
                     'TraceData:plus:incompatibleFrequencies','Frequencies should be the same');
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
       
      function A = minus(A, B)
         % MINUS add something to the TraceData's data,
         %   This will return a TraceData object
         %
         %   valid combinations (let TD represent any TraceData object)
         %      TraceData - TraceData;  % as long as both have same data length and unit type
         %      TraceData - N; % where N is a column of numbers same length as td.data
         %      TraceData - Scalar;
         %
         % Cannot subtract a TraceData from something other than another TraceData
         
         if isnumeric(B) 
            % A is guaranteed to be a TraceData
            A.data = A.data - B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
         else
            assert(isa(A,'TraceData'),'TraceData:minus:invalidSubtraction',...
               'in A - B, B cannot be a TraceData object unless both A & B are TraceData objects');
            switch class(B)
               case 'TraceData'
                  assert(numel(A.data) == numel(B.data), 'TraceData:minus:incorrectSize', 'Both data fields need to be the same size');
                  assert(isempty(B.units) || strcmp(A.units, B.units), 'TraceData:minus:missmatchedUnits', 'TraceData only subtracts items with the same units');
                  assert(abs(A.freq - B.freq) < (min(A.freq, B.freq) / 100),...
                     'TraceData:plus:incompatibleFrequencies','Frequencies should be the same')
                  A.data = A.data - B.data;
               case 'waveform'
                  disp('mix and match of TraceData and waveform. Not really recommended');
                  assert(get(B,'data_length') == numel(A.data), 'TraceData:minus:incorrectSize',...
                     'waveform''s data has to be same size as TraceData (%d vs %d',get(w,'data_length'), numel(A.data));
                  A.data = A.data - get(B,'data'); 
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
                  assert(abs(A.freq - B.freq) < (min(A.freq, B.freq) / 100),...
                     'TraceData:plus:incompatibleFrequencies','Frequencies should be the same')
                  A.data = A.data .* B.data;
                  if isempty(B.units)
                     % do no unit stuff
                  elseif isempty(A.units)
                     A.units = B.units;
                  else % multiplying units together
                     A.units = [A.units, ' * ', B.units];
                  end
               otherwise
                  error('TraceData:minus:unknownClass','do not know how to multiply a %s with a TraceData object', class(B));
            end
         end
      end
      
      function A = mtimes(A, B)
         error('uimplemented mtimes');
      end
      
      function A = rdivide(A, B)
         % rdivide elementwise division A ./ B
         % A must be a TraceData object
         % B can be:
         %   numeric   (scalar or vector same size as A.data)
         %   TraceData (note: also the units will be affected)
         
         if isnumeric(B) 
            % A is guaranteed to be a TraceData
            A.data = A.data ./ B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
         else
            assert(isa(A,'TraceData'),'TraceData:rdivide:invalidSubtraction',...
               'in A ./ B, B cannot be a TraceData object unless both A & B are TraceData objects');
            switch class(B)
               case 'TraceData'
                  assert(numel(A.data) == numel(B.data), 'TraceData:rdivide:incorrectSize', 'Both data fields need to be the same size');
                  assert(abs(A.freq - B.freq) < (min(A.freq, B.freq) / 100),...
                     'TraceData:plus:incompatibleFrequencies','Frequencies should be the same')
                  A.data = A.data ./ B.data;
                  if isempty(B.units)
                     % do no unit stuff
                  elseif isempty(A.units)
                     A.units = B.units;
                  else % multiplying units together
                     A.units = [A.units, ' / (', B.units, ')'];
                  end
               case 'waveform'
                  disp('mix and match of TraceData and waveform. Not really recommended');
                  assert(get(B,'data_length') == numel(A.data), 'TraceData:rdivide:incorrectSize',...
                     'waveform''s data has to be same size as TraceData (%d vs %d', get(w,'data_length'), numel(A.data));
                  A.data = A.data ./ get(B,'data'); 
               otherwise
                  error('TraceData:rdivide:unknownClass','do not know how to divide a %s from a TraceData object', class(B));
            end
         end
      end
      
      function A = uminus(A)
         A.data = -A.data;
      end
     
      function A = abs(A)
         A.data = abs(A.data);
         A.units = ['abs (', A.units, ')'];
      end
      
      function A = sign(A)
         A.data = sign(A.data);
         A.units = ['sign(', A.units, ')'];
      end
               
      %% more complicated 
      function A = diff(A, varargin)
         % FREQUENCY is not considered!
         % otherwise, would be X = diff(X) .* Freq
         if isempty(varargin)
            A.data = diff(A).data .* A.freq;
            A.data = diff(A.data);
         else
            error('not implemented yet');
         end
         % deal with units
         %{
         % swiped directly from waveform, needs editing.
         tempUnits = allUnits{I};
      whereInUnits = strfind(tempUnits,' * sec');
      if isempty(whereInUnits)
         w(I) = set(w(I),'units', [tempUnits, ' / sec']);
      else
         tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
         w(I) = set(w(I),'units',tempUnits);
      end
         %}
      end
      
      function A = integrate(A, method)
         error('not implemented yet');
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

