// Measurement of Myofiber Cross-Sectional Area
// Developed by Jae-Ryong KIM with assistance from Claude AI.

// ===== User Input =====
pixelPerUm = parseFloat(getString("Input the image scale (pixel/um):", "1.0"));
unit = getString("Input a length unit (ex: um, mm, etc):", "um");

// Folder Selection
print("====== Folder Selection ======");
originalFolder = getDirectory("Select original image folder:");
maskFolder = getDirectory("Select masks image folder:");
filteredMaskFolder = getDirectory("Select folder to save filtered masks:");
outputFolder = getDirectory("Select folder to save analysis results:");

// Filtering Settings
Dialog.create("Fiber Area Filtering");
Dialog.addNumber("Minimum Area", 100);
Dialog.addNumber("Maximum Area", 4000);
Dialog.addNumber("Minimum Circularity", 0.3);
Dialog.addCheckbox("Enable manual ROI review", true);
Dialog.show();

minArea = Dialog.getNumber();
maxArea = Dialog.getNumber();
minCirc = Dialog.getNumber();
enableManualReview = Dialog.getCheckbox();

// Create directories if needed
if (!File.exists(outputFolder)) File.makeDirectory(outputFolder);
if (!File.exists(filteredMaskFolder)) File.makeDirectory(filteredMaskFolder);

// Initialize variables
var mergedAreaData = "";
var imageNames = newArray();
var imageProcessSummary = "";
var imageInitialCounts = newArray();
var imageFinalCounts = newArray();

// Save analysis summary
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
timeStamp = year + "/" + (month+1) + "/" + dayOfMonth + " " + hour + ":" + minute + ":" + second;

manualReviewStatus = "Disabled";
if (enableManualReview) {
    manualReviewStatus = "Enabled";
}

summaryPath = outputFolder + "analysis_input_summary.txt";
File.saveString(
    "=== ImageJ Muscle Fiber Analysis Summary ===\n" +
    "Analysis time: " + timeStamp + "\n" +
    "Scale: " + pixelPerUm + " pixel/" + unit + "\n" +
    "Min Area: " + minArea + ", Max Area: " + maxArea + "\n" +
    "Min Circularity: " + minCirc + "\n" +
    "Manual review: " + manualReviewStatus + "\n\n",
    summaryPath
);

// ===== Get File Lists =====
function filterImageFiles(fileList) {
    filtered = newArray();
    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], ".tif") || endsWith(fileList[i], ".tiff") || 
            endsWith(fileList[i], ".jpg") || endsWith(fileList[i], ".png")) {
            filtered = Array.concat(filtered, fileList[i]);
        }
    }
    return filtered;
}

originalImages = filterImageFiles(getFileList(originalFolder));
maskImages = filterImageFiles(getFileList(maskFolder));

if (originalImages.length == 0 || maskImages.length == 0) {
    exit("ERROR: No image files found in selected folders");
}

print("Found " + originalImages.length + " original images and " + maskImages.length + " mask images.");

// ===== Create Filtered Mask Function =====
function createFilteredMask(originalMaskPath, filteredMaskPath) {
    open(originalMaskPath);
    run("Set Scale...", "distance=" + pixelPerUm + " known=1 unit=" + unit);
    run("Remove Border Labels", "left right top bottom");
    
    getDimensions(width, height, channels, slices, frames);
    
    roiManager("Reset");
    run("Label Map to ROIs", "exclude_zero add_to_manager");
    
    initialCount = roiManager("count");
    
    if (initialCount == 0) {
        newImage("EmptyMask", "16-bit black", width, height, 1);
        saveAs("Tiff", filteredMaskPath);
        close("*");
        return initialCount;
    }
    
    // Measure and filter ROIs
    run("Set Measurements...", "area perimeter shape decimal=3");
    roiManager("Measure");
    
    newImage("FilteredMask", "16-bit black", width, height, 1);
    run("32-bit");
    
    labelValue = 1;
    filteredCount = 0;
    
    for (j = 0; j < nResults; j++) {
        area = getResult("Area", j);
        circ = getResult("Circ.", j);
        
        if (area >= minArea && area <= maxArea && circ >= minCirc) {
            roiManager("Select", j);
            run("Set...", "value=" + labelValue);
            labelValue++;
            filteredCount++;
        }
    }
    
    run("Select None");
    run("16-bit");
    saveAs("Tiff", filteredMaskPath);
    close("*");
    run("Clear Results");
    roiManager("Reset");
   
    return initialCount;
}

// ===== Recreate Filtered Mask from ROI Manager =====
function recreateFilteredMaskFromROIs(originalImagePath, filteredMaskPath) {
    open(originalImagePath);
    getDimensions(width, height, channels, slices, frames);
    close();
    
    newImage("UpdatedFilteredMask", "16-bit black", width, height, 1);
    run("Set Scale...", "distance=" + pixelPerUm + " known=1 unit=" + unit);
    run("32-bit");
    
    currentRoiCount = roiManager("count");
    for (i = 0; i < currentRoiCount; i++) {
        roiManager("Select", i);
        run("Set...", "value=" + (i + 1));
    }
    
    run("Select None");
    run("16-bit");
    saveAs("Tiff", filteredMaskPath);
    close();
    print("Updated filtered mask created with " + currentRoiCount + " ROIs");
}

// ===== Area Data Collection =====
function collectAreaData(imageName) {
    imageNames = Array.concat(imageNames, imageName);
    
    areaString = "";
    for (i = 0; i < nResults; i++) {
        if (i > 0) areaString += ",";
        areaString += d2s(getResult("Area", i), 3);
    }
    
    if (mergedAreaData != "") mergedAreaData += "\t";
    mergedAreaData += areaString;
    
    return nResults;
}

