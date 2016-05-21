function cmatrix=catmatrices(matrix2,matrix1);
% CATMATRICES - concatenate 2D matrices of arbitrary size
%    Sometimes it is rather tedious when reading in data
%    to work out how to concatenate matrices.
%    catmatrices is different to the inbuilt function cat,
%    in that it works out in what what the dimensions are
%    compatible, whereas cat expects the programmer to know.
%
%    Usage:
%      outmatrix=catmatrices(matrix2,matrix1);
%
%    INPUT:
%      matrix2         - the matrix to be appended
%      matrix1         - the primary matrix, to append matrix2 to
%
%    OUPUT:
%      cmatrix         - the concatenated matrix
%
%    See also cat

% AUTHOR: Glenn Thompson
% $Date$
% $Revision$

if size(matrix1)~=[0 0]
    s1=size(matrix1);
    s2=size(matrix2);
    if s1(1)==s2(1)
        cmatrix=[matrix1 matrix2];
    elseif s1(1)==s2(2)
        cmatrix=[matrix1 matrix2'];
    elseif s1(2)==s2(1)
        cmatrix=[matrix1;matrix2'];
    elseif s1(2)==s2(2)
        cmatrix=[matrix1;matrix2];
    else
	size(matrix2)
	size(matrix1)
        error('matrix dimensions are incompatible');

    end
else
    cmatrix=matrix2;
end

