function w = plus(w,q)
   %PLUS (+) waveform addition     w + q
   %     w is an N-DIMENSIONAL waveform.
   %     if q is a scalar, it is added to all data values of all waveforms
   %
   %     if q is numeric, and has the same size & shape as w, then each q is
   %     added to the appropriate w  ie.  result(n) = w(n) + q(n)
   %
   %     if q is a vector, it should be of the same length as the number of
   %     samples within the waveform.  It will be added sample-by-sample added
   %     to each waveform.
   %
   %     if q is waveform, data values from w & q are added together, assuming
   %     that each has the same number of samples.
   %
   % See also: plus, wavform/plus, fix_data_length
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   % CODE WARNING:
   % ASSUMES DATA is in w.data and is in a single column. MAY bypass GET & SET
   % for speed.
   if ~isa(w,'waveform'),
      n  = w; w = q; q = n;
      clear n
   end
   
   array_addition = all(size(w) == size(q));
   scalar_addition = isscalar(q);
   element_addition = isvector(q) && all(get(w(:),'data_length') == numel(q));
   
   for n = 1:numel(w)
      if isnumeric(q)
         % keep out characters and character arrays because they'd be
         % converted to their ascii equivelents.  Not good.
         %
         % other numeric types, such as int32  must be converted explicetly
         % to double before the action takes place.  Also, these must be in
         % the same shape as the data column (thus the "q(:)")
         
         
         if scalar_addition
            w(n).data = w(n).data + double(q);
         elseif array_addition
            w(n).data = w(n).data + double(q(n));
         elseif element_addition
            w(n).data = w(n).data + double(q(:));
         else
            if all(size(w) == size(q'))
               error('Waveform:plus:sizeMismatch',...
                  ['error in dimensions: [NxM] + [MxN].\nOne possible'...
                  ' fix would be to transpose ('') one of the addends '])
            else
               wsize = num2str(size(w),'%dx'); wsize = wsize(1:end-1);
               qsize = num2str(size(q),'%dx'); qsize = qsize(1:end-1);
               error('Waveform:plus:unknownOperation',...
                  ['unknown waveform addition operation:\n',...
                  '< %s %s>  + <%s %s>'],wsize, class(w), qsize, class(q));
            end
         end
         
         
      elseif isa(q,'waveform')
         if  isscalar(q) && ( numel(w(n).data) == numel(q.data) )
            w(n).data = w(n).data + q.data;
         else
            error('Waveform:plus:invalidDataLengths',...
               'Invalid operation - data lengths are different or adding multiple waveforms');
         end;
      else
         error('Waveform:plus:invalidClass',...
            'unknown addition operation: %s + %s', class(w), class(q));
      end
   end
end