function csv_path = save_scenario2_csv(all_rows, scenario_num, method_name, ...
                                       n, p, design, rho, n_reps, out_dir)
% SAVE_SCENARIO_CSV  Write all SNR-level rows for one method to a single CSV.
%
%   csv_path = save_scenario_csv(all_rows, scenario_num, method_name,
%                                n, p, design, rho, n_reps, out_dir)
%
%   all_rows already contains SNR_level, SNR_target, EmpiricalSNR, Sigma,
%   and Rep columns (added by the caller).  This function prepends fixed
%   provenance columns and writes everything to one file.
%
%   File name:
%     Output_scenario_<S>_methodname_<M>_n_<N>_p<P>_design_<D>_SNR_all_rho_<R>_rep<REP>.csv
%
%   INPUTS
%     all_rows      Table with one row per (SNR level x rep) combination
%     scenario_num  integer  scenario identifier   (e.g. 1)
%     method_name   char     method label          (e.g. 'UniLASSO')
%     n             integer  number of observations
%     p             integer  number of features
%     design        char     design label          (e.g. 'gaussian')
%     rho           numeric  feature correlation   (e.g. 0.5)
%     n_reps        integer  total replications run
%     out_dir       char     output directory path
%
%   OUTPUT
%     csv_path   full path of the written CSV file

    % ------------------------------------------------------------------
    % Build filename  (SNR token = 'all'; rep token = total reps run)
    % ------------------------------------------------------------------
    if isnumeric(rho)
        rho_str = strrep(sprintf('%.2f', rho), '.', 'p');  % 0.50 -> 0p50
    else
        rho_str = char(rho);                               % e.g. 'NA'
    end
    clean = @(s) strrep(strrep(char(s), '.', 'p'), ' ', '_');

    fname = sprintf( ...
        'Output_scenario_%d_methodname_%s_n_%d_p%d_design_%s_SNR_all_rho_%s_rep%d.csv', ...
        scenario_num, clean(method_name), n, p, clean(design), rho_str, n_reps);

    % ------------------------------------------------------------------
    % Prepend fixed provenance columns
    % ------------------------------------------------------------------
    n_rows = height(all_rows);

    provenance = table( ...
        repmat(scenario_num,         n_rows, 1), ...
        repmat(string(method_name),  n_rows, 1), ...
        repmat(n,                    n_rows, 1), ...
        repmat(p,                    n_rows, 1), ...
        repmat(string(design),       n_rows, 1), ...
        repmat(string(rho),          n_rows, 1), ...
        'VariableNames', {'Scenario', 'MethodName', 'n', 'p', 'Design', 'rho'});

    % Drop 'Method' from all_rows to avoid duplication with 'MethodName'
    if ismember('Method', all_rows.Properties.VariableNames)
        all_rows = removevars(all_rows, 'Method');
    end

    out_table = [provenance, all_rows];

    % ------------------------------------------------------------------
    % Ensure output directory exists and write
    % ------------------------------------------------------------------
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    csv_path = fullfile(out_dir, fname);
    writetable(out_table, csv_path);

    fprintf('  Saved (%d rows): %s\n', n_rows, csv_path);
end