function exit_stat = main(varargin)
    
    % use the inputParser class to deal with arguments
    ip = inputParser;
    %#ok<*NVREPL> dont warn about addParamValue
    addParamValue(ip,'subject', 0, @(x) isnumeric(x));
    addParamValue(ip,'debug_mode', 'default', @(x) (ischar(x) && any(strcmpi(x,{'default','testing','robot'}))));
    addParamValue(ip,'force',false, @(x) islogical(x));
    parse(ip,varargin{:}); 
    input = ip.Results;
    defaults = ip.UsingDefaults;
    
    exp_onset = GetSecs; % record the time the experiment began
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
end
