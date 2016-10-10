% % % Performs particle swarm model selection and returns the 
% % % selected model as an object
% % % 
% % % 
% % % Input:
% % %           retAlgo  -  psms - object
% % %           dat      -  training data
% % % Output:
% % % 
% % % 
% % %===============================================================
% % % Hugo Jair Escalante -- hugojair@ccc.inaoep.mx -- June 2008
% % %                        hugo.jair@gmail.com
% % %===============================================================

function [dat, retRes] = training(retAlgo,dat)
rlikepathcmd='del C:\CLOP\challenge_objects\packages\Rlink\*.Rdata';
% system(rlikepathcmd);
retRes = {};
retRes.training_time=cputime;
rand('state',sum(100*clock));

if retAlgo.algorithm.verbosity>0
    disp(['training ' get_name(retAlgo) '... '])
end

psms_child=retAlgo.child;

% if isa(psms_child,'cell') 
%     untrained = group(psms_child); % <-- convert retAlgo.child{1} to group
% end;

str_psms_child=struct(psms_child{:});
child_n=get_name(str_psms_child.algorithm);

% % % Use pso for selection of preprocessing, feature selection and
% % % hyperparameter optimization
if retAlgo.fms==0,
    psms_case=2;
% % % Use pso for hyperparameter optimization for the fixed child    
elseif retAlgo.fms==-1,
       [is_classifier]=isclassifier(child_n);
        if (~is_classifier)        
            fprintf('-o-o-o-o-o-o-o\n This is not a valid child \n -o-o-o');
            return;
        end
%         method{1}=str_psms_child.algorithm;
        [st]=set_pars(child_n,retAlgo.donotincludethis);   
        if (ischar(st)),
            fprintf('-o-o-o-o\n Nothing to do for this model \n-o-o-o-o\n');
            return;
        end
    retAlgo.dim=st.npars;
    retRes.dim=st.npars;
    psms_case=1;

else 
    retAlgo.fms=1,
    psms_case=3;   
end
retRes.fms=retAlgo.fms;

% % % % This part of the code determines the representation for particles
% % % % Full model representation
% if ~isempty(st)
%     retAlgo.dim=st.npars;
%     retRes.dim=st.npars;
%     psms_case=1;
% % % % Hyperparameter optimization for methods{1}    
% elseif length(method)==1
%     psms_case=2;
% % % % Parameters-hyperparameters for methods{:}
% else
%     psms_case=3;
% end


retRes.history_best=-1.*ones(1,retAlgo.swarmsize*retAlgo.maxiter+retAlgo.swarmsize);
[num,vecDim,outDim]=get_dim(dat);       %% Dimensionality of data
orig_name=get_name(dat);                

% % % Create the subsample object
natts=round(num/retAlgo.redfactor);
sbmodel=subsample({['p_max=' num2str(natts)] ,'balance=1'})
sbmodel.verbosity=retAlgo.verbosity;

% if retAlgo.animation
%     global vizAxes; %Use the specified axes if using GUI or create a new global if called from command window
%     
% %     % % %  Create the Figure
% %     ud.dist_fig = figure('Name','GUI - Particle Swarm Model Selection','Tag','disptfig','Position',[190,150,1000,680]);
% %     set(ud.dist_fig,'Units','Normalized','Backingstore','off','InvertHardcopy','on',...
% %     'PaperPositionMode','auto','Color','white','resize','off','MenuBar','none');
% %     figcolor = get(ud.dist_fig,'Color');    
% %     
%     vizAxes = plot3(0,0,0, '.w');
%     set(gcf,'Color','white');
%     axis([-0.5 0.5 -0.5 0.5 -0.5 0.5]);   %Initially set to a cube of this size
%     axis square;
%     grid on;
%     box;
%     set(vizAxes,'EraseMode','xor','MarkerSize',15); %Set it to show particles.
% %         set(vizAxes,'EraseMode','xor','MarkerSize',15); %Set it to show particles.
% %     ylabel('Classifier');xlabel('Prepro + Feat-Sel ');
%     xlabel('Preprocessing','FontSize',14);ylabel('Feature-Selection','FontSize',14);zlabel('Classifier','FontSize',14);
% %     set(vizAxes,'EraseMode','none','Marker','>','MarkerSize',10,'LineWidth',2); %Set it to show particles.
% %     set(vizAxes,'EraseMode','xor','Marker','>','MarkerSize',10,'LineWidth',2); %Set it to show particles.
% gca;cla;
%     pause(1);
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      PSMS STARTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initializing variables
success = 0; % Success Flag
iter = 0;   % Iterations' counter

% % Defines total number of iterations for which weight is changed.
w_varyfor = floor(retAlgo.w_varyfor*retAlgo.maxiter); %Weight change step. 
w_now = retAlgo.w_start;
inertdec = (retAlgo.w_start-retAlgo.w_end)/w_varyfor; %Inertia weight's change per iteration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%   SWARM INITIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % Switch the model selection cases (i. e. hyperparameter optimization, 
% % % full model selection, or 'half' fms)
switch psms_case,
% % % Hyperparameter optimization for a fixed classifier
    case 1,

    for i=1:retAlgo.swarmsize
    for j=1:length(st.min_vals)
        retRes.Swarm(i,j) = rand*(st.max_vals(j)-st.min_vals(j)) ...
            + st.min_vals(j);
    end
    end 
%     retAlgo.dimensionality=length(st.min_vals);
    VStep = rand(retAlgo.swarmsize, retAlgo.dim);
    for hh = 1:retAlgo.swarmsize
    try, [ndat, tm]=train(sbmodel,dat);
    catch,  ndat=dat; 
    end
    try
    [retRes.Swarm(hh,:), retRes.fSwarm(hh), xvar ] =  ...
        fitness(retAlgo,ndat,abs(retRes.Swarm(hh,:)),...
        vecDim,psms_case,st);
    catch
        disp(lasterr);
        retRes.fSwarm(hh)=100;
    end
        retRes.track(hh,:)=retRes.fSwarm(hh);
        
    clear ndat tm;
    end
%     system('del C:\CLOP\challenge_objects\packages\Rlink\*.Rdata');
    system(rlikepathcmd);
    % Initializing the Best positions matrix and
    % the corresponding function values
    retRes.PBest = retRes.Swarm;
    retRes.fPBest = retRes.fSwarm;

    % Finding best particle in initial population
    [retRes.fGBest, g] = min(retRes.fSwarm);
    retRes.lastbpf = retRes.fGBest;
    retRes.Best = retRes.Swarm(g,:); %Used to keep track of the Best particle ever
    retRes.Best_set=retRes.Best;
    retRes.fBest = retRes.fGBest;
    retRes.history = [0, retRes.fGBest];
    retRes.counter=hh+1;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                  THE  PSO  LOOP                          %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while( (success == 0) & (iter < retAlgo.maxiter) )
        iter = iter+1;
        fprintf('************ Iteration # %i ******************\n',iter);    
        str=[' Iteration=' num2str(iter)];      

        % Update the value of the inertia weight W
            if (iter<=w_varyfor) & (iter > 1)
            w_now = w_now - inertdec; %Change inertia weight
            end
% w_varyfor = floor(retAlgo.w_varyfor*retAlgo.maxiter); %Weight change step. 
% w_now = retAlgo.w_start;
% inertdec = (retAlgo.w_start-retAlgo.w_end)/w_varyfor; %Inertia weight's change per iteration

        % Set GBest
        A = repmat(retRes.Swarm(g,:), retAlgo.swarmsize, 1); 
        B = A; %B wil be nBest (best neighbor) matrix

        % Generate Random Numbers
        R1 = rand(retAlgo.swarmsize, retAlgo.dim);
        R2 = rand(retAlgo.swarmsize, retAlgo.dim);

        % Calculate Velocity
        VStep = w_now*VStep + retAlgo.c1*R1.*(retRes.PBest-retRes.Swarm)...
            + retAlgo.c2*R2.*(A-retRes.Swarm);

        % Apply Vmax Operator for v > Vmax
        changeRows = VStep > retAlgo.vmax;
        VStep(find(changeRows)) = retAlgo.vmax;
        % Apply vmax Operator for v < -vmax
        changeRows = VStep < -retAlgo.vmax;
        VStep(find(changeRows)) = -retAlgo.vmax;

        % ::UPDATE POSITIONS OF PARTICLES::
        retRes.Swarm = retRes.Swarm + retAlgo.chi * VStep;    % Evaluate new Swarm    

        for hh = 1:retAlgo.swarmsize
        try,         [ndat, tm]=train(sbmodel,dat);
        catch
            ndat=dat;
        end
        try
    [retRes.Swarm(hh,:), retRes.fSwarm(hh), xvar ] =  fitness(retAlgo,ndat,abs(retRes.Swarm(hh,:)),...
        vecDim,psms_case,st);
            
        catch
            disp(lasterr);
            retRes.fSwarm(hh)=100;
        end
        clear ndat tm;

            retRes.track(retRes.counter,:)=retRes.fSwarm(hh);
            retRes.counter=retRes.counter+1;
        end

        system(rlikepathcmd);
        % Updating the best position for each particle
        changeRows = retRes.fSwarm < retRes.fPBest;
        retRes.fPBest(find(changeRows)) = retRes.fSwarm(find(changeRows));
        retRes.PBest(find(changeRows), :) = retRes.Swarm(find(changeRows), :);

        % Updating index g
        [retRes.fGBest, g] = min(retRes.fPBest);

        %Update Best. Only if fitness has improved.   
        if retRes.fGBest < retRes.lastbpf
            [retRes.fBest, b] = min(retRes.fPBest);
            retRes.Best = retRes.PBest(b,:);
        end

