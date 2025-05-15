% Predictive T-maze (PTM) study 1 and 2
% ERP averaging
% author: Yifan Gao
% V1: 4/10/2025
% Toolbox: EEGLAB, ERPLAB

%% add paths
clear all
close all
clc

addpath('C:\Yifan\scripts\eeglab2024.0');
addpath('C:\Program Files\MATLAB')
addpath('C:\Yifan\PTM\study1\data\EEG\rawdata')
addpath('C:\Yifan\PTM\study2\data\EEG\rawdata')
addpath('C:\Yifan\scripts\MATLAB_function')
addpath('C:\Program Files\MATLAB\TESA1.1.1')
addpath('C:\Program Files\MATLAB\cleanline-master')
eeglab

%% define study and subject
study = 3; % (1=FMT_TM); can also add other task/study prefixes and give them a different index
block = 1;
if study==1
    study_name = 'study1';
    pathname_source = 'C:\Yifan\PTM\study1\data\EEG\rawdata';
    subjs = {'0004' '0005' '0006' '0007' '0008' '0010' '0012' '0013' '0014'}; %study1 subject ID
    bin = 'C:\Yifan\PTM\bin\PTM_all.txt';
elseif study==2
    study_name = 'study2';
    pathname_source = 'C:\Yifan\PTM\study2\data\EEG\rawdata';
    subjs = {'0015' '0016' '0017' '0018' '0019'}; %study2 subject ID
    bin = 'C:\Yifan\PTM\bin\PTM_all.txt';
elseif study==3
    study_name = 'study3';
    pathname_source = 'C:\Yifan\PTM\study3\data\EEG\rawdata';
    subjs = {'0020' '0021' '0022'}; %study3 subject ID
    %bin = 'C:\Yifan\PTM\bin\PTM_study3_all.txt';
end

