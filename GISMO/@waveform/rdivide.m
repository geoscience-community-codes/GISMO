function W = rdivide(W,B)
%RDIVIDE (./) Right array divide for WAVEFORMS.
%     W./B denotes element-by-element division.  A and B
%     must have the same dimensions unless one is a scalar.
%     A scalar can be divided with anything.
%
%     C = RDIVIDE(A,B) is called for the syntax 'W ./ B' when A or B is an
%     object.
%
% See also LDIVIDE, MLDIVIDE, MRDIVIDE.

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009

if ~isa(W,'waveform')
    error('Waveform:rdivide:invalidDividendClass',...
      'The dividend must be a waveform object');
end

if ~(isnumeric(B) || isa(B,'waveform'))
    error('Waveform:rdivide:invalidDivisorClass',...
      'The divisor must be either numeric or a single waveform object');
end

if isa(B,'waveform') && (~isscalar(B))
    error('Waveform:rdivide:invalidDivisorSize',...
      'The divisor may only be single waveform, not %s',num2str(size(B)));
end

for n = 1 : numel(W);
    if isa(B,'waveform') %jiggle to get matrix dimensions correct
        W(n) = set(W(n), 'data', get(W(n),'data') ./ double(B));
    else
        W(n) = set(W(n), 'data', double(W(n)) ./ double(B));
    end
end
if isscalar(B) && (~isa(B,'waveform'))
    W = addhistory(W,'Divided by %s', num2str(B));
else
    W = addhistory(W,'Divided by "%s" <%s>',inputname(2), class(B));
end