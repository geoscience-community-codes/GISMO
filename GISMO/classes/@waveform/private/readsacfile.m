function OUTPUT = readsacfile(varargin)
%readsacfile    Read SAC binary files.
%    usage:  output = readsacfile('sacfile')
%         OUTPUT is a struct with fields "header" and "amplitudes"
%         OUTPUT.header is an array of cells, each parsed into the proper
%         data type (ie, SINGLE, CHAR, LOGICAL, etc.).
%         OUTPUT.amplitudes is an array of the measured data

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes   creyes@gi.alaska.edu
%    modified from Michael Thorne (4/2004)
% LASTUPDATE: 9/2/2009


try
  OUTPUT = mainFunction('little-endian',varargin{:});
catch
  % disp('big-endian')
  OUTPUT = mainFunction('big-endian',varargin{:});
end

function OUTPUT = mainFunction(endian,varargin)
for nrecs = 1:nargin-1

  sacfile = varargin{nrecs};

  %---------------------------------------------------------------------------
  %    Default byte-order
  %    endian  = 'big-endian' byte order (e.g., UNIX)
  %            = 'little-endian' byte order (e.g., LINUX)

  %endian = 'little-endian';
  %endian = 'big-endian';

  if strcmp(endian,'big-endian')
    fid = fopen(sacfile,'r','ieee-be');
  elseif strcmp(endian,'little-endian')
    fid = fopen(sacfile,'r','ieee-le');
  end

  %preallocate
  h = cell(1,123);
  
  % read in single precision real header variables:
  %---------------------------------------------------------------------------
  for i=1:70
    h(i) = {fread(fid,1,'single')};
  end

  % read in single precision integer header variables:
  %---------------------------------------------------------------------------
  for i=71:105
    h(i) = {fread(fid,1,'int32')};
  end


  % Check header version = 6 and issue warning
  %---------------------------------------------------------------------------
  % If the header version is not NVHDR == 6 then the sacfile is likely of the
  % opposite byte order.  This will give h(77) some ridiculously large
  % number.  NVHDR can also be 4 or 5.  In this case it is an old SAC file
  % and rsac cannot read this file in.  To correct, read the SAC file into
  % the newest verson of SAC and w over.
  %
  if (h{77} == 4 || h{77} == 5)
    message = strcat('NVHDR = 4 or 5. File: "',sacfile,'" may be from an old version of SAC.');
    fclose(fid);
    error('Waveform:readsacfile:oldSacVersion',message)
  elseif h{77} ~= 6
    message = strcat('Current readsacfile byte order: "',endian,'". File: "',sacfile,'" may be of opposite byte-order.');
    fclose(fid);
    error('Waveform:readsacfile:wrongEndian',message)
  end

  % read in logical header variables
  %---------------------------------------------------------------------------
  for i=106:110
    h(i) = {fread(fid,1,'int32')};
  end

  % read in character header variables
  %---------------------------------------------------------------------------
  strlens = repmat(8,23,1); strlens(2) = 16;
  for i=111:133;%111:8:302
    h(i) = {(fread(fid,strlens(i-110),'char=>char'))'};
  end
  

  % read in amplitudes
  %---------------------------------------------------------------------------


  OUTPUT(nrecs).amplitudes = fread(fid,'single');
  fclose(fid);


  % arrange output files
  %------------------------------------------------------------------------
  %---
  OUTPUT(nrecs).header = h(:)';


end
