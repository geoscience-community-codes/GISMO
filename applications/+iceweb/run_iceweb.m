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
    products_dir = fullfile(PRODUCTS_TOP_DIR, networkName, subnetName);
    try
        if ~exist(products_dir,'dir')
            mkdir(products_dir);
        end
    catch
        error(sprintf('Cannot make directory %s',products_dir));
    end

    %% Process waveform data in chunks nummins long from start time to end time
    
    % if end time empty, make it UTC time now
    if enum==0
        enum = iceweb.utnow - delaymins/1440;
    end
    
    % generate list of timewindows
    timewindows = iceweb.get_timewindow(enum, nummins, snum);
    disp(sprintf('Planning to run IceWeb from %s to %s in (%d x) %d minute chunks',datestr(snum),datestr(enum),length(timewindows.start),nummins));
      
%     % loop over timewindows
%     for count = 1:length(timewindows.start)
%         hh = datestr(timewindows.start(count),'HH');
%         mm = datestr(timewindows.start(count),'MM');
%         if strcmp(hh,'00') && strcmp(mm, '00') || count==1
%             fprintf('\n%s ',datestr(timewindows.start(count),26));
%         end
%         if strcmp(mm,'00')
%             fprintf('%s ',hh);
%         end
%         iceweb.process_timewindow(products_dir, networkName, ...
%             subnetName, ChannelTagList, timewindows.start(count), ...
%             timewindows.stop(count), ds, products, calibObjects);
% 
%     end
    
    %% Daily plots
    close all

%     flptrn = fullfile(products_dir,'YYYY-MM-DD','spdata.NSLC.YYYY.MM.DD.max');
% 
%     for snumday=floor(snum):ceil(enum-1)
%         enumday = ceil(enum)-eps;
% 
%         % DAILY SPECTROGRAMS
%         if products.daily.spectrograms
%             iceweb.plot_day_spectrogram('', flptrn, ChannelTagList, snumday, enumday);
%             dstr = datestr(snumday,'yyyy-mm-dd');
%             daysgrampng = fullfile(products_dir,dstr,sprintf('daily_sgram_%s.png',dstr));
%             print('-dpng',daysgrampng);
%             close
%         end
% 
%         % RSAM plots for max, mean, median
%         if products.daily.rsamplots
%             measures = {'max';'mean';'median'};
%             filepattern = fullfile(products_dir,'SSSS.CCC.YYYY.MMMM.060.bob');
%             for k=1:numel(measures)
%                 iceweb.daily_rsam_plot(filepattern, snumday, enumday, ChannelTagList, measures{k});
%                 pngfile = fullfile(products_dir,dstr,sprintf('daily_rsam_%s_%s.png',measures{k},dstr));
%                 print('-dpng',pngfile);
%                 close
%             end
%         end
% 
%         % SPECTRAL METRICS PLOTS
%         if products.daily.spectralplots
%             measures = {'findex';'fratio';'meanf';'peakf'};
%             filepattern = fullfile(products_dir,'SSSS.CCC.YYYY.MMMM.bob');
%             for k=1:numel(measures)
%                 iceweb.daily_rsam_plot(filepattern, snumday, enumday, ChannelTagList, measures{k});
%                 pngfile = fullfile(products_dir, dstr, sprintf('daily_%s_%s.png',measures{k},dstr));
%                 print('-dpng',pngfile);
%                 close
%             end  
%         end
%         
%         % DAILY HELICORDERS
%         if products.daily.helicorders
%             % add code here
%         end
%         
%         
%         
% 
%     end
    
    %% overall plots
        % RSAM plots for max, mean, median
        if products.daily.rsamplots
            %measures = {'max';'mean';'median'};
            measures = {'max'};
            filepattern = fullfile(products_dir,'SSSS.CCC.YYYY.MMMM.060.bob');
            for k=1:numel(measures)
                r=iceweb.daily_rsam_plot(filepattern, floor(snum), ceil(enum-1/3600), ChannelTagList, measures{k});
                pngfile = fullfile(products_dir,sprintf('overall_rsam_%s.png',measures{k}));
                print('-dpng',pngfile);
                %fileexchange.datetickzoom()
                
                i=input('enter to continue')
                close
                save
                
                % existence plot
                N = numel(r);
                for counter=1:N
                    r2(counter)=r(counter);
                    data = r2(counter).data;
                    data(~isnan(data))=1;
                    data(isnan(data))=0;
                    data(2:2:end)=data(2:2:end)*-1.0;
                    r2(counter).data = data;
                end
                
                r2.plot_panels()
                pngfile = fullfile(products_dir,sprintf('existence_rsam_%s.png',measures{k}));
                print('-dpng',pngfile);
                
            end
        end    

    %%
    disp('IceWeb completed run');
    debug.printfunctionstack('<');
end
%%





