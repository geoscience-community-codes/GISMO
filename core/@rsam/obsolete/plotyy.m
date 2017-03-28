function plotyy(obj1, obj2, varargin)
   p = inputParser;
   p.addParameter('snum',max([obj1.dnum(1) obj2.dnum(1)]));
   p.addParameter('enum', min([obj1.dnum(end) obj2.dnum(end)]));
   p.addParameter('fun1','plot');
   p.addParameter('fun2','plot');
   p.parse(varargin{:});
   Args = p.Results;

    [ax, ~, ~] = plotyy(obj1.dnum, obj1.data, obj2.dnum, obj2.data, Args.fun1, Args.fun2);
    datetick('x');
    set(ax(2), 'XTick', [], 'XTickLabel', {});
    set(ax(1), 'XLim', [Args.snum Args.enum]);
end