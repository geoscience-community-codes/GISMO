function c = norm(c,varargin)

% C = NORM(C)
% This function normalizes the amplitudes of all traces.
% 
% C = NORM(C,'max')
% Normalize to the maximum absolute value of each trace.
% This is the default.
% 
% C = NORM(C,'std')
% Normalize to one half of the standard deviation of the absolute value of
% each trace.
%
% C = NORM(C,METHOD,PRETRIG,POSTTRIG) Normalize traces based on the segment
% of data specified by PRETRIG and POSTTRIG. This is useful for scaling an
% entire trace based on the amplitude of a particular arrival. METHOD may
% be either 'max' or 'std'.
%
% C = NORM(C,SCALE)
% Multiply each trace by SCALE factor, where SCALE is a scalar number.
%
% C = NORM(C,...,INDEX) Apply normalization/scaling only to the traces in
% INDEX. INDEX must appear as the third argument to NORM. 
% 

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end


% CHECK FOR RANGE
if (length(varargin)==3) && isa(varargin{2},'double') && isa(varargin{3},'double')
    c2 = crop(c,varargin{2},varargin{3});
    varargin = varargin(1:end-2);
else
    c2 = c;
end


% CHECK FOR INDEX LIST
if (length(varargin)==2) && isa(varargin{1},'double')
    index  = varargin{2};
    varargin = varargin(1:end-1);
else
    index = 1:get(c,'Traces');
end


% CHOOSE NORMALIZATION TYPE
if (length(varargin)==1) && isa(varargin{1},'char')
    type = varargin{1};
elseif  (length(varargin)==1) && isa(varargin{1},'double')
    type = 'sca';
    scale = varargin{1};
elseif  (nargin==1)
    type = 'max';
else
    error('Incorrect inputs');
end;


% NORMALIZE EACH TRACES
for i = index
    
    % MAX
    if strncmpi(type,'MAX',3)
        d2 = get(c2.W(i),'DATA');
        d = get(c.W(i),'DATA');
        maxd = max(abs(d2));
       if maxd ~= 0
            d = d/maxd;
       end;
       c.W(i) = set(c.W(i),'DATA',d);

    % SCALED
    elseif strncmpi(type,'SCA',3)
        d = get(c.W(i),'DATA');
        d = d * scale;
        c.W(i) = set(c.W(i),'DATA',d);
    
    % STD
    elseif strncmpi(type,'RMS',3) | strncmpi(type,'STD',3)
        d2 = get(c2.W(i),'DATA');
        d = get(c.W(i),'DATA');
        stdd = 0.5 * std(abs(d2));
        if stdd ~= 0
            d = d/stdd;
        end;
        c.W(i) = set(c.W(i),'DATA',d);
    end;
end;

