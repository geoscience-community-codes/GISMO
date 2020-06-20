function dayfiles2smallfiles(networkName, subnetName, ...
    ChannelTagList, snum, enum, ds, products, calibObjects, nummins)
    debug.printfunctionstack('>');
    % compatible with Pensive, except it names files by endtime
    filedate = datestr(snum,'yyyy-mm-dd'); % ICEWEB

    MILLISECOND_IN_DAYS = (1 / 86400000);
    enum = enum - MILLISECOND_IN_DAYS; % try to skip last sample\

    %% uncomment the following to use the state file
    % this is best used only for a real-time system, to prevent
    % re-processing the same data
        %useStateFile;
           
    %% Load waveform data from MAT file - or from datasource otherwise
    jjj = datenum2julday(snum);
    wavdaymat = fullfile(products.subnetdir, filedate, sprintf('%s_%s_day.mat',subnetName,filedate));
    wavdaylock = fullfile(products.subnetdir, filedate, sprintf('%s_%s_day.lock',subnetName,filedate));
    system(sprintf('touch %s',wavdaylock));
    fprintf('Creating lock file %s\n',wavdaylock);
    %anykey=input('Any key to continue')
    if exist(wavdaymat)
        fprintf('Day waveform file %s already exists\n',wavdaymat);
        load(wavdaymat);
    else
        %% Get waveform data
        fprintf('Waveform file %s not found\n',wavdaymat);
        w = iceweb.waveform_wrapper(ds, ChannelTagList, snum, enum);
        wavdir = fileparts(wavdaymat);
        if ~exist(wavdir,'dir')
            mkdir(wavdir);
        end
        debug.print_debug(1,sprintf('Saving waveform data to %s',wavdaymat));
        
        % save waveform?
        if ~isempty(w)
            save(wavdaymat,'w');   
        end
          
    end
    
    %% make sure we got 1 day of data & rename to wday
    if exist('w','var')
        if isempty(w)
            disp('No data in waveform object. Keeping day lock in place')
            return
        end

            
    else
        disp('No waveform object. Keeping day lock in place')
        return
    end  
    
    % we got at least some data. so remove the lock file
    system(sprintf('rm %s',wavdaylock));
    fprintf('Removinglock file %s\n',wavdaylock);
    
    % if we didn't get something close to 1 day of data, we probably do not
    % have miniseed files one day long, so return
    [wsnum, wenum] = gettimerange(w);
    if median(wenum) < median(wsnum) + 0.99
        % we did not get 1 day of data
        disp('Less than 1 day of data in each file. Returning')
        return
    end    
    
    wday = w;
    clear w;
    
   
    %% loop over the day-long waveform object and cut out smaller files and clean them
    timewindows = iceweb.get_timewindow(enum, nummins, snum);
    for count = 1:length(timewindows.start)
        hh = datestr(timewindows.start(count),'HH');
        mm = datestr(timewindows.start(count),'MM'); 
        filetime = datestr(timewindows.start(count),'yyyymmdd-HHMM');
        fileendtime = datestr(timewindows.stop(count),'yyyymmdd-HHMM');        
        wavcleanmat = fullfile(products.subnetdir, filedate, sprintf('%s_%s_%s_clean.mat',subnetName,filetime,fileendtime));
        
        % Save the cleaned waveform data to MAT file
        if ~exist(wavcleanmat,'file')
            if exist('wday','var')
                fprintf('Waveform file %s not found\n',wavcleanmat);
                fprintf('but day waveform object already in memory and stored at %s\n',wavdaymat);
                w = extract(wday, 'time',timewindows.start(count), timewindows.stop(count)); 
                
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

%                 % Pad all waveforms to same start/end
%                 [wsnum wenum] = gettimerange(w); % assume gaps already filled, signal
%                 w = pad(w, timewindows.start(count), timewindows.stop(count), 0);

                wavdir = fileparts(wavcleanmat);
                if ~exist(wavdir,'dir')
                    mkdir(wavdir);
                end

                debug.print_debug(1,sprintf('Saving waveform data to %s',wavcleanmat));

                % save waveform?
                if ~products.removeWaveformFiles
                    save(wavcleanmat,'w');   
                end

            else
                error('Something went wrong')
            end
        else
            fprintf('%s already exists\n',wavcleanmat);
        end
    end

    debug.printfunctionstack('<');
end