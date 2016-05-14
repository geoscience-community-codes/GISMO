%This is synthetic219
%This program generates a synthetic catalog of given total number of events, b-value, minimum magnitude,
%and magnitude increment.
%The synthetic catalog will be sotred in a file "synt.mat"
% Yuzo Toya 2/1999

TN = length(mag(1));  %total number of events
B = bv2 ;%b-value
IM= i;%starting magnitude (hypothetical Mc)
inc = 0.1 ;%magnitude increment

% log10(N)=A-B*M
M=[IM:inc:15];
N=10.^(log10(TN)-B*(M-IM));
aval=(log10(TN)-B*(0-IM));
N=round(N);
%N=floor(N);
%N=ceil(N);

syn = ones(TN,9)*nan;
new = ones(TN,1)*nan;

%[ttt,indt]=sortrows(new,[3]);
%new=ttt;
%new=a
ct1=1;


ct1  = min(find(N == 0)) - 1;
if isempty(ct1) == 1 ; ct1 = length(N); end

ctM=M(ct1);
count=0;
ct=0;
swt=0;
sc=0;
for I=IM:inc:ctM;
    ct=ct+1;
    if I~=ctM;
        for sc=1:(N(ct)-N(ct+1));
            count=count+1;
            new(count)=I;
        end
    else
        count=count+1;
        new(count)=I;
    end
end;


PM=M(1:ct);
PN=log10(N(1:ct));
%bdiff(catZmap)
%ga = findobj('Tag','cufi');
%axes(ga); hold on;
%plot(PM,N(1:ct));
%pause
N = N(1:ct);
le = length(mag(l));
[bval,xt2] = hist(mag(l),PM);
b3 = fliplr(cumsum(fliplr(bval)));    % N for M >= (counted backwards)
res2 = sum(abs(b3 - N))/sum(b3)*100;
res = res2;

return

fi = findobj('tag','mcfig2');
if isempty(fi) == 1
    figure('pos',[300 300 300 300],...
        'tag','mcfig2');
else
    figure(fi); delete(gca);delete(gca);
end


axes('pos',[0.15 0.2 0.7 0.7])

pl = semilogy(PM,b3,'bo')
set(pl,'LineWidth',[1.5],'MarkerSize',[5],...
    'MarkerFaceColor',[0 0 0 ],'MarkerEdgeColor','k');

hold on
pl = semilogy(PM,N(1:ct),'rs')
set(pl,'LineWidth',[1.5],'MarkerSize',[5],...
    'MarkerFaceColor',[0.9 0.9 0.9],'MarkerEdgeColor','k');

%re = (abs(b3 - N));
%pl = semilogy(PM,re,'rv')
%set(pl,'LineWidth',[1.0],'MarkerSize',[5],...
%  'MarkerFaceColor','w','MarkerEdgeColor','k');

set(gca,'visible','on','FontSize',fs12,'FontWeight','bold',...
    'TickDir','out','LineWidth',[1.0],...
    'Box','on')
legend('Observed','Synthetic')
xlabel('Magnitude')
ylabel('Cumulative Number')
title('Goodness of FMD fit to GR')
set(gca,'Ylim',[1 1300])
