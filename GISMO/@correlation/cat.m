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



if nargin <= 1
    error('Not enough inputs');
end
for i = 1:nargin
    if get(varargin{i},'Fs') ~= get(varargin{1},'Fs')
        error('All inputs must have the same sampling frequency');
    end
    if size(get(varargin{i},'DATA_LENGTH'),1) ~= size(get(varargin{1},'DATA_LENGTH'),1)
        error('All inputs must have the same trace length');
    end
end


c = varargin{1};
c.C = [];
c.L = [];
c.stat = [];
c.link = [];
c.clust = [];
for i = 2:nargin
    for i = 1:nargin
        if ~isa(c,'correlation')
            error('All inputs but be correlation objects');
        end
    end
    cin = varargin{i};
    c.W = cat(1,c.W,cin.W);    
    c.trig = cat(1,c.trig,cin.trig);
end




