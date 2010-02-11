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
        sprintf('  for a waveform result, try:  -<waveform> + <%s>\n',class(w)),...
        sprintf('\t and don''t forget to modify the waveform''s history if appropriate\n')];
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

% %% below is previous implementation of minus
% for n=1: numel(w)
%     if isnumeric(q)
%         % keep out characters and character arrays because they'd be
%         % converted to their ascii equivelents.  Not good.
%         %
%         % other numeric types, such as int32  must be converted explicetly
%         % to double before the action takes place.  Also, these must be in
%         % the same shape as the data column (thus the "q(:)")
%         w(n) = set(w(n), 'data', get(w(n),'data') - double(q(:))  );
%
%         if isscalar(q)
%             w(n) = addhistory(w(n),['Subtracted ' num2str(q)]);
%         else
%             w(n) = addhistory(w(n),'Subtracted a vector "%s"', inputname(2));
%         end
%
%     elseif isa(q,'waveform')
%         if  isscalar(q) && ( get(w(n),'data_length') == get(q,'data_length') )
%             w(n) = set(w(n),'data', get(w(n),'data') - get(q,'data'));
%             w = addhistory(w,['Subtracted by another waveform ', inputname(2)]);
%         else
%             warning('Waveform:minus:invalidDataLengths',...
%                 'Invalid operation - data lengths are different or subtracting multiple waveforms');
%         end;
%     else
%         error('Waveform:minus:invalidClass',...
%           'unknown subtraction operation: "%s - %s"',class(w),class(q));
%     end;
% end