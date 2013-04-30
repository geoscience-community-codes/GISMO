function j = contiguous(i);
% CONTIGUOUS find contiguous sequences in an input vector of integers
% j = contiguous(i)
% Take an input vector like i = [ 2 3 4 7 11 12 13 14 17 19 21] and
% return j.start = [2 11], j.end = [4 14]
% meaning that ranges 2:4 and 4:14 are contiguous in i

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$

sequenceOn = false;
sequenceNum = 0;
j.start=[];
j.end=[];
for c=2:length(i)
    if i(c) == i(c-1) + 1
        if ~sequenceOn
            sequenceOn = true;
            sequenceNum = sequenceNum + 1;
            j.start(sequenceNum) = i(c-1);
        else
            j.end(sequenceNum) = i(c);
        end
    else
        if sequenceOn
            sequenceOn = false;
            j.end(sequenceNum) = i(c-1);
        end
    end
end
    
        
    
