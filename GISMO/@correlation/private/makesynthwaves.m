function c = makesynthwaves(n);

% Add N traces of synthetic data to a correlation object. Alters properties: waves, trig,
% start, Fs.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% MAKE SINGLE SIGNAL
t = [-5:.01:14.99]';
env_orig = exp(-1*(t-5).^2/ (2*3^2) );
sprep = 0.2*sin(t+1) + .3*sin((t-3)/0.3) + 0.4*cos(t/0.8) + 0.2*cos((t-1.7)/0.2);
%sprep = sin(t);
%sprep = 0.5*sin(t) + 0.5*sin(t/.5);
s = sprep .* env_orig;


% MAKE SUITE OF SIMILAR EVENT
%n = 150; %no. of events
w = s * ones(1,n) + .01*(rand(length(s),n)-.5); % add time offset
aa = .6;    % adjust to add randomness
for i = 1:n
    w(:,i) = w(:,i) + aa*rand(1)*sin((t-rand(1))/rand(1));
end;


% VARY START TIMES
for i = 1:n
    bump = round(300*(rand(1)));
    w(:,i) = w([ length(t)-bump:length(t) 1:(length(t)-1)-bump],i);
end;


% VARY AMPLITUDES
for i = 1:n
    w(:,i) = rand * 100 * w(:,i);
end;


% DEMEAN
w = w - ones(size(w,1),1)*mean(w);


% MAKE v0 CORRELATION
d.trig = 732604 + rand(n,1);
d.start = d.trig - (5 + 0.2*rand(n,1))/86400;
d.Fs = 100;
d.w = w;


% CREATE v1 CORRELATION OBJECT
c.W = waveform;
for i = 1:length(d.trig)
    w = waveform;
    w = set(w,'Station','UNKN');
    w = set(w,'Channel','EHZ');
    w = set(w,'Start',d.start(i));
    w = set(w,'Fs',d.Fs);
    w = set(w,'Data',d.w(:,i));
    c.W(i) = w;
end;
c.W = reshape(c.W,length(c.W),1);
c.trig = d.trig;


