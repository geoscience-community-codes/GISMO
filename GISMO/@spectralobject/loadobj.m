function a = loadobj(b)
% LOADOBJ - handles updates to spectralobject

% VERSION: 1.1 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 5/29/2007

if isa (s,'spectralobject')
    a = b;
    return
end

fn = fieldnames(b)
a = spectralobject;
for n=1:numel(fn);
    try
        a = set(fn{n},b.(fn{n}));
    end
end