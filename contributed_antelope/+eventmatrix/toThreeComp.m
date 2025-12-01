function EQTC = toThreeComp(EQWF, meta)
%EVENTMATRIX.TOTHREECOMP Convert 3-channel waveforms to threecomp

[norigins, nstations] = size(EQWF);
EQTC = cell(size(EQWF));

for i = 1:norigins
    for j = 1:nstations
        w = EQWF{i,j};

        if isempty(w)
            EQTC{i,j} = [];
            continue;
        end

        if numel(w) == 3
            try
                EQTC{i,j} = threecomp(w, meta.otimes(i));
            catch
                EQTC{i,j} = [];
            end
        else
            EQTC{i,j} = w;
        end
    end
end
end