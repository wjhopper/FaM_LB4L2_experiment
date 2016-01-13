function resps = getSubjectInfo(varargin)

% Calling Example 
% c = { struct('name','sub_num','type','textinput','label','Subject Number','classcheck',@(x) (isnumeric(x) && ~isnan(x))), ...
%       struct('name','group','type','dropdown','label','Group','values',{{'immediate','delay'}},'mustbe', {{'delay','session','2'}}), ...
%       struct('name','session','type','dropdown','label','Session','values',{{'1','2'}},'mustbe', {{'1','group','immediate'}}) };

% getSubjectInfo('components',c);

% parse input arguments
ip = inputParser;
ip.KeepUnmatched = true;
addParamValue(ip,'components', {struct('name','sub_num','type','textinput','label','Subject Number')}, @iscell);
addParamValue(ip,'win_name', 'Input Subject Info', @ischar);
parse(ip,varargin{:}); 
s= ip.Results.components;
t = ip.Results.win_name;

%some gui object constants to use
margin = 10;
padding = 5;
BTN_size = 30;
TI_size = 30;
DD_size = 30;
CHK_size = 20;
label_size = 20;
table = {'textinput',{'edit',TI_size}; 'check',{'checkbox',CHK_size};'dropdown',{'popupmenu',DD_size}};
height = BTN_size + (3*margin);
width = 250;

% figure out correct size
for i=1:numel(s)
    if any(strcmp('type',fieldnames(s{i})))
        tmp = table{strcmp(s{i}.type,table(:,1)),2};
        s{i}.type = tmp{1}; %#ok<FXSET>
        height = height + tmp{2} + label_size;
    else
        s{i}.type = 'textinput'; %#ok<FXSET>
        height = height + label_size + TI_size + label_size;
    end
end

% create figure 
dims =  get(0, 'ScreenSize');
fig = dialog('Name',t,'Position',[(dims(3)/2) + width/2, (dims(4)/2) + height/2, width, height], 'ToolBar','None','MenuBar','none', ...
    'NumberTitle','off','Visible','off');

% add elements to fig
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
        props.Position = [margin, height - offset - padding - label_size - TI_size, width-2*margin, TI_size];
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
        offset = offset +  TI_size + label_size;
    elseif strcmp(s{i}.type, 'popupmenu')
        if any(strcmp('default',fieldnames(s{i}))) && s{i}.default <= numel(vals)
            selection = s{i}.default;
        else 
            selection = 1;
        end
        drop_objs(i) = uicontrol(fig,props,'Style','popupmenu', 'String', vals,'Value',selection);
        offset = offset +  DD_size + label_size;
    else
        if any(strcmp('value',fieldnames(s{i})))
            vals = s{i}.value;
        else
            vals= 0;
        end
        value_objs(end+1) = uicontrol(fig,props,'Style','checkbox','String',s{i}.label,'Val',s{i}.values,'Tag',s{i}.name, ...
        'Position',[margin, height - offset - margin - CHK_size, width-2*margin, CHK_size]);
        offset = offset + CHK_size;
    end
end    
% blank out missings
value_objs(value_objs==0)=[];
string_objs(string_objs==0)=[];
drop_objs(drop_objs==0)=[];

% add buttons
uicontrol(fig, 'Style','pushbutton','String','Run','Tag','RunBtn','Callback' ,@done ,...
          'Pos', [(width/2)+padding height-(height-10) ((width-2*margin)/2)-margin, BTN_size]) 
uicontrol(fig, 'Style','pushbutton','String','Cancel','Tag','CancelBtn','Callback' ,@cancel , ...
          'Pos', [margin height-(height-10) ((width-2*margin)/2)-padding, BTN_size])       

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
