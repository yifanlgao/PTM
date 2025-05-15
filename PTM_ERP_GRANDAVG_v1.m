% Predictive T-maze (PTM) study 1 and 2
% ERP Grand averaging
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

%% define task, session, target, and subject
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
pathname_destination = ['C:\Yifan\PTM\' study_name '\MATLAB_GAVG_v1'];

if exist(pathname_destination, 'dir')==0
    mkdir(pathname_destination);
end

cd(pathname_destination);

pathname_write = pathname_destination;

%% load individual ERP files
for s=1:length(subjs)

    % path to search for files
    subjectx = ['PTM_' subjs{s}];
    pathname_read = [pathname_source, '\', subjectx];

    % check if the file exists
    if exist(pathname_read, 'dir')

        % filename
        avgfile = [subjectx '_AVG.erp'];

        % load the latest file into ERP, and all files into ALLERP
        [ERP ALLERP] = pop_loaderp('filename',avgfile,'filepath',pathname_read);
    end
end
%% edit incongruent bin description
%bin_descr = {'peak_reward ' 'peak_noreward ' 'rest_reward ' 'rest_noreward ' 'peak_diff' 'rest_diff'};
%ALLERP(3).bindescr = bin_descr;


%% define stim or feedback
nbin = 31;

type = 2;
if type==1
    type_bin = 1:6; % N2 based on mean latency
    type_name = 'stim';
    stim_window_lat = [250 350]; % search window for peak amplitude
    window_lat = stim_window_lat;
elseif type==2
    type_bin = 7:16; % N2 based on mean latency
    type_name = 'fb';
    fb_window_lat = [200 300]; % search window for peak amplitude
    window_lat = fb_window_lat;
elseif type==3
    type_bin = 17:nbin;
    type_name = 'pair';
end

%% search for peak amplitude in the defined search window
for x=1:2
    
    % FCz
    peaklat_fname = ['PTM_' study_name '_' type_name '_PeakLat.txt'];
    ALLERP = pop_geterpvalues(ALLERP,window_lat,type_bin,15,'Baseline','pre','Erpsets',1:length(ALLERP),...
        'FileFormat','wide','Filename',peaklat_fname,'Measure','peaklatbl','Fracreplace','NaN',...
        'Neighborhood',3,'PeakOnset',1,'Peakpolarity','negative','Peakreplace','absolute',...
        'Resolution',3,'SendtoWorkspace','on' );

    % average the latency
    lat = readtable(peaklat_fname);
    
    if type==1
        mean_stim_lat = mean(table2array(lat(:, 1:6)),'all'); % take the mean latency of all conditions in stim
        mean_stim_lat;
    elseif type==2
        mean_fb_lat = mean(table2array(lat(:, 1:10)),'all'); % take the mean latency of all conditions in fb
        mean_fb_lat;
    end
end

%% extract mean amplitude
for x = 1:2
    window = 1;
    if window==1
        window_amp = [260 360]; % N2 based on mean latency
        window_write = '260_360';
    elseif window==2
        window_amp = [240 340];
        window_write = '240_340';
    elseif window==3
        window_amp = [200 400];
        window_write = '200_400';
    end

    chan = 15; % (15=FCz)
    if chan==2
        chan_name = 'Fz';
    elseif chan==15
        chan_name = 'FCz';
    elseif chan==20
        chan_name = 'Cz';
    end

    meanamp_fname = ['PTM_' study_name '_stim_MeanAmp_' window_write '_' chan_name '.txt'];
    ALLERP = pop_geterpvalues(ALLERP,window_amp,1:6,chan,'Baseline','pre','Binlabel','on','Erpsets',1:length(ALLERP),...
        'FileFormat','wide','Filename',meanamp_fname,'Measure','meanbl','Resolution',3,'SendtoWorkspace','on');

    %% extract feedback mean amplitude
    window = 1;
    if window==1
        window_amp = [215 315]; % N2 based on mean latency
        window_write = '215_315';
    elseif window==2
        window_amp = [240 340];
        window_write = '240_340';
    elseif window==3
        window_amp = [200 400];
        window_write = '200_400';
    end

    chan = 15; % (15=FCz)
    if chan==2
        chan_name = 'Fz';
    elseif chan==15
        chan_name = 'FCz';
    elseif chan==20
        chan_name = 'Cz';
    end

    meanamp_fname = ['PTM_' study_name '_fb_MeanAmp_' window_write '_' chan_name '.txt'];
    ALLERP = pop_geterpvalues(ALLERP,window_amp,7:nbin,chan,'Baseline','pre','Binlabel','on','Erpsets',1:length(ALLERP),...
        'FileFormat','wide','Filename',meanamp_fname,'Measure','meanbl','Resolution',3,'SendtoWorkspace','on');
end

%% grand average
nsubj = length(ALLERP);
ERP = pop_gaverager(ALLERP,'Erpsets',1:nsubj,'Criterion',100,'SEM','on','Warning','on','Weighted','off');
%bins = [5, 2, 1]; %active
bins = [6, 4, 3]; %rest

% plot ERP of all channels
ERP = pop_ploterps(ERP,bins,1:22,'Axsize',[0.05 0.08],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 12.0 -3:2:12]);

% plot only FCz
ERP = pop_ploterps(ERP,1:2,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 12.0 -3:2:12]);

% save grand average ERP
erpname = [phase_name '_' exp_name '_GrandAvg_ERP']; %change the name if TEP
ERP = pop_savemyerp(ERP, 'erpname', erpname, 'filename', [erpname '.erp'], 'filepath',pathname_write);

%% plot active and sham together (doesn't work)
% plot Cz
ERP = pop_ploterps(ERP,bins,13,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-6.0 16.0 -6:2:16]);
%hold on
% plot Cz
ERP = pop_ploterps(ERP,bins,13,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on','Linespec', {':k', ':r', ':b'},...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.93,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-6.0 16.0 -6:2:16]);

%% export amplitude info into TXT file
% filename = erpname;
% nbin = 4;
% for b=1:nbin
%     % export all bins into separate files
%     ERP = pop_export2text(ERP,filename,1:nbin,'time','on','timeunit',1E-3,'electrodes','on','transpose','on');
% end

%% test plots
% AB stim at FCz
ERP = pop_ploterps(ERP,1:2,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 12.0 -3:2:12]);

% CD stim at FCz
ERP = pop_ploterps(ERP,3:4,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 12.0 -3:2:12]);

% EF stim at FCz
ERP = pop_ploterps(ERP,5:6,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 12.0 -3:2:12]);

% AB fb at FCz
ERP = pop_ploterps(ERP,7:8,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','on','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 12.0 -3:2:12]);

% CD fb at FCz
ERP = pop_ploterps(ERP,9:12,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','off','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 15.0 -3:2:15]);

% EF fb at FCz
ERP = pop_ploterps(ERP,13:16,chan,'Axsize',[0.05 0.08],'Box',[1 1],'BinNum','on','Blc','pre','ChLabel','on','FontSizeChan',10,...
    'FontSizeLeg',12,'FontSizeTicks',10,'LegPos','bottom','LineWidth',1.5,'Maximize','on',...
    'Style','Classic','SEM','off','Tag','ERP_figure','Transparency',0.9,'xscale',[-200.0 600.0 -200:100:600 ],'YDir','normal','yscale',[-3.0 15.0 -3:2:15]);

clear ERP
clear ALLERP
