ref_channel = 4;
data_channel = 3;
extension = ".tif";

px_shift = 4;




dir = getDirectory("Choose data Folder");
outdir = dir + "shifted" + File.separator;
File.makeDirectory(outdir)
flist = getFileList(dir);
suffix = "_shifts.tif";


x_shifts = newArray(0, -px_shift, px_shift);
y_shifts = newArray(0, -px_shift, px_shift);
relevant_channels = newArray(ref_channel, data_channel);



for (f = 0; f < flist.length; f++) {
	file = flist[f];
	if (endsWith(file, extension) && !endsWith(file, suffix) && !startsWith(file, "_") ){
		// open file
		open(dir + file);
		ori = getTitle();
		getDimensions(width, height, channels, slices, frames);
		getVoxelSize(vox_width, vox_height, depth, unit);
		Stack.getUnits(X, Y, Z, Time, Value);

		// create new image
		newImage("shifts", "16-bit", width, height, 2*x_shifts.length*slices);
		new = getTitle();
		run("Stack to Hyperstack...", "order=xyczt(default) channels="+2*x_shifts.length+" slices="+slices+" frames=1 display=Color");
		setVoxelSize(vox_width, vox_height, depth, unit);
		Stack.setUnits(X, Y, Z, Time, Value);

		
		for (i = 0; i < relevant_channels.length; i++) {	// do for each relevant channel
			selectImage(ori);
			Stack.setChannel(relevant_channels[i]);
			getLut(reds, greens, blues);
			for (s = 0; s < slices; s++) {	// loop through slices (Z)
				// copy original signal
				selectImage(ori);
				Stack.setSlice(s + 1);
				run("Select All");
				run("Copy");

				// paste wioth shift
				selectImage(new);
				for (c = 0; c < x_shifts.length; c++) {
					Stack.setChannel(c + x_shifts.length * i + 1);
					Stack.setSlice(s+1);
					setLut(reds, greens, blues);
					makeRectangle(x_shifts[c], y_shifts[c], width, height);
					run("Paste");
					if (s == floor(slices/2)){
						setLut(reds, greens, blues);
						resetMinAndMax;
					}
				}
			}
		}

		// save and close
		selectImage(new);
		makeRectangle(px_shift, px_shift, width-2*px_shift, height-2*px_shift);
		run("Crop");
		save(outdir + file + suffix);
		run("Close All");
	}
}


