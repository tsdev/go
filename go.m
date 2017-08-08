function varargout = go(label, path)
% save, go to, go back and retrieve folders identified by arbitrary label
%
% GO(label,path)
%
% Adds path and the corresponding label to the list of saved path. If the
% label already exists, it will be overwritten. The command automatically
% exchange the user home folder path to '~' for unix based systems.
%
% GO
%
% Prints all label - path pairs to the Command Window.
%
% GO(label)
%
% Changes the directory to the path based on the following rules in order
% of precedence:
%   -   if the label is a valid path the command is equivalent to the
%       MATLAB built-in cd command
%   -   if the label is a matlab function, the new path is the folder of
%       the function
%   -   if the label exists in the go.db file, go to the corresponding
%       folder
% If none of the above rules are fulfilled, gives a warning.
%
% path = GO(label)
%
% Returns the path that corresponds to the given label.
%
% GO clear
%
% Clears the database.
%
% Go back
%
% Goes back to the previous path from where GO() was called last time. Can
% be only used to go back one level.
%
% GO label here
%
% To abel to use the command without string notation and brackets, the here
% string is automaticelly replaced by the output of the pwd() function
% (current path).
%
% The labels are case sensitive. The list of label path pairs are saved
% into the text file $USERPATH/go.db.
%

% Sandor Toth
% tothsa@gmail.com
% 08 Aug 2017

% get the home folder of the user if not on Windows
if ~ispc
    homePath = getenv('HOME');
end

% location of the database
dbpath = [userpath filesep 'go.db'];

if nargin == 0
    % list all label path pairs
    db = strsplit(fileread(dbpath),'\n');
    db = cellfun(@(C)strsplit(C,' '),db,'uniformoutput',false);
    L  = max(cellfun(@(C)numel(C{1}),[db {{'LABEL' ''}}],'uniformoutput',true));
    
    if nargout > 0
        varargout{1} = cellfun(@(C)C{1},db,'UniformOutput',false);
        return
    end
    
    if ~isempty(db)
        if ~ispc
            dbpath = strrep(dbpath,homePath,'~');
        end
        fprintf('The content of the %s database:\n',dbpath);
        lFormat = ['%-' num2str(L) 's  %s\n'];
        fprintf(lFormat,'LABEL','PATH');
        for ii = 1:numel(db)
            fprintf(lFormat,db{ii}{1},db{ii}{2});
        end
    else
        fprintf('The go.db database is empty. Use ''go label path'' to create new labels first!\n')
    end
    
    return
elseif nargin == 1
    try %#ok<TRYNC>
        % works as MATLAB built-in cd() command if label is a valid folder
        % name, using try because there is no command to test if a path is
        % valid
        
        % when renaming go to cd, avoid warnings
        if strcmp(mfilename,'cd')
            warn0 = warning;
            warning('off','MATLAB:dispatcher:nameConflict');
        end
        
        varargout      = cell(1,nargout);
        [varargout{:}] = builtin('cd',label);
        
        if strcmp(mfilename,'cd')
            warning(warn0);
        end
        return
    end
end


if nargin == 1 && strcmp(label,'clear')
    clear = true;
else
    clear = false;
end

if nargin < 2
    % if true the database is resaved
    savedb = false;
else
    if strcmp(path,'here')
        path = pwd;
    end
    % if true the database is resaved
    savedb = true;
end

% load db and check intengrity
if exist(dbpath,'file') && ~clear
    
    % read file into cell
    db = strsplit(fileread(dbpath),'\n');
    
    if isempty(db{end})
        % remove last empty line
        db(end) = [];
    end
    
    % check file format
    if isempty(db)
        % empty file
        l0 = {};
        p0 = {};
    elseif ~all(cellfun(@(C)sum(C==' '),db)==1)
        warning('go:WrongDB','The stored database has the wrong format, all labels are cleared!')
        % empty data
        l0 = {};
        p0 = {};
        savedb = true;
    else
        % extract labels and path
        db = cellfun(@(C)strsplit(C,' '),db,'uniformoutput',false);
        % labels
        l0 = cellfun(@(C)C{1},db,'uniformoutput',false);
        % path
        p0 = cellfun(@(C)C{2},db,'uniformoutput',false);
    end
    if nargin == 2
        % add the new labels as well
        l0 = [l0 {label}];
        p0 = [p0 {path}];
    elseif nargout == 0 && ~strcmp(label,'back')
        % add the 'back' label to the current path to able to go back
        l0 = [l0 {'back'}];
        p0 = [p0 {pwd   }];
        savedb = true;
    end
    
    % remove non-unique labels, keep the latest ones
    [l0,uidx] = unique(l0(end:-1:1));
    
    if numel(l0)<numel(p0)
        % resave the new file
        savedb = true;
    end
    
    uidx = numel(p0)+1-uidx;
    p0 = p0(uidx);
    
else
    % create new empty file
    l0 = {};
    p0 = {};
    savedb = true;
end

path = '';

if nargin == 1 && ~clear
    % find the label
    idx = find(ismember(l0,label));
    if ~isempty(idx)
        path = p0{idx};
    end
end

if savedb
    % save the database
    % create empty file
    fid = fopen(dbpath,'w');
    
    % change all path below the user path to '~' to enable multi account
    % use of the command
    if ~ispc
        p0 = strrep(p0,homePath,'~');
    end
    
    db = [l0; p0];
    if ~isempty(db)
        db1 = db(:,1:end-1);
        db2 = db(:,end);
        fprintf(fid,'%s %s\n',db1{:});
        fprintf(fid,'%s %s',db2{:});
    end
    % write file content
    fclose(fid);
end

if isempty(path) && nargin == 1 && ~clear
    % check for function handle
    if isa(label,'function_handle')
        fun = func2str(label);
    else
        fun = label;
    end
    
    fun = which(fun);
    
    if ~isempty(fun) && isempty(strfind(fun,'built-in')) %#ok<STREMP>
        path = fileparts(fun);
        
        if nargout > 0
            varargout{1} = path;
        elseif ~isempty(path)
            cd(path)
        end
    else
        warning('go:MissingLabel','The given label does not exists, assign a path to it first!')
    end
    
else
    % create output or go to path
    if nargin == 1 && ~clear
        if nargout > 0
            varargout{1} = path;
        else
            cd(path)
            fprintf(['pwd: ' path '\n']);
        end
    end
end

end