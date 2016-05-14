function f = set(f, varargin)
%SET - Set filterobject properties
%   out_filterobject = set(f,prop_name, value, ...)
%   Valid property names:
%       TYPE: one of 'L' 'B' or 'H'. where L=LowPass, B=BandPass, and H=HighPass
%       CUTOFF: frequency cut-off. single val for L or H, 2 vals for B
%       POLES: number of poles
% 
%   You may change multiple properties at once; for example:
%      f = set(f,'type','b','cutoff',[1 5]);
% 
%   if multiple filterobjects are given, then the property will be set
%   for ALL of them.
%
%
%  See also FILTEROBJECT/SET

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

Vidx = 1 : numel(varargin);

while numel(Vidx) >= 2  % for each property
    prop_name = varargin{Vidx(1)};
    val = varargin{Vidx(2)};

    for n = 1 : numel(f); %for each filterobject

        switch upper(prop_name)
            case 'TYPE'
                if (~ischar(val) || ~isscalar(val))
                    error('filter TYPE must be ''B'', ''H'', or ''L'', not a %s',class(val));
                end
                if ismember(upper(val),'BHL')
                    f(n).type = upper(val);
                else
                    error('Unrecognized value for TYPE.  Should be B,H,or L.  :<%s>' , val);
                end
                
            case 'CUTOFF'
                if ~isnumeric(val)
                    error('Cutoff frequency should be numeric, not %s',class(val));
                end
                if strcmpi(get(f(n),'type'),'B'),
                    cutoffcount = 2;
                else
                    cutoffcount = 1;
                end
                
                if numel(val) > cutoffcount,
                    error('Too many cutoffs (%d) for %s-pass filter',...
                        numel(val),get(f(n),'type'));
                elseif numel(val) < cutoffcount
                    error('Too few cutoffs (%d) for %s-pass filter',...
                        numel(val),get(f(n),'type'));
                end
                
                f(n).cutoff = sort(val);
                
            case 'POLES'
                if val >=0,
                    f(n).poles = fix(val);
                else
                    warning('Poles cannot be negative!');
                end

            otherwise
                warning(['Unrecognized property name...' upper(prop_name)]);
        end; %of switch
    end; %each filterobject    
    Vidx(1:2) = []; %done with those parameters, move to the next ones...
end; %each property