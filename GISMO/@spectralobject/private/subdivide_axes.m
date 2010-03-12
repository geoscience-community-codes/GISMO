function sub_h = subdivide_axes(h,sizes)
% returns handles for sub-axes of axis(h).  These axes are createdb y
% subdividing h into sections according to SIZES, where sizes is a
% 2-component vector corresponding to [nCol, nRow];
% example:
%   subplot(3,3,5); % break figure into 3x3 grid, and select the center
%   % let w be an NxM object array
%   h = subdivide_axes(gca, size(w));
%   for n=1:numel(h)
%     plot(h,somethingToPlot);
%   end
%
% axis h is cleared, then subaxes are created.  This function returns an
% NxM array of handles to the subaxes.


rect = get(h,'position');
nCol = sizes(2);
nRow = sizes(1);
left = rect(1);
bottom = rect(2);
width = rect(3);
height = rect(4);
%top = bottom - height;

if sizes(1) == 1
    % unchanged # of rows
    newMaxHeight  = height;
else
    newMaxHeight = height / nRow .* .85;
    %top = top + ( (0:nRow-1) .* (top/nRow)) + heightToAddEachTime
    bottom = linspace(bottom,  (bottom+height)-newMaxHeight,nRow);
end
if sizes(2) == 1
    % unchanged # of columns
    newMaxWidth = width;
else
    newMaxWidth = width / nCol .* .93;
    %widthToAddEachTime = (0:nCol-1) .* deadwidth;
    left = linspace(left, (left+width) - newMaxWidth, nCol);
    %left = left + ( (0:nCol-1) .* width/nCol) + widthToAddEachTime;
end
delete(h);
sub_h = zeros(nRow,nCol);
for c = 1:nCol
    for r = 1:nRow
        sub_h(r,c) = axes('position',...
            [left(c) bottom(r) newMaxWidth newMaxHeight]);
    end
end
sub_h = flipud(sub_h);