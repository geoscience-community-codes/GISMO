function catalogobj = associate(arrivals, maxTimeDiff)
%ASSOCIATE Associate arrivals into events
% catalogobj = associate(arrivals, maxTimeDiff) will scan through an
% arrivals object and look for times where there are at least 2 arrivals on
% 2 different channels within maxTimeDiff of each other, and declare an event.
%
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

%% Associate events
disp('Associating arrivals into events...')
eventOn = false;
firstchaninfo = '';
firsttime = 0;
lasttime = 0;
eventNumber = 0;

for c=2:numel(arrivals.daynumber)
    if arrivals.daynumber(c-1) + maxTimeDiff/86400 > arrivals.daynumber(c)
            if ~eventOn % start new event
                eventOn = true;
                %eventNumber = eventNumber + 1;
                %infrasoundEvent(eventNumber).FirstArrivalTime = arrivals.daynumber(c-1);
                firsttime = arrivals.daynumber(c-1);
                lasttime = 0;
                firstchaninfo = arrivals.channelinfo(c-1);
            else % event already in progress
            end
            if ~strcmp(firstchaninfo, arrivals.channelinfo(c))
                %infrasoundEvent(eventNumber).LastArrivalTime = arrivals.daynumber(c);
                lasttime = arrivals.daynumber(c);
            end
    else 
        if eventOn % write out event
            eventOn = false;
            if (firsttime>0 && lasttime > 0)
                eventNumber = eventNumber + 1;
                infrasoundEvent(eventNumber).FirstArrivalTime = firsttime;
                infrasoundEvent(eventNumber).LastArrivalTime = lasttime;
            end
            firstchaninfo = '';
            firsttime = 0;
            lasttime = 0;
        end
    end
end
catalogobj = Catalog([infrasoundEvent.FirstArrivalTime], [], [], [], [], {}, {}, 'ontime', [infrasoundEvent.FirstArrivalTime], 'offtime', [infrasoundEvent.LastArrivalTime]);
