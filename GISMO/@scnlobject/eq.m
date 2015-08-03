function results = eq(mywave, anythingelse)
   % when using wildcards, use ismember
results = mywave.tag == get(anythingelse,'channeltag');
