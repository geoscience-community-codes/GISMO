function rsamobj=load(varargin)
%RSAM.LOAD Load RSAM-like data from a BOB file into an RSAM object.
% RSAM is a generic term used here to represent any continuous data
% sampled at a regular time interval (usually 1 minute). This is a 
% format widely used within the USGS Volcano Hazards Programme which
% originally stems from the RSAM system (Endo & Murray, 1989)
%
% RSAM data are historically stored in "BOB" format, which consists
% of a 4 byte floating number for each minute of the year, for a 
% single station-channel.
%
% Usage:
%
% s = rsam.load('file', file, 'snum', snum, 'enum', enum, 'sta', sta, 'chan', chan, 'measure', measure, 'seismogram_type', seismogram_type, 'units', units)
%
%     file        % the path to the file. Substitutions enabled
%                 'SSSS' replaced with sta
%                 'CCC' replaced with chan
%                 'MMMM' replaced with measure
%                 'YYYY' replaced with year (from snum:enum)
%                 These allow looping over many year files
%     snum        % the start datenum
%     enum        % the end   datenum
%     sta         % station
%     chan        % channel
%     measure     % statistical measure, default is 'mean'
%     seismogram_type % e.g. 'velocity' or 'displacement', default is 'raw'
%     units       % units to label y-axis, e.g. 'nm/s' or 'nm' or 'cm2', default is 'counts'
%
% Example: Plot the entire RSAM record for station MLGT (MVO analog
% network)
% 
%     file = '/Users/thompsong/Dropbox/MVOnetwork/SEISMICDATA/RSAM_1/%station%year.DAT';
%     sta = 'MLGT';
%     chan = 'SHZ';
%     snum = datenum(1995,7,1);
%     enum = datenum(2004,12,31,23,59,59);
%     s = rsam.load('file', file, 'snum', snum, 'enum', enum, 'sta', sta, 'chan', chan);
%     s.plot()
%
% See also: sam, oneMinuteData
    self = rsam(); % Create a blank sam object
    
    [file, self.snum, self.enum, self.sta, self.chan, self.measure, self.seismogram_type, self.units, self.dnum, self.data] = ...
        matlab_extensions.process_options(varargin, 'file', '', 'snum', self.snum, 'enum', self.enum, 'sta', self.sta, ...
        'chan', self.chan, 'measure', self.measure, 'seismogram_type', self.seismogram_type, 'units', self.units, 'dnum', self.dnum, 'data', self.data);

    % make sta & chan same length & cell arrays
    self.sta = cellstr(self.sta);
    self.chan = cellstr(self.chan);
    if numel(self.sta)>1 & numel(self.chan)==1
        for c=2:numel(self.sta)
            self.chan{c} = self.chan{1};
        end
    end
    if numel(self.chan)>1 & numel(self.sta)==1
        for c=2:numel(self.chan)
            self.sta{c} = self.sta{1};
        end
    end     
    
    % create an rsam object corresponding to each request
    for c=1:numel(self.sta)
        rsamobj(c) = self;
        rsamobj(c).sta = self.sta{c};
        rsamobj(c).chan = self.chan{c};

        %%%% CREATING SAM OBJECT FROM A BOB FILE            
        % check if filename has a year in it, if it does
        % make sure snum doesn't start before this year
        % and enum doesn't end after this year
        if ~isempty(file)
            dummy = regexp(file, '(\d+)', 'match');
            if ~isempty(dummy)
                yyyy = str2num(dummy{end});
                d=datevec(now);yearnow=d(1);clear d
                if yyyy>=1980 & yyyy<=yearnow
                    rsamobj(c).snum = max([rsamobj(c).snum datenum(yyyy,1,1)]);
                    rsamobj(c).enum = min([rsamobj(c).enum datenum(yyyy,12,31,23,59,59)]);
                end
            end
        
            % Generate a list of files
            rsamobj(c) = findfiles(rsamobj(c), file);

            % Load the data
            for f = rsamobj(c).files
                if f.found
                    rsamobj(c) = readbob(rsamobj(c),f);
                end
            end
        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
