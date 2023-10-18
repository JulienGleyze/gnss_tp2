function xml_write(command, str1, str2)

% function used to write xml text into a file
% use a string buffer for efficency
%
% Syntax : 
% xml_write('init', filename)
%       initialize the file and the buffer (first use of the function)
%       
% xml_write('tag', str1)
%       add the tag "<str1>" to the buffer
%
% xml_write('/tag', str1)
%       add the end-tag "</str1>" to the buffer
%
% xml_write('elem', str1, str2)
%      add the element "<str1>str2</str1>" to the buffer
%
% xml_write('string', str1)
%       add the string "str1" to the buffer with no tag
%
% xml_write('write')
%       write the content of the buffer, and empty the buffer
%
% xml_write('reset')
%       reset the buffer
%


% buffer initialization
persistent BUFFER ENDSTR
if isempty(BUFFER)
    BUFFER = blanks(1e5); % default buffer size
    ENDSTR = 0;
end

max_size = 1e7; % maximum buffer size, to avoid out of memory
nl = '\r\n';


switch command
    case 'elem'
        if isempty(str2)
            % empty-element tag
            str = ['<' str1 ' />' nl];
        else
            % element
            str = ['<' str1 '>' str2 '</' str1 '>' nl];
        end
        
    case 'tag'
        % simple tag
        str = ['<' str1 '>' nl];
        
    case '/tag'
        % end tag
        str = ['</' str1 '>' nl];
        
    case 'string'
        % string only
        str = [str1 nl];
        
    case 'write'
        % write buffer to file
        write_file(BUFFER(1:ENDSTR));
        ENDSTR = 0;
        return
        
    case 'init'
        % initialize the file
        write_file('', str1);
        % reset buffer
        BUFFER = ''; % will be set to the default size
        ENDSTR = 0;
        return
        
    case 'reset'
        % reset buffer
        BUFFER = ''; % will be set to the default size
        ENDSTR = 0;
        return
        
    otherwise
        error('Unknown command.')
end


newENDSTR = ENDSTR + length(str);
if (newENDSTR <= length(BUFFER))
    % add the string to the buffer
    BUFFER(ENDSTR+1 : newENDSTR) = str;
    ENDSTR = newENDSTR;
    
else % buffer overflow
    if (1.2*newENDSTR < max_size)
        % increase buffer size
        BUFFER(ceil(1.2*newENDSTR)) = ' ';
        BUFFER(ENDSTR+1 : newENDSTR) = str;
        ENDSTR = newENDSTR;
        
    else
        % write to file to avoid out of memory
        write_file([BUFFER(1:ENDSTR) str]);
        ENDSTR = 0;
    end
end


end % xml_buffer


%--------------------------------------------------------------------------


function write_file(str, file)

% write string into a file
%
% str  : string to write
% file : file name (string) (only at the file initialization)
%        reset the text file

persistent FILE_NAME

if (nargin > 1)
    FILE_NAME = file;
    %[fid, message] = fopen(FILE_NAME, 'wt', 'n', 'UTF-8');
    [fid, message] = fopen(FILE_NAME, 'w');
    if isequal(fid, -1), error(message); end
    fclose(fid);
end

if isempty(FILE_NAME)
    error('file not initialized.')
end

% for Octave...
str = [' ' str];
str = str(2:end);

% write to the file
[fid, message] = fopen(FILE_NAME, 'a');
if isequal(fid, -1), error(message); end
fprintf(fid, str);
fclose(fid);

end % write_file

