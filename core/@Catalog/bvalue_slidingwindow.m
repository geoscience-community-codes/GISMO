function [a,b,Mc,berror,ot] = bvalue_slidingwindow(cobj, N, stepsize, runmode)
%BVALUE_SLIDINGWINDOW Sliding-window Gutenberg–Richter analysis
%
%   [a,b,Mc,berror,ot] = BVALUE_SLIDINGWINDOW(cobj, N, stepsize)
%   [a,b,Mc,berror,ot] = BVALUE_SLIDINGWINDOW(cobj, N, stepsize, runmode)
%
%   Inputs:
%       cobj      - Catalog object
%       N         - Number of events per window (>= 30 recommended)
%       stepsize  - Number of events to advance per step
%       runmode   - 0 = no plotting (default, CI/batch safe)
%                   1 = plot results
%
%   Outputs:
%       a         - a-value time series
%       b         - b-value time series
%       Mc        - magnitude of completeness time series
%       berror    - b-value standard error
%       ot        - origin times corresponding to window end times
%
%   Each window contains exactly N events. The k-th window spans:
%       events (k-N+1 : k)
%
%   Internally calls:
%       Catalog.bvalue(runmode=0)
%
%   Author: Glenn Thompson (refactor 2025)

    % ----------------------------
    % Input validation
    % ----------------------------
    if nargin < 3
        error('Catalog:bvalue_slidingwindow:NotEnoughInputs', ...
              'Requires (cobj, N, stepsize)');
    end
    if nargin < 4 || isempty(runmode)
        runmode = 0;   % batch-safe default
    end
    if N < 30
        warning('Catalog:bvalue_slidingwindow:SmallWindow', ...
                'N < 30 may give unstable b-values');
    end
    if stepsize < 1
        error('stepsize must be >= 1');
    end

    % ----------------------------
    % Remove events with undefined magnitude
    % ----------------------------
    goodIdx  = find(cobj.mag > -1);
    cleancat = cobj.subset('indices', goodIdx);

    nEvents = cleancat.numberOfEvents;

    % ----------------------------
    % Preallocate outputs
    % ----------------------------
    a       = NaN(1, nEvents);
    b       = NaN(1, nEvents);
    Mc      = NaN(1, nEvents);
    berror  = NaN(1, nEvents);
    ot      = cleancat.otime;

    % ----------------------------
    % Sliding-window loop
    % ----------------------------
    fprintf('Running sliding-window b-value analysis:\n');

    for count = N:stepsize:nEvents

        thiscobj = cleancat.subset('indices', count-N+1 : count);

        if mod(count,10) == 0
            fprintf('\nEvent %d / %d',count,nEvents);
        else
            fprintf('.');
        end

        try
            gr = thiscobj.bvalue(0);   % force non-interactive

            a(count)      = gr.avalue;
            b(count)      = gr.bvalue;
            Mc(count)     = gr.Mc;
            berror(count) = gr.bvalue_error;

        catch ME
            warning('Catalog:bvalue_slidingwindow:WindowFailed', ...
                    'Window ending at event %d failed: %s', ...
                     count, ME.message);
        end
    end

    fprintf('\nDone.\n');

    % ----------------------------
    % Optional plotting
    % ----------------------------
    if runmode > 0

        % ----- a-value -----
        hf1 = figure('Color','w');
        plot(ot, a, 'b.');
        hold on
        plot(ot, smoothdata(a,'movmean',25), 'r');
        a2 = a;
        a2(berror > 0.25) = NaN;
        plot(ot, a2, 'k','LineWidth',2);
        datetick('x')
        ylabel('a-value')
        title('Sliding-window a-value')
        axis tight
        xlims1 = get(gca, 'XLim');

        % ----- b & Mc -----
        hf2 = figure('Color','w');

        subplot(2,1,1)
        plot(ot, b, 'r');
        hold on
        plot(ot, b + berror, 'k:');
        plot(ot, b - berror, 'k:');
        b2 = b;
        b2(berror > 0.25) = NaN;
        plot(ot, b2, 'k','LineWidth',2);
        datetick('x');
        ylabel('b-value')
        title('Sliding-window b-value')
        axis tight
        xlims2 = get(gca, 'XLim');

        subplot(2,1,2)
        plot(ot, Mc, 'b.');
        hold on
        plot(ot, smoothdata(Mc,'movmean',25), 'r')
        Mc2 = Mc;
        Mc2(berror > 0.25) = NaN;
        plot(ot, Mc2, 'k','LineWidth',2);
        datetick('x');
        ylabel('Mc')
        title('Sliding-window Mc')
        axis tight
        xlims3 = get(gca, 'XLim');

        % ----- synchronize x-limits -----
        xlimmin = max([xlims1(1) xlims2(1) xlims3(1)]);
        xlimmax = min([xlims1(2) xlims2(2) xlims3(2)]);

        figure(hf1)
        set(gca,'XLim',[xlimmin xlimmax]);

        figure(hf2)
        subplot(2,1,1)
        set(gca,'XLim',[xlimmin xlimmax]);
        subplot(2,1,2)
        set(gca,'XLim',[xlimmin xlimmax]);
    end
end