%         [valid_particle] = validate_particle(retAlgo,Best, vecDim);
%         [retRes,base_model]=create_CLOP_model(retAlgo,valid_particle);

        if (mod(iter,retAlgo.save_every)==0)
            retRes.Best_set=[retRes.Best_set; retRes.Best];       
            retRes.history_best(:,iter*retAlgo.swarmsize+retAlgo.swarmsize)...
                =retRes.fBest;
        end
        save psms_bestmodels.mat retRes;
        
%     if retAlgo.animation
%         [fworst, worst] = max(retRes.fGBest);
%         DrawSwarmPSMS(retRes.Swarm, retAlgo.swarmsize, iter, retAlgo.dim, retRes.Swarm(g,:), vizAxes);
%     end

%         retRes = {};
        %%TERMINATION%%
        if abs(retRes.fGBest-0) <= retAlgo.terminate_err     %GBest
            success = 1;
        elseif abs(retRes.fBest-0)<=retAlgo.terminate_err %Best
            success = 1;
        else
            retRes.lastbpf = retRes.fGBest; %To be used to find Best
        end

        if retAlgo.algorithm.verbosity
            str = sprintf('PSMS, iteration No. %d of a total of %d', ...
                iter, retAlgo.maxiter);
            disp(str)
        end  

    end  %%% end while - iterations    
%     end
        try
    [retRes.Best_P, retRes.Best_f, retRes.Best_model] =...
        fitness(retAlgo,dat,retRes.Best,...
        vecDim,psms_case,st);
            retRes.Suc_train=1;
    catch
        disp(lasterr);
        i=1;
        [ss,si]=sort(retRes.fSwarm);
        while (i<=size(retRes.Swarm,1))
            try
        [A,B,C]=fitness(retAlgo,dat,retRes.Swarm(si(i),:),...
vecDim,psms_case,st);
            retRes.Best_P=A;
            retRes.Best_f=B;
            retRes.Best_model=C;
            retRes.Suc_train=2;
            break;
            catch
                 retRes.Suc_train=0;
                disp(lasterr);
                i=i+1;
            end
        end
%         retRes.Best_model=retAlgo.defmodel;
        
    end


% % % % % % % %     End of case 1
    case 2,
% % % %         In case we want to perform search of pre-processing methods
% % % % and feature selection algorithms for a fixed classifier
    [stc]=set_pars(child_n,retAlgo.donotincludethis);       
    if ischar(stc),
        fprintf('this classifier has been specified as do-not-consider\n');
        return;
    end
%     if stc.isKM, end
%     [st,max_prep,maxp1]=set_pars_prep('x');           
    [st,max_prep,maxp1]=set_pars_prep2('x');  %%% we can chose multiple prep.         
    [st,max_fs,maxp2]=set_pars_fs('x',retAlgo.donotincludethis);
% % %     Set the particles dimension
    retAlgo.dim=maxp1+maxp2+4+stc.npars;
    retRes.dim=retAlgo.dim;
% % %     Maximum values for the prepro/fs particle's dimension
% % %     Prepromethod
    csp.min_vals=[1,0,0,0];
    csp.max_vals=[max_prep,1,1,1];

%     csp.min_vals=[0,0];
%     csp.max_vals=[max_prep,1];
% % %     FS-method
    csf.min_vals=zeros(1,maxp2+1);
    csf.min_vals(1,2)=4;
    csf.max_vals=ones(1,maxp2+1);
    csf.max_vals(1,1)=max_fs;
    csf.max_vals(1,2)=vecDim-1;
% % % % In this setting preprocessing is performed before fs
        st1.min_vals=[csp.min_vals,csf.min_vals,0,1,stc.min_vals];
        st1.max_vals=[csp.max_vals,csf.max_vals,1,stc.maxclassif,stc.max_vals];
% % % % In this setting fs is performed before preprocessing
        st2.min_vals=[csf.min_vals,csp.min_vals,0,1,stc.min_vals];
        st2.max_vals=[csf.max_vals,csp.max_vals,1,stc.maxclassif,stc.max_vals];
        wsfi=10;
    for i=1:retAlgo.swarmsize
                wsf=rand;
        if wsf>0.5,
            st=st1;
        else
            st=st2;
        end

    for j=1:length(st1.min_vals)
        retRes.Swarm(i,j) = rand*(st.max_vals(j)-st.min_vals(j)) ...
            + st.min_vals(j);

    end
    retRes.Swarm(i,wsfi)=wsf;
            clear st wsf;
    end 
st{1}=st1;st{2}=st2;st{3}=stc;st{4}=wsfi;
    VStep = rand(retAlgo.swarmsize, retAlgo.dim);
    for hh = 1:retAlgo.swarmsize
    try, 
        [ndat, tm]=train(sbmodel,dat);
    catch,  ndat=dat; 
    end
    try
    [retRes.Swarm(hh,:), retRes.fSwarm(hh), xvar ] =  ...
        fitness(retAlgo,ndat,abs(retRes.Swarm(hh,:)),...
        vecDim,psms_case,st);
    catch
        disp(lasterr);
        retRes.fSwarm(hh)=100;
    end
        retRes.track(hh,:)=retRes.fSwarm(hh);
    clear ndat tm;
    end
    system(rlikepathcmd);
    % Initializing the Best positions matrix and
    % the corresponding function values
    retRes.PBest = retRes.Swarm;
    retRes.fPBest = retRes.fSwarm;

    % Finding best particle in initial population
    [retRes.fGBest, g] = min(retRes.fSwarm);
    retRes.lastbpf = retRes.fGBest;
    retRes.Best = retRes.Swarm(g,:); %Used to keep track of the Best particle ever
    retRes.Best_set=retRes.Best;
    retRes.fBest = retRes.fGBest;
    retRes.history = [0, retRes.fGBest];
    retRes.counter=hh+1;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                  THE  PSO  LOOP                          %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while( (success == 0) & (iter < retAlgo.maxiter) )
        iter = iter+1;
        fprintf('************ Iteration # %i ******************\n',iter);    
        str=[' Iteration=' num2str(iter)];      

        % Update the value of the inertia weight W
            if (iter<=w_varyfor) & (iter > 1)
            w_now = w_now - inertdec; %Change inertia weight
            end

        % Set GBest
        A = repmat(retRes.Swarm(g,:), retAlgo.swarmsize, 1); 
        B = A; %B wil be nBest (best neighbor) matrix

        % Generate Random Numbers
        R1 = rand(retAlgo.swarmsize, retAlgo.dim);
        R2 = rand(retAlgo.swarmsize, retAlgo.dim);

        % Calculate Velocity
        VStep = w_now*VStep + retAlgo.c1*R1.*(retRes.PBest-retRes.Swarm)...
            + retAlgo.c2*R2.*(A-retRes.Swarm);

        % Apply Vmax Operator for v > Vmax
        changeRows = VStep > retAlgo.vmax;
        VStep(find(changeRows)) = retAlgo.vmax;
        % Apply vmax Operator for v < -vmax
        changeRows = VStep < -retAlgo.vmax;
        VStep(find(changeRows)) = -retAlgo.vmax;

        % ::UPDATE POSITIONS OF PARTICLES::
        retRes.Swarm = retRes.Swarm + retAlgo.chi * VStep;    % Evaluate new Swarm    

        for hh = 1:retAlgo.swarmsize
        try,        
            [ndat, tm]=train(sbmodel,dat);
        catch
            ndat=dat;
        end
        try
%          ofint=find(retRes.Swarm(:,wsfi)>1 | retRes.Swarm(:,wsfi)<0);
%          retRes.Swarm(ofint,wsfi)=rand(size(ofint));
        ofint=find(retRes.Swarm(:,wsfi)>1);
        retRes.Swarm(ofint,wsfi)=0.9;
        ofint=find(retRes.Swarm(:,wsfi)<0);
        retRes.Swarm(ofint,wsfi)=0.1;

    [retRes.Swarm(hh,:), retRes.fSwarm(hh), xvar ] =  fitness(retAlgo,ndat,abs(retRes.Swarm(hh,:)),...
        vecDim,psms_case,st);
            
        catch
            disp(lasterr);
            retRes.fSwarm(hh)=100;
        end
        clear ndat tm;

            retRes.track(retRes.counter,:)=retRes.fSwarm(hh);
            retRes.counter=retRes.counter+1;
        end
    system(rlikepathcmd);
        % Updating the best position for each particle
        changeRows = retRes.fSwarm < retRes.fPBest;
        retRes.fPBest(find(changeRows)) = retRes.fSwarm(find(changeRows));
        retRes.PBest(find(changeRows), :) = retRes.Swarm(find(changeRows), :);

        % Updating index g
        [retRes.fGBest, g] = min(retRes.fPBest);

        %Update Best. Only if fitness has improved.   
        if retRes.fGBest < retRes.lastbpf
            [retRes.fBest, b] = min(retRes.fPBest);
            retRes.Best = retRes.PBest(b,:);
        end

