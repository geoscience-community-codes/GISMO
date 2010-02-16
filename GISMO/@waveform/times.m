function A = times(A,B)
%TIMES (.*) overloaded Array multiply for WAVEFORM objects.
%     X.*Y denotes element-by-element multiplication.  X and Y
%     must have the same dimensions unless one is a scalar.
%     A scalar can be multiplied into anything.
%
%     C = TIMES(X,Y) is called for the syntax 'X .* Y' when either X or Y
%     is a waveform object.
%
%     if BOTH X and Y are waveforms, then the resulting waveform has the
%     properties of X.  Only individual waveforms can be multiplied
%     together.
%
%     examples.
%       Let W be an N-dimensional Waveform
%       C = W .* 10 % scale all W's data values by multiplying them by 10
%
%       Let Z be a waveform with the same # of data points as each W.
%       C = W .* Z; % scale each data point within each W by the 
%                   % corresponding data point within Z
%                   % The resulting waveforms (C) will have same properties
%                   % as original W, only scaled.
%
%       C = Z .* W; % Will error if numel(W) > 1  This is because of the
%                   % need to copy properties from Z.  
%                   %  1:1, many:1 - OK.
%                   %  1:many - NOT OK 
%
%       Let W be a 1x3 waveform, let
%       C = W .* [1 2 3] % does nothing to first waveform, but scales the
%                        % data within the second waveform by 2 and the
%                        % third waveform by 3
% See also MTIMES.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if ~isa(A,'waveform') %either A or B MUST be a waveform to get this far...
    D = A;
    A = B; %A is the waveform
    B = D; %B is either a waveform or numeric
    clear D
end

% at this point A is guarenteed to be a waveform, while B may be anything
hasSameArrayShape = all(size(A) == size(B));
elements_haveMatchingSize = ...
    all(get(A,'data_length') == numel(double(B)));


%%
% ----------------------------------------------------------------------- %
% Validation tests
% --------------------------
%
% factor checks
%   for a WAVEFORM factorB
%     must be scalar (1x1)
%     must have same data length as all factorA
%   for a NUMERIC factorB
%     must be scalar OR
%     must be same size (shape) as factorA OR
%     must have same data length as all factorA
%
% ----------------------------------------------------------------------- %


if isa(B,'waveform')
    if ~isscalar(B)
        error('Waveform:times:invalidFactorBSize',...
            ['The factor has too many elements.  '...
            'It must be single (1x1) waveform object'])
    else
        task = 'waveform_by_waveform';
    end
elseif isnumeric(B)
    if isscalar(B)
        task = 'waveform_by_scalar';
    elseif hasSameArrayShape
        task = 'waveforms_by_element';
    elseif elements_haveMatchingSize
        task = 'sample_by_sample';
    else
        if numel(A) == numel(B)
        error('Waveform:times:shapeMismatch',...
            'Factor dimensions do not match waveform dimensions');
        else
        error('Waveform:times:sizeMismatch',...
            'Number of factors (%d) are incompatable with the number of waveforms (%d)',...
            numel(B),numel(A));
        end
    end
else % divisor is of an unknown type
    error('Waveform:times:invalidDivisorClass',...
        'The factorB must be either numeric or a single waveform object');
end

% ----------------------------------------------------------------------- %
switch task
    case {'waveform_by_waveform', 'sample_by_sample'}
        for n = 1 : numel(A);
            A(n).data = A(n).data .* double(B(:)); %set(A(n), 'data', double(A(n)) .* double(B(:)));
        end
        if isempty(inputname(2))
            A = addhistory(A,'Multiplied by a constant <%s>', class(B));
        else
            A = addhistory(A,'Multiplied by "%s" <%s>',...
                inputname(2), class(B));
        end
    case 'waveforms_by_element'
        % each waveform has its own number to be multiplied by
        for n=1:numel(A)
            thisFactor = double(B(n));
            A(n).data = A(n).data .* thisFactor; % set(A(n),'data',double(A(n)) .* thisFactor );
            A(n) = addhistory(A(n),'Multiplied by %s', num2str(thisFactor));
        end
    case 'waveform_by_scalar'
        for n=1:numel(A)
            A(n).data = A(n).data .* B; % = set(A(n),'data',double(A(n)) .* B );
        end
        A = addhistory(A,'Multiplied by %s', num2str(B));
    otherwise
        error('Waveform:times:unknownoperation',...
            'A times operation was attempted that had no recognized task.');
end
