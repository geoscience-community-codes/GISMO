classdef miniseed
   %MINISEED Reads and plots a miniseed file
   % this is very much under construction.
   % based on the rdmseed matlab functions created by 
   % Fran?ois Beauducel <beauducel@ipgp.fr>
         %		Institut de Physique du Globe de Paris
         %
         %	Acknowledgments:
         %		Ljupco Jordanovski, Jean-Marie Saurel, Mohamed Boubacar, Jonathan Berger,
         %		Shahid Ullah, Wayne Crawford, Constanza Pardo, Sylvie Barbier,
         %		Robert Chase, Arnaud Lemarchand.
         %
         %	References:
         %		IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010,
         %		  IFDSN/IRIS/USGS, http://www.iris.edu
         %		Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
         %		Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
         
         %	Copyright (c) 2014, Fran?ois Beauducel, covered by BSD License.
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
         %	     the documentation and/or other materials provided with the distribution
         %
         %	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
         %	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
         %	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
         %	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
         %	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
         %	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
         %	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
         %	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
         %	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
         %	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
         %	POSSIBILITY OF SUCH DAMAGE.
         
         % MODIFIED Oct 2015 by Celso Reyes
   
   properties
      X % structure of blocks, containing headers, blockettes, data
      I % detected channels and additional info fields
   end
   
   properties(Hidden)
      FileName
      offset
      littleEndian
      WordOrder
      
      verbose = 0;	% verbose flag/level
      forcebe = false;	% force big-endian
      ef = 10;		% encoding format default
      wo = true;		% word order default
      rl = 2^12;		% record length default
      force = false;		% force input argument over blockette 1000 (UNDOCUMENTED)
      notc = false;		% force no time correction (over ActivityFlags)
      
   end
   
   methods
      function ms = rdmseed(ms, varargin)
         %RDMSEED Read miniSEED format file.
         %	X = RDMSEED(F) reads file F and returns a M-by-1 structure X containing
         %	M blocks ("data records") of a miniSEED file with headers, blockettes,
         %	and data in dedicated fields, in particular, for each data block X(i):
         %		         t: time vector (DATENUM format)
         %		         d: data vector (double)
         %		BLOCKETTES: existing blockettes (substructures)
         %
         %	Known blockettes are 100, 500, 1000, 1001 and 2000. Others will be
         %	ignored with a warning message.
         %
         %	X = RDMSEED(F,ENCODINGFORMAT,WORDORDER,RECORDLENGTH), when file F does
         %	not include the Blockette 1000 (like Seismic Handler outputs), specifies:
         %		- ENCODINGFORMAT: FDSN code (see below); default is 10 = Steim-1;
         %		- WORDORDER: 1 = big-endian (default), 0 = little-endian;
         %		- RECORDLENGTH: must be a power of 2, at least 256 (default is 4096).
         %	If the file contains Blockette 1000 (which is mandatory in the SEED
         %	convention...), these 3 arguments are ignored except with 'force' option.
         %
         %	X = RDMSEED without input argument opens user interface to select the
         %	file from disk.
         %
         %	[X,I] = RDMSEED(...) returns a N-by-1 structure I with N the detected
         %	number of different channels, and the following fields:
         %	    ChannelFullName: channel name,
         %	        XBlockIndex: channel's vector index into X,
         %	         ClockDrift: vector of time interval errors, in seconds,
         %	                     between each data block (relative to sampling
         %	                     period). This can be compared to "Max Clock Drift"
         %	                     value of a Blockette 52.
         %	                        = 0 in perfect case
         %	                        < 0 tends to overlapping
         %	                        > 0 tends to gapping
         %	  OverlapBlockIndex: index of blocks (into X) having a significant
         %	                     overlap with previous block (less than 0.5
         %	                     sampling period).
         %	        OverlapTime: time vector of overlapped blocks (DATENUM format).
         %	      GapBlockIndex: index of blocks (into X) having a significant gap
         %	                     with next block (more than 0.5 sampling period).
         %	            GapTime: time vector of gapped blocks (DATENUM format).
         %
         %	RDMSEED(...) without output arguments plots the imported signal by
         %	concatenating all the data records, in one single plot if single channel
         %	is detected, or subplots for multiplexed file (limited to 10 channels).
         %	Gaps are shown with red stars, overlaps with green circles.
         %
         %	[...] = RDMSEED(F,...,'be') forces big-endian reading (overwrites the
         %	automatic detection of endianness coding, which fails in some cases).
         %
         %	[...] = RDMSEED(F,...,'notc') disable time correction.
         %
         %	[...] = RDMSEED(F,...,'plot') forces the plot with output arguments.
         %
         %	[...] = RDMSEED(F,...,'v') uses verbose mode (displays additional
         %	information and warnings when necessary). Use 'vv' for extras, 'vvv'
         %	for debuging.
         %
         %	Some instructions for usage of the returned structure:
         %
         %	- to get concatenated time and data vectors from a single-channel file:
         %		X = rdmseed(ms.FileName,'plot');
         %		t = cat(1,X.t);
         %		d = cat(1,X.d);
         %
         %	- to get the list of channels in a multiplexed file:
         %		[X,I] = rdmseed(ms.FileName);
         %		char(I.ChannelFullName)
         %
         %	- to extract the station component n from a multiplexed file:
         %		[X,I] = rdmseed(ms.FileName);
         %		k = I(n).XBlockIndex;
         %		plot(cat(1,X(k).t),cat(1,X(k).d))
         %		datetick('x')
         %		title(I(n).ChannelFullName)
         %
         %	Known encoding formats are the following FDSN codes:
         %		 0: ASCII
         %		 1: 16-bit integer
         %		 2: 24-bit integer
         %		 3: 32-bit integer
         %		 4: IEEE float32
         %		 5: IEEE float64
         %		10: Steim-1
         %		11: Steim-2
         %		12: GEOSCOPE 24-bit (untested)
         %		13: GEOSCOPE 16/3-bit gain ranged
         %		14: GEOSCOPE 16/4-bit gain ranged
         %		19: Steim-3 (alpha and untested)
         %
         %	See also MKMSEED to export data in miniSEED format.
         %
         %
         %	Author: Fran?ois Beauducel <beauducel@ipgp.fr>
         %		Institut de Physique du Globe de Paris
         %	Created: 2010-09-17
         %	Updated: 2014-06-29
         %
         %	Acknowledgments:
         %		Ljupco Jordanovski, Jean-Marie Saurel, Mohamed Boubacar, Jonathan Berger,
         %		Shahid Ullah, Wayne Crawford, Constanza Pardo, Sylvie Barbier,
         %		Robert Chase, Arnaud Lemarchand.
         %
         %	References:
         %		IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010,
         %		  IFDSN/IRIS/USGS, http://www.iris.edu
         %		Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
         %		Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
         
         %	Copyright (c) 2014, Fran?ois Beauducel, covered by BSD License.
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
         %	     the documentation and/or other materials provided with the distribution
         %
         %	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
         %	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
         %	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
         %	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
         %	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
         %	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
         %	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
         %	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
         %	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
         %	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
         %	POSSIBILITY OF SUCH DAMAGE.
         
         % MODIFIED Oct 2015 by Celso Reyes
         
         if nargin > 6
            error('Too many input arguments.')
         end
         
         % global variables shared with sub-functions
         global offset littleEndian ef wo rl forcebe verbose notc force
         % default input arguments
         makeplot = false;	% make plot flag
         verbose = 0;	% verbose flag/level
         forcebe = false;	% force big-endian
         ef = 10;		% encoding format default
         wo = true;		% word order default
         rl = 2^12;		% record length default
         force = false;		% force input argument over blockette 1000 (UNDOCUMENTED)
         notc = false;		% force no time correction (over ActivityFlags)
         
         if nargin < 1
            [filename,pathname] = uigetfile('*','Please select a miniSEED file...');
            ms.FileName = fullfile(pathname,filename);
         else
            ms.FileName = varargin{1};
         end
         
         if ~ischar(ms.FileName) || ~exist(ms.FileName,'file')
            error('File %s does not exist.',ms.FileName);
         end
         
         if nargin > 1
            verbose = any(strcmpi(varargin,'v')) + 2*any(strcmpi(varargin,'vv')) ...
               + 3*any(strcmpi(varargin,'vvv'));
            makeplot = any(strcmpi(varargin,'plot'));
            forcebe = any(strcmpi(varargin,'be'));
            notc = any(strcmpi(varargin,'notc'));
            force = any(strcmpi(varargin,'force'));
         end
         nargs = makeplot + (verbose>0) + forcebe + notc + force;
         
         
         if nargin > (1 + nargs)
            ef = varargin{2};
            if ~isnumeric(ef) || ~any(ef==[0:5,10:19,30:33])
               error('Argument ENCODINGFORMAT must be a valid FDSN code value.');
            end
         end
         
         if nargin > (2 + nargs)
            wo = varargin{3};
            if ~isnumeric(wo) || (wo ~= 0 && wo ~= 1)
               error('Argument WORDORDER must be 0 or 1.');
            end
            wo = logical(wo);
         end
         
         if nargin > (3 + nargs)
            rl = varargin{4};
            if ~isnumeric(rl) || rl < 256 || rem(log(rl)/log(2),1) ~= 0
               error('Argument RECORDLENGTH must be a power of 2 and greater or equal to 256.');
            end
         end
         
         if nargout == 0
            makeplot = true;
         end
         
         % file is opened in Big-Endian encoding (this is encouraged by SEED)
         fid = fopen(ms.FileName,'rb','ieee-be');
         littleEndian = false;
         
         % --- tests if the header is mini-SEED
         % the 7th character must be one of the "data header/quality indicator", usually 'D'
         header = fread(fid,20,'*char');
         if ~any(header(7)=='DRMQ')
            if any(header(7),'VAST')
               s = ' (seems to be a SEED Volume)';
            else
               s = '';
            end
            error('File is not in mini-SEED format%s. Cannot read it.',s);
         end
         
         i = 1;
         offset = 0;
         
         while offset >= 0
            ms.X(i) = ms.read_data_record(fid);
            i = i + 1;
         end
         
         fclose(fid);
         
         % --- analyses data
         
         % test if the file is multiplexed or a single channel
         un = unique(cellstr(char(ms.X.ChannelFullName)));
         nc = numel(un);
         for i = 1:nc
            k = find(strcmp(cellstr(char(ms.X.ChannelFullName)),un{i}));
            ms.I(i).ChannelFullName = ms.X(k(1)).ChannelFullName;
            ms.I(i).XBlockIndex = k;
            ms.I(i).ClockDrift = ([diff(cat(1,ms.X(k).RecordStartTimeMATLAB));NaN]*86400 - cat(1,ms.X(k).NumberSamples)./cat(1,ms.X(k).SampleRate))./cat(1,ms.X(k).NumberSamples);
            ms.I(i).OverlapBlockIndex = k(find(ms.I(i).ClockDrift.*cat(1,ms.X(k).NumberSamples).*cat(1,ms.X(k).SampleRate) < -.5) + 1);
            ms.I(i).OverlapTime = cat(1,ms.X(ms.I(i).OverlapBlockIndex).RecordStartTimeMATLAB);
            ms.I(i).GapBlockIndex = k(find(ms.I(i).ClockDrift.*cat(1,ms.X(k).NumberSamples).*cat(1,ms.X(k).SampleRate) > .5) + 1);
            ms.I(i).GapTime = cat(1,ms.X(ms.I(i).GapBlockIndex).RecordStartTimeMATLAB);
         end
         
         % --- plots the data
         if makeplot
            plotresults(ms);
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function D = read_data_record(ms, fid)
         % read_data_record uses global variables ms.FileName, fid, offset, littleEndian, ef, wo, rl,
         %	and verbose. It reads a data record and returns a structure D.
         
         global offset littleEndian ef wo rl verbose notc force
         
         fseek(fid,offset,'bof');
         
         % --- read fixed section of Data Header (48 bytes)
         D.SequenceNumber        = fread(fid,6,'*char')';
         D.DataQualityIndicator  = fread(fid,1,'*char');
         D.ReservedByte          = fread(fid,1,'*char');
         D.StationIdentifierCode = fread(fid,5,'*char')';
         D.LocationIdentifier    = fread(fid,2,'*char')';
         D.ChannelIdentifier	    = fread(fid,3,'*char')';
         D.NetworkCode           = fread(fid,2,'*char')';
         D.ChannelFullName = sprintf('%s:%s:%s:%s',deblank(D.NetworkCode), ...
            deblank(D.StationIdentifierCode),deblank(D.LocationIdentifier), ...
            deblank(D.ChannelIdentifier));
         
         % Start Time decoding
         [D.RecordStartTime,swapflag] = readbtime;
         if swapflag
            if littleEndian
               machinefmt = 'ieee-be';
               littleEndian = false;
            else
               machinefmt = 'ieee-le';
               littleEndian = true;
            end
            position = ftell(fid);
            fclose(fid);
            fid = fopen(ms.ms.FileName,'rb',machinefmt);
            fseek(fid,position,'bof');
            if verbose > 0
               warning('RDMSEED:DataIntegrity', ...
                  'Sequence # %s: need to switch file encoding to %s...\n', ...
                  D.SequenceNumber,machinefmt);
            end
         end
         
         D.NumberSamples	        = fread(fid,1,'uint16');
         
         % Sample Rate decoding
         SampleRateFactor        = fread(fid,1,'int16');
         SampleRateMultiplier    = fread(fid,1,'int16');
         if SampleRateFactor > 0
            if SampleRateMultiplier >= 0
               D.SampleRate = SampleRateFactor*SampleRateMultiplier;
            else
               D.SampleRate = -1*SampleRateFactor/SampleRateMultiplier;
            end
         else
            if SampleRateMultiplier >= 0
               D.SampleRate = -1*SampleRateMultiplier/SampleRateFactor;
            else
               D.SampleRate = 1/(SampleRateFactor*SampleRateMultiplier);
            end
         end
         
         D.ActivityFlags          = fread(fid,1,'uint8');
         D.IOFlags                = fread(fid,1,'uint8');
         D.DataQualityFlags       = fread(fid,1,'uint8');
         D.NumberBlockettesFollow = fread(fid,1,'uint8');
         D.TimeCorrection         = fread(fid,1,'int32');	% Time correction in 0.0001 s
         D.OffsetBeginData        = fread(fid,1,'uint16');
         D.OffsetFirstBlockette   = fread(fid,1,'uint16');
         
         % --- read the blockettes
         OffsetNextBlockette = D.OffsetFirstBlockette;
         
         D.BLOCKETTES = [];
         b2000 = 0;	% Number of Blockette 2000
         
         for i = 1:D.NumberBlockettesFollow
            fseek(fid,offset + OffsetNextBlockette,'bof');
            BlocketteType = fread(fid,1,'uint16');
            
            switch BlocketteType
               
               case 1000
                  % BLOCKETTE 1000 = Data Only SEED (8 bytes)
                  OffsetNextBlockette = fread(fid,1,'uint16');
                  D.BLOCKETTES.B1000.EncodingFormat = fread(fid,1,'uint8');
                  D.BLOCKETTES.B1000.WordOrder = logical(fread(fid,1,'uint8'));
                  D.BLOCKETTES.B1000.DataRecordLength = fread(fid,1,'uint8');
                  D.BLOCKETTES.B1000.Reserved = fread(fid,1,'uint8');
                  
               case 1001
                  % BLOCKETTE 1001 = Data Extension (8 bytes)
                  OffsetNextBlockette = fread(fid,1,'uint16');
                  D.BLOCKETTES.B1001.TimingQuality = fread(fid,1,'uint8');
                  D.BLOCKETTES.B1001.Micro_sec = fread(fid,1,'int8');
                  D.BLOCKETTES.B1001.Reserved = fread(fid,1,'uint8');
                  D.BLOCKETTES.B1001.FrameCount = fread(fid,1,'uint8');
                  
               case 100
                  % BLOCKETTE 100 = Sample Rate (12 bytes)
                  OffsetNextBlockette = fread(fid,1,'uint16');
                  D.BLOCKETTES.B100.ActualSampleRate = fread(fid,1,'float32');
                  D.BLOCKETTES.B100.Flags = fread(fid,1,'uint8');
                  D.BLOCKETTES.B100.Reserved = fread(fid,1,'uint8');
                  
               case 500
                  % BLOCKETTE 500 = Timing (200 bytes)
                  OffsetNextBlockette = fread(fid,1,'uint16');
                  D.BLOCKETTES.B500.VCOCorrection = fread(fid,1,'float32');
                  D.BLOCKETTES.B500.TimeOfException = readbtime;
                  D.BLOCKETTES.B500.MicroSec = fread(fid,1,'int8');
                  D.BLOCKETTES.B500.ReceptionQuality = fread(fid,1,'uint8');
                  D.BLOCKETTES.B500.ExceptionCount = fread(fid,1,'uint16');
                  D.BLOCKETTES.B500.ExceptionType = fread(fid,16,'*char')';
                  D.BLOCKETTES.B500.ClockModel = fread(fid,32,'*char')';
                  D.BLOCKETTES.B500.ClockStatus = fread(fid,128,'*char')';
                  
               case 2000
                  % BLOCKETTE 2000 = Opaque Data (variable length)
                  b2000 = b2000 + 1;
                  OffsetNextBlockette = fread(fid,1,'uint16');
                  BlocketteLength = fread(fid,1,'uint16');
                  OffsetOpaqueData = fread(fid,1,'uint16');
                  D.BLOCKETTES.B2000(b2000).RecordNumber = fread(fid,1,'uint32');
                  D.BLOCKETTES.B2000(b2000).DataWordOrder = fread(fid,1,'uint8');
                  D.BLOCKETTES.B2000(b2000).Flags = fread(fid,1,'uint8');
                  NumberHeaderFields = fread(fid,1,'uint8');
                  HeaderFields = splitfield(fread(fid,OffsetOpaqueData-15,'*char')','~');
                  D.BLOCKETTES.B2000(b2000).HeaderFields = HeaderFields(1:NumberHeaderFields);
                  % Opaque data are stored as a single char string, but must be
                  % decoded using appropriate format (e.g., Quanterra Q330)
                  D.BLOCKETTES.B2000(b2000).OpaqueData = fread(fid,BlocketteLength-OffsetOpaqueData,'*char')';
                  
               otherwise
                  OffsetNextBlockette = fread(fid,1,'uint16');
                  
                  if verbose > 0
                     warning('RDMSEED:UnknownBlockette', ...
                        'Unknown Blockette number %d (%s)!\n', ...
                        BlocketteType,D.ChannelFullName);
                  end
            end
         end
         
         % --- read the data stream
         fseek(fid,offset + D.OffsetBeginData,'bof');
         
         if ~force && isfield(D.BLOCKETTES,'B1000')
            EncodingFormat = D.BLOCKETTES.B1000.EncodingFormat;
            WordOrder = D.BLOCKETTES.B1000.WordOrder;
            D.DataRecordSize = 2^D.BLOCKETTES.B1000.DataRecordLength;
         else
            EncodingFormat = ef;
            WordOrder = wo;
            D.DataRecordSize = rl;
         end
         
         D.d = NaN;
         D.t = NaN;
         
         [decode, D.EncodingFormatName] = getDecoder(EncodingFormat);
         [D, success] = decode(D);
         
         % Applies time correction (if needed)
         D.RecordStartTimeMATLAB = datenum(double([D.RecordStartTime(1),0,D.RecordStartTime(2:5)])) ...
            + (~notc & bitand(D.ActivityFlags,2) == 0)*D.TimeCorrection/1e4/86400;
         tv = datevec(D.RecordStartTimeMATLAB);
         doy = datenum(tv(1:3)) - datenum(tv(1),1,0);
         D.RecordStartTime = [tv(1),doy,tv(4:5),round(tv(6)*1e4)/1e4];
         D.RecordStartTimeISO = sprintf('%4d-%03d %02d:%02d:%07.4f',D.RecordStartTime);
         
         D.t = D.RecordStartTimeMATLAB;
         
         % makes the time vector and applies time correction (if needed)
         if EncodingFormat > 0
            D.t = D.t + (0:(D.NumberSamples-1))'/(D.SampleRate*86400);
         end
         
         offset = ftell(fid);
         fread(fid,1,'char');	% this is to force EOF=1 on last record.
         if feof(fid)
            offset = -1;
         end
      end
      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function c = splitfield(s,d)
         % splitfield(S) splits string S of D-character separated field names
         C = textscan(s,'%s','Delimiter',d);
         c = C{1};
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function [d,swapflag] = readbtime
         % readbtime reads BTIME structure from current opened file and returns
         %	D = [YEAR,DAY,HOUR,MINUTE,SECONDS]
         
         global fid forcebe
         
         Year		= fread(fid,1,'*uint16');
         DayOfYear	= fread(fid,1,'*uint16');
         Hours		= fread(fid,1,'uint8');
         Minutes		= fread(fid,1,'uint8');
         Seconds		= fread(fid,1,'uint8');
         fseek(fid,1,0);	% skip 1 byte (unused)
         Seconds0001	= fread(fid,1,'*uint16');
         
         % Automatic detection of little/big-endian encoding
         % -- by F. Beauducel, March 2014 --
         %
         % If the 2-byte day is >= 512, the file is not opened in the correct
         % endianness. If the day is 1 or 256, there is a possible byte-swap and we
         % need to check also the year; but we need to consider what is a valid year:
         % - years from 1801 to 2047 are OK (swapbytes >= 2312)
         % - years from 2048 to 2055 are OK (swapbytes <= 1800)
         % - year 2056 is ambiguous (swapbytes = 2056)
         % - years from 2057 to 2311 are OK (swapbytes >= 2312)
         % - year 1799 is ambiguous (swapbytes = 1799)
         % - year 1800 is suspicious (swapbytes = 2055)
         %
         % Thus, the only cases for which we are 'sure' there is a byte-swap, are:
         % - day >= 512
         % - (day == 1 or day == 256) and (year < 1799 or year > 2311)
         %
         % Note: in IRIS libmseed, the test is only year>2050 or year<1920.
         if ~forcebe && (DayOfYear >= 512 || (ismember(DayOfYear,[1,256]) && (Year > 2311 || Year < 1799)))
            swapflag = true;
            Year = swapbytes(Year);
            DayOfYear = swapbytes(DayOfYear);
            Seconds0001 = swapbytes(Seconds0001);
         else
            swapflag = false;
         end
         d = [double(Year),double(DayOfYear),Hours,Minutes,Seconds + double(Seconds0001)/1e4];
      end
      
      
      function [decFn, formatName] = getDecoder(encodingcode)
         switch encodingcode
            case 0
               decFn = @decode_ASCII;
               formatName = {'ASCII'};
            case 1
               decFn = @decode_INT16;
               formatName = {'INT16'};
            case 2
               decFn = @decode_INT24;
               formatName = {'INT24'};
            case 3
               decFn = @decode_INT32;
               formatName = {'INT32'};
            case 4
               decFn = @decode_FLOAT32;
               formatName = {'FLOAT32'};
            case 5
               decFn = @decode_FLOAT64;
               formatName = {'FLOAT64'};
            case 10
               decFn = @decode_STEIM1;
               formatName = {'STEIM1'};
            case 11
               decFn = @decode_STEIM2;
               formatName = {'STEIM2'};
            case 12
               formatName = {'GEOSCOPE24'};
               decFn = @decode_GEOSCOPE24;
            case 13
               formatName = {'GEOSCOPE16-3'};
               decFn = @decode_GEOSCOPE16_3;
            case 14
               formatName = {'GEOSCOPE16-4'};
               decFn = @decode_GEOSCOPE16_4;
            case 15
               % --- decoding format: US National Network compression
               formatName = {'USNN'};
               decFn = @decode_UNIMPLEMENTED;
            case 16
               % --- decoding format: CDSN 16-bit gain ranged
               formatName = {'CDSN'};
               decFn = @decode_UNIMPLEMENTED;
            case 17
               % --- decoding format: Graefenberg 16-bit gain ranged
               formatName = {'GRAEFENBERG'};
               decFn = @decode_UNIMPLEMENTED;
            case 18
               % --- decoding format: IPG - Strasbourg 16-bit gain ranged
               formatName = {'IPGS'};
               decFn = @decode_UNIMPLEMENTED;
            case 19
               formatName = {'STEIM3'};
               decFn = @decode_STEIM3;
            case 30
               % --- decoding format: SRO format
               formatName = {'SRO'};
               decFn = @decode_UNIMPLEMENTED;
            case 31
               % --- decoding format: HGLP format
               formatName = {'HGLP'};
               decFn = @decode_UNIMPLEMENTED;
            case 32
               % --- decoding format: DWWSSN gain ranged format
               formatName = {'DWWSSN'};
               decFn = @decode_UNIMPLEMENTED;
            case 33
               % --- decoding format: RSTN 16-bit gain ranged
               formatName = {'RSTN'};
               decFn = @decode_UNIMPLEMENTED;
            otherwise
               decFn = @decode_UNIMPLEMENTED;
               formatName = sprintf('Unknown: %d', encodingcode);
         end
      end
      
      
      %% Decoders
      function [D, success] = decode_ASCII(D)
         global fid
         D.EncodingFormatName = {'ASCII'};
         D.d = fread(fid,D.DataRecordSize - D.OffsetBeginData,'*char')';
         success = true;
      end
      
      function [D, success] = decode_INT16(D)
         global WordOrder fid
         % --- decoding format: 16-bit integers
         D.EncodingFormatName = {'INT16'};
         dd = fread(fid,ceil((D.DataRecordSize - D.OffsetBeginData)/2),'*int16');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_INT24(D)
         global WordOrder fid
         % --- decoding format: 24-bit integers
         D.EncodingFormatName = {'INT24'};
         dd = fread(fid,ceil((D.DataRecordSize - D.OffsetBeginData)/3),'bit24=>int32');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_INT32(D)
         global WordOrder fid
         % --- decoding format: 32-bit integers
         D.EncodingFormatName = {'INT32'};
         dd = fread(fid,ceil((D.DataRecordSize - D.OffsetBeginData)/4),'*int32');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_FLOAT32(D)
         global WordOrder fid
         % --- decoding format: IEEE floating point
         D.EncodingFormatName = {'FLOAT32'};
         dd = fread(fid,ceil((D.DataRecordSize - D.OffsetBeginData)/4),'*float');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_FLOAT64(D)
         global WordOrder fid
         % --- decoding format: IEEE double precision floating point
         D.EncodingFormatName = {'FLOAT64'};
         dd = fread(fid,ceil((D.DataRecordSize - D.OffsetBeginData)/8),'*double');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_UNIMPLEMENTED(D)
         error('Sorry, the encoding format "%s" is not yet implemented.',D.EncodingFormatName);
      end
      
      function [D, success] = decode_GEOSCOPE24(D)
         global WordOrder fid
         % --- decoding format: GEOSCOPE multiplexed 24-bit integer
         D.EncodingFormatName = {'GEOSCOPE24'};
         dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/3,'bit24=>double');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_GEOSCOPE16_3
         global WordOrder fid
         % --- decoding format: GEOSCOPE multiplexed 16/3 and 16/4 bit gain ranged
         %	(13): 16/3-bit (bit 15 is unused)
         %	bits 15-12 = 3 or 4-bit gain exponent (positive)
         %	bits 11-0 = 12-bit mantissa (positive)
         %	=> data = (mantissa - 2048) / 2^gain
         geoscope = 7; % mask for gain exponent
         D.EncodingFormatName = {'GEOSCOPE16-3'};
         dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/2,'*uint16');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         dd = (double(bitand(dd,2^12-1))-2^11)./2.^double(bitand(bitshift(dd,-12),geoscope));
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_GEOSCOPE16_4(D)
         global WordOrder fid verbose
         % --- decoding format: GEOSCOPE multiplexed 16/3 and 16/4 bit gain ranged
         %	(14): 16/4-bit
         %	bits 15-12 = 3 or 4-bit gain exponent (positive)
         %	bits 11-0 = 12-bit mantissa (positive)
         %	=> data = (mantissa - 2048) / 2^gain
         geoscope = 15; % mask for gain exponent
         D.EncodingFormatName = {'GEOSCOPE16-4'};
         dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/2,'*uint16');
         dd = miniseed.correctWordOrder(WordOrder, dd);
         dd = (double(bitand(dd,2^12-1))-2^11)./2.^double(bitand(bitshift(dd,-12),geoscope));
         D.d = dd(1:D.NumberSamples);
         success = true;
      end
      
      function [D, success] = decode_STEIM1(D)
         global WordOrder fid verbose
         
         % Steim compression decoding strategy optimized for Matlab
         % -- by F. Beauducel, October 2010 --
         %
         %	1. loads all data into a single 16xM uint32 array
         %	2. gets all nibbles from the first row splitted into 2-bit values
         %	3. for each possible nibble value, selects (find) and decodes
         %	   (bitsplit) all the corresponding words, and stores results
         %	   in a 4xN (STEIM1) or 7xN (STEIM2) array previously filled with
         %	   NaN's. For STEIM2 with nibbles 2 or 3, decodes also dnib values
         %	   (first 2-bit of the word)
         %	5. reduces this array with non-NaN values only
         %	6. integrates with cumsum
         %
         % This method is about 30 times faster than a 'C-like' loops coding...
         
         frame32 = fread(fid,[16,(D.DataRecordSize - D.OffsetBeginData)/64],'*uint32');
         frame32 = miniseed.correctWordOrder(WordOrder, frame32);
         
         % nibbles is an array of the same size as frame32...
         nibbles = bitand(bitshift(...
            repmat(frame32(1,:),16,1),...
            repmat(-30:2:0,size(frame32,2),1)'), 3);
         x0 = miniseed.bitsign(frame32(2,1),32);	% forward integration constant
         xn = miniseed.bitsign(frame32(3,1),32);	% reverse integration constant
         
         % STEIM-1: 3 cases following the nibbles
         ddd = nan(4,numel(frame32));	% initiates array with NaN
         k = nibbles == 1;			% nibble = 1 : four 8-bit differences
         if any(k)
            ddd(1:4,k) = miniseed.bitsplit(frame32(k),32,8);
         end
         k = nibbles == 2;			% nibble = 2 : two 16-bit differences
         if any(k)
            ddd(1:2,k) = miniseed.bitsplit(frame32(k),32,16);
         end
         k = nibbles == 3;			% nibble = 3 : one 32-bit difference
         if any(k)
            ddd(1,k) = miniseed.bitsign(frame32(k),32);
         end
         
         % Little-endian coding: needs to swap bytes
         if ~WordOrder
            ddd = flipud(ddd);
         end
         dd = ddd(~isnan(ddd));		% reduces initial array ddd: dd is non-NaN values of ddd
         
         % controls the number of samples
         if numel(dd) ~= D.NumberSamples
            if verbose > 1
               warning('RDMSEED:DataIntegrity','Problem in %s sequence # %s [%s]: number of samples in header (%d) does not equal data (%d).\n',...
                  D.EncodingFormatName{:},...
                  D.SequenceNumber,...
                  'unk',... % was D.RecordStartTimeISO,...
                  D.NumberSamples,numel(dd));
            end
            if numel(dd) < D.NumberSamples
               D.NumberSamples = numel(dd);
            end
         end
         
         % rebuilds the data vector by integrating the differences
         D.d = cumsum([x0;dd(2:D.NumberSamples)]);
         
         % controls data integrity...
         if D.d(end) ~= xn
            warning('RDMSEED:DataIntegrity','Problem in %s sequence # %s [%s]: data integrity check failed, last_data=%d, Xn=%d.\n',...
               D.EncodingFormatName{:},D.SequenceNumber,...
               'unk',... % was D.RecordStartTimeISO,...
               D.d(end),xn);
         end
         
         % for debug purpose...
         if verbose > 2
            D.dd = dd;
            D.nibbles = nibbles;
            D.x0 = x0;
            D.xn = xn;
         end
         success = true;
      end
      
      function [D, success] = decode_STEIM2(D)
         global WordOrder fid verbose
         % --- decoding formats: STEIM-1 and STEIM-2 compression
         %    (c) Joseph M. Steim, Quanterra Inc., 1994
         
         % Steim compression decoding strategy optimized for Matlab
         % -- by F. Beauducel, October 2010 --
         %
         %	1. loads all data into a single 16xM uint32 array
         %	2. gets all nibbles from the first row splitted into 2-bit values
         %	3. for each possible nibble value, selects (find) and decodes
         %	   (bitsplit) all the corresponding words, and stores results
         %	   in a 4xN (STEIM1) or 7xN (STEIM2) array previously filled with
         %	   NaN's. For STEIM2 with nibbles 2 or 3, decodes also dnib values
         %	   (first 2-bit of the word)
         %	5. reduces this array with non-NaN values only
         %	6. integrates with cumsum
         %
         % This method is about 30 times faster than a 'C-like' loops coding...
         
         frame32 = fread(fid,[16,(D.DataRecordSize - D.OffsetBeginData)/64],'*uint32');
         frame32 = miniseed.correctWordOrder(WordOrder, frame32);
         
         % nibbles is an array of the same size as frame32...
         nibbles = bitand(bitshift(repmat(frame32(1,:),16,1),repmat(-30:2:0,size(frame32,2),1)'),3);
         x0 = miniseed.bitsign(frame32(2,1),32);	% forward integration constant
         xn = miniseed.bitsign(frame32(3,1),32);	% reverse integration constant
         
         
         % STEIM-2: 7 cases following the nibbles and dnib
         ddd = nan(7,numel(frame32));	% initiates array with NaN
         k1 = nibbles == 1;			% nibble = 1 : four 8-bit differences
         if any(any((k1)))
            ddd(1:4,k1) = miniseed.bitsplit(frame32(k1),32,8);
         end
         k2 = find(nibbles == 2);			% nibble = 2 : must look in dnib
         [k2nib1,k2nib2,k2nib3] = deal([]);
         if ~isempty(k2)
            dnib = bitshift(frame32(k2),-30);
            k2nib1 = k2(dnib == 1);		% dnib = 1 : one 30-bit difference
            if ~isempty(k2nib1)
               ddd(1,k2nib1) = miniseed.bitsign(frame32(k2nib1),30);
            end
            k2nib2 = k2(dnib == 2);		% dnib = 2 : two 15-bit differences
            if ~isempty(k2nib2)
               ddd(1:2,k2nib2) = miniseed.bitsplit(frame32(k2nib2),30,15);
            end
            k2nib3 = k2(dnib == 3);		% dnib = 3 : three 10-bit differences
            if ~isempty(k2nib3)
               ddd(1:3,k2nib3) = miniseed.bitsplit(frame32(k2nib3),30,10);
            end
         end
         k3 = find(nibbles == 3);				% nibble = 3 : must look in dnib
         [k3nib0, k3nib1, k3nib2] = deal([]);
         if ~isempty(k3)
            dnib = bitshift(frame32(k3),-30);
            k3nib0 = k3(dnib == 0);		% dnib = 0 : five 6-bit difference
            if ~isempty(k3nib0)
               %disp('dnib = 0 : five 6-bit difference');
               ddd(1:5,k3nib0) = miniseed.bitsplit(frame32(k3nib0),30,6);
            end
            k3nib1 = k3(dnib == 1);		% dnib = 1 : six 5-bit differences
            if ~isempty(k3nib1)
               %disp('dnib = 1 : six 5-bit differences');
               ddd(1:6,k3nib1) = miniseed.bitsplit(frame32(k3nib1),30,5);
            end
            k3nib2 = k3(dnib == 2);		% dnib = 2 : seven 4-bit differences (28 bits!)
            if ~isempty(k3nib2)
               %disp('dnib = 2 : seven 4-bit differences (28 bits!)');
               ddd(1:7,k3nib2) = miniseed.bitsplit(frame32(k3nib2),28,4);
            end
         end
         if verbose > 2
            fprintf('k1:%d k2:%d k3:%d; k2nib1:%d k2nib2:%d k2nib3:%d; k3nib0:%d k3nib1:%d k3nib2:%d \n',...
               any(any(k1)), ~isempty(k2), ~isempty(k3),...
               ~isempty(k2nib1),~isempty(k2nib2),~isempty(k2nib3),...
               ~isempty(k3nib0), ~isempty(k3nib1), ~isempty(k3nib2));
         end
         % Little-endian coding: needs to swap bytes
         if ~WordOrder
            ddd = flipud(ddd);
         end
         dd = ddd(~isnan(ddd));		% reduces initial array ddd: dd is non-NaN values of ddd
         
         % controls the number of samples
         if numel(dd) ~= D.NumberSamples
            if verbose > 1
               warning('RDMSEED:DataIntegrity','Problem in %s sequence # %s [%s]: number of samples in header (%d) does not equal data (%d).\n',D.EncodingFormatName{:},D.SequenceNumber,...
                  datestr([D.RecordStartTime(1),0,D.RecordStartTime(2:end)]),... % was D.RecordStartTimeISO,...
                  D.NumberSamples,...
                  numel(dd));
            end
            if numel(dd) < D.NumberSamples
               D.NumberSamples = numel(dd);
            end
         end
         
         % rebuilds the data vector by integrating the differences
         D.d = cumsum([x0;dd(2:D.NumberSamples)]);
         
         % controls data integrity...
         if D.d(end) ~= xn
            warning('RDMSEED:DataIntegrity','Problem in %s sequence # %s [%s]: data integrity check failed, last_data=%d, Xn=%d.\n',...
               D.EncodingFormatName{:},...
               D.SequenceNumber,...
               'unk',...% was D.RecordStartTimeISO,...
               D.d(end),xn);
         end
         
         % for debug purpose...
         if verbose > 2
            D.dd = dd;
            D.nibbles = nibbles;
            D.x0 = x0;
            D.xn = xn;
         end
         success = true;
      end
      
      function [D, success] = decode_STEIM3(D)
         global WordOrder fid
         frame32 = fread(fid,[16,(D.DataRecordSize - D.OffsetBeginData)/64],'*uint32');
         frame32 = miniseed.correctWordOrder(WordOrder, frame32);
         
         % specific processes for STEIM-3
         if steim == 3
            % first bit = 1 means second differences
            SecondDiff = bitshift(frame32(1,:),-31);
            % checks for "squeezed flag"... and replaces frame32(1,:)
            squeezed = bitand(bitshift(frame32(1,:),-24),127);
            k = find(bitget(squeezed,7));
            if ~isempty(k)
               moredata24 = bitand(frame32(1,k),16777215);
               k = find(squeezed == 80);	% upper nibble 8-bit = 0x50
               if ~isempty(k)
                  frame32(1,k) = hex2dec('15555555');
               end
               k = find(squeezed == 96);	% upper nibble 8-bit = 0x60
               if ~isempty(k)
                  frame32(1,k) = hex2dec('2aaaaaaa');
               end
               k = find(squeezed == 112);	% upper nibble 8-bit = 0x70
               if ~isempty(k)
                  frame32(1,k) = hex2dec('3fffffff');
               end
            end
         end
         
         % nibbles is an array of the same size as frame32...
         nibbles = bitand(bitshift(repmat(frame32(1,:),16,1),repmat(-30:2:0,size(frame32,2),1)'),3);
         x0 = miniseed.bitsign(frame32(2,1),32);	% forward integration constant
         xn = miniseed.bitsign(frame32(3,1),32);	% reverse integration constant
         
         % *** STEIM-3 DECODING IS ALPHA AND UNTESTED ***
         % STEIM-3: 7 cases following the nibbles
         ddd = NaN*ones(9,numel(frame32));	% initiates array with NaN
         k = find(nibbles == 0);				% nibble = 0 : two 16-bit differences
         if ~isempty(k)
            ddd(1:2,k) = miniseed.bitsplit(frame32(k),32,16);
         end
         k = find(nibbles == 1);				% nibble = 1 : four 8-bit differences
         if ~isempty(k)
            ddd(1:4,k) = miniseed.bitsplit(frame32(k),32,8);
         end
         k = find(nibbles == 2);				% nibble = 2 : must look even dnib
         if ~isempty(k)
            dnib2 = bitshift(frame32(k(2:2:end)),-30);
            w60 = bitand(frame32(k(2:2:end)),1073741823) ...
               + bitshift(bitand(frame32(k(1:2:end)),1073741823),30);	% concatenates two 30-bit words
            kk = find(dnib2 == 0);		% dnib = 0: five 12-bit differences (60 bits)
            if ~isempty(kk)
               ddd(1:5,k(2*kk)) = miniseed.bitsplit(w60,60,12);
            end
            kk = find(dnib2 == 1);		% dnib = 1: three 20-bit differences (60 bits)
            if ~isempty(kk)
               ddd(1:3,k(2*kk)) = miniseed.bitsplit(w60,60,20);
            end
         end
         k = find(nibbles == 3);				% nibble = 3 : must look 3rd bit
         if ~isempty(k)
            dnib = bitshift(frame32(k),-27);
            kk = k(dnib == 24);		% dnib = 11000 : nine 3-bit differences (27 bits)
            if ~isempty(kk)
               ddd(1:9,kk) = miniseed.bitsplit(frame32(kk),27,3);
            end
            kk = k(dnib == 25);		% dnib = 11001 : Not A Difference
            if ~isempty(kk)
               ddd(1,kk) = miniseed.bitsign(frame32(kk),27);
            end
            kk = k(dnib > 27);		% dnib = 111.. : 29-bit sample (29 bits)
            if ~isempty(kk)
               ddd(1,kk) = miniseed.bitsign(frame32(kk),29);
            end
         end
         
         % Little-endian coding: needs to swap bytes
         if ~WordOrder
            ddd = flipud(ddd);
         end
         dd = ddd(~isnan(ddd));		% reduces initial array ddd: dd is non-NaN values of ddd
         
         % controls the number of samples
         if numel(dd) ~= D.NumberSamples
            if verbose > 1
               warning('RDMSEED:DataIntegrity',...
                  'Problem in %s sequence # %s [%s]: number of samples in header (%d) does not equal data (%d).\n',...
                  D.EncodingFormatName{:},D.SequenceNumber,...
                  'unk',... % was D.RecordStartTimeISO,...
                  D.NumberSamples,numel(dd));
            end
            if numel(dd) < D.NumberSamples
               D.NumberSamples = numel(dd);
            end
         end
         
         % rebuilds the data vector by integrating the differences
         D.d = cumsum([x0;dd(2:D.NumberSamples)]);
         
         % controls data integrity...
         if D.d(end) ~= xn
            warning('RDMSEED:DataIntegrity',...
               'Problem in %s sequence # %s [%s]: data integrity check failed, last_data=%d, Xn=%d.\n',...
               D.EncodingFormatName{:},...
               D.SequenceNumber,...
               'unk',... % was D.RecordStartTimeISO,...
               D.d(end),xn);
         end
         
         % for debug purpose...
         if verbose > 2
            D.dd = dd;
            D.nibbles = nibbles;
            D.x0 = x0;
            D.xn = xn;
         end
         success = true;
      end
      
      function plotresults(ms)
         
         % sensible limits for multiplexed files
         max_channels = 20;	% absolute max number of channels to plot
         max_channel_label = 6;	% max. number of channels for y-labels
         
         chanlist = unique(cellstr(char(ms.X.ChannelFullName)));
         numchans = numel(chanlist);
         ms.I = something;
         figure
         minlim = min(cat(1,ms.X.t));
         maxlim = max(cat(1,ms.X.t));
         xlimits = [minlim,maxlim];
         
         % test if all data records have the same length
         reclens = unique(cat(1,ms.X.DataRecordSize));
         if numel(reclens) == 1
            rl_text = sprintf('%d bytes',reclens);
         else
            rl_text = sprintf('%d-%d bytes',min(reclens),max(reclens));
         end
         
         % test if all data records have the same sampling rate
         samprates = unique(cat(1,ms.X.SampleRate));
         if numel(samprates) == 1
            sr_text = sprintf('%g Hz',samprates);
         else
            sr_text = sprintf('%d # samp. rates',numel(samprates));
         end
         
         % test if all data records have the same encoding format
         encodefmts = unique(cellstr(cat(1,ms.X.EncodingFormatName)));
         if numel(encodefmts) == 1
            ef_text = sprintf('%s',encodefmts{:});
         else
            ef_text = sprintf('%d different encod. formats',numel(encodefmts));
         end
         
         if numchans == 1
            plot(cat(1,ms.X.t),cat(1,ms.X.d))
            hold on
            for i = 1:length(ms.I.GapBlockIndex)
               plot(ms.I.GapTime(i),ms.X(ms.I.GapBlockIndex(i)).d(1),'*r')
            end
            for i = 1:length(ms.I.OverlapBlockIndex)
               plot(ms.I.OverlapTime(i),ms.X(ms.I.OverlapBlockIndex(i)).d(1),'og')
            end
            hold off
            set(gca,'XLim',xlimits)
            datetick('x','keeplimits')
            grid on
            xlabel(sprintf('Time\n(%s to %s)',datestr(xlimits(1)),datestr(xlimits(2))))
            ylabel('Counts')
            title(sprintf('mini-SEED file "%s"\n%s (%d rec. @ %s - %g samp. @ %s - %s)', ...
               ms.ms.FileName,chanlist{1},length(ms.X),rl_text,numel(cat(1,ms.X.d)),sr_text,ef_text),'Interpreter','none')
         else
            % plot is done only for real data channels...
            if numchans > max_channels
               warning('Plot has been limited to %d channels (over %d). See help to manage multiplexed file.', ...
                  max_channels,numchans);
               numchans = max_channels;
            end
            for i = 1:numchans
               subplot(numchans*2,1,i*2 + (-1:0))
               k = ms.I(i).XBlockIndex;
               if ~any(strcmp('ASCII',cellstr(cat(1,ms.X(k).EncodingFormatName))))
                  plot(cat(1,ms.X(k).t),cat(1,ms.X(k).d))
                  hold on
                  for ii = 1:length(ms.I(i).GapBlockIndex)
                     plot(ms.I(i).GapTime(ii),ms.X(ms.I(i).GapBlockIndex(ii)).d(1),'*r')
                  end
                  for ii = 1:length(ms.I(i).OverlapBlockIndex)
                     plot(ms.I(i).OverlapTime(ii),ms.X(ms.I(i).OverlapBlockIndex(ii)).d(1),'og')
                  end
                  hold off
               end
               set(gca,'XLim',xlimits,'FontSize',8)
               h = ylabel(chanlist{i},'Interpreter','none');
               if numchans > max_channel_label
                  set(gca,'YTick',[])
                  set(h,'Rotation',0,'HorizontalAlignment','right','FontSize',8)
               end
               datetick('x','keeplimits')
               set(gca,'XTickLabel',[])
               grid on
               if i == 1
                  title(sprintf('mini-SEED file "%s"\n%d channels (%d rec. @ %s - %g data - %s - %s)', ...
                     ms.ms.FileName,length(chanlist),length(ms.X),rl_text,numel(cat(1,ms.X(k).d)),sr_text,ef_text),'Interpreter','none')
               end
               if i == numchans
                  datetick('x','keeplimits')
                  xlabel(sprintf('Time\n(%s to %s)',datestr(xlimits(1)),datestr(xlimits(2))))
               end
            end
            v = version;
            if str2double(v(1))>=7
               linkaxes(findobj(gcf,'type','axes'),'x')
            end
         end
      end
   end
   methods(Static)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function d = bitsplit(x,b,n)
         % bitsplit(X,B,N) splits the B-bit number X into signed N-bit array
         %	X must be unsigned integer class
         %	N ranges from 1 to B
         %	B is a multiple of N
         
         sign = repmat((b:-n:n)',1,size(x,1));
         x = repmat(x',b/n,1);
         d = double(bitand(bitshift(x,flipud(sign-b)),2^n-1)) ...
            - double(bitget(x,sign))*2^n;
      end
      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function d = bitsign(x,n)
         % bitsign(X,N) returns signed double value from unsigned N-bit number X.
         % This is equivalent to bitsplit(X,N,N), but the formula is simplified so
         % it is much more efficient
         
         d = double(bitand(x,2^n-1)) - double(bitget(x,n)).*2^n;
      end
      
      function  val = correctWordOrder(wordOrder, val)
         global littleEndian;
         % replacing xor(~wordOrder,littleEndian) with (wordOrder == littleEndian)
         if (wordOrder == littleEndian)
            val = swapbytes(val);
         end
      end
   end
   
end

