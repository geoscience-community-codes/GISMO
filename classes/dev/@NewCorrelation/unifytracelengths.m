function c = unifytracelengths(c)
   %unifytracelengths   make all traces the same length (mode length)
   %   C = unifytracelengths(C) if traces are of unequal lengths, then they
   %   are either trimmed or zero-padded to the same size.  The final length
   %   will be the mode length of the original set of traces.
   %
   %   See also mode
   
   if isempty(c.traces)
      return
   end
   
   lengths = [c.traces.nsamples];
   ideal = mode(lengths);
   
   tooShort = lengths < ideal;
   tooLong = lengths > ideal;
   
   for i = 1:numel(lengths)
      if tooShort(i)
         c.traces(i).data(ideal) = 0;
      elseif tooLong(i)
         c.traces(i).data = c.traces(i).data(1:ideal);
      end
   end
end
