function [] = plot_trace_peak_rise(timeinfo,traceinfo,varargin)
    % plot traces, peaks (marked with "o") and rises (marked with ">") sharing
    % the same time info
    %   timeinfo: 1-col array
    %   traceinfo: 1 or multiple column array(s)
    %   varargin: peakinfo,riseinfo. Both are cell arrays. Each cell contains 1
    %   column of time information and 1 column of value information
    
    if nargin < 2
    	error('Not enough input. Minimum 2: timeinfo and traceinfo')
    elseif nargin == 2
    	% plot_mark = 0;
    	plot_mark_peak = 0;
    	plot_mark_rise = 0;
    	plot_mark_decay = 0;
    elseif nargin == 3
    	plot_mark_peak = 1;
    	peakinfo = varargin{1};
    elseif nargin == 4
        plot_mark_peak = 1;
    	plot_mark_rise = 1;
        peakinfo = varargin{1};
    	riseinfo = varargin{2};
    % elseif nargin == 5
    elseif nargin > 4
    	error('Too many input. Maximum 4')
    end

    color_trace = {'k', '#0072BD', '#7E2F8E'}; % color of traces
    color_mark = {'#000000', '#D95319'}; % color of marks for peaks and rise locations
    linewidth_mark = [1 2];
    rise_mark_shape = {'>', 'd'};

    num_trace = size(traceinfo, 2);
    if plot_mark_peak == 1
    	num_peakset = length(peakinfo);
    end
    if plot_mark_rise == 1
    	num_riseset = length(riseinfo);
    end
    trace_max = NaN(1, num_trace); % allocate ram. max values of each traces
    trace_min = NaN(1, num_trace); % allocate ram. min values of each traces
    
    hold on
    for tn = 1:num_trace % plot traces
    	plot(timeinfo, traceinfo(:, tn), 'Color', color_trace{tn})
    	trace_max(tn) = max(traceinfo(:, tn));
    	trace_min(tn) = min(traceinfo(:, tn));
    end
    for pn = 1:num_peakset % plot peak marks
    	plot(peakinfo{pn}(:, 1), peakinfo{pn}(:, 2), 'o',...
    		'Color', color_mark{pn}, 'linewidth', linewidth_mark(pn))
    end
    for rn = 1:num_riseset % plot rise marks
    	plot(riseinfo{rn}(:, 1), riseinfo{rn}(:, 2), rise_mark_shape{rn},...
    		'Color', color_mark{rn}, 'linewidth', linewidth_mark(rn))
    end

    ylim_max = max(trace_max)*1.1;
    ylim_min = min(trace_min) - abs(min(trace_min))*0.1;
    axis([0 max(timeinfo) ylim_min ylim_max]);
    hold off
end

