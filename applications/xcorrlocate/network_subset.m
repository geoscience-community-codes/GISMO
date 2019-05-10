function [network] = network_subset(LIST,CT,STA,CHAN)
%NETWORK_SUBSET finds the subset of waveforms that appears on all stations
%within the network. This function is effectively the same as running
%station_subsets then network_compare, however, this computes the final
%subset through elimination rather than a comparison of individual subsets
%on each station. For larger datasets this one is more efficient.
%       Input Arguments:
%           LIST: full path to file containing list of waveforms.
%               Ex: LIST = '/path/to/file.dat' where each line in the file
%               is the name of a sac waveform file. note: the full path to
%               the file must be included (i.e. /path/to/sac/file.sac')
%           CT: correlation threshold for correlating waveforms.
%           recommended using at least 0.7
%           STA: cell array of the station tags in the network
%           CHAN: cell array of the channel tags for each station
%       Output/Example:    
%           Given an initial list of waveforms on one component at a
%           station (TBTN-BHZ) STATION_SUBSETS will give a structured array
%           of the subset that appears on all station on the componenets.
%           Here is an example of looking across 4 stations with 3 components:
%               LIST = '/media/shared/mitch/telica/2012-05-11.dat';
%               CT = 0.7;
%               STA = {'TBTN','TBMR','TBHS','TBHY'};
%               CHAN = {'BHZ','BHN','BHE'};
%               network = network_subsets(LIST,CT,STA,CHAN);
%
%           The output variable "network" is a Multiplet object with
%           properties for channeltag, filepaths to waveforms, and
%           waveform objects. The arrivals are left blank and can be filled
%           with stack_and pick. 

    w = load_waveforms(LIST,'file');
    w = w';
    
    for station = 1:numel(STA)
        for channel = 1:numel(CHAN)
            w = station_replace(w,STA{station},CHAN{channel});
            w = load_waveforms(w,'cellarray');
            w = clip_waveforms(w);
            w = correlate_waveforms(w,CT);
        end
    end
    
    sta_elm = numel(STA);
    chan_elm = numel(CHAN);
    
    % rebuild network array
    i = 1;
    for station = 1:numel(STA)
        for channel = 1:numel(CHAN)
            w2 = strrep(w,STA{sta_elm},STA{station});
            w2 = strrep(w2,CHAN{chan_elm},CHAN{channel});
            w2 = load_waveforms(w2,'cellarray');
            w2 = clip_waveforms(w2);
            f = correlate_waveforms(w2,CT);
            w2 = load_waveforms(f,'cellarray');
            c = ChannelTag('',STA{station},'',CHAN{channel});
            network(i) = Multiplet(c,f,w2);
            i = i + 1;
        end
    end
    

end