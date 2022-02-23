function [roi_distance,varargout] = get_roi_distance(ref_coor,other_coor,varargin)
	% Calculate the distance between a reference roi and other rois (1 or multiple)

	% ref_coor: a single roi coordinate (1x2 vector)
	% other_coor: one or multiple coordinates (n x 2 array)

	% Defaults

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('traceType', varargin{ii})
	%         traceType = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	%     elseif strcmpi('timeInfo', varargin{ii})
	%         timeInfo = varargin{ii+1};
	%     end
	% end	


	%% Content
	dist_num = size(other_coor, 1); % number of distance pairs
	roi_distance = NaN(dist_num, 1);
	for dn = 1:dist_num
		roi_distance(dn) = sqrt((ref_coor(1)-other_coor(dn, 1))^2+(ref_coor(2)-other_coor(dn, 2))^2);
	end
	mean_dist = mean(roi_distance);
	std_dist = std(roi_distance);
	[min_dist, min_dist_idx] = min(roi_distance);
	[max_dist, max_dist_idx] = max(roi_distance);

	dist_par.mean = mean_dist;
	dist_par.std = std_dist;
	dist_par.min = min_dist;
	dist_par.min_idx = min_dist_idx;
	dist_par.max = max_dist;
	dist_par.max = max_dist_idx;
	varargout{1} = dist_par; 
end