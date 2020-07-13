function process_timewindow(networkName, subnetName, ...
    ChannelTagList, snum, enum, ds, products, calibObjects)
    debug.printfunctionstack('>');
    % compatible with Pensive, except it names files by endtime
    filedate = datestr(snum,'yyyy-mm-dd'); % ICEWEB
    filetime = datestr(snum,'yyyymmdd-HHMM');
    fileendtime = datestr(enum,'yyyymmdd-HHMM');
%     filedate = datestr(enum,'yyyy-mm-dd'); % PENSIVE
%     filetime = datestr(enum,'yyyymmdd-HHMM');    

    MILLISECOND_IN_DAYS = (1 / 86400000);
    enum = enum - MILLISECOND_IN_DAYS; % try to skip last sample\

    %% uncomment the following to use the state file
    % this is best used only for a real-time system, to prevent
    % re-processing the same data
        %useStateFile;

%     spectrogramFilename = fullfile(products.subnetdir, filedate, sprintf('%s_%s.png',subnetName, filetime) );
%     if exist(spectrogramFilename, 'file')
%         fprintf('%s exists - skipping this timewindow',spectrogramFilename);
%         return
%     end
%            
    %% Load waveform data from MAT file - or from datasource otherwise
    jjj = datenum2julday(snum);
    wavrawmat = fullfile(products.subnetdir, filedate, sprintf('%s_%s_%s_raw.mat',subnetName,filetime,fileendtime));
    wavcleanmat = fullfile(products.subnetdir, filedate, sprintf('%s_%s_%s_clean.mat',subnetName,filetime,fileendtime));
    
    % return if we found no data for this day with dayfiles2smallfiles
    wavdaylock = fullfile(products.subnetdir, filedate, sprintf('%s_%s_day.lock',subnetName,filedate));
    if exist(wavdaylock, 'file')
        return
    end
    
    if exist(wavcleanmat)
        debug.print_debug(1,'Waveform file %s already exists\n',wavcleanmat);
        load(wavcleanmat);
        % keep waveform?
        if products.removeWaveformFiles
            delete(wavcleanmat);    
        end 
    elseif exist(wavrawmat)
        debug.print_debug(1,'Waveform file %s not found\n',wavcleanmat);
        debug.print_debug(1,'but %s already exists\n',wavrawmat);
        load(wavrawmat);
        % keep waveform?
        if products.removeWaveformFiles
            delete(wavrawmat);    
        end 
    else
        %% Get waveform data
        debug.print_debug(1,'Waveform file %s not found\n',wavcleanmat);
        debug.print_debug(1,'Waveform file %s not found\n',wavrawmat);
        w = iceweb.waveform_wrapper(ds, ChannelTagList, snum, enum);
        wavdir = fileparts(wavrawmat);
        if ~exist(wavdir,'dir')
            mkdir(wavdir);
        end
        debug.print_debug(1,sprintf('Saving waveform data to %s',wavrawmat));
        
        % save waveform?
        if ~products.removeWaveformFiles
            save(wavrawmat,'w');    
        end
          
    end
   
    % Save the cleaned waveform data to MAT file
    if ~exist(wavcleanmat,'file')

        % Eliminate empty waveform objects
        w = iceweb.waveform_remove_empty(w);
        if numel(w)==0
            debug.print_debug(1, 'All waveform objects were empty - skipping this time window');
            return
        end

        % Clean the waveforms
        w = clean(w);
        
        % Apply filterobject if exists
        if isfield(products,'filterobject') & ~isempty(products.filterobject)
            w = filtfilt(products.filterobject, w);
        end

        % Pad all waveforms to same start/end
        [wsnum wenum] = gettimerange(w); % assume gaps already filled, signal
        w = pad(w, min([snum wsnum]), max([enum wenum]), 0);
        
        wavdir = fileparts(wavcleanmat);
        if ~exist(wavdir,'dir')
            mkdir(wavdir);
        end

        debug.print_debug(1,sprintf('Saving waveform data to %s',wavcleanmat));
        
        % save waveform?
        if ~products.removeWaveformFiles
            save(wavcleanmat,'w');   
        end
    end
   
    % Apply calibs which should be stored within sites structure to
    % waveform objects to convert from counts to real physical
    % units
    w = iceweb.apply_calib(w, calibObjects);

    
    %% ICEWEB PRODUCTS

    % WAVEFORM PLOT
    if products.waveform_plot.doit
        fname = fullfile(products.subnetdir, filedate, sprintf('%s_%s_wfplot.png',subnetName,filetime));      
        if ~exist(fname,'file')
            close all
            plot_panels(w, 'visible', 'off');
            orient tall;
            iceweb.saveImageFile(fname, 72); % this should make directory tree too
            close all
        end
    end
    
    % RSAM
    rsamDoneFilename = fullfile(products.subnetdir, filedate, sprintf('%s_%s_rsamDone.txt',subnetName, filetime) );
    if ~exist(rsamDoneFilename, 'file')      
        if products.rsam.doit
            for measureNum = 1:numel(products.rsam.measures)
                measure = products.rsam.measures{measureNum};
                for sinum = 1:numel(products.rsam.samplingIntervalSeconds)
                    samplingInterval = products.rsam.samplingIntervalSeconds(sinum);
                    rsamobj = waveform2rsam(w, measure, samplingInterval);
                    rsamobj.save_to_bob_file(fullfile(products.subnetdir, sprintf('SSSS.CCC.YYYY.MMMM.%03d.bob',samplingInterval) ));
                end
            end
            % touch this file now we have successfully saved
            % the rsam data
            rfptr = fopen(rsamDoneFilename,'a+');
            fprintf(rfptr,'%s\n',datestr(now));
            fclose(rfptr);
        end
    end
   
    % COMPUTE SPECTROGRAMS
    spectrogramFilename = fullfile(products.subnetdir, filedate, sprintf('%s_%s.png',subnetName, filetime) );
    spectralProductsDoneFilename = fullfile(products.subnetdir, filedate, sprintf('%s_%s_SpectralDataDone.txt',subnetName, filetime) );
    if ~exist(spectrogramFilename, 'file') || ~exist(spectralProductsDoneFilename,'file')
        if products.spectral_data.doit || products.spectrograms.doit
            if products.spectrograms.doit
                % filepath is compatible with Pensive, except iceweb names by
                % start of timewindow, pensive names by end
                spectrogramFilename = fullfile(products.subnetdir, filedate, sprintf('%s_%s.png',subnetName, filetime) );
                debug.print_debug(1, sprintf('Creating %s',spectrogramFilename));
                close all
            end

            % if any channels have units 'Pa', multiple by 1000 so they are
            % visible
            for wavnum=1:numel(w)
                thischan = get(w(wavnum),'channel');
                if strcmp(get(w(wavnum),'units'), 'Pa') || strcmp(thischan(1:2),'BD')
                    w(wavnum) = w(wavnum) * 1000;
                    w(wavnum) = set(w(wavnum), 'units', 'mPa');
                end
            end

            % spectralobject
            nfft = 1024;
            overlap = 924;
            freqmax = products.spectrograms.fmax;
            dbLims = [products.spectrograms.dBmin products.spectrograms.dBmax];
            spobj = spectralobject(nfft, overlap, freqmax, dbLims);

            % compute spectrogram
            [sgresult, Tcell, Fcell, Ycell] = iceweb.spectrogram_iceweb(...
                spobj, w,  ...
                'plot_metrics', products.spectrograms.plot_metrics, ...
                'makeplot', products.spectrograms.doit);

            if sgresult > 0 % sgresult = number of waveforms for which a spectrogram was successfully plotted
                % SAVE SPECTROGRAM PLOT TO IMAGE FILE AND CREATE THUMBNAIL

                if products.spectrograms.doit
                    orient tall;
                    if iceweb.saveImageFile(spectrogramFilename, 72)

                        fileinfo = dir(spectrogramFilename); % getting a weird Index exceeds matrix dimensions error here.
                        debug.print_debug(1, sprintf('%s %s: spectrogram PNG size is %d',mfilename, datestr(now), fileinfo.bytes));	

                        % make thumbnails
                        iceweb.makespectrogramthumbnails(spectrogramFilename);
                        
                    end
                end
                
                % save spectral data
                if products.spectral_data.doit && ~exist(spectralProductsDoneFilename,'file')
                    debug.print_debug(1, sprintf('Saving spectral data'));
                    for spi = 1:numel(Fcell) % loop over channels
                        thisY = Ycell{spi}; % Y is in dB
                        thisS = power(10,thisY/20); % S is the true amplitude
                        thisF = Fcell{spi};
                        thisT = Tcell{spi};
                        thisCtag = get(w(spi),'ChannelTag');

                        % peakF and meanF for each spectrogram window but
                        % using a 1.0-20.0 Hz window
                        idx = find(thisF >= 1.0 & thisF <= 20.0);
                        thatF = thisF(idx);
                        thatS = thisS(idx,:);
                        [Smax,imax] = max(thatS);
                        PEAK_F = thatF(imax);
                        MEAN_F = (thatF' * thatS)./sum(thatS);

                        % frequency index for each spectrogram window Buurman and West (2010)
                        % log10 with 10-20 Hz and 1-2 Hz bands
                        fUpperIndices = find(thisF >= 10.0 & thisF <= 20.0);
                        fLowerIndices = find(thisF <= 2.0 & thisF >= 1.0);                    
                        fupper = mean(thisS(fUpperIndices,:));
                        flower = mean(thisS(fLowerIndices,:));
                        F_INDEX = log10(fupper ./ flower); 
                        
                        % frequency ratio Rodgers et al. (2015) JVGR 290, 63-74, https://doi.org/10.1016/j.jvolgeores.2014.11.012
                        % uses log2 of 1-6 and 6-11 Hz
                        fUpperIndices2 = find(thisF >= 6.0 & thisF <= 11.0);
                        fLowerIndices2 = find(thisF <= 6.0 & thisF >= 1.0);                    
                        fupper2 = mean(thisS(fUpperIndices2,:));
                        flower2 = mean(thisS(fLowerIndices2,:));
                        F_RATIO = log2(fupper2 ./ flower2); % 
                        % Peak spectral value in each frequency bin - or in
                        % each minute?

                        % Now downsample to 1 sample per minute
                        dnum = unique(floorminute(thisT));
                        for k=1:length(dnum) % loop over minutes
                            p = find(floorminute(thisT) == dnum(k));
                            downsampled_peakf(k) = nanmean(PEAK_F(p));
                            downsampled_meanf(k) = nanmean(MEAN_F(p));  
                            downsampled_findex(k) = nanmean(F_INDEX(p));
                            downsampled_fratio(k) = nanmean(F_RATIO(p));
                            
                            % For spectral data to make daily spectrograms,
                            % we use thisY, which is in dB, and represents
                            % all frequencies, not just 1-20 Hz
                            subY = thisY(:,p);
%                             size(subY)
                            median_in_each_freq_band(:, k) = nanmedian(subY');
%                             size(median_in_each_freq_band)
%                             size(nanmedian(subY'))
%                             size(subY.*subY)
%                             size(sum(subY.*subY,2)')
                            energy_in_each_freq_band(:, k) = sum(subY.*subY,2)';
%                             stop
                        end

                        % Save 1-minute spectral data
                        r1 = rsam(dnum, downsampled_peakf, 'ChannelTag', thisCtag, ...
                            'measure', 'peakf', ...
                            'units', 'Hz');
                        r1.save_to_bob_file(fullfile(products.subnetdir, 'SSSS.CCC.YYYY.peakf.bob'))

                        r2 = rsam(dnum, downsampled_meanf, 'ChannelTag', thisCtag, ...
                            'measure', 'meanf', ...
                            'units', 'Hz');
                        r2.save_to_bob_file(fullfile(products.subnetdir,  'SSSS.CCC.YYYY.meanf.bob'))

                        r3 = rsam(dnum, downsampled_findex, 'ChannelTag', thisCtag, ...
                            'measure', 'findex', ...
                            'units', 'none');                      
                        r3.save_to_bob_file(fullfile(products.subnetdir,   'SSSS.CCC.YYYY.findex.bob'))

                        r4 = rsam(dnum, downsampled_fratio, 'ChannelTag', thisCtag, ...
                            'measure', 'fratio', ...
                            'units', 'none');                      
                        r4.save_to_bob_file(fullfile(products.subnetdir,   'SSSS.CCC.YYYY.fratio.bob'))                        
                        % median spectral amplitude by minute
                        spdatafilepattern = fullfile(products.subnetdir, 'YYYY-MM-DD', 'spdata.NSLC.YYYY.MM.DD.amplitude');                      
                        iceweb.save_to_spectral_data_file(spdatafilepattern, dnum, ...
                            thisF, median_in_each_freq_band, ...
                            products.spectral_data.samplingIntervalSeconds, ...
                            thisCtag);
                        
                        % energy in each spectral amplitude by minute
                        spdatafilepattern = fullfile(products.subnetdir, 'YYYY-MM-DD', 'spdata.NSLC.YYYY.MM.DD.energy');
                        iceweb.save_to_spectral_data_file(spdatafilepattern, dnum, ...
                            thisF, energy_in_each_freq_band, ...
                            products.spectral_data.samplingIntervalSeconds, ...
                            thisCtag)    ; 
                       
                        % touch this file now we have successfully saved
                        % the spectral data
                        spfptr = fopen(spectralProductsDoneFilename,'a+');
                        fprintf(spfptr,'%s\n',datestr(now));
                        fclose(spfptr);
                        
                        clear r1 r2 r3 k p   downsampled_peakf downsampled_meanf ...
                            downsampled_findex fUpperIndices fLowerIndices flower ...
                            fupper F_INDEX PEAK_F MEAN_F Ymax imax thisY thisF thisT ...
                            thisCtag suby max_in_each_freq_band

                    end
                end
            end
        end
    end

    % SOUND FILES
    soundfilelist = sprintf('%s_sound.txt',spectrogramFilename(1:end-4) );
    if ~exist(soundfilelist,'file')
        if products.soundfiles.doit

            % 20120221 Added a "sound file" like 201202211259_sound.txt which simply records order of stachans in waveform object so
            % php script can match spectrogram panel with appropriate wav file 
            [dname, bnameroot, bnameext] = fileparts(spectrogramFilename);
            fsound = fopen(soundfilelist,'a');
            for c=1:length(w)
                soundfilename = fullfile(dname, sprintf('%s_%s_%s.wav',bnameroot, get(w(c),'station'), get(w(c), 'channel')  ) );
                pathparts = strsplit(soundfilename, filesep);
                soundfileurl = fullfile(pathparts{end-3:end});
                fprintf(fsound,'%s\n', soundfileurl);  
                debug.print_debug(1, sprintf('Writing to %s',soundfilename)); 
                isSuccessful = waveform2sound(w(c), 60, soundfilename);
            end
            fclose(fsound);
        end
    end
    
%     % CREATE & SAVE HELICORDER PLOT
%     if products.helicorders.doit 
%         close all
%         for wi=1:numel(w)
%             plot_helicorder(w(wi),'mpl',3);
%             ct = get(w(wi),'channeltag');
%             helicorderFilename = fullfile(products.subnetdir, filedate, sprintf('helicorder_%s_%s.png',ct.string(),filetime));
%             orient tall;
%             iceweb.saveImageFile(helicorderFilename, 72);
%             clear ct helicorderFilename
%         end
%         clear wi
%     end
    
    
    debug.printfunctionstack('<');
end