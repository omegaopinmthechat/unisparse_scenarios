function csv_path = save_scenario_csv(metrics_row, scenario_num, method_name, ...
                                       n, p, design, snr_label, rho, rep, out_dir)
% SAVE_SCENARIO_CSV  Write a single-row metrics table to a named CSV file.
%
%   csv_path = save_scenario_csv(metrics_row, scenario_num, method_name,
%                                n, p, design, snr_label, rho, rep, out_dir)
%
%   The file is placed in out_dir with the naming convention:
%     Output_scenario_<S>_methodname_<M>_n_<N>_p<P>_design_<D>_SNR_<L>_rho_<R>_rep<REP>.csv
%
%   INPUTS
%     metrics_row   1-row MATLAB table (one row from summarize_unisparse_methods)
%     scenario_num  integer  scenario identifier  (e.g. 1)
%     method_name   char     method label         (e.g. 'UniLASSO')
%     n             integer  number of observations
%     p             integer  number of features
%     design        char     design label         (e.g. 'gaussian')
%     snr_label     char     SNR level label      (e.g. 'low')
%     rho           numeric  feature correlation  (e.g. 0.5)
%     rep           integer  replication index    (e.g. 1)
%     out_dir       char     output directory path
%
%   OUTPUT
%     csv_path  full path of the written CSV file

    % ------------------------------------------------------------------
    % Sanitise string tokens so they are safe in a filename
    % ------------------------------------------------------------------
    clean = @(s) strrep(strrep(char(s), '.', 'p'), ' ', '_');

    rho_str = strrep(sprintf('%.2f', rho), '.', 'p');  % e.g. 0.50 -> 0p50

    fname = sprintf('Output_scenario_%d_methodname_%s_n_%d_p%d_design_%s_SNR_%s_rho_%s_rep%d.csv', ...
                    scenario_num, ...
                    clean(method_name), ...
                    n, p, ...
                    clean(design), ...
                    clean(snr_label), ...
                    rho_str, ...
                    rep);

    % ------------------------------------------------------------------
    % Add provenance columns so the CSV is self-describing
    % ------------------------------------------------------------------
    n_rows = height(metrics_row);

    provenance = table( ...
        repmat(scenario_num,  n_rows, 1), ...
        repmat(string(method_name),  n_rows, 1), ...
        repmat(n,             n_rows, 1), ...
        repmat(p,             n_rows, 1), ...
        repmat(string(design), n_rows, 1), ...
        repmat(string(snr_label), n_rows, 1), ...
        repmat(rho,           n_rows, 1), ...
        repmat(rep,           n_rows, 1), ...
        'VariableNames', {'Scenario', 'MethodName', 'n', 'p', ...
                          'Design', 'SNR_level', 'rho', 'rep'});

    % Drop the Method column from metrics_row to avoid duplication
    drop_cols = {'Method'};
    for c = drop_cols
        if ismember(c{1}, metrics_row.Properties.VariableNames)
            metrics_row = removevars(metrics_row, c{1});
        end
    end

    out_row = [provenance, metrics_row];

    % ------------------------------------------------------------------
    % Ensure output directory exists and write CSV
    % ------------------------------------------------------------------
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    csv_path = fullfile(out_dir, fname);
    writetable(out_row, csv_path);

    fprintf('  Saved: %s\n', csv_path);
end