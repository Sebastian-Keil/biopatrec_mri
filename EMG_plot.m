%Plotting
load('Debug.mat');
x=1:length(data);
y=data(:,1);
y1=EMG_noisy(:,1);
y2=EMG_filt(:,1);

figure;
hold on;
plot(x,y,'r');
plot(x,y1,'b');
plot(x,y2,'g');
hold off;