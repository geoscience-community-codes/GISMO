function w = plus(w,q)
%PLUS (+) waveform addition     w + q
%     w is an N-DIMENSIONAL waveform.
%     if q is a scalar, it is added to all data values of all waveforms
%     if q is a vector, it should be of same length as waveform's data
%     sample-by-sample added to each waveform
%     if q is waveform, data from w & q are added

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009

if ~isa(w,'waveform'),
    n  = w; w = q; q = n;
end
for n = 1:length(w)
    if isnumeric(q)
        % keep out characters and character arrays because they'd be
        % converted to their ascii equivelents.  Not good.
        %
        % other numeric types, such as int32  must be converted explicetly
        % to double before the action takes place.  Also, these must be in
        % the same shape as the data column (thus the "q(:)")
        w(n) = set(w(n), 'data', get(w(n),'data') + double(q(:))  );
        
        if isscalar(q)
            w(n) = addhistory(w(n),['added ' num2str(q)]);
        else
            w(n) = addhistory(w(n),'Added a vector "%s"', inputname(2));
        end


    elseif isa(q,'waveform')
        if  isscalar(q) && ( get(w(n),'data_length') == get(q,'data_length') )
            w(n) = set(w(n),'data', get(w(n),'data') + get(q,'data'));
            w = addhistory(w,['Added to another waveform ', inputname(2)]);
        else
            warning('Waveform:plus:invalidDataLengths',...
                'Invalid operation - data lengths are different or adding multiple waveforms');
        end;
    else
        error('Waveform:plus:invalidClass',...
          'unknown addition operation: %s + %s', class(w), class(q));
    end
end