function [fo, ip] = func_despike_phasespace( fi, i_plot );
%======================================================================
%
% Version 2.00
%
% This subroutine excludes spike noise from Acoustic Doppler 
% Velocimetry (ADV) data using phasce-space method by Goring and 
% Nikora (2002).
% 
%======================================================================
%
% Input
%   fi     : input data with dimension (n,1)
%   i_plot : =9 plot results (optional)
%
% Output
%   fo     : output (filterd) data
%   ip     : excluded array element number in xi and yi
%
% Example: 
%   [fo, ip] = func_despike_phasespace_sub( fi, i_plot );
%
%
%======================================================================
% Terms:
%
%       Distributed under the terms of the terms of the 
%       GNU General Public License
%
% Copyright: Nobuhito Mori, Osaka City University
%
%========================================================================
%
% Update:
%       2.00    2004/12/29 Major bug has been fixed
%       1.10    2004/09/06 Iteration is added
%       1.00    2004/09/01 Nobuhito Mori, Osaka City University
%
%========================================================================

%
% --- initial setup
%

% number of maximum iternation
n_iter = 10;                    
n_out  = 999;

n      = size(fi,1);
f_mean = nanmean(fi);
f      = fi - f_mean;
lambda = sqrt(2*log(n));

if nargin==1
  i_plot = 0;
end

%
% --- loop
%

n_loop = 1;

while (n_out~=0) & (n_loop <= n_iter)

%
% --- main
%

f = f - nanmean(f);
s = nanstd(f);

% step 1: first and second derivatives
f_t  = gradient(f);
f_tt = gradient(f_t);

% step 2: calculation of std of f, ft, ftt
s_t  = nanstd(f_t);
s_tt = nanstd(f_tt);

% step 3: angle
theta = atan2( sum(f.*f_tt), sum(f.^2) );

% step 4: estimation of a and b
f1  =   f*cos(theta) + f_tt*sin(theta);
f2  = - f*sin(theta) + f_tt*cos(theta);
s_1 = std(f1);
s_2 = std(f2);
a_3 = lambda*s_1;
b_3 = lambda*s_2;

% step 5: checking outlier in the phase space
if isnan(a_3)==0 & isnan(b_3)==0 & isinf(a_3)==0 & isinf(b_3)==0
  a_1 = lambda*s;
  b_1 = lambda*s_t;
  a_2 = lambda*s_t;
  b_2 = lambda*s_tt;
  % f-f_ft
  [x1_p, y1_p, ip1] = func_excludeoutlier_ellipsoid(   f,  f_t, a_1, b_1, 0 );
  % f-f_ft
  [x2_p, y2_p, ip2] = func_excludeoutlier_ellipsoid( f_t, f_tt, a_2, b_2, 0 );
  % f_t-f_ft
  [x3_p, y3_p, ip3] = func_excludeoutlier_ellipsoid(   f, f_tt, a_3, b_3, theta );
else

    ip1 = [];
    ip2 = [];
    ip3 = [];

end

%
% --- excluding data
%

n_nan_1 = size(find(isnan(f)==1),1);
f(ip1)  = NaN;
f(ip2)  = NaN;
f(ip3)  = NaN;
n_nan_2 = size(find(isnan(f)==1),1);
n_out   = n_nan_2 - n_nan_1;

%
% --- for check
%

if i_plot == 9 & (isnan(a_3)==0 & isnan(b_3)==0)

t = 0:pi/64:2*pi;
ip = find(isnan(f));
x1_e = a_1*cos(t);
x2_e = a_2*cos(t);
x3_t = a_3*cos(t);
y1_e = b_1*sin(t);
y2_e = b_2*sin(t);
y3_t = b_3*sin(t);
x3_e = x3_t*cos(theta) - y3_t*sin(theta);
y3_e = x3_t*sin(theta) + y3_t*cos(theta);

