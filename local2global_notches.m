%% Local to Global Transformation of PY6 position based on the notch setting 
% There are 10 possible participant notch settings, which would impact
% the position of the force cube. Since V3D requires inputs to be in the
% GCS, the force cube L2G transformation matrix will be calculated across
% all 10 different notch positionings based on the static cart positions in
% 3D space.

%% IMPORT 
% Set folder location
cd('Z:\2 Research Projects\Z_Hand Force Direction Error_SV\Hand Force Direction Error\PY6_Positions\xlsx')


%% Read in data file for one of the notch settings (notch 1) 

% NOTE: FUTURE ITERATION OF THIS CODE WILL LOOP THROUGH ALL OF THESE FILES
% AND CREATE LCS FOR FORCE VECTOR TRANSFORMATIONS 
data = readmatrix('Hole1_labelled_c3d.tsv.xlsx');

% Create marker labels 
[~, txt] = xlsread('Hole1_labelled_c3d.tsv.xlsx', 'A9:Z9');
markerNames = txt(2:end);

% Expand each marker label into x y z 
expandedNames = cell(1, numel(markerNames)*3);

idx = 1;
for i = 1:numel(markerNames)
    expandedNames{idx}   = [markerNames{i} '_x'];
    expandedNames{idx+1} = [markerNames{i} '_y'];
    expandedNames{idx+2} = [markerNames{i} '_z'];
    idx = idx + 3;
end



%% Filter marker trajectories before computing PY6 axes
Fs_marker = 100;        % or whatever your Qualisys marker rate is
Fc_marker = 6;          % (Winter, 2009; Robertson, 2014)
order_marker = 4; %(Winter, 2009; Robertson, 2014)

Wn = Fc_marker / (Fs_marker/2);
[b, a] = butter(order, Wn, 'low');

% Example: filter each marker trajectory (Nx3)
marker_filt = filtfilt(b, a, data(:,:));

% Assign column headers to data 
marker_filt_labelled = array2table(marker_filt, 'VariableNames', expandedNames);

%% Create PY6 LCS 

%The markers on the PY6 have all been uniquely labelled. Imagine facing the handle and
%the cube- the markers are: 
% 1. front_top, 
% 2. back_right (used with front_top to form the Y vector), 
% 3. back_left (used with back_right to form a temp x oriented vector 
%   to cross with the Y vector to get a Z vector)
% 4. front_bottom: labelled in QtM but unused 
% 5. back_bottom: labelled in QtM but unused)

% Y unit vector - front_top to back_right 
y_py6 = table2array(marker_filt_labelled(:,{'back_right_x','back_right_y','back_right_z'})) - table2array(marker_filt_labelled(:,{'front_top_x','front_top_y','front_top_z'}));
y_py6_unit = y_py6 ./ vecnorm(y_py6,2,2); % unit vector in the y direction 

% Temporary X vector - back_left to back_right, projects to the right and goes from the back left
% marker to the back right marker
x_py6_temp = table2array(marker_filt_labelled(:,{'back_right_x','back_right_y','back_right_z'})) - table2array(marker_filt_labelled(:,{'back_left_x','back_left_y','back_left_z'}));

% Generate positive Z, which is a cross of the temporary X and the Y unit
% vector
z_py6 = cross(x_py6_temp, y_py6_unit, 2);
z_py6_unit = z_py6 ./ vecnorm(z_py6,2,2); % unit vector in the z direction 


% Generate the final X unit vector by crossing Y and Z unit vectors 
x_py6_unit = cross(y_py6_unit, z_py6_unit, 2);

%% Create rotation matrix 
% R = zeros(3,3,size(x_py6_unit,1));
% 
% for i = 1:size(x_py6_unit,1)
%     R(:,:,i) = [x_py6_unit(i,:); 
%                 y_py6_unit(i,:); 
%                 z_py6_unit(i,:)];
% end

% Alternatively, use the mean to generate the rotation matrix (stacked
% horizontally to create the G2L, then the transpose will be taken to
% obtain the L2G)
x_py6_unit_mean = mean(x_py6_unit(:,:))/norm(mean(x_py6_unit(:,:))); % Include re-normalization
y_py6_unit_mean = mean(y_py6_unit(:,:))/norm(mean(y_py6_unit(:,:)));
z_py6_unit_mean = mean(z_py6_unit(:,:))/norm(mean(z_py6_unit(:,:)));

