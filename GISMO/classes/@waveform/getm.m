function varargout = getm(w,varargin)
%GETM Get MULTIPLE waveform properties
%   a = getm(waveform, propertyA)
%   [a b c ...] = getm(waveform, propA [, propB] [, propC] [, ...])
%   
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%       PROPERTYA, PROPERTYB, etc.: string containing a valid waveform
%       property.  For valid properties, check out waveform/get
%
%   Output Arguments
%       a, b, c, etc... : variables for receiving the values from get.  
%
%   This routine is basically a glorified gofer and will call get for as
%   many properties as you give it.  If you are using an N-dimensional
%   waveform, then each variable will return it's variables in the same
%   sized variable.
%
%   example:
%      [s c d] = getm(w, 'station', 'component', 'start')
%      % returns station name in s, component in c, startdate in d
%      % this saves the overhead with many calls to the get function.
%
%   Note, Must have as many output variables as requested properties
%
%
%   See also WAVEFORM/GET for valid properties and such

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/6/2007

error (nargoutchk(nargin, nargin, nargout+1));

for n = 1 : nargin-1;
    varargout{n} = get(w,varargin{n});
end