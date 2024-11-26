function [this, newModelPath] = runAutomaticScalingTool(this)
%RUNAUTOMATICSCALINGTOOL Run the Automatic scaling tool.
%
%   [newModelPath] = ModelBuilder.runAutomaticScalingTool();
%
%   This method creates a copy of the scalingSetupFile Template within the
%   output directory. Then modifies all subject specific data values and
%   runs the Automatic scaling tool after.
%
%   Outputs:
%   newModelPath  - [1x1 string] Full path of the newly created OpenSim
%                       model.
%
%   +Package: partload
%   @Class: ModelBuilder
%
%
%   See also: partload.ModelBuilder,
%   partload.ModelBuilder.createPatientSpecificModel

%   Copyright:      2020, Balgrist Campus
%   Authors:        Andrea Di Pietro, University of Pisa, (Italy)                       
%                   Alex Bersani, Alma Mater Studiorum - University of Bologna, (Italy) 
%                   Jana Ender (BFH / ETH Zurich, 2024)

% "AST: an OpenSim-based tool for the automatic scaling of generic musculoskeletal models" © 2024
% by Andrea Di Pietro and Alex Bersani is licensed under CC BY-NC 4.0 

disp('Started running OpenSim Scaling Tool');

% create subject specific scaling setup file from template
this.scalingIntermediateSetupFilePath = this.createSpecificScalingSetupFile();

% copy Geometry files from template directory if not already existent,
% as there will be problems rendering the model in OpenSim if geometry
% files are not located at the same directory with the model
if ~exist( fullfile( this.modelDir, 'Geometry' ), 'dir' )
    copyfile( fullfile( fileparts(this.modelTemplatePath), 'Geometry' ), fullfile( this.modelDir, 'Geometry' ) );
end

%% run Automatic Scaling Tool
import org.opensim.modeling.*;

%% import input files
[~, fileName, fileExt] = fileparts(this.modelTemplatePath);
BaseModelFile = strcat(fileName, fileExt);
model = Model(this.modelTemplatePath);
modelFile = regexprep(BaseModelFile, '.osim', '_itr.osim'); % changing name of the copy of the starting model
model.print(fullfile(this.modelDir, modelFile)); % duplicate the generic model for running the iterations 
for u=0:model.getJointSet.getSize-1 % for every joint
    for v=0:model.getJointSet.get(u).numCoordinates-1 % get every coordinate from every joint
       model.getJointSet.get(u).get_coordinates(v).set_locked(model.getJointSet.get(u).get_coordinates(v).get_locked()) % check every coordinate
    end
end

[TRCFolder, fileName, ext] = fileparts(this.trcStaticPath);
TRCFile = [fileName, ext];

[StatTRC,HeadTRC,HeadTRC_XYZ] = this.load_trc(this.trcStaticPath); % loading the TRC file

[~, fileName, fileExt] = fileparts(this.scalingIntermediateSetupFilePath);
SetupFile = strcat(fileName, fileExt);

%% parameters to set
SubjectHeight = (this.modelHeight)*100; % Height of subject (cm)
SubjectWeight = this.modelMass; % Weight of subject (Kg) 
GenericModelHeight = 180;% Height of generic model (cm): gait2392=180;
GenericModelWeight = 75.16;% Weight of generic model (Kg): gait2392=75.16;

pose = 1; % Pose estimation

% Defining the manual scale factors
MeanScaleFactY=SubjectHeight/GenericModelHeight; % mean manual scale factor = heights ratio
MeanScaleFact = Vec3(MeanScaleFactY); % from vector to Vec3

name_ModelScaledAdj='ModelScaledMarkerAdj.osim'; % Name of the final scaled model

%% Setup Tool user paramenters
Km=400; % iterations Threshold: number of iterations 
EndErr=0.004; % End condition for RMS error of loop while
ManualScaleErr=0.025; % error over which the scaling becomes manual for all bodies 
rep=4; % number of times to perform manual scaling just for detected segment 
rep2=8;%  number of times to perform manual scaling for all segments
%% start of algorithm's parameter : Don't modify these parameters
s=-1; % initially the sign for adding the position increment is negative
k=1; % first cycle
flag=0; % flag = 1 if the tool is scaling with Manual scaing factor just for some segments
ind=0; % counter for flag used as a controller
flag2=0;% flag2 =  if the tool is scaling with Manual scaing factor for all segments
ind2=0;% counter for flag2 used as a controller

