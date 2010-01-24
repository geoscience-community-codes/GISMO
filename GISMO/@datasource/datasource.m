function ds = datasource(whichsource, varargin)
%DATASOURCE constructor for a datasource object.
% The datasource object is the go-between between the waveform class (or
% any other class) and whichever sort of database or file scheme is in use.
%
% ds = datasource(whichsource, filename) is the most basic implementation.
%    Data from file FILENAME will be interpreted to be of type WHICHSOURCE.  
%   
%    default WHICHSOURCE values are 'antelope','file','sac', and 'seisan'
%
% ds = datasource(whichsource, fileformatstring[, param1[,...]])
%    The FILEFORMATSTRING may have additional formatting parameters,
%    allowing the datasource to traverse directory trees or make
%    intelligent decisions about which files to access.  These formatting
%    parameters follow the sprintf convetions: each starts   with a '%'
%    followed by the type.
%        %s : string        %f : float      %d : integer
%      these formatters can be further modified. ex.
%        %04d : 4-digit integer, zero padded
%
%      Each use of a formatter must be accompanied by a matching
%      parameter.  See the example section, below.
%        %d is used for  'YEAR','DAY','JDAY','HOUR','MINUTE','SECOND'
%        %s is used for 'STATION','CHANNEL'
%  
%        when an object is requested, the scnl, start, and end times are
%        used to determine exactly which file(s) to consult.
%
% ds = datasource(interpreter_function,fileformatstring [,param1[,...]])
%    the INTERPRETER_FUNCTION is a function handle to a user-created
%    function capable of receiving a single filename and returning
%    an array of objects.  
%      Ex. if I have a function declared :
%           function objects = load_foobar(filename)
%        then, INTERPRETER_FUNCTION would be @load_foobar
%
% ds = datasource('winston',servername, portnumber)
%    this usage associates a datasource object with a winston waveserver.
%
% to get the default continuous antelope database, use 'uaf_continuous'
%
% --------------- EXAMPLES --------------------
% *Example 1: (FILE) I would like to access a specific file of waveforms,
% saved from matlab.
%
% ds = datasource('file','C:/DATA/workingfile')
%
% *Example 2: (ANTELOPE) the continuous waveform archive (antelope based),
% in Fairbanks, could be set up as follows:
%
% ds = datasource('antelope', ...
%      '/iwrun/op/db/archive/archive_%04d/archive_%04d_%02d_%02d',...
%      'year','year','month','day');
%
% 
% *Example 3: (USER_DEFINED) I have a series of .CGR files stored in files
% named for each station and Julian day, in a directory (on drive "T"named
% for the year. I wrote my  own interpreter, a function called "load_cgr". 
%
% ds = datasource(@load_cgr,'T:/%04d/%s%03d.cgr','year','jday','station');
%
%
% *Example 4: (WINSTON) All datafiles are accessible through a winston
% wave server, with server address myserver.uaf.edu, port 12345:
%
% ds = datasource('winston','myserver.uaf.edu',12345);
%
%
% -------------------
% RECOMMENDATION: commonly used datasources may best be saved saved in
% either a .mat datafile or a .m script, where they can be loaded without
% constantly needing to be re-entered
%
% more information about defining filenames and directory trees can be
% found by typing:
% help datasource/setfile
%
%
% see also datasource/setfile

% VERSION: 1.1
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/26/2009

ds.type=  'none';
ds.file_string = '';
ds.file_args = {};
ds.server_name = '';
ds.port_number = [];
ds.usefile = false;
ds.interpreter = @void_interpreter;
ds = class(ds,'datasource');
if nargin == 0
  return
end
if isa(whichsource,'function_handle')
  ds.interpreter = whichsource;
  ds.type = 'user_defined';
  if numel(varargin) == 0
        error('when setting the datasource to a user-defined type, the filesource must be declared');
      end
  ds = setfile(ds,varargin{1:end});
else
  switch lower(whichsource)
    case 'antelope'
      switch numel(varargin)
        case 0
          %do nothing, the default case will be handled by waveform
        otherwise
          ds = setfile(ds,varargin{:});
          ds.type = whichsource;
      end
      
    case {'file','sac', 'seisan'}
      if numel(varargin) == 0
        error('when setting the datasource to %s the filesource must be declared',upper(whichsource));
      end
      ds = setfile(ds,varargin{:});
      ds.type = whichsource;
      
    case 'winston' %expect:type, databasename, port
      switch (nargin)
        case {1 2}
          error('datasource type WINSTON requires both a server and port number');
        case 3
          %fine
        otherwise
      end
      if ~ischar(varargin{1}),
        error('the second parameter for a WINSTON datatype must be a server name');
      end
      if ~isnumeric(varargin{2})
        error('the third parameter for a WINSTON datatype must be a port number');
      end
      ds.server_name = varargin{1};
      ds.port_number = varargin{2};
      ds.type = whichsource;
      
      % now, the special cases -------------------------------
      
    case 'uaf_continuous'
      %default in-house antelope file
      ds = datasource('antelope', ...
        '/iwrun/op/db/archive/archive_%04d/archive_%04d_%02d_%02d',...
        'year','year','month','day');
      % end special cases ------------------------------------
      
    otherwise
      error('Current valid datasources are: ANTELOPE, SAC, FILE, WINSTON, SEISAN, or a function handle to an interpeter function');
  end
end