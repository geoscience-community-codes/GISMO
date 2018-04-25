function [detObj, sta, lta, sta_to_lta] = sta_lta(wave,varargin)
%function [detectionObject, sta, lta, sta_to_lta] = sta_lta(wave, varargin)

%STA_LTA: Short-Time-Average/Long-Time-Average event detector.
%
%USAGE: events = sta_lta(wave,prop_name_1,prop_val_1,...)
%
%DIAGRAM:
%                       /\      /\/\        /\
%              /\  /\/\/  \/\  /    \/\    /  \/\
%                \/          \/        \/\/      \
%                                           |-STA-| -->
%         --> |-----------------LTA---------------| -->
%
%INPUTS: wave     - A waveform object containing events (maybe)
%        varargin - User-defined parameter name/value pairs (below)
%
%VALID PROP_NAME: 
%
%  'edp'      - Event Detection Parameters (Detailed in 'VALID PROP_VAL')
%  'lta_mode' - LTA window behavior following a 'trigger on' flag
%
%VALID PROP_VAL: 
%
%  'edp'(1x6 numeric) ... default: [1 8 2 1.6 0 3]
%     --> [l_sta l_lta th_on th_off min_sep min_dur]
%        --> l_sta    - STA window length (s)
%        --> l_lta    - LTA window length (s)
%        --> th_on    - STA/LTA trigger on threshold
%        --> th_off   - STA/LTA trigger off threshold
%        --> min_dur  - Minimum event duration to be recorded(s)
%
%	'lta_mode' (string) ... default: 'continuous'
%     --> 'frozen' - LTA window fixed in place after trigger is turned on 
%                    while STA window continues forward.
%     --> 'continuous' - LTA window continues w/ STA window after trigger 
%                        is turned on (Same behavior as before trigger)
            
%OUTPUTS: Detection object

% Author: Glenn Thompson 2016-04-19 based heavily on an earlier program by Dane
% Ketner (Alaska Volcano Observatory). The main differences are:
%   * algorithm rewritten to improve execution speed, clarity
%   * visualization of the sta_lta ratio added
%   * triggered events are returned as a GISMO Detection object, for
%     consistency across GISMO
%   
% $Date$
% $Revision$

    %% Check waveform variable
    if isa(wave,'waveform')
        if numel(wave)>1
            detObj = [];
            for wavnum=1:numel(wave)
                [detObj0,sta,lta,sta_to_lta] = Detection.sta_lta(wave(wavnum),varargin{:});
                if strcmp(class(detObj0),'Detection')
                    if isempty(detObj)
                        detObj = detObj0;
                    else
                        detObj = detObj.append(detObj0);
                    end
                end

            end
            return
        end
            
       Fs = get(wave,'freq');         % Sampling frequency
       l_v = get(wave,'data_length'); % Length of time series
       tv = get(wave, 'timevector');  % Time vector of waveform
       staname = get(wave, 'station');
       channame = get(wave, 'channel');
       if isempty(wave)
           disp('Input waveform empty, no events detected')
           events = [];
           return
       end
    else
       error('STA_LTA: First Argument must be a waveform object')
    end

    %% Set all default parameters
    l_sta = round(1*Fs);     % STA window length
    l_lta = round(8*Fs);     % LTA window length
    th_on = 2.0;        % Trigger on when sta_to_lta exceeds this theshold
    th_off = 1.6;     % Trigger off when sta_to_lta drops below threshold
    minimum_duration_days = 3.0/86400;   % Any triggers shorter than minimum_duration_days are discarded
    lta_mode = 'continuous'; % (Default) Post trigger-on LTA behavior

    %% Check varargin size
    nv = numel(varargin);
    if ~rem(nv,2) == 0
       error(['STA_LTA: Arguments after wave must appear in ',...
              'property_name/property_value pairs'])
    end

    %% User-defined parameters (varargin)
    if nv > 0
        for p = 1:2:nv-1
            v1 = varargin{p};
            v2 = varargin{p+1};
            switch lower(v1)
                case 'edp'
                    if isnumeric(v2) && numel(v2) == 5
                        l_sta = round(v2(1)*Fs);    % STA window length
                        l_lta = round(v2(2)*Fs);    % LTA window length
                        th_on = v2(3);       % Trigger on theshold
                        th_off = v2(4);      % Trigger off threshold
                        minimum_duration_days = v2(5)/86400;  % Minimum event duration
                    else
                        error('STA_LTA: Wrong format for input ''edp''')
                    end
                case 'lta_mode'
                    switch lower(v2)
                        case {'freeze','frozen'}
                            lta_mode = 'frozen';
                        case {'continue','continuous'}
                            lta_mode = 'continuous';
                        case {'grow','growing'}
                            lta_mode = 'grow';
                        otherwise
                          error('STA_LTA: Wrong format for input ''lta_mode''')
                    end
                otherwise
                    warning('property name not recognized')
                    v2
            end
        end
    end


    %% Initialize waveform data
    wave = fillgaps(wave,'interp'); % replace NaN values using splines
    wave = detrend(wave); % critical to work with detrended data
    y = abs(get(wave,'data')); % Absolute value of time series
    t = get(wave,'timevector');

    eventnum = 0;
    EVENT_ON = false;
    eventstart=0;
    eventend=0;
    trig_array = [];
    sta = ones(size(y));
    lta = sta;
    sta_to_lta = sta;
    
    % initialize for first l_lta samples
    sta(1:l_sta) = cumsum(y(1:l_sta))/l_sta;
    lta(1:l_lta) = cumsum(y(1:l_lta))/l_lta;
    for count = l_sta+1:l_lta
        sta(count) = sta(count-1) + (y(count) - y(count - l_sta)) / l_sta;
    end
    sta_to_lta(1:l_lta) = sta(1:l_lta)./lta(1:l_lta);
    
    for count=l_lta+1:length(y)
        % rather than use a moving average, just remove oldest sample and
        % add newest = faster
        if EVENT_ON && strcmp(lta_mode,'frozen')
            lta(count) = lta_freeze_level; % freeze LTA is event is triggering
        else
            lta(count) = lta(count-1) + (y(count) - y(count - l_lta))/l_lta ;
        end
        sta(count) = sta(count-1) + (y(count) - y(count - l_sta))/l_sta;
        sta_to_lta(count) = sta(count)/lta(count);
        
        if ~EVENT_ON & sta_to_lta(count) >= th_on 
            EVENT_ON = true;
            eventstart = t(count);
            lta_freeze_level = lta(count);
            snr_start = sta_to_lta(count);
        end
        
        if EVENT_ON & ((sta_to_lta(count) <= th_off) || count == length(y))
            EVENT_ON = false;
            eventend = t(count);
            if strcmp(lta_mode,'frozen') % unfreeze the lta
                lta(count) = nanmean(y(count-l_lta+1:count));
            end
            if (eventend-eventstart)>=minimum_duration_days
                eventnum = eventnum + 1;
                if eventnum < 11
                    disp(sprintf('Event %d: %s to %s',eventnum,datestr(eventstart),datestr(eventend)))
                end
                trig_array(eventnum, 1) = eventstart;
                trig_array(eventnum, 2) = eventend;
                snr_val(eventnum*2-1) = snr_start;
                snr_val(eventnum*2) = sta_to_lta(count);
