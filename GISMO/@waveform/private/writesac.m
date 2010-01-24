function writesac(outfilename, header, data)
%WRITESAC    Write SAC binary files to disk.
%    WSAC(sacfilename, sacheader, data) writes a SAC (seismic analysis code) binary
%    format file
%
%    Default byte order is little-endian.  M-file can be set to default
%    little-endian byte order.
%
%
%    See also:  readsac, sac2waveform, set_sacheader, waveform2sacheader

% VERSION: 1.1 of waveform objects
%    modified from Michael Thorne (4/2004)
% MODIFICATIONS: Celso Reyes
% LASTUPDATE: 9/2/2009

%---------------------------------------------------------------------------
%    Default byte-order
%    endian  = 'big'  big-endian byte order (e.g., UNIX)
%            = 'lil'  little-endian byte order (e.g., LINUX)

endian = 'lil';

if strcmp(endian,'big')
  fid = fopen(outfilename,'w','ieee-be');
elseif strcmp(endian,'lil');
  fid = fopen(outfilename,'w','ieee-le');
else
  error('Waveform:writesac:invalidEndian','unrecognized endianness');
end



% write single precision real header variables:
%---------------------------------------------------------------------------
for i=1:70
  fwrite(fid,header(i),'single');
end

% write single precision integer header variables:
%---------------------------------------------------------------------------
for i=71:105
  fwrite(fid,header(i),'int32');
end

% write logical header variables
%---------------------------------------------------------------------------
for i=106:110
  fwrite(fid,header(i),'int32');
end

% write character header variables
%---------------------------------------------------------------------------
for i=111:302
  fwrite(fid,header(i),'char');
end

% write out amplitudes
%---------------------------------------------------------------------------
fwrite(fid,data,'single');

fclose(fid);

