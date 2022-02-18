function varargout = plotOGsegmentsInGroup (IOnVokeData, PREwin, POSTwin, varargin)
%plots averaged calcium traces in entire group aligned on OG segments

	% Defaults
	SavePlot = 0;
	SaveTo = pwd;

	% Options
	for ii = 1:2:(nargin-3)
		if strcmpi('SavePlot', varargin{ii})
			SavePlot = varargin{ii+1};
		elseif strcmpi('SaveTo', varargin{ii})
			SaveTo = varargin{ii+1};
        end
	end

	if SavePlot
		figdir = uigetdir(SaveTo,...
			    'Select a folder to save figures');
	end

	frameRate = getFrameRateForTrial(IOnVokeData(1, :));
	nTrials = getNtrialsFromROIdata(IOnVokeData);
	trialType = getTrialTypeFromROIdataStruct(IOnVokeData);
	OGdur = getOGdurFromTrialData(IOnVokeData(1, :));
	% fovInfo = get_fov_info(trialData);
	grandAverageSegments = [];
	f1 = figure;
	NCOLS = 2;
	NROWS = ceil(nTrials / NCOLS);

	PREwin = PREwin*frameRate;
	POSTwin = POSTwin*frameRate;


	for trial = 1:nTrials

		% debugging code
		% disp(['Trial number: ', num2str(trial)])
		% if trial == 11
		% 	pause
		% end

		% trial_name = IOnVokeData{trial, 1};
		subplot(NROWS, NCOLS, trial); hold on;
	   	MTS = plotOGsegmentsInTrial (IOnVokeData(trial, :), PREwin, POSTwin, gca);
	   	MTS = MTS(:, :) - MTS (PREwin-1, :); 
	    meanTraceSegments{trial} = MTS;
	    grandAverageSegments = [grandAverageSegments; mean(meanTraceSegments{trial}', 'omitnan')];
	end
	titleString1 = ['Mean traces in ', trialType, ' single trials'];
	figure(f1)
	sgtitle(titleString1)


	% xAx = [1:length(meanTraceSegments{1})];
	xAx = [1:size(meanTraceSegments{1},1)];
	xAx = xAx ./ frameRate;

	f2 = figure; hold on;
	plot (xAx,grandAverageSegments', 'b', 'HandleVisibility','off' );
	plot (xAx, mean(grandAverageSegments, 'omitnan'), 'r', 'LineWidth', 2);


	axp = get(gca);
	ylims = axp.YLim;
	rectPos = [frames2sec(PREwin, frameRate) ylims(1) frames2sec(OGdur, frameRate) ylims(2)-ylims(1)];
	rectangle(gca, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.2]);
	xlabel('sec');
	legend ({'Mean of all trials'});

	titleString2 = ['Mean traces in ' trialType ' all trials'];
	title (titleString2);


	% Save plots
	if SavePlot
		figfile1 = titleString1;
		figfile2 = titleString2;
		fig1_fullpath = fullfile(figdir, figfile1);
		fig2_fullpath = fullfile(figdir, figfile2);

		figure(f1)
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
		savefig(gcf, [fig1_fullpath, '.fig']);
		saveas(gcf, [fig1_fullpath, '.jpg']);
		saveas(gcf, [fig1_fullpath, '.svg']);

		figure(f2)
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
		savefig(gcf, [fig2_fullpath, '.fig']);
		saveas(gcf, [fig2_fullpath, '.jpg']);
		saveas(gcf, [fig2_fullpath, '.svg']);
	end

	varargout{1} = grandAverageSegments;
	if exist('figdir', 'var')
		varargout{2} = figdir;
	else
		varargout{2} = SaveTo;
	end
end