function [rsamobjects, ah]=plotrsam(sta, chan, snum, enum, DATAPATH)
% [rsamobjects, ah]=plotrsam_wrapper(sta, chan, snum, enum, DATAPATH)
% 
%   Inputs:
%       sta - station code
%       chan - channel code
%       snum - start datenum
%       enum - end datenum
%       DATAPATH - path to data, including pattern
%
%   Outputs:
%       rsamobjects - vector of rsam objects
%       ah - vector of axes handles
%
%   Examples:
%       1. Data from the digital seismic network, Montserrat
%           DP = fullfile('/raid','data','antelope','mvo','SSSS_CCC_YYYY.DAT');
%           [rsamobjects, ah] = rsam.plotrsam('MBWH','SHZ',datenum(2001,2,24), datenum(2001,3,3), DP);
%       2. Data from the analog seismic network, Montserrat
%           DP = fullfile(DROPBOX, 'DOME', 'SEISMICDATA', 'RSAM_1', 'SSSSYYYY.DAT');
%           [rsamobjects, ah] = rsam.plotrsam('MWHZ','',datenum(1996,7,1), datenum(1996,8,13), DP);
%   Could use the following logic in a wrapper to decide DP:
%       strfind(sta{i},'MB') & ~strcmp(sta{i},'MBET')

    % validate
    if nargin ~= 5
        help rsam>plotrsam()
        return
    end

    % initialise
    if ~iscell(sta)
        sta={sta};
    end
    if ~iscell(chan)
        chan={chan};
    end
    numsta = length(sta);
    numrsams = 0;
    rsamobjects = [];
    ah = [];

    % load data
    for i=1:numsta
        s = rsam('file', DATAPATH, 'snum', snum, 'enum', enum, 'sta', sta{i},'chan',chan{i});
        if ~isempty(s.data)
            numrsams = numrsams + 1;
            rsamobjects = [rsamobjects resample(s.despike(100))];
            %ah(i)=subplot(numsta,1,i),plot(resample(s.despike(10)));
        end
    end

    % plot data
    if numrsams > 0
        figure
        for i=1:numrsams
            ah(i) = subplot(numrsams, 1, i), plot(rsamobjects(i))
        end
        linkaxes(ah, 'x')
        %datetick('x','keeplimits')
    end
end