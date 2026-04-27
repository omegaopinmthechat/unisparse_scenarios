% =========================================================================
%  scenario4.m
%  Scenario 4: Correlated design — Toeplitz  (fixed beta, sigma = 1)
%  =========================================================================
%  Setup  (paper: Scenario 2 — correlated design)
%  -----
%    X in R^{n x p}: Toeplitz covariance  Sigma_jk = rho^|j-k|, rho = 0.5
%                    columns standardised after sampling
%    Beta and noise IDENTICAL to Scenario 3:
%      beta = (2.5, -2.0, 1.8, -1.5, 1.2, 1.0, -0.9, 0.8, 0.7, -0.7, 0,...,0)
%      y = X*beta + eps,   eps ~ N_n(0, sigma^2*I_n),   sigma = 1
%
%  Toeplitz vs compound-symmetry (Scenario 1)
%  -------------------------------------------
%    Compound-symmetry: Cov(x_j, x_k) = rho for ALL j != k   (same for all pairs)
%    Toeplitz:          Cov(x_j, x_k) = rho^|j-k|             (decays with lag)
%    Toeplitz is more realistic: nearby features are more correlated
%    than distant ones.
%
%  Outputs
%  -------
%    One CSV per method (3 files), one row per replication:
%      Output_scenario_4_methodname_<M>_n_<N>_p<P>_design_toeplitz_SNR_fixed_rho_0p50_rep<REP>.csv
% =========================================================================

clc;
clear;

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'supp_funs'));

out_dir = fullfile(script_dir, 'output');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

if exist('unisparse', 'file') ~= 2
    error('unisparse not found on path. Install Unisparse.mltbx first.');
end

SCENARIO_NUM = 4;
DESIGN_LABEL = 'toeplitz';
SNR_LABEL    = 'fixed';
rho          = 0.5;    % Toeplitz decay parameter

n_obs     = 30;
p         = 20;   % set to 20 for quick testing
sigma_eps = 1;
n_reps    = 1;

% TRUE BETA — identical to Scenario 3 (only design X changes)
% First 10 entries nonzero, rest zero
beta_true       = zeros(p, 1);
beta_true(1:10) = [2.5; -2.0; 1.8; -1.5; 1.2; 1.0; -0.9; 0.8; 0.7; -0.7];

% UniSparse options
lambda_grid = logspace(-4, 4, 10);
nfolds      = 3;
a_scad      = 3.7;
gamma_mcp   = 3.0;
tol         = 1e-4;

method_keys   = {'UNILASSO', 'UNIMCP', 'UNISCAD'};
method_labels = {'UniLASSO', 'UniMCP', 'UniSCAD'};

fprintf('\n=================================================================\n');
fprintf(' Scenario %d | Toeplitz design | n=%d | p=%d | rho=%.2f | sigma=%.2f\n', ...
        SCENARIO_NUM, n_obs, p, rho, sigma_eps);
fprintf(' Sigma_jk = rho^|j-k|  (correlation decays with feature lag)\n');
fprintf(' beta(1:10) = (2.5,-2.0,1.8,-1.5,1.2,1.0,-0.9,0.8,0.7,-0.7)\n');
fprintf(' beta(11:p) = 0\n');
fprintf(' [Same beta and sigma as Scenario 3 — only X changes]\n');
fprintf('=================================================================\n');

scenario_results = struct();

for rep = 1:n_reps

    rng(SCENARIO_NUM * 10000 + rep);

    [X, y, beta0_true, ~, ~, snr_emp] = ...
        generate_scenario4_data(n_obs, p, beta_true, rho, sigma_eps);

    fprintf('\n rep %d/%d | empirical SNR = %.3f\n', rep, n_reps, snr_emp);

    fit = unisparse(X, y, lambda_grid, nfolds, 'all', ...
                    [], [], [], [], a_scad, gamma_mcp);

    metrics_table = summarize_unisparse_methods( ...
                        fit, beta0_true, beta_true, X, y, tol);

    if rep == 1, disp(metrics_table); end

    for k = 1:numel(method_keys)

        row_idx     = strcmp(metrics_table.Method, method_labels{k});
        metrics_row = metrics_table(row_idx, :);
        if isempty(metrics_row), continue; end

        metrics_row.EmpiricalSNR = snr_emp;
        metrics_row.Sigma        = sigma_eps;
        metrics_row.Rep          = rep;

        save_scenario_csv( ...
            metrics_row, SCENARIO_NUM, method_labels{k}, ...
            n_obs, p, DESIGN_LABEL, SNR_LABEL, rho, rep, out_dir);
    end

    scenario_results(rep).snr_empirical = snr_emp;
    scenario_results(rep).beta_true     = beta_true;
    scenario_results(rep).fit           = fit;
    scenario_results(rep).metrics_table = metrics_table;

end

fprintf(' Done.  CSVs written to:  %s\n', out_dir);