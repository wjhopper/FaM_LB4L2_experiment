function exit_stat = main(varargin)

exit_stat = 1;
if Screen('NominalFrameRate', max(Screen('Screens'))) ~= 60
    errordlg('Monitor refresh rate must be set to 60hz');
    return;
end
 % assume that we exited badly if ever exit before this gets reassigned
% use the inputParser class to deal with arguments
ip = inputParser;
ip.KeepUnmatched = true;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip,'subject', 0, @isnumeric);
addParamValue(ip,'group', [], @ischar);
addParamValue(ip,'debugLevel',0, @isnumeric);
addParamValue(ip,'robotType', 'Good', @(x) sum(strcmp(x, {'Good','Bad','Chaotic'}))==1);
parse(ip,varargin{:}); 
input = ip.Results;
defaults = ip.UsingDefaults;

constants.exp_onset = GetSecs; % record the time the experiment began
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
if any(ismember(defaults, 'subject')) % only subject should be allowed to be set by GUI
% call gui for input
    guiInput = getSubjectInfo('subject', struct('title', 'Subject Number', 'values', '', 'type', 'textinput', 'validationFcn', subjectValidator));
    if isempty(guiInput)
        exit_stat = 1;
        return
    else
       input = filterStructs(guiInput, input); % Overwrite any fields in the CLI input that are also given via GUI input
       input.subject = str2double(input.subject); 
    end
else
    [validSubNum, msg] = subjectValidator(input.subject);
    assert(validSubNum, msg)
end


%% Ask for demographics if we're not debugging heavily
if input.debugLevel <= 2;
    demographics(constants.savePath);
end

%% Determine Group, if not specified on command line
if ismember('group', ip.UsingDefaults)
    groups = {'immediate','delay'};
    input.group = groups{randi(2,1,1)};
end

% now that we have all the input and its passed validation, we can have a file path!
% Remember that this is a file path WITHOUT AN EXTENSION!!!!
constants.fName=fullfile(constants.savePath, strjoin({'Subject', num2str(input.subject)},'_'));

clear defaults groups varargin guiInput msg validSubNum subjectValidator

%% Debug Levels
% Level 0: normal experiment
if input.debugLevel >= 0
    constants.cueDur = 4; % Length of time to study each cue-target pair
    constants.testDur = 8;
    constants.gamebreak = 300;
    constants.readtime=10;
    constants.countdownSpeed = 1;
    constants.ISI = .5;    
    inputHandler = makeInputHandlerFcn('KbQueue');
end

% Level 1: Fast Stim durations, readtimes & breaks
if input.debugLevel >= 1
    hertz = Screen('NominalFrameRate', max(Screen('Screens'))); % hertz = 1/ifi
    constants.cueDur = (30/hertz); % pairs on screen for the length of 30 flip intercals 
    constants.testDur = 3;
    constants.gamebreak = 10;
    constants.readtime = constants.cueDur;
end

% Level 2: Fast countdowns & Game
if input.debugLevel >= 2
    constants.countdownSpeed = constants.cueDur;
    constants.gamebreak = 5;
end

% Level 4: Robot input
if input.debugLevel >= 4
    inputHandler = makeInputHandlerFcn([input.robotType,'Robot']);
end

% Level 4: Extreme debugging, useful for knowing if flips are timed ok.
if input.debugLevel >= 5
    constants.cueDur = (1/hertz); % pairs on screen for only 1 flip
    constants.countdownSpeed = constants.cueDur;
    constants.readtime = constants.cueDur;
    constants.ISI = constants.cueDur;
end
    
%% Set up the experimental design %%
% Some experimental constants
constants.nLists = 10;
constants.nTargets = 10;
constants.nCues = 20;
constants.CTratio = constants.nCues/constants.nTargets;
constants.nTrials = constants.nCues*constants.nLists;
constants.practiceCountdown = 3;
constants.finalTestCountdown = 5;
constants.finalTestBreakCountdown = 10;
constants.studyNewListCountdown = 5;
constants.gamebreakCountdown = 5;

