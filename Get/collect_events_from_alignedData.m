function [ca_events,varargout] = collect_events_from_alignedData(alignedData,varargin)
    % Return a structure var containing all events from trial(s) of alignedData
    % Use func [collect_event_prop] and [mod_cat_name]

    % alignedData: structure var containing multiple seriese of trials (Same FOV, same ROI set)
    
    % Defaults
    entry = 'event'; % entry of output, ca_events. 'event'/'roi' . If 'roi', calculate the means for each roi  
    modify_stim_name = true; % true/false. Change the stimulation name, 
                                % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('entry', varargin{ii})
    		entry = varargin{ii+1};
    	elseif strcmpi('modify_stim_name', varargin{ii})
    		modify_stim_name = varargin{ii+1};
    	% elseif strcmpi('keep_colNames', varargin{ii})
    	% 	keep_colNames = varargin{ii+1};
     %    elseif strcmpi('RowNameField', varargin{ii})
     %        RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    [ca_events] = collect_event_prop(alignedData, 'style', entry); % only use 'event' for 'style'

    % modify the stimulation name in ca_events
    if modify_stim_name
        % cat_setting.cat_type = 'stim_name';
        % cat_setting.cat_names = {'og', 'ap', 'og-ap'};
        % cat_setting.cat_merge = {{'OG-LED-5s'}, {'GPIO-1-1s'}, {'OG-LED-5s GPIO-1-1s'}};

        [cat_setting] = set_CatNames_for_mod_cat_name('stimulation'); % Get the settings to modify the stimulation names in ca_events 
        [ca_events] = mod_cat_name(ca_events,...
            'cat_setting',cat_setting,'dis_extra', false,'stimType',false);
    end
end

