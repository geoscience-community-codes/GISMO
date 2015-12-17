function makebobfile(outfile, days);
    % makebobfile(outfile, days);
    datapointsperday = 1440;
    samplesperyear = days*datapointsperday;
    a = zeros(samplesperyear,1);
    % ensure host directory exists
    mkdir(fileparts(outfile));
    % write blank file
    fid = fopen(outfile,'w');
    fwrite(fid,a,'float32');
    fclose(fid);
end