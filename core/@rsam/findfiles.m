function self = findfiles(self, file)
    % Generate a list of files corresponding to the file pattern,
    % snum and enum given.

    % substitute for station
    file = regexprep(file, 'SSSS', self.sta);

    % substitute for channel
    file = regexprep(file, 'CCC', self.chan);

    % substitute for measure
    file = regexprep(file, 'MMMM', self.measure);             

    % set start year and month, and end year and month
    [syyy, ~]=datevec(self.snum);
    [eyyy, ~]=datevec(self.enum);

    years = syyy:eyyy;
    if numel(years) <= 1
       starts = self.snum;
       ends = self.enum;
    else
       %unless it is 1st year, start on 1st Jan
       starts = [self.snum, datenum(syyy+1:eyyy,1,1)];
       %unless it is last year, end on 31st Dec
       ends = [datenum(syyy:eyyy-1,12,31,23,59,59), self.enum];
    end

    files_(numel(starts)) = struct(...
       'file', []...     % file name
       , 'snum', [] ...  % start date
       , 'enum', [] ...  % end date
       , 'found', []);   % file exists

    for N = 1 : numel(years)
       files_(N).snum = starts(N);
       files_(N).enum = ends(N);

       fileWithYearReplaced = regexprep(file, 'YYYY', num2str(years(N), '%04d') );
       debug.print_debug(2, 'Output file: %s', fileWithYearReplaced);
       files_(N).file = fileWithYearReplaced;

       files_(N).found = exist(fileWithYearReplaced, 'file');
       if files_(N).found
          debug.print_debug(3,' - found\n');
       else
          debug.print_debug(2,' - not found\n');
       end
    end
    self.files = files_;
end