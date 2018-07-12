%% ObjectFinder - Recognize 3D structures in image stacks
%  Copyright (C) 2016,2017,2018 Luca Della Santina
%
%  This file is part of ObjectFinder
%
%  ObjectFinder is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <https://www.gnu.org/licenses/>.
%

function [fig_handle, axes_handle, scroll_bar_handles, scroll_func] = colocVideoFig(redraw_func, ColocManual, Grouped, Post, Colo, Colo2, ColocManual2)

	%check arguments
	check_callback(redraw_func);

    size_video = [0 0.03 0.87 0.97]; % default video window size within the open window (set same as the original videofig) HO 2/17/2011
    click = 0;
    [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
    num_frames = size(ImStk,3);
	f = ceil(num_frames/2); % Current frame
   
    if NumRemainingDots == 0
        disp('Colocalization analysis complete, no more objects to process.');
        disp(['Colocalization Rate: ' num2str(ColocManual.ColocRate)]);
        return;
    end
    
    %initialize figure
	fig_handle = figure('Name','Colocalization Analysis','NumberTitle','off',...
        'Color',[.3 .3 .3], 'MenuBar','none', 'Units','norm', ...
		'WindowButtonDownFcn',@button_down, 'WindowButtonUpFcn',@button_up, ...
		'WindowButtonMotionFcn', @on_click, 'KeyPressFcn', @key_press, 'windowscrollWheelFcn', @wheel_scroll);
    
	% Add custom scroll bar
	scroll_axes_handle = axes('Parent',fig_handle, 'Position',[.000 .000 .860 .030], 'Visible','off', 'Units', 'normalized');
	axis([0 1 0 1]); axis off
	scroll_bar_width = max(1 / num_frames, 0.01);
	scroll_handle = patch([0 1 1 0] * scroll_bar_width, [0 0 1 1], [.8 .8 .8], 'Parent',scroll_axes_handle, 'EdgeColor','none', 'ButtonDownFcn', @on_click);
	
    % Add GUI conmponents
    set(gcf,'units', 'normalized', 'position', [0.25 0.1 0.455 0.72]);
    lblRefChan   = uicontrol('Style','text'      ,'Units','normalized','position',[.017,.970,.400,.020],'String',['Reference channel: ' ColocManual.Source]); %#ok, unused variable
    lblCurrObjs  = uicontrol('Style','text'      ,'Units','normalized','position',[.017,.050,.400,.020],'String',['Current ' ColocManual.Source ' (green)']); %#ok, unused variable
    if isempty(Colo2)
        lblColoChan  = uicontrol('Style','text'  ,'Units','normalized','position',[.445,.970,.400,.020],'String',['Colocalizing channel: ' ColocManual.Fish1]); %#ok, unused variable
        lblOverlay   = uicontrol('Style','text'  ,'Units','normalized','position',[.445,.050,.400,.020],'String',['Current ' ColocManual.Source ' (green),' ColocManual.Fish1 ' (magenta)']); %#ok, unused variable
    else
        lblColoChan  = uicontrol('Style','text'  ,'Units','normalized','position',[.445,.970,.400,.020],'String',['Colocalizing red: ' ColocManual.Fish1 ' green: ' ColocManual2.Fish1]); %#ok, unused variable
        lblOverlay   = uicontrol('Style','text'  ,'Units','normalized','position',[.445,.050,.400,.020],'String',['Current ' ColocManual.Source ' (green), ' ColocManual.Fish1 ' (red), ' ColocManual2.Fish1 ' (blue)']); %#ok, unused variable
    end

    pnlSettings  = uipanel(  'Title',' '         ,'Units','normalized','Position',[.865,.005,.133,.990]); %#ok, unused variable    
    lblObjNum    = uicontrol('Style','text'      ,'Units','normalized','position',[.880,.950,.110,.020],'String','Objects'); %#ok, unused variable
    lblObjTotal  = uicontrol('Style','text'      ,'Units','normalized','position',[.880,.920,.110,.020],'String',['Total: ' num2str(ColocManual.TotalNumDotsManuallyColocAnalyzed)]); %#ok, unused variable
    txtCurrent   = uicontrol('Style','text'      ,'Units','normalized','position',[.880,.900,.110,.020],'String',['Current: ' num2str(DotNum)]);
    txtRemaining = uicontrol('Style','text'      ,'Units','normalized','position',[.880,.880,.110,.020],'String',['Left: ' num2str(NumRemainingDots)]);

    btnResetLast = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.800,.110,.050], 'String','Reset last','CallBack',@btnResetLast_clicked); %#ok, unused variable        
    if isempty(Colo2)
        btnColoc    = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.510,.110,.100], 'String','Colocalized','CallBack',@btnColocalized_clicked); %#ok, unused variable
        btnNotColoc = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.400,.110,.100], 'String','<html><center>Not<br>Colocalized','CallBack',@btnNotColocalized_clicked); %#ok, unused variable
    else
        btnNotColoc12 = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.620,.110,.100], 'String','<html><center>Not<br>Colocalized','CallBack',@btnNotColoc12_clicked); %#ok, unused variable        
        btnColoc1     = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.510,.110,.100], 'String',['<html><center>Colocalized<br>with<br>' ColocManual.Fish1],'CallBack',@btnColoc1_clicked); %#ok, unused variable
        btnColoc2     = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.400,.110,.100], 'String',['<html><center>Colocalized<br>with<br>' ColocManual2.Fish1],'CallBack',@btnColoc2_clicked); %#ok, unused variable
        btnColoc12    = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.290,.110,.100], 'String','<html><center>Double<br>Colocalized','CallBack',@btnColoc12_clicked); %#ok, unused variable        
    end    
    btnSave      = uicontrol('Style','Pushbutton','Units','normalized','position',[.880,.030,.110,.050], 'String','Save','Callback',@btnSave_clicked); %#ok, unused variable
    
    % Main drawing axes for video display
    if size_video(2) < 0.03; size_video(2) = 0.03; end % Bottom 0.03 must be used for scroll bar HO 2/17/2011
	axes_handle = axes('Position',size_video); %[0 0.03 1 0.97] to size_video (6th input argument) to allow space for buttons and annotations 2/13/2011 HO
    
	% Return handles and initial call to redraw_func
	scroll_bar_handles = [scroll_axes_handle; scroll_handle];
	scroll_func = @scroll;
    scroll(f);
    uiwait;
    
    function [ImStk, DotNum, NumRemainingDots] = getNewImageStack()
        RemainingDotIDs = ColocManual.ListDotIDsManuallyColocAnalyzed(ColocManual.ColocFlag == 0);
        NumRemainingDots = length(RemainingDotIDs);
        if NumRemainingDots > 0 
            dot = ceil(rand*NumRemainingDots); % randomize the order of analyzing dots
            DotNum = RemainingDotIDs(dot);
            PostVoxMap = zeros(size(Post), 'uint8');
            PostVoxMap(Grouped.Vox(DotNum).Ind) = 1;
            CutNumVox = [60, 60, 20];
            PostCut = colocDotStackCutter(Post, Grouped, DotNum, [], CutNumVox);
            ColoCut = colocDotStackCutter(Colo, Grouped, DotNum, [], CutNumVox);
            if ~isempty(Colo2)
                Colo2Cut = colocDotStackCutter(Colo2, Grouped, DotNum, [], CutNumVox);
            end

            PostVoxMapCut = colocDotStackCutter(PostVoxMap, Grouped, DotNum, [], CutNumVox);
            
            MaxRawBright = max(Grouped.Vox(DotNum).RawBright);
            %PostMaxRawBright = single(max(PostCut(:)));
            PostUpperLimit = 200;
            PostScalingFactor = PostUpperLimit/MaxRawBright; % Normalized to brightness of the current object
            PostCutScaled = uint8(single(PostCut)*single(PostScalingFactor));

            ColoMaxRawBright = single(max(ColoCut(:)));
            ColoUpperLimit = 200;
            ColoScalingFactor = ColoUpperLimit/ColoMaxRawBright; % Normalized to the local field's brightness
            ColoCutScaled = uint8(single(ColoCut)*single(ColoScalingFactor));

            if ~isempty(Colo2)
                Colo2MaxRawBright = single(max(Colo2Cut(:)));
                Colo2UpperLimit = 200;
                Colo2ScalingFactor = Colo2UpperLimit/Colo2MaxRawBright; % Normalized to the local field's brightness
                Colo2CutScaled = uint8(single(Colo2Cut)*single(Colo2ScalingFactor));
            end
            
            ZeroCut = uint8(zeros(size(PostCut)));
            
            ImStk1 = cat(4, PostCutScaled, PostCutScaled, PostCutScaled);
            if ~isempty(Colo2)
                ImStk2 = cat(4, ColoCutScaled, ZeroCut, Colo2CutScaled);
            else
                ImStk2 = cat(4, ColoCutScaled, ColoCutScaled, ColoCutScaled);
            end
            
            if ~isempty(Colo2)
                ImStk3 = cat(4, ZeroCut, PostCutScaled.*PostVoxMapCut, ZeroCut);
                ImStk4 = cat(4, ColoCutScaled, PostCutScaled.*PostVoxMapCut, Colo2CutScaled);
            else
                ImStk3 = cat(4, ZeroCut, PostCutScaled.*PostVoxMapCut, ZeroCut);                
                ImStk4 = cat(4, ColoCutScaled, PostCutScaled.*PostVoxMapCut, ColoCutScaled);
            end

            % Separate left and right panels visually with a vertical line
            ImStk1(1:end, end, 1:end, 1:3) = 60;
            ImStk3(1:end, end, 1:end, 1:3) = 60;
            % Separate top and bottom panels visually with a vertical line
            ImStk3(1, 1:end, 1:end, 1:3) = 60;
            ImStk4(1, 1:end, 1:end, 1:3) = 60;

            ImStk = cat(1, cat(2, ImStk1, ImStk2),  cat(2, ImStk3, ImStk4));
        else
            % Add stats so that you can remember ColocFlag of 1 is coloc, etc.
            ColocManual.NumDotsColoc = length(find(ColocManual.ColocFlag == 1));
            ColocManual.NumDotsNonColoc = length(find(ColocManual.ColocFlag == 2));
            ColocManual.NumFalseDots = length(find(ColocManual.ColocFlag == 3));
            ColocManual.ColocRate = ColocManual.NumDotsColoc/(ColocManual.NumDotsColoc+ColocManual.NumDotsNonColoc);
            ColocManual.FalseDotRate = ColocManual.NumFalseDots/(ColocManual.NumDotsColoc+ColocManual.NumDotsNonColoc+ColocManual.NumFalseDots);
            ColocManual.ColocRateInclugingFalseDots = ColocManual.NumDotsColoc/(ColocManual.NumDotsColoc+ColocManual.NumDotsNonColoc+ColocManual.NumFalseDots);            

            if ~isempty(Colo2)            
                    % Add stats so that you can remember ColocFlag of 1 is coloc, etc.
                    ColocManual2.NumDotsColoc = length(find(ColocManual2.ColocFlag == 1));
                    ColocManual2.NumDotsNonColoc = length(find(ColocManual2.ColocFlag == 2));
                    ColocManual2.NumFalseDots = length(find(ColocManual2.ColocFlag == 3));
                    ColocManual2.ColocRate = ColocManual2.NumDotsColoc/(ColocManual2.NumDotsColoc+ColocManual2.NumDotsNonColoc);
                    ColocManual2.FalseDotRate = ColocManual2.NumFalseDots/(ColocManual2.NumDotsColoc+ColocManual2.NumDotsNonColoc+ColocManual2.NumFalseDots);
                    ColocManual2.ColocRateInclugingFalseDots = ColocManual2.NumDotsColoc/(ColocManual2.NumDotsColoc+ColocManual2.NumDotsNonColoc+ColocManual2.NumFalseDots);            
            end
            
            if exist([pwd filesep 'Coloc.mat'], 'file')
                load([pwd filesep 'Coloc.mat'], 'Coloc');
                % Check if we need to replace a previously done analysis
                FoundColocManual  = false;
                FoundColocManual2 = false;
                for i=1:numel(Coloc)
                    if strcmp(Coloc(i).Source, ColocManual.Source) && strcmp(Coloc(i).Fish1, ColocManual.Fish1)
                        Coloc(i) = ColocManual;
                        FoundColocManual = true;
                    end
                    if (~isempty(Colo2)) && strcmp(Coloc(i).Source, ColocManual2.Source) && strcmp(Coloc(i).Fish1, ColocManual2.Fish1)
                        Coloc(i) = ColocManual2;
                        FoundColocManual2 = true;
                    end
                end
                
                % If nothing to replace, just append to the list
                if ~FoundColocManual
                    Coloc(end+1) = ColocManual; % Coloc is saved later
                end
                if ~isempty(Colo2) && ~FoundColocManual2
                    Coloc(end+1) = ColocManual2;
                end
            else
                % If Coloc.mat does not exist, create a new one
                Coloc = ColocManual; % Coloc is saved later
                if ~isempty(Colo2)
                    Coloc(2) = ColocManual2;
                end
            end
            save([pwd filesep 'Coloc.mat'], 'Coloc'); % Add completed analusis to Coloc
            
            % Delete any temporary file
            if exist([pwd filesep 'Colo.mat'], 'file')
                delete([pwd filesep 'Colo.mat']);
            end
            if exist([pwd filesep 'Colo2.mat'], 'file')
                delete([pwd filesep 'Colo2.mat']);
            end
            if exist([pwd filesep 'ColocManual.mat'], 'file')
                delete([pwd filesep 'ColocManual.mat']);
            end
            if exist([pwd filesep 'ColocManual2.mat'], 'file')
                delete([pwd filesep 'ColocManual2.mat']);
            end

            ImStk = [];
            DotNum = 0;
            return;
        end
    end
    
    function btnResetLast_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=0;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);
        msgbox('Last object will be examined again in random order.');
    end

    function btnColocalized_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);        
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);
    end

    function btnNotColocalized_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);        
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);        
    end

    function btnNotColoc12_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2;
        ColocManual2.ColocFlag(ColocManual2.ListDotIDsManuallyColocAnalyzed==DotNum)=2;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);        
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);        
    end

    function btnColoc1_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1;
        ColocManual2.ColocFlag(ColocManual2.ListDotIDsManuallyColocAnalyzed==DotNum)=2;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);        
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);
    end

    function btnColoc2_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2;
        ColocManual2.ColocFlag(ColocManual2.ListDotIDsManuallyColocAnalyzed==DotNum)=1;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);        
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);
    end

    function btnColoc12_clicked(src, event) %#ok, unused arguments
        ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1;
        ColocManual2.ColocFlag(ColocManual2.ListDotIDsManuallyColocAnalyzed==DotNum)=1;
        [ImStk, DotNum, NumRemainingDots] = getNewImageStack();
        set(txtCurrent,'string',['Current: ' num2str(DotNum)]);
        set(txtRemaining,'string',['Left: ' num2str(NumRemainingDots)]);        
        num_frames = size(ImStk,3);
        f = ceil(num_frames/2); % Current frame
        scroll(f);
    end

    function btnSave_clicked(src, event) %#ok, unused arguments
        save([pwd filesep 'ColocManual.mat'], 'ColocManual');
        if ~isempty(Colo2)
            save([pwd filesep 'ColocManual2.mat'], 'ColocManual2');
        end
        msgbox('Progress saved.');        
    end
    
    function wheel_scroll(src, event) %#ok
          if event.VerticalScrollCount < 0
              %disp('scroll up');
              %position = get(scroll_handle, 'XData');
              %disp(position);
              scroll(f+1);
          elseif event.VerticalScrollCount > 0
              %disp('scroll down');
              scroll(f-1);
          end
    end
    
	function key_press(src, event)  %#ok, unused arguments
		switch event.Key  %process shortcut keys
		case 'leftarrow'
			scroll(f - 1);
		case 'rightarrow'
			scroll(f + 1);
		case 'home'
			scroll(1);
		case 'end'
			scroll(num_frames);
		end
	end
	
	%mouse handler
	function button_down(src, event)  %#ok, unused arguments
		set(src,'Units','norm')
		click_pos = get(src, 'CurrentPoint');
		if click_pos(2) <= 0.03  %only trigger if the scrollbar was clicked
			click = 1;
			on_click([],[]);
		end
	end

	function button_up(src, event)  %#ok, unused arguments
		click = 0;
	end

	function on_click(src, event)  %#ok, unused arguments
		if click == 0, return; end
		
		%get x-coordinate of click
		set(fig_handle, 'Units', 'normalized');
		click_point = get(fig_handle, 'CurrentPoint');
		set(fig_handle, 'Units', 'pixels');
		x = click_point(1);
		
		%get corresponding frame number
		new_f = floor(1 + x * num_frames);
		
		if new_f < 1 || new_f > num_frames, return; end  %outside valid range
		
		if new_f ~= f  %don't redraw if the frame is the same (to prevent delays)
			scroll(new_f);
		end
	end

	function scroll(new_f)
        if nargin == 1  %scroll to another position (new_f)
            if new_f < 1 || new_f > num_frames
                return
            end
            f = new_f;
        end
        
		%convert frame number to appropriate x-coordinate of scroll bar
		scroll_x = (f - 1) / num_frames;
		
		%move scroll bar to new position
		set(scroll_handle, 'XData', scroll_x + [0 1 1 0] * scroll_bar_width);
		
		%set to the right axes and call the custom redraw function
		set(fig_handle, 'CurrentAxes', axes_handle);
		redraw_func(f, ImStk);
		
		%used to be "drawnow", but when called rapidly and the CPU is busy
		%it didn't let Matlab process events properly (ie, close figure).
		pause(0.001)
	end
	
	function check_callback(a)
		assert(isempty(a) || isa(a, 'function_handle'), ...
			[upper(inputname(1)) ' must be a valid function handle.'])
    end

end

