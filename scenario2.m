% =========================================================================
%  scenario2.m
%  Scenario 2: Counter-example  (fixed collinear design, fixed sigma)
%  =========================================================================
%  Setup  (as stated in the paper counter-example)
%  -----
%    n  = 100  observations
%    p  = 20   features
%    x1 ~ N(0,1)
%    x2  = x1 + N(0,1)          <- deliberately collinear with x1
%    x3, ..., xp ~ N(0,1)       <- noise features
%    beta = (1, -0.5, 0, ..., 0)  <- only first two coefficients nonzero
%    error SD = 0.5              <- fixed (no SNR sweep)
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
%  Outputs
%  -------
%    One CSV per method (3 files), one row per replication:
%      Output_scenario_2_methodname_<M>_n_100_p20_design_counterexample_SNR_fixed_rho_NA_rep<REP>.csv
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

% =========================================================================
% 4.  Replication loop
% =========================================================================
fprintf('\n=================================================================\n');
fprintf(' Scenario %d | Counter-example | n=%d | p=%d | sigma=%.2f\n', ...
        SCENARIO_NUM, n_obs, p, sigma_eps);
fprintf(' beta = (1, -0.5, 0, ..., 0)\n');
fprintf(' x1~N(0,1),  x2 = x1 + N(0,1),  x3..xp ~ N(0,1)\n');
fprintf(' Methods: UniLASSO, UniMCP, UniSCAD\n');
fprintf('=================================================================\n');

scenario_results = struct();

for rep = 1:n_reps

    % --------------------------------------------------------------------
    % 4a.  Deterministic seed per (scenario, rep)
    % --------------------------------------------------------------------
    rng(SCENARIO_NUM * 10000 + rep);

    % --------------------------------------------------------------------
    % 4b.  Generate dataset
    % --------------------------------------------------------------------
    [X, y, beta0_true, beta_true, ~, snr_emp] = ...
        generate_scenario2_data(n_obs, p, sigma_eps);

    save_generated_data(X, y, beta0_true, beta_true, sigma_eps, snr_emp, ...
        SCENARIO_NUM, n_obs, p, 2, DESIGN_LABEL, SNR_LABEL, RHO_LABEL, rep, out_dir);

    

    fprintf('\n rep %d/%d | empirical SNR = %.3f\n', rep, n_reps, snr_emp);

    % --------------------------------------------------------------------
    % 4c.  Fit UniLASSO, UniMCP, UniSCAD in one call
    % --------------------------------------------------------------------
    fit = unisparse(X, y, lambda_grid, nfolds, 'all', ...
                    [], [], [], [], a_scad, gamma_mcp);

    % --------------------------------------------------------------------
    % 4d.  Compute metrics for all methods
    % --------------------------------------------------------------------
    metrics_table = summarize_unisparse_methods( ...
                        fit, beta0_true, beta_true, X, y, tol);

    if rep == 1
        disp(metrics_table);
    end

    % --------------------------------------------------------------------
    % 4e.  Save one CSV per method  — same save_scenario_csv as scenario 1
    %      SNR_LABEL = 'fixed'  (no SNR sweep; sigma is constant)
    %      RHO_LABEL = 'NA'     (no compound-symmetry rho)
    % --------------------------------------------------------------------
    for k = 1:numel(method_keys)

        row_idx     = strcmp(metrics_table.Method, method_labels{k});
        metrics_row = metrics_table(row_idx, :);

        if isempty(metrics_row)
            warning('scenario2:missingMethod', ...
                    'No row found for method %s — skipping CSV.', ...
                    method_labels{k});
            continue;
        end

        % Append provenance columns
        metrics_row.EmpiricalSNR = snr_emp;
        metrics_row.Sigma        = sigma_eps;
        metrics_row.Rep          = rep;

        save_scenario_csv( ...
            metrics_row, SCENARIO_NUM, method_labels{k}, ...
            n_obs, p, DESIGN_LABEL, SNR_LABEL, RHO_LABEL, rep, out_dir);
    end

    % --------------------------------------------------------------------
    % 4f.  Store for in-workspace inspection
    % --------------------------------------------------------------------
    scenario_results(rep).snr_empirical = snr_emp;
    scenario_results(rep).sigma_eps     = sigma_eps;
    scenario_results(rep).beta0_true    = beta0_true;
    scenario_results(rep).beta_true     = beta_true;
    scenario_results(rep).fit           = fit;
    scenario_results(rep).metrics_table = metrics_table;

end % rep loop

fprintf('\n=================================================================\n');
fprintf(' Done.  CSVs written to:  %s\n', out_dir);
fprintf(' In-workspace variable:   scenario_results\n');
fprintf('=================================================================\n');