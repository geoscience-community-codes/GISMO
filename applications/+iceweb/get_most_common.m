function s = getmostcommon(ctags)
    if numel(ctags)==1
        s = get(ctags,'network');
        return
    end
    x = get(ctags,'network');
    y = unique(x);
    n = zeros(length(y), 1);
    for iy = 1:length(y)
      n(iy) = length(find(strcmp(y{iy}, x)));
    end
    [~, itemp] = max(n);
    s= y{itemp};
end