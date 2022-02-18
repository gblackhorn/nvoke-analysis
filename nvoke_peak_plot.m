function [peak_info_compilation] = nvoke_peak_plot(peak_info_compilation, plotsave, varargin)
	% Plot peak info from multiple peak_info_sheet
    % Select multiple peak_info_sheet output by nvoke_event_cal function. Tag them according to
    % stimulation, peak-category, etc. Plot peak info from all stimuli and category on same figures.
    % peak_info_compilation has the same format like peak_info_sheet. Either of them can be used in this fun 
    % plot: 0-no plot. 1-plot. 2-plot and save
    % varargin(1): 0-peaks are not grouped. 1-peaks are grouped according to category. 
    % 			   2-peaks are grouped according to stimuli
    %			   3-peaks are grouped according to both category and stimuli

    if plotsave == 2
    	global figfolder
    	if figfolder~=0
    	else
    		if ispc
    			figfolder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks\';
    		elseif isunix
    			figfolder = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/peaks/';
    		end
    		
    	end
    	figfolder = uigetdir(figfolder,...
    				['Select a folder to save figures. Trigger_filter-']);
    end

	peakStim_str = unique(peak_info_compilation.peakStim);
	peakCategory_str = unique(peak_info_compilation.peakCategory);

	peak_num_sum = size(peak_info_compilation, 1);
	peakStim_num = size(peakStim_str, 1);
	peakCategory_num = size(peakCategory_str, 1);
	disp(['Total peaks number: ', num2str(peak_num_sum)])
	disp(['Stimuli (', num2str(peakStim_num), '): '])
	disp(unique(peak_info_compilation.peakStim))
	disp(['Peak Category (', num2str(peakCategory_num), '): '])
	disp(unique(peak_info_compilation.peakCategory))


	groupstr_0 = '0: peaks are not grouped';
	groupstr_1 = '1: peaks are grouped according to peakCategory';
	groupstr_2 = '2: peaks are grouped according to peakStimuli';
	groupstr_3 = '3: peaks are grouped according to both peakCategory and peakStimuli';
	if length(varargin) > 0
		peak_info_group.group = varargin{1};
		if ~isnumeric(peak_info_group.group)
			disp('Please input a number (0 - 3) for the 3rd input')
			disp([groupstr_0, '\n', groupstr_1, '\n', groupstr_2, '\n', groupstr_3])
			return
		end
	elseif length(varargin) == 0
	    prompt_peakgroup_option = 'Do you want to group peaks? 0/1/2/3/4 [0]: ';
		input_str = input([groupstr_0, '\n', groupstr_1, '\n', groupstr_2, '\n', groupstr_3, '\n', prompt_peakgroup_option], 's');
		peak_info_group.group = str2num(input_str);
		if isempty(input_str)
			input_str = 0;
		elseif isempty(find(peak_info_group.group == [0:3]))
			disp('Please input 0 to 3 for peak group option')
			return
		end
	end

	if peak_info_group.group == 0
		stim_group = 0;
		cat_group = 0;
	elseif peak_info_group.group == 1
		stim_group = 0;
		cat_group = 1;
	elseif peak_info_group.group == 2
		stim_group = 1;
		cat_group = 0;
	elseif peak_info_group.group == 3
		stim_group = 1;
		cat_group = 1;
	end

	if stim_group == 1
		for sn = 1:peakStim_num
			stimgroup_row = find(strcmp(peakStim_str{sn}, peak_info_compilation.peakStim));
			peak_info_stim(sn).value = peak_info_compilation(stimgroup_row, :);
			peak_info_stim(sn).group = peakStim_str{sn}; 
			if cat_group == 1 % peak_info_group.group == 3
				for cn = 1:peakCategory_num
					gn = (sn-1)*peakCategory_num+cn; % peak group number
					catgroup_row = find(strcmp(peakCategory_str{cn}, peak_info_stim(sn).value.peakCategory));
					peak_info_group(gn).value = peak_info_stim(sn).value(catgroup_row, :);
					peak_info_group(gn).group = [peak_info_stim(sn).group, '-', peakCategory_str{cn}];
				end
			elseif cat_group == 0 % peak_info_group.group == 2
				gn = sn;
				peak_info_group(gn).value = peak_info_stim(sn).value;
				peak_info_group(gn).group = peak_info_stim(sn).group;
			end
		end
	elseif stim_group == 0
		if cat_group == 1 % peak_info_group.group == 1
			for cn = 1:peakCategory_num
				gn = cn;
				catgroup_row = find(strcmp(peakCategory_str{cn}, peak_info_compilation.peakCategory));
				peak_info_group(gn).value = peak_info_compilation(catgroup_row, :);
				peak_info_group(gn).group = peakCategory_str{cn};
			end
		elseif cat_group == 0 % peak_info_group.group == 0
			peak_info_group.value = peak_info_compilation;
			peak_info_group.group = 'All';
		end
	end

	% plot
	close all
	peakGroup_num = size(peak_info_group, 2); 
	max_riseT = 0;
	max_peakAmp = 0;
	max_peakSlope = 0;
	max_peakSlope_normhp = 0;
	max_peakAmpzscore = 0;
	max_PeakAmpNormHp = 0;
	for gn = 1:peakGroup_num
		peak_info_sheet = peak_info_group(gn).value;
		total_peak_num = size(peak_info_sheet, 1);
		

		if size(peak_info_sheet.riseDuration, 1) <= 2
			disp('Less then 2 peaks found in this category. Not enough for plot')
		else
			if gn == 1
				legendstr = {peak_info_group(gn).group};
			else
				if exist('legendstr', 'var')
					legendstr = [legendstr peak_info_group(gn).group];
				else
					legendstr = {peak_info_group(gn).group};
				end
			end
			
			if nargin >= 2
				if plotsave == 1 || 2 
					% calculate proper bin number according to The Freedman-Diaconis rule
					% h=2×IQR×n^(−1/3), bin+number = (max−min)/h
					iqr_rise = iqr(peak_info_sheet{:, 'riseDuration'});
					bin_width_rise = 2*iqr_rise*total_peak_num^(1/3);
					bin_num_rise = (max(peak_info_sheet{:, 'riseDuration'})-min(peak_info_sheet{:, 'riseDuration'}))/bin_width_rise;
					bin_num_rise = ceil(bin_num_rise);

					iqr_decay = iqr(peak_info_sheet{:, 'decayDuration'});
					bin_width_decay = 2*iqr_decay*total_peak_num^(1/3);
					bin_num_decay = (max(peak_info_sheet{:, 'decayDuration'})-min(peak_info_sheet{:, 'decayDuration'}))/bin_width_decay;
					bin_num_decay = ceil(bin_num_decay);

					iqr_transient = iqr(peak_info_sheet{:, 'wholeDuration'});
					bin_width_transient = 2*iqr_transient*total_peak_num^(1/3);
					bin_num_transient = (max(peak_info_sheet{:, 'wholeDuration'})-min(peak_info_sheet{:, 'wholeDuration'}))/bin_width_transient;
					bin_num_transient = ceil(bin_num_transient);

					iqr_peakmag = iqr(peak_info_sheet{:, 'peakAmp'});
					bin_width_peakmag = 2*iqr_peakmag*total_peak_num^(1/3);
					bin_num_peakmag = (max(peak_info_sheet{:, 'peakAmp'})-min(peak_info_sheet{:, 'peakAmp'}))/bin_width_peakmag;
					bin_num_peakmag = ceil(bin_num_peakmag);

					iqr_peakslope = iqr(peak_info_sheet{:, 'peakSlope'});
					bin_width_peakslope = 2*iqr_peakslope*total_peak_num^(1/3);
					bin_num_peakslope = (max(peak_info_sheet{:, 'peakSlope'})-min(peak_info_sheet{:, 'peakSlope'}))/bin_width_peakslope;
					bin_num_peakslope = ceil(bin_num_peakslope);

					% use the self-decided bin number
					bin_num_rise = 40;
					bin_num_decay = 40;
					bin_num_transient = 40;
					bin_num_peakmag = 40;
					bin_num_peakslope = 200;
					bin_num_peakslope_normhp = 200;
					bin_num_peak_zscore = 40;
					bin_num_peak_norm_hp = 40;
					bin_num_rise_rela2stim = 40;

					if length(peakStim_str) == 1
						str_fn_part = [peakStim_str{:}, '-', peak_info_group(gn).group];
					elseif length(peakCategory_str) == 1
						str_fn_part = [peak_info_group(gn).group, '-', peakCategory_str{:}];
					else
						str_fn_part = peak_info_group(gn).group;
					end
					
					h = figure(1);
					set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
					subplot(2, 3, 1);
					
					histogram(peak_info_sheet{:, 'riseDuration'}, bin_num_rise); % plot rise duration
					title('peak rise duration', 'FontSize', 16);
					subplot(2, 3, 2);
					histogram(peak_info_sheet{:, 'decayDuration'}, bin_num_decay); % plot decay duration
					title('Peak decay duration', 'FontSize', 16);
					% subplot(2, 3, 3);
					% histogram(peak_info_sheet{:, 7}, bin_num_transient); % plot transient duration
					% title('Calcium transient duration', 'FontSize', 16); 
					subplot(2, 3, 3);
					histogram(peak_info_sheet{:, 'peakAmp'}, bin_num_peakmag); % peak_mag
					title('Peak amp', 'FontSize', 16);
					subplot(2, 3, 4);
					histogram(peak_info_sheet{:, 'peakSlope_normhp'}, bin_num_peakslope_normhp); % peak_slope
					title('Peak slope normhp', 'FontSize', 16);
					% subplot(2, 3, 5);
					% histogram(peak_info_sheet{:, 'peakZscore'}, bin_num_peak_zscore); % peak zscore
					% title('Peak zscore', 'FontSize', 16);
					subplot(2, 3, 5);
					histogram(peak_info_sheet{:, 'peakNormHP'}, bin_num_peak_norm_hp); % peak normalized to std of highpassed data
					title('Peak norm HighpassStd', 'FontSize', 16);
					subplot(2, 3, 6);
					histogram(peak_info_sheet{:, 'riseTimeRelative2Stim'}, bin_num_rise_rela2stim); % peak normalized to std of highpassed data
					title('Time diff - stimulation start and rise of peak', 'FontSize', 16);
					sgtitle(['nVoke analysis - Histograms ', str_fn_part], 'Interpreter', 'none');

					cor = figure(2);
					set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
					subplot(2, 3, 1);
					corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakAmp], 'varNames', {'RiseT', 'PeakM'});
					% subplot(2, 3, 2);
					% corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakZscore], 'varNames', {'RiseT', 'PeakMzscore'});
					% subplot(2, 3, 3);
					% corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP], 'varNames', {'RiseT', 'PeakMnorm'});
					subplot(2, 3, 2);
					corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP], 'varNames', {'RiseT', 'PMnorm'});
					subplot(2, 3, 3);
					corrplot([peak_info_sheet.peakAmp, peak_info_sheet.peakSlope], 'varNames', {'PeakM', 'Slope'});
					% subplot(2, 3, 5);
					% corrplot([peak_info_sheet.peakZscore, peak_info_sheet.peakSlope], 'varNames', {'PeakMzscore', 'Slope'});
					subplot(2, 3, 4);
					corrplot([peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope], 'varNames', {'PeakMnorm', 'Slope'});
					% scatter3(peak_info_sheet(:, 5), peak_info_sheet(:, 8), peak_info_sheet(:, 9))
					% % set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
					% xlim([0 150])
					% ylim([0 30])
					% zlim([0 40])
					% xlabel('RiseT')
					% ylabel('PeakM')
					% zlabel('Slope')
					sgtitle(['nVoke analysis - corralations ', str_fn_part], 'Interpreter', 'none');
					% hold on

					% cor2 = figure(3);
					% set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
					% subplot(2, 3, 1);
					% corrplot(peak_info_sheet(:, [5, 8]), 'varNames', {'RiseT', 'PeakM'});
					% subplot(2, 3, 2);
					% corrplot(peak_info_sheet(:, [5, 10]), 'varNames', {'RiseT', 'PeakMzscore'});
					% subplot(2, 3, 3);
					% corrplot(peak_info_sheet(:, [5, 11]), 'varNames', {'RiseT', 'PeakMnorm'});
					% subplot(2, 3, 4);
					% corrplot(peak_info_sheet(:, [8, 9]), 'varNames', {'PeakM', 'Slope'});
					% subplot(2, 3, 5);
					% corrplot(peak_info_sheet(:, [10, 9]), 'varNames', {'PeakMzscore', 'Slope'});
					% subplot(2, 3, 6);
					% corrplot(peak_info_sheet(:, [11, 9]), 'varNames', {'PeakMnorm', 'Slope'});
					% % scatter3(peak_info_sheet(:, 5), peak_info_sheet(:, 8), peak_info_sheet(:, 9))
					% % % set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
					% % xlim([0 150])
					% % ylim([0 30])
					% % zlim([0 40])
					% % xlabel('RiseT')
					% % ylabel('PeakM')
					% % zlabel('Slope')
					% sgtitle(['nVoke event analysis - corralations PeakMzscore ', peak_info_group.group], 'Interpreter', 'none');

					if max_riseT < max(peak_info_sheet.riseDuration);
						max_riseT = max(peak_info_sheet.riseDuration);
					end
					if max_peakAmp < max(peak_info_sheet.peakAmp);
						max_peakAmp = max(peak_info_sheet.peakAmp);
					end
					if max_peakSlope < max(peak_info_sheet.peakSlope);
						max_peakSlope = max(peak_info_sheet.peakSlope);
					end
					if max_peakSlope_normhp < max(peak_info_sheet.peakSlope);
						max_peakSlope_normhp = max(peak_info_sheet.peakSlope);
					end
					if max_peakAmpzscore < max(peak_info_sheet.riseDuration);
						max_peakAmpzscore = max(peak_info_sheet.riseDuration);
					end
					if max_PeakAmpNormHp < max(peak_info_sheet.peakNormHP);
						max_PeakAmpNormHp = max(peak_info_sheet.peakNormHP);
					end

					s = figure(4);
					scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakAmp, peak_info_sheet.peakSlope, 'filled')
					% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
					xlim([0 (max_riseT+0.5)])
					ylim([0 (max_peakAmp+0.1)])
					zlim([0 (max_peakSlope+0.05)])
					xlabel('RiseT', 'FontSize', 16)
					ylabel('PeakAmp', 'FontSize', 16)
					zlabel('Slope', 'FontSize', 16)
					% if gn == peakGroup_num
					% 	legend(gca, legendstr);
					% end
					legend(gca, legendstr);
					title(['nVoke analysis - scatter ', str_fn_part], 'FontSize', 16)
					hold on

					s2 = figure(5);
					scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakZscore, peak_info_sheet.peakSlope, 'filled')
					% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
					xlim([0 (max_riseT+0.5)])
					ylim([0 (max_peakAmpzscore+1)])
					zlim([0 (max_peakSlope+0.05)])
					xlabel('RiseT', 'FontSize', 16)
					ylabel('PeakAmpzscore', 'FontSize', 16)
					zlabel('Slope', 'FontSize', 16)
					% if gn == peakGroup_num
					% 	legend(gca, legendstr);
					% end
					legend(gca, legendstr);
					title(['nVoke analysis - scatter ', str_fn_part], 'FontSize', 16)
					hold on

					s3 = figure(6);
					scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope, 'filled')
					% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
					xlim([0 (max_riseT+0.5)])
					ylim([0 (max_PeakAmpNormHp+5)])
					zlim([0 (max_peakSlope+0.05)])
					xlabel('RiseT', 'FontSize', 16)
					ylabel('PeakAmpNormHp', 'FontSize', 16)
					zlabel('Slope', 'FontSize', 16)
					% if gn == peakGroup_num
					% 	legend(gca, legendstr);
					% end
					legend(gca, legendstr);
					title(['nVoke analysis - scatter ', str_fn_part], 'FontSize', 16)
					hold on

					s4 = figure(7);
					scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope_normhp, 'filled')
					% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
					xlim([0 (max_riseT+0.5)])
					ylim([0 (max_PeakAmpNormHp+5)])
					zlim([0 (max_peakSlope_normhp+0.05)])
					xlabel('RiseT', 'FontSize', 16)
					ylabel('PeakAmpNormHp', 'FontSize', 16)
					zlabel('SlopeNormhp', 'FontSize', 16)
					title(['nVoke analysis - scatter ', str_fn_part], 'FontSize', 16)
					legend(gca, legendstr);
					title(['nVoke analysis - scatter ', str_fn_part], 'FontSize', 16)
					hold on

					% if triggeredPeak_filter == 0
					% 	In_peak_str = ['In-Peak (n=', num2str(peak_fq_numIn), ')'];
					% 	Out_peak_str = ['Out-Peak (n=', num2str(peak_fq_numOut), ')'];
					% 	peak_cat = categorical({In_peak_str, Out_peak_str});
					% 	peak_fq_plot = [peak_fq_in*100 peak_fq_out*100];
					% 	s4 = figure(7);
					% 	bar(peak_cat, peak_fq_plot)
					% 	ylabel('peak_frequency x 100', 'FontSize', 16)
					% end


					if plotsave == 2 && ~isempty(figfolder)
						if length(peakStim_str) == 1
							str_fn_part = [peakStim_str{:}, '_', peak_info_group(gn).group];
						elseif length(peakCategory_str) == 1
							str_fn_part = [peak_info_group(gn).group, '_', peakCategory_str{:}];
						else
							str_fn_part = peak_info_group(gn).group;
						end
						disp(['Example of saved file name: ', datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part,' stimGroup', num2str(stim_group), ' catGroup', num2str(cat_group)])
						disp(['str_fn_part: ', str_fn_part])
						% prompt_save_with_specificStr = 'Do you want to keep "str_fn_part" shown above for the names of saved file? y/n [y]:';
						% str_save_with_specificStr = input(prompt_save_with_specificStr, 's');
						% if isempty(str_save_with_specificStr)
						% 	str_save_with_specificStr = 'y';
						% end
						% if str_save_with_specificStr ~= 'y'
						% 	str_fn_part = input('add stim, peak_category and/or something else to the file names: ', 's');
						% end

						figfile_histo = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part, ' nVoke - Histograms'];
						figfile_corr = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part, ' nVoke - corralations'];
						figfile_scatter = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part, ' nVoke - scatter'];
						% figfile_corr2 = [peak_info_group.group, ' nVoke - corralations2'];
						figfile_scatter2 = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part, ' nVoke - scatter2'];
						figfile_scatter3 = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part, ' nVoke - scatter3'];
						figfile_scatter4 = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn_part, ' nVoke - scatter4'];
						% figfile_fqbar = [peak_info_group.group, 'nVoke - peak_fq'];

						figfullpath_histo = fullfile(figfolder,figfile_histo);
						figfullpath_corr = fullfile(figfolder,figfile_corr);
						figfullpath_scatter = fullfile(figfolder,figfile_scatter);
						% figfullpath_corr2 = fullfile(figfolder,figfile_corr2);
						figfullpath_scatter2 = fullfile(figfolder,figfile_scatter2);
						figfullpath_scatter3 = fullfile(figfolder,figfile_scatter3);
						figfullpath_scatter4 = fullfile(figfolder,figfile_scatter4);
						% figfullpath_fqbar = fullfile(figfolder, figfile_fqbar);

						savefig(h, figfullpath_histo);
						savefig(cor, figfullpath_corr);

						saveas(h, figfullpath_histo,'jpg');
						saveas(cor, figfullpath_corr,'jpg');

						saveas(h, figfullpath_histo,'svg');
						saveas(cor, figfullpath_corr,'svg');

						saveas(h, figfullpath_histo,'fig');
						saveas(cor, figfullpath_corr,'fig');

						% if gn == peakGroup_num
						% 	saveas(s, figfullpath_scatter,'jpg');
						% 	% saveas(cor2, figfullpath_corr2,'jpg');
						% 	saveas(s2, figfullpath_scatter2,'jpg');
						% 	saveas(s3, figfullpath_scatter3,'jpg');
						% 	saveas(s, figfullpath_scatter,'svg');
						% 	% saveas(cor2, figfullpath_corr2,'svg');
						% 	saveas(s2, figfullpath_scatter2,'svg');
						% 	saveas(s3, figfullpath_scatter3,'svg');
						% 	saveas(s, figfullpath_scatter,'fig');
						% 	% saveas(cor2, figfullpath_corr2,'fig');
						% 	saveas(s2, figfullpath_scatter2,'fig');
						% 	saveas(s3, figfullpath_scatter3,'fig');
						% end

						% if triggeredPeak_filter == 0
						% 	savefig(s4, figfullpath_fqbar);
						% 	saveas(s4, figfullpath_fqbar,'jpg');
						% 	saveas(s4, figfullpath_fqbar,'fig');
						% end
					end

				end
			end
		end
	end
	if plotsave == 2 && ~isempty(figfolder)
		saveas(s, figfullpath_scatter,'jpg');
		% saveas(cor2, figfullpath_corr2,'jpg');
		saveas(s2, figfullpath_scatter2,'jpg');
		saveas(s3, figfullpath_scatter3,'jpg');
		saveas(s4, figfullpath_scatter4,'jpg');
		saveas(s, figfullpath_scatter,'svg');
		% saveas(cor2, figfullpath_corr2,'svg');
		saveas(s2, figfullpath_scatter2,'svg');
		saveas(s3, figfullpath_scatter3,'svg');
		saveas(s4, figfullpath_scatter4,'svg');
		saveas(s, figfullpath_scatter,'fig');
		% saveas(cor2, figfullpath_corr2,'fig');
		saveas(s2, figfullpath_scatter2,'fig');
		saveas(s3, figfullpath_scatter3,'fig');
		saveas(s4, figfullpath_scatter4,'fig');
	end
end

