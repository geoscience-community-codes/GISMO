function m = get_highest_figure_number()
figs = get(0,'Children');
if numel(figs)>0
    m = max([figs.Number]);
else
    m = 0;
end