clc; clear; close all;

% Define the number of stories in the building
n = 5; % Change this for a different number of stories

% Define properties of the building as row matrices
E = 210e9; % Elastic modulus in Pascals (Pa)
g = 9.81; % Acceleration due to gravity in m/s^2 (not used in this code but generally useful)
masses = [35000, 30000, 30000, 25000, 20000]; % Masses of each floor in kg
heights = [5.0, 4.0, 4.0, 4.0, 3.8]; % Heights of each floor in meters
inertia_mm4 = [2.2e9, 3.4e9+2.2e9, 2.2e9, 1.8e9, 1.4e9]; % Moment of inertia in mm^4
inertia = inertia_mm4 * 1e-12; % Convert moment of inertia to m^4

% Calculate the stiffness for each floor using the formula k = 12EI/h^3
k_values = 12 * E * inertia ./ heights.^3;

% Assemble the stiffness matrix K for the building
K = zeros(n,n);
for i = 1:n-1
    K(i,i) = k_values(i) + k_values(i+1);
    K(i,i+1) = -k_values(i+1);
    K(i+1,i) = -k_values(i+1);
end
K(n,n) = k_values(n);

% Assemble the mass matrix M (diagonal matrix with mass of each floor)
M = diag(masses);

% Solve the eigenvalue problem to find natural frequencies and mode shapes
[V,D] = eig(K,M);

% Extract natural frequencies and convert to Hz
omega_n = sqrt(diag(D));
frequencies_hz = omega_n / (2*pi);
time_periods = 1 ./ frequencies_hz;

% Normalize the mode shapes (each column represents a mode shape)
normalized_mode_shapes = V;
for i = 1:size(V, 2)
    normalized_mode_shapes(:,i) = normalized_mode_shapes(:,i) / max(abs(normalized_mode_shapes(:,i)));
end

% Print results to the MATLAB console
fprintf('Stiffness matrix [K] in N/m:\n');
disp(K);

fprintf('Mass matrix [M] in kg:\n');
disp(M);

fprintf('Natural frequencies (Hz):\n');
disp(frequencies_hz);

fprintf('Time periods (s):\n');
disp(time_periods);

% Plot mode shapes in subplots
story_heights = [0, cumsum(heights)]; % Heights for each floor (cumulative)

% Define colors for the plot for clarity
non_normalized_color = 'b'; % Blue for non-normalized mode shapes
normalized_color = 'r'; % Red for normalized mode shapes

% Create figure for mode shapes
figure;

% Plot non-normalized mode shapes
for i = 1:n
    subplot(2, n, i);
    plot([0; V(:,i)], story_heights, 'o-', 'Color', non_normalized_color, 'LineWidth', 2);
    title(['Mode Shape ', num2str(i)]);
    xlabel('Displacement');
    ylabel('Height (m)');
    grid on;
    axis tight;
end

% Plot normalized mode shapes
for i = 1:n
    subplot(2, n, i+n);
    plot([0; normalized_mode_shapes(:,i)], story_heights, 'o-', 'Color', normalized_color, 'LineWidth', 2);
    title(['Normalized Mode Shape ', num2str(i)]);
    xlabel('Displacement');
    ylabel('Height (m)');
    grid on;
    axis tight;
end

% Optional: Enhance the display of the figure
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, 1, 1]); % Maximize figure window

% Define initial conditions for free vibration analysis
x0 = [0; 0; 0; 0; 0.1]; % Initial displacement (0.1 meters for the top floor)
v0 = [0; 0; 0; 0; 0]; % Initial velocity (assuming rest)

% Transform initial conditions into modal coordinates
q0 = V' * x0; % Initial modal displacement
qd0 = V' * v0; % Initial modal velocity

% Time vector for simulation
t = 0:0.01:10; % 10 seconds simulation with 0.01s time step

% Initialize response vectors for time history analysis
x_t = zeros(length(x0), length(t));
q_t = zeros(size(q0, 1), length(t));

% Construct the time history response for each mode
for i = 1:length(omega_n)
    % Calculate modal amplitude and phase angle based on initial conditions
    A_i = sqrt(q0(i)^2 + (qd0(i)/omega_n(i))^2);
    phi_i = atan2(omega_n(i)*q0(i), qd0(i));
    
    % Calculate modal response
    q_t(i, :) = A_i * cos(omega_n(i)*t + phi_i);
    
    % Superpose modal responses to get total response
    x_t = x_t + V(:,i) * q_t(i, :);
end

% Plot the free vibration response of each floor in subplots
figure; % Create a new figure for free vibration response

for floor = 1:n
    subplot(n, 1, floor);
    plot(t, x_t(floor, :), 'LineWidth', 2);
    title(['Free Vibration Response of Floor ', num2str(floor)]);
    xlabel('Time (s)');
    ylabel('Displacement (m)');
    grid on;
end

% Optional: Maximize figure window for better visibility
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, 1, 1]);

% End of script
