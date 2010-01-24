function w = loadsac(w, filename)
%LOADSAC  creates a waveform from a SAC file
% waveform = loadsac(waveform, filename);
% To call, the first argument must be a waveform.  However this waveform
% will never be accessed-- it will be overwritten by the SAC information.
% Therefore, you can use "waveform" as your first argument, so that a
% generic waveform object will be created for you
%
% If the filename is a cell of several SAC file names, such as:
% fn = {'BOB.SHZ.AV','TOM.EHZ.AV','HARRY.EHZ.AV'}
% then, w = loadsac(waveform,fn) will return a matrix of waveforms, the
% same size and shape  as fn.   fn(N,M) will be the SAC file name for the
% waveform denoted by w(N,M).  In the example above, loadsac will return a
% 1x3 waveform object, with all three files.
%
% Programming suggestion—select files using a dialog box, by using the
% following code:
%   % display the dialog box used for selecting files, and
%   % allow for multiple selections
%   [f,d] = uigetfile({'*.*','all Files (*.*)'}, 'MultiSelect', 'on');
%
%   % f will have one or more file names, so concatenate them
%   % with the directory
%   filename = strcat(d,f);
%
%   %call loadsac to load all these files into waveform objects
%   w = loadsac(waveform, filename);
%
% The SAC header is parsed out, with the following equivelent fields used
% by waveform:
% _waveform_ 	_sac_
% STATION		KSTNM
% CHANNEL		KCMPNM
% FREQUENCY		1 / DELTA (ODELTA is not used)
% START			NZYEAR, NZJDAY, NZHOUR, NZMIN, NZSEC, NZMSEC, B
% UNITS			IDEP is parsed.  IUNK becomes "Counts"
% All header fields with values - that is, header fields that do not
% contain the value  -12345 (either numeric or text) - are put into
% user-defined fields within the waveform.
% These fields can then be accessed via get/set.  User-defined fields
% does not include those that are parsed into waveform's predefined  fields
%
% For more information about the SAC header, and the interpretation of the
% fields, check out Lawrence Livermore's web site.  Search for "seismic
% sac" and you'll find it.
%
% -------------------------------------------------------------------------
% The functionality of loadsac has been redistributed to the datasource
% class.  This will allow greater flexibility in traversing directory/file
% structures and loading arbitrary time-ranges from the SAC files.
% -------------------------------------------------------------------------
%
%  Here are examples of loading sac files using the datasource class
%  sacfile of interest: "2008/myfile.MSOM.035.sac"
%
% % here is a datasource that finds files such as:"2008/myfile.MSOM.035.sac"
% ds = datasource('sac',...        % type of data
%    '%04d/myfile.%s.%03d.sac',... % filename described in sprintf terms
%    'year','station','jday');     % used to determine filename at runtime
%
% %  and here is a datasource tied to a specific file
% ds2 = datasource('sac','specificpath/specificfilename');
%
% %     Here's a scnlobject filled with wildcards, 
% %     that will grab any station or channel
% anyscnl = scnlobject('*','*','*','*');  
%
% %     and here's one that is specific to our station of interest
% scnl = scnlobject('MSOM','BHZ','AV'); %% specific station 
%
% % load any station for a timespan of interest 
% w = waveform(ds,anyscnl,'2/4/2008 04:40','2/4/2008 04:53');
%    or
% % load our specific sacfile, making sure to grab the whole thing
% w = waveform(ds2,anyscnl,'1/1/2000','12/31/2009');

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 3/14/2009
warning('Waveform:loadsac:OldUsage',...
  ['For more flexability, please use the waveform function\n'...
  '  with a datasource object.\n']);
w = load_sac(filename);