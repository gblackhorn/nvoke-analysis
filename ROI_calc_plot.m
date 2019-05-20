function [ ROI_table, varargout ] = ROI_calc_plot( ROI_table, draw )
% Format ROI_table and find out the duration of recording and number of ROIs
%   
%	ROI_calc_plot(ROI_table)
%	ROI_calc_plot(ROI_table, draw) - if draw is one, draw all ROIs value
%
%
%	INPUT
%	ROI_table: table varible containing time info (1st column) and ROI readouts (rest columns)
%				1st row has ROI name (C00, C01, C02, C03, ...)
%				2nd row has 'Time(s)/Cell Status' and many 'undecided'. currently usless
%	draw: if 1, plot all ROIs readout. if 0, don't plot
%
%
%	OUTPUT
%	[ ROI_table ...... ] - 
%			formated ROI_tabel is always outputed
% 	[ ROI_table recording_time ROI_num] 




narginchk(1,2); % check the number of inputs

% organize ROI data table. The first row containing strings should be deleted.
ROI_table.Properties.VariableNames{'Var1'} = 'Time'; % set first column varible name as Time

recording_time = table2array(ROI_table(end,1)); % use the last time point as the recording duration.
ROI_num = size(ROI_table, 2) - 1; % number of ROIs
 varargout{1} = recording_time;
 varargout{2} = ROI_num;

 if nargin == 2
 	if draw == 1
 		figure
 		stackedplot(ROI_table);
 	end
 end

end

