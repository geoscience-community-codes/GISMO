%RQBN  Read seismic handler (SH) binary file
%
%      usage:
%      [output]=rqbn('filename');
%
%      Where:  filename  = SH format filename.  The filename
%                        does not include the suffix .QBN 
%                        The suffixes .QBN and .QHD are added
%                        where needed.
%
%      examples:
%
%      To read the SH binary file traces from the file foo.QBN
%      into the matlab variable traces:
%
%      traces=rqbn('foo'); 
%
%      By, Michael Thorne (mthorne@asu.edu)  4/2004
%
function [data] = rqbn(filename)

binfile = strcat(filename,'.QBN');

endian = 'lil';
if endian == 'big'
  fid = fopen(binfile,'r','ieee-be');
elseif endian == 'lil'
  fid = fopen(binfile,'r','ieee-le');
end

%grab trace-lengths from header file
tlength=rqhd(filename,'L001',0);
tp=size(tlength);
ntraces=tp(1,2);

for j=1:ntraces
  for k=1:tlength(j)
    data(j,k) = fread(fid,1,'single');
  end
end

fclose(fid);

