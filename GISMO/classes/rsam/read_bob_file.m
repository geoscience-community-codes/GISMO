function self=read_bob_file(varargin)
%READ_BOB_FILE Load RSAM-like data from a BOB file into a SAM object.
% SAM is a generic term used here to represent any continuous data
% sampled at a regular time interval (usually 1 minute). This is a 
% format widely used within the USGS Volcano Hazards Programme which
% originally stems from the RSAM system (Endo & Murray, 1989)
%
% Written for loading and plotting RSAM data at the Montserrat Volcano 
% Observatory (MVO), and then similar measurements derived from the VME 
% "ltamon" program and ampengfft and rbuffer2bsam which took Seisan 
% waveform files as input. 
%
% RSAM data are historically stored in "BOB" format, which consists
% of a 4 byte floating number for each minute of the year, for a 
% single station-channel.
%
% s = read_bob_file('file', file, 'snum', snum, 'enum', enum, 'sta', sta, 'chan', chan, 'measure', measure, 'seismogram_type', seismogram_type, 'units', units)
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
% See also: sam, oneMinuteData
    self = rsam(); % Create a blank sam object
    
    [file, self.snum, self.enum, self.sta, self.chan, self.measure, self.seismogram_type, self.units, self.dnum, self.data] = ...
        matlab_extensions.process_options(varargin, 'file', '', 'snum', self.snum, 'enum', self.enum, 'sta', self.sta, ...
        'chan', self.chan, 'measure', self.measure, 'seismogram_type', self.seismogram_type, 'units', self.units, 'dnum', self.dnum, 'data', self.data);

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
                self.snum = max([self.snum datenum(yyyy,1,1)]);
                self.enum = min([self.enum datenum(yyyy,12,31,23,59,59)]);
            end
        end

        % Generate a list of files
        self = findfiles(self, file);

        % Load the data
        for f = self.files
            if f.found
                self = self.load(f);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
function self = findfiles(self, file)
    % Generate a list of files corresponding to the file pattern,
    % snum and enum given.

    filenum = 0;

    % substitute for station
    file = regexprep(file, 'SSSS', self.sta);

    % substitute for channel
    file = regexprep(file, 'CCC', self.chan);

    % substitute for measure
    file = regexprep(file, 'MMMM', self.measure);             

    % set start year and month, and end year and month
    [syyy sm]=datevec(self.snum);
    [eyyy em]=datevec(self.enum);

    for yyyy=syyy:eyyy

        filenum = filenum + 1;
        files(filenum) = struct('file', file, 'snum', self.snum, 'enum', self.enum, 'found', false);

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
        files(filenum).file = regexprep(files(filenum).file, 'YYYY', sprintf('%04d',yyyy) );
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
function self = load(self, f)
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

