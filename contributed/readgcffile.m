function [samples,streamID,sps,tStart] = readgcffile(filename, streamID)
% ReadGCFFile
%
%   [SAMPLES,STREAMID,SPS,tStart] = READGCFFILE(filename, streamID)
%
%   Reads in the specified GCF formatted file, and returns:
%     Samples - an array of all samples in file
%     Stream ID (string up to 6 characters)
%     SPS - sample rate of data in SAMPLES
%     tStart - start time of data, as serial date number
%
%   example:
%   [samples,streamID,sps,tStart]=readgcffile('test.gcf');
%   streams=readgcffile('test.gcf','list');
%   [samples,streamID,sps,tStart]=readgcffile('test.gcf','TESTZ2');

%   M. McGowan, Guralp Systems Ltd.
%   2004/09/23 M. McGowan (support@guralp.com)
%     Added support for multiple streams in a GCF file, where the user can
%     specify which stream ID they want to extract. See 'streamID' input
%     parameter. This is optional - if ommited, it will use the first
%     streamID it finds. Note that it IS case-sensitive - all IDs should be
%     uppercase. If StreamID is a cell array of strings, this function will
%     return array structures containing data for all streams specified.
%     [SAMPLES,STREAMID,SPS,tStart] = READGCFFILE(FILENAME, 'list')
%     Specifying 'list' for the streamID will return a cell array of strings,
%     one string for each streamID found in the file. This can be used to
%     iterate through each streamID in the file to read all the data contained
%     in the file. For an example, see the 'plot' option.
%     READGCFFILE(FILENAME, 'plot')
%     The 'plot' option is an example of reading all streams in a file and
%     displaying them.
%
%     If the specified stream is a status stream, 'samples' will return an
%     array of numbers which can be converted into text using
%     char(samples').
%
%     Modified code to cope with gaps, overlaps and out-of-sequence data.
%     Uses the first block timestamp as a reference, so will not return any
%     data in the file that has a timestamp older than the first
%     block in file.
%     In the case of an overlap, the data found further through the file will
%     overwrite the data read earlier.
%     Where a gap exists, it will be padded with sample values of NaN.
%
%   2008/11/13 M.McGowan (support@guralp.com)
%     Updated plotfile routine - only plots data streams (sps>0), and plots
%     aligned for time
%
%   2008/11/28 M.McGowan (support@guralp.com)
%     Updated readgcfblock for sample rates >250
%
%   2009/03/05 M.McGowan (support@guralp.com)
%     Fixed bug picking up streamID from first block. Was preventing code
%     from reading a GCF file without a Stream ID being specified
%
%   2014/09/26 M.McGowan (support@guralp.com)
%     changed to be a 2-pass reader. First pass to read blocks for the
%     given streamID, and find start/end window, second pass to populate
%     the samples array. Memory use can be up to (approx) 2x the
%     uncompressed size of the data, but the file is only read once, which
%     is more critical.

% initialise output variables to 'invalid'. Can't leave them non-existing,
% as that doesn't compile properly in 6.x.
sps=-1;
tStart=-1;
wstreamID=-1;
expectedtime=-1;

% support asking for multiple streams in one call.
if (nargin>1) && iscell(streamID),
  for i = 1:length(streamID),
    [samples{i},streamID{i},sps(i),tStart(i)]=readgcffile(filename,streamID{i});
  end
  return
end

if (nargin>1) && strcmp(streamID,'plot'),
  plotfile(filename);
  return
end

% try to open the file. If unsuccessful, try again with a .gcf extension.
fid = fopen(filename,'r','ieee-be');
if fid==-1,
    [p,n,e]=fileparts(filename);
    if ~strcmpi(e,'.gcf'),
        fname2 = [filename,'.gcf'];
        fid = fopen(fname2,'r','ieee-be');
    end
end
if fid==-1,
    error(['Unable to open file "',filename,'"']);
    return; 
end

if (nargin>1) && strcmp(streamID,'list'),
  samples=getstreamidlist(fid);
  fclose(fid);
  return
end

% determine the stream ID that we will be reading from this file.
if nargin>1,
  wstreamID = base2dec(streamID,36); % faster to compare numbers than strings, so use a 'working' streamID
end
if wstreamID < 0, % no stream ID has been pre-specified, so use the first one we find
  [blk] = readgcfblock(fid);
  wstreamID = blk.streamID;
  frewind(fid);
end
streamID = dec2base(wstreamID,36); % convert numerical streamID back to a string

onesec = datenum(0,0,0,0,0,1);
onemsec = onesec/1000;

% Pass 1 - read the blocks for the given ID into an array. Determine start
% and end times.

% get the file size, and init array to block count
fseek(fid,0,'eof');
siz=ftell(fid)/1024;
frewind(fid);
blks=repmat({},siz,1);

% read every block of this stream into array "blks"
cnt=0;
tStart = nan;
tEnd = nan;
while ~feof(fid),
    blk=readgcfblock(fid,wstreamID);
    if ~isempty(blk.samps),
        cnt=cnt+1;
        blks{cnt}=blk;
        % track start and end times
        tStart = min(tStart,blk.tStart);
        tEnd = max(tEnd, blk.tStart + (length(blk.samps)/blk.sps)*onesec );
    end
end
fclose(fid);



% Pass 2 - create the array to handle the entire file's samples,
% then, block by block, copy samples into the array in the correct place.
% This is MUCH faster than adding on to the end of an array each block.
sps = blks{1}.sps;

if sps>0,
    sampcount=round((tEnd-tStart)*blks{1}.sps/onesec); % assume the samplerate is continuous throughout.
else
    blksm=cell2mat(blks);
    samples=[blksm(:).samps]; % note - no sorting or duplicate removal, but this is all we need to do.
    return; % ensure all the output variables are defined before here.
end

% if there is corruption in the file, and the time span is large, the
% repmat below might fail on memory allocation.
samples=repmat(NaN,sampcount,1); 
sampcount=1;

for i=1:length(blks),
  [blk] = blks{i};
  if (sps>0),
    if expectedtime>=0,
      if expectedtime+onemsec < blk.tStart,
        disp(['Warning: Gap in ',dec2base(blk.streamID,36),', Expected ',datestr(expectedtime,31),', found ',datestr(blk.tStart,31)]);
      end
      if blk.tStart+onemsec < expectedtime,
        disp(['Warning: Overlap in ',dec2base(blk.streamID,36),', Expected ',datestr(expectedtime,31),', found ',datestr(blk.tStart,31)]);
      end
      if sps ~= blk.sps,
          disp('Warning: sample rate change in file, results will be unpredictable');
      end
    end
    secs = length(blk.samps)/sps;
    expectedtime = blk.tStart + secs*onesec;
  end
  % Copy the samples into the pre-prepared array
  if blk.sps>0,
    ofs = round((blk.tStart-tStart)*blk.sps/onesec);
  else
    ofs = sampcount; % count the number of ascii chars, to append the status.
  end
  endofs = ofs + length(blk.samps);
  while endofs > length(samples), %if array not big enough, expand until it is. This should only happen if the samplerate changes.
    samples = [samples;NaN*ones(length(samples),1)];
  end
  
  samples(ofs+1:endofs)=blk.samps;
  sampcount = max([sampcount,endofs]);
end
samples=samples(1:sampcount);     % trim samples array to actual length



function [blk] = readgcfblock(fid,nstrid)
blk.samps=[];
blk.sps=-1;
blk.tStart=-1;
blk.sysID = fread(fid,1,'uint32');
blk.streamID = fread(fid,1,'uint32');
if nargin>1, % if we have specified a particular ID, keep searching until we find it
  while ~feof(fid) && (nstrid ~= blk.streamID),
    fseek(fid,1016,'cof');
    blk.sysID = fread(fid,1,'uint32');
    blk.streamID = fread(fid,1,'uint32');
  end
end
if feof(fid)
  return 
end

date = fread(fid,1,'ubit15');
time = fread(fid,1,'ubit17');
blk.reserved = fread(fid,1,'uint8');
blk.sps = decodesps(fread(fid,1,'uint8'));
frac = fread(fid,1,'ubit4');
blk.compressioncode = fread(fid,1,'ubit4');
blk.numrecords = fread(fid,1,'uint8');

% Convert GCF coded time to Matlab coded time
hours = floor(time / 3600);
mins = rem(time,3600);
blk.tStart = datenum(1989,11,17, hours, floor(mins / 60), rem(mins,60) ) + date;
% add in the fractional second offset (if any)
if blk.sps>0,
  if blk.sps==400, step=50; else step=250; end;
  diff=frac*step/blk.sps; % fractions of a second
  blk.tStart=blk.tStart+ diff/86400;
end

if (blk.sps ~= 0),
   fic = fread(fid,1,'int32');
   switch blk.compressioncode
   case 1,
      diffs = fread(fid,blk.numrecords,'int32');
   case 2,
      diffs = fread(fid,blk.numrecords*2,'int16');
   case 4,
      diffs = fread(fid,blk.numrecords*4,'int8');
   end
   ric = fread(fid,1,'int32',1000-blk.numrecords*4);
   diffs(1) = fic;
   blk.samps = cumsum(diffs);
else
   blk.samps = char(fread(fid,blk.numrecords*4,[num2str(blk.numrecords*4),'*uchar=>uchar'],1008-blk.numrecords*4)');
end


function [outsps]=decodesps(insps)
switch insps
  case 157,  outsps=0.1;
  case 161,  outsps=0.125;
  case 162,  outsps=0.2;
  case 164,  outsps=0.25;
  case 167,  outsps=0.5;
  case 171,  outsps=400;
  case 174,  outsps=500;
  case 176,  outsps=1000;
  case 179,  outsps=2000;
  case 181,  outsps=4000;
  otherwise outsps=insps;
end


function list = getstreamidlist(fid)
fseek(fid,4,'bof');
list=fread(fid,'uint32',1020);
list=dec2base(list,36);
list=unique(cellstr(list));


function plotfile(fname)
% EXAMPLE SCRIPT TO READ AND PLOT ALL STREAMS IN A GCF FILE
list=readgcffile(fname,'list');
for i = 1:length(list),
  [samples{i},id{i},sps(i),Tstart(i)]=readgcffile(fname,list{i});
  Tend(i)=Tstart(i);
  if sps(i)>0,
    Tend(i)=Tstart(i) + (length(samples{i})/sps(i))/86400;
  end
end
Tmin=datevec(min(Tstart));
Tmax=datevec(max(Tend));
Tdiff=etime(Tmax,Tmin);
datachans=find(sps>0);
numchans=length(datachans);
for i = 1:numchans,
  subplot(numchans,1,i);
  Soffset=etime(datevec(Tstart(datachans(i))),Tmin);
  plot((Soffset:1/sps(datachans(i)):Soffset+(length(samples{datachans(i)})-1)/sps(datachans(i))),samples{datachans(i)});
  ylabel(id(datachans(i)));
  ax=axis;
  axis([0 Tdiff ax(3) ax(4)]);
end
xlabel(['seconds from ',datestr(Tmin)]);
