function [s,success] = dmc_xml2struct(file)

%Convert xml file into a MATLAB structure
%  [S,SUCCESS]= DMC_XML2STRUCT(SOURCE) Reads xml-formatted SOURCE and returns a
%  structure S. S contains the attributes in SOURCE, nested to reflect the
%  xml children as appropriate. If SOURCE cannot be parsed for any reason
%  the s is returned as an empty matrix [] and SUCCESS is set to 0.
%  Otherwise SUCCESS is 1.
%
%  EXAMPLE
%  A file containing:
%    <XMLname attrib1="Some value">
%      <Element>Some text</Element>
%      <DifferentElement attrib2="2">Some more text</Element>
%      <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
%    </XMLname>
%
%  Will produce:
%    s.XMLname.Attributes.attrib1 = "Some value";
%    s.XMLname.Element.Text = "Some text";
%    s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
%    s.XMLname.DifferentElement{1}.Text = "Some more text";
%    s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
%    s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
%    s.XMLname.DifferentElement{2}.Text = "Even more text";
%
%  Note the characters : - and . are not supported in structure fieldnames and
%  are replaced by _

%  Modified from function xml2struct (Matlab exchange File ID: #28518)
%  Copyright by W. Falkena. distributed under BSD license.
%  Last accessed Feb. 3, 2011
%  Modifications here allow xml loading from URLs and return null 
%  result when file or URL is invalid. 
%
%  MODIFIED BY: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
%  $Date: 2011-01-31 09:16:48 -0900 (Mon, 31 Jan 2011) $
%  $Revision: 259 $



%check for URL for file name
if (nargin~=1)
    error('xml2struct:IncorrectNumberOfArguments','Incorrect number of arguments');
end
% VALID = 0;
% if strfind(file,'http://')
%     VALID = 1;
% elseif exist(file,'file')
%     VALID = 1;
% elseif exist([file '.xml'],'file')
%     VALID = 1;
% else
%     warning('xml2struct:argumentIsNotFileOrURL',['URL or filename not recognized: ' file]);
% end

try 
    xDoc = xmlread(file);
    s = parseChildNodes(xDoc);
    success = 1;
catch
    %warning('xml2struct:InvalidFileOrURL',['No xml code could be parsed from URL (or filename): ' file]);
    s = [];
    success = 0;
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Subfunction parseChildNodes 
function [children,ptext] = parseChildNodes(theNode)
% Recurse over node children.
children = struct;
ptext = [];
if theNode.hasChildNodes
    childNodes = theNode.getChildNodes;
    numChildNodes = childNodes.getLength;
    
    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        [text,name,attr,childs] = getNodeData(theChild);
        
        if (~strcmp(name,'#text') && ~strcmp(name,'#comment'))
            %XML allows the same elements to be defined multiple times,
            %put each in a different cell
            if (isfield(children,name))
                if (~iscell(children.(name)))
                    %put existsing element into cell format
                    children.(name) = {children.(name)};
                end
                index = length(children.(name))+1;
                %add new element
                children.(name){index} = childs;
                if(~isempty(text))
                    children.(name){index}.('Text') = text;
                end
                if(~isempty(attr))
                    children.(name){index}.('Attributes') = attr;
                end
            else
                %add previously unkown new element to the structure
                children.(name) = childs;
                if(~isempty(text))
                    children.(name).('Text') = text;
                end
                if(~isempty(attr))
                    children.(name).('Attributes') = attr;
                end
            end
        elseif (strcmp(name,'#text'))
            %this is the text in an element (i.e. the parentNode)
            if (~isempty(regexprep(text,'[\s]*','')))
                if (isempty(ptext))
                    ptext = text;
                else
                    %what to do when element data is as follows:
                    %<element>Text <!--Comment--> More text</element>
                    
                    %put the text in different cells:
                    % if (~iscell(ptext)) ptext = {ptext}; end
                    % ptext{length(ptext)+1} = text;
                    
                    %just append the text
                    ptext = [ptext text];
                end
            end
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET NODE DATA    
function [text,name,attr,childs] = getNodeData(theNode)
% Create structure of node info.

%make sure name is allowed as structure name
name = regexprep(char(theNode.getNodeName),'[-:.]','_');

attr = parseAttributes(theNode);
if (isempty(fieldnames(attr)))
    attr = [];
end

%parse child nodes
[childs,text] = parseChildNodes(theNode);

if (isempty(fieldnames(childs)))
    %get the data of any childless nodes
    try
        %faster then if any(strcmp(methods(theNode), 'getData'))
        text = char(theNode.getData);
    catch
        %no data
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARSE THE ATTRIBURES
function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = struct;
if theNode.hasAttributes
    theAttributes = theNode.getAttributes;
    numAttributes = theAttributes.getLength;
    
    for count = 1:numAttributes
        attrib = theAttributes.item(count-1);
        attr_name = regexprep(char(attrib.getName),'[-:.]','_');
        attributes.(attr_name) = char(attrib.getValue);
    end
end