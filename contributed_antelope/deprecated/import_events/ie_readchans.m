function chanlist = ie_readchans(chanfile)
%IE_READCHANS Read and parse station/channel list from file
% CHANLIST = IE_READCHANS(CHANFILE) returns a string cell array of stations
% and their associated channels, read from comma-delimited input filename CHANFILE.
% Each line of CHANFILE should contain up to four fields: a station name in
% the first column, then either one or three channel names in the
% subsequent columns.  Lines beginning with the percent sign % are ignored.
%
% IE_READCHANS performs some basic error checking on the input file, but
% does not compare against any database or other listing of station data.
% This is left up to the user.
%
% EXAMPLE
%
% Suppose CHANFILE points to the following file:
%
% % Stations and channels of interest in Uturuncu data set
% UTCA,SHZ,SHN,SHE
% UTCM,SHZ,,
% %UTKH,BHZ,BHN,BHE
% %UTLA2,SHZ,SHN,SHE
% UTSW,SHZ,SHN,SHE
%
% Then IE_READCHANS will return:
%
% ans = 
%     'UTCA'    'SHZ'    'SHN'    'SHE'
%     'UTCM'    'SHZ'       ''       ''
%     'UTSW'    'SHZ'    'SHN'    'SHE'
%
% Author: Christopher Bruton, Geophysical Institute, University of Alaska Fairbanks
% $Date$
% $Revision$

	[fp, message] = fopen(chanfile,'r'); % Open the file
	
	if fp < 0 % Could not open the file
		error(['Could not open file ' chanfile ': ' message]);
	end
	
	% The following seems to be the best way to read a CSV file of text.
	% csvread() can only handle numeric data.
	filecontents = textscan(fp,'%s %s %s %s','Delimiter',',','ReturnOnError',false,'CommentStyle','%');
	
	fclose(fp); % Close file handle
	
	% Concatenate into one cell array
	chanlist = cat(2,filecontents{:});
	
	% Run some mechanical checks
	
	for n = 1:size(chanlist,1)
		% Empty station?
		if isempty(chanlist{n,1})
			error(['Empty station on line ' num2str(n) ' of input file ' chanfile]);
		end
		
		% Number of empty channels
		n_empty = 0;
		for c = 2:4
			if isempty(chanlist{n,c})
				n_empty = n_empty + 1;
			end
		end
		
		% Error if we have wrong number of empty channel names
		if (n_empty ~= 2) && (n_empty ~= 0)
			error(['Incorrect number of channels specified on line ' num2str(n) ' of input file ' chanfile '.  Please specify either 1 or 3 channel names.']);
		end
		
		% All channels must have unique names
		if length(unique(chanlist(n,2:4))) ~= (3-(n_empty>0))
			error(['Nonunique channel names specified on line ' num2str(n) ' of input file ' chanfile]);
		end
	end
	
	% All stations must have unique names
	if length(unique(chanlist(:,1))) ~= length(chanlist(:,1))
		error(['Nonunique station names specified in input file ' chanfile]);
	end
	
end