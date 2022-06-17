function [ttest_stat] = struct_field_paired_ttest(structVar,field1,field2)
    % Run paired ttest on contents in 2 different fields of a structure var
    % Content in each entry of field1/field2 must be double

    % structVar: a structure variable
    % field1: 'char' var. name of a field in structVar
    % field2: 'char' var. name of a field in structVar

    field1_val = [structVar.(field1)];
    field2_val = [structVar.(field2)];

    ttest_stat.n_num = numel(field1_val);

    ttest_stat.field1_name = field1;
    ttest_stat.field1_val = field1_val;
    ttest_stat.field1_val_mean = mean(field1_val);
    ttest_stat.field1_val_std = std(field1_val);
    ttest_stat.field1_val_ste = std(field1_val)/sqrt(ttest_stat.n_num);
    % ttest_stat.field1_n = numel(field1_val);

    ttest_stat.field2_name = field2;
    ttest_stat.field2_val = field2_val;
    ttest_stat.field2_val_mean = mean(field2_val);
    ttest_stat.field2_val_std = std(field2_val);
    ttest_stat.field2_val_ste = std(field2_val)/sqrt(ttest_stat.n_num);

    

    [ttest_stat.h,ttest_stat.p,ttest_stat.ci,ttest_stat.stats] = ttest(field1_val,field2_val);
end

