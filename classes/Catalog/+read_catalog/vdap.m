function self=vdap(filename)
%readEvents.vdap read Hypoellipse summary files and PHA pickfiles
%   based on Montserrat analog network
%   cObject = read_vdap(filename) will read the catalog file, and create a
%   Catalog object
%
%   Summary file has lines like:
%
%   PHA phase file has lines like:
%   MGHZEP 1 950814071436.76
%   MSPTIPU0 950814071437.96
%   MGATEPU0 950814071437.92                                              00011
%   MLGT PD0 950814071438.09       39.41 S 2
%   MWHTEPD1 950814071437.61       38.78 S 2                              00009
%   1-4: sta code
%   5:   E or I
%   6:   P (or blank)
%   7:   U or D
%   8:   quality 0-4
%  10-24: YYMMDDhhmmss.ii for P
%  31-35: ss.ii for S
%  37:   S (or blank)
%  39:   quality 0-4
% Glenn Thompson 2014/11/14

    %% read the headers and data
    fid = fopen(phafilename);
    tline = fgetl(fid);
    while ischar(tline)
        tline = fgetl(fid);
        stacode = tline(1:4);
        p_eori = tline(5);
        p = tline(6);
        p_uord = tline(7);
        p_qual = tline(8);
        p_datetime = tline(10:24);
        s_datetime = tline(31:35);
        s = tline(37);
        s_qual = tline(39);
    end
    fclose(fid);


end