%                 detectionArray(eventnum*2-1) = Detection(staname, channame, trig_array(eventnum,1) , 'ON', '', snr_start);
%                 detectionArray(eventnum*2) = Detection(staname, channame, trig_array(eventnum,2) , 'OFF', '', snr_end);
                eventstart = 0;
                eventend = 0;
            end  
        end  
    end
    
    figure
    t_secs=(t-t(1))*86400;
    ta_secs = (trig_array-t(1))*86400;
    
    ax(1)=subplot(4,1,1);
    plot(t_secs, get(wave,'data'), 'k')
    title('waveform')
    ax(2)=subplot(4,1,2);
    plot(t_secs, sta, 'k')
    title('STA')
    ax(3)=subplot(4,1,3);
    plot(t_secs, lta, 'k')
    title('LTA')
    ax(4)=subplot(4,1,4);
    plot(t_secs, sta_to_lta, 'k')
    title('STA:LTA')
    linkaxes(ax,'x')
    hold on
    a=axis();
    xlabel('Time (s)')
    plot([a(1) a(2)],[th_on th_on],'r');
    plot([a(1) a(2)],[th_off th_off],'g');
    for count=1:size(ta_secs,1)
        plot(ta_secs(count,:),[0 0],'b','LineWidth',5);
    end
    %% CHANGED CODE FROM RETURNING A CATALOG TO RETURNING A DETECTION VECTOR
%     if eventnum==0
%         cobj = Catalog();
%     else
%         cobj = Catalog([], [], [], [], [], {}, {}, 'ontime', trig_array(:,1), 'offtime', trig_array(:,2));
%     end

      if eventnum>0
          detObj = Detection(repmat(cellstr(staname),eventnum*2,1), ...
              repmat(cellstr(channame),eventnum*2,1), ...
              reshape(trig_array', 1, eventnum*2), ...
              repmat({'ON';'OFF'},eventnum,1), ...
              repmat(cellstr(''), eventnum*2,1), ...
              snr_val);
      else
          detObj = 0;
      end
          

end




            
                     

