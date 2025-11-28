function C = catmatrices(A, B)
% CATMATRICES  Concatenate two matrices using matching dimensions
%
%   C = CATMATRICES(A,B) concatenates A and B along the dimension that
%   matches automatically:
%
%   • If size(A,1) == size(B,1) → horizontal concat   [A B]
%   • If size(A,2) == size(B,2) → vertical concat     [A; B]
%   • If size(A,1) == size(B,2) → horizontal with B'  [A B']
%   • If size(A,2) == size(B,1) → vertical with B'    [A; B']
%
%   This is intended for dynamically growing matrices when orientation
%   is not known in advance (e.g., streaming waveform features).
%
%   Glenn Thompson
%
%   See also: CAT, HORZCAT, VERTCAT, rsam/read_bob_file, rsam/load 

    % Handle empty primary matrix
    if isempty(A)
        C = B;
        return
    end

    sA = size(A);
    sB = size(B);

    if sA(1) == sB(1)
        % Same number of rows → horizontal concat
        C = [A B];

    elseif sA(2) == sB(2)
        % Same number of columns → vertical concat
        C = [A; B];

    elseif sA(1) == sB(2)
        % Transposed B matches rows
        C = [A B'];

    elseif sA(2) == sB(1)
        % Transposed B matches columns
        C = [A; B'];

    else
        error('smartcat:DimensionMismatch', ...
            'Cannot concatenate: size(A) = [%d %d], size(B) = [%d %d]', ...
            sA(1), sA(2), sB(1), sB(2));
    end
end