% this.createTools
    
%% createTools
% 
% Scale tool: loading pre-existent scaling setup file then uploading it
Scaler=ScaleTool(this.scalingIntermediateSetupFilePath); % opening the Scale tool
Array2=ArrayStr(); % defining array object
Array2.append("measurements manualScale ");% initial setup has both manual and measurement scale
Scaler.getModelScaler.setScalingOrder(Array2);% in the scaling order we want the array just created ("manualScale")
ScaledFileName='ModelScaled_API.osim';%name of the Scaled model updated at every iteration
Scaler.getModelScaler.setOutputModelFileName(ScaledFileName);%setting the name of the new scaled model
Scaler.getGenericModelMaker.setModelFileName(modelFile); % set the generic model name in the scale tool
Scaler.getMarkerPlacer.setMarkerFileName(TRCFile); %loading the TRC file with exp markers to use to perform the scaling factors
time_range=Scaler.getModelScaler.getTimeRange; % get the time range frome initial scale setup file
Scaler.getMarkerPlacer.setTimeRange(time_range); % set the time range
Scaler.getMarkerPlacer.setApply(0); % make sure Markers won't be repositioned after scaling
Scaler.print(this.scalingIntermediateSetupFilePath); % saving setup file

%% Creation Ik tool for Static trial from Scaling setup
IKSet=Scaler.getMarkerPlacer.getIKTaskSet;% getting IK Sets from Scaling setup
ikTool = InverseKinematicsTool();% define the IK setup tool
ikTool.set_IKTaskSet(IKSet);%set Ik set previously retrieved
ikTool.set_marker_file(TRCFile);% set the trial data .TRC 
ikTool.set_report_marker_locations(1);% true on "Report_marker_location"
CoordFileName=('Coord_Static.mot'); % name of Coordinates file
ikTool.set_output_motion_file(fullfile(this.modelDir,CoordFileName));%setting path of output motion file
%TRCData=MarkerData(fullfile(TRCFolder,TRCFile)); % MarkerData object from TRC file
ikTool.setStartTime(time_range.get(0));% getting initial time of scaling trial
ikTool.setEndTime(time_range.get(1));% getting end time of scaling trial
path_ik_static=fullfile(this.modelDir,'IkSetup(static_trial).xml');% path of ik setup file for scaling trial
ikTool.print(path_ik_static);%saving ik setup file for static trial
   
%% Creation of Scale tool with Manual scale factor if RMS erorr exceeds ManualScaleErr Threshold
ScalerManual=Scaler; % new Scale tool 
ScalerManual.setSubjectMass(this.modelMass);%set Subject mass
ScalerManual.setSubjectHeight(this.modelHeight);% set subject height
NumBodies=model.getBodySet.getSize; % retrieving Number of bodies of the model
% inserting manual scale factors for each body of the subject
for m=0:NumBodies-1 % OpenSim starts from 0 not from 1
    scale=Scale(); % defining scale object
    scale.setScaleFactors(MeanScaleFact)% set the same scale factor for each body
    scale.setSegmentName(model.getBodySet.get(m).getName); % set body name
    scale.setApply(1);% apply: true
ScalerManual.getModelScaler.getScaleSet.cloneAndAppend(scale);% appending the scale factor on the scale set
end%for
   
path_scaledFile=fullfile(this.modelDir,ScaledFileName);%path of scaled model
ScalerManual.getModelScaler.setOutputModelFileName(ScaledFileName);% setting the name of the new scaled model
ScalerManual.getModelScaler.setPreserveMassDist(1); % preserve mass: true
ScalerManual.getModelScaler.setMarkerFileName(TRCFile);%setting the TRC file name
ScalerManual.getMarkerPlacer.setApply(0);%  Markers won't be repositioned after scaling
ScalerManual.getGenericModelMaker.setModelFileName(modelFile); % set the generic model name in the scale tool
Array=ArrayStr(); % defining array object
Array.append("manualScale");% write inside array object
ScalerManual.getModelScaler.setScalingOrder(Array);% in the scaling order we want the array just created ("manualScale")
ScalerManual.getModelScaler.setTimeRange(time_range);%set the time range
path_manualScale=fullfile(this.modelDir, 'ManualScaleSetup.xml');%define the manual scale setup file path 
ScalerManual.print(path_manualScale);  %save manual scale setup file


