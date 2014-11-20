/*
 * non-compilation build steps for producing Neko target
 */

import BuildLib;

class BuildNeko {

	static private inline var inPath = "server-files";
	static private inline var outPath = "neko";

	static public function main() {
		BuildLib.CopyRecursive.copyDirContents(inPath, outPath);
	}

}