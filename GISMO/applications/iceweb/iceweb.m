function iceweb(ds, varargin)
    debug.printfunctionstack('>');
    % Process arguments
    [thismode, snum, enum, nummins, delaymins, thissubnet, matfile] = matlab_extensions.process_options(varargin, 'mode', 'archive', 'snum', 0, 'enum', 0, 'nummins', 10, 'delaymins', 0, 'thissubnet', '', 'matfile', 'pf/tremor_runtime.mat');
    if exist(matfile, 'file')
        load(matfile);
        PARAMS.mode = thismode;
        clear thismode;
    else
        warning(sprintf('matfile %s not found',matfile))
        return
    end

    % load state
    statefile = sprintf('iceweb_%s_state.mat',thissubnet);
    if exist(statefile, 'file')
        load(statefile)
        if strcmp(thissubnet, subnet0)
		snum = snum0;
	end
    end

    % subset on thissubnet
    if ~strcmp(thissubnet, '') 
        index = 0;
        for c=1:length(subnets)
            if strcmp(subnets(c).name, thissubnet)
                index = c;
            end
        end
        if index > 0
            subnets = subnets(index);
            debug.print_debug(0, 'subnet found')
        else
            warning('subnet not found')
            return;
        end
    end

    % end time
    if enum==0
        enum = utnow - delaymins/1440;
    end
    
    % since the standard way is to create Antelope databases from day-long
    % miniseed files for each channeltag, and reference these from
    % day-long databases, I could add a check here using
    % listMiniSEEDfiles to see if there are any data files for each day
    % before I look for each 10 minute window for that day with
    % waveform_wrapper
    %   steps:
        % check if datasource is Antelope
        % loop over each day from snum to enum
        % call listMiniSEEDfiles
        % see for which channeltag I get exists=2, and then only use that
        % list of successful channeltags for that day
        % create timewindows for that day
        % call iceweb_helper for each time window
        
    % NEW STUFF TO IMPLEMENT ABOVE SUGGESTION - MIGHT NOT WORK    
    if exist('ds','var') & strcmp(get(ds,'type'),'antelope')

        for c=1:numel(subnets)
            sites = subnets(c).sites;
            for dnum = floor(snum):ceil(enum)
                disp(datestr(dnum))
%                 for ccc=1:numel(sites)
%                     disp(sites(ccc).channeltag.string())
%                 end
                   
                % subset to channels active for today according to
                % site/sitechan db
                todaysites = get_channeltags_active(sites, dnum); % subset to channeltags valid
                if isempty(todaysites)
                    continue;
                end
                chantag = [todaysites.channeltag];
%                 for ccc=1:numel(chantag)
%                     disp(chantag(ccc).string())
%                 end             
                % change channel tag if this is MV network because channels in wfdisc table
                % are like SHZ_--
                for cc=1:numel(chantag)
                    if strcmp(chantag(cc).network, 'MV')
                        chantag(cc).channel = sprintf('%s_--',chantag(cc).channel);
                    end
                end

                % subset to sites for which the files pointed to by the
                % wfdisc table, actually exist
                m = listMiniseedFiles(ds, chantag, dnum, dnum+1);
                todaysites = todaysites([m.exists]==2);
                tw = get_timewindow(min([enum dnum+1]), nummins, max([dnum snum]));

                newsubnets = subnets(c);
                newsubnets.sites = todaysites;
%                 for ccc=1:numel(todaysites)
%                     disp(sites(ccc).channeltag.string())
%                 end

                % loop over timewindows
                for count = 1:length(tw.start)
                    thistw.start = tw.start(count);	
                    thistw.stop = tw.stop(count);	
                    iceweb_helper(paths, PARAMS, newsubnets, thistw, ds);
                end
            end
        end
    else
        % THE WAY WE USED TO DO IT
        % timewindows
        if snum==0
            tw = get_timewindow(enum, nummins);
        else
            tw = get_timewindow(enum, nummins, snum);
        end
        snum = enum - nummins/1440;

        % loop over timewindows backwards, thereby prioritizing most recent data
        for count = length(tw.start) : -1 : 1
            thistw.start = tw.start(count);	
            thistw.stop = tw.stop(count);	
            iceweb_helper(paths, PARAMS, subnets, thistw);
        end
    end
    debug.printfunctionstack('<');
end


