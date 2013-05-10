function [ result ] = eq( w1, w2 )
%EQ Check if waveform objects are equal
%   result = eq(w1, w2)
%   Check the scnl, start and end times, and data in two waveform objects

% Author: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: $
% $Revision: $



result = false;
if strcmp(get(w1, 'station'), get(w2, 'station'))
    if strcmp(get(w1, 'channel'), get(w2, 'channel'))
        if (get(w1,'timevector') == get(w2,'timevector'))
            if (get(w1, 'data') == get(w2, 'data'))
                result = true;
            end
        end
    end
end


