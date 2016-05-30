function self = load(self)
% Purpose:
%    Loads derived data from a binary file in the BOB RSAM format
%    The pointer position at which to reading from the binary file is determined from f.snum 
%    Load all the data from f.snum to f.enum. So if timewindow is 12:34:56 to 12:44:56, 
%    it is the samples at 12:35, ..., 12:44 - i.e. 10 of them. 
%    
% Input:
%    self.f - a structure which contains 'file', 'snum', 'enum' and 'found' parameters
% Author:
%   Glenn Thompson, MVO, 2000

    % initialise return variables

    f = self.files;
    
    [yyyy, ~]=datevec(f.snum);
    days=365;
    if mod(yyyy,4)==0
        days=366;
    end

    datapointsperday = 1440;
    headersamples = 0;
    tz=0;
    if strfind(f.file,'RSAM') 
        headersamples=datapointsperday;% for PC-SEIS RSAM data there is a 1 day header
        tz=-4;% for Montserrat RSAM data time zone is off by 4 hours
    end
    startsample = ceil( (f.snum-datenum(yyyy,1,1))*datapointsperday)+headersamples;
    endsample   = (f.enum-datenum(yyyy,1,1)) *datapointsperday + headersamples;
    nsamples    = endsample - startsample + 1;

    % create dnum & blank data vector
    dnum_ = ceilminute(f.snum)+(0:nsamples-1)/datapointsperday - tz/24;
    data_ = nan(1,length(dnum_));

    if f.found    
        % file found
        debug.print_debug(0, sprintf( 'Loading data from %s, position %d to %d of %d', ...
             f.file, startsample,(startsample+nsamples-1),(datapointsperday*days) )); 

        fid=fopen(f.file,'r', 'l'); % big-endian for Sun, little-endian for PC

        % Position the pointer
        offset=(startsample)*4;
        fseek(fid,offset,'bof');

        % Read the data
        [data_, ~] = fread(fid, nsamples, 'float32');
        fclose(fid);
        debug.print_debug(0, sprintf('mean of data loaded is %e',nanmean(data_)));

        % Transpose to give same dimensions as dnum
        data_=data_';

        % Test for Nulls
        datafound = any(data_ > 0);
    else
       datafound = false;
       debug.print_debug(0, sprintf('File %s not found', f.file));
    end

    % Now paste together the matrices
    self.dnum = catmatrices(dnum_, self.dnum);
    self.data = catmatrices(data_, self.data);

    if ~datafound
        debug.print_debug(0, sprintf('%s: No data loaded from file %s',mfilename,f.file));
    end

    % eliminate any data outside range asked for
    myRange = self.dnum >= self.snum & self.dnum <= self.enum;
    self.dnum = self.dnum(myRange);
    self.data = self.data(myRange);

    % Fill NULL values with NaN
    self.data(self.data == -998 | self.data == 0) = NaN;

end