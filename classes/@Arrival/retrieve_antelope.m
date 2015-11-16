function arrivalObj = retrieve_antelope(dbpath)
%RETRIEVE_ANTELOPE Read arrivals from an Antelope database
% ARRIVALOBJ = RETRIEVE_HYPOELLIPSE(PHAFILENAME) Read an Antelope database into an
% arrival object. Wraps ANTELOPE.DBGETARRIVALS.
%
%   % The output from antelope.dbgetarrivals is a structure containing the fields:
    %   * arid
    %   * sta
    %   * chan
    %   * time (arrival date/time converted from epoch to MATLAB datenum)
    %   * iphase
    %   * amp
    %   * snr
    %   * seaz
    %   * deltim
    %   * iphase
    %   * delta
    %   * otime (origin date/time converted from epoch to MATLAB datenum)
    %   * orid
    %   * evid
    %   * timeres
    %   * traveltime (= time - otime)
%
% Example: 
%     arrivalObj = ARRIVAL.RETRIEVE_ANTELOPE('/opt/antelope/data/db/demo/demo')

%
% See also: ANTELOPE.DBGETARRIVALS

    if nargin==1
        arrivals_struct = antelope.dbgetarrivals(dbpath);
        ctag = ChannelTag.array('',arrivals_struct.sta,'',arrivals_struct.chan);
        ctag = ctag';
        arrivalObj = Arrival(ctag, arrivals_struct.time, arrivals_struct.iphase, ...
            'arid', arrivals_struct.arid, ...
            'orid', arrivals_struct.orid, ...
            'evid', arrivals_struct.evid)
    else
        error(sprintf('%s: Wrong number of arguments',mfilename));
    end
end