%         [valid_particle] = validate_particle(retAlgo,Best, vecDim);
%         [retRes,base_model]=create_CLOP_model(retAlgo,valid_particle);

        if (mod(iter,retAlgo.save_every)==0)
            retRes.Best_set=[retRes.Best_set; retRes.Best];       
            retRes.history_best(:,iter*retAlgo.swarmsize+retAlgo.swarmsize)...
                =retRes.fBest;
        end
        save psms_bestmodels.mat retRes;
%             if retAlgo.animation
%         [fworst, worst] = max(retRes.fGBest);
%         DrawSwarmPSMS(retRes.Swarm, retAlgo.swarmsize, iter, retAlgo.dim, retRes.Swarm(g,:), vizAxes);
%     end

%         retRes = {};
        %%TERMINATION%%
        if abs(retRes.fGBest-0) <= retAlgo.terminate_err     %GBest
            success = 1;
        elseif abs(retRes.fBest-0)<=retAlgo.terminate_err %Best
            success = 1;
        else
            retRes.lastbpf = retRes.fGBest; %To be used to find Best
        end

        if retAlgo.algorithm.verbosity
            str = sprintf('PSMS, iteration No. %d of a total of %d', ...
                iter, retAlgo.maxiter);
            disp(str)
        end  

    end  %%% end while - iterations    

        try
    [retRes.Best_P, retRes.Best_f, retRes.Best_model] =...
        fitness(retAlgo,dat,retRes.Best,...
        vecDim,psms_case,st);
            retRes.Suc_train=1;
    catch
disp(lasterr);
        i=1;
        [ss,si]=sort(retRes.fSwarm);
        while (i<=size(retRes.Swarm,1))
            try
        [A,B,C]=fitness(retAlgo,dat,retRes.Swarm(si(i),:),...
vecDim,psms_case,st);
            retRes.Best_P=A;
            retRes.Best_f=B;
            retRes.Best_model=C;
            retRes.Suc_train=2;
            break;
            catch
                retRes.Suc_train=0;
                disp(lasterr);
                i=i+1;
            end
        end
%         retRes.Best_model=retAlgo.defmodel;
        
    end
    
% % %     End of case 2

%         return;
    case 3,   
%                 solsfname='load add_data_fms_1.mat';
%             load add_data_fms_1.mat;
% % % %         Full model selection case
% % % %         In case we want to perform search of pre-processing methods
% % % % and feature selection algorithms for a fixed classifier
    classifier=round(rand.*10);
    if (classifier<=0 || classifier>12)
        classifier=2;
    end
    [stc]=set_pars_fms(classifier,retAlgo.donotincludethis);       
%     if stc.isKM, end
%     [st,max_prep,maxp1]=set_pars_prep('x');           
    [st,max_prep,maxp1]=set_pars_prep2('x');  %%% we can chose multiple prep.         
    [st,max_fs,maxp2]=set_pars_fs('x',retAlgo.donotincludethis);
% % %     Set the particles dimension
    retAlgo.dim=maxp1+maxp2+4+stc.maxclassif_pars;
    retRes.dim=retAlgo.dim;
% % %     Maximum values for the prepro/fs particle's dimension
% % %     Prepromethod
    csp.min_vals=[1,0,0,0];
    csp.max_vals=[max_prep,1,1,1];

%     csp.min_vals=[0,0];
%     csp.max_vals=[max_prep,1];
% % %     FS-method
    csf.min_vals=zeros(1,maxp2+1);
    csf.min_vals(1,2)=4;
    csf.max_vals=ones(1,maxp2+1);
    csf.max_vals(1,1)=max_fs;
    csf.max_vals(1,2)=vecDim-1;
    classi.min_vals=zeros(1,stc.maxclassif_pars);
    classi.max_vals=ones(1,stc.maxclassif_pars);
% % % % In this setting preprocessing is performed before fs
        st1.min_vals=[csp.min_vals,csf.min_vals,0,1,classi.min_vals];
        st1.max_vals=[csp.max_vals,csf.max_vals,1,stc.maxclassif,classi.max_vals];
% % % % In this setting fs is performed before preprocessing
        st2.min_vals=[csf.min_vals,csp.min_vals,0,1,classi.min_vals];
        st2.max_vals=[csf.max_vals,csp.max_vals,1,stc.maxclassif,classi.max_vals];
        wsfi=10;
    for i=1:retAlgo.swarmsize
        wsf=rand;
        if wsf>0.5,
            st=st1;
        else
            st=st2;
        end

    for j=1:length(st1.min_vals)
        retRes.Swarm(i,j) = rand*(st.max_vals(j)-st.min_vals(j)) ...
            + st.min_vals(j);

    end
        retRes.Swarm(i,wsfi)=wsf;
            clear st wsf;
    end 
st{1}=st1;st{2}=st2;st{3}=stc;st{4}=wsfi;
    VStep = rand(retAlgo.swarmsize, retAlgo.dim);
    for hh = 1:retAlgo.swarmsize
    try, [ndat, tm]=train(sbmodel,dat);
    catch,  ndat=dat; 
    end
    try
    [retRes.Swarm(hh,:), retRes.fSwarm(hh), xvar ] =  ...
        fitness(retAlgo,ndat,abs(retRes.Swarm(hh,:)),...
        vecDim,psms_case,st);
        retRes.solutionstried(hh,:)=retRes.Swarm(hh,:);
    retRes.clasif_selected(hh,:)=retRes.Swarm(hh,wsfi+1);
    retRes.first_fs(hh,:)=retRes.Swarm(hh,wsfi);
    if retRes.first_fs(hh,:)>0.5,        
        retRes.fs(hh,:)=retRes.Swarm(hh,5);
        retRes.pp(hh,:)=retRes.Swarm(hh,1);
    else
        retRes.fs(hh,:)=retRes.Swarm(hh,1);
        retRes.pp(hh,:)=retRes.Swarm(hh,6);
    end
    catch
        disp(lasterr);
        retRes.fSwarm(hh)=100;
    end
        retRes.track(hh,:)=retRes.fSwarm(hh);
    clear ndat tm;
    end
%         retRes.solutionstried(1,:).swarm=retRes.Swarm;

    system(rlikepathcmd);
    % Initializing the Best positions matrix and
    % the corresponding function values
    retRes.PBest = retRes.Swarm;
    retRes.fPBest = retRes.fSwarm;

    % Finding best particle in initial population
    [retRes.fGBest, g] = min(retRes.fSwarm);
    retRes.lastbpf = retRes.fGBest;
    retRes.Best = retRes.Swarm(g,:); %Used to keep track of the Best particle ever
    retRes.Best_set=retRes.Best;
    retRes.fBest = retRes.fGBest;
    retRes.history = [0, retRes.fGBest];
    retRes.counter=hh+1;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                  THE  PSO  LOOP                          %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while( (success == 0) & (iter < retAlgo.maxiter) )
        iter = iter+1;
        fprintf('************ Iteration # %i ******************\n',iter);    
        str=[' Iteration=' num2str(iter)];      

        % Update the value of the inertia weight W
            if (iter<=w_varyfor) & (iter > 1)
            w_now = w_now - inertdec; %Change inertia weight
            end

        % Set GBest
        A = repmat(retRes.Swarm(g,:), retAlgo.swarmsize, 1); 
        B = A; %B wil be nBest (best neighbor) matrix

        % Generate Random Numbers
        R1 = rand(retAlgo.swarmsize, retAlgo.dim);
        R2 = rand(retAlgo.swarmsize, retAlgo.dim);

        % Calculate Velocity
        VStep = w_now*VStep + retAlgo.c1*R1.*(retRes.PBest-retRes.Swarm)...
            + retAlgo.c2*R2.*(A-retRes.Swarm);

        % Apply Vmax Operator for v > Vmax
        changeRows = VStep > retAlgo.vmax;
        VStep(find(changeRows)) = retAlgo.vmax;
        % Apply vmax Operator for v < -vmax
        changeRows = VStep < -retAlgo.vmax;
        VStep(find(changeRows)) = -retAlgo.vmax;

        % ::UPDATE POSITIONS OF PARTICLES::
        retRes.Swarm = retRes.Swarm + retAlgo.chi * VStep;    % Evaluate new Swarm    

        for hh = 1:retAlgo.swarmsize
        try,         [ndat, tm]=train(sbmodel,dat);
        catch
            ndat=dat;
        end
        try
        ofint=find(retRes.Swarm(:,wsfi)>1);
        retRes.Swarm(ofint,wsfi)=0.9;
        ofint=find(retRes.Swarm(:,wsfi)<0);
        retRes.Swarm(ofint,wsfi)=0.1;

