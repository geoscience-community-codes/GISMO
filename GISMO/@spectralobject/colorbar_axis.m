
function handle = colorbar_axis(s,loc,clabel,rlab1,rlab2, fontsize)
% COLORBAR - Display color bar (color scale).
%
%   This function differs from colorbar(loc,clabel,rlab1,rlab2) in that 
%   only a portion of the colorbar defined by the plot axis "paxis" is shown
%
%       s.dBlims is the [2] vector containing the plotting axis limits
%       paxis   is the [2] vector containing the plotting axis limits
%               that are used to limit the portion of the colorbar shown 
%
%	COLORBAR('vert') appends a vertical color scale to 
%	the current axis. COLORBAR('horiz') appends a 
%	horizontal color scale.
%
%	COLORBAR(H) places the colorbar in the axes H. The
%	colorbar will be horizontal if the axes width > height.
%
%	COLORBAR without arguments either adds a new vertical
%	color scale or updates an existing colorbar.
%
%	H = COLORBAR(...) returns a handle to the colorbar axis.
%
%       clabel  is the string containing the colorbar axis label
%       rlab1   is the string label for the lower limit plotted
%       rlab2   is the string label for the upper limit plotted
%
%

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

%return

%set (gca, 'FontSize', 8)
if ~exist('fontsize','var')
    fontsize = 8;
end;
if nargin<1, 
  echo ' Error:  vector of plot-axis limits required'
  echo '         else,  use: '
  echo '    colorbar_axis(spectralobject,loc,clabel,rlab1,rlab2)'
  return
end

if nargin>1,
  lower=s.dBlims(1);
  upper=s.dBlims(2);
  paxis = s.dBlims;
end

if nargin<2, 
    loc = 'vert'; 
end

ax = [];
if nargin==2,
  if ~ischar(loc), 
    ax = loc; 
    if ~strcmp(get(ax,'type'),'axes'),
      error('Requires axes handle.');
    end
    rect = get(ax,'position');
    if rect(3) > rect(4), loc = 'horiz'; else loc = 'vert'; end
  end
end

% Determine color limits by context.  If any axes child is an image
% use scale based on size of colormap, otherwise use current CAXIS.

ch = get(gca,'children');
hasimage = 0; t = [];
for i=1:length(ch),
  if strcmp(get(ch(i),'type'),'image'),
    hasimage = 1;
    t = get(ch(i),'UserData'); % Info stored by imshow or imagesc
  elseif strcmp(get(ch(i),'Type'),'surface'), % Texturemapped surf?
    if strcmp(get(ch(i),'FaceColor'),'texturemap')
      hasimage = 2;
    t = get(ch(i),'UserData'); % Info stored by imshow or imagesc
    end
  end
end
if hasimage,
  if isempty(t), 
    t = [0.5 size(colormap,1)+0.5];
  end
else
  t = paxis;
  cmin=t(1);
  cmax=t(2);
end

h = gca;

if nargin==1,
  % Search for existing colorbar
  ch = get(gcf,'children'); ax = [];
  for i=1:length(ch),
    d = get(ch(i),'userdata');
    if numel(d)==1, 
        if d==h, 
            ax = ch(i); 
            pos = get(ch(i),'Position');
            if pos(3)<pos(4), loc = 'vert'; 
            else loc = 'horiz'; 
            end
            break;
        end
    end
  end
end

if strcmp(get(gcf,'NextPlot'),'replace'),
  set(gcf,'NextPlot','add')
end
set(gca,'FontSize',fontsize);
fsize=get(gca,'FontSize');          %get fontsize and shift if>16
%vshift=0;
%if fsize>16, vshift=.25; end

%------------------------------------------------------------------------