// ===== Process All Images =====
print("====== Creating Filtered Masks ======");
setBatchMode(true);

for (i = 0; i < maskImages.length; i++) {
    maskPath = maskFolder + maskImages[i];
    filteredMaskPath = filteredMaskFolder + maskImages[i];
    createFilteredMask(maskPath, filteredMaskPath);
}

setBatchMode(false);
print("====== Image Analysis Started ======");

processedCount = 0;

for (fileIndex = 0; fileIndex < originalImages.length; fileIndex++) {
    originalPath = originalFolder + originalImages[fileIndex];
    baseName = File.getNameWithoutExtension(originalImages[fileIndex]);
    
    // Find matching mask
    maskPath = "";
    for (m = 0; m < maskImages.length; m++) {
        maskBaseName = File.getNameWithoutExtension(maskImages[m]);
        if (indexOf(maskBaseName, baseName) >= 0 || indexOf(baseName, maskBaseName) >= 0) {
            maskPath = filteredMaskFolder + maskImages[m];
            break;
        }
    }

    if (maskPath == "") {
        print("Warning: No mask found for " + baseName);
        continue;
    }

    print("Processing (" + (fileIndex + 1) + "/" + originalImages.length + "): " + baseName);
    
    // Get initial ROI count from mask
    open(maskPath);
    roiManager("Reset");
    run("Label Map to ROIs", "exclude_zero add_to_manager");
    initialROICount = roiManager("count");
    close();
    
    // Open images for analysis
    roiManager("Reset");
    open(originalPath); 
    rename("Original");
    open(maskPath); 
    rename("Mask");
    run("Set Scale...", "distance=" + pixelPerUm + " known=1 unit=" + unit + " global");

    // Generate ROIs from filtered mask
    selectWindow("Mask");
    run("Label Map to ROIs", "exclude_zero add_to_manager");

    if (roiManager("count") == 0) {
        print("Warning: No ROIs found for " + baseName);
        close("*");
        continue;
    }

    // Initial measurement
    run("Set Measurements...", "area mean perimeter shape redirect=Original decimal=3");
    selectWindow("Original");
    roiManager("Measure");

    // Manual ROI review
    roiModified = false;
    if (enableManualReview && roiManager("count") > 0) {
        setBatchMode(false);
        selectWindow("Original");
        roiManager("Show All with labels");
        roiManager("Set Color", "yellow");
        roiManager("Set Line Width", 1);
        
        initialRoiCount = roiManager("count");
        
        waitForUser("Manual ROI Review (" + baseName + ")", 
            "Review and edit ROIs as needed.\n" +
            "Delete unwanted ROIs or modify existing ones.\n" +
            "Press OK when finished.");
        
        if (roiManager("count") != initialRoiCount) {
            roiModified = true;
            recreateFilteredMaskFromROIs(originalPath, maskPath);
        }
    }
    
    // Final measurement and save results
    finalRoiCount = roiManager("count");
    
    if (finalRoiCount > 0) {
        run("Clear Results");
        selectWindow("Original");
        roiManager("Measure");
        
        // Save results
        collectAreaData(baseName);
        saveAs("Results", outputFolder + baseName + "_filtered_results.csv");
        roiManager("Save", outputFolder + baseName + "_filtered_rois.zip");
        
        // Save overlay image
        roiManager("Show All with labels");
        selectWindow("Original");
        run("Flatten");
        saveAs("PNG", outputFolder + baseName + "_ROI_overlay.png");
        close();
        
        processedCount++;
    }
    
    // Store ROI counts for summary
    imageInitialCounts = Array.concat(imageInitialCounts, initialROICount);
    imageFinalCounts = Array.concat(imageFinalCounts, finalRoiCount);
    
    // Save summary entry - simplified version for individual file tracking
    summaryEntry = "File: " + baseName + " | Initial: " + initialROICount + " | Final: " + finalRoiCount + " ROIs\n";
    File.append(summaryEntry, summaryPath);

    close("*");
    run("Clear Results");
}

// ===== Create Merged Area Data =====
if (imageNames.length > 0 && mergedAreaData != "") {
    mergedPath = outputFolder + "merged_area_data.csv";
    
    imageDataArray = split(mergedAreaData, "\t");
    maxAreaCount = 0;
    
    for (i = 0; i < imageDataArray.length; i++) {
        if (imageDataArray[i] != "") {
            areaValues = split(imageDataArray[i], ",");
            if (areaValues.length > maxAreaCount) {
                maxAreaCount = areaValues.length;
            }
        }
    }
    
    // Generate CSV
    csvContent = "";
    for (i = 0; i < imageNames.length; i++) {
        if (i > 0) csvContent += ",";
        csvContent += imageNames[i];
    }
    csvContent += "\n";
    
    for (row = 0; row < maxAreaCount; row++) {
        for (col = 0; col < imageNames.length; col++) {
            if (col > 0) csvContent += ",";
            if (col < imageDataArray.length && imageDataArray[col] != "") {
                areaValues = split(imageDataArray[col], ",");
                if (row < areaValues.length) {
                    csvContent += areaValues[row];
                }
            }
        }
        csvContent += "\n";
    }
    
    File.saveString(csvContent, mergedPath);
    print("Merged area data saved: " + mergedPath);
}

// ===== Final Cleanup =====
run("Close All");
if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
if (isOpen("Results")) { selectWindow("Results"); run("Close"); }

print("====== Analysis Complete ======");
print("Processed " + processedCount + " images");
print("Results saved to: " + outputFolder);