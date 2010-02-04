function w = ideas2waveform(fileName)

%OPEN_INFRASOUND Open UAF/GI infrasound data as a waveform object.
% [W] = OPEN_INFRASOUND(FILENAME) opens a file in the UAF/GI infrasound
% format. FILENAME should be quoted and be in .mat format. The contents of
% the infrasound data are then parsed into a waveform object.
%   Example:
%       w = open_infrasound('FAI200908205.mat')

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



if ~exist(fileName)
    error(['file ' fileName ' does not exist.']);
end

load(fileName);
w = waveform;

for n = 1:size(data,2)
    startTime = datenum([micHeader(n).date ' ' micHeader(n).time]);
    w(n) = waveform( micHeader(n).station , micHeader(n).channel , micHeader(n).Hz , startTime , CSS.calib(n)*data(:,n) );
    w(n) = set(w(n),'UNITS','Pa');
    w(n) = addfield(w(n),'LAT',CSS.lat(n));
    w(n) = addfield(w(n),'LON',CSS.lon(n));
    w(n) = addfield(w(n),'DNORTH',CSS.dnorth(n));
    w(n) = addfield(w(n),'DEAST',CSS.deast(n));
    w(n) = addfield(w(n),'ELEV',CSS.elev(n));
    w(n) = addfield(w(n),'DESCRIP',CSS.descrip(n,:));
    w(n) = addfield(w(n),'STANAME',CSS.staname(n,:));
    w(n) = addfield(w(n),'EDEPTH',CSS.edepth(n));
    w(n) = addfield(w(n),'REFSTA',CSS.refsta(n,:));
    w(n) = addfield(w(n),'CALIB',CSS.calib(n));
    w(n) = addfield(w(n),'ONDATE',CSS.ondate(n));
    w(n) = addfield(w(n),'OFFDATE',CSS.offdate(n));
end
    
    
    



