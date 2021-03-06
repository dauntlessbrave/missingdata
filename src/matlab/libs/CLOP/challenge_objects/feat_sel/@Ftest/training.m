function [dat, alg] =  training(alg,dat)
%[dat, alg] =  training(alg,dat)
% Compute the F statistic
% and rank the features accordingly.
% Returns the training data matrix dat restricted to the
% selected features (i.e. feat_num<=feat_max and w>w_min.

% Isabelle Guyon -- isabelle@clopinet.com -- December 2005
  
if alg.algorithm.verbosity>0
    disp(['training ' get_name(alg) '... '])
end
 
[p,n]=get_dim(dat);

X=get_x(dat);
Y=get_y(dat);

[idxs,crit]=fisher_feat(X, Y);

alg.fidx=idxs;
alg.W(idxs)=crit; 
% For 2 classes
v1=1; v2=p-2;
alg.pval=1-fcdf(alg.W, v1, v2);
sorted_fdr=alg.pval(alg.fidx).*(n./[1:n]);
alg.fdr(alg.fidx) = sorted_fdr;

if 1==2 % Computes the same thing with anovan
W=zeros(1,n);
pval=ones(1,n);
for k=1:n
    if(var(X(:,k))~=0)
        [P, T]=anovan(full(X(:,k)),{Y}, 'display', 'off');
        W(k)=T{2,6};
        pval(k)=P;
        %If you are confused, >doc anovan :=)
    end
end
alg.W=abs(W);
[ss,alg.fidx]=sort(-alg.W);
alg.pval = pval;
sorted_fdr=alg.pval(alg.fidx).*(n./[1:n]);
alg.fdr(alg.fidx) = sorted_fdr;
  
end %if 1==2

if ~alg.algorithm.do_not_evaluate_training_error
    dat=test(alg, dat);
end

  

  

  
  
