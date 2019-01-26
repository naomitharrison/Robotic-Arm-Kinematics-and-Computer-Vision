%%
% RBE3001 - Laboratory 1 
% 
% Instructions
% ------------
% Welcome again! This MATLAB script is your starting point for Lab
% 1 of RBE3001. The sample code below demonstrates how to establish
% communication between this script and the Nucleo firmware, send
% setpoint commands and receive sensor data.
% 
% IMPORTANT - understanding the code below requires being familiar
% with the Nucleo firmware. Read that code first.
clear
clear java
%clear import;
clear classes;
vid = hex2dec('3742');
pid = hex2dec('0007');
disp (vid );
disp (pid);
javaaddpath ../lib/SimplePacketComsJavaFat-0.6.4.jar;
import edu.wpi.SimplePacketComs.*;
import edu.wpi.SimplePacketComs.device.*;
import edu.wpi.SimplePacketComs.phy.*;
import java.util.*;
import org.hid4java.*;
version -java
myHIDSimplePacketComs=HIDfactory.get();
myHIDSimplePacketComs.setPid(pid);
myHIDSimplePacketComs.setVid(vid);
myHIDSimplePacketComs.connect();
% Create a PacketProcessor object to send data to the nucleo firmware
pp = PacketProcessor(myHIDSimplePacketComs); 
figure('Name', 'Current Position', 'NumberTitle', 'off')
plot3([0,0],[0,0],[0,0]);
 title('Current Postition')
 xlabel('Position (Encoder Ticks)') 
 ylabel('Position (Encoder Ticks)')
 zlabel('Position (Encoder Ticks)')

setpts = [];
xAxis = [];
TipPos = [];
elap = [];
elapsedTime = 0;
try
  SERV_ID = 01; 
  SERV_ID_READ = 03;% we will be talking to server ID 37 on
  SERV_ID_PID = 04;% the Nucleo
%   
%   pp.write(SERV_ID_READ, zeros(15,1,'single'));
%   pause(.003);
%   returnPacket2 = pp.read(SERV_ID_READ);
%   homePos = [];
%   homePos(1,1:3) = returnPacket2(1:3,1);


  
  Kp_Shoulder=.001;
  Ki_Shoulder=.001;
  Kd_Shoulder=0.02;
  
  
  Kp_Elbow=.003;
  Ki_Elbow=.0025;
  Kd_Elbow=.04;
  
  Kp_Wrist=.0006;
  Ki_Wrist=.0025;
  Kd_Wrist=.05;
  
  DEBUG   = true;          % enables/disables debug prints

  % Instantiate a packet - the following instruction allocates 64
  % bytes for this purpose. Recall that the HID interface supports
  % packet sizes up to 64 bytes.
  packet = zeros(15, 1, 'single');
  packet(1) = Kp_Shoulder;
  packet(2) = Ki_Shoulder;
  packet(3) = Kd_Shoulder;
  
  packet(4) = Kp_Elbow;
  packet(5) = Ki_Elbow;
  packet(6) = Kd_Elbow;
  
  packet(7) = Kp_Wrist;
  packet(8) = Ki_Wrist;
  packet(9) = Kd_Wrist;
