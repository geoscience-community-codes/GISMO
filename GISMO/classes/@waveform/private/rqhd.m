%RQHD  Read seismic handler (SH) header variables 
%
%      usage:
%      [output]=rqhd('header_file','header_variable',occurrence);
%
%      Where:  header_file     = SH format header file
%              header_variable = SH format header variable name 
%              occurrence      = n - only display value of the nth 
%                                occurrence of variable in header file
%                              = 0 - create array of values containing
%                                each occurrence of variable in header file
%
%      examples:
%
%      To assign the first occurrence of the SH header value 'R000'
%      to the matlab variable 'delta' from the SH header file foo.QHD:
%
%      delta=rqhd('foo','R000',1); 
%
%      To create an array containing the number of records in each
%      trace from the SH header file foo.QHD and store in the matlab
%      variable 'length': 
%
%      length=rqhd('foo','L001',0);
%
%      To read both variables in the above example in one line:
%
%      [delta,length]=rqhd('foo','R000',1,'L001',0);
%
%      some useful SH header variables are:
%  
%        SH           purpose 
%      ------    ------------------
%       L001       length
%       R000       delta
%       R011       distance
%       R012       azimuth
%       R014       depth
%       R015       magnitude
%       R016       lat
%       R017       lon
%       S000:S     slowness
%       S021       event origin time
%       S024       trace begin time
%
%       By, Michael Thorne (mthorne@asu.edu)  4/2004
%       MODIFIED by Celso Reyes 4/2009
%
function [varargout]=rqhd(headin,varargin)

if (nargin < 3)
  error('Waveform:rqhd:insufficientArguments','not enough input arguments ...')
end

headfile=strcat(headin,'.QHD');

fid=fopen(headfile,'r');

junk=fgets(fid);  %read first line of file

%read in header file line by line and paste into array 'g'
%------------------------------------------------------------------------
h=1;
bline=1;
while h ~= -1  %h=-1 indicates end of file

  h=fgetl(fid);
  lbreak=find(h=='|');
  hh=h(lbreak+1:length(h));
  
  if h ~= -1 && isempty(hh) == 0
    eline=bline + length(hh) - 1;
    g(bline:eline) = hh;
    bline = eline + 1;
  end

end   %end while

%grab requested header variables from array 'g'
%------------------------------------------------------------------------

count = 1;
for recs=1:2:(nargin-1)

header=varargin{recs};
occurrence=varargin{recs+1};

ltilde=find(g=='~');         %locations of all tildes
location=findstr(header,g);  %start locations of requested variables
if isempty(location) == 1
  error('Waveform:rqhd:undefinedHeader','header variable not defined ...')
end


if header(1) == 'R'
  if occurrence > 0
    e1 = find(ltilde>location(occurrence));
    e2 = ltilde(e1(1)) - 1;
    output = str2num(g(location(occurrence)+length(header)+1:e2));
  else
    for j=1:length(location)
      e1 = find(ltilde>location(j));
      e2 = ltilde(e1(1)) - 1;
      output(j) = str2num(g(location(j)+length(header)+1:e2));
    end
  end
elseif header(1) == 'L' || header(1) == 'I'
  if occurrence > 0
    e1 = find(ltilde>location(occurrence));
    e2 = ltilde(e1(1)) - 1;
    output = round(str2num(g(location(occurrence)+length(header)+1:e2)));
  else
    for j=1:length(location)
      e1 = find(ltilde>location(j));
      e2 = ltilde(e1(1)) - 1;
      output(j) = round(str2num(g(location(j)+length(header)+1:e2)));
    end
  end
elseif header(1) == 'C' || header(1) == 'S' || header(1) == 'T'
  if occurrence > 0
    e1 = find(ltilde>location(occurrence));
    e2 = ltilde(e1(1)) - 1;
    output = g(location(occurrence)+length(header)+1:e2);
  else
    for j=1:length(location)
      e1 = find(ltilde>location(j));
      e2 = ltilde(e1(1)) - 1;
      output{j} = g(location(j)+length(header)+1:e2);
    end
  end
else
  error('header name does not exist or is unsupported ...')
end

varargout{count} = output;
count = count + 1;

end

fclose(fid);

