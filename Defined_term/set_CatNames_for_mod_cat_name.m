function [cat_setting,varargout] = set_CatNames_for_mod_cat_name(CatType,varargin)
    % Return the cat_setting used by func [mod_cat_name] to modify contents in struct var (eventProp_all)
    % "cat": category. mod_cat_name was originally wrote to modify category name. 
    %   Actually, mod_cat_name can be used on any structure field containing strings

    % CatType: 
    %   - 'stimulation'
    %   - 'event'
    
    % Defaults

    % % Optionals for inputs
    % for ii = 1:2:(nargin-1)
    % 	if strcmpi('entry', varargin{ii})
    % 		entry = varargin{ii+1};
    % 	elseif strcmpi('modify_stim_name', varargin{ii})
    % 		modify_stim_name = varargin{ii+1};
    % 	% elseif strcmpi('keep_colNames', varargin{ii})
    % 	% 	keep_colNames = varargin{ii+1};
    %  %    elseif strcmpi('RowNameField', varargin{ii})
    %  %        RowNameField = varargin{ii+1};
    %     end
    % end

    %% main contents
    switch CatType
    case 'stimulation'
        cat_setting.cat_type = 'stim_name';
        cat_setting.cat_names = {'og', 'ap', 'og-ap'};
        cat_setting.cat_merge = {{'OG-LED-5s'}, {'GPIO-1-1s'}, {'OG-LED-5s GPIO-1-1s'}};
    case 'event'
        cat_setting.cat_type = 'peak_category'; % 'fovID', 'peak_category'
        cat_setting.cat_names = {'spon', 'trig', 'trig-AP', 'opto-delay', 'rebound'}; % new category names
        cat_num = numel(cat_setting.cat_names);
        cat_setting.cat_merge = cell(cat_num, 1); % each cell contains old categories which will be grouped together
        cat_setting.cat_merge{1} = {'noStim', 'beforeStim', 'interval',...
            'beforeStim-beforeStim', 'interval-interval'}; % spon
        cat_setting.cat_merge{2} = {'trigger', 'trigger-beforeStim', 'trigger-interval'}; % trig
        cat_setting.cat_merge{3} = {'delay-trigger'}; % trig-AP
        cat_setting.cat_merge{4} = {'delay', 'delay-rebound', 'delay-interval', 'delay-beforeStim'}; % delay. 'delay-delay', 
        cat_setting.cat_merge{5} = {'rebound', 'rebound-interval'}; % rebound
    end
        
end

