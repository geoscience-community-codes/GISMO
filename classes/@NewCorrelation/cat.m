function c = cat(varargin)

% c = cat(c1,c2,c3,...)
% Concatenate the traces in two or more correlation objects. c1,c2,c3,...
% will be combined in the order listed. Only the four data descriptor
% fields (TRIG,START,WAVES,FS) will be filled in the output object. There
% is not enough information to fill in the CORRELATION, LAG, STAT, LINK, or 
% CLUSTER fields. These fields will be empty. Data in c1,c2,c3,... must
% have the same number of samples and sampling frequency.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if nargin < 2
    error('Not enough inputs');
end

varargin{1} = ensureType(varargin{1});
expectedSamplerate = varargin{1}.samplerate;
expectedDatalength = varargin{1}.data_length;

% make sure that the inputs are compatible
for i = 2:nargin
   varargin{i} = ensureType(varargin{i});
   assert(varargin{i}.samplerate == expectedSamplerate,...
      'All inputs must have the same sampling frequency');
   assert(varargin{i}.data_length == expectedDatalength,...
      'All inputs must have the same trace length');
end

c = varargin{1};
c.corrmatrix = [];
c.lags = [];
c.stat = [];
c.link = [];
c.clust = [];

for i = 2:nargin
    cin = varargin{i};
    c.traces = cat(1,c.traces,cin.traces);    
    c.trig = cat(1,c.trig,cin.trig);
end
end

function c = ensureType(c)
   if ~isa(c,'NewCorrelation')
      c = NewCorrelation(c); % c must be a correlation or be convertable into one.
   end
end
         


