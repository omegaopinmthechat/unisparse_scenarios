function [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
        generate_scenario3_data(n, p, sigma_eps)
% GENERATE_SCENARIO3_DATA  Independent-design sparse regression (Scenario 3).
%
%   [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
%       generate_scenario3_data(n, p, sigma_eps)
%
%   Design
%   ------
%   X in R^{n x p}: entries are i.i.d. N(0,1), then standardised column-wise
%   (mean 0, std 1) — the "independent design" scenario.
%
%   True coefficients (FIXED, not random)
%   --------------------------------------
%   s0 = 10 nonzero entries placed in the FIRST ten coordinates:
%     beta = (2.5, -2.0, 1.8, -1.5, 1.2, 1.0, -0.9, 0.8, 0.7, -0.7, 0, ..., 0)
%   beta0 (intercept) = 0.
%
%   Noise
%   -----
%   epsilon ~ N_n(0, sigma^2 * I_n),  default sigma = 1.
%
%   Response
%   ---------
%   y = X * beta + epsilon   (intercept is zero so beta0 term drops out)
%
%   INPUTS
%     n          Number of observations
%     p          Total number of features  (must be >= 10)
%     sigma_eps  Noise standard deviation  (default = 1)
%
%   OUTPUTS
%     X              n x p  standardised design matrix
%     y              n x 1  response vector
%     beta0_true     scalar intercept (= 0)
%     beta_true      p x 1  true coefficient vector (fixed values)
%     sigma_eps      scalar noise SD  (echoed back)
%     snr_empirical  empirical Var(Xbeta) / Var(epsilon) for this draw

    if nargin < 3 || isempty(sigma_eps)
        sigma_eps = 1;
    end
    if p < 10
        error('generate_scenario3_data:badInput', ...
              'p must be >= 10 (need room for 10 nonzero coefficients).');
    end
    if n < 1
        error('generate_scenario3_data:badInput', 'n must be >= 1.');
    end
    if sigma_eps <= 0
        error('generate_scenario3_data:badInput', 'sigma_eps must be positive.');
    end


    X  = randn(n, p);
    X  = X - mean(X, 1);          % centre each column
    sd = std(X, 0, 1);
    sd(sd == 0) = 1;               % guard against degenerate columns
    X  = X ./ sd;

    % The first 10 values are fixed and rest are 0's
    beta0_true = 0;
    beta_true  = zeros(p, 1);
    beta_true(1:10) = [2.5; -2.0; 1.8; -1.5; 1.2; 1.0; -0.9; 0.8; 0.7; -0.7];

    % y=β0​+Xβ+ϵ beta0 is zero
    signal        = X * beta_true;              % intercept = 0
    noise         = sigma_eps * randn(n, 1);
    y             = signal + noise;
    snr_empirical = var(signal, 1) / var(noise, 1);
end