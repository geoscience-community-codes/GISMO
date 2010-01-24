function C = times(A,B)
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
% See also MTIMES.

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/6/2007


if ~isa(A,'waveform') %either A or B MUST be a waveform to get this far...
    D = A;
    A = B; %A is the waveform
    B = D; %B is either a waveform or numeric
    clear D
end

C = A;


for n = 1 : numel(A)
    % the following syntax guarentees B is a double.
    if isnumeric(B) || isa(B,'waveform'),
        if ~isscalar(B) && (numel(double(B(:))) ~= get(A(n),'data_length'))
            error('waveform''s sample count must match the length of numeric vector it is multiplied by.');
        end
        C(n) = set(A(n), 'data', get(A(n),'data') .* double(B(:)) );

        if isa(B,'waveform') 
            C(n) = addhistory(C(n),'multiplied by a waveform %s', inputname(2));
        else
            if ~isscalar(B),
                C(n) = addhistory(C(n),'multiplied by vector %s', inputname(2));
            else
                C(n) = addhistory(C(n),'multiplied by %s', num2str(B));
            end
        end
    else
        error('Must multiply by a numeric type or a waveform, not a %s',class(B));
    end
end