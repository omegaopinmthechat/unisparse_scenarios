function [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
        generate_scenario2_data(n, p, sigma_eps)
% GENERATE_SCENARIO2_DATA  Counter-example dataset (Scenario 2).
%
%   [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
%       generate_scenario2_data(n, p, sigma_eps)
%
%   Fixed design as described in the paper counter-example:
%     x1  ~ N(0, 1)
%     x2   = x1 + N(0, 1)        ← correlated with x1, not independent
%     x3, ..., xp ~ N(0, 1)      ← independent noise features
%     beta = (1, -0.5, 0, ..., 0)  ← only first two coefficients nonzero
%     y    = beta0 + X*beta + eps,  eps ~ N(0, sigma_eps^2)
%
%   INPUTS
%     n          Number of observations
%     p          Total number of features  (must be >= 2)
%     sigma_eps  Fixed noise standard deviation  (default = 0.5)
%
%   OUTPUTS
%     X              n x p  design matrix  (NOT column-standardised —
%                            preserves the exact counter-example structure)
%     y              n x 1  response vector
%     beta0_true     scalar intercept (= 0)
%     beta_true      p x 1  true coefficient vector
%     sigma_eps      scalar noise SD (echoed back for convenience)
%     snr_empirical  empirical Var(signal) / Var(noise) for this draw

    % ------------------------------------------------------------------
    % Input validation
    % ------------------------------------------------------------------
    if nargin < 3 || isempty(sigma_eps)
        sigma_eps = 0.5;
    end
    if p < 2
        error('generate_scenario2_data:badInput', 'p must be >= 2.');
    end
    if n < 1
        error('generate_scenario2_data:badInput', 'n must be >= 1.');
    end
    if sigma_eps <= 0
        error('generate_scenario2_data:badInput', 'sigma_eps must be positive.');
    end

    % ------------------------------------------------------------------
    % Design matrix — exact counter-example structure
    % ------------------------------------------------------------------
    x1 = randn(n, 1);                  % x1 ~ N(0,1)
    x2 = x1 + randn(n, 1);            % x2 = x1 + N(0,1)

    % Remaining features are i.i.d. N(0,1)
    X_rest = randn(n, p - 2);

    X = [x1, x2, X_rest];             % n x p   (no standardisation)

    % ------------------------------------------------------------------
    % True coefficients  (fixed, not random)
    % ------------------------------------------------------------------
    beta0_true        = 0;
    beta_true         = zeros(p, 1);
    beta_true(1)      =  1.0;
    beta_true(2)      = -0.5;

    % ------------------------------------------------------------------
    % Response
    % ------------------------------------------------------------------
    signal        = beta0_true + X * beta_true;   % n x 1
    noise         = sigma_eps * randn(n, 1);
    y             = signal + noise;

    snr_empirical = var(signal, 1) / var(noise, 1);
end