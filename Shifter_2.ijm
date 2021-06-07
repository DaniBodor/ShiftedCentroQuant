ref_channel = 4;
extension = ".tif";

x_shift = 8;
y_shift = 8;

suffix = "shifted";


run("Close All");
dir = getDirectory("Choose data Folder");
outdir = dir + suffix + File.separator;
File.makeDirectory(outdir)
flist = getFileList(dir);





for (f = 0; f < flist.length; f++) {
	file = flist[f];
	if (endsWith(file, extension) && !endsWith(file, suffix) && !startsWith(file, "_") ){
		// open file
		open(dir + file);
		ori = getTitle();

		// split channels and create shifted ref
		run("Split Channels");
		selectImage(ref_channel);
		run("Duplicate...", "title=shifted duplicate");
		run("Translate...", "x=" + x_shift + " y=" + y_shift + " interpolation=None stack");

		// merge channels
		merge_str = "";
		for (i = 1; i <= nImages; i++) {
			selectImage(i);
			merge_str = merge_str + "c" + i + "=" +getTitle() + " ";
		}
		merge_str = merge_str + "create";
		print(merge_str);
		run("Merge Channels...", merge_str);
		Stack.setDisplayMode("grayscale");
		new = getTitle();

		// save and close
		selectImage(new);
		save(outdir + file + "_" + suffix);
		close();
	}
}


