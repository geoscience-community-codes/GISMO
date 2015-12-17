function rsamobj = detectTremorEvents(stationName, chan, DP, snum, enum, spikeRatio, transientEventRatio, STA_minutes, LTA_minutes, stepsize, ratio_on, ratio_off, plotResults)
% detectTremorEvents Load RSAM data, remove spikes, remove
% transient events, and run STA/LTA detector on continuous data to
% identify tremor events.
%   rsamobj = detectTremorEvents(stationName, snum, enum, spikeRatio, transientEventRatio, STA_minutes, LTA_minutes, stepsize, ratio_on, ratio_off, plotResults)
%
%   Example:
%       DP = fullfile('/raid','data','antelope','mvo','SSSS_CCC_YYYY.DAT');
%       rsamobj = detectTremorEvents('MBWH', 'SHZ', DP, datenum(2001,2,26), datenum(2001,3,23), 100, 3, 20, 180, 1, 1.5, 1.0, true)
%   
%   This will:
%   * load data for MBWH between the dates given
%   * remove spikes lasting 1 or 2 samples that are at least 100 times adjacent samples
%   * remove transient events lasting 1 or 2 samples that are at least 3 times adjacent samples
%   * run an STA/LTA detector using STA_minutes, LTA_minutes,
%      stepsize, ratio_on and ratio_off (help rsam>detect for more)
%   * if plotResults==true, the results will be plotted in 3
%       figures
%   
%
%   Glenn Thompson 2014

    % validate inputs
    if nargin ~=13
        warning(sprintf('Wrong number of input arguments. Expected %d, got %d',13, nargin))
        help rsam>detectTremorEvents
        return
    end

    % load RSAM data into a RSAM object
    disp('load rsam object')
    rsamobj = rsam('file', DP, 'snum', snum, 'enum', enum, 'sta', stationName, 'chan', chan);
    rsamobj_raw = rsamobj;

    % Find really bad telemetry spikes in the data
    % This populates the spikes property and removes bad
    % spikes from data property            
    rsamobj = rsamobj.despike('spikes', spikeRatio);
    rsamobj_despiked = rsamobj;

    % Now find smaller spikes, corresponding to events
    % This populates the transientEvents property and removes event
    % spikes from data property
    rsamobj = rsamobj.despike('events', transientEventRatio);

    %% Now we have a RSAM object we can run tremor detections on
    % STA/LTA detector to find "continuous" events
    % This populates the continuousEvents property
    [rsamobj, windows] = rsamobj.tremorstalta('stalen', STA_minutes, 'ltalen', LTA_minutes, 'stepsize', stepsize, 'ratio_on', ratio_on, 'ratio_off', ratio_off);

    %% plot results if asked
    if plotResults

        %% plot the results from despiking bad & transient spikes
        figure

        % plot raw data
        ah(1)=subplot(3,1,1);
        rsamobj_raw.plot('h', ah(1));
        title('Raw')

        % plot despiked data
        ah(2)=subplot(3,1,2);     
        rsamobj_despiked.plot('h', ah(2));
        title('Despiked')

        % plot data after transient events removed
        ah(3)=subplot(3,1,3);     
        rsamobj.plot('h', ah(3));
        title('Transient events removed')
        linkaxes(ah,'x');

        %% Plot the STA/LTA diagnosticsnicole_paper.m
        figure;
        ha(1)=subplot(4, 1 ,1);plot(rsamobj.dnum, rsamobj.data );
        datetick('x')

        ha(2)=subplot(4, 1 ,2);plot(windows.endtime, windows.sta);
        datetick('x')
        ylabel(sprintf('STA\n(%s mins)',STA_minutes))

        ha(3)=subplot(4, 1,3); plot(windows.endtime, windows.lta);
        datetick('x')
        ylabel(sprintf('LTA\n(%s mins)',LTA_minutes))

        ha(4)=subplot(4,1,4);plot(windows.endtime, windows.ratio);
        datetick('x')
        hold on;
        for j=1:length(rsamobj.continuousEvents)
            i =( windows.endtime >= rsamobj.continuousEvents(j).dnum(1) & windows.endtime <= rsamobj.continuousEvents(j).dnum(end) );
            area(windows.endtime(i), windows.ratio(i),'FaceColor', 'r')
        end
        plot(windows.endtime, ones(1,length(windows.endtime))*ratio_on, ':')
        plot(windows.endtime, ones(1,length(windows.endtime))*ratio_off, ':')
        hold off
        ylabel('STA:LTA')
        linkaxes(ha,'x');
        suptitle('STA/LTA detector diagnostics')

        %% Plot the tremor events superimposed on the background signal RSAM
        % object 
        figure;
        rsamobj.plot();
        hold on
        for i=1:length(rsamobj.continuousEvents);
            plot(rsamobj.continuousEvents(i).dnum, rsamobj.continuousEvents(i).data,'r')
        end
        hold off
        datetick('x')
        title('Tremor events')
    end

end