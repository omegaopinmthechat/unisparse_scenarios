function [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
        generate_scenario1_data(n, p, true_p, rho, target_snr)
% GENERATE_SCENARIO1_DATA  Generate a sparse linear regression dataset.
%
%   [X, y, beta0_true, beta_true, sigma_eps, snr_empirical] = ...
%       generate_scenario1_data(n, p, true_p, rho, target_snr)
%
%   INPUTS
%     n          Number of observations
%     p          Total number of features
%     true_p     Number of truly active (nonzero) features   (true_p <= p)
%     rho        Pairwise feature correlation (compound-symmetry structure)
%     target_snr Desired signal-to-noise ratio  Var(Xb) / sigma^2
%
%   OUTPUTS
%     X              n x p  standardised design matrix
%     y              n x 1  response vector
%     beta0_true     scalar intercept (= 0)
%     beta_true      p x 1  sparse true coefficient vector
%     sigma_eps      scalar noise standard deviation chosen to hit target_snr
%     snr_empirical  empirical SNR achieved in this realisation
%
%   Design
%     Features are drawn from N(0, Sigma) where Sigma is a compound-symmetry
%     matrix: Sigma_jk = rho for j~=k, Sigma_jj = 1.  Columns are then
%     z-standardised so each column has mean 0 and std 1.
%
%     The true_p active predictors are chosen uniformly at random; their
%     coefficients are i.i.d. N(0,1).  Noise is Gaussian with sigma chosen
%     so that Var(X*beta_true) / sigma^2 = target_snr.

    % ------------------------------------------------------------------
    % Input validation
    % ------------------------------------------------------------------
    if true_p > p
        error('generate_scenario1_data:badInput', ...
              'true_p (%d) must be <= p (%d).', true_p, p);
    end
    if target_snr <= 0
        error('generate_scenario1_data:badInput', ...
              'target_snr must be a positive number.');
    end
    if rho < 0 || rho >= 1
        error('generate_scenario1_data:badInput', ...
              'rho must satisfy 0 <= rho < 1.');
    end

    % ------------------------------------------------------------------
    % Design matrix: compound-symmetry covariance
    % ------------------------------------------------------------------
    % Sigma = (1-rho)*I + rho*11'  =>  all off-diagonal entries = rho
    Sigma = (1 - rho) * eye(p) + rho * ones(p);

    % Cholesky factor with small ridge for numerical stability
    R = chol(Sigma + 1e-10 * eye(p), 'lower');

    % Raw Gaussian draws, then rotate to introduce correlation
    X = randn(n, p) * R';

    % Column-wise standardisation (mean 0, std 1)
    X  = X - mean(X, 1);
    sd = std(X, 0, 1);
    sd(sd == 0) = 1;           % guard against degenerate columns
    X  = X ./ sd;

    % ------------------------------------------------------------------
    % True coefficient vector
    % ------------------------------------------------------------------
    beta0_true = 0;
    beta_true  = zeros(p, 1);

    % Randomly select true_p active predictors
    active_idx = randperm(p, true_p);
    beta_true(active_idx) = randn(true_p, 1);

    % ------------------------------------------------------------------
    % Response variable
    % ------------------------------------------------------------------
    signal    = beta0_true + X * beta_true;
    var_signal = var(signal, 1);

    % Choose sigma so that SNR = Var(signal) / sigma^2 = target_snr
    if var_signal < eps
        warning('generate_scenario1_data:zeroSignal', ...
                'Signal variance is (near) zero — sigma set to 1.');
        sigma_eps = 1;
    else
        sigma_eps = sqrt(var_signal / target_snr);
    end

    noise         = sigma_eps * randn(n, 1);
    y             = signal + noise;
    snr_empirical = var(signal, 1) / var(noise, 1);
end