if loc(1)=='v',        % Append VERTICAL scale to right of current plot
  stripe = 0.075; edge = 0.02; 

  if isempty(ax),
    pos = get(h,'Position');
    [az,el] = view;
    if all([az,el]==[0 90]), space = 0.05; else space = .1; end
    set(h,'Position',[pos(1) pos(2) pos(3)*(1-stripe-edge-space) pos(4)])
    rect = [pos(1)+(1-stripe-edge)*pos(3) pos(2) stripe*pos(3)*.5 pos(4)];

    % Create axes for stripe
    ax = axes('Position', rect);
  else
    axes(ax);
  end
  
  % Create color stripe
  n = size(colormap,1);
  image([0 1],t,[1:n]'); set(ax,'Ydir','normal')

  if nargin>2,
    set(ax,'ylabel',text(0,0,clabel, 'FontSize', fontsize));
  end

  xpos = get(ax,'Xlim');
  ypos = get(ax,'Ylim');
  if nargin>3,
    xshift=.5*(xpos(2)-xpos(1));
    yshift=.05*(ypos(2)-ypos(1));
    if nargin==4,        %put color range  max label on colorbar
      text(xpos(2)-xshift,ypos(2)+yshift,0.,rlab1);
    end
    if nargin==5,        %put color range min, max labels on colorbar
      text(xpos(1)-xshift,ypos(1)-.75*yshift,0.,rlab1);
      text(xpos(1)-xshift,ypos(2)+yshift,0.,rlab2);
    end
  end
  %d=date;
  yshift=.12*(ypos(2)-ypos(1));
%  text(xpos(1)+2.0,ypos(1)-yshift,0.,d)

  % Create color axis
  ylim = get(ax,'ylim');   % Note: axis ticlabel range will be truncated
  units = get(ax,'Units'); set(ax,'Units','pixels');
  pos = get(ax,'Position');
  set(ax,'Units',units);
  yspace = get(ax,'FontSize')*(ylim(2)-ylim(1))/pos(4)/2;
  xspace = .5*get(ax,'FontSize')/pos(3);
  yticks = get(ax,'ytick');
  ylabels = get(ax,'yticklabel');
  labels = []; width = [];
  
set (gca, 'FontSize', fontsize)  %This sets the font size
  for i=1:length(yticks),
    labels = [labels;text(1+0*xspace,yticks(i),deblank(ylabels(i,:)), ...
         'HorizontalAlignment','right', ...
         'VerticalAlignment','middle', ...
         'FontName',get(ax,'FontName'), ...
         'FontSize',get(ax,'FontSize'), ...
         'FontAngle',get(ax,'FontAngle'), ...
         'FontWeight',get(ax,'FontWeight'))];
    width = [width;get(labels(i),'Extent')];
  end

  % Shift labels over so that they line up
  [dum,k] = max(width(:,3)); width = width(k,3);
  for i=1:length(labels),
    pos = get(labels(i),'Position');
    set(labels(i),'Position',[pos(1)+width pos(2:3)])
  end

  % If we need an exponent then draw one
  [ymax,k] = max(abs(yticks));
  if abs(abs(str2num(ylabels(k,:)))-ymax)>sqrt(eps),
    ex = log10(max(abs(yticks)));
    ex = sign(ex)*ceil(abs(ex));
    l = text(0,ylim(2)+2*yspace,'x 10', ...
         'FontName',get(ax,'FontName'), ...
         'FontSize',get(ax,'FontSize'), ...
         'FontAngle',get(ax,'FontAngle'), ...
         'FontWeight',get(ax,'FontWeight'));
    width = get(l,'Extent');
    text(width(3)-xspace,ylim(2)+3.2*yspace,num2str(ex), ...
         'FontName',get(ax,'ExpFontName'), ...
         'FontSize',get(ax,'ExpFontSize'), ...
         'FontAngle',get(ax,'ExpFontAngle'), ...
         'FontWeight',get(ax,'ExpFontWeight'));
  end

  set(ax,'yticklabelmode','manual','yticklabel','')
  set(ax,'xticklabelmode','manual','xticklabel','')

%set(gca,'ytick',[])
%------------------------------------------------------------------------
%------------------------------------------------------------------------
else            % Append HORIZONTAL scale to bottom of current plot

  if isempty(ax),
    pos = get(h,'Position');           %[left,bottom,width,height]
    stripe = 0.05; space = 0.1;       %stripe = 0.075
    ori=get(gcf,'paperorientation');
    if fsize<=16, 
        sfact=1; 
    else
        sfact=2;
    end
%    if ori=='landscape', stripe = 0.05; end
%    if fsize<=26,
%      set(h,'Position',...
%        [pos(1) pos(2)+(stripe+space)*pos(4) pos(3) (1-stripe-space)*pos(4)])
%    else
      set(h,'Position',...
     [pos(1) pos(2)+(sfact*stripe+space)*pos(4) pos(3) (1-stripe-space)*pos(4)])
%    end
    rect = [pos(1) pos(2) pos(3) stripe*pos(4)*.8];

    % Create axes for stripe
    ax = axes('Position', rect);
  else
    axes(ax);
  end

  t = paxis;
  cmin=t(1);
  cmax=t(2);

  % Create color stripe
  n = size(colormap,1);
  if paxis(1)>cmin,
    diff=paxis(1)-cmin;
    cstep=(cmax-cmin)/n;
    n1=round(diff/cstep);
  else 
    n1=1;
  end
  if paxis(2)<cmax,
    diff=cmax-paxis(2);
    cstep=(cmax-cmin)/n;
    n2=n-round(diff/cstep);
  else 
    n2=n;
  end
    
%  image(t,[0 1],[1:n]); set(ax,'Ydir','normal')
  image(t,[0 1],[n1:n2]); set(ax,'Ydir','normal')
  set(ax,'yticklabelmode','manual')
  set(ax,'yticklabel','')

set (gca, 'FontSize', fontsize)  %This sets the font size
  if nargin>2,
   set(ax,'xlabel',text(0,0,clabel, 'FontSize', fontsize));
  end

  xpos = get(ax,'Xlim');
  ypos = get(ax,'Ylim');
  if nargin>3,
    xshift=.025*(xpos(2)-xpos(1));
    if nargin==4,        %put color range  max label on colorbar
      text(xpos(2)-xshift,ypos(1)-1.0,0.,rlab1);
    end
    if nargin==5,        %put color range min, max labels on colorbar
      text(xpos(1)-xshift,ypos(1)-1.0,0.,rlab1);
      text(xpos(2)-xshift,ypos(1)-1.0,0.,rlab2);
    end
  end
  d=date;
  xshift=.15*(xpos(2)-xpos(1));
%  text(xpos(1)-xshift,ypos(1)-3.5,0.,d)

%set(gca,'xtick',[])
end
%------------------------------------------------------------------------
%------------------------------------------------------------------------

set(ax,'userdata',h)
set(gcf,'CurrentAxes',h)
set(gcf,'Nextplot','Replace')

if nargout>0, handle = ax; end