%             
%          ofint=find(retRes.Swarm(:,wsfi)>1 | retRes.Swarm(:,wsfi)<0);
%          retRes.Swarm(ofint,wsfi)=rand(size(ofint));
% %         end
    [retRes.Swarm(hh,:), retRes.fSwarm(hh), xvar ] =  fitness(retAlgo,ndat,abs(retRes.Swarm(hh,:)),...
        vecDim,psms_case,st);
        retRes.solutionstried(retRes.counter,:)=retRes.Swarm(hh,:);
     retRes.clasif_selected(retRes.counter,:)=retRes.Swarm(hh,wsfi+1);
    retRes.first_fs(retRes.counter,:)=retRes.Swarm(hh,wsfi);
    if retRes.first_fs(retRes.counter,:)>0.5,        
        retRes.fs(retRes.counter,:)=retRes.Swarm(hh,5);
        retRes.pp(retRes.counter,:)=retRes.Swarm(hh,1);
    else
        retRes.fs(retRes.counter,:)=retRes.Swarm(hh,1);
        retRes.pp(retRes.counter,:)=retRes.Swarm(hh,6);
    end
             
        catch
            disp(lasterr);
            retRes.fSwarm(hh)=100;
        end
        clear ndat tm;

            retRes.track(retRes.counter,:)=retRes.fSwarm(hh);
            retRes.counter=retRes.counter+1;
        end
%         retRes.solutionstried(iter,:).swarm=retRes.Swarm;

        system(rlikepathcmd);
        % Updating the best position for each particle
        changeRows = retRes.fSwarm < retRes.fPBest;
        retRes.fPBest(find(changeRows)) = retRes.fSwarm(find(changeRows));
        retRes.PBest(find(changeRows), :) = retRes.Swarm(find(changeRows), :);

        % Updating index g
        [retRes.fGBest, g] = min(retRes.fPBest);

        %Update Best. Only if fitness has improved.   
        if retRes.fGBest < retRes.lastbpf
            [retRes.fBest, b] = min(retRes.fPBest);
            retRes.Best = retRes.PBest(b,:);
        end

%         [valid_particle] = validate_particle(retAlgo,Best, vecDim);
%         [retRes,base_model]=create_CLOP_model(retAlgo,valid_particle);

        if (mod(iter,retAlgo.save_every)==0)
            retRes.Best_set=[retRes.Best_set; retRes.Best];       
            retRes.history_best(:,iter*retAlgo.swarmsize+retAlgo.swarmsize)...
                =retRes.fBest;
        end
        save psms_bestmodels.mat retRes;
%     if retAlgo.animation
%         [fworst, worst] = max(retRes.fGBest);
% %         [axr]=test(bmod,data(retRes.Swarm));
% %         DrawSwarmPSMS(axr.X, retAlgo.swarmsize, iter, 2, axr.X(g,:), vizAxes);
% %         DrawSwarmPSMS(retRes.Swarm, retAlgo.swarmsize, iter, retAlgo.dim, retRes.Swarm(g,:),wsfi, vizAxes);
%         DrawSwarmPSMS_II(retRes.Swarm, retAlgo.swarmsize, iter, retAlgo.dim, retRes.Swarm(g,:),wsfi, vizAxes);
%     end

%         retRes = {};
        %%TERMINATION%%
        if abs(retRes.fGBest-0) <= retAlgo.terminate_err     %GBest
            success = 1;
        elseif abs(retRes.fBest-0)<=retAlgo.terminate_err %Best
            success = 1;
        else
            retRes.lastbpf = retRes.fGBest; %To be used to find Best
        end

        if retAlgo.algorithm.verbosity
            str = sprintf('PSMS, iteration No. %d of a total of %d', ...
                iter, retAlgo.maxiter);
            disp(str)
        end  

    end  %%% end while - iterations    
%     end

        try
    [retRes.Best_P, retRes.Best_f, retRes.Best_model] =...
        fitness(retAlgo,dat,retRes.Best,...
        vecDim,psms_case,st);
            retRes.Suc_train=1;
    catch
disp(lasterr);
        i=1;
         [ss,si]=sort(retRes.fSwarm);
        while (i<=size(retRes.Swarm,1))
            try               
        [A,B,C]=fitness(retAlgo,dat,retRes.Swarm(si(i),:),...
vecDim,psms_case,st);
            retRes.Best_P=A;
            retRes.Best_f=B;
            retRes.Best_model=C;
            retRes.Suc_train=2;
            break;
            catch
                retRes.Suc_train=0;
                disp(lasterr);
                i=i+1;
            end
        end
%         retRes.Best_model=retAlgo.defmodel;
        
    end
    
% %         try
%     [retRes.Best_P, retRes.Best_f, retRes.Best_model] =...
%         fitness(retAlgo,dat,retRes.Best,...
%         vecDim,psms_case,st);
%             retRes.Suc_train=1;
% %     catch
% %         disp(lasterr);
% %         retRes.Best_model=retAlgo.defmodel;
% %                 retRes.Suc_train=0;
% %     end
    
% % %     End of case 3


        
%         return;
end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                  END  OF PSO  LOOP                       %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if retAlgo.visualize
        figure;
    plot(retRes.track,'g','LineWidth',2,'Marker','*','MarkerEdgeColor','r');set(gcf,'Color','w');
    gcf; hold on; %stem(retRes.history_best,'MarkerEdgeColor','r');
    % figure(1); hold on; plot(history_best,'.','MarkerEdgeColor','b');plot(history_best,'o','MarkerEdgeColor','r');
    title('Fitness function evaluation');
    xlabel('Particles fitness value');ylabel('CV-BER');
    xlim([0 size(retRes.track,1)+1]);
    ylim([0,1]);
    line(1:length(retRes.track),retRes.fBest.*ones(1,length(retRes.track)),'LineWidth',2);
%     ylim([(min(retRes.track)-0.15) (max(retRes.track)+0.15)]);
    legend('fitness per particle per iteration','best-fitness');
    % pause(5);close all;
    hold off;
    end
    
% % % In case we should return an ensemble
if (retAlgo.create_ensemble==1)

%             try
%     [retRes.Best_P, retRes.Best_f, retRes.Best_model] =...
%         fitness(retAlgo,dat,retRes.Best,...
%         vecDim,psms_case,st);
%             retRes.Suc_train=1;
%     catch
%         disp(lasterr);
%         i=1;
%         [ss,si]=sort(retRes.fSwarm);
%         while (i<=size(retRes.Swarm,1))
%             try
%         [A,B,C]=fitness(retAlgo,dat,retRes.Swarm(si(i),:),...
% vecDim,psms_case,st);
%             retRes.Best_P=A;
%             retRes.Best_f=B;
%             retRes.Best_model=C;
%             retRes.Suc_train=2;
%             break;
%             catch
%                  retRes.Suc_train=0;
%                 disp(lasterr);
%                 i=i+1;
%             end
%         end
% %         retRes.Best_model=retAlgo.defmodel;
%         
%     end

    
    
for i=1:size(retRes.Best_set,1)
    try
        [retRes.Best_Pe{i}, retRes.Best_fe{i}, retRes.Best_modele{i}] =...
        fitness(retAlgo,dat,retRes.Best_set(i,:),...
        vecDim,psms_case,st);
                    retRes.Suc_traine(i)=1;
    catch
        disp(lasterr);
        retRes.Best_modele{i}=retAlgo.defmodel;
                retRes.Suc_traine(i)=0;
    end
end
   retRes.ensemble=ensemble(retRes.Best_modele);

% % %    An ensemble with the final swarm
elseif (retAlgo.create_ensemble==2)

for i=1:retAlgo.swarmsize
   try
        [retRes.Best_Pe{i}, retRes.Best_fe{i}, retRes.Best_modele{i}] =...
        fitness(retAlgo,dat,retRes.Swarm(i,:),...
        vecDim,psms_case,st);
                    retRes.Suc_traine(i)=1;
    catch
        disp(lasterr);
        retRes.Best_modele{i}=retAlgo.defmodel;
                        retRes.Suc_traine(i)=0;
    end
end
   retRes.ensemble=ensemble(retRes.Best_modele);   
% % % Or the best model
else
    retRes.ensemble=[];    
end

    
%     if retAlgo.create_ensemble,
%         
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      FUNCTIONS                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [st]=set_pars(child_n,notthis)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % CLASSIFIERS PARAMETERS  % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
no_pars_classifiers={'zarbi','naive','klogistic','gkridge'};
pars_classifiers={'logitboost','neural','svc','kridge','rf','lssvm',...
    'rf_as','gb_rf'};
classif_not_supported_yet={'gentleboost','prune'};
st.maxclassif_pars=8;

    
[xa,xb]=ismember(child_n,no_pars_classifiers);
[xc,xd]=ismember(child_n,pars_classifiers);
[xe,xf]=ismember(child_n,classif_not_supported_yet);
if (xc), 
    st.maxclassif=length(pars_classifiers);

switch xd,
    case 1,
% % % % Parameter definitions for logitboost
st.method='logitboost';
st.npars=3;
st.parameters={'units', 'shrinkage', 'depth'};
st.max_vals=[1000,2,5];
st.min_vals=[10,0.1,1];
st.real_valued=[0,1,0];
st.binary=[0,0,0];
st.isKM=false;
    case 2,
