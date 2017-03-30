function catalogobj = associate(arrivalobj, maxTimeDiff)
%ASSOCIATE Associate arrivals into events
% catalogobj = associate(arrivals, maxTimeDiff) will scan through an
% arrivals object (assumed to be sorted in chronological order) and look 
% for times where there are at least 2 arrivals on
% within maxTimeDiff seconds of each other, and declare an event.
%
% Notes: 
% - no checking is done to see if arrivals are on different channels
% - if loading from Antelope with Arrival.retrieve(), arrivals are already
%   sorted
%
% Example: Imagine you have an infrasound array and you have marked
% infrasound events manually (or automatically) with an "N" phase, picking
% an "N" on at least two channels. You also notice that the time to cross
% the array is less than 0.1s (e.g. array less than 34m across if sound
% speed is 340m/s). Then the following code will load the arrivals, subset
% for "N" phases, and associate into events wherever 2 channels have an "N"
% pick within 0.1s. The final line returns a Catalog object - the GISMO
% container for multiple events.
%   
%   dbpath = '/raid/data/sakurajima/db'; 
%   arrivalobj = Arrival.retrieve('antelope', dbpath); 
%   arrivalobj = arrivalobj.subset('iphase', 'N'); 
%   catalogobj = arrivalobj.associate(0.1);        


% First we begin with each arrival and find how many arrivals occur in the
% maxTimeDiff seconds that follow. This way each arrival is assigned a
% weight equal to that number of arrivals. The point of this is to help us
% identify the beginning of each event.
arrtimes = arrivalobj.time;
fprintf('\nFinding how many arrivals within %e sec of each arrival\n',maxTimeDiff)
for c=1:numel(arrtimes)
    associated_indices{c} = find(arrtimes>=arrtimes(c) & arrtimes<=arrtimes(c)+maxTimeDiff/86400);
    numarrivals(c) = numel(associated_indices{c});
end

% remove decrementing series, e.g. replace sequence 
% like 6 5 4 3 2 1 with 6 0 0 0 0 0
numarrivals = [numarrivals(1) diff(numarrivals)+1];
numarrivals(numarrivals<=1)=0;


% Now loop over numarrivals and create events
fprintf('Making events')
eventnum = 0;
for c=1:numel(numarrivals)
    if numarrivals(c)
        fprintf('.')
        eventnum = eventnum + 1;
        firstArrivalTime(eventnum) = arrtimes(c);
        lastArrivalTime(eventnum) = arrtimes(c + numarrivals(c) - 1);
        
        try
            arrivalobj2{eventnum} = arrivalobj.subset([c : c + numarrivals(c) - 1]);
        catch
            numarrivals(c)
            c+numarrivals(c)-1
            numel(numarrivals)
            rethrow();
        end
       

    end
    if mod(c,30) == 0
        fprintf('\nProcessed %d out of %d\n',c, numel(numarrivals));
    end
end

fprintf('\nCreating Catalog\n')
catalogobj = Catalog(firstArrivalTime, [], [], [], [], {}, {}, 'ontime', firstArrivalTime, 'offtime', lastArrivalTime);
catalogobj.arrivals = arrivalobj2;

% function result = alreadyHaveArrivalFromThisChannel(ctaglist, thisctag)
% result = sum(cellfun(@(s) ~isempty(strfind(thisctag, s)), ctaglist));