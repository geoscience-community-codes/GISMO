function [swarminess, magstd] = swarminess(cobj, N)
%SWARMINESS Determine the running swarminess metric for a Catalog object
%   [swarminess, magstd] = swarminess(cobj, N) where N is number of closest 
%       events in time to include in the calculation. 
% e.g.
%   [swarminess, magstd] = swarminess(redoubt_events, 100)

    nEvents = cobj.numberOfEvents;
    secs = cobj.otime * 86400; 
    for count = 1 : nEvents
        if mod(count,10)==0
            fprintf('\nEvent %d/%d',count,nEvents);
        else
            fprintf('.');
        end
        minindex = max([count-N 1]);
        timediff = abs( secs(count) - secs(minindex:count-1) );
        %timediff(timediff==0) = []; % so we don't compare current event with itself, would cause Inf
        timediff(timediff<10.0) = []; % because no catalog has events within 10s of each other
        swarminess(count) = sum(1./timediff);
        magstd(count) = nanstd(cobj.mag(minindex:count));
    end
    figure
    subplot(3,1,1)
    er = cobj.eventrate('binsize', 1/24);
    plot(er.time, er.counts);
    ylabel('Events per hour')
    datetick('x')
    subplot(3,1,2)
    plot(cobj.otime, swarminess)
    datetick('x')
    xlabel('Date/Time')
    ylabel('Swarminess')
    subplot(3,1,3)
    plot(cobj.otime, magstd)
    datetick('x')
    xlabel('Date/Time')
    ylabel('Std(Magnitude)')
end

