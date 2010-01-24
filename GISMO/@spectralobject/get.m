function out = get(s, prop_name)
%GET - Get properties for spectralobject
%   value = Get(s,prop_name)
%   Valid property names:
%   nfft, over, dBlims, freqmax
%
%   If N-dimensional spectralobject used, then output is an N-dimensional
%   cell.
%
%  See also SPECTRALOBJECT/SET

% VERSION: 1.1 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 6/20/2007

switch upper(prop_name)
    case {'DBLIMS'}
        out = cell(size(s));
    otherwise
        out = NaN(size(s));
end

for N = 1 : numel(s)
    switch upper(prop_name)
        case 'NFFT'
            
            out(N) = [s(N).nfft];
        case {'OVER', 'OVERLAP'}
            out(N) = [s(N).over];
        case 'DBLIMS'
            out(N) = {s(N).dBlims};
        case 'FREQMAX'
            out(N) = [s(N).freqmax];
        case 'SCALING'
            out{N} = {s(N).scaling};
        otherwise
            warning(['unrecognized property name...' upper(prop_name)]);
            out = {[]};
    end;
end

if numel(s) == 1 && iscell(out)
    out = out{1}; % return the actual value, not a cell array
end

%% changelog
%{
6/20/2007 fixed issue with cells 
%}