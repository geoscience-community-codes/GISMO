function [spectrogramPosition, tracePosition] = calculatePanelPositions(numchannels, channelNum, fractionalSpectrogramHeight, frameLeft, frameBottom, totalWidth, totalHeight)
% calculatePanelPositions   get spectrogram and trace positions
   debug.printfunctionstack('>');
channelHeight 		= totalHeight/numchannels;
spectrogramHeight 	= fractionalSpectrogramHeight * channelHeight;
traceHeight 		= channelHeight - spectrogramHeight; 
spectrogramBottom   = frameBottom + (numchannels - channelNum) * channelHeight;
traceBottom         = spectrogramBottom + spectrogramHeight;
spectrogramPosition = [frameLeft, spectrogramBottom, totalWidth, spectrogramHeight];
tracePosition 		= [frameLeft, traceBottom      , totalWidth, traceHeight];
debug.printfunctionstack('<');
end
