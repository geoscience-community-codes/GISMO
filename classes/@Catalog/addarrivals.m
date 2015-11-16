function [ catalogObj ] = addarrivals( catalogObj, format, filepath)
%ADDARRIVALS Add Arrival objects to a Catalog object
%   Retrieves arrival times for each event in a Catalog object.
    catalogObj.arrivals = Arrival.retrieve(format, filepath);
end

