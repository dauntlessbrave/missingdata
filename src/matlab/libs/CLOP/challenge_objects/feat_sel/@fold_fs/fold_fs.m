function a = fold_fs(hyper) 

%=========================================================================
% Fold change feature ranking
%=========================================================================   
% A=fold_fs(H) returns a fold object initialized with hyperparameters H. 
% 
%  Hyperparameters, and their defaults
%
%   is_log          -- Flag indicating whether the data are on a log scale
%   f_max           -- Maximum number of features to be selected;
%                     if f_max=Inf then no limit is set on the number of
%                     features.
%   w_min           -- Threshold on the ranking criterion W;
%                     if W(i) <= w_min, the feature i is eliminated.
%                     W is between 0 and 1. A negative value of w_min
%                     means all the features are kept.
%  If both theta and featnum are provided, both criteria are satisfied,
%  i.e. feature_number <= featmax and W > theta.
%
%  Model
%
%  a.fidx          -- Indices of the ranked features. Best first.
%  a.W             -- Ranking criterion (weight), the larger, the better.  
%                     These values are unsorted.
%
%  Methods:
%   train, test, get_w, get_fidx
%
%  Example:
%  d=gen(toy); a=s2n('w_min=0.2'); a.f_max=20; [r,a]=train(a,d);
%  get_fidx(a)  % lists the chosen features in  order of importance, using 20 features

% Isabelle Guyon -- isabelle@clopinet.com -- Nov 2012

a.IamCLOP=1;

% hyperparameters
a.display_fields={'f_max', 'w_min'};
a.f_max= default(Inf, [0 Inf]);             % number of features 
a.w_min= default(-Inf, [-Inf Inf]);         % threshold of the criterion    

a.is_log=1;                                 % parameter indicating whether the data are on a log scale
a.cache_file='';                            % file that caches the weights

% model
a.fidx=[];
a.W=[];

algoType=algorithm('fold_fs');
a= class(a,'fold_fs',algoType);

a.algorithm.do_not_evaluate_training_error=0; 
a.algorithm.verbosity=1;

% overwrite the defaults
eval_hyper;



   
  
