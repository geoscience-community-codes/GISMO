function setup_lite(subnet, snum, enum, setupfile, chanmatch)
    [paths,PARAMS,subnets]=pf2PARAMS(setupfile);
    if ~exist('enum','var')
        enum = snum;
    end
    subnets(1).sites = get_closest_sites(subnets(1).source.longitude, subnets(1).source.latitude, subnets(1).radius, paths.DBMASTER, Inf, snum, enum+1, chanmatch);
    sites = subnets(1).sites;
    save sites.mat sites
    
%     %gismo_datasource = datasource('antelope', dbwfdata);
%     % Add response data (calib only?) for each scnl
%     for k=1:numel(subnets(1).sites)
%         %try
%                 subnets(1).sites(k).response = response_get_from_db(subnets(1).sites(k).channeltag.station, subnets(1).sites(k).channeltag.channel, snum, PARAMS.f, paths.DBMASTER);
%                 % for Sakurajima I get:
%                     % Error using response_get_from_db (line 59)
%                     % Database does not contain a sensor table.
%         %catch
%         %        subnets(1).sites(k).response.calib = NaN;
%         %end
%     end
    %save2mat(sprintf('pf/%s_%s.mat',subnet,datestr(snum,'yyyymmdd')), subnets, paths, PARAMS)
    
    % Replace this whole complicated response thing above with a simple
    % grab for calib value. Not much good for short periods, but who cares?
    % - implemented in closest stations
    
    
    save2mat(sprintf('pf/%s.mat',subnet), subnets, paths, PARAMS)
end

function [paths,PARAMS,subnets]=pf2PARAMS(setupfile)
    debug.printfunctionstack('>')
    
    % create pointer to main parameter file
    [dirname, filename, ext] = fileparts(setupfile);
    if exist(setupfile, 'file')
        setuppf = dbpf(sprintf('%s/%s',dirname,filename));

        % subnets
        subnet_tbl = pfget_tbl(setuppf, 'subnets');
        for c=1:numel(subnet_tbl)
            fields = regexp(subnet_tbl{c}, '\s+', 'split');
            subnets(c).name = fields{1};
            subnets(c).source.latitude = str2double(fields{2});
            subnets(c).source.longitude = str2double(fields{3});
            subnets(c).radius = str2double(fields{4});
            subnets(c).use = str2double(fields{5});
        end


        % Maximum number of scnls to display in a spectrogram
        PARAMS.max_number_scnls = pfget_num(setuppf, 'max_number_scnls');

        % Select channels to use according to this channel mask
        PARAMS.channel_mask = pfget(setuppf, 'channel_mask');

        % paths (removed from setup.pf file 2013/04/22)
        paths.DBMASTER = pfget(setuppf, 'dbmaster');
        paths.PFS = 'pf';
        paths.spectrogram_plots = 'spectrograms'; 

        % datasource
        try
            datasources = pfget_tbl(setuppf, 'datasources');
            for c=1:numel(datasources)
                fields = regexp(datasources{c}, '\s+', 'split');
                PARAMS.datasource(c).type = fields{1};
                PARAMS.datasource(c).path = fields{2};
                if numel(fields)>2
                    PARAMS.datasource(c).port = fields{3};
                end
            end
        end

        % archive_datasource
        PARAMS.switch_to_archive_after_days = pfget(setuppf, 'switch_to_archive_after_days'); 
        try
            archive_datasources = pfget_tbl(setuppf, 'archive_datasources');
            for c=1:numel(archive_datasources)
                fields = regexp(archive_datasources{c}, '\s+', 'split');
                PARAMS.archive_datasource(c).type = fields{1};
                PARAMS.archive_datasource(c).path = fields{2};
                if numel(fields)>2
                    PARAMS.archive_datasource(c).port = fields{3};
                end
            end
        end
        
        % waveform processing
        lowcut	 = pfget_num(setuppf,'lowcut');
        highcut	 = pfget_num(setuppf,'highcut');
        npoles	 = pfget_num(setuppf,'npoles');
        PARAMS.filterObj = filterobject('b',[lowcut highcut],npoles);

        % Spectrograms
        PARAMS.spectralobject = spectralobject( ...
            pfget_num(setuppf,'nfft'), ...
            pfget_num(setuppf,'overlap'), ...
            pfget_num(setuppf,'max_freq'), ...
            [ pfget_num(setuppf,'blue') pfget_num(setuppf,'red')] ...
        );

        % Derived data
        PARAMS.surfaceWaveSpeed = pfget_num(setuppf,'surfaceWaveSpeed');
        PARAMS.df = pfget_num(setuppf, 'df');
        PARAMS.f = 0:PARAMS.df:50;

        % Alarm system
        PARAMS.triggersForAlarmFraction = pfget_num(setuppf,'triggersForAlarmFraction');

        debug.print_debug(1, 'PARAMS setup OK')
    else
        error(sprintf('%s: parameter file %s.pf does not exist',mfilename, setupfile));
    end
    debug.printfunctionstack('<')
end

function save2mat(RUNTIMEMATFILE, subnets, paths, PARAMS)
    % write pf/tremor_runtime.mat, preserve current version if it already exists
    if exist(RUNTIMEMATFILE, 'file')
        system(sprintf('mv %s %s.%s',RUNTIMEMATFILE,RUNTIMEMATFILE,datestr(now,30)));
    end

    save(RUNTIMEMATFILE, 'subnets', 'paths', 'PARAMS');
end

