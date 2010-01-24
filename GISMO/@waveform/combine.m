function combined_waveforms = combine (waveformlist)
%COMBINE merges waveforms based on start/end times and SCNL info.
% combined_waveforms = combine (waveformlist) takes a vector of waveforms
% and combines them based on SCNL information and start/endtimes.
% DOES NO OTHER CHECKS

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/26/2009

if numel(waveformlist) == 0  %nothing to do
  combined_waveforms = waveformlist;
  return
end

scnls = get(waveformlist,'scnlobject');
[uniquescnls, idx, scnlmembers] = unique(scnls);

%preallocate
combined_waveforms = repmat(waveform,size(uniquescnls));

for i=1:numel(uniquescnls)
  w = waveformlist(scnlmembers == i);
  w = timesort(w);
  for j=(numel(w)-1):-1:1
    w(j) = piece_together(w(j:j+1));
    w(j+1) = waveform;
  end
  combined_waveforms(i) = w(1);
end

function w = piece_together(w)
if numel(w) > 2
  for i = numel(w)-1: -1 : 1
    w(i) = piece_together(w(i:i+1));
  end
  w = w(1);
  return;
elseif numel(w) == 1
  return
end
if isempty(w(1)) 
  w = w(2);
  return;
end;
dt = dt_seconds(w(1),w(2));  %time overlap in seconds.
sampleRates = round(get(w,'freq'));
sampleInterval = 1 ./ sampleRates(1);
% if abs(dt - sampleInterval) < 1e-4,
%   w = spliceAndPad(w(1),w(2),0);
% end
if overlaps(dt, sampleInterval)
  w = spliceWaveform(w(1), w(2));
else
  paddingAmount = round((dt * sampleRates(1))-1);
  w = spliceAndPad(w(1),w(2), paddingAmount);
end
w = w(1);


%piece_together
function w = spliceAndPad(w1, w2, paddingAmount)
if paddingAmount > 0 && ~isinf(paddingAmount)
  toAdd = nan(paddingAmount,1);
else
  toAdd = [];
end
w = set(w1,'data',[get(w1,'data');toAdd;get(w2,'data')]);
%mydates = get(w1,'end_str');
%myotherdates = get(w2,'start_str');

function w = spliceWaveform(w1, w2)
timesToGrab = sum(get(w1,'timevector') < get(w2,'start'));
samplesRemoved = get(w1,'data_length') - timesToGrab;
w = set(w1,'data',[double(extract(w1,'index',1,timesToGrab)); get(w2,'data')]);
w= addhistory(w,'SPLICEPOINT: %s, removed %d points (overlap)',...
  datestr(get(w2,'start')),samplesRemoved);

function result = overlaps(dt, sampleInterval)
result = (dt- sampleInterval .* 1.25) < 0;

%function result = hasgap(dt,sampleInterval)
%result = dt < sampleInterval;

function t = dt_seconds(w1,w2)
%  w1----] t [----w2
firstsampleT = get(w2,'start');
lastsampleT = get(w1,'timevector'); lastsampleT = lastsampleT(end);
t = firstsampleT*86400 - lastsampleT * 86400;


function w = timesort(w)
[Y, I] = sort(get(w,'start'));
w = w(I);

