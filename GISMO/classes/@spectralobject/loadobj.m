function a = loadobj(b)
% LOADOBJ - handles updates to spectralobject
% AUTHOR: Celso Reyes

if isa (s,'spectralobject')
    a = b;
    return
end

fn = fieldnames(b);
a = spectralobject;
for n=fn;
    try
        a = set(n{:},b.(n{:}));
    end
end