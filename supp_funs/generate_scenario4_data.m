function [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
        generate_scenario4_data(n, p, beta_true, rho, sigma_eps)
% GENERATE_SCENARIO4_DATA  Correlated design (Toeplitz) sparse regression.
%
%   Design: Toeplitz covariance  Sigma_jk = rho^|j-k|
%           X columns are standardised after sampling.
%   Beta:   passed in by caller (identical to Scenario 3)
%   Noise:  epsilon ~ N(0, sigma^2 * I_n)
%   Model:  y = X * beta_true + epsilon   (intercept beta0 = 0)
%
%   Toeplitz structure
%   ------------------
%   Cov(x_j, x_k) = rho^|j-k|
%   So adjacent features are correlated by rho, features 2 apart by rho^2,
%   and so on — correlation decays with lag distance.  This is more
%   realistic than compound-symmetry (Scenario 1) where ALL pairs share
%   the same rho.
%
%   INPUTS
%     n          Number of observations
%     p          Total number of features  (must equal length(beta_true))
%     beta_true  p x 1  true coefficient vector  (caller-defined)
%     rho        Toeplitz correlation parameter  (0 <= rho < 1, default 0.5)
%     sigma_eps  Noise standard deviation  (default = 1)
%
%   OUTPUTS
%     X              n x p  column-standardised design matrix
%     y              n x 1  response vector
%     beta0_true     scalar intercept (= 0)
%     beta_true      p x 1  echoed back
%     sigma_eps      scalar noise SD echoed back
%     snr_empirical  Var(signal) / Var(noise) for this draw

    if nargin < 4 || isempty(rho),       rho       = 0.5; end
    if nargin < 5 || isempty(sigma_eps), sigma_eps = 1;   end

    if numel(beta_true) ~= p
        error('generate_scenario4_data:badInput', ...
              'length(beta_true)=%d must equal p=%d.', numel(beta_true), p);
    end
    if rho < 0 || rho >= 1
        error('generate_scenario4_data:badInput', ...
              'rho must satisfy 0 <= rho < 1.');
    end
    if sigma_eps <= 0
        error('generate_scenario4_data:badInput', 'sigma_eps must be positive.');
    end

    beta_true  = beta_true(:);
    beta0_true = 0;

    col1  = rho .^ (0:p-1)';          % first column of Sigma
    Sigma = toeplitz(col1);            % symmetric Toeplitz matrix

    % Cholesky factor (add small ridge for numerical stability)
    R = chol(Sigma + 1e-10 * eye(p), 'lower');

    X  = randn(n, p) * R';

    % Column-standardise (mean 0, std 1)
    X  = X - mean(X, 1);
    sd = std(X, 0, 1);
    sd(sd == 0) = 1;
    X  = X ./ sd;

    signal        = X * beta_true;
    noise         = sigma_eps * randn(n, 1);
    y             = signal + noise;
    snr_empirical = var(signal, 1) / var(noise, 1);
end