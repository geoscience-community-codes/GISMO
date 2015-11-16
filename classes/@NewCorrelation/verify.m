function c = verify(c)

%VERIFY
%   C = VERIFY(C) checks the length of waveforms in a correlation object
%   and adjusts them if they are not equal. Traces ends are trimmed or
%   zero-padded to the mode length of all traces.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


lengths = get(c.W,'DATA_LENGTH');
ideal = mode(lengths);
f = find(lengths~=ideal);

for i = f'
	if (lengths(i)>ideal)
		c.W(i) = extract(c.W(i),'INDEX',1,ideal);
	elseif (lengths(i)<ideal)
		d = get(c.W(i),'DATA');
		wtmp = zeros(ideal,1);
		wtmp(1:length(d)) = d;
		c.W(i) = set(c.W(i),'DATA',wtmp);
	end
end

