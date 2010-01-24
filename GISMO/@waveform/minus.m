function w = minus(w,q)
%MINUS (-) Overloaded waveform subtraction    w - q
%   w is a waveform.
%   if q is a scalar, it is subtracted from all data values
%   if q is a vector, it should be of same length as P's data, and is
%   sample-by-sample subtracted from w
%   if q is waveform, data from q is subtracted from w assuming lengths are
%   the same

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009

if ~isa(w,'waveform')
    %yipes.  we have a number minus a waveform
    fprintf('"<%s> - <waveform>" makes no sense (ambiguous answer type)\n',class(w));  
    fprintf('for a numerical answer, try "%s - double(waveform)"\n',class(w));  
    fprintf('for a waveform answer, try:\n');
    fprintf('\t"waveform = set(waveform,''data'', %s - double(waveform))"\n',class(w));  
    fprintf('\t and don''t forget to modify the waveform''s history if appropriate\n');
    error('Waveform:minus:invalidClass','%s - %s',class(w),class(q));
end
for n=1: numel(w)
    if isnumeric(q)
        % keep out characters and character arrays because they'd be
        % converted to their ascii equivelents.  Not good.
        %
        % other numeric types, such as int32  must be converted explicetly
        % to double before the action takes place.  Also, these must be in
        % the same shape as the data column (thus the "q(:)")
        w(n) = set(w(n), 'data', get(w(n),'data') - double(q(:))  );
  
        if isscalar(q)
            w(n) = addhistory(w(n),['Subtracted ' num2str(q)]);
        else
            w(n) = addhistory(w(n),'Subtracted a vector "%s"', inputname(2));
        end

    elseif isa(q,'waveform')
        if  isscalar(q) && ( get(w(n),'data_length') == get(q,'data_length') )
            w(n) = set(w(n),'data', get(w(n),'data') - get(q,'data'));
            w = addhistory(w,['Subtracted by another waveform ', inputname(2)]);
        else
            warning('Waveform:minus:invalidDataLengths',...
                'Invalid operation - data lengths are different or subtracting multiple waveforms');
        end;
    else
        error('Waveform:minus:invalidClass',...
          'unknown subtraction operation: "%s - %s"',class(w),class(q));
    end;
end