% % % % Parameter definitions for neural
st.method='neural';
st.npars=4;
st.parameters={'units', 'shrinkage', 'balance', 'maxiter'};
st.max_vals=[25,2,1,250];
st.min_vals=[1,0.0001,0,10];
st.real_valued=[0,1,0,0];
st.binary=[0,0,1,0];
st.isKM=false;
    case 3,
% % % % Parameter definitions for SVM
st.method='svc';
st.npars=4;
st.parameters={'coef0', 'degree', 'gamma', 'shrinkage'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage','k'};
st.min_vals=[0,1,0.0001,0.0001];
st.max_vals=[1,3,100,2];
st.real_valued=[0,0,1,1];
st.binary=[0,0,0,0];
st.isKM=true;
    case 4,
% % % % Parameter definitions for K-ridge
st.method='kridge';
st.npars=4;
st.parameters={'coef0', 'degree', 'gamma', 'shrinkage'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage','k'};
st.min_vals=[0,0,0,0.0001];
st.max_vals=[1,3,10,2];
st.real_valued=[0,0,1,1];
st.binary=[0,0,0,0];
st.isKM=true;
    case 5,
% % % % Parameter definitions for RF
st.method='rf';
st.npars=3;
st.parameters={'units', 'mtry', 'balance'};
st.min_vals=[10,1,0];
st.max_vals=[250,10,1];
st.real_valued=[0,0,0];
st.binary=[0,0,1];
st.isKM=false;
    case 6,
% % % % Parameter definitions for LSSVM
st.method='lssvm';
st.npars=5;
st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
    'balance'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
%     'balance','k'};
st.min_vals=[0,0,0,0.0001,0];
st.max_vals=[1,3,10,2,1];
st.real_valued=[0,0,1,1,0];
st.binary=[0,0,0,0,1];
st.isKM=true;
   case 7,
% % % % Parameter definitions for LSSVM
st.method='rf_as';
st.npars=7;
st.parameters={'units', 'depth', ...
    'hypNum','subFeatNum','subSampRatio', 'balance','cutoff'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
%     'balance','k'};
st.min_vals=[1,1,1,1,0,0,0.1];
st.max_vals=[250,5,50,10,1,1,0.6];
st.real_valued=[0,0,0,0,1,0,1];
st.binary=[0,0,0,0,0,1,0];
st.isKM=false;
 case 8,
% % % % Parameter definitions for LSSVM
st.method='gb_rf';
st.npars=8;
st.parameters={'baseNum','units', 'depth', ...
    'hypNum','subFeatNum','subSampRatio', 'balance','cutoff'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
%     'balance','k'};
st.min_vals=[10,1,1,1,1,0,0,0.1];
st.max_vals=[200,250,5,50,10,1,1,0.6];
st.real_valued=[0,0,0,0,0,1,0,1];
st.binary=[0,0,0,0,0,0,1,0];
st.isKM=false;
end
elseif (xa), 
        st.maxclassif=length(no_pars_classifiers);
        st.min_vals=[];
        st.max_vals=[];
        st.parameters=[];
        st.real_valued=[];
        st.binary=[];
        st.isKM=[];

    switch xb,
        case 1,
        st.npars=0;
        st.method='zarbi';    
        case 2,
        st.npars=0;
        st.method='naive';    
        case 3,
        st.npars=0;
        st.method='klogistic';    
        case 4,
        st.npars=0;
        st.method='gkridge';    
    end
    
elseif (xe), st='not-supported'; 
end

if (~isempty(notthis) && xc)
    [aa,bb]=setdiff(pars_classifiers,notthis);
        if isempty(intersect(xd,bb)),
       st='not-supported'; 
        end
    
end

function [st]=set_pars_fms(child_n,notthis)   
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % CLASSIFIERS PARAMETERS  % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
all_classifiers={'zarbi','naive','klogistic','gkridge','logitboost',...
    'neural','svc','kridge','rf','lssvm','rf_as','gb_rf'};

classif_not_supported_yet={'gentleboost','prune'};
st.maxclassif_pars=8;
st.maxclassif=length(all_classifiers);


% [xa,xb]=ismember(child_n,no_pars_classifiers);
% [xc,xd]=ismember(child_n,pars_classifiers);
% [xe,xf]=ismember(child_n,classif_not_supported_yet);
% if (xc), 
    

switch child_n,
        case 1,
        st.npars=0;
        st.method='zarbi';    
        st.min_vals=[];
        st.max_vals=[];
        st.parameters=[];
        st.real_valued=[];
        st.binary=[];
        st.isKM=[];
        case 2,
        st.npars=0;
        st.method='naive';    
        st.min_vals=[];
        st.max_vals=[];
        st.parameters=[];
        st.real_valued=[];
        st.binary=[];
        st.isKM=[];

        case 3,
        st.npars=0;
        st.method='klogistic';    
        st.min_vals=[];
        st.max_vals=[];
        st.parameters=[];
        st.real_valued=[];
        st.binary=[];
        st.isKM=[];

        case 4,
        st.npars=0;
        st.method='gkridge';    
        st.min_vals=[];
        st.max_vals=[];
        st.parameters=[];
        st.real_valued=[];
        st.binary=[];
        st.isKM=[];
     case 5,
    % % % % Parameter definitions for logitboost
    st.method='logitboost';
    st.npars=3;
    st.parameters={'units', 'shrinkage', 'depth'};
    st.max_vals=[1000,2,5];
    st.min_vals=[10,0.1,1];
    st.real_valued=[0,1,0];
    st.binary=[0,0,0];
    st.isKM=false;
        case 6,
    % % % % Parameter definitions for neural
    st.method='neural';
    st.npars=4;
    st.parameters={'units', 'shrinkage', 'balance', 'maxiter'};
    st.max_vals=[25,2,1,250];
    st.min_vals=[1,0.0001,0,10];
    st.real_valued=[0,1,0,0];
    st.binary=[0,0,1,0];
    st.isKM=false;
        case 7,
    % % % % Parameter definitions for SVM
    st.method='svc';
    st.npars=4;
    st.parameters={'coef0', 'degree', 'gamma', 'shrinkage'};
    % st.parameters={'coef0', 'degree', 'gamma', 'shrinkage','k'};
  st.min_vals=[0,1,0.0001,0.0001];
st.max_vals=[1,3,100,2];
    st.real_valued=[0,0,1,1];
    st.binary=[0,0,0,0];
    st.isKM=true;
        case 8,
    % % % % Parameter definitions for K-ridge
    st.method='kridge';
    st.npars=4;
    st.parameters={'coef0', 'degree', 'gamma', 'shrinkage'};
    % st.parameters={'coef0', 'degree', 'gamma', 'shrinkage','k'};
    st.min_vals=[0,0,0,0.0001];
    st.max_vals=[1,3,10,2];
    st.real_valued=[0,0,1,1];
    st.binary=[0,0,0,0];
    st.isKM=true;
        case 9,
    % % % % Parameter definitions for RF
    st.method='rf';
    st.npars=3;
    st.parameters={'units', 'mtry', 'balance'};
    st.min_vals=[10,1,0];
    st.max_vals=[1000,10,1];
    st.real_valued=[0,0,0];
    st.binary=[0,0,1];
    st.isKM=false;
        case 10,
    % % % % Parameter definitions for LSSVM
    st.method='lssvm';
    st.npars=5;
    st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
        'balance'};
    % st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
    %     'balance','k'};
    st.min_vals=[0,0,0,0.0001,0];
    st.max_vals=[1,3,10,2,1];
    st.real_valued=[0,0,1,1,0];
    st.binary=[0,0,0,0,1];
    st.isKM=true;
     case 11,
% % % % Parameter definitions for LSSVM
st.method='rf_as';
st.npars=7;
st.parameters={'units', 'depth', ...
    'hypNum','subFeatNum','subSampRatio', 'balance','cutoff'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
%     'balance','k'};
st.min_vals=[1,1,1,1,0,0,0];
st.max_vals=[250,5,50,10,1,1,1];
st.real_valued=[0,0,0,0,1,0,1];
st.binary=[0,0,0,0,0,1,0];
st.isKM=false;
 case 12,
% % % % Parameter definitions for LSSVM
st.method='gb_rf';
st.npars=8;
st.parameters={'baseNum','units', 'depth', ...
    'hypNum','subFeatNum','subSampRatio', 'balance','cutoff'};
% st.parameters={'coef0', 'degree', 'gamma', 'shrinkage', ...
%     'balance','k'};
st.min_vals=[10,1,1,1,1,0,0,0];
st.max_vals=[200,250,5,50,10,1,1,1];
st.real_valued=[0,0,0,0,0,1,0,1];
st.binary=[0,0,0,0,0,0,1,0];
st.isKM=false;
end
if (~isempty(notthis))        
        [xa,xy]=setdiff(all_classifiers,notthis);
        if isempty(intersect(child_n,xy)),
        st.npars=0;
        st.method='zarbi';    
        st.min_vals=[];
        st.max_vals=[];
        st.parameters=[];
        st.real_valued=[];
        st.binary=[];
        st.isKM=[];
        end
end
%     elseif (xe), st='not-supported'; 
% end

function [st,nmets,maxp]=set_pars_prep(child_n)   
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % PREPROCESSING PARAMETERS  % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
prepro_clop_objs={'normalize','standardize','shif_n_scale'};
nmets=length(prepro_clop_objs);
% % % % Maximum number of hyperparameters
maxp=1;

