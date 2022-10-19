function [gpio_ch_names,varargout] = gpio_ch_names(varargin)
    % This function returns a structure var containing the names of non-stimulation and stimulation channels used in nVoke2.
    %	It also returns the channel names used to replace the stimulation channels for better readibility
    % Note: Use this function to get channel names in other function for consistency.

    % if channel names are input as a cell array (varargin{1}), for example{'sync','EX-LED','GPIO-1','GPIO-2','GPIO-3'},
    %	the locations of non-stim and stim channels can be found and output as varargout{1}
    %	Use varargin{2} to choose 'gpio_ch_names.stim' or 'gpio_ch_names.stim_mod' to for finding the stimulation channels

    % Example: return all the channel names stored in this function, and the locations of stim and non-stim channels in the input cell array 
    %	[gpio_ch_names,gpio_ch_locs] = gpio_ch_names({'sync','EX-LED','GPIO-1','GPIO-2','GPIO-3'},1)

    gpio_ch_names.non_stim = {'sync','EX-LED'}; 
    % sync: sync signal between nVoke2 and other device
    gpio_ch_names.discard = {'GPIO-2'}; % Can be used to mark the channels neither for non-stim and stim

    gpio_ch_names.stim = {'OG-LED','GPIO-1','GPIO-3'}; % GPIO names from nVoke2
    gpio_ch_names.stim_mod = {'og','ap_GPIO-1','ap'}; % used to rename the gpio_ch_names.stim
    % gpio_ch_names.stim_mod = {'OG-LED','AP_GPIO-1','AP'}; % used to rename the gpio_ch_names.stim


    if nargin == 0 % only output the gpio_ch_names
    elseif nargin >= 1 && nargin <= 2 % Return the locations of non_stim and stim channels given in varargin{1} 
    	ch_names = varargin{1};
    	stim_name_type = 1;
    	if nargin == 2
    		stim_name_type = varargin{2};
    	end

    	if stim_name_type == 1
    		stim_names = gpio_ch_names.stim;
    	elseif stim_name_type == 2
    		stim_names = gpio_ch_names.stim_mod;
    	else
    		error('Function [gpio_ch_names]: the 2nd input must be 1 (stim) or 2 (stim_mod)')
    	end

    	TF_ch_non_stim = contains(ch_names,gpio_ch_names.non_stim,'IgnoreCase',true);
    	gpio_ch_locs.non_stim = find(TF_ch_non_stim);
        TF_ch_discard = contains(ch_names,gpio_ch_names.discard,'IgnoreCase',true);
        gpio_ch_locs.discard = find(TF_ch_discard);
    	TF_ch_stim = contains(ch_names,stim_names,'IgnoreCase',true);
    	gpio_ch_locs.stim = find(TF_ch_stim);
    	varargout{1} = gpio_ch_locs;
    else
    	error('Function [gpio_ch_names]: number of input must be less than 2 (containing 2)')
    end
