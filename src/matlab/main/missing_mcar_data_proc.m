% Load and show digits

% More info: http://clopinet.com/isabelle/Projects/ETH/Feature_Selection_w_CLOP.html
% Isabelle guyon, Oct, 2016

% There are 2 data versions:
%1) no probes = Gisette_noprobe
%2) with probes (original) = Gisette

% Set the dataset name.
dataset_name = 'Gisette';
% Set the dataset folder.
dataset_orig_type = 'orig_dataset';
% Set the dataset folder.
dataset_type = 'miss_dataset';

mcar_p = [0, 10, 20, 40, 80];

% Get the different file names of the dataset.
data_base_name = lower(dataset_name);
data_train_name = [data_base_name '_train'];
data_test_name = [data_base_name '_test'];
data_valid_name = [data_base_name '_valid'];
data_feat_name = [data_base_name '_feat'];

% Add the utils folder to Matlab path to start the file load process (including libs).
utils_dir = '../utils';
addpath(utils_dir);
% Obtain the dir of each relevant folder in the repository.
[rootdir datadir graphsdir srcdir resultsdir] = load_path();
% Obtain the dataset folder.
dataset_folder = [datadir filesep dataset_orig_type filesep dataset_name];
% Create a folder to save the different graphs of the dataset.
graphs_folder = [graphsdir filesep dataset_name];
mkdir(graphs_folder);
% Create a folder to save the info of the dataset.
results_folder = [resultsdir filesep dataset_name];
mkdir(results_folder);

% Load the dataset, divided in train, test, validation, ...
[D Dt Dv F T] = load_dataset(dataset_folder, data_train_name, data_test_name, ...
                             data_valid_name, data_feat_name);
% Take a look at the digits
%M=browse_digit(X,Y,F);
% Note: If you use the plain Gisette_noprobe, do niot load F and use
% M=browse_digit(X,Y);
% The function returns the image you were looking at when you exited

% Learn a simple model
use_spider_clop;
%my_classifier=svc({'coef0=1','degree=3','gamma=0','shrinkage=1'});

%my_classifier=kridge; % Other possible models, e.g. my_classifier=naive;
% Slightly better with normalization, but don't bother: my_model=chain({normalize, s2n('f_max=1000'),my_classifier});

for p=1:length(mcar_p)
    miss_perc = mcar_p(p);
    % Create a folder to save the different aurocs for each features selected
    % by feature selection methods. 
    auroc_by_fs_folder = [graphs_folder filesep 'auroc_by_fs_' dataset_type '_' num2str(miss_perc)];
    mkdir(auroc_by_fs_folder);
    % Apply MCAR missing data on the dataset.
    [M_mcar Mt_mcar Mv_mcar] = mcar(1, miss_perc, D, Dt, Dv);
    % Apply an imputation over the missing data values.
    [D_mcar Dt_mcar Dv_mcar] = imputation(1, D, Dt, Dv, M_mcar, Mt_mcar, Mv_mcar);

    % Feature selection process.
    [rank_list num_feats] = fs_rank( 1, 1, D_mcar, Dt_mcar, Dv_mcar, F, T);
    % Classification with the different feature subsets. 
    [train_r, valid_r, test_r, train_mod, prec_r, recall_r] = ...
                        classif(1, D_mcar, Dt_mcar, Dv_mcar, F, T, rank_list);
    % Obtain the different plots for the validation subset.
    [cell_h_auroc, h_total_auroc, h_aulc, h_aupr, auroc, aulc, aupr] = ...
                        get_plot(valid_r, prec_r, recall_r, num_feats);
    % Obtain the different plots for the test subset.
    %[cell_h_auroc, h_total_auroc, h_aulc, h_aupr] = ...
    %                    get_plot(test_r, prec_r, recall_r, num_feats);

    for i=1:length(cell_h_auroc)
        savefig(cell_h_auroc{i}, ...
                [auroc_by_fs_folder filesep 'auroc_fs_' num2str(num_feats(i)) '_' dataset_type '_' num2str(miss_perc)]);
    end
    savefig(h_total_auroc, [auroc_by_fs_folder filesep 'all_auroc_fs_' dataset_type '_' num2str(miss_perc) '.fig']);
    close(h_total_auroc);
    savefig(h_aulc, [graphsdir filesep dataset_name filesep 'aulc_' dataset_type '_' num2str(miss_perc)]);
    close(h_aulc);
    savefig(h_aupr, [graphsdir filesep dataset_name filesep 'aupr_' dataset_type '_' num2str(miss_perc)]);
    close(h_aupr);

    save([results_folder filesep 'data_' dataset_type '_' num2str(mcar_p(p)*100) '.mat'], ...
         'D_mcar', 'Dt_mcar', 'Dv_mcar', 'M_mcar', 'Mt_mcar', 'Mv_mcar', ...
         'rank_list', 'num_feats', 'train_r', 'valid_r', 'test_r', ...
         'train_mod', 'prec_r', 'recall_r', 'auroc', 'aulc', 'aupr', 'miss_perc');
end

%h_miss_evol = get_miss_evolution_plot(results_folder, dataset_type, miss_perc);
%savefig(h_miss_evol, [graphsdir filesep dataset_name filesep 'miss_evolution_' dataset_type]);
%close(h_miss_evol);
    
fprintf('\n ========== END =========\n');

% Todo: 
% Compute ALC and AUPR for all proportions of missing data
