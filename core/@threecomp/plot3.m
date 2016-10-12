function plot3(TC)
%PLOT3 Interactively make 3D plot of particle motion vector evolution

    %% Extract data for whole threecomp object
    w = get(TC,'waveform');
    fs = get(w(1), 'freq');
    yz = get(w(1),'data');
    yr = get(w(2),'data');
    yt = get(w(3),'data');

    %% Get user to mouse click the window of interest
    plot2(TC);

    while true,
        % Select start and end times with mouse
        ylims=get(gca,'ylim');
        disp('Select start of time window with left mouse click')
        [xclick1 yclick1]=ginput(1);
        line([xclick1 xclick1],ylims);
        disp('Select end of time window with right mouse click')
        [xclick2 yclick2]=ginput(1);
        line([xclick2 xclick2],ylims);

        % Plotting
        fh = figure;
        nsamples = length(yz);
        startSample = ceil(xclick1 * fs);
        endSample = floor(xclick2 * fs);
        plot3(yr(startSample:endSample), yt(startSample:endSample), yz(startSample:endSample));
        xlabel('Radial')
        ylabel('Transverse')
        zlabel('Vertical')
        axis equal

        choice = menu('Select new time window?', 'yes', 'no');
        if choice==2
            return
        end
        close
    end
end
