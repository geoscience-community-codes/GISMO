function mksac(f,d,varargin)
%MKSAC Write data in SAC format file.
%	MKSAC(FILENAME,D) writes a file FILENAME from data vector D in the 
%	Seismic Analysis Code (SAC) format. But additional options are highly
%	recommended to produce a real consistent seismic file:
%
%	MKSAC(FILENAME,D,T0,H) will use origin time T0 (DATENUM format), and
%	header fields in structure H (as defined by the IRIS/SAC format).
%
%	MKSAC(FILENAME,D,T0,'HEADER1',header1,'HEADER2',header2, ...) is an 
%	alternative to define the header fields.
%
%	MKSAC(FILENAME,D,T,...) where T is a time vector of same size as D,
%	will define DELTA sampling value from the time interval median.
%
%	MKSAC will produce a SAC file in any case, using default values for 
%	any missing header field. But we strongly suggest to define at least 
%	the following header fields:
%	- DELTA (increment between evenly spaced samples, in seconds), default
%	  will be 1 second;
%	- KSTNM (station code), KHOLE (location code), KCMPNM (channel code),
%	  and KNETWK (network code) to define the station component;
%
%	Header field names that are not recognized are ignored, while some will
%	be overwritten in order to keep the file consistency:
%	- NPTS, DEPMIN, DEPMAX, DEPMEN are inferred from data D
%	- NZYEAR, NZJDAY, NZHOUR, NZMIN, NZSEC, NZMSEC are defined from time T0
%	- B is forced to 0, E to the last sample relative time (in seconds)
%	- NVHDR is forced to 6 (header version number)
%
%	Example:
%	   mksac('test.sac',sin(linspace(0,10*pi)),now,'DELTA',1/100,'KSTNM','TEST')
%
%
%	Reference: http://www.iris.edu/files/sac-manual/
%
%	Author: F. Beauducel <beauducel@ipgp.fr>
%	Created: 2015-11-12
%	Updated: 2016-03-05

%	Release history:
%	[2016-03-05] v1.1
%		- fix a problem with date of origin time
%	[2015-11-12] v1.0
%
%	Copyright (c) 2016, François Beauducel, covered by BSD License.
%	All rights reserved.
%
%	Redistribution and use in source and binary forms, with or without 
%	modification, are permitted provided that the following conditions are 
%	met:
%
%	   * Redistributions of source code must retain the above copyright 
%	     notice, this list of conditions and the following disclaimer.
%	   * Redistributions in binary form must reproduce the above copyright 
%	     notice, this list of conditions and the following disclaimer in 
%	     the documentation and/or other materials provided with the 
%	     distribution
%	                           
%	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
%	IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
%	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
%	PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
%	OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
%	LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
%	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
%	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
%	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
%	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if nargin < 2
	error('Not enough input argument.')
end

if nargin < 3
	t0 = now;
else
	t0 = varargin{1};
	if length(t0) > 1
	end
end

if nargin > 3 && isstruct(varargin{2})
	H = varargin{2};
end

if nargin > 4
	for n = 2:2:(nargin-3)
		if ischar(varargin{n})
			try
				H.(varargin{n}) = varargin{n+1};
			catch
				fprintf('Warning: invalid header name "%s" or value.\n',varargin{n});
			end
		end
	end
end

% header default values
H0 = struct('DELTA',1,'NVHDR',6,'IFTYPE',1,'LEVEN',1);
for h = fieldnames(H0)'
	if ~exist('H','var') || ~isfield(H,h{:})
		H.(h{:}) = H0.(h{:});
	end
end

% header origin time values
tv = datevec(t0(1));
H.NZYEAR = tv(1);
H.NZJDAY = datenum(tv(1:3)) - datenum(tv(1),1,1) + 1;
H.NZHOUR = tv(4);
H.NZMIN = tv(5);
H.NZSEC = floor(tv(6));
H.NZMSEC = (tv(6) - H.NZSEC)*1e3;

% other header overwritten fields
H.NPTS = length(d);
H.DEPMIN = min(d);
H.DEPMAX = max(d);
H.DEPMEN = mean(d);
H.B = 0;
H.NVHDR = 6;

% splits KEVNM in 2 bytes
if isfield(H,'KEVNM') && ischar(H.KEVNM) && length(H.KEVNM) == 16
	H.KEVNM0 = H.KEVNM(1:8);
	H.KEVNM1 = H.KEVNM(9:16);
	H = rmfield(H,'KEVNM');
