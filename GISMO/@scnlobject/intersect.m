function [ref_A, ref_B] = intersect(scnlA,scnlB)

% intersect: Find the intersection between two SCNL objects. Returns only
% the references to intersecting (identical) SCNL.
%  
%  USAGE: [ref_A, ref_B] = intersect(scnlA,scnlB)
%  
%  INPUTS: scnlA - first SCNL object
%          scnlB - second SCNL object
%                           
%  OUTPUTS: ref_A - references to members of first SCNL object
%           ref_B - references to members of second SCNL object

% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

ref_A = [];
ref_B = [];

for n = 1:numel(scnlA)
    sA = strtrim(get(scnlA,'station'));
    if ~iscell(sA), sA = {sA}; end
    cA = strtrim(get(scnlA,'channel'));
    if ~iscell(cA), cA = {cA}; end
    nA = strtrim(get(scnlA,'network'));
    if ~iscell(nA), nA = {nA}; end
    for m = 1:numel(scnlB)
        sB = strtrim(get(scnlB,'station'));
        if ~iscell(sB), sB = {sB}; end
        cB = strtrim(get(scnlB,'channel'));
        if ~iscell(cB), cB = {cB}; end
        nB = strtrim(get(scnlB,'network'));
        if ~iscell(nB), nB = {nB}; end
        if strcmpi(sA{n},sB{m}) && ...
           strcmpi(cA{n},cB{m}) && ...
           strcmpi(nA{n},nB{m})
              ref_A = [ref_A, n];
              ref_B = [ref_B, m];
        end
    end
end
