function X = S_Step(Y_M, D_M, eta, maxiter)

norm_y = sqrt(mean(mean(Y_M.^2)));
D_M = D_M/norm_y;
Y_M = Y_M/norm_y;

[~, N] = size(Y_M);
[~, d] = size(D_M);

iter = 1;
epsilon = 1e-6;
stop = false;

G = zeros(d, N);
lamda1 = zeros(size(G));

mu = 1e-3;
rho = 1.5;
mu_bar = 1e+6;

while ~stop && iter < maxiter+1
    
    %update X
    B1=(D_M' * D_M) + mu * eye(size(D_M' * D_M));
    W1=D_M' * Y_M + mu * G + lamda1;
    C1=pinv(B1)*ones(d,1)*pinv(ones(1,d) * pinv(B1)*ones(d,1));
    X=pinv(B1)*W1-C1*(ones(1,d)*pinv(B1)*W1-1); 
    
    % solve sparse term
    G = max(abs(X - lamda1 / mu) - (eta / mu),0).*sign(X - lamda1 / mu); 
    
    % update lamda1-5
    lamda1 = lamda1 + mu * (G - X);
    mu = min(mu * rho, mu_bar);
    
    iter=iter+1;
    
    % check convergence
    res1 = norm(G - X, 'fro');

    if res1 < epsilon
        stop = true;
        break;
    end
end

end