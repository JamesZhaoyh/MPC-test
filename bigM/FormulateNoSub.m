function [matrix_ineq, solver_setting] = FormulateNoSub(A, B, C, D, dlim, Q, Qf, R, ...
                                           N, bigM, xmax, xmin, umax, umin)
% this function formulate the problem without substitution
% build the model
%  J = min X'*Smat*X + 2*x0'*cmat'*X + 2*Xd*dmat'*X
%          + (xd-x0)'*Q*(xd-x0) + Xd'*Q*Xd;
%   s.t.  Amat * X = bmat*x(0),   (N*dimA x dim(X))
%         Dmat * X + Dlim1 + Dlim2*x0 >= 0,   (N*dimC x dim(X))
%         Emat * X <= Elim1 + Elim2*x0,       (N*dimC x dim(X))
%         Fmat * X <= Flim (0),               (N*dimC x dim(X))
%         xmin <= x < xim, 
%         umin <= u <= umax, 
%         cn >=0, 
%         z = {0, 1} 

[dimA, ~] = size(A);
[~, dimB] = size(B);
[~, dimC] = size(C);

% compute big matrix
% Amat * X = bmat *x0 -> x(k+1) = Ax(k)+Bu(k)+Ccn(k)
a = kron(eye(N), -eye(dimA));
a = a + kron(tril(ones(N),-1)-tril(ones(N),-2), A);
b = kron(eye(N), B);
c = kron(eye(N), C);
Amat = sparse([a b c zeros(N*dimA, N*dimC)]);

% bmat
bmat = sparse([-A; kron(ones(N-1, 1), zeros(dimA))]);

% Phi(q) = [q1+q2 <= dstmax-1; q1-q3-1 >= dstmin]
% Dmat * X + Dlim >= 0 -> Phi(q(k+1)) = Dx(k+1)+dlim >= 0
Dmat = sparse([kron(eye(N), D) zeros(N*dimC, N*(dimB+2*dimC))]);
Dlim1 = kron(ones(N, 1), dlim);
Dlim2 = zeros(N*dimC, dimA);

% Emat * X <= Elim -> Phi(q(k+1)) <= M(1-z(k)) -> Dx(k+1)+dlim <= M(1-z) 
Emat = sparse([kron(eye(N), D) zeros(N*dimC, N*(dimB+dimC)) ...
               kron(eye(N), bigM*eye(dimC))]);
Elim1 = kron(ones(N, 1), [bigM; bigM]-dlim);
Elim2 = Dlim2;

% Fmat * X <= 0 -> cn(k) <= Mz(k)
Fmat = sparse([zeros(N*dimC, N*dimA) zeros(N*dimC, N*dimB) ...
         kron(eye(N), eye(dimC)) -bigM*kron(eye(N), eye(dimC))]);
Flim = zeros(N*dimC, 1);

% Smat -> J = X' * Smat * X
q = blkdiag(kron(eye(N-1), Q), Qf);
r = kron(eye(N), R);
S = blkdiag(q, r);
Smat = sparse([S zeros(N*(dimA+dimB), 2*N*dimC); ...
            zeros(2*N*dimC, N*(dimA+dimB)) zeros(2*N*dimC)]);

% write the formulation in a compact form using cell array
% notice Gmat, Glim1 and Glim2 are [] in this method
matrix_ineq = cell(1, 16);
matrix_ineq{1} = Smat; matrix_ineq{2} = zeros(N*(dimA+dimB+2*dimC), dimA);
matrix_ineq{3} = -[q zeros(N*dimA, N*(dimB+2*dimC))]';
matrix_ineq{4} = Amat; matrix_ineq{5} = bmat;
matrix_ineq{6} = Dmat; matrix_ineq{7} = Dlim1; matrix_ineq{8} = Dlim2;
matrix_ineq{9} = Emat; matrix_ineq{10} = Elim1; matrix_ineq{11} = Elim2;
matrix_ineq{12} = Fmat; matrix_ineq{13} = Flim;
matrix_ineq{14} = []; matrix_ineq{15} = []; matrix_ineq{16} = [];
matrix_ineq{17} = Q; matrix_ineq{18} = q;

% solver settings
senselst = [repmat('=', 1, N*dimA) repmat('<', 1, 3*N*dimC)];
vtypelst = [repmat('C', 1, N*(dimA+dimB+dimC)) repmat('B', 1, N*dimC)];
lb = [kron(ones(N,1), xmin); kron(ones(N,1), umin); zeros(2*N*dimC, 1)];
ub = [kron(ones(N,1), xmax); kron(ones(N,1), umax); Inf*ones(N*dimC, 1); ones(N*dimC, 1)];

solver_setting = cell(1, 4);
solver_setting{1} = senselst;
solver_setting{2} = vtypelst;
solver_setting{3} = lb;
solver_setting{4} = ub;

end