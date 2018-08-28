function infrasoundEventOut = auto_measure_amplitudes(infrasoundEvent, wevent, titleStr, predicted_traveltime_seconds, figureOutDirectory)
numEvents = numel(infrasoundEvent);
close all
min_traveltime = min(predicted_traveltime_seconds);
relative_traveltimes = predicted_traveltime_seconds - min_traveltime;
infrasoundEventOut = [];
for eventNumber=1:numEvents
    thisEvent = infrasoundEvent(eventNumber);
    thisW=wevent{eventNumber};
    
    thisEvent = auto_measure_minmax3(thisW, thisEvent, relative_traveltimes)
    ah=get(gcf,'Children');
    title(ah(7),sprintf('Event %d',eventNumber));

    feval('print', '-dpng', sprintf('%s/%s_%03d',figureOutDirectory, titleStr, eventNumber) );
    close
    infrasoundEventOut = [infrasoundEventOut thisEvent];
end