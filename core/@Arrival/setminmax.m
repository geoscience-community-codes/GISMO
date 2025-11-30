function self = setminmax(self, w, maxTimeDiff, pretrig, posttrig)
%SETMINMAX Compute peak amplitude in moving window around arrivals

if nargin < 4, pretrig  = Inf; end
if nargin < 5, posttrig = Inf; end

SECONDS_PER_DAY = 86400;
N = numel(self.time);

amp = NaN(N,1);

for k = 1:N

    thisW = detrend(fillgaps(w(k),'interp'));
    y  = get(thisW,'data');
    fs = get(thisW,'freq');

    wstart = get(thisW,'start');
    wend   = get(thisW,'end');

    t0 = max([wstart self.time(k) - pretrig/SECONDS_PER_DAY]);
    t1 = min([wend   self.time(k) + posttrig/SECONDS_PER_DAY]);

    s0 = max(1, round((t0 - wstart)*fs*SECONDS_PER_DAY));
    s1 = min(length(y), round((t1 - wstart)*fs*SECONDS_PER_DAY));

    subWindowSize = round(fs * maxTimeDiff);
    maxA = 0;

    for s = s0 : s1-subWindowSize
        seg = y(s:s+subWindowSize-1);
        a = max(seg) - min(seg);

        if a > maxA
            maxA = a;
            amp(k) = max(abs([max(seg) min(seg)]));
        end
    end
end

self.amp = amp;
end
