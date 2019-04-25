function [clipped_waveforms] = clip_waveforms(WAVEFORM_OBJECT)
    % Extract a portion of the waveform for the correlation. This is used in
    % conjuction with correlate_waveform() to analyze the same sample as
    % PEAKMATCH. Can add inputs to clip the waveform around the peak differently, see loop
    
    % this is specific to the telica data because some discrete waveforms
    % have multiple events within them but we only want the first one in
    % the waveform packet. 
    w_extracted = extract(WAVEFORM_OBJECT, 'INDEX', 250, 2000); % 5 to 40 sec 
    
    data = get(w_extracted, 'data');
    
    count2 = 1;
    for count = 1:numel(data)
        [~, I] = max(data{count});
        f = get(w_extracted(count), 'freq');
        start = int32(I - (f*4)); % T_BEFORE_PEAK = 4 s
        finish = int32(I + (f*8)); % T_AFTER_PEAK = 8 s
        if start > 0
            clipped_waveforms(count2) = extract(w_extracted(count), 'INDEX', start, finish);
        else
            clipped_waveforms(count2) = extract(w_extracted(count), 'INDEX', 1, finish);
        end
        count2 = count2 + 1;
    end

end