%% determininig coordinate values
if pose==1 % pose =1 means you have chosen to match the experimental pose
    ScaleTool(path_manualScale).run; %Run the manual scaling tool
    ScaledModelFirst= Model(fullfile(this.modelDir,ScaledFileName)); % calling the Scaled model
    ikCoord=InverseKinematicsTool(path_ik_static); % call back IK tool for static trial
    ikCoord.setModel(ScaledModelFirst); % set the Scaled model in the IK tool
    ikCoord.run; % run IK
    [CoordData, Coordhead]=this.load_mot(fullfile(this.modelDir,CoordFileName));% load the just computed coordinates
    CoordData=CoordData(:,2:end); % exclude time column from the IK result file
    AvgCoordData = deg2rad(mean(CoordData));% averaging coordinates over time and convert to radians
    AvgCoordData(4:6)=zeros(1,3); % The translation of the pelvis are set to 0 !!!!! To modify in case of different coordinates sequence of the model !!!!!
    %putting the coordinate values inside scaling marker placer
    d=1;
    for u=0:model.getJointSet.getSize-1 % for every joint
        for v=0:model.getJointSet.get(u).numCoordinates-1 % get every coordinate from every joint
            model.getJointSet.get(u).get_coordinates(v).set_clamped(0); % not clamped
            model.getJointSet.get(u).get_coordinates(v).set_default_value(AvgCoordData(d));% insert in every coordinate the relative computed value from IK 
            d=d+1;
        end
    end
    model.print(fullfile(this.modelDir,modelFile));%save the model with new coordinates
end
markerset=model.getMarkerSet; % getting the generic markerset from unscaled model
markerset.print(fullfile(this.modelDir,'MarkerSet.xml')); % printing the markerset
Nmarkers=markerset.getSize;% retrive number of markers


%% AST_core_v1