R = [x_py6_unit_mean(:,:); 
     y_py6_unit_mean(:,:); 
     z_py6_unit_mean(:,:)];

L2G = R'; % Local to Global Transformation

%% Import test force data 
% Set folder location
cd('Z:\2 Research Projects\Z_Hand Force Direction Error_SV\Hand Force Direction Error\PY6_Positions\Force_Test')

% Read in test force data

% NOTE: THIS IS USED TO VERIFY THAT THE MATH IS CORRECT - THIS CODE WILL
% EVENTUALLY BE SEPARATED INTO ITS OWN PIPELINE FOR L2G COORDINATE
% TRANSFORMATIONS 

% In QtM, the force plates and the PY6 were given different names:
% 1. f_1: Bertec PY6 Cube - this is the force we will be using for this study 
% 2. f_2: AMTI Force Plate 1 - unused, but documented here for reference 
% 3. f_3: AMTI Force Plate 2 - unused, but documented here for reference 

data_force = readmatrix('P01_FastPP1_f_1.xlsx');

% Create marker labels 
[~, txt] = xlsread('P01_FastPP1_f_1.xlsx', 'A28:Z28');
varnames = txt(1:end);


% Assign column headers to data 
data_force_labelled = array2table(data_force, 'VariableNames', varnames);

%% Filter force and moment data 
% To the force Apply a second order low-pass Butterworth filter with a 15Hz
% cutoff
% Inputs
Fs = 1000;                 % sampling frequency (Hz) - Confirmed from excel spreadsheet 
Fc = 15;                   % cutoff frequency (Hz) (Shim, 2004; Veerasammy, 2025)
order = 2;                 % 2nd-order Butterworth (Shim, 2004; Veerasammy, 2025)

% Filter design
Wn = Fc / (Fs/2);          % normalized cutoff
[b, a] = butter(order, Wn, 'low');

% Apply zero-lag filter
FandM_filt = filtfilt(b, a, table2array(data_force_labelled(:,{'Force_X','Force_Y','Force_Z','Moment_X','Moment_Y','Moment_Z'})));

% Convert back to a table and restore headers
FandM_filt = array2table(FandM_filt, ...
    'VariableNames', {'Force_X','Force_Y','Force_Z','Moment_X','Moment_Y','Moment_Z'});


%% From the filtered force and moment data, generate PY6 local x and y coordinates (z assumed 0)
z_py6_local = -(table2array(FandM_filt(:,{'Moment_Y'}))./table2array(FandM_filt(:,{'Force_Z'}))); %x becomes z 
x_py6_local = (table2array(FandM_filt(:,{'Moment_X'}))./table2array(FandM_filt(:,{'Force_Z'}))); %y becomes x
y_py6_local =  zeros(size(FandM_filt(:,{'Force_Z'})));  % zp = 0 for PY6 surface %reordered naming to align with the created lcs - z becomes y

% Combine into a table (optional, keeps headers)
COP_PY6_local = table(x_py6_local, y_py6_local, z_py6_local, 'VariableNames', {'COP_local_x','COP_local_y','COP_local_z'});

%% Apply transformation 
% Set transformation matrix (transpose of arbitrary frame 2)

force_coordinates_transformed = zeros(size(COP_PY6_local));

COP_local = table2array(COP_PY6_local); %allows us to do matrix math

for i = 1:size(COP_local,1)
    force_coordinates_transformed(i,:) = (L2G * COP_local(i,:)')'; %Double transpose since MATLAB is weird and rotation matrices only operate on column vectors 
end 

% Convert back to table with headers
force_coordinates_transformed = array2table(force_coordinates_transformed, ...
    'VariableNames', {'COP_x_GCS','COP_y_GCS','COP_z_GCS'});

%% Build L2G Transformation Matrix 
% Set origin to the top front marker on the PY6, creating a translation
% vector 
%origin = table2array(data_labelled(:,{'front_top_x','front_top_y','front_top_z'}));

% Create transformation matrix 
%T = zeros(4,4,size(R,3));

%for i = 1:size(R,3)
%    T(:,:,i) = [R(:,:,i), origin(i,:)'; 
%                0 0 0 1];
%end

%%
% Use the PY6 XYZ and translate to XYZ global 
% Open it up in vicon and start pushing the cube in different directions to
% see what directions the forces are reading 

% Transformation
% One LCS is moving and the other is not --> the GCS is 