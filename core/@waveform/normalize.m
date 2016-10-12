function wn = normalize(w)
w = demean(w);
m = max(abs(w));
wn = w./m;