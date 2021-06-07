// MANUAL INPUT SETTINGS

// Select file type to analyze. Only files ending in whatever is between the "" will be read
filetype = ".tif";		// use "" to read all files; this will include non-image files, so make sure there are none in your data folder

// Pause to select region?
pause_for_crop = false;	// set to true to pause each image to select a crop region; set to false to use entire image

// Set channels to use as reference and DNA (i.e. background) regions
ref_channel = 4;	// channel to use for kinetochore detection
DNA_channel = 1;	// (set to 0 to use entire selection)


// Set enlargement of reference and DNA regions (in pixels)
ref_enlarge = 1;	// default = 1
DNA_enlarge = 8;	// default = 8


// Check whether measurements are larger than for random areas
// by make additional measurements of shifted reference ROI
shifts = 2;			// set number of shifted measurements (max 2)
px_shift = 8;		// select shift distance




////////////////////////// ******************************** ////////////////////////// ******************************** //////////////////////////

print("\\Clear");
run("Close All");
savename = "_kt_quantifications.csv";


header = "Channel\tArea_bg\tMean_bg\tArea_kt\tMean_kt";
for (i = 0; i < shifts; i++) {
	header = header + "\tArea_sh" + (i+1) + "\tMean_sh" + (i+1);
}

// create dialog asking for data dir and get file list
dir = getDirectory("Choose data directory");
flist = getFileList(dir);

// run through all images in folder and measure
for (f = 0; f < flist.length; f++) {
	im = dir + flist[f];
	if (endsWith(im, filetype) && !endsWith(im, savename) && !startsWith(flist[f], "_") && !endsWith(im, "zip")) {
		run("Bio-Formats Importer", "open=[" + im + "] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		if (pause_for_crop)		waitForUser("select region to include in analysis");
		print(getTitle());
		print(header);
		makeMeasurements();
		run("Close All");
	}
}

selectWindow("Log");
saveAs("Text", dir + savename);
print("\\Clear");
print("Macro finished");
print("Results saved as: " + dir + savename);





////////////////////////// ******************************** ////////////////////////// ******************************** //////////////////////////

function makeMeasurements() {
	// START AUTOMATED MACRO
	ori=getTitle();
	AREA = getWidth()*getHeight();
	cropIM = "_cropped_";
	roiManager("reset");
	close(cropIM);
	run("Duplicate...", "title="+cropIM+" duplicate");
	
	
	// create ROI of DNA region for background measurement
	if (DNA_channel){
		setSlice(DNA_channel);
		setAutoThreshold("Default dark");
		run("Create Selection");
		run("Enlarge...", "enlarge="+DNA_enlarge+" pixel");
	}
	else	run("Select All");
	
	roiManager("Add");
	run("Select None");
	
	
	// create ROI of reference channel
	resetThreshold();
	run("Duplicate...", "title=convolve duplicate channels=" + ref_channel);
	run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n] normalize stack");
	setAutoThreshold("Default dark");
	run("Create Selection");
	run("Enlarge...", "enlarge="+ref_enlarge+" pixel");
	roiManager("Add");
	
	// make new ROI of region that is part of both ref & DNA
	roiManager("select", newArray(0,1));
	roiManager("and");	
	roiManager("Add");	
	
	// delete ROI that potentially contained regions outside of DNA
	roiManager("deselect");
	roiManager("select", 1);
	roiManager("delete");
	close("convolve");
	
	
	// exclude reference ROI from DNA ROI
	roiManager("select", newArray(0,1));
	roiManager("XOR");
	roiManager("Update");
	
	
	// create shifted ROIs
	for (i = 0; i < shifts; i++) {
		move = px_shift * pow(-1,i);
		
		roiManager("select", 1);
		getSelectionBounds(x, y, width, height);
		Roi.move(x+move, y+move);
		roiManager("Add");
	}
	
	
	// make measurements
	roiManager("deselect");
	roiManager("Remove Slice Info");
	for (c = 0; c < nSlices; c++) {
		setSlice(c+1);
		stats = newArray(d2s(c+1,0));
		for (r = 0; r < roiManager("count"); r++) {
			roiManager("select", r);
			getStatistics(area, mean);
			stats[1+2*r] = area;
			stats[1+2*r+1] = mean;
		}
		out = String.join(stats,"\t");
		print(out);
	}
	run("Select None");
	getStatistics(area);
	if (area < AREA)	saveAs("tiff", dir+"_cropped_"+flist[f]);
	roiManager("deselect");
	roiManager("save", dir + getTitle() + "_ROIs.zip");

	
}



