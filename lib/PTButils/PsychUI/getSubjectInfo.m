function resps = getSubjectInfo(varargin)

% Calling Example
% getSubjectInfo('subject', struct('label', 'Subject Number', 'type', 'textinput', 'validationFcn', @(x) (isnumeric(x) && ~isnan(x))), ...
%                'group', struct('label' ,'Group', 'type', 'dropdown', 'values', {{'immediate','delay'}}), ...
%                'session', struct('label', 'Session', 'type', 'dropdown', 'values', {{'1','2'}}));

%% --- parse and validate input --- %%

ip = inputParser;
ip.KeepUnmatched = true; % can have an arbitrary number of fields so this is important
addParamValue(ip,'title', 'Input Subject Info', @ischar); %#ok<*NVREPL> dont warn about addParamValue
parse(ip,varargin{:});
fields = validateInputStruct(ip.Unmatched);
%% --- Initialize the blank GUI window --- %%

%some gui object constants to use
width = 250;
margin = 10;
padding = 5;
button_size = 30;
textinput_size = 30;
dropdown_size = 30;
checkbox_size = 20;
label_size = 20;
height = button_size + (3*margin);
lookupTable = struct('textinput', {'edit', textinput_size},'check', {'checkbox', checkbox_size}, ...
                     'dropdown', {'popupmenu' ,dropdown_size}, 'label',{'Tag', label_size});

                 
% create figure 
dims =  get(0, 'ScreenSize');
fig = dialog('Name',ip.Results.title,'Position',[(dims(3)/2) + width/2, (dims(4)/2) + height/2, width, height], 'ToolBar','None','MenuBar','none', ...
    'NumberTitle','off','Visible','off');

% add elements to fig iteratively
offset= 0;
value_objs=[];
string_objs=[];
drop_objs=[];
title_obs=[];

for i=1:numel(s)
    
    if any(strcmp('label',fieldnames(s{i})))
        lab = s{i}.label;
    else
        lab = ['Field' num2str(i)];
         s{i}.label = lab;
    end
    
    if any(strcmp('mustbe',fieldnames(s{i}))) || any(strcmp('classcheck',fieldnames(s{i})))
        props.callback = {@interact, s{i}};
    end
    
% if its a drop down or text input field, give it a title and check its
% values setting, and assign its other properties
    if any(strcmp(s{i}.type, {'edit','popupmenu'}))
        props.Horiz ='left';
        props.Background ='w';
        props.FontSize= 11;
        props.Tag = s{i}.name;
        props.Position = [margin, height - offset - padding - label_size - textinput_size, width-2*margin, textinput_size];
        title_obs(i) = uicontrol(fig,'Style','text','String',lab, 'Horiz','left','Tag',[ s{i}.name '_lab'],  ... 
                        'Position',[margin, height - offset - margin - label_size, width-2*margin, label_size]); %#ok<*AGROW>
        if any(strcmp('values',fieldnames(s{i})))
            vals = s{i}.values;
        else
            vals= [];
        end 
    end
    
    if strcmp(s{i}.type, 'edit')
        string_objs(i) = uicontrol(fig,props,'Style','edit', 'String', vals);
        offset = offset +  textinput_size + label_size;
    elseif strcmp(s{i}.type, 'popupmenu')
        if any(strcmp('default',fieldnames(s{i}))) && s{i}.default <= numel(vals)
            selection = s{i}.default;
        else 
            selection = 1;
        end
        drop_objs(i) = uicontrol(fig,props,'Style','popupmenu', 'String', vals,'Value',selection);
        offset = offset +  dropdown_size + label_size;
    else
        if any(strcmp('value',fieldnames(s{i})))
            vals = s{i}.value;
        else
            vals= 0;
        end
        value_objs(end+1) = uicontrol(fig,props,'Style','checkbox','String',s{i}.label,'Val',s{i}.values,'Tag',s{i}.name, ...
        'Position',[margin, height - offset - margin - checkbox_size, width-2*margin, checkbox_size]);
        offset = offset + checkbox_size;
    end
end    
% blank out missings
value_objs(value_objs==0)=[];
string_objs(string_objs==0)=[];
drop_objs(drop_objs==0)=[];

% add buttons
uicontrol(fig, 'Style','pushbutton','String','Run','Tag','RunBtn','Callback' ,@done ,...
          'Pos', [(width/2)+padding height-(height-10) ((width-2*margin)/2)-margin, button_size]) 
uicontrol(fig, 'Style','pushbutton','String','Cancel','Tag','CancelBtn','Callback' ,@cancel , ...
          'Pos', [margin height-(height-10) ((width-2*margin)/2)-padding, button_size])       

% Wait for input
set(fig,'Visible','on');
uiwait(fig);

% Parse input
if ishghandle(fig) 
    if strcmp(get(fig,'UserData'),'OK'),
        if ~exist('resps','var')
            resps=struct();
        end
        for j=1:numel(string_objs)
            resps.(get(string_objs(j),'Tag')) = get(string_objs(j),'String');
        end
        for j=1:numel(drop_objs)
            resps.(get(drop_objs(j),'Tag')) =  CurrentPopupString(drop_objs(j),'get');
        end
        for j=1:numel(value_objs)
            resps.(get(value_objs(j),'Tag')) = get(value_objs(j),'Value');
        end
        delete(fig);
    end
else
  resps=[];  %#ok<NASGU>
end

end

