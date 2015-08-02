function [B,I,J] = unique(A)
%UNIQUE return set of unique scnlobjects from an array
% [B I J] = unique(scnlobjectList)
%   B is the unique (non duplicated) set of scnls
%   I is the index, such that B = A(I) and A = B(J)
% 
%
% see also UNIQUE
[B, I, J] = unique([A.tag]);