function iceweb_helper(paths, PARAMS, subnets, tw, ds)
    debug.printfunctionstack('>');

    MILLISECOND_IN_DAYS = (1 / 86400000);

    makeSamFiles = false;
    makeSoundFiles = true; 

    if ~exist('ds','var')
        for c=1:numel(PARAMS.datasource)
            if strcmp(PARAMS.datasource(c).type, 'antelope')
                ds(c) = datasource(PARAMS.datasource(c).type, PARAMS.datasource(c).path);
%                 ds(c) = datasource('antelope', ...
%                '/raid/data/MONTSERRAT/antelope/db/db%04d%02d%02d',...
%                'year','month','day');
            else
                ds(c) = datasource(PARAMS.datasource(c).type, PARAMS.datasource(c).path, str2num(PARAMS.datasource(c).port));
            end
        end
    end
    %gismo_datasource = gismo_datasource(1);

    %% LOOP OVER SUBNETS / SITES
    for subnet_num=1:length(subnets)
        % which subnet?
        subnet = subnets(subnet_num).name;

        % get IceWeb sites
        sites = subnets(subnet_num).sites;
        if isempty(sites)
            continue;
        end

        % loop over all elements of tw
        for twcount = 1:length(tw.start)

            snum = tw.start(twcount);
            enum = tw.stop(twcount) - MILLISECOND_IN_DAYS; % try to skip last sample

	    % load state
	    statefile = sprintf('iceweb_%s_state.mat',subnet);
	    if exist(statefile, 'file')
		load(statefile)
		if strcmp(subnet, subnet0)
			if snum < snum0 % skip
				continue
			end
		end
	    end
		
	    % save state
	    ds0=ds; sites0=sites; snum0=snum; enum0=enum; subnet0 = subnet;
	    save(statefile, 'ds0', 'sites0', 'snum0', 'enum0', 'subnet0');
	    clear ds0 sites0 snum0 enum0 subnet0

            % Have we already process this timewindow?
            spectrogramFilename = get_spectrogram_filename(paths,subnet,enum);
             if exist(spectrogramFilename, 'file')
                 fprintf('%s already exists - skipping\n',spectrogramFilename);
                 continue
             end
            
            %% Get waveform data
            debug.print_debug(0, sprintf('%s %s: Getting waveforms for %s from %s to %s at %s',mfilename, datestr(utnow), subnet , datestr(snum), datestr(enum)));
            w = waveform_wrapper([sites.channeltag], snum, enum, ds);

            %% PRE_PROCESS DATA
            
            % Eliminate empty waveform objects
            w = waveform_remove_empty(w);
            if numel(w)==0
                debug.print_debug(0, 'No waveform data returned - skipping');
                continue
            end

            % Clean the waveforms
            w = fillgaps(w, 'interp');
            w = detrend(w);

            % Apply calibs which should be stored within sites structure to
            % waveform objects to convert from counts to real physical
            % units
            w = apply_calib(w, sites);

            % Apply filter to all signals
            w = apply_filter(w, PARAMS);
            
            % Pad all waveforms to same start/end
            [wsnum wenum] = gettimerange(w); % assume gaps already filled, signal
            w = pad(w, min([snum wsnum]), max([enum wenum]), 0);
            
            % Save RSAM data
            rsamobj = rsam(w);
            rsamobj.save(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.rsam'));
            
            %% CREATE & SAVE WAVEFORM PLOT
            close all
            linkedplot(w)
            %s = input('continue?');
            [spdir,spbase,spext] = fileparts(spectrogramFilename);
            mulpltFilename = fullfile(spdir, sprintf('mulplt_%s%s',spbase,spext));
            orient tall;
            saveImageFile(mulpltFilename, 72);    
            
%             %% CREATE & SAVE HELICORDER PLOT
%             % SCAFFOLD
%             try % crashing with 
% %                  Index exceeds matrix dimensions.
% % 
% %                 Error in helicorder/build>pad_w (line 339)
% %                       dat = [pad1; get(w(n),'data')];
% % 
% %                 Error in helicorder/build (line 68)
% %                 h = pad_w(h);          % If front of waveform is missing, fill with NaN
% % 
% %                 Error in iceweb>iceweb_helper (line 208)
% %                             build(heliplot)
% % 
% %                 Error in iceweb (line 93)
% %                                     iceweb_helper(paths, PARAMS, newsubnets, thistw, ds);
% % 
% %                 Error in unrest (line 20)
% %                 iceweb(ds, 'thissubnet', 'Sakurajima', 'snum', datenum(2015,6,3), 'enum', datenum(2015,6, 7), 'delaymins', 0, 'matfile', 'pf/Sakurajima.mat',
% %                 'nummins', mins, 'mode', 'archive');               
%                 close all
%                 heliplot = helicorder(w);
%                 build(heliplot)
%                 helicorderFilename = fullfile(spdir, sprintf('heli_%s%s',spbase,spext));
%                 orient tall;
%                 saveImageFile(helicorderFilename, 72); 
%             end
            

            %% PLOT SPECTROGRAM	
            close all
            debug.print_debug(1, sprintf('Creating %s',spectrogramFilename))
            %specgram_iceweb(PARAMS.spectralobject, w, 0.75, extended_spectralobject_colormap);
            %specgram_wrapper(PARAMS.spectralobject, w, 0.75, extended_spectralobject_colormap);
%             try
                spectrogramFraction = 0.75;
                [sgresult, Tcell, Fcell, Ycell] = spectrogram_iceweb(PARAMS.spectralobject, w, spectrogramFraction, extended_spectralobject_colormap);
                if sgresult > 0 % sgresult = number of waveforms for which a spectrogram was successfully plotted
                    %% SAVE SPECTROGRAM PLOT TO IMAGE FILE AND CREATE THUMBNAIL
                    orient tall;

                    if saveImageFile(spectrogramFilename, 72)

                        fileinfo = dir(spectrogramFilename); % getting a weird Index exceeds matrix dimensions error here.
                        debug.print_debug(0, sprintf('%s %s: spectrogram PNG size is %d',mfilename, datestr(utnow), fileinfo.bytes));	

                        % make thumbnails
                        makespectrogramthumbnails(spectrogramFilename, spectrogramFraction);

                    end
                    close all

                    %% save spectral data
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
                        dnum = unique(matlab_extensions.floorminute(thisT));
                        for k=1:length(dnum)
                            p = find(matlab_extensions.floorminute(thisT) == dnum(k));
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
                        r1.save(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.peakf'))

                        r2 = rsam(dnum, downsampled_meanf, 'sta', sta, ...
                            'chan', chan, 'measure', 'meanf', ...
                            'units', 'Hz', 'snum', min(dnum), 'enum', max(dnum));
                        r2.save(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.meanf'))

                        r3 = rsam(dnum, downsampled_findex, 'sta', sta, ...
                            'chan', chan, 'measure', 'findex', ...
                            'units', 'none', 'snum', min(dnum), 'enum', max(dnum));
                        r3.save(fullfile('spectrograms', subnet, 'SSSS.CCC.YYYY.findex')) 

                        specdatafilename = fullfile('spectrograms', subnet, datestr(min(dnum),'yyyy/mm/dd'), sprintf( '%s_%s_%s.mat', datestr(min(dnum),30), sta, chan) );
                        mkdir(fileparts(specdatafilename)); % make the directory in case it does not exist
                        save(specdatafilename, 'dnum', 'max_in_each_freq_band') 
                        clear r1 r2 r3 k p   downsampled_peakf downsampled_meanf ...
                            downsampled_findex fUpperIndices fLowerIndices flower ...
                            fupper F_INDEX PEAK_F MEAN_F Ymax imax thisY thisF thisT ...
                            suby max_in_each_freq_band

                    end
                end

                %% SOUND FILES
                if makeSoundFiles
                    try
                        % 20120221 Added a "sound file" like 201202211259.sound which simply records order of stachans in waveform object so
                        % php script can match spectrogram panel with appropriate wav file 
                        % 20121101 GTHO COmment: Could replace use of bnameroot below with strrep, since it is just used to change file extensions
                        % e.g. strrep(spectrogramFilename, '.png', sprintf('_%s_%s.wav', sta, chan)) 
                        [bname, dname, bnameroot, bnameext] = matlab_extensions.basename(spectrogramFilename);
                        fsound = fopen(sprintf('%s%s%s.sound', dname, filesep, bnameroot),'a');
                        for c=1:length(w)
                            soundfilename = fullfile(dname, sprintf('%s_%s_%s.wav',bnameroot, get(w(c),'station'), get(w(c), 'channel')  ) );
                            fprintf(fsound,'%s\n', soundfilename);  
                            debug.print_debug(0, sprintf('Writing to %s',soundfilename)); 
                            data = get(w(c),'data');
                            m = max(data);
                            if m == 0
                                m = 1;
                            end 
                            data = data / m;
                            wavwrite(data, get(w(c), 'freq') * 120, soundfilename);
                        end
                        fclose(fsound);
                    end
                end
%             end
        end
    end

    debug.printfunctionstack('<');
end



	







