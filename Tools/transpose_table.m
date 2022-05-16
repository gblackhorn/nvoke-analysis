function [tableVar_trans,varargout] = transpose_table(tableVar,varargin)
    % transpose a table var
    

    A = table2array(tableVar); % convert the table var to an array var.

    A_trans = A.';

    tableVar_trans = array2table(A_trans);

    tableVar_trans.Properties.VariableNames = tableVar.Properties.RowNames;
    tableVar_trans.Properties.RowNames = tableVar.Properties.VariableNames;
end

