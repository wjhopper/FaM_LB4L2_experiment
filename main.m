function exit_stat = main(varargin)

exit_stat = 1; % assume that we exited badly if ever exit before this gets reassigned
% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip,'subject', 0, @isnumeric);
addParamValue(ip,'group', 'immediate', @ischar);
addParamValue(ip,'debugLevel',0, @isnumeric);
parse(ip,varargin{:}); 
input = ip.Results;
defaults = ip.UsingDefaults;

constants.exp_onset = GetSecs; % record the time the experiment began
KbName('UnifyKeyNames') % use a standard set of keyname/key positions
rng('shuffle'); % set up and seed the randon number generator, so lists get properly permuted

% Get full path to the directory the function lives in, and add it to the path
constants.root_dir = fileparts(mfilename('fullpath'));
constants.lib_dir = fullfile(constants.root_dir, 'lib');
path(path,constants.root_dir);
path(path, genpath(constants.lib_dir));

% Make the data directory if it doesn't exist (but it should!)
if ~exist(fullfile(constants.root_dir, 'data'), 'dir')
    mkdir(fullfile(constants.root_dir, 'data'));
end

% Define the location of some directories we might want to use
constants.stimDir=fullfile(constants.root_dir,'stimuli');
constants.savePath=fullfile(constants.root_dir,'data');

% instantiate the subject number validator function
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
       input = filterStructs(guiInput, input);
       input.subject = str2double(input.subject); 
    end
else
    [validSubNum, msg] = subjectValidator(input.subject, '.csv', input.debugLevel);
    assert(validSubNum, msg)
end

% now that we have all the input and its passed validation, we can have
% a file path!
constants.fName=fullfile(constants.savePath, strjoin({'Subject', num2str(input.subject), 'Group',num2str(input.group)},'_'));

% Define the input handler function we will use with the test() function
if any(input.debugLevel == [0 1 2])
    inputHandler = makeInputHandlerFcn('KbQueue');
else
    inputHandler = makeInputHandlerFcn('Robot');
end

%% Set up the experimental design %%
% read in the design matrix and the word stimuli
design = readtable(fullfile(constants.stimDir, 'designMatrix.csv'));
stimlist = readtable(fullfile(constants.stimDir, 'stimlist.csv'));
stimlist = stimlist(randperm(size(stimlist,1)),:); % randomize word order
response = table({''}, NaN, NaN, 'VariableNames',{'response','firstPress' 'lastPress'}); % placeholder

% Some experimental constants
constants.nLists = 10;
constants.nTargets = length(unique(design.target));
constants.nCues = length(unique(design.cue));
constants.CTratio = constants.nCues/constants.nTargets;
if input.debugLevel == 0
    constants.cueDur = 4; % Length of time to study each cue-target pair
    constants.testDur = 8;
    constants.countdownSpeed = 1;
    constants.gamebreak = 30;
    constants.Delay=20;
    constants.readtime=10;
else
    constants.cueDur = .25; % Length of time to study each cue-target pair
    constants.testDur = 8;
    constants.countdownSpeed = .25;
    constants.gamebreak = 5;
    constants.Delay = 5;
    constants.readtime = .5;
end


% Create study lists from design matrix
studyLists = repmat(design, constants.nLists, 1);
studyLists.cue = stimlist.WORD(1:size(studyLists,1));
stimlist(1:size(studyLists,1),:) = [];
targetIndex = repmat(1:(size(studyLists)/constants.CTratio), constants.CTratio, 1);
targetIndex = targetIndex(:);
studyLists.target = stimlist.WORD(targetIndex);

% Add list identifier
listID = repmat(1:constants.nLists, size(studyLists,1)/constants.nLists, 1);
studyLists.list = listID(:);
% add column to hold onset timestamps
studyLists.onset = nan(size(studyLists,1),1);
% Randomize the order of conditions within lists
studyLists = randomizeLists(studyLists);
assert(length(unique(studyLists.cue)) == size(studyLists,1));
assert(length(unique(studyLists.target)) == size(studyLists,1)/2);

% Create practice lists
pracLists = studyLists(~strcmp(studyLists.practice,'C'),:);
assert(size(pracLists,1)== .6*size(studyLists,1))
% Randomize the order of the practice lists
pracLists = randomizeLists(pracLists);
assert(length(unique(pracLists.cue)) == size(pracLists,1));
assert(length(unique(pracLists.target)) == size(pracLists,1) * (2/3));
% Duplicate the practice lists since each item gets two practice chances
pracLists = [pracLists table(ones(size(pracLists,1),1), 'VariableNames', {'pracRound'}); ...
    pracLists table(repmat(2,120,1), 'VariableNames', {'pracRound'})];
% add the columns for the reponses
pracLists = [pracLists, repmat(response,size(pracLists,1))];
% counterbalance the order of the study/test practices
if mod(input.subject, 2) == 0 
    constants.pracOrder = repmat({'S';'T'}, 5 ,1);
else
    constants.pracOrder = repmat({'T';'S'}, 5 ,1);
end

% Create final test phase lists
finalLists = studyLists(studyLists.finalTest == 1,:);
assert(size(finalLists,1)== .5*size(studyLists,1))
% Randomize the order of the final test lists lists
finalLists = randomizeLists(finalLists);
assert(length(unique(finalLists.cue)) == size(finalLists,1));
assert(length(unique(finalLists.target)) == size(finalLists,1));
% add the columns for the reponses
finalLists = [finalLists, repmat(response,size(finalLists,1))];


