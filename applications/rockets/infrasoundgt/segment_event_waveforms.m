function wevent = segment_event_waveforms(w, cobj, pretrigger, posttrigger, arrivalTimeCorrection)
%SEGMENT_EVENT_WAVEFORMS take a continuous vector of waveforms, and based
% arrival times in the infrasoundEvent vector, generate a cell vector where
% each element is a waveform vector extracted around the arrival times
% given
% Usage:
%     wevent = segment_event_waveforms(w, infrasoundEvent, pretrigger,
%                                      posttrigger,arrivalTimeCorrection)
% pretrigger and posttrigger are in seconds (e.g. 1)
if ~exist('arrivalTimeCorrection','var')
    arrivalTimeCorrection = 0.0;
end
disp('Segmenting event waveforms...')
numEvents = numel(infrasoundEvent);
for eventNumber=1:numEvents
    fprintf('- segmenting infrasound event %d of %d\n',eventNumber,numEvents );
    time1 = infrasoundEvent(eventNumber).FirstArrivalTime-pretrigger/86400-arrivalTimeCorrection/86400;
%     if arrivalTimeCorrection==0.0
%         time2 = infrasoundEvent(eventNumber).LastArrivalTime+posttrigger/86400-arrivalTimeCorrection/86400;
%     else
        time2 = infrasoundEvent(eventNumber).FirstArrivalTime+posttrigger/86400-arrivalTimeCorrection/86400;
%     end
    w2 = detrend(extract(w, 'time', time1, time2));
    wevent{eventNumber} = w2;
    clear w2
end
