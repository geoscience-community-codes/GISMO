function out = ensure_dateformat(t)
% stolen from waveform
   % returns a matrix of datenums of same shape as t
   if isnumeric(t)
      out = t;
   elseif ischar(t),
      for n = size(t,1) : -1 : 1
         out(n) = datenum(t(n,:));
      end
   elseif iscell(t)
      out(:) = datenum(t);
   end
   % previously implemented as:
   % if ischar(startt), startt = {startt}; end
   % if ischar (endt), endt = {endt}; end;
   % startt = reshape(datenum(startt(:)),size(startt));
   % endt = reshape(datenum(endt(:)),size(endt));
end
