ref_channel = 4;
px_shift = 8;
shifts = 0; // 0 or 1 or 2 number of shifted measurements


A = newArray(0,1,-1);
roiManager("reset");
run("Duplicate...", "title=[all_channels] duplicate");
setAutoThreshold("Default dark");
run("Create Selection");
run("Enlarge...", "enlarge=8 pixel");
run("Make Inverse");
roiManager("Add");

run("Select None");

for (i = 0; i < shifts; i++) {
	move = px_shift * A[i];
	run("Duplicate...", "duplicate channels=" + ref_channel);
	resetThreshold();
	run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n] normalize stack");
	run("Translate...", "x="+move+" y="+move+" interpolation=None");
	setAutoThreshold("Default dark");
	run("Create Selection");
	run("Enlarge...", "enlarge=1 pixel");
	roiManager("Add");
	close();
}

roiManager("select", newArray(0,1));
roiManager("Combine");
roiManager("deselect");

roiManager("Multi Measure");