function [network] = station_subsets(LIST,CT,STA,CHAN)
%STATION_SUBSETS creates a structure array of lists of waveforms that
%correlate above a given threshold on each component within a station. 
%       Input Arguments:
%           LIST: full path to file containing list of waveforms.
%               Ex: LIST = '/path/to/file.dat' where each line in the file
%               is the name of a sac waveform file. note: the full path to
%               the file must be included (i.e. /path/to/sac/file.sac')
%           CT: correlation threshold for correlating waveforms.
%           recommended using at least 0.7
%           STA: cell array of the station tags in the network
%           CHAN: cell array of the channel tags for each station
%       Example:
%           Given an initial list of waveforms on one component at a
%           station (TBTN-BHZ) STATION_SUBSETS will give a structured array
%           of all the subsets on the componenets you give it. Below is an
%           example of looking across 4 stations with 3 components:
%               LIST = '/media/shared/mitch/telica/2012-05-11.dat';
%               CT = 0.7;
%               STA = {'TBTN','TBMR','TBHS','TBHY'};
%               CHAN = {'BHZ','BHN','BHE'};
%               network = station_subsets(LIST,CT,STA,CHAN);
%
%           The output variable "network" will have the structure:
%           network.station.channel
%           Each of the channels contains the list of waveforms that
%           correlate above the given threshold for that respective station
%           and channel. 
%           You can inspect by prompting the array:
%               >>network.TBTN.BHZ
%           Will give the list that correlates above CT on station TBTN
%           channel BHZ
    
    w = load_waveforms(LIST,'file');
    w = w';
    
    i = 1;
    for station = 1:numel(STA)
        for channel = 1:numel(CHAN)
            w2 = station_replace(w,STA{station},CHAN{channel});
            w2 = load_waveforms(w2,'cellarray');
            w2 = clip_waveforms(w2); % clip to match peakmatch corr methods
            f = correlate_waveforms(w2,CT);
            w2 = load_waveforms(f,'cellarray');
            c = ChannelTag('TL',STA{station},'',CHAN{channel});
            network(i) = Multiplet(c,f,w2); % ctag first, filepaths second
            i = i + 1;
        end
    end
    
end