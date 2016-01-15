function exit_stat = main(varargin)
    
    % use the inputParser class to deal with arguments
    ip = inputParser;
    %#ok<*NVREPL> dont warn about addParamValue
    addParamValue(ip,'subject', 0, @isnumeric);
    addParamValue(ip,'debug_level', @isnumeric);
    parse(ip,varargin{:}); 
    input = ip.Results;
    defaults = ip.UsingDefaults;
    
    constants.exp_onset = GetSecs; % record the time the experiment began
    KbName('UnifyKeyNames') % use a standard set of keyname/key positions
    rng('shuffle'); % set up and seed the randon number generator, so lists get properly permuted
    
    % Get full path to the directory the function lives in, and add it to the path
    [constants.root_dir , ~, ~]  = fileparts(mfilename('fullpath'));
    path(path,genpath(constants.root_dir));

    % Make the data directory if it doesn't exist (but it should!)
    if ~exist([constants.root_dir, '\data\'], 'dir')
        mkdir([constants.root_dir, '\data\']);
    end
    
    % Define the location of some directories we might want to use
    constants.stimDir=fullfile(constants.root_dir,'stimuli');
    constants.savePath=fullfile(constants.root_dir,'data');

    subjectValidator = makeSubjectDataChecker(constants.savePath, '.csv', input.debugLevel);
    
    %% -------- GUI input option ----------------------------------------------------
    % If any input was not given, ask for it!
    expose = {'subject', 'group'}; % list of arguments to be exposed to the gui
    if any(ismember(defaults, expose))
    % call gui for input
        guiInput = getSubjectInfo('subject', struct('title', 'Subject Number', 'type', 'textinput', 'validationFcn', subjectValidator), ...
            'group', struct('title' ,'Group', 'type', 'dropdown', 'values', {{'immediate','delay'}}));
        if isempty(guiInput)
            exit_stat = 1;
            return
        else
           input = uniqueStructs(input,guiInput);
           input.subject = str2double(input.subject); 
        end
    else
        [validSubNum, msg] = subjectValidator(input.subject, '.csv', input.debugLevel);
        assert(validSubNum, msg)
    end

    % now that we have all the input and its passed validation, we can have
    % a file path!
    constants.fName=fullfile(save_path, strjoin({'Subject', num2str(s.sub_num), 'Group',num2str(s.group)},'_'));
end

function overwriteCheck = makeSubjectDataChecker(directory, extension, debugLevel)
    % makeSubjectDataChecker function closer factory, used for the purpose
    % of enclosing the directory where data will be stored. This way, the
    % function handle it returns can be used as a validation function with getSubjectInfo to 
    % prevent accidentally overwritting any data. 
    function [valid, msg] = subjectDataChecker(value, ~)
        % the actual validation logic
        
        subnum = str2double(value);        
        if (~isnumeric(subnum) || isnan(subnum)) && ~isnumeric(value);
            valid = false;
            msg = 'Subject Number must be greater than 0';
            return
        end
        
        filePathGlobUpper = fullfile(directory, ['*Subject', value, '*', extension]);
        filePathGlobLower = fullfile(directory, ['*subject', value, '*', extension]);
        if ~isempty(dir(filePathGlobUpper)) || ~isempty(dir(filePathGlobLower)) && debugLevel <= 2
            valid= false;
            msg = strjoin({'Data file for Subject',  value, 'already exists!'}, ' ');                   
        else
            valid= true;
            msg = 'ok';
        end
    end

overwriteCheck = @subjectDataChecker;
end
