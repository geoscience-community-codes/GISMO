vidObj = VideoReader('f9-29_ne_twr.mov');
save vidfile.mat vidObj 
%%
% Specify that reading should start at 0.5 seconds from the
% beginning.
%vidObj.CurrentTime = 0.5;

% Create an axes
currAxes = axes;
figure
fnum = 1;
while hasFrame(vidObj)
    vidFrame = readFrame(vidObj);
    %image(vidFrame, 'Parent', currAxes);
    fnum
    imagesc(vidFrame)
    %stop
    %currAxes.Visible = 'off';
    pause(2.0/vidObj.FrameRate);
    fnum=fnum+1;
end
