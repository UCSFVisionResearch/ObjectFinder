function convertObjectFinderDataV3toV4
% Convert objectfinder 3.x data format to 4.x data format

% Create Mask from D.mat
if exist('D.mat','file')
    load('D.mat');
    Mask = D;
    save('Mask.mat', 'Mask');
    clear D Mask
end

% Create Filter properties from SG.mat
if exist('find', 'dir')  
    load([pwd filesep 'find' filesep 'SG.mat'])
    Filter.passF = SG.passI;
    Filter.FilterOpts.EdgeDotCut = SG.SGOptions.EdgeDotCut;
    Filter.FilterOpts.SingleZDotCut = SG.SGOptions.SingleZDotCut;
    Filter.FilterOpts.xyStableDots = SG.SGOptions.xyStableDots;
    Filter.FilterOpts.Thresholds.ITMax = 0;
    Filter.FilterOpts.Thresholds.ITMaxDir = 1;
    Filter.FilterOpts.Thresholds.Vol = 0;
    Filter.FilterOpts.Thresholds.VolDir = 1;
    Filter.FilterOpts.Thresholds.MeanBright = 0;
    Filter.FilterOpts.Thresholds.MeanBrightDir = 1;
    save('Filter.mat','Filter');
    clear SG Filter
    rmdir('find', 's');
end

% Convert Dots.mat
load('Dots.mat');
Dots = rmfield(Dots,'TotalNumOverlapDots');
Dots = rmfield(Dots,'TotalNumOverlapVoxs');
Dots = rmfield(Dots,'Ratio');
Dots = rmfield(Dots,'DF');
Dots = rmfield(Dots,'DFOf');
Dots = rmfield(Dots,'DFOfTopHalf');
Dots.ImInfo.CBpos = Dots.Im.CBpos;
Dots = rmfield(Dots,'Im');
save('Dots.mat', 'Dots');
clear Dots

% Convert Settings.mat
load('Settings.mat');
Settings.objfinder.blockSize = Settings.dotfinder.blockSize;
Settings.objfinder.blockBuffer = Settings.dotfinder.blockBuffer;
Settings.objfinder.thresholdStep = Settings.dotfinder.thresholdStep;
Settings.objfinder.maxDotSize = ceil(Settings.dotfinder.maxDotSize);
Settings.objfinder.minDotSize = ceil(Settings.dotfinder.minFinalDotSize);
Settings.objfinder.itMin = Settings.dotfinder.itMin;
Settings.objfinder.minFinalDotSize = Settings.dotfinder.minFinalDotSize;
Settings.objfinder.watershed = 1;
Settings.debug = 0;
Settings = rmfield(Settings,'dotfinder');
save('Settings.mat', 'Settings');
clear Settings

delete('D.mat');
delete('CA.mat');
delete('Grad.mat');
delete('GradAll.mat');
delete('GradI.mat');
delete('Grouped.mat');
delete('TPN.mat');
delete('Use.mat');
rmdir('temp', 's');
end