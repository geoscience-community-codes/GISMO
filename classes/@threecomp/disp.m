function disp(TC)

%DISP Display threecomp object
%   DISP(TC)

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% TEST FOR NON-EMPTY TRACE DATA


if numel(TC)>1
    [n,m] = size(TC); % char returns a cell array
    disp([num2str(n) ' x ' num2str(m) ' threecomp object']);
end

if numel(TC)==1
    if any(isempty(TC.traces))
        disp('**Empty waveforms. Use VERIFY function');
    else
        net = get(TC.traces(1),'NETWORK');
        sta = get(TC.traces(1),'STATION');
        chan1 = get(TC.traces(1),'CHANNEL');
        chan2 = get(TC.traces(2),'CHANNEL');
        chan3 = get(TC.traces(3),'CHANNEL');
        chan = [chan1(1:end-1) '[' chan1(end) chan2(end) chan3(end) ']'];
        loc = get(TC.traces(1),'LOCATION');
        disp(['    net_sta_chan_loc:    ' net '_' sta '_' chan '_' loc]);
        
        disp(['    duration:            ' get(TC.traces(1),'DURATION_STR') ]);
        
        disp(['    sample rate:         ' num2str(get(TC.traces(1),'FREQ')) ' Hz']);

        disp(['    type:                ' char(get(TC,'TYPE')) ]);
        
        disp(['    trigger:             ' datestr(get(TC,'TRIGGER'),'yyyy/mm/dd HH:MM:SS.FFF') ]);
        
        if isempty(TC.backAzimuth)
            disp(['    backAzimuth:         ' 'property not set' ]);
        else
            disp(['    backAzimuth:         ' num2str(TC.backAzimuth) ]);
        end
        
        
        if isempty(TC.orientation)
            disp(['    orientation:         ' 'property not set' ]);
        else
            disp(['    orientation(' chan1(3) '):      ' num2str(TC.orientation(1)) '(h) '  num2str(TC.orientation(2)) '(v)' ]);
            disp(['    orientation(' chan2(3) '):      ' num2str(TC.orientation(3)) '(h) '  num2str(TC.orientation(4)) '(v)' ]);
            disp(['    orientation(' chan3(3) '):      ' num2str(TC.orientation(5)) '(h) '  num2str(TC.orientation(6)) '(v)' ]);


        end
        
        
        
        if isempty(TC.rectilinearity)
            disp(['    rectilinearity:      property not set' ]);
        else
            disp(['    rectilinearity:      ' num2str(get(TC.rectilinearity,'FREQ')) ' Hz, ' num2str(get(TC.rectilinearity,'THREECOMP_WINDOW')) ' sec window']);
        end
        
        if isempty(TC.planarity)
            disp(['    planarity:           property not set' ]);
        else
            disp(['    planarity:           ' num2str(get(TC.rectilinearity,'FREQ')) ' Hz, ' num2str(get(TC.rectilinearity,'THREECOMP_WINDOW')) ' sec window']);
        end
        
        if isempty(TC.energy)
            disp(['    energy:              property not set' ]);
        else
            disp(['    energy:              ' num2str(get(TC.rectilinearity,'FREQ')) ' Hz, ' num2str(get(TC.rectilinearity,'THREECOMP_WINDOW')) ' sec window']);
        end
        
        if isempty(TC.azimuth)
            disp(['    azimuth:             property not set' ]);
        else
            disp(['    azimuth:             ' num2str(get(TC.rectilinearity,'FREQ')) ' Hz, ' num2str(get(TC.rectilinearity,'THREECOMP_WINDOW')) ' sec window']);
        end
        
        if isempty(TC.inclination)
            disp(['    inclination:         property not set' ]);
        else
            disp(['    inclination:         ' num2str(get(TC.rectilinearity,'FREQ')) ' Hz, ' num2str(get(TC.rectilinearity,'THREECOMP_WINDOW')) ' sec window']);
        end
    end
end