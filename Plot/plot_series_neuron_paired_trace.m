function [varargout] = plot_series_neuron_paired_trace(NeuronGroup_data,varargin)
    % Plot all neuron traces in the NeuronGroup_data
    % Each entry contains events recording from the same ROI but in different trials

    % NeuronGroup_data: struct var containing 1 series data. Use data in plot_trace_data to plot 
    %       - fields: roi, ref, plot_trace_data, eventPropData
    
    % Defaults
    fig_row_num = 3; % number of rows (ROIs) in each figure
    plot_raw = true; % true/false.
    plot_norm = true; % true/false. plot the ref_trial normalized data
    plot_mean = true; % true/false. plot a mean trace on top of raw traces
    plot_std = true; % true/false. plot the std as a shade on top of raw traces. If this is true, "plot_mean" will be turn on automatically
    y_range = [-10 10];
    tickInt_time = 1; % interval of tick for timeInfo (x axis)
    save_path = '';
    series_name = 'SeriesData';
    fig_position = [0.1 0.1 0.85 0.85]; % [left bottom width height]
    FontSize = 18;
    FontWeight = 'bold';
    debug_mode = false; % true/false

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        if strcmpi('fig_row_num', varargin{ii})
            fig_row_num = varargin{ii+1};
        elseif strcmpi('plot_raw', varargin{ii})
            plot_raw = varargin{ii+1};
        elseif strcmpi('plot_norm', varargin{ii})
            plot_norm = varargin{ii+1};
        elseif strcmpi('plot_mean', varargin{ii})
          plot_mean = varargin{ii+1};
        elseif strcmpi('plot_std', varargin{ii})
            plot_std = varargin{ii+1};
        elseif strcmpi('y_range', varargin{ii})
            y_range = varargin{ii+1};
        elseif strcmpi('tickInt_time', varargin{ii})
            tickInt_time = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_path = varargin{ii+1}; % save figures to the specified location if this is not empty
        elseif strcmpi('series_name', varargin{ii})
            series_name = varargin{ii+1};
        elseif strcmpi('fig_position', varargin{ii})
            fig_position = varargin{ii+1};
        elseif strcmpi('FontSize', varargin{ii})
            FontSize = varargin{ii+1};
        elseif strcmpi('FontWeight', varargin{ii})
            FontWeight = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        end
    end

    %% main contents
    % Prepare to plot
    roi_num = numel(NeuronGroup_data);
    fig_num = ceil(roi_num/fig_row_num);
    trial_num = numel(NeuronGroup_data(1).plot_trace_data);
    ref_name = NeuronGroup_data(1).ref;
    if ~isempty(ref_name)
        ref_exist = true;
    else
        ref_exist = false;
        plot_norm = false;
    end

    if plot_norm % plot the ref_trial normalized data or not
        fig_col_num = trial_num+trial_num-1; % raw traces of all trials (trial_num) + norm traces of non-ref trial (trial_num-1)
    else
        fig_col_num = trial_num;
    end

    % Plot
    for fn = 1:fig_num
        fname = sprintf('%s-%d', series_name,fn);

        if debug_mode
            fprintf('plot_series_neuron_paired_trace: figure number %d/%d\n',fn,fig_num);
            if fn == 5;
                pause
            end
        end

        f(fn) = figure('Name', fname);
        set(gcf,'Units', 'normalized', 'Position', fig_position);
        tlo = tiledlayout(f(fn), fig_row_num, fig_col_num);

        if fn~=fig_num
            ROIs = [(fn-1)*fig_row_num+1:(fn-1)*fig_row_num+fig_row_num];
        else
            ROIs = [(fn-1)*fig_row_num+1:roi_num];
        end
        fig_roi_num = numel(ROIs);
        for frn = 1:fig_roi_num
            roi_idx = ROIs(frn);
            roi_name = NeuronGroup_data(roi_idx).roi;
            trace_data = NeuronGroup_data(roi_idx).plot_trace_data;

            if debug_mode
                fprintf('   figure roi number %d/%d\n',frn,fig_roi_num);
            end

            % plot raw traces from every trial
            for tn = 1:trial_num
                ax = nexttile(tlo);
                if ~isempty(trace_data(tn).raw_trace)
                    plot_trace(trace_data(tn).timeinfo, trace_data(tn).raw_trace, 'plotWhere', ax,...
                        'plot_combined_data', plot_mean,'plot_combined_data_shade',plot_std,...
                        'mean_trace', trace_data(tn).trace_mean, 'mean_trace_shade', trace_data(tn).trace_std,...
                        'plot_raw_races',plot_raw,'y_range', y_range,'tickInt_time',tickInt_time,...
                        'FontSize',FontSize,'FontWeight',FontWeight);
                    tiletitle = sprintf('%s-%s-raw', roi_name, trace_data(tn).spike_stim);
                    if ref_exist && tn==1
                        tiletitle = sprintf('%s (REF)', tiletitle);
                    end
                    title(tiletitle);
                end
            end

            % plot normalized trace (to ref data)
            if plot_norm
                for tn = 2:trial_num
                    ax = nexttile(tlo);
                    if ~isempty(trace_data(tn).raw_trace)
                        plot_trace(trace_data(tn).timeinfo, trace_data(tn).norm_trace, 'plotWhere', ax,...
                            'plot_combined_data', plot_mean,...
                            'mean_trace', trace_data(tn).norm_trace_mean, 'mean_trace_shade', trace_data(tn).norm_trace_std,...
                            'plot_raw_traces',plot_raw,'y_range', y_range,'tickInt_time',tickInt_time);
                        tiletitle = sprintf('%s-%s-NORMtoREF', roi_name, trace_data(tn).spike_stim);
                        title(tiletitle);
                    end
                end
            end
        end
        if ~isempty(save_path)
            savePlot(f(fn),'save_dir',save_path,'fname',fname);
        end
    end
end

