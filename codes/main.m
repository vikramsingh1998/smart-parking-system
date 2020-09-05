%%
% Create a multimedia reader object to read video data
videoObj = VideoReader('ParkingLot.webm');

% Determine number of frames in the video
numberOfFrames = videoObj.NumberOfFrames;
numberOfFramesProcessed = 0;

%% Traverse video frame by frame
for frame = 1 : 8 : numberOfFrames
    % Read frame from the video
    currentFrame = read(videoObj, frame);

    % Display current frame
    subplot(2, 2, 1); imshow(currentFrame);
    caption = sprintf('Frame %4d of %d.', frame, numberOfFrames);
    title(caption);
    drawnow; % Update figure window
    
    % Determine total frames processed
    numberOfFramesProcessed = numberOfFramesProcessed + 1;

    % Calculate binarized difference Image
    grayImage = rgb2gray(currentFrame);
    alpha = 0.7;
    if frame == 1
        Background = currentFrame;
    else
        % Change background slightly at each frame
        Background = (1-alpha)* currentFrame + alpha * Background;
    end

    % Calculate difference between current frame and the background
    differenceImage = currentFrame - uint8(Background);
    % Threshold with Otsu method
    grayImage = rgb2gray(differenceImage);
    thresholdLevel = graythresh(grayImage);
    binaryImage = im2bw( grayImage, thresholdLevel);
    subplot(2, 2, 2);
    imshow(binaryImage); title('Binarized Difference Image');
    
    %% Subplot 2
    hsvImage = rgb2hsv(currentFrame);
    
    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.006;
    channel1Max = 0.005;
    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.146;
    channel2Max = 1.000;
    
    % Create mask based on chosen histogram thresholds
    maskedImage = ( (hsvImage(:,:,1) >= channel1Min) | (hsvImage(:,:,1) <= channel1Max) ) & ...
        (hsvImage(:,:,2) >= channel2Min ) & (hsvImage(:,:,2) <= channel2Max);
    
    % Morphological operation to remove holes
    maskedImage1 = imfill(maskedImage,'holes');
    maskedImage2 = bwmorph(maskedImage1,'erode');
    maskedImage3 = bwmorph(maskedImage2,'dilate');
    maskedImage4 = imfill(maskedImage3,'holes');
    outputImage = bwareaopen(maskedImage4,500);
    
    % Define region properties for car detection
    stats = regionprops(outputImage);
    
    subplot(2,2,3); 
    imshow(currentFrame); title('Car detection');
    text(3,450,strcat('\color{green}Cars Detected:',num2str(length(stats))))
    hold on;
    % Draw the detected rectangles on output image
    for i = 1:numel(stats)
        rectangle('Position', stats(i).BoundingBox, 'Linewidth', 2, 'EdgeColor', 'g');
    end
    
    %% Subplot 3
    I = imresize(currentFrame,0.7);

    % Define thresholds for channel 1 based on histogram settings
    channel3Min = 215.000;
    channel3Max = 255.000;
    % Define thresholds for channel 2 based on histogram settings
    channel4Min = 237.000;
    channel4Max = 255.000;

    % Create mask based on chosen histogram thresholds
    maskedImg = (I(:,:,1) >= channel3Min ) & (I(:,:,1) <= channel3Max) & ...
        (I(:,:,2) >= channel4Min ) & (I(:,:,2) <= channel4Max);
    
    % Recognise parking slots
    ocrResults = ocr(maskedImg);
    ocrImage = insertObjectAnnotation(I,'rectangle',ocrResults.WordBoundingBoxes,ocrResults.WordConfidences);
    subplot(2, 2, 4);
    imshow(ocrImage); title('Slot detection');

    % Update vacancy of the parking lot
    vacantSpots = length(ocrResults.Words);
    time = datestr(now, 'HH:MM:SS');
    
    % Update user with the progress. Display in the command window
    vacancyUpdate = sprintf('Updated at %s \nTotal spaces available: %d \n\nThe vacant spots are \n\n%s', time, vacantSpots, ocrResults.Text);
    disp(vacancyUpdate);
    progressIndication = sprintf('Processed frame %4d of %d.', frame, numberOfFrames);
    disp(progressIndication);
end
 
%% Alert that processing is done
finishedMessage = sprintf('Done!  It processed %d frames of\n"%s"', numberOfFramesProcessed, 'ParkingLot.mp4');
disp(finishedMessage); % Write to command window
uiwait(msgbox(finishedMessage)); % Also pop up a message box