while true % iterate until the stop condition at the end of script
    if k>1 && flag==0 && flag2==0
        tolerance=0.08; % tolerance of scaling factor to determine the ScaleFactorRange
        if RMSErr(k-1)>=ManualScaleErr % if the RMSE is too high, the tolerance is 0 and the tool will scale all segments using Mean Scale Factor
            tolerance=0;
        end
        if MeanScaleFactY > 1 % The ScaleFactorRange is not symmetrical with the Mean Scaling Factor
            ScaleFactorsRange=[MeanScaleFactY-tolerance/4, MeanScaleFactY+tolerance*3/4];%define the scaling factors range to consider the scaling reliable : it's translated toward higher values
        elseif MeanScaleFactY < 1
            ScaleFactorsRange=[MeanScaleFactY-tolerance*3/4, MeanScaleFactY+tolerance/4];%define the scaling factors range to consider the scaling reliable: it's translated toward lower values
        elseif MeanScaleFactY == 1
            ScaleFactorsRange=[MeanScaleFactY-tolerance/2, MeanScaleFactY+tolerance/2];%define the scaling factors range to consider the scaling reliable: it's translated toward lower values
        end
    end
    if k==1 % at  first iteration
        ScaleTool(this.scalingIntermediateSetupFilePath).run; % Run scale setup file at first iteration
    elseif k > 1 % for iterations > 1
        if RMSErr(k-1) > ManualScaleErr && flag==0 || flag2==1 % condition to scale with all segments = mean scaling factor.
            ind2=ind2+1;
            flag2=1;
            if ind2>=rep2 % flag2 returns to 0 just when the tool performs Rep2 times in a row the manual scaling for all the segments
                flag2=0;
                ind2=0;
            end
            ScaleTool(path_manualScale).run;
            disp('Manual scaling for all bodies');
        elseif ManualBodies>1 || flag==1 % condition to scale with just some segments = mean scaling factor
            ind=ind+1;
            flag=1;
            if ind>=rep % flag returns to 0 just when the tool performs Rep2 times in a row the manual scaling for the detected segments
                flag=0;
                ind=0;
            end
            ScaleTool(path_ScalerMix).run; % Run manual setup file
            for l=1:ManualBodies
                Str(l)=convertCharsToStrings(NamesBodyManual{l,1}.toString.toCharArray);
            end
            if exist('Str','var')
                disp(append('Manual scale for body: ', strjoin(unique(Str)))); % displaying the segments been scaled manually
            end
            clear NamesBodyManual
        else
            ScaleTool(fullfile(this.modelDir, SetupFile)).run ;% scale the model with the settings in the scale tool setup
        end
    end
    % IK
    ikTool=InverseKinematicsTool(path_ik_static); % call back IK tool for static trial
    ScaledModel= Model(fullfile(this.modelDir,ScaledFileName)); % calling the Scaled model
    ikTool.setModel(ScaledModel); % set the Scaled model in the IK tool
    ikTool.run; % run IK
    [MarkerLocation, HeadSTO]=this.load_sto(fullfile(this.modelDir,'_ik_model_marker_locations.sto')); %loading the Model markers locations in output from IK
    %% obtaining the list of selected markers for the scaling (Markers True in IK Setup file)
    for i = 1:length(HeadSTO)-1 % do not consider time position in the HeadSTO vector
        SelectedMarker(i)=HeadSTO(i+1); % storing markers names
        SelectedMarker(i)=erase(SelectedMarker(i), '_tx'); %erasing extensions
        SelectedMarker(i)=erase(SelectedMarker(i), '_ty'); %erasing extensions
        SelectedMarker(i)=erase(SelectedMarker(i), '_tz'); %erasing extensions
    end
    SelectedMarkerList=unique(SelectedMarker,'stable'); %list of markers used
    %% determining the error between Experimental and Model markers using IK
    LengthMarkErr=min(length(MarkerLocation(:,1)),length(StatTRC(:,1))); % min length between TRC frames and Ik frames
    t1=time_range.get(0); % 
    t2=time_range.get(1);
    TRC_start=find(round(StatTRC(:,2),5)==t1); %searching in the time column
    TRC_end=find(round(StatTRC(:,2),5)==t2); %searching in the time column
    for i=1:length(SelectedMarkerList) % for every marker
        p_TRC=contains(HeadTRC,SelectedMarkerList{i});%position of a certain marker data in .TRC file
        pos_TRC=(find(p_TRC==1)-2)*3; % first coordinate of .TRC marker
        pos_STO=(i-1)*3+2:(i*3)+1;% all 3 coordinates of .STO marker
        MarkErr(1:LengthMarkErr,3*(i-1)+1:3*i)=StatTRC(TRC_start:TRC_end,pos_TRC:pos_TRC+2)/1000-MarkerLocation(1:LengthMarkErr,pos_STO); % Error matrix between .TRC and ModelMarkerLocation
        ModuleErr(i)=sqrt(sum(mean(MarkErr(:,3*(i-1)+1:3*i)).^2));% modulus of error for every marker
    end
    MeanMarkErr=mean(MarkErr); % mean of Markers errors for every direction
    [MaxErr,PosMaxErr]=max(abs(MeanMarkErr)); % finding max error
    RMSErr(k)=rms(ModuleErr);% finding RMS error
    %% determining what marker and in what direction to change
    ToChange=HeadSTO(PosMaxErr+1); % +1 beacuse the time is also considered  in HeadSTO (retrieving marker name from headSTO)
    if contains(ToChange,'_tx')
        dirToChange=1;
        MarkerToChange=erase(ToChange,'_tx');
    elseif contains( ToChange ,'_ty')
        dirToChange=2;
        MarkerToChange=erase(ToChange,'_ty');
    elseif contains( ToChange ,'_tz')
        dirToChange=3;
        MarkerToChange=erase(ToChange,'_tz');
    end
    direction(k)=dirToChange;
    %% storing errors and Marker name errors at every cycle
    err(k)=MaxErr;
    Merr(k)=MarkerToChange;
    %% control for scale factor: if scale factor is > or < of a certain threshold
    ManualBodies=0; % number of bodies scaled with Mean scaling factor
    if k~=1 % for every iteration > 1
        for n=0:Scaler.getModelScaler.getMeasurementSet.getSize-1 % for every measurement set
            for z=0:Scaler.getModelScaler.getMeasurementSet.get(n).getMarkerPairSet.getSize-1 %for every markerPair
                FirstMarker=Scaler.getModelScaler.getMeasurementSet.get(n).getMarkerPairSet.get(z).getMarkerName(0); % first marker of the MarkerPair
                SecondMarker=Scaler.getModelScaler.getMeasurementSet.get(n).getMarkerPairSet.get(z).getMarkerName(1);% second marker of the MarkerPair
                % find position on both 2 markers in .TRC file
                for p=1:length(HeadTRC)
                    if  strcmp(HeadTRC(p),FirstMarker)
                        PosA_exp=(p-2)*3;
                    elseif  strcmp(HeadTRC(p),SecondMarker)
                        PosB_exp=(p-2)*3;
                    end
                end
                %
                state=model.initSystem();
                % find position on both 2 markers in generic model file
                LocA_mod=markerset.get(FirstMarker).getLocationInGround(state).getAsMat; % get first model marker on the starting model
                LocB_mod=markerset.get(SecondMarker).getLocationInGround(state).getAsMat;% get first model markers on the starting model
                %
                dist_mod(z+1)=pdist([LocA_mod';LocB_mod'],'euclidean'); %distance of marker pairs in  model file
                dist_exp(z+1)=pdist([mean(StatTRC(:,PosA_exp:PosA_exp+2));mean(StatTRC(:,PosB_exp:PosB_exp+2))],'euclidean')/1000;%distance of marker pairs in .TRC file
            end
            ScaleFact(n+1)=mean(dist_exp./dist_mod);%definition of scale factor
            clear dist_mod dist_exp
            if ScaleFact(n+1) < ScaleFactorsRange(1) || ScaleFact(n+1) > ScaleFactorsRange(2) % if scale factor is outside the range
                if Scaler.getModelScaler.getMeasurementSet.get(n).getApply()==1 % considering only applied measurement sets
                    NamesBodyManual{ManualBodies+1,1}=Scaler.getModelScaler.getMeasurementSet.get(n).getBodyScaleSet.get(0).getName;%saving names of bodies affected
                    ManualBodies=ManualBodies+1;
                end
            end
        end
        clear n
    end
    %% creation of mixed ( measurement set and manual) scaling setup
    if ManualBodies > 0 % if detected
        ScalerMix=Scaler;
        % write inside array object
        ScalerMix.getModelScaler.setScalingOrder(Array2);% in the scaling order we want the array just created ("manualScale")
        for m=0:NumBodies-1
            scale.setSegmentName(model.getBodySet.get(m).getName); % set body name
            scale.setApply(0)
            ScalerMix.getModelScaler.getScaleSet.cloneAndAppend(scale);% appending the scale factor on the scale set
        end
        for m=0:NumBodies-1
            for l=1:ManualBodies
                scale=Scale(); % defining scale object
                scale.setScaleFactors(MeanScaleFact)% set the same scale factor for each body
                scale.setSegmentName(model.getBodySet.get(m).getName); % set body name
                if strcmp(model.getBodySet.get(m).getName, convertCharsToStrings(NamesBodyManual{l,1}.toString.toCharArray))
                    scale.setApply(1);% apply: true
                    ScalerMix.getModelScaler.getScaleSet.cloneAndAppend(scale);% appending the scale factor on the scale set
                end
            end
        end
        path_ScalerMix=fullfile(this.modelDir,'ScalerMix.xml');
        ScalerMix.print(path_ScalerMix);
    end
    %% increment to change the marker coordinate affected by the max error
    if flag==1 % in case of manual scaling just for some bodies
        step(k)=MaxErr;
    elseif flag2==1 % in case of manual scaling for all bodies
        step(k) = MaxErr/2;
    else% in case of normal scaling
        step(k)= MaxErr/6;
    end
    state=model.initSystem();%take the state of the model
    GenericMarker=markerset.get(Merr(k));%considering the marker to chaange
    SockName=GenericMarker.getParentFrame;%retrieve Socket name (local)
    GroundFrame=model.getJointSet.get(0).getParentFrame;%define the ground coordinate system
    GenericMarker.changeFramePreserveLocation(state,GroundFrame); %change from local to ground coodinate systems
    currentCoordAbs=GenericMarker.get_location.getAsMat;%from Vec3 to vector
    %% control to sign and step size: if err rises, go back of 2 step
    if  k~=1
        if  err(k) >= err(k-1) && strcmp(Merr(k),Merr(k-1)) && direction(k)==direction(k-1) %&&  if the Max error arises at next cycle to the same marker and to the same direction it means that the right sign is the opposite one
            s=-s;
            disp('sign changed');
            step(k)=2*step(k-1);% doubling this step because the step at iteration k-1 was wrong
        end
    end
    %% setting new coordinate
    switch dirToChange % add increment according to the direction to change
        case 1
            NewCoord=currentCoordAbs + [s*step(k);0;0];
        case 2
            NewCoord=currentCoordAbs + [0;s*step(k);0];
        case 3
            NewCoord=currentCoordAbs + [0;0;s*step(k)];
    end
    NewLocationGenericMarker=Vec3.createFromMat(NewCoord);% new coordinate in Vec3
    GenericMarker.set_location(NewLocationGenericMarker);%Upload new coordinates
    GenericMarker.changeFramePreserveLocation(state,SockName);%change from ground to local coordinate system
    model.updModel; %updt model
    markerset.connectToModel(model) % maybe this line is not useful
    model.print(fullfile(this.modelDir,modelFile));%Save the model with new markerset
    disp(['cycle #', num2str(k),' RMS Error:', num2str(RMSErr(k)), ' Max Error:', num2str(err(k)), ' Coord:', ToChange{1,1}, ' increment:' num2str(s*step(k))]);
    %% end condition of while loop
    if RMSErr(k) < EndErr || k>Km && RMSErr(k) > RMSErr(k-1) && flag==0 && flag2==0 % end codition for RMSE and iterations
        break
    end
    k=k+1;
    if flag==0
        clear Str
    end
    save(fullfile(this.modelDir, 'err.mat'), 'err')
    save(fullfile(this.modelDir, 'RMSErr.mat'), 'RMSErr')