function interact(obj, evd, s)
    if isempty(evd)
        evd = false;
    end
    if strcmp(s.type, 'edit') && isempty(get(obj,'String'))
        return
    end
    
    if any(strcmp('classcheck',fieldnames(s))) && strcmp(s.type, 'edit')
        if ~s.classcheck(str2double(get(obj,'String')))
            set(obj,'UserData','bad')
            msg = strjoin({'Incorrect data type for', s.label, 'field'},' ');
        else
            set(obj,'UserData','good')
        end
    end
    
	if ~exist('msg','var') && any(strcmp('mustbe',fieldnames(s))) && ~ischar(s.mustbe)
        cond = s.mustbe;
        h = findobj('Tag',cond{2});
        switch get(obj,'Style')
            case 'edit'
                data = str2double(get(obj,'String'));
            case 'popupmenu'
                data = CurrentPopupString(obj,'get');
            case 'checkbox'
                data = get(obj,'Values');
        end 
        switch get(h,'Style')
            case 'edit'
                str = get(h,'String');
                if (any(strcmp(str,cond{3})) && ~strcmp(data,cond{1}))
                    set(obj,'UserData','bad')
                    msg = strjoin({s.label 'must be' cond{1} 'when' cond{2} 'is' cond{3} }, ' ');
                else
                    set(obj,'UserData','good')
                end
            case 'popupmenu'
                if (any(strcmp(CurrentPopupString(h,'get'), cond{3})) &&  ~strcmp(data,cond{1}))  
                    set(obj,'UserData','bad')
                    msg = strjoin({s.label 'must be' cond{1} 'when' cond{2} 'is' cond{3} }, ' ');
                else
                    set(obj,'UserData','good')
                end
            case 'checkbox'
                if get(h,'Values') == cond{3} && data ~= cond{1}
                    set(obj,'UserData','bad')
                    msg = strjoin({s.label 'must be' cond{1} 'when' cond{2} 'is' cond{3} }, ' ');
                else
                    set(obj,'UserData','good')
                end
        end 
	end
    if strcmp(get(obj,'UserData'),'bad');
        lab_handle = findobj('Tag',[s.name '_lab']);
        set(lab_handle,'String',msg);
        set(lab_handle,'Background','r');
        set(findobj('Tag','RunBtn'),'Enable','off')
    else
        lab_handle = findobj('Tag',[s.name '_lab']);
        set(lab_handle,'String',s.label);
        set(lab_handle,'Background',[.94 .94 .94]); 
        if evd ~= 1 &&  exist('h','var') && ishghandle(h)
            callbackCell = get(h,'Callback');
            callbackCell{1}(h,1,callbackCell{2:end});
        end
        if isempty(findobj('UserData','bad'));
            set(findobj('Tag','RunBtn'),'Enable','on');
        end
    end
    
end

function doneKeyPress(obj, evd) %#ok
    switch(evd.Key)
      case {'return'}
        if ~strcmp(get(obj,'UserData'),'Cancel')
          set(gcbf,'UserData','OK');
          uiresume(gcbf);
        else
          delete(gcbf)
        end
      case 'escape'
        delete(gcbf)
    end
end

function done(obj, evd) %#ok
    if ~strcmp(get(obj,'UserData'),'Cancel')
      set(gcbf,'UserData','OK');
      uiresume(gcbf);
    else
      delete(gcbf)
    end
end

function cancel(obj,evd)
     delete(gcbf)
end

function str = CurrentPopupString(hh,action,strValue)
    %# getCurrentPopupString returns the currently selected string in the popupmenu with handle hh

    %# could test input here
    if ~ishandle(hh) || strcmp(get(hh,'Type'),'popupmenu')
    error('getCurrentPopupString needs a handle to a popupmenu as input')
    end

    %# get the string - do it the readable way
    list = get(hh,'String');
    val = get(hh,'Value');
    switch action
        case 'get'
            if iscell(list)
               str = list{val};
            else
               str = list(val,:);
            end
        case 'set'
            set(hh,'Value',find(strcmp(strValue,list)))
            str=strValue;
    end
end

function guiFields = validateInputStruct(guiFields)

validProperties = {'type','values','label', 'validationFcn'};
errorGeneric = '\nFeild ''%s'' is missing a value for the required property ''%s''.\n';

    for i = fieldnames(guiFields)'
        current = i{1};
        currentFieldProperties = fieldnames(guiFields.(current));
        difference = strcat('"', setdiff(currentFieldProperties, validProperties), '"');
        assert(all(ismember(currentFieldProperties, validProperties)), ...
               strjoin({'Field "%s" contains unrecognized properties:', difference{:}}, ' '), ...
               current) %#ok<CCAT>
        assert( (isfield(guiFields.(current),'type') && ismember(guiFields.(current).type, {'textinput','dropdown','check'}) ), ...
               [errorGeneric '''type'' must be specified as either ''textinput'', ''dropdown'', or ''check'' for each field.'], ...
               current, 'type')
        assert( isfield(guiFields.(current),'label'), ...
               [errorGeneric '''type'' must be specified as either ''textinput'', ''dropdown'', or ''check'' for each field.'], ...
               current, 'type')
        if strcmp('dropdown', guiFields.(current).type)
            assert(isfield(guiFields.(current),'values') && all(~cellfun(@isempty, guiFields.(current).values)), ...
                   [errorGeneric 'Fields with ''type'' set to ''dropdown'' must use the property ''values'' to populate the menu options.'], ...
                   current, 'values');
        else
            if isfield(guiFields.(current),'values')
                guiFields.(current).values = '';
            end
        end
        if ~isfield(guiFields.(current),'validationFcn')
            guiFields.(current).validationFcn = @(x) true ;
        end
    end
end
