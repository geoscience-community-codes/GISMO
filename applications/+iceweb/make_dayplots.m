function make_dayplots(products, subnetName, snum, enum, ChannelTagList)
    
% MAKE_DAYPLOTS
%   make_dayplots(products, snum, enum) make daily summary plots for each
%   day from snum to enum (the start and end datenum)

    debug.printfunctionstack('>');

    %% Daily plots

    flptrn = fullfile(products.subnetdir,'YYYY-MM-DD','spdata.NSLC.YYYY.MM.DD.max');

    for snumday=floor(snum):ceil(enum-1)
        enumday = snumday+1-1/86400;
        filedate = datestr(snumday,'yyyy-mm-dd');
        
        % next day if we found no data for this day with dayfiles2smallfiles
        wavdaylock = fullfile(products.subnetdir, filedate, sprintf('%s_%s_day.lock',subnetName,filedate));
        if exist(wavdaylock, 'file')
            continue
        end        
        
        % check there is underlying data for this day, if not skip to next
        % day
        daydir = fullfile(products.subnetdir,filedate);
        if ~exist(daydir, 'dir')
            continue
        end
        
        % DAILY SPECTROGRAMS
        if products.daily.spectrograms
            daysgrampng = fullfile(products.subnetdir,filedate,sprintf('daily_sgram_%s.png',filedate));
            if ~exist(daysgrampng, 'file')
                close all
                iceweb.plot_day_spectrogram('', flptrn, ChannelTagList, snumday, enumday);                 
                fig = get(groot,'CurrentFigure');
                if ~isempty(fig)          
                    print('-dpng',daysgrampng);
                    fprintf('Saved %s\n',daysgrampng);
                    close
                end
            end
        end

        % RSAM plots for max, mean, median
        if products.daily.rsamplots
            filepattern = fullfile(products.subnetdir,'SSSS.CCC.YYYY.MMMM.060.bob');
            for k=1:numel(products.rsam.measures )                
                pngfile = fullfile(products.subnetdir,filedate,sprintf('daily_rsam_%s_%s.png',products.rsam.measures {k},filedate));
                if ~exist(pngfile, 'file')
                    close all
                    iceweb.daily_rsam_plot(filepattern, snumday, enumday, ChannelTagList, products.rsam.measures{k});                
                    fig = get(groot,'CurrentFigure');
                    if ~isempty(fig)          
                        print('-dpng',pngfile);
                        fprintf('Saved %s\n',pngfile);
                        close
                    end
                end               
            end
        end

        % SPECTRAL METRICS PLOTS
        if products.daily.spectralplots & products.spectral_data.doit
            measures = {'findex';'fratio';'meanf';'peakf'};
            filepattern = fullfile(products.subnetdir,'SSSS.CCC.YYYY.MMMM.bob');
            for k=1:numel(measures)                
                pngfile = fullfile(products.subnetdir, filedate, sprintf('daily_%s_%s.png',measures{k},filedate));
                if ~exist(pngfile, 'file')
                    close all
                    iceweb.daily_rsam_plot(filepattern, snumday, enumday, ChannelTagList, measures{k});               
                    fig = get(groot,'CurrentFigure');
                    if ~isempty(fig)          
                        print('-dpng',pngfile);
                        fprintf('Saved %s\n',pngfile);
                        close
                    end
                end         
            end  
        end
        
        % DAILY HELICORDERS
        if products.daily.helicorders
            for ctag = ChannelTagList
                pngfile = fullfile(products.subnetdir, filedate, sprintf('helicorder_%s_%s.png',filedate,ctag.string()));
                if ~exist(pngfile, 'file')
                    [dummy,subnet]=fileparts(products.subnetdir);
                    matfile = fullfile(products.subnetdir, filedate, sprintf('%s_%s_day.mat',subnet,filedate));
                    if exist(matfile, 'file')
                        load(matfile);
                        close all
                        if strcmp(class(w),'waveform')
                            plot_helicorder(w,'mpl',60);
                            fig = get(groot,'CurrentFigure');
                            if ~isempty(fig)          
                                print('-dpng',pngfile);
                                fprintf('Saved %s\n',pngfile);
                                close
                            end
                        end
                    end
                end
            end
        end
        
        
        

    end
    
    %% RSAM plots for the overall time period
        % RSAM plots for max, mean, median
        if products.daily.rsamplots
            %measures = {'max';'mean';'median'};
            measures = {'median'};
            filepattern = fullfile(products.subnetdir,'SSSS.CCC.YYYY.MMMM.060.bob');
            for k=1:numel(measures)
                r=iceweb.daily_rsam_plot(filepattern, floor(snum), ceil(enum-1/3600), ChannelTagList, measures{k});
                pngfile = fullfile(products.subnetdir,sprintf('RSAM_%s_%s_%s.png',measures{k},datestr(snum),datestr(enum)));
                print('-dpng',pngfile);
                %fileexchange.datetickzoom()

                plot_existence(r);

                pngfile = fullfile(products.subnetdir,sprintf('EXISTENCE_%s_%s_%s.png',measures{k},datestr(snum),datestr(enum)));
                print('-dpng',pngfile);
                
            end
        end    


    debug.printfunctionstack('<');
end
%%





