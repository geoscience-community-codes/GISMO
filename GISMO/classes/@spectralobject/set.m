function s = set(s, varargin)
%SET - Set properties for spectralobject
%       s = Set(s,prop_name, val, ...)
%       Valid property names:
%       nfft, overlap, dBlims, freqmax
%
%       if multiple spectralobjects are given, then the property
%       will be set for ALL of them.
%
%       if setting multiple properties at once, make sure to set the 'NFFT'
%       before setting the 'OVERLAP' (aka 'OVER').  Otherwise, you'll get
%       an error or unexpected results as you set the nfft < overlap.

% VERSION: 1.1 of spectralobject
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 5/29/2007

Vidx = 1 : numel(varargin); %Vidx is the index for 'varargin'

while numel(Vidx) >= 2  % for each property
    prop_name = varargin{Vidx(1)};
    val = varargin{Vidx(2)};

    for n = 1 : numel(s); %for each spectralobject
        switch upper(prop_name)
            case 'NFFT'
                if ~isscalar(val),
                    error('NFFT needs to be a single number, not an array');
                end
                if ~isnumeric(val),
                    error('NFFT needs to be a number. Preferrably a power of 2');
                end
                s(n).nfft = val;
                if s(n).over >= s(n).nfft
                    s(n).over = val * 0.8; %reset to new default overlap
                end;
            case {'OVER', 'OVERLAP'}
                if ~isnumeric(val),
                    error('OVERLAP needs to be a number, not a %s',class(val));
                end
                if ~isscalar(val),
                    error('OVERLAP needs to be a single number, not an array');
                end
                if val >= s(n).nfft
                    error(['overlap (%.2f) must be less than NFFT (%d)'],val,s(n).nfft);
                end
                s(n).over = val;
            case 'DBLIMS'
                if (~isnumeric(val) || length(val) ~= 2)
                    error('dBlims must be a numeric pair [LOW HIGH]');
                end
                if val(1) > val(2)
                    warning('dblims entered as [HIGH LOW].  reversing.');
                end
                s(n).dBlims = sort(val);
            case 'FREQMAX'
                if ~isscalar(val),
                    error('FREQMAX needs to be a single number, not an array');
                end
                if ~isnumeric(val),
                    error('FREQMAX needs to be numeric, not %s',class(val));
                end
                s(n).freqmax = val;
            case 'SCALING'
                s(n).scaling = val;
            otherwise
                warning(['unrecognized property name...' upper(prop_name)]);
        end; %switch
        
    end; %each spectralobject
    Vidx(1:2) = []; %done with those parameters, move to the next ones...
end; %each property