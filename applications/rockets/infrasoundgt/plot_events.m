function plot_events(wevent, filepattern, figureOutDirectory)
numEvents = numel(wevent);
for eventNumber=1:numEvents
    fprintf('- plotting event %d of %d\n',eventNumber,numEvents );
    plot_panels(wevent{eventNumber});
    ah=get(gcf,'Children');
    title(ah(7),sprintf('Event %d',eventNumber));
    outfile = sprintf('%s/%s%03d.png',figureOutDirectory, filepattern, eventNumber);
    feval('print', '-dpng', outfile); 
    close
end