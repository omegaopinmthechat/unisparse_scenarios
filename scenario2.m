% =========================================================================
%  scenario2.m
%  Scenario 2: Counter-example  (fixed collinear design, fixed sigma)
%  =========================================================================
%  Setup  (as stated in the paper counter-example)
%  -----
%    n  = 100  observations
%    p  = 20   features
%    x1 ~ N(0,1)
%    x2  = x1 + N(0,1)          ← deliberately collinear with x1
%    x3, ..., xp ~ N(0,1)       ← noise features
%    beta = (1, -0.5, 0, ..., 0)  ← only first two coefficients nonzero
%    error SD = 0.5              ← fixed (no SNR sweep)
%
%  Key difference from Scenario 1
%  --------------------------------
%    - Beta is FIXED (not drawn from N(0,1))
%    - sigma is FIXED at 0.5 (not tuned to a target SNR)
%    - x1/x2 are specifically collinear (not compound-symmetry)
%    - No SNR loop — one fixed condition, run for n_reps replications
%
%  Methods compared
%  ----------------
%    UniLASSO, UniMCP, UniSCAD   (via  unisparse with method='all')
%
%  Output
%  ------
%    ONE CSV file (all methods, all reps):
%      Output_scenario_2_methodname_all_n_100_p20_design_counterexample_SNR_fixed_rho_NA_rep<NREPS>.csv
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
SCENARIO_NUM = 2;
DESIGN_LABEL = 'counterexample';   % collinear x1/x2 fixed-beta design
SNR_LABEL    = 'fixed';            % sigma is fixed, not SNR-targeted
RHO_LABEL    = 'NA';               % no single rho; structure is x2=x1+noise

% -------------------------------------------------------------------------
% 3.  Simulation parameters
% -------------------------------------------------------------------------
n_obs      = 100;    % observations  (paper: n = 100)
p          = 20;     % features      (paper: p = 20)
sigma_eps  = 0.5;    % noise SD      (paper: error SD = 0.5)

n_reps     = 1;      % replications  (increase to e.g. 100 for Monte-Carlo)

% UniSparse fitting options
lambda_grid = logspace(-4, 4, 10);
nfolds      = 3;       % use 5+ for final results
a_scad      = 3.7;
gamma_mcp   = 3.0;
tol         = 1e-4;

method_keys   = {'UNILASSO', 'UNIMCP', 'UNISCAD'};
method_labels = {'UniLASSO', 'UniMCP', 'UniSCAD'};
n_methods     = numel(method_labels);

% =========================================================================
% 4.  Single accumulator for ALL rows  (all methods x all reps)
% =========================================================================
all_rows = [];

fprintf('\n=================================================================\n');
fprintf(' Scenario %d | Counter-example | n=%d | p=%d | sigma=%.2f\n', ...
        SCENARIO_NUM, n_obs, p, sigma_eps);
fprintf(' beta = (1, -0.5, 0, ..., 0)\n');
fprintf(' x1~N(0,1),  x2 = x1 + N(0,1),  x3..xp ~ N(0,1)\n');
fprintf(' Methods: UniLASSO, UniMCP, UniSCAD\n');
fprintf('=================================================================\n');

% =========================================================================
% 5.  Replication loop
% =========================================================================
for rep = 1:n_reps

    % --------------------------------------------------------------------
    % 5a.  Deterministic seed per (scenario, rep)
    % --------------------------------------------------------------------
    rng(SCENARIO_NUM * 10000 + rep);

    % --------------------------------------------------------------------
    % 5b.  Generate dataset
    % --------------------------------------------------------------------
    [X, y, beta0_true, beta_true, ~, snr_emp] = ...
        generate_scenario2_data(n_obs, p, sigma_eps);

    fprintf('\n rep %d/%d | empirical SNR = %.3f\n', rep, n_reps, snr_emp);

    % --------------------------------------------------------------------
    % 5c.  Fit UniLASSO, UniMCP, UniSCAD in one call
    % --------------------------------------------------------------------
    fit = unisparse(X, y, lambda_grid, nfolds, 'all', ...
                    [], [], [], [], a_scad, gamma_mcp);

    % --------------------------------------------------------------------
    % 5d.  Compute metrics for all methods
    % --------------------------------------------------------------------
    metrics_table = summarize_unisparse_methods( ...
                        fit, beta0_true, beta_true, X, y, tol);

    if rep == 1
        disp(metrics_table);
    end

    % --------------------------------------------------------------------
    % 5e.  Accumulate rows  (one row per method per rep)
    % --------------------------------------------------------------------
    for k = 1:n_methods

        row_idx     = strcmp(metrics_table.Method, method_labels{k});
        metrics_row = metrics_table(row_idx, :);

        if isempty(metrics_row)
            warning('scenario2:missingMethod', ...
                    'No row for method %s — skipping.', method_labels{k});
            continue;
        end

        % Provenance columns specific to Scenario 2
        metrics_row.EmpiricalSNR = snr_emp;
        metrics_row.Sigma        = sigma_eps;
        metrics_row.Rep          = rep;

        if isempty(all_rows)
            all_rows = metrics_row;
        else
            all_rows = [all_rows; metrics_row]; %#ok<AGROW>
        end
    end

end % rep loop

% =========================================================================
% 6.  Write ONE CSV  (all methods + all reps)
% =========================================================================
fprintf('\n--- Saving CSV ---\n');

if isempty(all_rows)
    warning('scenario2:noRows', 'No rows collected — CSV not written.');
else
    save_scenario2_csv( ...
        all_rows, SCENARIO_NUM, 'all', ...
        n_obs, p, DESIGN_LABEL, RHO_LABEL, n_reps, out_dir);
end

fprintf(' Done.  CSV written to:  %s\n', out_dir);