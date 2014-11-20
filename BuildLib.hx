/*
 * Shared code for the non-compilation build steps
 */

import sys.io.File;
import sys.FileSystem;

class CopyRecursive {

	private static inline var sep = "/";

	/*
	 * Copy the contents of directory `src` to inside directory `dest`.
	 */
	static public function copyDirContents(src: String, dest: String) : Void {
		makeDir(dest);
		for (filename in FileSystem.readDirectory(src)) {
			var inName = src + sep + filename;
			var outName = dest + sep + filename;

			copyFile(inName, outName);
		}
	}

	/*
	 * Copy the file `src` to the destination filename `dest`.
	 * 
	 * If `src` is a directory, copy its contents recursively.
	 */
	static public function copyFile(src: String, dest: String) : Void {
		if (FileSystem.isDirectory(src)) {
			copyDirContents(src, dest);
		} else if (!FileSystem.exists(dest)) {
			File.copy(src, dest);
		} else { // out file already exists
			// compare modification times and copy if source is newer
			var inStat = FileSystem.stat(src);
			var outStat = FileSystem.stat(dest);

			if (inStat.mtime.getTime() > outStat.mtime.getTime()) {
				File.copy(src, dest);
			}
		}
	}

	static private function makeDir(name: String) : Void {
		if (!FileSystem.exists(name)) {
			FileSystem.createDirectory(name);
		}
	}

}