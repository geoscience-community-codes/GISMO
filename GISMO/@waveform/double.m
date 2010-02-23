function n = double(W, option)
%DOUBLE returns a waveform's data as a double type
%   N = double(waveform  [, option] )
%   this is just a fancy way of saying get(W,'data')
%   but can handle vectors of W. The data lengths of the vectors do not
%   need to be the same.  By default it will zero-pad the end of all short
%   vectors.  Using the OPTION, you can specify a NaN padding instead.
%
%   Input Arguments
%       WAVEFORM: a waveform object   1xN DIMENSIONAL
%       OPTION: optional, the string 'NaN'.  If specified, padding will be
%               with NaN; Otherwise, data is zero padded on the end.
%
%   Output Arguments
%       N: the columns of data
%
%   example:
%       % W(1) is a waveform object with data [0 1 2 5 3]
%       % W(2) is a waveform object with data [2 5]
%
%       Y = double(W);
%       % Y is now [[ 0 2; 1 5; 2 0; 5 0; 3 0]
%
%       Z = double(W,'NaN'); pads with NaN instead of zeros
%       % Z is now [ 0 2; 1 5; 2 NaN; 5 NaN; 3 NaN]
%
%
%
% See also WAVEFORM/GET, NAN

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if ~exist('option','var')
    option = 'zeros';
else
    option = lower(option);
    switch option
        case 'nan' %do nothing, we're set...
        otherwise
            option = 'zeros';
    end
end
%  force dimensionality

if numel(W) ~= length(W) 
  error('Waveform:double:invalidWaveformDimensions',...
    'Waveforms must be 1 x N or N x 1');
end

% find out how many elements in each waveform
m = get(W,'data_length');
%emptywaves = find(m==0);
try
    if sum(m==0)~=0 % this is not a typo
        error('Waveform:double:forceCatch',...
          'Forcing move to catch'); %force us to the catch section...
    end
    % simplest way of doing this
    
        n = [W(:).data];
catch %craps out if not all data lengths the same

    %create array to match outgoing datafile
    eval(['n = ', option, '(max(m),numel(W));']); %akin to n=zeros(max(m,x))

    % fill with the actual data, end result is zero or nan padded
    for x=1:numel(W)
        n(1:m(x),x) = get(W(x),'data');
    end
end