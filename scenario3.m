% =========================================================================
%  scenario3.m
%  Scenario 3: Independent design  (fixed beta, sigma = 1)
%  =========================================================================
%  Setup  (from paper Scenario 1 — independent design)
%  -----
%    X in R^{n x p}: i.i.d. N(0,1) entries, column-standardised
%    s0 = 10 nonzero coefficients in the FIRST TEN coordinates:
%      beta = (2.5, -2.0, 1.8, -1.5, 1.2, 1.0, -0.9, 0.8, 0.7, -0.7, 0,...,0)
%    y = X*beta + eps,   eps ~ N_n(0, sigma^2 * I_n),   sigma = 1
%
%  Key difference from Scenarios 1 & 2
%  -------------------------------------
%    - X columns are INDEPENDENT  (no compound-symmetry, no collinearity)
%    - beta is FIXED  (specific non-random values, not drawn from N(0,1))
%    - sigma is FIXED at 1  (no SNR sweep)
%    - No intercept  (beta0 = 0)
%
%  Methods compared
%  ----------------
%    UniLASSO, UniMCP, UniSCAD   (via  unisparse with method='all')
%
%  Outputs
%  -------
%    One CSV per method (3 files), one row per replication:
%      Output_scenario_3_methodname_<M>_n_<N>_p<P>_design_independent_SNR_fixed_rho_0_rep<REP>.csv
% =========================================================================

clc;
clear;

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'supp_funs'));

out_dir = fullfile(script_dir, 'output');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

if exist('unisparse', 'file') ~= 2
    error(['unisparse not found on the MATLAB path.\n', ...
           'Install / enable Unisparse.mltbx, then re-run this script.']);
end

SCENARIO_NUM = 3;
DESIGN_LABEL = 'independent';   % i.i.d. N(0,1) columns, no correlation
SNR_LABEL    = 'fixed';         % sigma fixed at 1, no SNR sweep
RHO_LABEL    = '0';             % features are independent (rho = 0)

n_obs      = 30;    % number of observations   (adjust as needed)
p          = 20;   % number of features       (paper uses high-dimensional)
sigma_eps  = 1;      % noise SD  (paper: sigma = 1)

n_reps     = 3;      % replications  (increase to e.g. 100 for Monte-Carlo)

% UniSparse fitting options
lambda_grid = logspace(-4, 4, 10);
nfolds      = 3;       % use 5+ for final results
a_scad      = 3.7;
gamma_mcp   = 3.0;
tol         = 1e-4;

method_keys   = {'UNILASSO', 'UNIMCP', 'UNISCAD'};
method_labels = {'UniLASSO', 'UniMCP', 'UniSCAD'};

fprintf(' Scenario %d | Independent design | n=%d | p=%d | sigma=%.2f\n', ...
        SCENARIO_NUM, n_obs, p, sigma_eps);
fprintf(' beta = (2.5,-2.0,1.8,-1.5,1.2,1.0,-0.9,0.8,0.7,-0.7, 0,...,0)\n');
fprintf(' X ~ i.i.d. N(0,1) columns, column-standardised\n');
fprintf(' Methods: UniLASSO, UniMCP, UniSCAD\n');

scenario_results = struct();

for rep = 1:n_reps

    rng(SCENARIO_NUM * 10000 + rep);

    [X, y, beta0_true, beta_true, ~, snr_emp] = ...
        generate_scenario3_data(n_obs, p, sigma_eps);
    % save the generated data
    save_generated_data(X, y, beta0_true, beta_true, sigma_eps, snr_emp, ...
        SCENARIO_NUM, n_obs, p, 10, DESIGN_LABEL, SNR_LABEL, RHO_LABEL, rep, out_dir);

    fprintf('\n rep %d/%d | empirical SNR = %.3f\n', rep, n_reps, snr_emp);

    fit = unisparse(X, y, lambda_grid, nfolds, 'all', ...
                    [], [], [], [], a_scad, gamma_mcp);

    metrics_table = summarize_unisparse_methods( ...
                        fit, beta0_true, beta_true, X, y, tol);

    if rep == 1
        disp(metrics_table);
    end

    for k = 1:numel(method_keys)

        row_idx     = strcmp(metrics_table.Method, method_labels{k});
        metrics_row = metrics_table(row_idx, :);

        if isempty(metrics_row)
            warning('scenario3:missingMethod', ...
                    'No row found for method %s — skipping CSV.', ...
                    method_labels{k});
            continue;
        end

        metrics_row.EmpiricalSNR = snr_emp;
        metrics_row.Sigma        = sigma_eps;
        metrics_row.Rep          = rep;

        save_scenario_csv( ...
            metrics_row, SCENARIO_NUM, method_labels{k}, ...
            n_obs, p, DESIGN_LABEL, SNR_LABEL, RHO_LABEL, rep, out_dir);
    end

    scenario_results(rep).snr_empirical = snr_emp;
    scenario_results(rep).sigma_eps     = sigma_eps;
    scenario_results(rep).beta0_true    = beta0_true;
    scenario_results(rep).beta_true     = beta_true;
    scenario_results(rep).fit           = fit;
    scenario_results(rep).metrics_table = metrics_table;

end % rep loop

fprintf(' Done.  CSVs written to:  %s\n', out_dir);