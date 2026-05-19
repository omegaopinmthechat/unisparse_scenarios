function metrics_table = summarize_unisparse_methods(fit, beta0_true, beta_true, X, y, tol)
% SUMMARIZE_UNISPARSE_METHODS  Build a metrics table from a unisparse fit.
%
%   metrics_table = summarize_unisparse_methods(fit, beta0_true, beta_true,
%                                               X, y, tol)
%
%   INPUTS
%     fit         struct returned by unisparse(... , method='all')
%                 Expected fields: UNILASSO, UNIMCP, UNISCAD
%                 Each sub-struct must have:
%                   .beta   (p+1) x 1  [intercept; slopes]
%                   .lambda scalar     selected regularisation parameter
%     beta0_true  scalar              true intercept
%     beta_true   p x 1              true slope coefficients
%     X           n x p              design matrix (no intercept column)
%     y           n x 1              response
%     tol         scalar             threshold to declare a coefficient nonzero
%
%   OUTPUT
%     metrics_table  3-row MATLAB table with columns:
%       Method  Lambda  TPR  FPR  FDR  MCC  RMSE  NNZ
%       BetaRMSE  BetaMAD
%
%   Helper called:  compute_sparse_metrics   (must be on the MATLAB path)

    method_keys   = {'UNILASSO', 'UNIMCP', 'UNISCAD'};
    method_labels = {'UniLASSO', 'UniMCP', 'UniSCAD'};

    % Full true coefficient vector including intercept
    beta_true_whole = [beta0_true; beta_true];

    n_methods = numel(method_keys);

    % Pre-allocate storage
    lambda_vals   = nan(n_methods, 1);
    tpr_vals      = nan(n_methods, 1);
    fpr_vals      = nan(n_methods, 1);
    fdr_vals      = nan(n_methods, 1);
    mcc_vals      = nan(n_methods, 1);
    rmse_vals      = nan(n_methods, 1);
    nnz_vals      = nan(n_methods, 1);
    beta_rmse_vals = nan(n_methods, 1);
    beta_mad_vals  = nan(n_methods, 1);

    for k = 1:n_methods
        key = method_keys{k};

        if ~isfield(fit, key)
            warning('summarize_unisparse_methods:missingField', ...
                    'Field "%s" not found in fit struct — skipping.', key);
            continue;
        end

        beta_hat = fit.(key).beta(:);                    % (p+1) x 1
        yhat     = beta_hat(1) + X * beta_hat(2:end);   % n x 1

        % Core metrics vector: [TPR, FPR, MCC, BetaRMSE, BetaMAD, RMSE]
        m = compute_sparse_metrics(beta_hat, beta_true_whole, yhat, y, tol);

        % FDR = FP / (TP + FP)  — computed separately for clarity
        true_support = abs(beta_true_whole(2:end)) > tol;
        est_support  = abs(beta_hat(2:end))        > tol;
        tp = sum( est_support &  true_support);
        fp = sum( est_support & ~true_support);
        fdr_val = 0;
        if (tp + fp) > 0
            fdr_val = fp / (tp + fp);
        end

        lambda_vals(k)    = fit.(key).lambda;
        tpr_vals(k)       = m(1);
        fpr_vals(k)       = m(2);
        mcc_vals(k)       = m(3);
        beta_rmse_vals(k) = m(4);
        beta_mad_vals(k)  = m(5);
        rmse_vals(k)       = m(6);
        fdr_vals(k)       = fdr_val;
        nnz_vals(k)       = sum(est_support);
    end

    metrics_table = table( ...
        string(method_labels(:)), ...
        lambda_vals, ...
        tpr_vals, ...
        fpr_vals, ...
        fdr_vals, ...
        mcc_vals, ...
        rmse_vals, ...
        nnz_vals, ...
        beta_rmse_vals, ...
        beta_mad_vals, ...
        'VariableNames', {'Method', 'Lambda', 'TPR', 'FPR', ...
                          'FDR', 'MCC', 'RMSE', 'NNZ', ...
                          'BetaRMSE', 'BetaMAD'});
end