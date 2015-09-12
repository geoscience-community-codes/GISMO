function w = setsamples(w, index, values)
   %setsamples replaces selected data samples with values.
   %w = setsamples(w, INDEX, VALUES) will replace the data values 
   %described by INDEX with the value(s) in VALUES.
   %
   % this replaces the typical script:
   %   d = get(w,data);
   %   m = find(data == something);
   %   d(m) = newvalue;
   %   w = set(w,'data',d);
   % 
   % with:
   %   w = setsamples(w, double(w) == something, newvalue);
   
   w.data(index) = values;