%% make a new folder for SET files
pathname_destination = ['C:\Yifan\PTM\' study_name '\MATLAB_ERP_v1'];

if exist(pathname_destination, 'dir')==0
    mkdir(pathname_destination);
end

cd(pathname_destination);

%% single subject ERP averaging
for s=2:length(subjs)

    subjectx = ['PTM_' subjs{s}];

    pathname_read = [pathname_source, '\', subjectx];
    pathname_write = [pathname_destination, '\', subjectx];

    % load preprocessed EEG
    filename = [subjectx '_BL.set']; %FMT_TM_PAS1_001_BL.set
    if exist([pathname_read '\' filename], 'file')==2

        % if folder doesn't exist then make it
        if exist(pathname_write, 'dir')==0
            mkdir(pathname_write);
        end
        cd(pathname_write)

        EEG = pop_loadset(filename,pathname_read);

        %% average ERP
        nbin = 31; %(6 cue, 10 feedback, 15 pair)

        % average
        ERP = pop_averager(EEG,'Criterion','good','ExcludeBoundary','on','SEM','on'); %change if need shorter ERP averages

        % save averaged ERP file
        erpname = [subjectx '_AVG']; %change the name if TEP
        ERP = pop_savemyerp(ERP, 'erpname', erpname, 'filename', [erpname '.erp'], 'filepath',pathname_write);

        %% export then number of accepted trials
        % if nbin~=ERP.nbin
        %     error('ERP from %s does not have %g bins, it has %g!\n', sname, nbin, ERP.nbin);
        % end
        % 
        % % write the number of trials in each bin
        % header = {'id' 'b1_Astim' 'b2_Bstim' 'b3_Cstim' 'b4_Dstim' 'b5_Estim' 'b6_Fstim'...
        %     'b7_Awin' 'b8_Bloss' 'b9_Cwin' 'b10_Closs' 'b11_Dwin' 'b12_Dloss' 'b13_Ewin' 'b14_Eloss' 'b15_Fwin' 'b16_Floss'};
        % 
        % data = num2cell(zeros(1,nbin+1));
        % data{1,1} = subjectx;
        % 
        % trial_perc_accepted = zeros(1,nbin);
        % for n=1:nbin
        %     data{1,n+1} = ERP.ntrials.accepted(n);
        % end
        % 
        % nrow(s*2-1,:)=header;
        % nrow(s*2,:)=data;
        % 
        % % write trial numbers into an excel file
        % filename_trial = [pathname_destination '\ERP_trials_accepted_' study_name '.xlsx'];
        % xlswrite(filename_trial,nrow);

        %% export data into TXT file
        % electrodes in rows and timepoints in columns

        filename_erp = subjectx; %FMT_TM_PAS1_006_rest_right_noreward.txt

        % export all bins into separate files
        ERP = pop_export2text(ERP,filename_erp,1:nbin,'time','on','timeunit',1E-3,'electrodes','on','transpose','on');

        %% create new bins to combine left and right
        % ERP = pop_binoperator(ERP,{'BIN9=(BIN1+BIN3)/2','BIN10=(BIN2+BIN4)/2','BIN11=(BIN5+BIN7)/2','BIN12=(BIN6+BIN8)/2'});
        % nbin = 12;
        % for b=1:nbin
        %     filename_erp = subject; %FMT_TM_PAS1_006_rest_right_noreward.txt
        %
        %     % export all bins into separate files
        %     ERP = pop_export2text(ERP, filename_erp,1:nbin,'time','on','timeunit',1E-3,'electrodes','on','transpose','on');
        % end
        %
        % erpname = [subject '_FBx']; %change the name if TEP
        % ERP = pop_savemyerp(ERP, 'erpname', erpname, 'filename', [erpname '.erp'], 'filepath',pathname_write);

        %% create new bins for the difference wave
        % ERP = pop_binoperator(ERP,{'b17=b1-b2 label peak_diff','b6=b3-b4 label rest_diff'});
        % 
        % if t==1 || t==2
        %     ERP.bindescr = {'peak_reward ' 'peak_noreward ' 'rest_reward ' 'rest_noreward ' 'peak_diff ' 'rest_diff '};
        %     ERP.bin_descr = {'peak_reward ' 'peak_noreward ' 'rest_reward ' 'rest_noreward ' 'peak_diff ' 'rest_diff '};
        % elseif t==3 || t==4
        %     ERP.bindescr = {'trough_reward ' 'trough_noreward ' 'rest_reward ' 'rest_noreward ' 'trough_diff ' 'trough_diff '};
        %     ERP.bin_descr = {'trough_reward ' 'trough_noreward ' 'rest_reward ' 'rest_noreward ' 'trough_diff ' 'trough_diff '};
        % end
        % 
        % %ERP.bin_descr = {'peak_reward ' 'peak_noreward ' 'rest_reward ' 'rest_noreward ' 'peak_diff ' 'rest_diff '};
        % %ERP.bin_descr = {'trough_reward ' 'trough_noreward ' 'rest_reward ' 'rest_noreward ' 'trough_diff ' 'trough_diff '};
        % nbin = 6;
        % for b=1:nbin
        %     filename_erp = subjectx; %FMT_TM_PAS1_006_rest_right_noreward.txt
        % 
        %     % export all bins into separate files
        %     ERP = pop_export2text(ERP, filename_erp,1:nbin,'time','on','timeunit',1E-3,'electrodes','on','transpose','on');
        % end
        % 
        % erpname = [subjectx '_FBx']; %change the name if TEP
        % ERP = pop_savemyerp(ERP, 'erpname', erpname, 'filename', [erpname '.erp'], 'filepath',pathname_write);

        %% plot 
        % plot stim bins at FCz
        ERP = pop_ploterps(ERP,1:6,15,'Axsize',[0.05 0.08],'BinNum','on','Blc','pre','Box',[1 1],'ChLabel','on','FontSizeChan',10,...
            'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1,'Maximize','on','Position',[103.714 28 106.857 31.9412],...
            'Style','Classic','Tag','ERP_figure','Transparency',0,'xscale',[-200.0 800.0 -200:100:800 ],'AutoYlim','on');

        % plot feedback bins at FCz
        ERP = pop_ploterps(ERP,7:16,15,'Axsize',[0.05 0.08],'BinNum','on','Blc','pre','Box',[1 1],'ChLabel','on','FontSizeChan',10,...
            'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1,'Maximize','on','Position',[103.714 28 106.857 31.9412],...
            'Style','Classic','Tag','ERP_figure','Transparency',0,'xscale',[-200.0 800.0 -200:100:800 ],'AutoYlim','on');

        % plot testing pair bins at FCz
        ERP = pop_ploterps(ERP,17:nbin,15,'Axsize',[0.05 0.08],'BinNum','on','Blc','pre','Box',[1 1],'ChLabel','on','FontSizeChan',10,...
            'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1,'Maximize','on','Position',[103.714 28 106.857 31.9412],...
            'Style','Classic','Tag','ERP_figure','Transparency',0,'xscale',[-200.0 800.0 -200:100:800 ],'AutoYlim','on');

        %clear ERP
        clear EEG
    else
        continue;
    end
end
