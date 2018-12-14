function make_spectral_data_file(outfile, days, MINUTES_PER_DAY, F, HEADER_BYTES)
    % make_spectraldata_file(outfile, days);
    a = zeros(HEADER_BYTES/4 + MINUTES_PER_DAY*numel(F)*round(days),1);
    % ensure host directory exists
    mkdir(fileparts(outfile));
    % write blank file
    fid = fopen(outfile,'w');
    fwrite(fid,a,'float32');
    % header
    frewind(fid);
    fprintf(fid,'%6d\n',HEADER_BYTES);
    fprintf(fid,'%4d\n',numel(F));
    fprintf(fid,'%7.2f ',F);
    fprintf(fid,'\n');
    % close
    fclose(fid);
end