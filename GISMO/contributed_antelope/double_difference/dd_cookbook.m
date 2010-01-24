

%% HypoDD cross correlation toolbox 
% This toolbox of programs carries out waveform cross-correlation on picked
% P and S phases to generate date suitable for inclusion in the hydoDD
% program. This is a high level toolbox designed to be fast and
% user-friendly. To accomplish this, it requires that a number of other
% toolboxes be in place already. Known dependencies include:
%       Antelope toolbox
%       waveform toolbox
%       correlation toolbox
%       epoch2datenum.m

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% TODO: This cookbook looks incomplete?

%% Data sources
% This toolbox is hardwired to data from Antelope databases. This includes
% origins, phase arrival and waveform data. All tables should be accessible
% via a single database. If you are combining databases, use the descriptor
% file to bring the relevant tables into a single database. At a minimum
% this database muxt include the following tables:
%       origin
%       event
%       assoc
%       arrival
%       wfdisc
% It is expected that this database contain only the events that you wish
% to include in the double difference relocation. In other words, all
% events in this database are included in the calculations. It is best to
% perform any subsets or concatonations in the Antelope environment before
% using this toolbox.


%% Creating an 'SCP' file
% Cross correlation is carried out on waveforms of common station, channel
% and phase pick. Some parameters, such as trace window length and
% filtering, may be adjusted differently for different stations. This is
% accomplished in what we refer to as the SCP file. This simple file
% contains all station/channel/phase combinations that actually appear in
% the given database. In is the input file which controls the subsequent
% cross correlation process. The function DD_MAKE_SCP creates a nominal
% version of this file. So long as the general format is not changed, it is
% designed to be hand edited to account for different processing among
% channels. In the following examples, we are using a database named
% 'dbclust'. Details on DD_MAKE_SCP can be found with HELP DD_MAKE_SCP. One
% feature to note however is the ability to specify a preferred horizontal
% component. Catalog data might be picked on either 'E' of 'N' components.
% DD_MAKE_SCP allows collapses these picks onto a single horizontal channel
% for cross correlation, as specified in the function. This only applies to
% 'E' and 'N' components. Picks on different types of channel, for example
% BNE and HHE are not combined. In most cases concurrent picks on different
% types of data channels will not occur. If they however, DD_MAKE_SCP
% provides a good way to check of this.

dd_make_scp('dbclust')


