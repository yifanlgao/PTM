% Predictive T-maze (PTM) study 1 and 2
% Preprocessing pipeline
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
pathname_destination = ['C:\Yifan\PTM\' study_name '\MATLAB_PREPRO_v1'];

if exist(pathname_destination, 'dir')==0
    mkdir(pathname_destination);
end

cd(pathname_destination);

%% pipeline
for s=1:length(subjs)

    subjectx = ['PTM_' subjs{s}];

    pathname_read = pathname_source;
    pathname_write = [pathname_destination, '\', subjectx];

    % if folder doesn't exist then make it
    if exist(pathname_write, 'dir')==0
        mkdir(pathname_write);
    end
    cd(pathname_write)

    % load EEG
    filename = [subjectx '.vhdr']; %PTM_0001.vhdr
    if exist([pathname_read '\' filename], 'file')
        EEG = pop_loadbv(pathname_read, filename);

        % to load SET files
        % filename = [subjectx '_FILT.set'];
        % EEG = pop_loadset(filename,pathname_write);

        % load channel location file
        % 32-channel actiCAP (EASYCAP)
        % LM at TP9, RM at TP10
        % LH at AF7, RH at AF8

        % to remove extra channels if the 32 channel montage is used
        %EEG = pop_select(EEG, 'nochannel', {'FCz' 'F2' 'AFz' 'M1' 'M2'});

        % remove extra channels (in the case of wrong montage)
        %EEG.chanlocs(28:32) = [];
        %EEG.data(28:32, :) = [];
        %EEG.nbchan = 27;

        % import channel location
        EEG.chanlocs = loadbvef('C:\Yifan\PTM\study1\PTM_CLA-32.bvef');

        % remove VEOG
        %EEG = pop_select(EEG, 'nochannel', {'VEOG'});

        %% create eventlist
        % export events and fix the 100ms time delay
        EEG = pop_creabasiceventlist(EEG,'AlphanumericCleaning','on','BoundaryNumeric',{ -99 },'BoundaryString',...
            {'boundary'},'Eventlist',[pathname_write '\eventlist.txt']);

        % import exported eventlist so the events are in the correct format
        EEG = pop_importeegeventlist(EEG,[pathname_write '\eventlist.txt'],'ReplaceEventList','on');

        % fix 100ms delay
        %for i=2:length(EEG.event)
        %    EEG.event(i).latency = EEG.event(i).latency-100;
        %end

        
        % add block number to the marker
        EEG = PTM_marker(EEG);

        % count some trials for sanity check
        num_S11 = sum(strcmp({EEG.event.codelabel}, 'S11_1'));
        num_S21 = sum(strcmp({EEG.event.codelabel}, 'S21_1'));
        %num_S11 + num_S21;
        
        num_S16 = sum(strcmp({EEG.event.codelabel}, 'S16_6'));
        num_S26 = sum(strcmp({EEG.event.codelabel}, 'S26_6'));
        %num_S16 + num_S26;
        
        % export the new eventlist
        EEG = pop_creabasiceventlist(EEG,'AlphanumericCleaning','on','BoundaryNumeric',{ -99 },'BoundaryString',...
            {'boundary'},'Eventlist',[pathname_write '\eventlist.txt']);

        % save a copy of raw data
        EEG.setname = subjectx;
        EEG = pop_saveset(EEG,'filename',[EEG.setname '.set'],'filepath',pathname_write);

        %% filter data
        EEG = pop_tesa_filtbutter(EEG,0.1,20,4,'bandpass');

        % add notch filter at 60HZ (in the range from 57 to 63)
        %EEG = pop_eegfiltnew(EEG, 'locutoff',57,'hicutoff',63,'revfilt',1,'plotfreqz',1);

        % save a copy
        EEG.setname=[subjectx '_FILT'];
        EEG = pop_saveset(EEG, 'filename',[EEG.setname '.set'],'filepath',pathname_write);

        %% segment into trials
        % tally event number
        tally_filename = ['C:\Yifan\PTM\' study_name '\event_tally.xlsx'];
        PTM_event_tally(EEG,subjectx,tally_filename);

        % study2 bins include 4 extra bins
        bin_out = [pathname_write '\eventlist_bin.txt'];

        % specify the path for the individual specific eventlist file
        EEG = pop_binlister(EEG,'BDF',bin,'ExportEL',bin_out,'ImportEL',[pathname_write '\eventlist.txt'],'Saveas','on','SendEL2','All','UpdateEEG','on','Warning','on');

        % epoch data
        EEG = pop_epochbin(EEG, [-200 800],  [-200 0]);

        % save a copy
        EEG.setname=[subjectx '_EPOCH'];
        EEG = pop_saveset(EEG, 'filename',[EEG.setname '.set'],'filepath',pathname_write);

        %% scroll data and manual reject bad segments
        % open GUI
        %pop_eegplot(EEG);

        % save a coppy
        %EEG.setname=[subjectx '_MREJECT'];
        %EEG = pop_saveset(EEG, 'filename',[EEG.setname '.set'],'filepath',pathname_write);

        %%  interpolate bad electrodes
        % check the index of the bad channel
        % EEG = pop_interp(EEG, 4, 'spherical');
        % EEG = pop_interp(EEG, [5,9], 'spherical');

        % save a copy
        % EEG.setname=[subjectx '_CHAN'];
        % EEG = pop_saveset(EEG, 'filename',[EEG.setname '.set'],'filepath',pathname_write);

        %% ICA
        %EEG = pop_tesa_fastica(EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off');
        % Infomax ICA 
        % based on Tony Bell's infomax algorithm as implemented for automated use by Scott Makeig et al.
        EEG = pop_runica(EEG, 'icatype','runica'); 

        % save a copy
        EEG.setname=[subjectx '_ICA'];
        EEG = pop_saveset(EEG, 'filename',[EEG.setname '.set'],'filepath',pathname_write);
        
        % label ICA components
        comp_num = size(EEG.icaweights,1);
        EEG = pop_selectcomps(EEG,1:comp_num);
        
        % remove ICA components
        EEG = pop_subcomp(EEG);

        EEG.setname=[subjectx '_ICREJ'];
        EEG = pop_saveset(EEG, 'filename',[EEG.setname '.set'],'filepath',pathname_write);

        %% re-reference
        ref = {'LM' 'RM'};
        EEG = pop_reref(EEG, ref);

        % remove LHZ and RHZ for plotting later
        EEG = pop_select(EEG, 'nochannel', {'LH' 'RH' 'VEOG'});

        EEG.setname = [subjectx '_REF'];
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', pathname_write);

        %% baseline correction (-200 ms to 0 ms)
        bl = [-200 0];
        EEG = pop_rmbase(EEG, bl);

        EEG.setname = [subjectx '_BL'];
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', pathname_write);
        
        %% % reject abnormal trends (gradient check)
        n_chan = length(EEG.chanlocs);

        % dynamically calculate the SD of EEG data
        eeg_std = std(EEG.data(:));

        % convert the unit in BVA (35 muV/ms) to unit in EEGLAB (std/epoch)
        % max slope = (max voltage * gradient window size)/std
        max_slope = (35*400)/eeg_std;

        % R^2 = 0.3 (default), linear regression fit (R^2 = 1 is perfect linear, R^2 = 0 is highly variable)
        EEG = pop_rejtrend(EEG,1,1:n_chan,1000,max_slope,0.3,1,1);
        
        %% check max min difference
        % convert the max-min 150muV in BVA to -75muV to 75muV in EEGLAB
        thresh = 150; % 150 muV in BVA

        % convert the threshold for EEGLAB 
        min_thresh = -(thresh/2);
        max_thresh = (thresh/2);

        % check for the entire epoch
        EEG = pop_eegthresh(EEG,1,1:n_chan,min_thresh,max_thresh,-0.2,0.8,1,1);
        
        
        %% tally final event number
        tally_filename = ['C:\Yifan\PTM\' study_name '\event_tally_after_rej.xlsx'];
        PTM_event_tally(EEG,subjectx,tally_filename);

        clear EEG
    else
        continue;
    end
end