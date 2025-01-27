if ~exist('sbudp','var')
    sbudp = udp('localhost','RemotePort',7000);
    fopen(sbudp);
end
% load('test_96well.mat');

% fprintf(sbudp,'Axx0')
% fprintf(sbudp,'U010')
% fprintf(sbudp,'E001')


%% parameters to change
frameRate = 15.63;
nXSteps = 12;
nYSteps = 2;
dwellTimePerWell = 60*5;
%dwellTimePerWell = 10;
runtime = nXSteps * nYSteps * dwellTimePerWell + nXSteps*nYSteps*28;
disp(['estimated runtime: ' num2str(runtime/60) ' minutes'])
c=1; % count of wells

%% set for a 384 well plate
xStepSize = 4500;
yStepSize = 4500;
zStepSize = 4000;
%400 per 18000z
%motorSpeed = 42 * frameRate;
motorSpeed = 30 * frameRate;
flipDir = 1;

fprintf(sbudp,'G');
tic;

for y = 1:nYSteps
    for x = 1:nXSteps-1
        pause(15);
        % move up
        fprintf(sbudp,['Pz' num2str(zStepSize)]);
        disp('moving Z up')
        pause(zStepSize/motorSpeed);
        % move over
        fprintf(sbudp,['Px' num2str(-xStepSize * flipDir)]);
        disp('moving X over')
        pause(xStepSize/motorSpeed);
        % move down
        fprintf(sbudp,['Pz' num2str(-zStepSize)]);
        disp('moving Z down')
        pause(zStepSize/motorSpeed);
        disp('imaging well')
        t(c) = toc;
        fprintf(sbudp,['MTrial #' num2str(c,'%03.f') ' well imaged']);
        
%         fprintf(sbudp,['E' num2str(c,'%03.f')])
       
        
        c=1+c;
        pause(dwellTimePerWell);
        
        fprintf(sbudp,'S');
        pause(5);
        fprintf(sbudp,'G');
        
    end
    %move up
    if y < nYSteps
        fprintf(sbudp,['Pz' num2str(zStepSize)]);
        disp('moving Z up')
        pause(zStepSize/motorSpeed);
        fprintf(sbudp,['Py' num2str(yStepSize)]);
        disp('moving Y over')
        pause(zStepSize/motorSpeed);
        flipDir = flipDir * -1;
        % move down
        fprintf(sbudp,['Pz' num2str(-zStepSize)]);
        disp('moving Z down')
        pause(zStepSize/motorSpeed);
        disp('imaging well')
        fprintf(sbudp,['MTrial #' num2str(c,'%03.f') ' well imaged']);
        t(c) = toc;

    %     fprintf(sbudp,['E' num2str(c,'%03.f')])

        c=1+c;
        pause(dwellTimePerWell);
        fprintf(sbudp,'S');
        pause(5);
        fprintf(sbudp,'G');
    end
end
% for c = 1:length(table)
%     if table(c,1) ~= 0 
%         fprintf(sbudp,['Px' num2str(table(c,1)) ''])
%         disp('moving X')
%         pause(table(c,end)-table(c-1,end)/15.63)
%     elseif table(c,2) ~= 0 
%         fprintf(sbudp,['Py' num2str(table(c,2)) ''])
%         disp('moving Y')
%         pause(table(c,end)/15.63)
%     elseif table(c,3) ~= 0 
%         fprintf(sbudp,['Pz' num2str(table(c,3)) ''])
%         disp('moving Z')
%         pause(table(c,end)/15.63)
%     else
%         pause(table(c,end)/15.63)
%     end
% 
% end

% fprintf(sbudp,['Pz' num2str(zStepSize)]);
% disp('moving Z up')
disp('all done')
fprintf(sbudp,'S')
fclose(sbudp);
