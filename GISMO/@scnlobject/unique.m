function [B,I,J] = unique(A)
%UNIQUE return set of unique scnlobjects from an array
% [B I J] = unique(scnlobjectList)
%   B is the unique (non duplicated) set of scnls
%   I is the index, such that B = A(I) and A = B(J)
% 
%
% see also UNIQUE
scnlstrs = scnl2str(A);
[B I J] = unique(scnlstrs);
B = A(I);


function s = scnl2str(scnls)
ss = struct2cell(scnls);
pound_bounded = strcat([strcat(ss,'##')]);
s = cell(size(scnls));
for i=1:numel(scnls)
  s(i) = {strcat([pound_bounded{:,i}])};
end