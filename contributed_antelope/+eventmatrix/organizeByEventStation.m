function [EQWF, meta] = organizeByEventStation(arr, stations)
%EVENTMATRIX.ORGANIZEBYEVENTSTATION
% Build event × station waveform matrix from Arrival object

orids = unique(arr.orid);
nstations = numel(stations);
norigins  = numel(orids);

EQWF = cell(norigins, nstations);

meta.stations = stations;
meta.orids    = orids;
meta.otimes   = NaN(norigins,1);

for i = 1:norigins
    idx = arr.orid == orids(i);
    thisArr = arr.subset(find(idx));

    meta.otimes(i) = min(thisArr.time);

    for j = 1:nstations
        sta = stations{j};
        jdx = strcmp(thisArr.station, sta);

        if any(jdx)
            EQWF{i,j} = thisArr.waveforms(find(jdx,1));
        end
    end
end
end