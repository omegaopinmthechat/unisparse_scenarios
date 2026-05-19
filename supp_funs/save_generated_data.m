function [xy_path, params_path] = save_generated_data(X, y, beta0_true, beta_true, ...
                                         sigma_eps, snr_empirical, ...
                                         scenario_num, n, p, true_p, ...
                                         design, snr_label, rho, rep, out_dir)
% SAVE_GENERATED_DATA  Save a generated dataset to output/generated_data/ as CSV.
%
%   Writes two CSV files:
%     *_XY.csv     — design matrix X and response y  (n rows)
%     *_params.csv — true coefficients + metadata    (1 row)
%
%   rho can be numeric (e.g. 0.5) or a string label (e.g. 'NA', '0')

% ------------------------------------------------------------------
% Sanitise tokens  (mirrors save_scenario_csv convention)
% ------------------------------------------------------------------
    clean = @(s) strrep(strrep(char(s), '.', 'p'), ' ', '_');

    if isnumeric(rho)
        rho_str = strrep(sprintf('%.2f', rho), '.', 'p');  % 0.50 -> 0p50
    else
        rho_str = char(rho);                               % 'NA', '0', etc.
    end

    base_name = sprintf('generated_data_scenario_%d_n_%d_p%d_design_%s_SNR_%s_rho_%s_rep%d', ...
                        scenario_num, n, p, ...
                        clean(design), clean(snr_label), rho_str, rep);

% ------------------------------------------------------------------
% Ensure output/generated_data/ exists
% ------------------------------------------------------------------
    gen_data_dir = fullfile(out_dir, 'generated_data');
    if ~exist(gen_data_dir, 'dir'), mkdir(gen_data_dir); end

% ------------------------------------------------------------------
% CSV 1: X and y  (n rows x p+1 columns)
% ------------------------------------------------------------------
    x_colnames = arrayfun(@(j) sprintf('X%d', j), 1:p, 'UniformOutput', false);
    XY_table   = array2table([X, y], 'VariableNames', [x_colnames, {'y'}]);

    xy_path = fullfile(gen_data_dir, [base_name, '_XY.csv']);
    writetable(XY_table, xy_path);
    fprintf('  Saved XY data:     %s\n', xy_path);

% ------------------------------------------------------------------
% CSV 2: true parameters + provenance  (1 row)
% ------------------------------------------------------------------
    beta_colnames = arrayfun(@(j) sprintf('beta%d', j), 1:p, 'UniformOutput', false);

    params_table = array2table( ...
        [beta0_true, beta_true(:)', sigma_eps, snr_empirical], ...
        'VariableNames', ['beta0', beta_colnames, {'sigma_eps', 'snr_empirical'}]);

    provenance = table(scenario_num, n, p, true_p, ...
                       string(design), string(snr_label), string(rho_str), rep, ...
                       'VariableNames', {'Scenario','n','p','true_p', ...
                                         'Design','SNR_level','rho','rep'});
    params_table = [provenance, params_table];

    params_path = fullfile(gen_data_dir, [base_name, '_params.csv']);
    writetable(params_table, params_path);
    fprintf('  Saved params data: %s\n', params_path);
end