function make_dayplots(products, subnetName, snum, enum, ChannelTagList)
% MAKE_DAYPLOTS
%   make_dayplots(products, snum, enum) make daily summary plots for each
%   day from snum to enum (the start and end datenum)
    debug.printfunctionstack('>');

    spmeasures = {'findex';'fratio';'meanf';'peakf'};
    spylabels = {sprintf('Frequency Index\n(Buurman and West, 2010)'); ...
        sprintf('Frequency Ratio\nRodgers et al., 2015'); ...
        'Mean Frequency (Hz)'; ...
        'Peak Frequency (Hz)'};

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
                flptrn = fullfile(products.subnetdir,'YYYY-MM-DD','spdata.NSLC.YYYY.MM.DD.amplitude');
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
                pngfile = fullfile(products.subnetdir,filedate,sprintf('daily_rsam_%s_%s.png',products.rsam.measures{k},filedate));
                if ~exist(pngfile, 'file')
                    close all
                    iceweb.daily_rsam_plot(filepattern, snumday, enumday, ChannelTagList, products.rsam.measures{k});
                    fig = get(groot,'CurrentFigure')
                    if ~isempty(fig)
                        try
                            print('-dpng',pngfile);
                            fprintf('Saved %s\n',pngfile);
                            close
                        catch ME
                            warning(ME.message)
                        end
                    end
                end
            end
        end

        % SPECTRAL METRICS PLOTS
        if products.daily.spectralplots & products.spectral_data.doit
            filepattern = fullfile(products.subnetdir,'SSSS.CCC.YYYY.MMMM.bob');
            for k=1:numel(spmeasures)
                pngfile = fullfile(products.subnetdir, filedate, sprintf('daily_%s_%s.png',spmeasures{k},filedate));
                %if ~exist(pngfile, 'file')
                close all
                iceweb.daily_rsam_plot(filepattern, snumday, enumday, ChannelTagList, spmeasures{k});
                fig = get(groot,'CurrentFigure');
                if ~isempty(fig)
                    ylabel(spylabels{k});
                    print('-dpng',pngfile);
                    fprintf('Saved %s\n',pngfile);
                    close
                end
                %end
            end
        end

        % DAILY HELICORDERS
        if products.daily.helicorders
            [dummy,subnet]=fileparts(products.subnetdir);
            matfile = fullfile(products.subnetdir, filedate, sprintf('%s_%s_day.mat',subnet,filedate));
            if exist(matfile, 'file')
                load(matfile);
                if strcmp(class(w),'waveform')
                    for c=1:numel(w)
                        chaninfo=get(w(c),'channelinfo');
                        pngfile = fullfile(products.subnetdir, filedate, sprintf('helicorder_%s_%s.png',filedate,chaninfo));
                        if ~exist(pngfile, 'file')
                            close all
                            plot_helicorder(w(c),'mpl',60);
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


    debug.printfunctionstack('<');
end
%%