end

%% create the final scaled model with marker placement
if ManualBodies~=0
    AdjScaler=ScaleTool(path_ScalerMix);
else 
    AdjScaler=ScaleTool(fullfile(this.modelDir,SetupFile));%New scale tool with marker adjustments
end
AdjScaler.getGenericModelMaker.setModelFileName(modelFile);
AdjScaler.getMarkerPlacer.setApply(1);%repositioning markers after scaling
AdjScaler.getMarkerPlacer.setOutputModelFileName(name_ModelScaledAdj);%set the scaled model name
path_SetupScaleAdj=fullfile(this.modelDir, 'ScalingSetupMarkerAdj.xml');
AdjScaler.print(path_SetupScaleAdj); %save setup file
ScaleTool(path_SetupScaleAdj).run; %create model
modelScaledUnlocked=UnlockModel(this.modelDir,name_ModelScaledAdj);% unblocking coordinates to scaled model if at least one locked coordinate has been detected
tEnd=cputime;
ElapsedTime=tEnd-tStart;

tempo_exc = toc;
tempo_minuti_exc = tempo_exc/60;



% run scaling tool
scaleTool = org.opensim.modeling.ScaleTool( scalingSetupFile );
scaleTool.setName( this.modelName );
scaleTool.setPathToSubject('');
scaleTool.run;

% Save the scaled model
this = this.loadNewOpenSimModel;
this.osModel.print(this.newModelPath);
% return path of new model
newModelPath = this.newModelPath;

% set InitialScaling factor
this.InitialScaling = true;
  
disp('Finished running OpenSim Scaling Tool');

end