if isnumeric(child_n)
    xb=child_n;
    xa=1;
else
[xa,xb]=ismember(child_n,prepro_clop_objs);
end

% [xa,xb]=ismember(child_n,prepro_clop_objs);
if xa,
switch xb,
    case 0,
    st.method='no';    
    case 1,
% % % % Parameter definitions for normalize
st.method='normalize';
st.npars=1;
st.parameters={'center'};
st.max_vals=[1];
st.min_vals=[0];
st.real_valued=[0];
st.binary=[1];
    case 2,
% % % % Parameter definitions for standardize
st.method='standardize';
st.npars=1;
st.parameters={'center'};
st.max_vals=[1];
st.min_vals=[0];
st.real_valued=[0];
st.binary=[1];
    case 3,
% % % % Parameter definitions for shift_n_scale
st.method='shift_n_scale';
st.npars=1;
st.parameters={'take_log'};
st.max_vals=[1];
st.min_vals=[0];
st.real_valued=[0];
st.binary=[1];
end
else
    st=[];
end
function [st,nmets,maxp]=set_pars_prep2(child_n)   
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % PREPROCESSING PARAMETERS  % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
st.comb=[0,0,0;0,0,1;0,1,0;0,1,1;1,0,0;1,0,1;1,1,0;1,1,1];
st.npars=3;
st.max_vals=[8,1,1,1];
st.min_vals=[1,0,0,0];
st.real_valued=[0,0,0,0];
st.binary=[0,1,1,1];
st.methods={'normalize','standardize','shift_n_scale'};
st.parameter={'center','center','take_log'};
nmets=length(st.comb);
% % % % Maximum number of hyperparameters
maxp=3;

% 
if isnumeric(child_n)
    st.method=st.comb(child_n,:);
end

function [st,nmets,maxp]=set_pars_fs(child_n,notthis)   
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % FEATURE SELECTION PARAMETERS  % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
fs_clop_objs={'Ftest','Ttest','aucfs','odds_ratio','relief',...
    'rffs','svcrfe','Pearson','Zfilter','gs','s2n','pc_extract'};
nmets=length(fs_clop_objs);
% % % % Maximum number of hyperparameters
maxp=4;
fs_clop_ns={'rmconst','probe'};
if isnumeric(child_n)
    xb=child_n;
    xa=1;
else
[xa,xb]=ismember(child_n,fs_clop_objs);
end
if xa,
switch xb,
    case 0,
    st.method='no';    
    case 1,
    % % % % Parameter definitions for Ftest
    st.method='Ftest';
    st.npars=4;
    st.parameters={'f_max','w_min','pval_max','fdr_max'};
    st.max_vals=[1000,1,1,1];
    st.min_vals=[1,0,0,0];
    st.real_valued=[0,1,1,1];
    st.binary=[0,0,0,0];
    st.to_normalize=[0,1,1,1];    
%     b.W./sum(b.W)
    case 2,
    % % % % Parameter definitions for Ttest
    st.method='Ttest';
    st.npars=4;
    st.parameters={'f_max','w_min','pval_max','fdr_max'};
    st.max_vals=[1000,1,1,1];
    st.min_vals=[2,0,0,0];
    st.real_valued=[0,1,1,1];
    st.binary=[0,0,0,0];
    st.to_normalize=[0,1,1,1];
    case 3,
    % % % % Parameter definitions for AUCFS
    st.method='aucfs';
    st.npars=4;
    st.parameters={'f_max','w_min','pval_max','fdr_max'};
    st.max_vals=[1000,1,1,1];
    st.min_vals=[2,0,0,0];
    st.real_valued=[0,1,1,1];
    st.binary=[0,0,0,0];
    st.to_normalize=[0,1,1,1];
    case 4,
    % % % % Parameter definitions for odds_ratio
    st.method='odds_ratio';
    st.npars=4;
    st.parameters={'f_max','w_min','pval_max','fdr_max'};
    st.max_vals=[1000,1,1,1];
    st.min_vals=[2,0,0,0];
    st.real_valued=[0,1,1,1];
    st.binary=[0,0,0,0];
    st.to_normalize=[0,1,1,1];
    case 5,
    % % % % Parameter definitions for relief
    st.method='relief';
    st.npars=3;
    st.parameters={'f_max','w_min','k_num'};
    st.max_vals=[1000,1,10];
    st.min_vals=[2,0,2];
    st.real_valued=[0,1,0];
    st.binary=[0,0,0];
    st.to_normalize=[0,1,0];
    case 6,
    % % % % Parameter definitions for rf
    st.method='rffs';
    st.npars=2;
    st.parameters={'f_max','w_min'};
    st.max_vals=[1000,1];
    st.min_vals=[2,0];
    st.real_valued=[0,1];
    st.binary=[0,0];
    st.to_normalize=[0,1];
    case 7,
    % % % % Parameter definitions for SVCREF
    st.method='svcrfe';
    st.npars=1;
    st.parameters={'f_max'};
    st.max_vals=[1000];
    st.min_vals=[2];
    st.real_valued=[0];
    st.binary=[0];
    st.to_normalize=[0];
    case 8,
    % % % % Parameter definitions for Pearson
    st.method='Pearson';
    st.npars=4;
    st.parameters={'f_max','w_min','pval_max','fdr_max'};
    st.max_vals=[1000,1,1,1];
    st.min_vals=[2,0,0,0];
    st.real_valued=[0,1,1,1];
    st.binary=[0,0,0,0];
    st.to_normalize=[0,1,1,1];
    case 9,
    % % % % Parameter definitions for Pearson
    st.method='Zfilter';
    st.npars=2;
    st.parameters={'f_max','w_min'};
    st.max_vals=[1000,1];
    st.min_vals=[2,0];
    st.real_valued=[0,1];
    st.binary=[0,0];
    st.to_normalize=[0,1];
    case 10,
    % % % % Parameter definitions for Pearson
    st.method='gs';
    st.npars=1;
    st.parameters={'f_max'};
    st.max_vals=[1000];
    st.min_vals=[2];
    st.real_valued=[0];
    st.binary=[0];
    st.to_normalize=[0];
    case 11,
    % % % % Parameter definitions for Pearson
    st.method='s2n';
    st.npars=2;
    st.parameters={'f_max','w_min'};
    st.max_vals=[1000,1];
    st.min_vals=[2,0];
    st.real_valued=[0,1];
    st.binary=[0,0];
    st.to_normalize=[0,1];
    case 12,
    % % % % Parameter definitions for PCA
    st.method='pc_extract';
    st.npars=1;
    st.parameters={'f_max'};
    st.max_vals=[1000];
    st.min_vals=[2];
    st.real_valued=[0];
    st.binary=[0];
    st.to_normalize=[0];

end
else st=[];
end %%% end if xa
if (~isempty(notthis))        
        [xa,xy]=setdiff(fs_clop_objs,notthis);
        if isempty(intersect(child_n,xy)),
         % % % % Parameter definitions for PCA
     st.method='no';    
        end
end

