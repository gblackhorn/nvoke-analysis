function [DataStruct_new] = Replace_decon_raw_data(DataStruct,NewDataTbl)
%Replace the neuron calcium signal val in DataStruct with NewDataTbl

% DataStruct: a structure var. DataStruct = recdata_organized{n, 2}
% NewDataTbl: a table var. Output of function ConvertFijiTbl

	% Defaults

	%% Content
	% Get the time table from DataStruct.raw
	tbl_time = DataStruct.raw(:,1);

	% Creat a new table using tbl_time and NewDataTbl. Assign this tbl to both DataStruct.decon and DataStruct.raw
	tbl_TimeData = [tbl_time NewDataTbl];
	DataStruct.decon = tbl_TimeData;
	DataStruct.raw = tbl_TimeData;
	DataStruct_new = DataStruct;
end