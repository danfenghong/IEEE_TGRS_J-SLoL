function [D_H, X] = D_Step(Y_H, D_H, beta, gamma, maxiter)

[d_H, N] = size(Y_H);
[~, d] = size(D_H);

iter = 1;
epsilon = 1e-6;
stop = false;

P = zeros(d_H, d);
G = zeros(d, N);
Q = zeros(d_H,d);


lamda1 = zeros(size(G));
lamda2 = zeros(size(P));
lamda3 = zeros(size(P));

mu = 1E-3;
rho = 1.5;
mu_bar = 1e+6;


while ~stop && iter < maxiter+1
    
    % update X
    B1 = D_H' * D_H + mu * eye(size(D_H' * D_H));
    W1 = D_H' * Y_H + mu * G + lamda1;
    C1 = pinv(B1) * ones(d, 1) * pinv(ones(1, d) * pinv(B1) * ones(d, 1));
    X = pinv(B1) * W1 - C1 * (ones(1, d) * pinv(B1) * W1 - 1);

    % update D_H
    D_H = (Y_H * X' + mu * P + lamda2 + mu * Q + lamda3)/(X * X' + 2 * mu * eye(size(X * X')));

    Q = max(D_H - lamda3 / mu, 0); 

    % solve low-rank regularization
    Resi_G = D_H - lamda2/mu;
    [U1, S1, V1] = svd(Resi_G, 'econ');
    diagS = diag(S1);
    svp = length(find(diagS > gamma / mu));
    if svp >= 1
        diagS = diagS(1 : svp) - gamma / mu;
    else
        svp = 1;
        diagS = 0;
    end
    P = U1(:, 1 : svp) * diag(diagS) * V1(:, 1:svp)'; 
    
    % solve sparsity term
    G = max(abs(X - lamda1 / mu) - (beta / mu),0).*sign(X - lamda1 / mu); 
    
    %update lamda1-3
    lamda1 = lamda1 + mu * (G - X);
    lamda2 = lamda2 + mu * (P - D_H);
    lamda3 = lamda3 + mu * (Q - D_H);
    mu = min(mu * rho, mu_bar);
    
    iter=iter+1;
    
    % check convergence
    res1 = norm(G - X, 'fro');
    res2 = norm(P - D_H, 'fro');
    res3 = norm(Q - D_H, 'fro');    

    if res1 < epsilon && res2 < epsilon && res3 < epsilon
        stop = true;
        break;
    end
end

end