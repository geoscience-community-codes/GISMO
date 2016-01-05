function w = minus(w,q)
   %MINUS (-) Overloaded waveform subtraction    w - q
   %   w is an N-DIMENSIONAL waveform.
   %   if q is 1x1, it is subtracted from all data values of all waveforms
   %
   %   if q is numeric, and has the same size & shape as w, then each q is
   %     subtracted from the appropriate w  ie.  result(n) = w(n) + q(n)
   %
   %   if q is a vector, it should be of same length as waveform's data
   %     sample-by-sample subtracted from each waveform
   %
   %   if q is waveform, data from q are subtracted from w, assuming both
   %   waveforms have the same number of samples
   %
   %   If q is numeric, and w is of type waveform, then the operation
   %   q - w is invalid.  This is because of a possible ambiguous result type.
   %   Instead:
   %       for a numeric result, use the synatax:
   %              q  - double(w)
   %       for a waveform result, use the syntax:
   %              q + -w             or              -w + q
   %
   % See also: minus, wavform/plus, uminus, fix_data_length
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   if ~isa(w,'waveform')
      %yipes.  we have a number minus a waveform
      errtext = [sprintf('subtracting a <waveform> from a <%s> leads to ambiguous answer type\n',class(w)), ...
         sprintf('  for a numerical result, try: <%s> - double(<waveform>)\n',class(w)), ...
         sprintf('  for a waveform result, try:  -<waveform> + <%s>\n',class(w))];
      error('Waveform:minus:invalidClass','Error attempting: <%s> - <%s>\n%s', class(w),class(q),errtext);
   end
   try
      w = w + (-q);
   catch caughtvalue
      %NOTE, it is important to keep this section in sync with waveform/plus
      switch caughtvalue.identifier
         case 'Waveform:plus:unknownOperation'
            wsize = num2str(size(w),'%dx'); wsize = wsize(1:end-1);
            qsize = num2str(size(q),'%dx'); qsize = qsize(1:end-1);
            error('Waveform:minus:unknownOperation',...
               ['unknown waveform subtraction operation:\n',...
               '< %s %s>  - <%s %s>'],wsize, class(w), qsize, class(q));
         case 'Waveform:plus:sizeMismatch'
            error('Waveform:minus:sizeMismatch',...
               ['error in dimensions: [NxM] - [MxN].\nOne possible'...
               ' fix would be to transpose ('') one of the terms '])
         case 'Waveform:plus:invalidClass'
            error('Waveform:minus:invalidClass',...
               'unknown subtraction operation: %s - %s', class(w), class(q));
         otherwise
            rethrow(caughtvalue);
      end
   end
   return;
end