%   
%   packet(11) = 1;
%   packet(12) = homePos(1);
%   packet(13) = homePos(2);
%   packet(14) = homePos(3);
%   
  pp.write(SERV_ID_PID,packet);
  pause(.003);
  
  packet = zeros(15, 1, 'single');
    
  % The following code generates a sinusoidal trajectory to be
  % executed on joint 1 of the arm and iteratively sends the list of
  % setpoints to the Nucleo firmware. 
  %shoulder = [0, 324, -18, -404, -295, 0];
  %elbow = [0, 133.3, -75, -14, 44, 0];
  %wrist = [0, 221, 386, 79, 129, 0];
  
  
  shoulder = [0, 0,0, 0,0, 0,0,0,0,0];
  elbow = [0, 0, 7.55, 55.02, 580, 100, 100,100,100,100];
  wrist = [0, 0, -254.75, 302.5,-254.75, 0,0,0,0,0];
  

  ret = [];
  ret2 = [];
  ret3 = [];

  % Iterate through a sine wave for joint values
  
  %for tea = 1:length(shoulder)
  i=1;
  tea=1;
  tic
  timerVal = tic;
  
  while tea<=6
     
      
      %incremtal = (single(k) / sinWaveInc);

     viaPts = zeros(1, 100);
      % Send packet to the server and get the response
      
      %pp.write sends a 15 float packet to the micro controller
       if mod(i,75)==0
        packet = zeros(15, 1, 'single');
        packet(1) = shoulder(tea);
        packet(2) = elbow(tea);
        packet(3) = wrist(tea);
        tea=tea+1;
        pp.write(SERV_ID, packet); 
       end
       pause(0.003); % Minimum amount of time required between write and read
       
       %pp.read reads a returned 15 float backet from the nucleo.
       pp.write(SERV_ID_READ, zeros(15,1,'single'));
       pause(0.003);
       returnPacket = pp.read(SERV_ID_READ);
       %timerVal = tic;
       elapsedTime = toc(timerVal);
       
       plotDaArm(returnPacket(1:3))
       TipVals = plotDaArm(returnPacket(1:3));
       elap = [elap; elapsedTime];
       TipPos = [TipPos; TipVals'];
       csvwrite('Tip Position', TipPos);

       setpts = [setpts; returnPacket(1:3)'];
       csvwrite('Set Points', setpts);
       
       ret = [ret;returnPacket(1)];
       ret2 = [ret2;returnPacket(2)];
       ret3 = [ret3;returnPacket(3)];
       
       % xAxis = [xAxis;i];
       i= i+1;
       % xAxis(i,1) = i;
       % set(figure, 'Xdata', xAxis');
       % set(figure, 'Ydata', ret);
        %drawnowap = [elap; elapsedtime];
        %set(figure, 'Ydata', ret2);
        %plot(x(1:i),ret(1:i))
        
        %drawnow
       
       
      if DEBUG
          disp('Sent Packet:');
          disp(packet);
          disp('Received Packet:');
          disp(returnPacket);
      end
      
      for x = 0:3
          packet((x*3)+1)=0.1;
          packet((x*3)+2)=0;
          packet((x*3)+3)=0;
      end
      %THis version will send the command once per call of pp.write
      %pp.write(02, packet);
      %pause(0.003);
      %returnPacket2=  pp.read(02);
      %this version will start an auto-polling server and read back the
      %current data
      %returnPacket2=  pp.command(65, packet);
      if DEBUG
          %disp('Received Packet 2:');
          %disp(returnPacket2);
      end
      toc
      pause(.003); %timeit(returnPacket) !FIXME why is this needed?
      
  end
catch exception
    getReport(exception)
    disp('Exited on error, clean shutdown');
end
csvwrite('Time', elap);

% retAvg=sum(ret(1:10))/10;
% ret2Avg=sum(ret2(1:10))/10;
% ret3Avg=sum(ret3(1:10))/10;

% Clear up memory upon termination
%  rep = [];
%  retE = [];
%  retW = [];
%  
%  ret(1,:) = [];
%  rep = ret;
%  ret = ret(:,1:3);
%  
%  
%  plot(ret);
% plot(retE);
 %plot(retW);
 

 
 clear title xlabel ylabel
 close all
 
 xTip = TipPos(:,1);
 yTip = TipPos(:,2);
 zTip = TipPos(:,3);
 
 shoulderPos = setpts(:,1);
 elbowPos = setpts(:,2);
 wristPos = setpts(:,3);
 
 jvel1 = diff(shoulderPos)/diff(elap);
 jvel2 = diff(elbowPos)/diff(elap);
 jvel3 = diff(wristPos)/diff(elap);
 
 figure('Name', 'Tip Time', 'NumberTitle', 'off')
 hold on;
 plot(elap,xTip);
 plot(elap,zTip);
 plot(elap,yTip);
 hold off;
 title('Tip Time')
 xlabel('Time (Seconds)') 
 ylabel('Position (Encoder Ticks)')
 legend('x-Position', 'y-Position', 'z-Position')
 
 figure('Name', 'Tip Position', 'NumberTitle', 'off')
 hold on;
 plot(xTip, zTip);
 plot(191.2566,122.9888, 'ro');
 plot(112.3549,-20.2409, 'ro');
 plot(262.5972,5.2783, 'ro');
 
 
 hold off;
 title(' Tip Position')
 xlabel('Position (Encoder Ticks)') 
 ylabel('Position (Encoder Ticks)')
  
 figure('Name', 'Joint Postition', 'NumberTitle', 'off')
 hold on;
 plot(elap, shoulderPos);
 plot(elap, elbowPos);
 plot(elap, wristPos);
 hold off;
 title('Joint Postition')
 xlabel('Time (Seconds)') 
 ylabel('Position (Encoder Ticks)')
 legend('Shoulder Position', 'Elbow Position', 'Wrist Position')
 
 figure('Name', 'Joint Velocity', 'NumberTitle', 'off')
 hold on;
%  plot(elap(2:2:end), jvel1(1:2:end));
%  plot(elap(2:2:end), jvel2(1:2:end));
%  plot(elap(2:2:end), jvel3(1:2:end));
 plot(elap(2:end), jvel1);
 plot(elap(2:end), jvel2);
 plot(elap(2:end), jvel3);
 hold off;
 title('Joint Velocity')
 xlabel('Time (Seconds)') 
 ylabel('Velocity (Encoder Ticks/Second')
 legend('Shoulder Velocity', 'Elbow Velocity', 'Wrist Velocity')
 
%  csvwrite('Return File', rep);
%  csvwrite('Plot File Shoulder', ret);
%  csvwrite('Plot File Elbow', retE);
%  csvwrite('Plot File Wrist', retW);

pp.shutdown()

%viaPts = zeros(1, 100);
toc
