% =========================================================================
%  scenario1.m
%  Scenario 1: Low / Medium / High SNR
%  =========================================================================
%  Setup
%  -----
%    n = 300 observations,  p = 1000 features  (use p=20 for quick tests)
%    true_p = 20 truly active features  (sparse signal)
%    Features: Gaussian with compound-symmetry correlation  rho = 0.5
%    Noise:    Gaussian;  sigma chosen to hit target SNR
%
%  Methods compared
%  ----------------
%    UniLASSO, UniMCP, UniSCAD   (via  unisparse with method='all')
%
%  Outputs
%  -------
%    One CSV per (method x SNR level x replication) written to  output/
%    File name format:
%      Output_scenario_<S>_methodname_<M>_n_<N>_p<P>_design_<D>_SNR_<L>_rho_<R>_rep<REP>.csv
% =========================================================================

clc;
clear;

% -------------------------------------------------------------------------
% 0.  Path setup
% -------------------------------------------------------------------------
script_dir = fileparts(mfilename('fullpath'));

addpath(fullfile(script_dir, 'supp_funs'));

out_dir = fullfile(script_dir, 'output');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% -------------------------------------------------------------------------
% 1.  Safety check for UniSparse toolbox
% -------------------------------------------------------------------------
if exist('unisparse', 'file') ~= 2
    error(['unisparse not found on the MATLAB path.\n', ...
           'Install / enable Unisparse.mltbx, then re-run this script.']);
end

% -------------------------------------------------------------------------
% 2.  Scenario meta-data
% -------------------------------------------------------------------------
SCENARIO_NUM = 1;
DESIGN_LABEL = 'gaussian';     % compound-symmetry Gaussian features

% -------------------------------------------------------------------------
% 3.  Simulation parameters  (edit here for full / test runs)
% -------------------------------------------------------------------------
n_obs       = 30;    % number of observations
p           = 20;     % number of features  (set to 1000 for the full study)
true_p      = 20;     % number of truly nonzero features
rho         = 0.5;    % pairwise feature correlation

n_reps      = 1;      % number of independent replications per condition
                      % (increase for Monte-Carlo averages, e.g. n_reps=100)

% Noise levels: target SNR  <1 → low,  ~1 → medium,  >2 → high
snr_labels  = {'low',  'medium', 'high'};
snr_targets = [0.5,    1.0,      2.5   ];

% UniSparse fitting options
lambda_grid = logspace(-4, 4, 10);   % coarse grid — expand for final results
nfolds      = 3;                      % CV folds   (use 5+ for final results)
a_scad      = 3.7;
gamma_mcp   = 3.0;
tol         = 1e-4;                   % |beta| threshold for "nonzero"

% =========================================================================
% 4.  Main loop
% =========================================================================
fprintf('\n=================================================================\n');
fprintf(' Scenario %d | n=%d | p=%d | true_p=%d | rho=%.2f\n', ...
        SCENARIO_NUM, n_obs, p, true_p, rho);
fprintf(' Methods: UniLASSO, UniMCP, UniSCAD\n');
fprintf('=================================================================\n');

% Storage struct (one entry per SNR level)
scenario_results = struct();

for i = 1:numel(snr_targets)

    target_snr = snr_targets(i);
    snr_label  = snr_labels{i};

    fprintf('\n--- SNR: %s  (target = %.2f) ---\n', upper(snr_label), target_snr);

    for rep = 1:n_reps

        % ----------------------------------------------------------------
        % 4a.  Set RNG seed deterministically per (condition, rep)
        % ----------------------------------------------------------------
        rng(SCENARIO_NUM * 10000 + i * 100 + rep);

        % ----------------------------------------------------------------
        % 4b.  Generate dataset
        % ----------------------------------------------------------------
        [X, y, beta0_true, beta_true, sigma_eps, snr_emp] = ...
            generate_scenario1_data(n_obs, p, true_p, rho, target_snr);

        fprintf('   rep %d/%d | empirical SNR = %.3f | sigma = %.4f\n', ...
                rep, n_reps, snr_emp, sigma_eps);

        % ----------------------------------------------------------------
        % 4c.  Fit all three penalised-regression methods in one call
        % ----------------------------------------------------------------
        fit = unisparse(X, y, lambda_grid, nfolds, 'all', ...
                        [], [], [], [], a_scad, gamma_mcp);

        % ----------------------------------------------------------------
        % 4d.  Compute metrics for every method
        % ----------------------------------------------------------------
        metrics_table = summarize_unisparse_methods( ...
                            fit, beta0_true, beta_true, X, y, tol);

        if rep == 1
            disp(metrics_table);      % print table for first rep only
        end

        % ----------------------------------------------------------------
        % 4e.  Save one CSV per (method x rep)
        % ----------------------------------------------------------------
        method_keys   = {'UNILASSO', 'UNIMCP', 'UNISCAD'};
        method_labels = {'UniLASSO', 'UniMCP', 'UniSCAD'};

        for k = 1:numel(method_keys)

            % One-row slice for this method
            row_idx     = strcmp(metrics_table.Method, method_labels{k});
            metrics_row = metrics_table(row_idx, :);

            if isempty(metrics_row)
                warning('scenario1:missingMethod', ...
                        'No row found for method %s — skipping CSV.', ...
                        method_labels{k});
                continue;
            end

            % Append replication-level provenance columns
            metrics_row.EmpiricalSNR = snr_emp;
            metrics_row.Sigma        = sigma_eps;
            metrics_row.Rep          = rep;

            save_scenario_csv( ...
                metrics_row, SCENARIO_NUM, method_labels{k}, ...
                n_obs, p, DESIGN_LABEL, snr_label, rho, rep, out_dir);
        end

        % ----------------------------------------------------------------
        % 4f.  Store results for in-workspace inspection
        % ----------------------------------------------------------------
        scenario_results(i).snr_label     = snr_label;
        scenario_results(i).snr_target    = target_snr;
        scenario_results(i).snr_empirical = snr_emp;
        scenario_results(i).sigma_eps     = sigma_eps;
        scenario_results(i).beta0_true    = beta0_true;
        scenario_results(i).beta_true     = beta_true;
        scenario_results(i).fit           = fit;
        scenario_results(i).metrics_table = metrics_table;

    end % rep loop
end % SNR loop

fprintf('\n=================================================================\n');
fprintf(' Done.  CSVs written to:  %s\n', out_dir);
fprintf(' In-workspace variable:   scenario_results\n');
fprintf('=================================================================\n');