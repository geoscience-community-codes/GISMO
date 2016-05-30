function [w]=messitup(w)
t = get(w,'timevector');
x = get(w,'data');

% 1.normalize
m = max(abs(x));
x=x/m;

% 2. add high f noise (at 0.6 of Nyquist)
fs=1/(t(2)-t(1));
x = x + sin(2*pi*0.3*fs*t)/10;

% 3. add trend
x=x+(t-t(1))/(t(end)-t(1))*10;

% 4. Add dropouts & spikes
c=3;
while c<length(x),
    r = rand;
%     if r>0.999
%         c
%         x(c) = NaN; % dropout
%         c=c+200;
%     end
    if r<0.001
        x(c) = x(c) + abs(3*randn); % spike
        c=c+100;
    end
    c=c+1;
end

% return messed up waveform
w = set(w,'data',x*m);
    
