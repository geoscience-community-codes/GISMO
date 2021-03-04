function overview_plots(products, subnetName, snum, enum, ChannelTagList)
% OVERVIEW_PLOTS
%   OVERVIEW_PLOTS(products, subnetName, snum, enum, ChannelTagList) make daily summary plots for each
%   day from snum to enum (the start and end datenum)
    debug.printfunctionstack('>');

    spmeasures = {'findex';'fratio';'meanf';'peakf'};
    spylabels = {sprintf('Frequency Index\n(Buurman and West, 2010)'); ...
        sprintf('Frequency Ratio\nRodgers et al., 2015'); ...
        'Mean Frequency (Hz)'; ...
        'Peak Frequency (Hz)'};


    % RSAM plots for max, mean, median
    if products.daily.rsamplots
        measures = products.rsam.measures;
        filepattern = fullfile(products.subnetdir,'SSSS.CCC.YYYY.MMMM.060.bob');
        for k=1:numel(measures)
            pngfile = fullfile(products.subnetdir,sprintf('RSAM_%s_%s_%s.png',measures{k},datestr(snum,'yyyy-mm-dd'),datestr(enum,'yyyy-mm-dd')));
            if ~exist(pngfile, 'file')
                r=iceweb.daily_rsam_plot(filepattern, floor(snum), ceil(enum-1/3600), ChannelTagList, measures{k});
                print('-dpng',pngfile);
                plot_existence(r);
                pngfile = fullfile(products.subnetdir,sprintf('EXISTENCE_%s_%s_%s.png',measures{k},datestr(snum,'yyyy-mm-dd'),datestr(enum,'yyyy-mm-dd')));
                print('-dpng',pngfile);
            end
        end
    end

    if products.daily.spectralplots & products.spectral_data.doit
        filepattern = fullfile(products.subnetdir,'SSSS.CCC.YYYY.MMMM.bob');
        for k=1:numel(spmeasures)
            pngfile = fullfile(products.subnetdir, sprintf('SPECTRAL_%s_%s_%s.png',spmeasures{k},datestr(snum,'yyyy-mm-dd'),datestr(enum,'yyyy-mm-dd')));
            if ~exist(pngfile, 'file')
                close all
                iceweb.daily_rsam_plot(filepattern, floor(snum), ceil(enum-1/3600), ChannelTagList, spmeasures{k});
                fig = get(groot,'CurrentFigure');
                if ~isempty(fig)
                    ylabel(spylabels{k});
                    print('-dpng',pngfile);
                    fprintf('Saved %s\n',pngfile);
                    close
                end
            end
        end
    end


    % Spectrogram, spectrum and SSAM plots for Z channels only
    cc = 0;
    for c=1:numel(ChannelTagList)
        if strcmp(ChannelTagList(c).channel, 'HHZ')
            cc = cc + 1;
            ctags(cc)=ChannelTagList(c);
        end
    end
    if exist('ctags','var')
        if numel(ctags)>1
            fullsgram(products, snum, enum, ctags)
        end
    else
        disp('no ctags')
    end

    debug.printfunctionstack('<');
end
%%



function fullsgram(products, snum, enum, ChannelTagList)
    sgrampng = fullfile(products.subnetdir,sprintf('SGRAM_%s_%s.png',datestr(snum,'yyyy-mm-dd'),datestr(enum,'yyyy-mm-dd')));
    if ~exist(sgrampng, 'file')
        close all
        flptrn = fullfile(products.subnetdir,'YYYY-MM-DD','spdata.NSLC.YYYY.MM.DD.amplitude');
        %flptrn = fullfile(products.subnetdir,'YYYY-MM-DD','spdata.NSLC.YYYY.MM.DD.energy');
        iceweb.plot_day_spectrogram('', flptrn, ChannelTagList, snum, enum, 'plot_spectrum',true,'plot_SSAM',true);
        fig = get(groot,'CurrentFigure');
        if ~isempty(fig)
            ssampng = fullfile(products.subnetdir,sprintf('ssam_%s_%s.png',datestr(snum,'yyyy-mm-dd'),datestr(enum,'yyyy-mm-dd')));
            print('-dpng','-f3',ssampng);
            fprintf('Saved %s\n',ssampng);
         
            spectrumpng = fullfile(products.subnetdir,sprintf('spectrum_%s_%s.png',datestr(snum,'yyyy-mm-dd'),datestr(enum,'yyyy-mm-dd')));
            print('-dpng','-f2',spectrumpng);
            fprintf('Saved %s\n',spectrumpng);
            
            print('-dpng','-f1',sgrampng);
            fprintf('Saved %s\n',sgrampng);
           
        end
    end
    close all
end