clc;
clear all;
close all;
foregroundDetector = vision.ForegroundDetector('NumGaussians', 3, ...
    'NumTrainingFrames', 50);


%videoReader =
%vision.VideoFileReader('F:\Work\vehicle_tracking\MB_Traffic\traffic_video1.asf');%%rainy
videoReader = vision.VideoFileReader('F:\Work\vehicle_tracking\MB_Traffic\TruckRun.mp4');%sunny


% using the function VideoReader against vision.VideoFileReader is that the
% info generated has a hell lot of information, the main one being
% 'Duration'
%videoReader_Beta = VideoReader('C:\Users\CiE-user\Documents\Work\vehicle_tracking\MB_Traffic\TruckRun.mp4');
%info = get(videoReader_Beta);

%numberOfFrames = info.Duration*info.FrameRate; % (Frames Per Sec) * (Sec)

for i = 1:250 %floor(numberOfFrames)
    frame = step(videoReader); % read the next video frame
    foreground = step(foregroundDetector, frame);
    %imshow(frame)
end

%figure; imshow(frame); title('Video Frame');
%figure; imshow(foreground); title('Foreground');

se = strel('square', 2);
filteredForeground = imopen(foreground, se);
%figure; imshow(filteredForeground); title('Clean Foreground');

blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MinimumBlobArea', 1200);
bbox = step(blobAnalysis, filteredForeground);

% if(bbox(1,2)>200 && bbox(1,2)<400),
%     aa = insertShape(frame, 'line', [840 350 70 350], 'LineWidth', 5, 'Color', 'green');
% elseif (bbox(1,2)<200 && bbox(1,2)>400),
%     aa = insertShape(frame, 'line', [840 350 70 350], 'LineWidth', 5, 'Color', 'yellow');
% end

result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');

numCars = size(bbox, 1);
result = insertText(result, [10 10], numCars, 'BoxOpacity', 1, ...
    'FontSize', 14);
%figure; imshow(result); title('Detected Cars');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
videoPlayer = vision.VideoPlayer('Name', 'Detected Cars');
videoPlayer.Position(3:4) = [650,400];  % window size: [width, height]
se = strel('square', 2); % morphological filter for noise removal
count = 0;
initial_distance = 9999;
new_distance = 0;
last_distance = 9999;
while ~isDone(videoReader)

    frame = step(videoReader); % read the next video frame

    % Detect the foreground in the current video frame
    foreground = step(foregroundDetector, frame);

    % Use morphological opening to remove noise in the foreground
    filteredForeground = imopen(foreground, se);

    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    bbox = step(blobAnalysis, filteredForeground);

    % Display the number of cars found in the video frame
    numCars = size(bbox, 1);
    result = insertText(result, [10 10], numCars, 'BoxOpacity', 1, ...
        'FontSize', 14);
    
    additional_width = 0;
    additional_height = 0;
    color = 'blue';
    line_color = 'red';
    if numCars > 1
        for ii = 1:numCars -1 
            
            if abs(bbox(ii,1) - bbox(ii+1,1)) < 50
                fprintf('\n Boxes very close to each other')
                additional_width = bbox(ii,3)+bbox(ii+1,3)-(bbox(ii,3)-bbox(ii+1,1))
            else
                fprintf('\n Different Vehicles');
                
                if(bbox(ii,3)>300)
                    fprintf('\n More than One Vehicle--> Truck in Frame');
                    color = 'green'
                elseif(bbox(ii,3)>5 && bbox(ii,3)< 300)% || bbox(1,4) > 225 && bbox(1,4) < 300)
                    fprintf('\n More than One Vehicle --> Sedan/Hatchback/SUV in Frame')
                    color = 'blue'
                end
            end
        end
    elseif numCars == 1
        
        %Distance from line
        x0 = bbox(1,1)+bbox(1,3);
        y0 = bbox(1,2);
        x1 = 70;
        x2 = 840;
        y1 = 350;
        y2 = 350;
        
        Numerator = (x2-x1)*(y1-y0)-(x1-x0)*(y2-y1);
        Denominator = sqrt((x2-x1)^2+(y2-y1)^2);
        new_distance = abs(Numerator)/Denominator;
        flag = 0;
        if(new_distance > last_distance)
            flag = 1;
            %Crossing the line.
            disp('crossing line');
            
            if(flag ==1)
               disp('Thats my point');
               line_color = 'green';
            else
                disp('Min Distance reached ... get out of loop');
            end
        end
        
         last_distance = new_distance;
        %initial_distance(end+1) = min(initial_distance,distance);
        
%         if(distance<10)
%             line_color = 'green';
%         end
            
%         min_distance = 9999;
%         min_distance = min(distance,min_distance);
%         %Distance from line
        
        % Color the box Start
        if(bbox(1,3)>300)
            
            color = 'green';
            fprintf('%f \n One Vehicle--> Truck in Frame ---> GREEN ', distance);
            
        elseif(bbox(1,3)>5 && bbox(1,3)< 300)% || bbox(1,4) > 225 && bbox(1,4) < 300)
            
            color = 'blue';
            fprintf('%f \n One Vehicle --> Sedan/Hatchback/SUV in Frame ---> BLUE ', distance);
        end % Color the box END
    end
     % Draw bounding boxes around the detected cars
    pos_rectangle = bbox;
    pos_line = [840 350 70 350];
    shape_rect = insertShape(frame, 'Rectangle', bbox, 'Color', color);
    result = insertShape(shape_rect, 'Line', pos_line, 'Color', line_color, 'LineWidth', 10);

    
% if(isempty(bbox)),
%     fprintf('%s', 'EMPTY');
%     aa = insertShape(frame, 'line', [840 350 70 350], 'LineWidth', 5, 'Color', 'yellow');
%     
% elseif(bbox(1,2)>200 && bbox(1,2)<400),
%     fprintf('%s', 'Green');
%     aa = insertShape(frame, 'line', [840 250 70 250], 'LineWidth', 5, 'Color', 'green');
%  count = count +1;
%  fprintf('\n%d count', count);
% elseif (bbox(1,2)<200 & bbox(1,2)>400),
%     fprintf('%s', 'YELLOW');
%     aa = insertShape(frame, 'line', [840 350 70 350], 'LineWidth', 5, 'Color', 'yellow');
% end

% if(bbox(1,2)> 200 && bbox(1,2)< 400),
%     fprintf('%s', 'Green');
%     aa = insertShape(frame, 'line', [840 250 70 250], 'LineWidth', 5, 'Color', 'green');
%  count = count +1;
%  fprintf('\n%d count', count);
% elseif (bbox(1,2)<200 && bbox(1,2)>400),
%     fprintf('%s', 'YELLOW');
%     aa = insertShape(frame, 'line', [840 350 70 350], 'LineWidth', 5, 'Color', 'yellow');
% end
    step(videoPlayer, result);  % display the results
   
%    v = VideoWriter('F:\Work\vehicle_tracking\MB_Traffic\Pic of interest\newfile1.avi','Uncompressed AVI');
%    open(v)
%    writeVideo(v,step(videoPlayer, result))
%    close(v)
    end