% read in the design matrix and the word stimuli
design = readtable(fullfile(constants.stimDir, 'designMatrix.csv'));
assert(constants.nTargets == length(unique(design.target)), ...
    'number of targets per list declared does not match number of targets in design matrix');
assert(constants.nCues == length(unique(design.cue)), ...
    'number of cues per list declared does not match number of cues in design matrix');
stimlist = readtable(fullfile(constants.stimDir, 'stimlist.csv'));
stimlist = stimlist(randperm(size(stimlist,1)),:); % randomize word order
response = table({''}, NaN, NaN, 'VariableNames',{'response','firstPress' 'lastPress'}); % placeholder

%% Create study lists using design matrix and experimental constants
% Generate list ID variable
listID = repmat(1:constants.nLists, constants.nTrials/constants.nLists, 1);
% Create the study list table
studyLists = [table(repmat(input.subject, constants.nTrials, 1), repmat(input.group, constants.nTrials, 1), 'VariableNames', {'subject', 'group'}), ... % subject & group columns
    table(listID(:),'VariableNames', {'list'}), ... % list column
    table(stimlist.WORD(1:constants.nTrials), 'VariableNames', {'cue'}), ... % Cue words
    cell2table(cell(200, 2), 'VariableNames', {'target', 'practice'}), ... % target &  practice columns, (blank for now)
    array2table(nan(constants.nTrials,2), 'VariableNames', {'test', 'onset'})]; % test and onset column (missing for now
% remove the used up words from the pool
stimlist(1:constants.nTrials, :) = [];

% Insert target words: we need to repeat targets twice in each list,
% but we want the repetition to occur after each unique target
% has been presented at least once (i.e. lag between each occurance is 10).
% This is all for randomizing the order of conditions while meeting this
% constraint.
for i = 1:constants.nLists 
    % find the rows for the current list in the study list table
    rows = studyLists.list == i;
    % random order of each unique target for the list
    T_O = randperm(constants.nTargets); % T_O = "target order"
    % insert target words into the study list table
    studyLists.target(rows) = stimlist.WORD([ T_O, T_O ]);
    % remove used up words from the pool
    stimlist(1:constants.nTargets, :) = [];
    % Sort the condition mapping columns by random target order
    cond_orders = [design(T_O, {'practice', 'test'}) ;  design(T_O + max(T_O), {'practice', 'test'})];
    % insert the sorted condition mapping columns into the study list table
    studyLists(rows, {'practice', 'test'}) = cond_orders;
end
%% Checking constraints the study lists 
% Check that all cues are unique
assert(length(unique(studyLists.cue)) == size(studyLists,1));
% Check to be sure targets repeat twice
assert(length(unique(studyLists.target)) == constants.nTargets*constants.nLists);
% Check to be sure no targets get different practice types
studyRows = strcmp('S',studyLists.practice);
testRows = strcmp('T',studyLists.practice);
assert(isempty(intersect(studyLists.target(testRows),studyLists.target(studyRows))), ...
    'Target word set to recieve both study and test practice, which should be structually impossible for this design');
% Check that no word is used as both cue and target
assert(isempty(intersect(studyLists.cue,studyLists.target)), ...
    'Word used as both cue and target, which should be structually impossible for this design')

clear stimlist design listID rows T_O testRows studyRows i cond_orders

%% Create practice lists
% Practiced pairs are all those with an entry in the 'practice' column
pracLists = studyLists(~strcmp('', studyLists.practice),:);
% Check that subsetting the study list still leaves us with all unique cues
assert(length(unique(pracLists.cue)) == size(pracLists,1), 'Not all cues used in pratice are unique');
% Check that no target is practiced twice
assert(length(unique(pracLists.target)) == size(pracLists,1), 'Not all targets praticed are unique');
% Only 2 targets from each condition should be practiced (minus the control condition which gets nothing)
assert(size(pracLists,1)== .4*size(studyLists,1), 'Too many pairs set to receive practice')

% add the columns for the reponses
pracLists = [pracLists, repmat(response,size(pracLists,1),1)];
% Duplicate the practice lists since each item gets two practice chances
pracLists = [ repmat(pracLists, 2, 1), ...
    table([ones(size(pracLists,1),1) ; repmat(2,size(pracLists,1),1)], 'VariableNames', {'round'})];
% counterbalance the order of the study/test practices
if mod(input.subject, 2) == 0 
    constants.pracOrder = repmat({'S';'T'}, 5 ,1);
else
    constants.pracOrder = repmat({'T';'S'}, 5 ,1);
end

%% Create final test lists
finalLists = studyLists(studyLists.test == 1,:);
assert(size(finalLists,1)== .5*size(studyLists,1))
assert(length(unique(finalLists.cue)) == size(finalLists,1));
assert(length(unique(finalLists.target)) == size(finalLists,1));
% add the columns for the reponses
finalLists = [finalLists, repmat(response,size(finalLists,1),1)];
clear response

%% Open the PTB window
constants.firstRun = 1;
[window, constants] = windowSetup(constants);

%% Give the instructions %%
try
    giveInstructions('intro', input, inputHandler, window, constants)
    % set up the keyboard
    setupTestKBQueue;
%% Main Loop %%
    countdown('It''s time to study a new list of pairs', constants.studyNewListCountdown, ...
        constants.countdownSpeed,  window, constants);    
    for i = 1:constants.nLists
        % Study Phase
        studyListIndex = studyLists.list == i;
        studyLists.onset(studyListIndex) = study(studyLists(studyListIndex, {'cue','target'}), window, constants);

        % Practice Phase
        pracListIndex = pracLists.list == i;
        pracLists(pracListIndex,:) = practice(pracLists(pracListIndex,:), constants.pracOrder{i}, inputHandler, window, constants);

        if  strcmp('immediate', input.group)
            finalListIndex = finalLists.list == i;
            giveInstructions('final', input, inputHandler, window, constants);
            [onset, response, firstPress, lastPress] = testing(finalLists(finalListIndex,:), inputHandler, window, constants);
            finalLists.onset(finalListIndex) = onset;
            finalLists.response(finalListIndex) = response;
            finalLists.firstPress(finalListIndex) = firstPress;
            finalLists.lastPress(finalListIndex) = lastPress;         
            if i== 3 || i ==6
                [window, constants] = gamebreak(window, constants);
                giveInstructions('resume', input, [], window, constants);
                setupTestKBQueue;
            end
        else
            if i == 5 || i == 10
                [window, constants] = gamebreak(window, constants);
                giveInstructions('resume', input, [], window, constants); 
                setupTestKBQueue;
            end
            if i == 10 % if its the last list
                giveInstructions('final', input, inputHandler, window, constants);
                for j = 1:10
                    % Take the final test
                    finalListIndex = finalLists.list == j;
                    [onset, response, firstPress, lastPress] = testing(finalLists(finalListIndex,:), inputHandler, window, constants);
                    finalLists.onset(finalListIndex) = onset;
                    finalLists.response(finalListIndex) = response;
                    finalLists.firstPress(finalListIndex) = firstPress;
                    finalLists.lastPress(finalListIndex) = lastPress;
                    %  shortbreak
                    if j < 10
                        countdown('Take a short break, the test will resume in', constants.finalTestBreakCountdown,...
                            constants.countdownSpeed,  window, constants);
                    end
                end
            end            
        end
        
        if i < 10
            countdown('It''s time to study a new list of pairs', constants.studyNewListCountdown, ...
                constants.countdownSpeed,  window, constants);
        end      
    end
    
%% end of the experiment %%
    % write the data to file
    writetable(studyLists, [ constants.fName '_Study.csv' ])
    testRows = strcmp('T', pracLists.practice);
    writetable(pracLists(~testRows,:), [ constants.fName '_StudyPractice.csv' ])
    writetable(pracLists(testRows,:),  [ constants.fName '_TestPractice.csv' ])
    writetable(finalLists, [ constants.fName '_Final.csv' ])
    
    giveInstructions('bye', input, [], window, constants);
    cleanup(constants)
    exit_stat=0;
catch
    cleanup(constants)
    psychrethrow(psychlasterror);    
end
end % end main()

function overwriteCheck = makeSubjectDataChecker(directory, extension, debugLevel)
    % makeSubjectDataChecker function closer factory, used for the purpose
    % of enclosing the directory where data will be stored. This way, the
    % function handle it returns can be used as a validation function with getSubjectInfo to 
    % prevent accidentally overwritting any data. 
    function [valid, msg] = subjectDataChecker(value, ~)
        % the actual validation logic
        
        if ischar(value)
            subnum = str2double(value);
        else
            subnum = value;
        end
        if  isnan(subnum) || (subnum <= 0  && debugLevel <= 2);
            valid = false;
            msg = 'Subject Number must be greater than 0';
            return
        end
        
        filePathGlob = fullfile(directory, ['*Subject_', num2str(subnum), '*', extension]);
        if ~isempty(dir(filePathGlob)) && debugLevel <= 2
            valid= false;
            msg = strjoin({'Data file for Subject',  num2str(subnum), 'already exists!'}, ' ');                   
        else
            valid= true;
            msg = 'ok';
        end
    end

overwriteCheck = @subjectDataChecker;
end

function cleanup(constants)
    sca; % alias for screen('CloseAll')
    if isfield(constants, 'figureStruct')
        delete(constants.figureStruct.fig);
    end
    KbQueueRelease;
    Screen('Preference', 'VisualDebugLevel', constants.VisualDebug);
    rmpath(constants.lib_dir,constants.root_dir);
end

function [window, constants] = windowSetup(constants)

    if constants.firstRun
        constants.firstRun = 0;
        constants.VisualDebug = Screen('Preference', 'VisualDebugLevel', 4);
    else
        constants.VisualDebug = Screen('Preference', 'VisualDebugLevel', 1);
    end
    constants.screenNumber = max(Screen('Screens')); % Choose a monitor to display on
    constants.res=Screen('Resolution',constants.screenNumber); % get screen resolution
    constants.dims = [constants.res.width constants.res.height];
   
    try
        PsychDefaultSetup(2);
        HideCursor;
        [window, constants.winRect] = Screen('OpenWindow', constants.screenNumber, (4/5)*[255 255 255]);
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

    % Font Configuration'
        fontsize=28;
        Screen('TextFont',window, 'Arial');  % Set font to Arial
        Screen('TextSize',window, fontsize);       % Set font size to 28
        Screen('TextStyle', window, 1);      % 1 = bold font
        Screen('TextColor', window, [0 0 0]); % Black text

    % Text layout config
        constants.wrapat = round(constants.res.width/fontsize, -1); % line length
        constants.spacing=35;
        constants.leftMargin = constants.winRect(3)/5;
        
    catch
        psychrethrow(psychlasterror);
        cleanup(constants)
    end
end

function setupTestKBQueue
    keysOfInterest = zeros(1,256);
    keysOfInterest([65:90 KbName('BACKSPACE') KbName('RightArrow') KbName('RETURN')]) = 1;
    KbQueueCreate([], keysOfInterest);
end
function [window, constants] = gamebreak(window, constants)
    countdown(['Time for a break! Play some Tetris and relax.\n\n', ...
        'If you dont know how to play, click the ''Help'' button',...
        '\non the Tetris window that pops up'], ...
        constants.gamebreakCountdown ,constants.countdownSpeed, window, constants);
    sca; % this is good, don't remove this!!
    if ~isfield(constants, 'figureStruct')
        constants.figureStruct = tetris(0, 2);
    end
    pause(constants.gamebreak);
    status = get(constants.figureStruct.pbt, 'string');
    if strcmp('Pause',status)
       startButtonCallback = get(constants.figureStruct.pbt, 'callback');
       startButtonCallback();
    end
[window, constants] = windowSetup(constants);
  
end