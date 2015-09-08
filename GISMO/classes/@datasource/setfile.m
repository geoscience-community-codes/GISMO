function ds = setfile(ds, desc_string, varargin)
%SETFILE associates a datasource object with a file (or directory)
%   ds = setfile(ds, descriptor_string, [var1, var2, ... varN])
%   where;
%   - DS is the datasource object
%   - DESCRIPTOR_STRING is a format statement, like that from sprintf.
%   - var1...varN are optional variable names that are used to fill in the
%     information from the format statement.
%      valid variable names (of type integer, or format string of '%d')
%         YEAR, DAY, HOUR, MINUTE, SECOND, JDAY (<-- julian day) 
%
%      valid variable names (of type string, or format string of '%s')
%         station, channel, location, network
%
%   this provides a powerful tool that allows the program to navigate a
%   wide variety of files and directories based upon date or SCNL
%   information. 
%
% ------------------------------------------------------------------------
% EXAMPLE #1:
% Assume data files are stored in the following directories:
%   /DATA/year2006/04/OKCF.dat
%   /DATA/year2006/04/OKFG.dat
%   /DATA/year2006/05/OKCF.dat 
%   ...etc...
%
%  To find any given peice of data requires the year, month (zero padded!),
%  and the station name.
%
%  You can specify which file to use by setting the filename as follows:
%  ds = setfile(ds,'/DATA/year%04d/%02d/%s.dat','year','month','station');
%  
%  * notice that each percent sign (%) has a corresponding term.  That is:
%    %04d --> 'year',   %02d --> 'month', and %s -->'station'
%  * The numbers and symbols between the '%' and the first alphabetic
%    character provide additional formatting details. 
%    * any number greater than zero means "use up this many spaces"
%    * a leading zero means "fill up leading space with zeros"
%
%    ex. %04d -> write the number with 4 spaces, and pad with zeros.
%
% ------------------------------------------------------------------------
% EXAMPLE #2:
% The method waveform/which_archive can be supplanted by
% the following setfile call...
% ds = setfile(ds, ...
%            '/iwrun/op/db/archive/archive_%04d/archive_%04d_%02d_%02d',...
%            'year','year','month','day')
% - - - - 
% For access to a specific, date independent, SCNL independent database:
% ds = setfile(ds,'mydatabasename');
%
% see also sprintf, datasource/getfilename


if ~exist('desc_string','var') || isempty(desc_string)
  ds.usefile = false;
  ds.file_string = {};
  ds.file_args = {};
  return
end

% the number of arguments should equal the number of %somethings
% ... except where '%' is preceded by a  '\'
n = find(desc_string == '%');
z=0; %currently not accepting % in filename!!!
%z = sum('\'== desc_string(n(n>2)-1)); 
expectedArgumentCount = numel(n) - z;
if numel(varargin) ~= expectedArgumentCount
  error('Datasource:FileArgumentMismatch', ...
    'the number of file arguments provided (%d) doesn''t match the number of arguments requested by the filestring %d',...
    numel(varargin),expectedArgumentCount);
  
end
varargin = lower(varargin);

%check to be sure arguments are valid
validVariables = {'year', 'month', 'day', 'hour', 'minute', 'second',...
  'station', 'channel','location','network', 'jday'};
for i=1:numel(varargin)
  if ~ismember(varargin{i},validVariables)
    error('Datasource:FileArgumentError',...
      'unrecognized file argument [%s].',varargin{i});
  end
end

ds.file_string = desc_string;
ds.file_args = varargin;
ds.usefile = true;
