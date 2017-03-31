function iceweb2017(subnetName, ds, ChannelTagList, ...
    snum, enum, nummins, products)
    debug.printfunctionstack('>');

    % load state
    statefile = sprintf('iceweb_%s_state.mat',subnetName);
    if exist(statefile, 'file')
        load(statefile)
    end

    % end time
    if enum==0
        enum = utnow - delaymins/1440;
    end
    
    % generate list of timewindows
    timewindows = iceweb.get_timewindow(enum, nummins, snum);
    
    % loop over timewindows
    for count = 1:length(timewindows.start)
        hh = datestr(timewindows.start(count),'HH');
        mm = datestr(timewindows.start(count),'MM');
        if strcmp(hh,'00') && strcmp(mm, '00') || count==1
            fprintf('\n%s ',datestr(timewindows.start(count),26));
        end
        if strcmp(mm,'00')
            fprintf('%s ',hh);
        end
        process_timewindow(subnetName, ChannelTagList, timewindows.start(count), timewindows.stop(count), ds, products);
    end
    debug.printfunctionstack('<');
end


function process_timewindow(subnetName, ChannelTagList, snum, enum, ds, products)
    debug.printfunctionstack('>');

    MILLISECOND_IN_DAYS = (1 / 86400000);
    enum = enum - MILLISECOND_IN_DAYS; % try to skip last sample

    % load state
    statefile = fullfile('iceweb', sprintf('%s_state.mat',subnetName));
    if exist(statefile, 'file')
        load(statefile)
        if snum < snum0 
            return
        end
    end
		
    % save state
    ds0=ds; ChannelTagList0=ChannelTagList; snum0=snum; enum0=enum; subnetName0 = subnetName;
    mkdir(fileparts(statefile));
    save(statefile, 'ds0', 'ChannelTagList0', 'snum0', 'enum0', 'subnetName0');
    clear ds0 ChannelTagList0 snum0 enum0 subnetName0
           
    %% Save raw waveform data to MAT file
    jjj = datenum2julday(snum);
    wavrawmat = fullfile('iceweb', 'waveforms_raw', subnetName, datestr(snum,'yyyy-mm-dd'), datestr(snum,30));
    if ~exist(wavrawmat,'file')
        %% Get waveform data
        debug.print_debug(1, sprintf('%s %s: Getting waveforms for %s from %s to %s at %s',mfilename, datestr(utnow), subnetName , datestr(snum), datestr(enum)));
        w = waveform(ds, ChannelTagList, snum, enum);
        %w = iceweb.waveform_wrapper(ds, ChannelTagList, snum, enum); % returns 1 waveform per channeltag, in same order
        if isempty(w)
            if debug.get_debug() > 0
                ds
                ChannelTagList
                datestr(snum)
                datestr(enum)
            end
            debug.printfunctionstack('<');
            return
        end
        mkdir(fileparts(wavrawmat));
        disp(sprintf('Saving waveform data to %s',wavrawmat));
        save(wavrawmat,'w');   
    end
    debug.printfunctionstack('<');

    % Save the cleaned waveform data to MAT file
    wavcleanmat = fullfile('iceweb', 'waveforms_clean', subnetName, datestr(snum,'yyyy-mm-dd'), datestr(snum,30));
    if ~exist(wavcleanmat,'file')

        % Eliminate empty waveform objects
        w = iceweb.waveform_remove_empty(w);
        if numel(w)==0
            debug.print_debug(1, 'No waveform data returned - skipping');
            return
        end

        % Clean the waveforms
        w = clean(w);

        % Pad all waveforms to same start/end
        [wsnum wenum] = gettimerange(w); % assume gaps already filled, signal
        w = pad(w, min([snum wsnum]), max([enum wenum]), 0);

        mkdir(fileparts(wavcleanmat));
        debug.print_debug(1,sprintf('Saving waveform data to %s',wavcleanmat));
        save(wavcleanmat,'w');   
    end
    
    %% ICEWEB PRODUCTS
    
    % WAVEFORM PLOT
    if products.waveform_plot.doit
        fname = fullfile('iceweb', 'waveforms_clean_plots', subnetName, sprintf('%s.png',datestr(snum,30)) );
        if ~exist(fname,'file')
            close all
            plot_panels(w, 'visible', 'off')
            orient tall;
            iceweb.saveImageFile(fname, 72); % this should make directory tree too
        end
    end
    
    % RSAM
    if products.rsam.doit
        for measureNum = 1:numel(products.rsam.measures)
            measure = products.rsam.measures{measureNum};
            if numel(products.rsam.samplingIntervalSeconds)>1
                samplingInterval = products.rsam.samplingIntervalSeconds(measureNum);
            else
                samplingInterval = products.rsam.samplingIntervalSeconds;
            end
            rsamobj = waveform2rsam(w, measure, samplingInterval);
            %rsamobj.plot_panels()
            rsamobj.save_to_bob_file(fullfile('iceweb', 'rsam_data', 'SSSS.CCC.YYYY.MMMM.bob'));
        end
    end

    
    % PLOT SPECTROGRAMS
    if products.spectrograms.doit
        spectrogramFilename = fullfile('iceweb', 'spectrograms', subnetName, datestr(snum, 26), sprintf('%s.png',datestr(snum,30)) );
        debug.print_debug(1, sprintf('Creating %s',spectrogramFilename))
        close all
        spectrogramFraction = 0.75;
        specObj = spectralobject(1024, 924, 10, [60 120]);
        [sgresult, Tcell, Fcell, Ycell] = iceweb.spectrogram_iceweb(specObj, w, spectrogramFraction, iceweb.extended_spectralobject_colormap);

            
        if sgresult > 0 % sgresult = number of waveforms for which a spectrogram was successfully plotted
            % SAVE SPECTROGRAM PLOT TO IMAGE FILE AND CREATE THUMBNAIL
            orient tall;

            if iceweb.saveImageFile(spectrogramFilename, 72)

                fileinfo = dir(spectrogramFilename); % getting a weird Index exceeds matrix dimensions error here.
                debug.print_debug(1, sprintf('%s %s: spectrogram PNG size is %d',mfilename, datestr(utnow), fileinfo.bytes));	

                % make thumbnails
                iceweb.makespectrogramthumbnails(spectrogramFilename, spectrogramFraction);
    
                % save spectral data
                if products.spectral_data.doit
                    frequency_index_divider = 5.0; % Hz
                    for spi = 1:numel(Fcell)
                        thisY = Ycell{spi};
                        thisF = Fcell{spi};
                        thisT = Tcell{spi};
                        sta = get(w(spi),'station');
                        chan = get(w(spi),'channel');

                        % peakF and meanF for each spectrogram window
                        [Ymax,imax] = max(thisY);
                        PEAK_F = thisF(imax);
                        MEAN_F = (thisF' * thisY)./sum(thisY);

                        % frequency index for each spectrogram window
                        fUpperIndices = find(thisF > frequency_index_divider);
                        fLowerIndices = find(thisF < frequency_index_divider);                    
                        fupper = sum(thisY(fUpperIndices,:));
                        flower = sum(thisY(fLowerIndices,:));
                        F_INDEX = log2(fupper ./ flower);

                        % Peak spectral value in each frequency bin - or in
                        % each minute?

                        % Now downsample to 1 sample per minute
                        dnum = unique(floorminute(thisT));
                        for k=1:length(dnum)
                            p = find(floorminute(thisT) == dnum(k));
                            downsampled_peakf(k) = nanmean(PEAK_F(p));
                            downsampled_meanf(k) = nanmean(MEAN_F(p));  
                            downsampled_findex(k) = nanmean(F_INDEX(p));
                            suby = thisY(:,p);
                            if size(suby,2) == 1
                                            max_in_each_freq_band(:,k) = suby;
                            else
                                            max_in_each_freq_band(:,k) = max(suby');
                            end
                        end

        %                 % Plot for verification
        %                 close all
        %                 subplot(2,1,1),plot(dnum,downsampled_peakf,':');datetick('x');
        %                 hold on
        %                 plot(dnum,downsampled_meanf);datetick('x');
        %                 subplot(2,1,2),plot(dnum,downsampled_findex);datetick('x');
        %                 anykey = input('Press any key to continue');

                        % Save data
                        r1 = rsam(dnum, downsampled_peakf, 'sta', sta, ...
                            'chan', chan, 'measure', 'peakf', ...
                            'units', 'Hz', 'snum', min(dnum), 'enum', max(dnum));
                        r1.save_to_bob_file(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.peakf'))

                        r2 = rsam(dnum, downsampled_meanf, 'sta', sta, ...
                            'chan', chan, 'measure', 'meanf', ...
                            'units', 'Hz', 'snum', min(dnum), 'enum', max(dnum));
                        r2.save_to_bob_file(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.meanf'))

                        r3 = rsam(dnum, downsampled_findex, 'sta', sta, ...
                            'chan', chan, 'measure', 'findex', ...
                            'units', 'none', 'snum', min(dnum), 'enum', max(dnum));
                        r3.save_to_bob_file(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.findex')) 

                        specdatafilename = fullfile('data', 'spectral', subnet, datestr(min(dnum),'yyyy/mm/dd'), sprintf( '%s_%s_%s.mat', datestr(min(dnum),30), sta, chan) );
                        specdatadir = fileparts(specdatafilename); % make the directory in case it does not exist
                        mkdir(specdatadir); % make the directory in case it does not exist
                        save(specdatafilename, 'dnum', 'max_in_each_freq_band') 
                        clear r1 r2 r3 k p   downsampled_peakf downsampled_meanf ...
                            downsampled_findex fUpperIndices fLowerIndices flower ...
                            fupper F_INDEX PEAK_F MEAN_F Ymax imax thisY thisF thisT ...
                            suby max_in_each_freq_band

                    end
                end
            end
        end
    end

    % SOUND FILES
    if products.soundfiles.doit
        try
            % 20120221 Added a "sound file" like 201202211259.sound which simply records order of stachans in waveform object so
            % php script can match spectrogram panel with appropriate wav file 
            % 20121101 GTHO COmment: Could replace use of bnameroot below with strrep, since it is just used to change file extensions
            % e.g. strrep(spectrogramFilename, '.png', sprintf('_%s_%s.wav', sta, chan)) 
            soundfileroot = fullfile('iceweb', 'soundfiles', subnetName, datestr(snum, 26) );
            [dname, bnameroot, bnameext] = fileparts(soundfileroot);
            soundfilelist = fullfile(soundfiles, sprintf('%s.sound',datestr(snum,30)));
            fsound = fopen(soundfilelist,'a');
            for c=1:length(w)
                soundfilename = fullfile(soundfileroot, sprintf('%s_%s_%s.wav',datestr(snum,30), get(w(c),'station'), get(w(c), 'channel')  ) );
                fprintf(fsound,'%s\n', soundfilename);  
                debug.print_debug(0, sprintf('Writing to %s',soundfilename)); 
                isSuccessful = waveform2sound(w(c), 60, soundfilename)
            end
            fclose(fsound);
        end
    end  
    debug.printfunctionstack('<');
end

