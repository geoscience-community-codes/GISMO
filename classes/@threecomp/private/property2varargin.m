function c = property2varargin(properties)
%PROPERTY2VARARGIN makes a cell array from properties
%  c = property2varargin(properties)
%
% properties is a structure with fields "name" and "val"
%
%see also waveform/private/getproperty, waveform/private/parseargs

c = {};
c(1:2:numel(properties.name)*2) = properties.name;
c(2:2:numel(properties.name)*2) = properties.val;