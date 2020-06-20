close all
clear all
load savetospectraldatafile.mat
% how many days in this year?
dv=datevec(this.snum);
yyyy=dv(1);
daysperyear = 365;
if (mod(yyyy,4)==0)
        daysperyear = 366;
end 
disp('got here')
tic
i=1
if length(i)>0
    % slow mode

    for c=1:length(dnumy)
        disp('Using slow mode')
        % write the data, sample by sample
        startminute = round((dnumy(c) - this.snum) * MINUTES_PER_DAY);
        offset = HEADER_BYTES + startminute * 4 * numel(F);
        fid = fopen(this.file,'r+');
        frewind(fid);
        fseek(fid,offset,'bof');
        debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at minute %d',nanmean(datay),this.file,startminute,(MINUTES_PER_DAY*(daysperyear+1))));
        fwrite(fid,datay(:,c),'float32');
        fclose(fid);
    end

else
    % fast mode
    disp('Using fast mode')
    % write the data
    startminute = round((dnumy(1) - this.snum) * MINUTES_PER_DAY);
    offset = HEADER_BYTES + startminute * 4 * numel(F);
    fid = fopen(this.file,'r+','l'); % little-endian. Anything written on a PC is little-endian by default. Sun is big-endian.
    fseek(fid,offset,'bof');
    debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at minute %d',nanmean(datay),this.file,startminute));
    fwrite(fid,datay,'float32');
    fclose(fid);
end
toc

%% read the data back

T= [];
Y = []; 
F2=[];
if ~exist('ctag','var')
    ctag = ChannelTag();
end

if ~isempty(filepattern)

    % Generate a list of files
    %files = findfiles(filepattern, snum, enum, ctag);
    filestruct = filepattern_substitute(filepattern, ctag, [this.snum this.enum]);

    % Load the data
    for filenum = 1:numel(filestruct)
        f = filestruct(filenum);
        if f.found
            f
            datestr(this.snum)
            datestr(this.enum)
            try
                [T, Y, F2] = loadspdatafile(f, T, Y, this.snum, this.enum);
            catch
                warning(sprintf('Error found - could not read spectral data file: %s',f.file));
            end
        else
            warning(sprintf('%s: file not found',f.file));
        end
    end
end
iceweb.spdatatestplot(T,F2,Y)

iceweb.plot_day_spectrogram([], filepattern, ctag, this.snum, this.enum)

%%
function [dnum, data, F] = loadspdatafile(f, dnum, data, snum, enum)
% Purpose:
%    Load data from a spectral data binary file 
%    
% Input:
%    self.f - a structure which contains 'file', 'snum', 'enum' and 'found' parameters
% Author:
%   Glenn Thompson, MVO, 2000
    debug.printfunctionstack('>');

    MINUTES_PER_DAY = 1440;
    sizeOfVal = 4;  % bytes
        
    if snum > f.snum
        startminute = round((snum - f.snum)*MINUTES_PER_DAY);
    else
        startminute = 0;
    end
    if enum > f.enum
        endminute = round((f.enum - f.snum)*MINUTES_PER_DAY);
    else
        endminute = round((enum - f.snum)*MINUTES_PER_DAY)-1;
    end
    nminutes = endminute - startminute + 1;

    % create dnum & blank data vector
    dnum_ = ceilminute(f.snum)+(0:nminutes-1)/MINUTES_PER_DAY;

    if f.found    
        % file found
        debug.print_debug(0, sprintf( 'Loading data from %s, minute %d to %d', ...
             f.file, startminute, endminute )); 

        fid=fopen(f.file,'r', 'l'); % big-endian for Sun, little-endian for PC
        header_bytes = fscanf(fid,'%6d ',1);
        sizeF = fscanf(fid,'%04d ',1);
        F = fscanf(fid,'%f ',sizeF);
        
        % Position the pointer
        nvalues = nminutes * sizeF;
        offset = startminute * sizeF * sizeOfVal + header_bytes;
        frewind(fid);
        fseek(fid,offset,'bof');

        % Read the data
        [data_, ~] = fread(fid, nvalues, 'float32');
        fclose(fid);
        debug.print_debug(0, sprintf('max of data loaded is %e',nanmax(nanmax(data_))));

        % Transpose to give same dimensions as dnum
        data_=data_';

        % Test for Nulls
        datafound = any(data_ > 0);
        data_ = reshape(data_, sizeF, numel(dnum_));

        % Now paste together the matrices
        dnum = catmatrices(dnum_, dnum);
        data = catmatrices(data_, data);

        if ~datafound
            debug.print_debug(0, sprintf('%s: zero data only from %s',mfilename,f.file));
        end

        % eliminate any data outside range asked for
        myRange = dnum >= f.snum & dnum <= f.enum;
        dnum = dnum(myRange);
        data = data(:,myRange);

        % Fill NULL values with NaN
        data(data == -998 | data == 0) = NaN;
        
    
    else
       datafound = false;
       debug.print_debug(0, sprintf('File %s not found', f.file));
    end
    
    debug.printfunctionstack('<');

end