function spdatatestplot(T,F,Y);
disp('sizeY sizeF')
size(Y)
size(F)
close all
figure
imagesc(Y)
ylabel('Frequency')
xlabel('time')
title(datestr(T(1),30))

[s,l]=bounds(Y,'all', 'omitnan')

figure  
for tindex=1:length(T)
    plot(Y(:,tindex))
    hold on
end
hold off
anykey=input('press any key to continue') 
close all
end