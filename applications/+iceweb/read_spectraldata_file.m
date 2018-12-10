function [dnum,data,F]=read_spectraldata_file(filepattern, snum, enum, ctag)
%READ_SPECTRALDATA_FILE Load RSAM-like data from a spectraldata binary file 
%
% [dnum,data] = read_spectraldata_file(filepattern, snum, enum, ctag)
%     filepattern % the path to the file. Substitutions enabled
%                 'SSSS' replaced with sta
%                 'CCC' replaced with chan
%                 'MMMM' replaced with measure
%                 'YYYY' replaced with year (from snum:enum)
%                 'SCN' replaced with STATION_CHANNEL_NETWORK
%                 'NSLC' replaced with NETWORK_STATION_LOCATION_CHANNEL
%                 These allow looping over many year files
%     snum        % the start datenum
%     enum        % the end   datenum
%     ctag        % ChannelTag of the station/channel



% See also: sam, oneMinuteData
    debug.printfunctionstack('>');
    dnum = [];
    data = []; 
    F=[];
    if ~exist('ctag','var')
        ctag = ChannelTag();
    end

    if ~isempty(filepattern)

        % Generate a list of files
        %files = findfiles(filepattern, snum, enum, ctag);
        filestruct = filepattern_substitute(filepattern, ctag, [snum enum]);

        % Load the data
        for filenum = 1:numel(filestruct)
            f = filestruct(filenum);
            if f.found
                [dnum, data, F] = load(f, dnum, data, snum, enum);
            else
                warning(sprintf('%s: file not found',f.file));
            end
        end
    end
    debug.printfunctionstack('<');
end


%%
function [dnum, data, F] = load(f, dnum, data, snum, enum)
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


