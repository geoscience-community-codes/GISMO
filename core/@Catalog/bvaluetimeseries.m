function [a,b,Mc,berror]=bvaluetimeseries(cobj, N, stepsize)
%BVALUETIMESERIES b-value and magnitude of completeness through time
%   bvaluetimeseries(catalogObject, windowsize, stepsize) where:
%       cobj     = a Catalog object
%       N        = the number of events to include for each bvalue
%                       calculation
%       stepsize = the number of events to slide with each iteration.
%   
%   Hence the first time window will go from event 1 to event N. The second
%   will go from event 1+stepsize to N+stepsize. The third from
%   1+2*stepsize to N+2*stepsize. Hence each window always has N events.
%
%   For each window of N events, the Catalog.bvalue() method is run to
%   find the best fit Gutenberg-Richter power law given by:
%        log10(cumN) = a - bM
%
%
%   Outputs:
%       a, b, Mc, and berror are vectors, the same size as 
%                            catalogObject.otime().
%   
%  
%   Example:
%       [a,b,Mc,berror] = bvaluetimeseries(redoubt_events, 100, 1)
%
%   A windowsize of at least 100 events works well - less than this makes
%   it hard to have a statistically robust Gutenburg-Richter plot to fit an
%   Mc and slope (bvalue) to.
%   The stepsize can be 1, in which case the window slides 1 event at a
%   time. This is fine for a catalog of a few thousand events. But for
%   really large catalogs, a larger stepsize might be required to keep
%   computational time reasonable.

    % remove events with undefined magnitude
    i = find(cobj.mag > -1);
    cleancat = cobj.subset('indices', i);

    % initialize
    a = NaN(1, numel(cleancat.otime));
    b = a;
    berror = a;
    Mc = a;

    for count = N:cleancat.numberOfEvents
        thiscobj = cleancat.subset('indices', count-N+1: count);
        if mod(count,10)==0
            fprintf('\nEvent %d/%d',count,cleancat.numberOfEvents);
        else
            fprintf('.');
        end
        %try
            gr = thiscobj.bvalue(0);
            a(count) = gr.avalue;
            b(count) = gr.bvalue;
            Mc(count) = gr.Mc;
            berror(count) = gr.bvalue_error;
        %catch
        %    disp('caught crash');
        %end

    end
    
    % plot data
    hf1=figure;
    plot(cleancat.otime, a, 'b.')
    hold on
    plot(cleancat.otime, smooth(a), 'r')
    a2 = a;
    a2(berror>0.25) = NaN;
    plot(cleancat.otime, a2, 'k','LineWidth',3);
    datetick('x')
    ylabel('a-value')
    axis tight;
    xlims1 = get(gca, 'XLim');

    hf2=figure;
    subplot(2,1,1)
    %errorbar(cleancat.otime, b, berror, 'b.')
    plot(cleancat.otime, b, 'r');
    hold on
    plot(cleancat.otime, b+berror, 'k:');
    plot(cleancat.otime, b-berror, 'k:');
    b2 = b;
    b2(berror>0.25) = NaN;
    plot(cleancat.otime, b2, 'k','LineWidth',3);
    datetick('x');
    ylabel('b-value')
    axis tight
    xlims2 = get(gca, 'XLim');

    subplot(2,1,2)
    plot(cleancat.otime, Mc, 'b.')
    hold on
    plot(cleancat.otime, smooth(Mc), 'r')
    Mc2 = Mc;
    Mc2(berror>0.25) = NaN;
    plot(cleancat.otime, Mc2, 'k','LineWidth',3);
    datetick('x');
    ylabel('Mc')
    axis tight
    xlims3 = get(gca, 'XLim');

    % fix to same xlimits
    xlimmin = max([xlims1(1) xlims2(1) xlims3(1)]);
    xlimmax = min([xlims1(2) xlims2(2) xlims3(2)]);
    set(gca,'XLim',[xlimmin xlimmax]);
    subplot(2,1,1)
    set(gca,'XLim',[xlimmin xlimmax]);
    figure(hf2)
    set(gca,'XLim',[xlimmin xlimmax]);

end