end

fid = fopen(f, 'wb', 'ieee-le');
if fid == -1
	error('Cannot write the data file %s',f);
end

writeheader(fid,H);
fwrite(fid,single(d),'float32');	% writes data as single class

fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeheader(fid,H)

novalue = -12345;

% --- classifies header fields
% floating variables (single)
v = { ...
'DELTA',   'DEPMIN',  'DEPMAX',  'SCALE',  'ODELTA';
'B',       'E',       'O',       'A',      'INTERNAL';
'T0',      'T1',      'T2',      'T3',     'T4';
'T5',      'T6',      'T7',      'T8',     'T9';
'F',       'RESP0',   'RESP1',   'RESP2',  'RESP3';
'RESP4',   'RESP5',   'RESP6',   'RESP7',  'RESP8';
'RESP9',   'STLA',    'STLO',    'STEL',   'STDP';
'EVLA',    'EVLO',    'EVEL',    'EVDP',   'MAG';
'USER0',   'USER1',   'USER2',   'USER3',  'USER4';
'USER5',   'USER6',   'USER7',   'USER8',  'USER9';
'DIST',    'AZ',      'BAZ',     'GCARC',  'INTERNAL';
'INTERNAL','DEPMEN',  'CMPAZ',   'CMPINC', 'XMINIMUM';
'XMAXIMUM','YMINIMUM','YMAXIMUM','UNUSED', 'UNUSED';
'UNUSED',  'UNUSED',  'UNUSED',  'UNUSED', 'UNUSED';
}';

hf = single(repmat(novalue,size(v)));
for n = 1:numel(v)
	if isfield(H,v{n})
		hf(n) = single(H.(v{n}));
	end
end

% integer variables (int32)
v = { ...
'NZYEAR',  'NZJDAY',  'NZHOUR',  'NZMIN',  'NZSEC';
'NZMSEC',  'NVHDR',   'NORID',   'NEVID',  'NPTS';
'INTERNAL','NWFID',   'NXSIZE',  'NYSIZE', 'UNUSED';
'IFTYPE',  'IDEP',    'IZTYPE',  'UNUSED', 'IINST';
'ISTREG',  'IEVREG',  'IEVTYP',  'IQUAL',  'ISYNTH';
'IMAGTYP', 'IMAGSRC', 'UNUSED',  'UNUSED', 'UNUSED';
'UNUSED',  'UNUSED',  'UNUSED',  'UNUSED', 'UNUSED';
}';

hi = int32(repmat(novalue,size(v)));
for n = 1:numel(v)
	if isfield(H,v{n})
		% case of enumerated fields I* that may contain 'Description {N}'
		if strncmp(v{n},'I',1) && ischar(H.(v{n}))
			d = regexp(H.(v{n}),' {(\d*)}','tokens');
			if ~isempty(d{1}{1})
				hi(n) = str2double(d{1}{1});
			end
		end
		if isnumeric(H.(v{n}))
			hi(n) = int32(H.(v{n}));
		end
	end
end

% logical variables (int32)
v = { ...
'LEVEN',   'LPSPOL',  'LOVROK',  'LCALDA', 'UNUSED';
}';

hl = int32(zeros(size(v)));
for n = 1:numel(v)
	if isfield(H,v{n})
		hl(n) = int32(H.(v{n}));
	end
end


% alphanumerical variables (char)
v = { ...
'KSTNM',  'KEVNM0', 'KEVNM1';
'KHOLE',  'KO',     'KA';
'KT0',    'KT1',    'KT2';
'KT3',    'KT4',    'KT5';
'KT6',    'KT7',    'KT8';
'KT9',    'KF',     'KUSER0';
'KUSER1', 'KUSER2', 'KCMPNM';
'KNETWK', 'KDATRD', 'KINST';
}';

hc = char(repmat(sprintf('%-8d',novalue),1,numel(v)));
for n = 1:numel(v)
	if isfield(H,v{n})
		s = char(H.(v{n}));
		if length(s) > 8
			s = s(1:8);
		end
		hc((n-1)*8 + (1:8)) = sprintf('%-8s',s);
	end
end


% writes the header
fwrite(fid,hf,'float32');
fwrite(fid,[hi,hl],'int32');
fwrite(fid,hc','char');

