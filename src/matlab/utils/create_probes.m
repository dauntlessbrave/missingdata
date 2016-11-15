function [ D, Dt, Dv, F, T ] = create_probes(D, Dt, Dv, F, T)
%CREATE_PROBES Summary of this function goes here
%   Detailed explanation goes here

    X_prob = zeros(size(D.X));
    Xt_prob = zeros(size(Dt.X));
    Xv_prob = zeros(size(Dv.X));
    for c=1:size(D.X,2)
        X_prob(:,c) = D.X(randperm(size(D.X,1)),c);
    end
    for c=1:size(Dt.X,2)
        Xt_prob(:,c) = Dt.X(randperm(size(Dt.X,1)),c);
    end
    for c=1:size(Dv.X,2)
        Xv_prob(:,c) = Dv.X(randperm(size(Dv.X,1)),c);
    end
    D.X = [D.X X_prob];
    Dt.X = [Dt.X Xt_prob];
    Dv.X = [Dv.X Xv_prob];
end

