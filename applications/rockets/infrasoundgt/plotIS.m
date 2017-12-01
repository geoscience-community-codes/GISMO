function plotIS(w)
r=waveform2rsam(w([2 6]),'max',0.1);
yi = r(1).data;
ys = r(2).data;
t = r(1).dnum;

figure
subplot(2,1,1), semilogy(t,yi);
ytickpos = get(gca,'YTick');
set(gca,'YTickLabels',ytickpos);
ylabel('Pressure change (Pa)');
datetick('x','keeplimits')

subplot(2,1,2), semilogy(t,ys);
ytickpos = get(gca,'YTick');
set(gca,'YTickLabels',ytickpos);
ylabel('Ground velocity (nm/sec)');
xlabel(sprintf('Date/Time starting at %s',datestr(t(1),'yyyy-mm-dd HH:MM:SS.FFF')));
datetick('x','keeplimits')