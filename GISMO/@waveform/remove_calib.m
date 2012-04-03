function w = remove_calib(w)
%WAVEFORM = REMOVE_CALIB(WAVEFORM) removes calibration factor
% which is automatically applied when reading waveforms from "wfdisc".
% The unit of output waveform will be in "COUNT"

% AUTHOR: Yun Wang
% $Date: 2010-02-16 14:55:19 -0900 (Tue, 16 Feb 2010) $
% $Revision: 204 $

% CHECK WAVEFORM
if ~strcmpi(class(w),'waveform')
    error('Waveform:remove_calib:missingWaveform',...
        'Input must be a waveform object');
end

nrec = length(w);
for i = 1:nrec
    if(strcmp(get(w(i),'CALIBRATION_APPLIED'),'YES'))
       calib = get(w(i),'CALIB');
       % w.CALIB unit is nm/sec/count if w is in nm/sec  
       w(i) = w(i)/calib;
       w(i) = set(w(i),'DATA',round(get(w(i),'DATA')));     % ensures integer values (counts)
       w(i) = addhistory(w(i),'Calibration removed');
       w(i) = delfield(w(i),'CALIBRATION_APPLIED');
       w(i) = delfield(w(i),'CALIB');
       w(i) = set(w(i),'UNITS','Counts');
    end
end
