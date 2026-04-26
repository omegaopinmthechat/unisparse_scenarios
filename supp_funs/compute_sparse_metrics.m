function m = compute_sparse_metrics(beta_hat, beta_true_whole, yhat, y, tol)
% COMPUTE_SPARSE_METRICS  Compute classification + prediction metrics.
%
%   m = compute_sparse_metrics(beta_hat, beta_true_whole, yhat, y, tol)
%
%   INPUTS
%     beta_hat        (p+1) x 1  estimated coefficients [intercept; slopes]
%     beta_true_whole (p+1) x 1  true coefficients      [intercept; slopes]
%     yhat            n x 1      fitted values
%     y               n x 1      observed response
%     tol             scalar     threshold for "nonzero" (e.g. 1e-4)
%
%   OUTPUT  m  1 x 6 row vector
%     m(1)  TPR  (sensitivity / recall)
%     m(2)  FPR  (fall-out)
%     m(3)  MCC  (Matthews correlation coefficient)
%     m(4)  Beta_RMSE
%     m(5)  Beta_MAD
%     m(6)  Full_MSE  (prediction MSE on training data)
%
%   Notes
%   - The intercept is excluded from support-recovery metrics (slopes only).
%   - If a denominator is zero the corresponding metric is set to NaN.

    beta_slopes_hat  = beta_hat(2:end);
    beta_slopes_true = beta_true_whole(2:end);

    true_pos_mask = abs(beta_slopes_true) > tol;   % truly nonzero
    true_neg_mask = ~true_pos_mask;                 % truly zero
    est_pos_mask  = abs(beta_slopes_hat)  > tol;   % estimated nonzero
    est_neg_mask  = ~est_pos_mask;                  % estimated zero

    TP = sum( est_pos_mask &  true_pos_mask);
    FP = sum( est_pos_mask &  true_neg_mask);
    TN = sum( est_neg_mask &  true_neg_mask);
    FN = sum( est_neg_mask &  true_pos_mask);

    % TPR
    if (TP + FN) > 0
        tpr = TP / (TP + FN);
    else
        tpr = NaN;
    end

    % FPR
    if (FP + TN) > 0
        fpr = FP / (FP + TN);
    else
        fpr = NaN;
    end

    % MCC
    denom_mcc = sqrt(double(TP + FP) * double(TP + FN) * ...
                     double(TN + FP) * double(TN + FN));
    if denom_mcc > 0
        mcc = (double(TP) * double(TN) - double(FP) * double(FN)) / denom_mcc;
    else
        mcc = NaN;
    end

    % Coefficient estimation errors
    beta_rmse = sqrt(mean((beta_hat - beta_true_whole).^2));
    beta_mad  = mean(abs(beta_hat  - beta_true_whole));

    % Prediction MSE
    full_mse  = mean((y - yhat).^2);

    m = [tpr, fpr, mcc, beta_rmse, beta_mad, full_mse];
end