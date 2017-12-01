function masterEvent = make_master_event(infrasoundEvent)
%% Construct a master infrasound event, from all the individual ones
disp('Constructing master infrasound event from individual event statistics')
masterEvent.FirstArrivalTime = infrasoundEvent(1).FirstArrivalTime;
masterEvent.LastArrivalTime = infrasoundEvent(1).LastArrivalTime;

% find the mean xcorr time lag difference for non-identical infrasound components - it should be close to zero if only one event in time window
% e.g. needle 1 and haystack 2 should have same magnitude but opposite sign
% time delay to needle 2 and haystack 1 if there is only one clear N wave
% in the haystacks
disp('- finding events with a mean time lag difference of close to 0 - these are the events we can use')
indexes = find(abs([infrasoundEvent.meanSecsDiff]) < 0.01); % these are events with probably only one event in wevent time window
fprintf('- found %d events we can use\n', numel(indexes));
disp('- event indexes to use');
disp(indexes)

masterEvent.secsDiff = zeros(3,3);
masterEvent.stdSecsDiff = zeros(3,3);
for row=1:3
    for column=1:3
        a = [];
        for eventNumber = indexes
            thisEvent = infrasoundEvent(eventNumber);
            a = [a thisEvent.secsDiff(row, column)];
        end
        
%         % eliminate any events which have a difference from the mean of
%         % greater than the standard deviation
%         diffa = abs( (a-mean(a))/std(a) );
%         
%         % now set the mean and std for the master event
%         masterEvent.secsDiff(row, column) = mean(a(diffa<1.0));
%         masterEvent.stdSecsDiff(row, column) = std(a(diffa<1.0));
        
        masterEvent.secsDiff(row, column) = mean(a);
        masterEvent.stdSecsDiff(row, column) = std(a);
    end
end
disp('  - mean:');
disp(masterEvent.secsDiff)
disp('  - std:')
disp(masterEvent.stdSecsDiff)
disp('  - fractional std:')
disp(masterEvent.stdSecsDiff ./ masterEvent.secsDiff)