% % % % % % Fitness function for PSMS   % % % % % % % % % % % %
function [Swarm, fSwarm, cmodel] =  fitness(retAlgo,ndat,Swarm,...
        vecDim,psms_case,st);
    switch psms_case
        case 1, 
            longit=length(st.parameters);
            tmodel=['chain({' st.method '({'];
            for bi=1:longit
                cpar=min(Swarm(bi),st.max_vals(bi));
                cpar=max(cpar,st.min_vals(bi));
                if ~st.real_valued(bi)
                    cpar=round(cpar);
                    if (st.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
                end
                tmodel=[tmodel '''' st.parameters{bi} '=' num2str(cpar)...
                    ''','];
%                 nSwarm(bi)=cpar;
                Swarm(bi)=cpar;                
                clear cpar;
            end
%             if st.isKM,
%                 nSwarm(end+1)=cpar1;
%             end
            tmodel(end)='}';
            tmodel=[tmodel '),bias});'];
%             tmodel=[tmodel '),bias});'];
            cmodel=eval(tmodel);
% % %       Build the CB model             
            cv_model = cv(cmodel, {['folds=' num2str(retAlgo.foldnum)], ...
                'store_all=0'});
            cv_model.verbosity=retAlgo.verbosity;
            % Call the method "train" of the object "cv_model":
            cv_output   = train(cv_model, ndat); 
            % Collect the results
            OutX = []; OutY = []; ber =[];
            for kk = 1:retAlgo.foldnum,
                outX    = cv_output.child{kk}.X;
                outY    = cv_output.child{kk}.Y;
                OutX    = [OutX; outX]; 
                OutY    = [OutY; outY]; 
                ber(kk) = balanced_errate(outX, outY);
            end
                        correct_bias=0;
                        % Check whether to do a bias correction
            if isa(cmodel, 'chain')
                chain_length=length(cmodel.child);
                if isa(cmodel{chain_length}, 'bias')
                    correct_bias=1;
                end
            end
            if correct_bias
                % Train a bias model with the cv outputs
                [d, cv_bias]=train(bias, data(OutX, OutY));            
                % Compensate the bias
                OutX=OutX+cv_bias.b0;
            end


%             % Train a bias model with the cv outputs
%             [d, cv_bias]=train(bias, data(OutX, OutY));            
%             % Compensate the bias
%             OutX=OutX+cv_bias.b0;
                        % Compute the CV error rate and error bar
            fSwarm   = balanced_errate(OutX, OutY);
            cv_ebar    = std(ber,1)/sqrt(retAlgo.foldnum);
            fprintf('CV BER (Inside PSMS) =%5.2f+-%5.2f%%\n', ...
                100*fSwarm, 100*cv_ebar); 
        case 2,
            st1=st{1};
            st2=st{2};
            stc=st{3};
            orpos=st{4};
            cmi=orpos+1;
            if Swarm(orpos)>0.5,
            fs_first=false;
            else
                fs_first=true;
            end
%             nSwarm=zeros(size(Swarm));
%             nSwarm(orpos)=fs_first;
%             Swarm(orpos)=fs_first;
%             if (orpos_val>1 | orpos_val<0)  orpose_val=rand; end
            if ~fs_first,
                sfps=st1;
                fmi=5;
                pmi=1;
            else
                sfps=st2;
                fmi=1;
                pmi=6;
            end
            fmi_val=round(min(sfps.max_vals(fmi),Swarm(fmi))); 
            fmi_val=max(sfps.min_vals(fmi),fmi_val); 
            pmi_val=round(min(sfps.max_vals(pmi),Swarm(pmi))); 
            pmi_val=max(sfps.min_vals(pmi),pmi_val); 
%             nSwarm(fmi)=fmi_val;
%             nSwarm(pmi)=pmi_val;
            Swarm(fmi)=fmi_val;
            Swarm(pmi)=pmi_val;
            [fstx,aa,ab]=set_pars_fs(round(fmi_val),retAlgo.donotincludethis);   
%             [pstx,ba,bb]=set_pars_prep(round(pmi_val));   
            [pstx,ba,bb]=set_pars_prep2(round(pmi_val));   
            if ~fs_first,
%                 fprintf('First_prepro\n');
% % %                 First perform preprocessing
            if isempty(find(pstx.method))
% %                 no preprocessing
            tmodel=['chain({'];
            else 
            touse=find(pstx.method==1);
            notuse=find(pstx.method==0);
            tmodel=['chain({'];
            for bi=1:length(touse)
                 tmodel=[tmodel pstx.methods{touse(bi)} '('];
                cpar=min(Swarm(pmi+touse(bi)),sfps.max_vals(pmi+touse(bi)));
                cpar=max(cpar,sfps.min_vals(pmi+touse(bi)));
                if cpar>0.5, cpar=1;
                else, cpar=0;  end                                           
                tmodel=[tmodel '''' pstx.parameter{touse(bi)} '=' num2str(cpar)...
                    '''),'];
                Swarm(pmi+touse(bi))=cpar;
%                 nSwarm(pmi+touse(bi))=cpar;                
                clear cpar;             
%                 tmodel=[tmodel pstx.methods{touse(bi)} '('];
%                 cpar=min(Swarm(pmi+bi),sfps.max_vals(pmi+bi));
%                 cpar=max(cpar,sfps.min_vals(pmi+bi));
%                 if cpar>=0.5, cpar=1;
%                 else, cpar=0;  end                                           
%                 tmodel=[tmodel '''' pstx.parameter{bi} '=' num2str(cpar)...
%                     '''),'];
% %                 nSwarm(pmi+bi)=cpar;
%                 Swarm(pmi+bi)=cpar;
%                 clear cpar;

            end  %%% end for
            end %%% end else
        if ~strcmp(fstx.method,'no')            
            tmodel=[tmodel fstx.method '({'];
            for bi=1:fstx.npars
            cpar=min(Swarm(fmi+bi),sfps.max_vals(fmi+bi));
            cpar=max(cpar,sfps.min_vals(fmi+bi));
%             fstx
            if ~fstx.real_valued(bi)
                    cpar=round(cpar);
                    if (fstx.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
             end
            
            tmodel=[tmodel '''' fstx.parameters{bi} '=' num2str(cpar)...
                    ''','];
            Swarm(fmi+bi)=cpar;
%             nSwarm(fmi+bi)=cpar;
            clear cpar;
            end
                        tmodel(end)='}';
            tmodel=[tmodel '),'];

        end  %%% enf if ~FS
            else
% % %                 First perform feature selection
            if strcmp(fstx.method,'no')
% %                 no preprocessing
            tmodel=['chain({'];
            else 
            tmodel=['chain({' fstx.method '({'];
               for bi=1:fstx.npars
%                 tmodel=['chain({' fstx.method '({'];
                cpar=min(Swarm(fmi+bi),sfps.max_vals(fmi+bi));
                cpar=max(cpar,sfps.min_vals(fmi+bi));
% fstx
                if ~fstx.real_valued(bi)
                    cpar=round(cpar);
                    if (fstx.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
                end
                
                tmodel=[tmodel '''' fstx.parameters{bi} '=' num2str(cpar)...
                    ''','];
%                 nSwarm(fmi+bi)=cpar;
                Swarm(fmi+bi)=cpar;
                clear cpar;
               end
            tmodel(end)='}';
            tmodel=[tmodel '),'];
            if ~isempty(find(pstx.method))
            touse=find(pstx.method==1);
            notuse=find(pstx.method==0);
%             tmodel=['chain({'];
            for bi=1:length(touse)
                tmodel=[tmodel pstx.methods{touse(bi)} '('];
                cpar=min(Swarm(pmi+touse(bi)),sfps.max_vals(pmi+touse(bi)));
                cpar=max(cpar,sfps.min_vals(pmi+touse(bi)));
                if cpar>0.5, cpar=1;
                else, cpar=0;  end                                           
                tmodel=[tmodel '''' pstx.parameter{touse(bi)} '=' num2str(cpar)...
                    '''),'];
                Swarm(pmi+touse(bi))=cpar;
%                 nSwarm(pmi+touse(bi))=cpar;                
                clear cpar;
            end
            end
            end   %%%end FS
            end  %%% end FS & prepro

% % %         Adding the classifier
            longit=size(stc.parameters,2);
        if (longit==0),
            tmodel=[tmodel stc.method ',bias});'];
        else
            tmodel=[tmodel stc.method '({'];
            for bi=1:longit
                cpar=min(Swarm(cmi+bi),stc.max_vals(bi));
                cpar=max(cpar,stc.min_vals(bi));
                if ~stc.real_valued(bi)
                    cpar=round(cpar);
                    if (stc.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
                end
                tmodel=[tmodel '''' stc.parameters{bi} '=' num2str(cpar)...
                    ''','];
%                 nSwarm(cmi+bi)=cpar;
                Swarm(cmi+bi)=cpar;                
                clear cpar;
            end
%             if stc.isKM,
%                 nSwarm(end)=cpar1;
%             end
            tmodel(end)='}';
            tmodel=[tmodel '),bias});'];
        end
%             tmodel=[tmodel '),bias});'];
% tmodel
            cmodel=eval(tmodel);

% % %       Build the CB model             
            cv_model = cv(cmodel, {['folds=' num2str(retAlgo.foldnum)], ...
                'store_all=0'});
            cv_model.verbosity=retAlgo.verbosity;
            % Call the method "train" of the object "cv_model":
            cv_output   = train(cv_model, ndat); 
            % Collect the results
            OutX = []; OutY = []; ber =[];
            for kk = 1:retAlgo.foldnum,
                outX    = cv_output.child{kk}.X;
                outY    = cv_output.child{kk}.Y;
                OutX    = [OutX; outX]; 
                OutY    = [OutY; outY]; 
                ber(kk) = balanced_errate(outX, outY);
            end
            correct_bias=0;
                        % Check whether to do a bias correction
            if isa(cmodel, 'chain')
                chain_length=length(cmodel.child);
                if isa(cmodel{chain_length}, 'bias')
                    correct_bias=1;
                end
            end
            if correct_bias
                % Train a bias model with the cv outputs
                [d, cv_bias]=train(bias, data(OutX, OutY));            
                % Compensate the bias
                OutX=OutX+cv_bias.b0;
            end

            
%             % Train a bias model with the cv outputs
%             [d, cv_bias]=train(bias, data(OutX, OutY));            
%             % Compensate the bias
%             OutX=OutX+cv_bias.b0;
                        % Compute the CV error rate and error bar
            fSwarm   = balanced_errate(OutX, OutY);
            cv_ebar    = std(ber,1)/sqrt(retAlgo.foldnum);
            fprintf('CV BER (Inside PSMS) =%5.2f+-%5.2f%%\n', ...
                100*fSwarm, 100*cv_ebar); 

        case 3,            
            
                st1=st{1};
            st2=st{2};
            stc=st{3};
            orpos=st{4};
            cmi=orpos+1;
            if Swarm(orpos)>0.5,
            fs_first=false;
            else
                fs_first=true;
            end
%             nSwarm=zeros(size(Swarm));
%             nSwarm(orpos)=fs_first;
%             Swarm=zeros(size(Swarm));
%             Swarm(orpos)=fs_first;
            
%             if (orpos_val>1 | orpos_val<0)  orpose_val=rand; end
            if ~fs_first,
                sfps=st1;
                fmi=5;
                pmi=1;
            else
                sfps=st2;
                fmi=1;
                pmi=6;
            end
            fmi_val=round(min(sfps.max_vals(fmi),Swarm(fmi))); 
            fmi_val=max(sfps.min_vals(fmi),fmi_val); 
            pmi_val=round(min(sfps.max_vals(pmi),Swarm(pmi))); 
            pmi_val=max(sfps.min_vals(pmi),pmi_val); 
%             nSwarm(fmi)=fmi_val;
%             nSwarm(pmi)=pmi_val;
            Swarm(fmi)=fmi_val;
            Swarm(pmi)=pmi_val;

            [fstx,aa,ab]=set_pars_fs(round(fmi_val),retAlgo.donotincludethis);   
%             [pstx,ba,bb]=set_pars_prep(round(pmi_val));   
            [pstx,ba,bb]=set_pars_prep2(round(pmi_val));   
            if ~fs_first,
%                 fprintf('First_prepro\n');
% % %                 First perform preprocessing
            if isempty(find(pstx.method))
% %                 no preprocessing
            tmodel=['chain({'];
            else 
            touse=find(pstx.method==1);
            notuse=find(pstx.method==0);
            tmodel=['chain({'];
            for bi=1:length(touse)
                tmodel=[tmodel pstx.methods{touse(bi)} '('];
                cpar=min(Swarm(pmi+touse(bi)),sfps.max_vals(pmi+touse(bi)));
                cpar=max(cpar,sfps.min_vals(pmi+touse(bi)));
                if cpar>0.5, cpar=1;
                else, cpar=0;  end                                           
                tmodel=[tmodel '''' pstx.parameter{touse(bi)} '=' num2str(cpar)...
                    '''),'];
                Swarm(pmi+touse(bi))=cpar;
%                 nSwarm(pmi+touse(bi))=cpar;                
                clear cpar;
%                 tmodel=[tmodel pstx.methods{touse(bi)} '('];
%                 cpar=min(Swarm(pmi+bi),sfps.max_vals(pmi+bi));
%                 cpar=max(cpar,sfps.min_vals(pmi+bi));
%                 if cpar>=0.5, cpar=1;
%                 else, cpar=0;  end                                           
%                 tmodel=[tmodel '''' pstx.parameter{bi} '=' num2str(cpar)...
%                     '''),'];
% %                 nSwarm(pmi+bi)=cpar;
%                 Swarm(pmi+bi)=cpar;                
%                 clear cpar;

            end  %%% end for
            end %%% end else
        if ~strcmp(fstx.method,'no')            
            tmodel=[tmodel fstx.method '({'];
            for bi=1:fstx.npars
            cpar=min(Swarm(fmi+bi),sfps.max_vals(fmi+bi));
            cpar=max(cpar,sfps.min_vals(fmi+bi));
            
            if ~fstx.real_valued(bi)
                    cpar=round(cpar);
                    if (fstx.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
                end
            
            tmodel=[tmodel '''' fstx.parameters{bi} '=' num2str(cpar)...
                    ''','];
%             nSwarm(fmi+bi)=cpar;
            Swarm(fmi+bi)=cpar;            
            clear cpar;
            end
                        tmodel(end)='}';
            tmodel=[tmodel '),'];

        end  %%% enf if ~FS
            else
% % %                 First perform feature selection
            if strcmp(fstx.method,'no')
% %                 no preprocessing
            tmodel=['chain({'];
            else 
            tmodel=['chain({' fstx.method '({'];
               for bi=1:fstx.npars
%                 tmodel=['chain({' fstx.method '({'];
                cpar=min(Swarm(fmi+bi),sfps.max_vals(fmi+bi));
                cpar=max(cpar,sfps.min_vals(fmi+bi));

                if ~fstx.real_valued(bi)
                    cpar=round(cpar);
                    if (fstx.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
                end
                
                tmodel=[tmodel '''' fstx.parameters{bi} '=' num2str(cpar)...
                    ''','];
%                 nSwarm(fmi+bi)=cpar;
                Swarm(fmi+bi)=cpar;                
                clear cpar;
               end
            tmodel(end)='}';
            tmodel=[tmodel '),'];
            if ~isempty(find(pstx.method))
            touse=find(pstx.method==1);
            notuse=find(pstx.method==0);
%             tmodel=['chain({'];
            for bi=1:length(touse)
                tmodel=[tmodel pstx.methods{touse(bi)} '('];
                cpar=min(Swarm(pmi+touse(bi)),sfps.max_vals(pmi+touse(bi)));
                cpar=max(cpar,sfps.min_vals(pmi+touse(bi)));
                if cpar>0.5, cpar=1;
                else, cpar=0;  end                                           
                tmodel=[tmodel '''' pstx.parameter{touse(bi)} '=' num2str(cpar)...
                    '''),'];
                Swarm(pmi+touse(bi))=cpar;
%                 nSwarm(pmi+touse(bi))=cpar;                
                clear cpar;
%                 tmodel=[tmodel pstx.methods{touse(bi)} '('];
%                 cpar=min(Swarm(pmi+touse(bi)),sfps.max_vals(pmi+touse(bi)));
%                 cpar=max(cpar,sfps.min_vals(pmi+touse(bi)));
%                 if cpar>0.5, cpar=1;
%                 else, cpar=0;  end                                           
%                 tmodel=[tmodel '''' pstx.parameter{touse(bi)} '=' num2str(cpar)...
%                     '''),'];
% %                 nSwarm(pmi+touse(bi))=cpar;
%                 Swarm(pmi+touse(bi))=cpar;                
%                 clear cpar;
            end
            end

            end   %%%end FS
            end  %%% end FS & prepro

% % %         Adding the classifier
                    cpar1=round(min(Swarm(cmi),sfps.max_vals(cmi)));
                     cpar1=max(cpar1,sfps.min_vals(cmi));
            Swarm(cmi)=cpar1;
                 stc=set_pars_fms(cpar1,retAlgo.donotincludethis);

            longit=size(stc.parameters,2);
        
        if (longit==0),
            tmodel=[tmodel stc.method ',bias});'];
        else
            tmodel=[tmodel stc.method '({'];
            for bi=1:longit
                cpar=min(Swarm(cmi+bi),stc.max_vals(bi));
                cpar=max(cpar,stc.min_vals(bi));
                if ~stc.real_valued(bi)
                    cpar=round(cpar);
                    if (stc.binary(bi))
                       if cpar>=0.5
                           cpar=1;
                       else 
                           cpar=0;
                       end
                    end
                end
                tmodel=[tmodel '''' stc.parameters{bi} '=' num2str(cpar)...
                    ''','];
%                 nSwarm(cmi+bi)=cpar;
                Swarm(cmi+bi)=cpar;                
                clear cpar;
            end
%             if stc.isKM,
%                 nSwarm(end)=cpar1;
%             end
            tmodel(end)='}';
            tmodel=[tmodel '),bias});'];
        end
%             tmodel=[tmodel '),bias});'];
            cmodel=eval(tmodel);

% % %       Build the CB model             
            cv_model = cv(cmodel, {['folds=' num2str(retAlgo.foldnum)], ...
                'store_all=0'});
            
%             cv_model.verbosity=retAlgo.verbosity;
            % Call the method "train" of the object "cv_model":
            cv_output   = train(cv_model, ndat); 
            % Collect the results
            OutX = []; OutY = []; ber =[];
            for kk = 1:retAlgo.foldnum,
                outX    = cv_output.child{kk}.X;
                outY    = cv_output.child{kk}.Y;
                OutX    = [OutX; outX]; 
                OutY    = [OutY; outY]; 
                ber(kk) = balanced_errate(outX, outY);
            end
            correct_bias=0;
                        % Check whether to do a bias correction
            if isa(cmodel, 'chain')
                chain_length=length(cmodel.child);
                if isa(cmodel{chain_length}, 'bias')
                    correct_bias=1;
                end
            end
            if correct_bias
                % Train a bias model with the cv outputs
                [d, cv_bias]=train(bias, data(OutX, OutY));            
                % Compensate the bias
                OutX=OutX+cv_bias.b0;
            end

            
%             % Train a bias model with the cv outputs
%             [d, cv_bias]=train(bias, data(OutX, OutY));            
%             % Compensate the bias
%             OutX=OutX+cv_bias.b0;
                        % Compute the CV error rate and error bar
            fSwarm   = balanced_errate(OutX, OutY);
            cv_ebar    = std(ber,1)/sqrt(retAlgo.foldnum);
            fprintf('CV BER (Inside PSMS) =%5.2f+-%5.2f%%\n', ...
                100*fSwarm, 100*cv_ebar); 
    end

% % % Determines if child_n is a valid CLOP-classifier
function [xa]=isclassifier(child_n)
v_classifiers={'gentleboost', 'klogistic',  'logitboost',   'naive', ...
    'prune', 'svc', 'gkridge', 'kridge', 'lssvm', 'neural', 'rf', 'rf_as', 'gb_rf'};

[xa,xb]=ismember(child_n,v_classifiers);
