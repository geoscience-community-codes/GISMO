function y=nancumsum(y)
i=find(isnan(y));
y(i)=0;
y=cumsum(y);
