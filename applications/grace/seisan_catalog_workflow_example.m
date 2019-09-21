% This workflow is an example of how to load Seisan S-files, read in any
% amplitude-energy-frequency metrics that already exist in S-files or AEF
% files, load in the corresponding WAV files, and then do some simple
% things for each event like
%      plot seismograms
%      plot amplitude information from ampengfft
%      plot energy information from ampengfft
%      fit a regression line to energy vs amplitude data
clc, close all, clear all
SEISAN_DATA='/Users/thompsong/Documents/MATLAB/gdrive/data/Montserrat/seismo';
dirseisan = fullfile(SEISAN_DATA, 'REA', 'MVOE_');
ls(dirseisan)
catobj = Catalog.retrieve('seisan', ...
    'dbpath', dirseisan, ...
	'startTime', '2001/02/10 00:30:00', ...
	'endTime', '2001/02/10 00:33:00' );
%%
catobj = catobj.addwaveforms()
%%
% plot waveforms
for eventnum=1:catobj.numberOfEvents
    plot_panels(catobj.waveforms{eventnum})
end
%%
% plot amplitudes
for eventnum=1:catobj.numberOfEvents
    figure
    amp = catobj.aef{eventnum}.amp;
    x = 1:numel(amp);
    semilogy(x,amp,'o')
    xticklabels = {};
    for ctagnum=1:numel(catobj.aef{eventnum}.ctag)
        xticklabels{ctagnum}=catobj.aef{eventnum}.ctag(ctagnum).string();
    end
    set(gca,'XTick',x,'XTickLabel',xticklabels,'XTickLabelRotation',90)  
    xlabel('NET.STA.LOC.CHAN')
    ylabel('Amplitude m/s')
end
%%
% plot energy
for eventnum=1:catobj.numberOfEvents
    figure
    eng = catobj.aef{eventnum}.eng;
    x = 1:numel(eng);
    semilogy(x,eng,'o')
    xticklabels = {};
    for ctagnum=1:numel(catobj.aef{eventnum}.ctag)
        xticklabels{ctagnum}=catobj.aef{eventnum}.ctag(ctagnum).string();
    end
    set(gca,'XTick',x,'XTickLabel',xticklabels,'XTickLabelRotation',90)  
    xlabel('NET.STA.LOC.CHAN')
    ylabel('Energy')
end
%%
for eventnum=1:catobj.numberOfEvents
    catobj.regress_energy_vs_amplitude(eventnum)
end
%%
catobj.regress_energy_vs_amplitude_all()
%%
for eventnum=1:catobj.numberOfEvents
    figure
    catobj.waveforms{eventnum} = addmetrics(catobj.waveforms{eventnum});
    w = catobj.waveforms{eventnum};
    ctags = get(w,'ChannelTag');
    m = get(w,'metrics');
    for c=1:numel(m)
        amp(c) = max([m{c}.maxAmp -m{c}.minAmp]);
    end
    x = 1:numel(amp);
    semilogy(x,amp,'o')
    xticklabels = {};
    for ctagnum=1:numel(ctags)
        xticklabels{ctagnum}=ctags(ctagnum).string();
    end
    set(gca,'XTick',x,'XTickLabel',xticklabels,'XTickLabelRotation',90)  
    xlabel('NET.STA.LOC.CHAN')
    ylabel('Amplitude m/s')
    
end

