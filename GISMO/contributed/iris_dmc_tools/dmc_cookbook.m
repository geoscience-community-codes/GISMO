function dmc_cookbook



% TMP DATA
scnl = scnlobject({'CRP' 'CKN' 'CGL' 'SPU' 'CKL' 'CKT' 'BGL' 'NCG' 'JUNK'},'EHZ','AV','')';
for n = 1:numel(scnl)
   w(n) = set(waveform,'SCNLOBJECT',scnl(n));
end
    
    


[w2,success] = dmc_station_meta(w)



