function s = getsamples(w, indexes)
  %   waveform = getsamples(waveform, indexes) simply returns the
  %       samples at w.data(indexes).  -> Only works with individual 
  %       waveforms!
   s = w.data(indexes);
end