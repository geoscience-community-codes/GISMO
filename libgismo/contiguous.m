function B = contiguous(A)
% CONTIGUOUS  find contiguous sequences in an input vector of integers
% B = contiguous(A)
% Take an input vector like i = [ 2 3 4 7 11 12 13 14 17 19 21] and
% return B.start = [2 11], B.end = [4 14]
% meaning that ranges 2:4 and 4:14 are contiguous in A


% using example:
% A      = [ 2  3  4  7 11 12 13 14 17 19 21]
% mask   = [ 0  1  1  0  0  1  1  1  0  0  0  0]
% starts = [ 1  0  0  0  1  0  0  0  0  0  0]
% ends   = [ 0  0  1  0  0  0  0  1  0  0  0]
% i(starts) = [2 11]
% i(ends)   = [4 14]

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% Vectorized by Celso Reyes

% forcing i into a column ensures this won't crash for rows OR columns.
mask = [false; diff(A(:))==1; false]; %true where i(N) == i(N-1)+1
starts = mask(1:end-1) < mask(2:end);
endIdx = mask(1:end-1) > mask(2:end);
B.start = A(starts);
B.end = A(endIdx);


% tests:
% v0 = [];
% v1= ([ 2 3 4 7 11 12 13 14 17 19 20])
% v2 = [0, v1, 0];
% contiguous([ 2 3 4 7 11 12 13 14 17 19 20])
% expectedStarts = [2 11 19];
% expectedEnds = [4 14 20];
% contiguous([ 0 2 3 4 7 11 12 13 14 17 19 20 22])
% SAME RESULTS.