function self = findfiles(self, file)
    % Generate a list of files corresponding to the file pattern,
    % snum and enum given.

    filenum = 0;
        
    thisfile = file;

    % substitute for station
    thisfile = regexprep(thisfile, '%station', self.sta);

    % substitute for channel
    thisfile = regexprep(thisfile, '%channel', self.chan);

    % substitute for measure
    thisfile = regexprep(thisfile, '%measure', self.measure);             

    % set start year and month, and end year and month
    [syyy sm]=datevec(self.snum);
    [eyyy em]=datevec(self.enum);

    for yyyy=syyy:eyyy

        filenum = filenum + 1;
        files(filenum) = struct('file', thisfile, 'snum', self.snum, 'enum', self.enum, 'found', false);

        % Check year against start year 
        if yyyy~=syyy
            % if not the first year, start on 1st Jan
            files(filenum).snum = datenum(yyyy,1,1);
        end

        % Check year against end year
        if yyyy~=eyyy
            % if not the last year, end at 31st Dec
            files(filenum).enum = datenum(yyyy,12,31,23,59,59);
        end   

        % Substitute for year        
        files(filenum).file = regexprep(files(filenum).file, '%year', sprintf('%04d',yyyy) );
        fprintf('Looking for file: %s',files(filenum).file);

        if exist(files(filenum).file, 'file')
            files(filenum).found = true;
            fprintf(' - found\n');
        else
            fprintf(' - not found\n');
        end
    end
    self.files = files;
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
function self = readbob(self, f)
% Purpose:
%    Loads derived data from a binary file in the BOB RSAM format
%    The pointer position at which to reading from the binary file is determined from f.snum 
%    Load all the data from f.snum to f.enum. So if timewindow is 12:34:56 to 12:44:56, 
%    it is the samples at 12:35, ..., 12:44 - i.e. 10 of them. 
%    
% Input:
%    f - a structure which contains 'file', 'snum', 'enum' and 'found' parameters
% Author:
%   Glenn Thompson, MVO, 2000

    % initialise return variables
    datafound=false;
    dnum=[];
    data=[];

    [yyyy mm]=datevec(f.snum);
    days=365;
    if mod(yyyy,4)==0
        days=366;
    end

    datapointsperday = 1440;
    headersamples = 0;
    tz=0;
    if strfind(f.file,'RSAM')
        headersamples=datapointsperday;
        tz=-4;
    end
    startsample = ceil( (f.snum-datenum(yyyy,1,1))*datapointsperday)+headersamples;
    endsample   = (f.enum-datenum(yyyy,1,1)) *datapointsperday + headersamples;
    %endsample   = floor( max([ datenum(yyyy,12,31,23,59,59) f.enum-datenum(yyyy,1,1) ]) *datapointsperday);
    nsamples    = endsample - startsample + 1;

    % create dnum & blank data vector
    dnum = matlab_extensions.ceilminute(f.snum)+(0:nsamples-1)/datapointsperday - tz/24;
    data(1:length(dnum))=NaN;

    if f.found    
        % file found
        debug.print_debug(sprintf( 'Loading data from %s, position %d to %d of %d', ...
             f.file, startsample,(startsample+nsamples-1),(datapointsperday*days) ),3); 

        fid=fopen(f.file,'r', 'l'); % big-endian for Sun, little-endian for PC

        % Position the pointer
        offset=(startsample)*4;
        fseek(fid,offset,'bof');

        % Read the data
        [data,numlines] = fread(fid, nsamples, 'float32');
        fclose(fid);
        debug.print_debug(sprintf('mean of data loaded is %e',nanmean(data)),1);

        % Transpose to give same dimensions as dnum
        data=data';

        % Test for Nulls
        if length(find(data>0)) > 0
            datafound=true;
        end    
    end

    % Now paste together the matrices
    self.dnum = matlab_extensions.catmatrices(dnum, self.dnum);
    self.data = matlab_extensions.catmatrices(data, self.data);

    if ~datafound
        debug.print_debug(sprintf('%s: No data loaded from file %s',mfilename,f.file),1);
    end

    % eliminate any data outside range asked for - MAKE THIS A
    % SEPARATE FN IF AT ALL
    i = find(self.dnum >= self.snum & self.dnum <= self.enum);
    self.dnum = self.dnum(i);
    self.data = self.data(i);

    % Fill NULL values with NaN
    i = find(self.data == -998);
    self.data(i) = NaN;
    i = find(self.data == 0);
    self.data(i) = NaN;

end

