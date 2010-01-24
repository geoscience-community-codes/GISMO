function val = get(f, prop_name)
%GET - Get filterobject properties
%   out = Get(f,prop_name)
%   Valid property names:
%       type, cutoff, poles
%   
%   If n-dimensional filterobjects used, then output is an n-dimensional
%   cell.
%
%
%  See also FILTEROBJECT/GET

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

val = cell(size(f));

for N = 1 : numel(val)

    switch upper(prop_name)
        case 'TYPE'
            val{N} = f(N).type;
        case 'CUTOFF'
            val{N} = f(N).cutoff;
        case 'POLES'
            val{N} = f(N).poles;
        otherwise
            warning(['Unrecognized property : ' prop_name ]);
    end
end
if numel(f) == 1
    val = val{1}; % return the actual value, not a cell array
end