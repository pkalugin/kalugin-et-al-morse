%% open connection to scanbox
if ~exist('sbudp','var')
    sbudp = udp('localhost','RemotePort',7000);
    fopen(sbudp);
end

%% imaging parameters (6 GRINs)
%frameRate = 15.63;
%nSweeps = 120;
%nXSteps = 3;
%nYSteps = 2;
%nWells = nXSteps * nYSteps;
%volumesPerWell = 20;
%zPerVolume = 30;
%returnTime = 30;
%bufferTime = 20;
%timePerWell = volumesPerWell * zPerVolume/frameRate;
%timePerSweep = nWells * timePerWell;
%runtime = nSweeps * (timePerSweep + returnTime + bufferTime);
%disp(['estimated runtime: ' num2str(runtime/60) ' minutes'])

%table = round(table);
%% imaging parameters (9 GRINs)
frameRate = 15.63;
nSweeps = 120;
nXSteps = 3;
nYSteps = 2;
nWells = nXSteps * nYSteps;
volumesPerWell = 20;
zPerVolume = 30;
returnTime = 30; %used 90 for 211122_DT1 recording
bufferTime = 30;
timePerWell = volumesPerWell * zPerVolume/frameRate;
timePerSweep = nWells * timePerWell;
runtime = nSweeps * (timePerSweep + returnTime + bufferTime);
disp(['estimated runtime: ' num2str(runtime/60) ' minutes'])

table = round(table);
%% scan loop
fprintf(sbudp,'G');
tic;
for c = 1:nSweeps
    t(c) = toc;
    disp(strcat('Sweep #', num2str(c),' imaged'));
    fprintf(sbudp,['MSweep #' num2str(c,'%03.f') ' imaged']);
    for w = 1:nWells-1
        disp(strcat('Well #', num2str(w),' imaged'));
        pause(timePerWell);
        % move X
        fprintf(sbudp,['Px' num2str(table(w,1))]);
        % move Y
        fprintf(sbudp,['Py' num2str(table(w,2))]);
        % move Z
        fprintf(sbudp,['Pz' num2str(table(w,3))]);
    end
    disp(strcat('Well #', num2str(nWells),' imaged'));
    pause(timePerWell);
    
    % return X
    %fprintf(sbudp,['Px' num2str(-sum(table(:,1)))]);
    % return Y
    %fprintf(sbudp,['Py' num2str(-sum(table(:,2)))]);
    % return Z
    %fprintf(sbudp,['Pz' num2str(-sum(table(:,3)))]);
    %pause(returnTime);
    
    % return to memory A (make sure to store it as the origin!)
    fprintf(sbudp,'Ra');
    pause(returnTime);
    
    %fprintf(sbudp,'O');
    %pause(returnTime);
    
    fprintf(sbudp,'S');
    fprintf(sbudp,'G');
    pause(bufferTime);
    
end

disp('all done');
fprintf(sbudp,'S');
fclose(sbudp);