%% Open the PTB window
    [window, constants] = windowSetup(constants, input);

%% Give the instructions %%
try
    giveInstructions('intro', inputHandler, window, constants, input)
%% Main Loop %%
    % set up the keyboard
    keysOfInterest = zeros(1,256);
    keysOfInterest([65:90 KbName('BACKSPACE') KbName('RightArrow') KbName('RETURN')]) = 1;
    KbQueueCreate([], keysOfInterest);

    countdown('It''s time to study a new list of pairs', 5, constants.countdownSpeed,  window, constants);    
    for i = 1:constants.nLists
        % Study Phase
        studyListIndex = studyLists.list == i;
        studyLists.onset(studyListIndex) = study(studyLists(studyListIndex, {'cue','target'}), window, constants);

        % Practice Phase
        pracListIndex = pracLists.list == i;
        pracLists(pracListIndex,:) = practice(pracLists(pracListIndex,:), constants.pracOrder{i}, inputHandler, window, constants);

        if  strcmp('immediate', input.group)
            finalListIndex = finalLists.list == i;
            countdown('Final Test', 5, constants.countdownSpeed,  window, constants);
            [onset, response, firstPress, lastPress] = testing(finalLists(finalListIndex,:), inputHandler, window, constants);
            data.onset(finalListIndex) = onset;
            data.response(finalListIndex) = response;
            data.firstPress(finalListIndex) = firstPress;
            data.lastPress(finalListIndex) = lastPress;         
            if i==3 || i ==6
                % gamebreak, countdown is place holder
                countdown('Game Break', constants.gamebreak ,constants.countdownSpeed, window, constants);
            end
        else
            if i == 5
                % gamebreak, countdown is place holder
                countdown('Game Break', constants.gamebreak ,constants.countdownSpeed, window, constants)
            end
            
        end
        
        if i < 10
            countdown('It''s time to study a new list of pairs', 5, constants.countdownSpeed,  window, constants);
        end        
    end
    
    if  strcmp('delay', input.group)
        for i = 1:10
            % Take the final test
            finalListIndex = finalLists.list == i;
            countdown('Final Test', 5, constants.countdownSpeed,  window, constants);
            [onset, response, firstPress, lastPress] = testing(finalLists(finalListIndex,:), inputHandler, window, constants);
            data.onset(finalListIndex) = onset;
            data.response(finalListIndex) = response;
            data.firstPress(finalListIndex) = firstPress;
            data.lastPress(finalListIndex) = lastPress;
            %  shortbreak
            if i < 10
                countdown('Short Break', 5, constants.countdownSpeed,  window, constants);
            end
        end
    end

%% end of the experiment %%
    windowCleanup(constants)
    exit_stat=0;
catch
    psychrethrow(psychlasterror);
    windowCleanup(constants)
end
end % end main()

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

function windowCleanup(constants)
    sca; % alias for screen('CloseAll')
    rmpath(constants.lib_dir,constants.root_dir);
end

function [window, constants] = windowSetup(constants, input)
    PsychDefaultSetup(2);
    constants.screenNumber = max(Screen('Screens')); % Choose a monitor to display on
    constants.res=Screen('Resolution',constants.screenNumber); % get screen resolution
    constants.dims = [constants.res.width constants.res.height];
    if any(input.debugLevel == [0 1 3])
    % Set the size of the PTB window based on screen size and debug level
        constants.screen_scale = [];
        constants.indent=500;
        constants.wrapat=60; % line length
    else
        constants.screen_scale = round(reshape((constants.dims' * [(1/8),(7/8)]),1,[]));
        constants.indent=100;
        constants.wrapat=50; % line length
    end
    constants.spacing=35;

    try
        [window, constants.winRect] = Screen('OpenWindow', constants.screenNumber, (3/4)*[255 255 255], constants.screen_scale);
    % define some landmark locations to be used throughout
        [constants.xCenter, constants.yCenter] = RectCenter(constants.winRect);
        constants.center = [constants.xCenter, constants.yCenter];
        constants.left_half=[constants.winRect(1),constants.winRect(2),constants.winRect(3)/2,constants.winRect(4)];
        constants.right_half=[constants.winRect(3)/2,constants.winRect(2),constants.winRect(3),constants.winRect(4)];
        constants.top_half=[constants.winRect(1),constants.winRect(2),constants.winRect(3),constants.winRect(4)/2];
        constants.bottom_half=[constants.winRect(1),constants.winRect(4)/2,constants.winRect(3),constants.winRect(4)];

    % Get some the inter-frame interval, refresh rate, and the size of our window
        constants.ifi = Screen('GetFlipInterval', window);
        constants.hertz = FrameRate(window); % hertz = 1 / ifi
        constants.nominalHertz = Screen('NominalFrameRate', window);
        [constants.width, constants.height] = Screen('DisplaySize', constants.screenNumber); %in mm

    % Font Configuration
        Screen('TextFont',window, 'Arial');  % Set font to Arial
        Screen('TextSize',window, 28);       % Set font size to 28
        Screen('TextStyle', window, 1);      % 1 = bold font
        Screen('TextColor', window, [0 0 0]); % Black text
    catch
        psychrethrow(psychlasterror);
        windowCleanup(constants)
    end
end

function data = randomizeLists(data)
    for i = unique(data.list)'
        rows = data.list == i;
        items = data(rows,:);
        data(rows,:) = items(randperm(sum(rows)),:);
    end
end