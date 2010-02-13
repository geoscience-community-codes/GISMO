function W = rdivide(W,divisor)
%RDIVIDE (./) Right array divide for WAVEFORMS.
%     W./B denotes element-by-element division for waveform objects.
%     W./B scales the data in waveform(s) W by dividing them by value(s) B
%     The dividend (W) Must be one or more waveforms.  The divisor may be
%     a scalar, a numeric array of the same size & shape as W, or a
%     waveform with the same number of data values as W.
%
%     If the divisor is a scalar, the resulting waveform(s) have all had
%     their data scaled by dividing by the divisor.
%
%     If the divisor is an array, then it must be of the same size as W.
%     The data within each element of W will be divided by the
%     corresponding element of divisor.
%       i.e. for each element(n) of W , C(n) = W(n) ./ B(n)
%
%     If divisor is another waveform, each sample in W is divided by the
%     corresponding sample in divisor.
%        divisor & W must have the same # of data points.
%
%     C = RDIVIDE(A,B) is called for the syntax 'W ./ B' when A
%     or B is a waveform object.
%
%     The returned values are waveforms of the same size as W
%
%     examples.
%       C = W ./ 10 % scale all data values within W by dividing them by 10
%
%       Let W be a 1x3 waveform, let
%       C = W ./ [1 2 3] % does nothing to first waveform, but scales the
%                        % data within the second waveform by 1/2 and the
%                        % third waveform by 1/3
%
%       C = W ./ max(abs(W)); % scale all waveforms to have
%                             % values between -1 and 1.
%
%       Let Z be a waveform with the same # of elements as W.
%       C = W ./ Z; % scale each data point within W by the corresponding
%                   % data point within Z
%
% See also RDIVIDE, LDIVIDE, MLDIVIDE, MRDIVIDE.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% ----------------------------------------------------------------------- %
% Validation tests
% --------------------------
%
% dividend check
%   must be a waveform
%
% divisor checks
%   for a WAVEFORM divisor
%     must be scalar (1x1)
%     must have same data length as all dividends
%   for a NUMERIC divisor
%     must be scalar OR
%     must be same size (shape) as dividend OR
%     must have same data length as all dividends
%
% ----------------------------------------------------------------------- %

% Logical variables used in validating the RDIVIDE operation

hasOneDivisorPerDividend = all(size(W) == size(divisor));
elements_haveMatchingSize = ...
    all(get(W,'data_length') == numel(double(divisor)));
%-----------------------------------------------------------%

if ~isa(W,'waveform');
    error('Waveform:rdivide:invalidDividendClass',...
        'The dividend must be a waveform object');
end

if isa(divisor,'waveform')
    if ~isscalar(divisor)
        error('Waveform:rdivide:invalidDivisorSize',...
            ['The divisor has too many elements.  '...
            'It must be single (1x1) waveform object'])
    else
        task = 'waveform_by_waveform';
    end
elseif isnumeric(divisor)
    if isscalar(divisor)
        task = 'waveform_by_scalar';
    elseif hasOneDivisorPerDividend
        task = 'waveforms_by_element';
    elseif elements_haveMatchingSize
        task = 'sample_by_sample';
    else
        error('Waveform:rdivide:sizeMismatch',...
            'Number of waveforms are incompatable with the number of divisors');
    end
else % divisor is of an unknown type
    error('Waveform:rdivide:invalidDivisorClass',...
        'The divisor must be either numeric or a single waveform object');
end

% ----------------------------------------------------------------------- %
switch task
    case {'waveform_by_waveform', 'sample_by_sample'}
        for n = 1 : numel(W);
            W(n).data = W(n).data ./ double(divisor(:));
        end
        if isempty(inputname(2))
            W = addhistory(W,'Divided by a constant <%s>', class(divisor));
        else
            W = addhistory(W,'Divided by "%s" <%s>',...
                inputname(2), class(divisor));
        end
    case 'waveforms_by_element'
        % each waveform has its own number to be divided by
        for n=1:numel(W)
            thisDivisor = double(divisor(n));
            W(n) = set(W(n),'data',W(n).data ./ thisDivisor );
            W(n) = addhistory(W(n),'Divided by %s', num2str(thisDivisor));
        end
    case 'waveform_by_scalar'
        for n=1:numel(W)
            W(n) = set(W(n),'data', W(n).data ./ double(divisor) );
            W(n) = addhistory(W(n),'Divided by %s', num2str(divisor));
        end
    otherwise
        error('Waveform:rdivide:unknownoperation',...
            'A rdivide operation was attempted that had no recognized task.');
end