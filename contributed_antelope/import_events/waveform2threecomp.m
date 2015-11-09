function eqtc=waveform2threecomp(eqwf,norigins,nstations,eqtimes)
%% Convert waveforms to threecomp objects where appropriate
% We've loaded all the waveforms.  Now convert the three-component sets
% into threecomp objects

fprintf(2,'Converting to threecomp objects if applicable...\n');

eqtc = cell(size(eqwf));
for no = 1:norigins
	for ns = 1:nstations
		if length(eqwf{no,ns}) == 3 % If it's three-compoenent
			try
				eqtc{no,ns} = threecomp(eqwf{no,ns},eqtimes(no,ns));
			catch me
				warning(['Error converting earthquake (' num2str(no) ',' num2str(ns) ') to threecomp object.  Leaving empty.']);
				eqtc{no,ns} = [];
			end
		else % If it's 1-component (or empty)...
			eqtc{no,ns} = eqwf{no,ns}; % ...store the original value
		end
	end
end