clf;
subplot(2,2,1);
plot(x1_e,y1_e,'b-');
hold on
plot(f,f_t,'k.');
plot(x1_p,y1_p,'r.');
hold off
xlabel('u');
ylabel('\Delta u');

subplot(2,2,3);
plot(x3_e,y3_e,'b-');
hold on
plot(f,f_tt,'k.');
plot(x3_p,y3_p,'r.');
hold off
ylabel('\Delta u');
ylabel('\Delta^2 u');

subplot(2,2,2);
plot(x2_e,y2_e,'b-');
hold on
plot(f_t,f_tt,'k.');
plot(x2_p,y2_p,'r.');
hold off
xlabel('\Delta u');
ylabel('\Delta^2 u');

subplot(2,2,4);
plot(fi,'k-');
hold on
plot(ip,fi(ip),'ro','MarkerSize',5);
hold off
xlabel('time');
ylabel('u[s]');
axis tight
%pause

end

%
% --- end of loop
%

n_loop = n_loop + 1;

end

%
% --- post process
%

fo = f + f_mean;
ip = find(isnan(fo));

if n_loop < n_iter
  debug.print_debug(...
    ['>> Number of outlier   = ', num2str(size(find(isnan(f)==1),1)), ...
     ' : Number of iteration = ', num2str(n_loop-1)] ...
  ,4)
else
  debug.print_debug(...
    ['>> Number of outlier   = ', num2str(size(find(isnan(f)==1),1)), ...
     ' : Number of iteration = ', num2str(n_loop-1), ' !!! exceed maximum value !!!'] ...
  ,4)
end



function [xp, yp, ip] = func_excludeoutlier_ellipsoid( xi, yi, a, b, theta );
%======================================================================
%
% Version 2.11
%
% This program excludes the points outside of ellipsoid in two-
% dimensional domain
%
% Input
%   xi : input x data
%   yi : input y data
%   a  : the major axis
%   b  : the minor axis
%
% Output
%   xp : excluded x data
%   yp : excluded y data
%   ip : excluded array element number in xi and yi
%
% Example: 
%   [xp, yp, ip] = func_excludeoutlier_ellipsoid( f, f_t, a, b );
%
%
%======================================================================
% Terms:
%
%       Distributed under the terms of the terms of the 
%       GNU General Public License
%
% Copyright: Nobuhito Mori, Osaka City University
%
%========================================================================
%
% Update:
%       2.11    2005/01/14 Minor bug has been fixed
%       2.10    2005/01/12 Minor bug has been fixed
%       2.00    2004/12/29 Major bug has been fixed
%       1.01    2004/09/06 Bug fixed
%       1.00    2004/09/01 Nobuhito Mori, Osaka City University
%
%========================================================================

%
% --- initial setup
%

n = max(size(xi));

xp = [];
yp = [];
ip = [];

%
% --- rotate data
%

if theta == 0
  X = xi;
  Y = yi;
else
  X =   xi*cos(theta) + yi*sin(theta);
  Y = - xi*sin(theta) + yi*cos(theta);
end

%
% --- main
%

m = 0;
for i=1:n
  x1 = X(i);
  y1 = Y(i);
  % point on the ellipsoid
  if x1 ~= 0
    x2 = 1 / sqrt( 1/a^2 + 1/b^2*(y1^2/x1^2) );
  else
    x2 = a;
  end
  y2 = sqrt( (1 - x2^2/a^2)*b^2 );
  if x1 < 0
    x2 = -x2;
  end
  if y1 < 0
    y2 = -y2;
  end
  dis = (x2^2+y2^2) - (x1^2+y1^2);
  if dis < 0 
    m = m + 1;
    ip(m) = i;
%    xt(m) = x1;
%    yt(m) = y1;
    xp(m) = xi(i);
    yp(m) = yi(i);
  end
end

%
% --- rotate data / reverse
%

%if theta == 0
%  xp = xt;
%  yp = yt;
%else
%  xp = xt*cos(theta) - yt*sin(theta);
%  yp = xt*sin(theta) + yt*cos(theta);
%end
