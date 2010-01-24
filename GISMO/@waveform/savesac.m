function w = savesac(w, direc, fname)
%SAVESAC  creates a SAC file from a waveform
% savesac(waveform)   saves a waveform to a sac file in the
% current directory, with a default filename as described below.
%
% savesac(waveform, directory)  saves the  sac file in the
% provided directory, but with default filenames as described below.
%
% savesac(waveform, directory, filename)   saves a sac file
% based upon the waveform(s).  The number of filenames (given as CELLS)
% must equal the number of waveform objects to save.
%
% If filename is left out, a default filename will be generated for each
% SAC file.  The default name will be
%   YYYYMMDD_HHmmss.STATION.CHANNEL.NETWORK
%   if the network does not exist in the waveform (in User defined field
%   KNETWK, which is the standard SAC field for this), then network as
%   defined in the filename becomes '__';
%   For example:
%    for waveform COLA(BHZ) starting 1/5/2007 04:03:21.32 ,AK network -->
%       20070105_040321.COLA.BHZ.AK
%    for waveform COLA(BHZ) starting 1/5/2007 04:03:21.32 ,no network -->
%       20070105_040321.COLA.BHZ.__
%
% w = savesac(w...) will add history to the waveform showing into which
% file the waveform was written.
%
% The waveform object is parsed out and placed into the sac header, with
% the following equivalent fields set.  That is, the SAC field is replaced
% with the waveform based values.
% _waveform_ 	_sac_
% STATION		KSTNM
% CHANNEL		KCMPNM
% FREQUENCY		1 / DELTA (ODELTA is not used)
% START			NZYEAR, NZJDAY, NZHOUR, NZMIN, NZSEC, NZMSEC
% UNITS			IDEP (but with caveats.  See SAC header info from llanl)
%
%
% savesac uses routines developed by Mike Thorn and modified by yours
% truly,  stored in the @waveform/private/ directory.
%
% For more information about the SAC header, and the interpretation of the
% fields, check out Lawrence Livermore's web site.  Search for "seismic
% sac" and you'll find it.
%


% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 9/2/2009

if exist('fname') && ~iscell(fname), 
  fname = {fname}; 
end

if nargin == 1
  %place file in current directory
  direc = pwd;
end
if nargin== 3
  %filename has been specified.
  if numel(w) ~= numel(fname) %but not one file per waveform...
    error('Waveform:savesac:badFilenameCount',...
      'Incorrect number of filenames (%d) for (%d) waveforms', ...
      numel(fname), numel(w));
  end
else % nargin ~= 3
  %filenames are to be generated automatically.
  %Format: YYYYMMDD_HHmmss.STATION.CHANNEL.NETWORK
  for n=1:numel(w)
    [Y,M,D,h,m,s] = datevec(get(w(n),'start'));
    Net = get(w(n),'KNETWK'); %get network from existing sac info.
    if isempty(Net)
      Net = '__';
    end
    
    fname(n) = {sprintf('%04d%02d%02d_%02d%02d%02d.%s.%s.%s',...
      Y,M,D,h,m,fix(s), ...
      get(w(n),'station'),get(w(n),'channel'), Net)};
  end
end

%ensure we're working with cells for consistency
if ~iscell(fname)
  fname = {fname};
end

disp('Warning: if dates have been changed within the waveform object,');
disp('these changes will not be reflected within any SAC file picks');
disp('That is, a change to the waveform starting time-- by subsetting,');
disp('extracting, or by use of SET-- will only be reflected in NZHOUR,');
disp('NZJDAY, NZMIN, NZMSEC, NZSEC, and NZYEAR');

for n=1: numel(w) %fname is a cell array
  %first column of SAC is times, seocond is data. third will be header
  sacHeader = waveform2sacheader(w(n));
  outputFileName = fullfile(direc,fname{n});
  writesac(outputFileName,sacHeader, get(w,'data'));
  w(n) = addhistory(w(n),'Saved SAC file as: %s',outputFileName);
end