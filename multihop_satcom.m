%% Multi-Hop Satellite Communications Link Between Two Ground Stations
% Пример: многоскачковая спутниковая линия связи с регенеративными
% ретрансляторами (Satellite Communications Toolbox, R2025b).
% Линия: GS1 (Индия) -> Sat1 -> Sat2 -> GS2 (Австралия).

% Экспорт графиков в текущую папку
outDir = pwd;

%% Create Satellite Scenario
startTime = datetime(2020,8,19,20,55,0);              % 19 August 2020 8:55 PM UTC
stopTime = startTime + days(1);                       % 20 August 2020 8:55 PM UTC
sampleTime = 60;                                      % seconds
sc = satelliteScenario(startTime,stopTime,sampleTime);

%% Add the Satellites
semiMajorAxis = 10000000;                  % meters
eccentricity = 0;
inclination = 0;                           % degrees
rightAscensionOfAscendingNode = 0;         % degrees
argumentOfPeriapsis = 0;                   % degrees
trueAnomaly = 0;                           % degrees
sat1 = satellite(sc, ...
    semiMajorAxis, ...
    eccentricity, ...
    inclination, ...
    rightAscensionOfAscendingNode, ...
    argumentOfPeriapsis, ...
    trueAnomaly, ...
    "Name","Satellite 1", ...
    "OrbitPropagator","two-body-keplerian");

semiMajorAxis = 10000000;                  % meters
eccentricity = 0;
inclination = 30;                          % degrees
rightAscensionOfAscendingNode = 120;       % degrees
argumentOfPeriapsis = 0;                   % degrees
trueAnomaly = 300;                         % degrees
sat2 = satellite(sc, ...
    semiMajorAxis, ...
    eccentricity, ...
    inclination, ...
    rightAscensionOfAscendingNode, ...
    argumentOfPeriapsis, ...
    trueAnomaly, ...
    "Name","Satellite 2", ...
    "OrbitPropagator","two-body-keplerian");

%% Add Gimbals to the Satellites
gimbalSat1Tx = gimbal(sat1, ...
    "MountingLocation",[0;1;2]);  % meters
gimbalSat2Tx = gimbal(sat2, ...
    "MountingLocation",[0;1;2]);  % meters
gimbalSat1Rx = gimbal(sat1, ...
    "MountingLocation",[0;-1;2]); % meters
gimbalSat2Rx = gimbal(sat2, ...
    "MountingLocation",[0;-1;2]); % meters

%% Add Receivers and Transmitters to the Gimbals
sat1Rx = receiver(gimbalSat1Rx, ...
    "MountingLocation",[0;0;1], ...      % meters
    "GainToNoiseTemperatureRatio",3, ... % decibels/Kelvin
    "RequiredEbNo",4);                   % decibels
sat2Rx = receiver(gimbalSat2Rx, ...
    "MountingLocation",[0;0;1], ...      % meters
    "GainToNoiseTemperatureRatio",3, ... % decibels/Kelvin
    "RequiredEbNo",4);                   % decibels

gaussianAntenna(sat1Rx, ...
    "DishDiameter",0.5);    % meters
gaussianAntenna(sat2Rx, ...
    "DishDiameter",0.5);    % meters

sat1Tx = transmitter(gimbalSat1Tx, ...
    "MountingLocation",[0;0;1], ...   % meters
    "Frequency",30e9, ...             % hertz
    "Power",15);                      % decibel watts
sat2Tx = transmitter(gimbalSat2Tx, ...
    "MountingLocation",[0;0;1], ...   % meters
    "Frequency",27e9, ...             % hertz
    "Power",15);                      % decibel watts

gaussianAntenna(sat1Tx, ...
    "DishDiameter",0.5);    % meters
gaussianAntenna(sat2Tx, ...
    "DishDiameter",0.5);    % meters

%% Add the Ground Stations
latitude = 12.9436963;          % degrees
longitude = 77.6906568;         % degrees
gs1 = groundStation(sc, ...
    latitude, ...
    longitude, ...
    "Name","Ground Station 1");

latitude = -33.7974039;        % degrees
longitude = 151.1768208;       % degrees
gs2 = groundStation(sc, ...
    latitude, ...
    longitude, ...
    "Name","Ground Station 2");

%% Add Gimbal to Each Ground Station
gimbalGs1 = gimbal(gs1, ...
    "MountingAngles",[0;180;0], ... % degrees
    "MountingLocation",[0;0;-5]);   % meters
gimbalGs2 = gimbal(gs2, ...
    "MountingAngles",[0;180;0], ... % degrees
    "MountingLocation",[0;0;-5]);   % meters

%% Add Transmitters and Receivers to Ground Station Gimbals
gsAntennaType = "Gaussian Antenna";
if gsAntennaType == "Gaussian Antenna"
    gs1Tx = transmitter(gimbalGs1, ...
        Name = "Ground Station 1 Transmitter", ...
        MountingLocation = [0;0;1], ...           % meters
        Frequency = 30e9, ...                     % hertz
        Power = 30);                              % decibel watts
    gaussianAntenna(gs1Tx, ...
        DishDiameter = 2);                        % meters
end

if gsAntennaType == "Gaussian Antenna"
    gs2Rx = receiver(gimbalGs2, ...
        Name = "Ground Station 2 Receiver", ...
        MountingLocation = [0;0;1], ...        % meters
        GainToNoiseTemperatureRatio = 3, ...   % decibels/Kelvin
        RequiredEbNo = 1);                     % decibels
    gaussianAntenna(gs2Rx, ...
        "DishDiameter",2);                     % meters
end

%% Set Tracking Targets for Gimbals
pointAt(gimbalGs1,sat1);
pointAt(gimbalSat1Rx,gs1);
pointAt(gimbalSat1Tx,sat2);
pointAt(gimbalSat2Rx,sat1);
pointAt(gimbalSat2Tx,gs2);
pointAt(gimbalGs2,sat2);

%% Add Link Analysis and Visualize Scenario
lnk = link(gs1Tx,sat1Rx,sat1Tx,sat2Rx,sat2Tx,gs2Rx);

%% Determine Times When Link is Closed and Visualize Link Closures
intervals = linkIntervals(lnk);
disp(intervals);

%% Plot Link Margin at Ground Station 2
[e, time] = ebno(lnk);
margin = e - gs2Rx.RequiredEbNo;
fig1 = figure("Visible","off");
plot(time,margin,"LineWidth",2);
xlabel("Time");
ylabel("Link Margin (dB)");
grid on;
title("Link Margin at Ground Station 2 Receiver");
exportgraphics(fig1,fullfile(outDir,"margin_plot.png"),"Resolution",150);

%% Modify Required Eb/No and Observe Effect on Link Intervals
gs2Rx.RequiredEbNo = 10; % decibels
intervalsNew = linkIntervals(lnk);
disp(intervalsNew);

[e, newTime] = ebno(lnk);
newMargin = e - gs2Rx.RequiredEbNo;
fig2 = figure("Visible","off");
plot(newTime,newMargin,"r",time,margin,"b","LineWidth",2);
xlabel("Time");
ylabel("Link Margin (dB)");
legend("New link margin (RequiredEbNo = 10 dB)", ...
    "Old link margin (RequiredEbNo = 1 dB)","Location","north");
grid on;
title("Link Margin Comparison at Ground Station 2 Receiver");
exportgraphics(fig2,fullfile(outDir,"margin_compare.png"),"Resolution",150);

%% Reset Required Eb/No
gs2Rx.RequiredEbNo = 1; % decibels
