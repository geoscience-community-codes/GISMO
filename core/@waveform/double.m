function n = double(W, option)
   %DOUBLE returns a waveform's data as a double type
   %   N = double(waveform  [, option] )
   %   this is just a fancy way of saying get(W,'data')
   %   but can handle vectors of W. The data lengths of the vectors do not
   %   need to be the same.  By default it will zero-pad the end of all short
   %   vectors.  Using the OPTION, you can specify a NaN padding instead.
   %
   %   Input Arguments
   %       WAVEFORM: a waveform object   assumed as 1xN DIMENSIONAL
   %               (If not, it will be treated as though it were 1xN!)
   %       OPTION: Handle to any function that creates an array of a
   %               dictated size.  The chosen function should work like:
   %               A = (nRows,nCols); and return a double array of the
   %               appropriate size. ex. @ones, @zeros, @nan.
   %
   %   Output Arguments
   %       N: the columns of data
   %
   %   example:
   %       % let W(1) be a waveform with data [0 1 2 5 3]
   %       % let W(2) be a waveform with data [2 5]
   %
   %       Y = double(W);
   %       % Y is now [[ 0 2; 1 5; 2 0; 5 0; 3 0]
   %
   %       Z = double(W,@nan); pads with NaN instead of zeros
   %       % Z is now [ 0 2; 1 5; 2 NaN; 5 NaN; 3 NaN]
   %
   % See also WAVEFORM/GET, NAN
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   if numel(W) <= 1
      n = W.data; %  assumption --> data is already a column of double!
      return
   end
   
   if nargin == 1
      createDefaultArray = @zeros;
   else
      if ischar(option)
         createDefaultArray = str2func(option);
      elseif isa(option,'function_handle')
         createDefaultArray = option;
      else
         error('waveform:double:invalidOption',...
            '''option'' must be either a function handle or function name.');
      end
   end
   
   m = get(W,'data_length');
   if isempty(m)
      n = [];
      return
   end
   
   m=m(:);
   if all(m == m(1))
      n = [W(:).data]; % easy-peazy since all data is of same length.
   else
      n = createDefaultArray(max(m),numel(W));
      for x=1:numel(W)
         n(1:m(x),x) = W(x).data; % assumes that data is a column of double!
      end
   end
end