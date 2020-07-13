function run_iceweb(PRODUCTS_TOP_DIR, subnetName, ds, ChannelTagList, ...
    snum, enum, nummins, products, calibObjects)
    debug.printfunctionstack('>');
    
    %% Safety checks
    % knock out any rsam timewindows that would result in fewer than 2
    % samples in gulpMinutes
    products.rsam.samplingIntervalSeconds(products.rsam.samplingIntervalSeconds > (nummins*60)/2)=[];
    
    % code assumes 60-s, any other value will break
    products.spectral_data.samplingIntervalSeconds = 60;
    
    %% Directory setup
    % make the directory under which all products will be stored
    networkName = iceweb.get_most_common(ChannelTagList);
    products.subnetdir = fullfile(PRODUCTS_TOP_DIR, networkName, subnetName);
    try
        if ~exist(products.subnetdir,'dir')
            mkdir(products.subnetdir);
        end
    catch
        error(sprintf('Cannot make directory %s',products.subnetdir));
    end

    %% Process waveform data in chunks nummins long from start time to end time
    
    % if end time empty, make it UTC time now
    if enum==0
        enum = iceweb.utnow - delaymins/1440;
    end
    
    % generate list of timewindows
    timewindows = iceweb.get_timewindow(enum, nummins, snum);
    disp(sprintf('Planning to run IceWeb from %s to %s in (%d x) %d minute chunks',datestr(snum),datestr(enum),length(timewindows.start),nummins));
      
      
    % loop over timewindows
    for count = 1:length(timewindows.start)
        hh = datestr(timewindows.start(count),'HH');
        mm = datestr(timewindows.start(count),'MM');
        if strcmp(hh,'00') && strcmp(mm, '00') || count==1
            fprintf('\n%s ',datestr(timewindows.start(count),26));
            % if the datasource is day files, let's create smaller waveform files
            % here so we aren't reloading the same 1-day files over and over (they
            % take a long time)
                iceweb.dayfiles2smallfiles(networkName, ...
                    subnetName, ChannelTagList, floor(timewindows.start(count)), ...
                    ceil(timewindows.stop(count)), ds, products, calibObjects, nummins); 
            
        end
        if strcmp(mm,'00')
            fprintf('%s ',hh);
        end
        iceweb.process_timewindow(networkName, ...
            subnetName, ChannelTagList, timewindows.start(count), ...
            timewindows.stop(count), ds, products, calibObjects);

    end
    disp('IceWeb loop over 10-minute timewindows is complete');


    %%
    disp('IceWeb completed run');
    debug.printfunctionstack('<');
end
%%





