
\d .fT

// @kind readme
// @author simon.j.watson@gmail.com
// @name .fileTools/README.md
// @category fileTools
// .fT (fileTools) contains tools related to manipulating the file system on which the hdb resides.
// It contains the following items:
//      - .hbr.fExists
//      - .hbr.nukeDir
//      - .hbr.redditFileInfo
// @end

// @kind function
// @fileoverview fExists returns a True if the file specified in a file handle exists. Otherwise, it returns False.
// @param x {hsym} A file/folder handle
// @return exists? {bool} True or False depending on whether the file exists. 
fExists:{[fileHandle] not () ~ key fileHandle}; 

// @kind function
// @fileoverview nukeDir removes a directory from the file system even if it contains something. 
// @param dirTarget {hsym} A file/folder handle
// @throws Error rank thrown if the directory is empty. 
// @return null
nukeDir:{[dirTarget]
        / diR gets recursive dir listing
        diR:{$[11h=type d:key x;raze x,.z.s each` sv/:x,/:d;d]};
        / hide power behind nuke
        nuke:(hdel each desc diR @); / desc sort!
        nuke[dirTarget];
    };

// @kind function
// @fileoverview infltFiles itterates through files in a given directory and inflates any it recognises if they are compressed.
// @param dir {hsym} A folder handle to check for compressed files. 
// @return null
infltFiles:{[dir]                                                   // x is a string representing the file name of a file in the directory dir.                                   
    fileSet: key dir;                                               // get list of files in directory. 
    inflt:{[file]                                                   // build function to inflate files using the right function for the right file type. 
            f:{("/" sv (string dir;(string x))) except ":"};        // function f that builds file path from host directory (dir) and given file (x).
            p:f[file];                                              // use f to create the file path
            $[("." vs (string file))[1]~"bz2";0N!"bzip2 -d ",p;];   // unzip bz2 filepath. 
            $[("." vs (string file))[1]~"xz";0N!"xz -d",p;];        // unzip xz filepath. 
        };
    inflt each fileSet;}                                            // use the function to try and inflate each file. 

// @kind function
// @fileoverview infltFiles itterates through files in a given directory and inflates any it recognises if they are compressed.
// @param dir {hsym} A folder handle to check for compressed files. 
// @param fn {function} A function that executes after being passed each file after decompression by file handle.  
// @param getSinkName {function} A function that returns the sink (target table) given the name of the inbound file. (more generally, a function that can hold or calculate a value for use as an input to the function passed for Running for infltFilesRunFunc)
// @return null
infltFilesRunFunc:{[dir;fn;getSinkName]                                     // x is a string representing the file name of a file in the directory dir.                                   
    fileSet: key dir;                                                       // get list of files in directory. 
//     `DEBUG["attempt permission change: sudo chown -R ubuntu:ubuntu ",(string dir) except ":"];
//     system("sudo chown -R ubuntu:ubuntu ",(string dir) except ":");         // set the import directory access rights so files can be manipulated without sudo.
    inflt:{[file;dir;fn;getSinkName]                                        // build function to inflate files using the right function for the right file type. 
            if[fExists (hsym `$(string dir),"/STOP");:`STOP];               // stop importing this file if a "STOP" file is found in the import directory (case sensitive).
            f:{[file;dir]("/" sv (string dir;(string file))) except ":"};   // function f that builds file path from host directory (dir) and given file (x).
            p:f[file;dir];                                                  // use f to create the file path
            fileName:("." vs (string file))[0];                             // get the name of the file
            fileType:("." vs (string file))[1];                             // get the type of the file
            np:f[`$fileName;dir]                                              // use f to create the unzipped file path
            `DEBUG[raze string "[kxReddit][.fT.infltFilesRunFunc] Attempting unzip {name: ",fileName," type: ",fileType," path: ",p,"}"];
            $[fileType~"bz2";system"bzip2 -d ",p;];                         // unzip if bz2 filepath. 
            $[fileType~"xz";system"xz -d ",p;];                              // unzip if xz filepath. 
            `DEBUG[raze string "[kxReddit][.fT.infltFilesRunFunc] Attempting to apply function. Table sink: ",getSinkName[fileName]];
            fn[`$np;getSinkName[fileName]];
        };
    inflt[;dir;fn;getSinkName] each fileSet;                                                  // Unzip and apply function to each file.
    }      


infltFilesRunFuncTEST:{[dir]                                     // x is a string representing the file name of a file in the directory dir.                                   
    fileSet: key dir;                                                       // get list of files in directory. 
//     `DEBUG["attempt permission change: sudo chown -R ubuntu:ubuntu ",(string dir) except ":"];
//     system("sudo chown -R ubuntu:ubuntu ",(string dir) except ":"); // set the import directory access rights so files can be manipulated without sudo.
    inflt:{[file;dir]                                        // build function to inflate files using the right function for the right file type. 
            if[fExists (hsym `$(string dir),"/STOP");:`stop];               // stop importing this file if a "STOP" file is found (case sensitive).
            f:{[file;dir]("/" sv (string dir;(string file))) except ":"};   // function f that builds file path from host directory (dir) and given file (x).
            p:f[file;dir];                                                  // use f to create the file path
            fileName:("." vs (string file))[0];                             // get the name of the file
            fileType:("." vs (string file))[1];                             // get the type of the file                                             // use f to create the unzipped file path
            `DEBUG[raze string "[kxReddit][.fT.infltFilesRunFunc] Attempting unzip {name: ",fileName," type:",fileType," path: ",p,"}"];
            $[fileType~"bz2";0N!"bzip2 -d ",p;];                         // unzip if bz2 filepath. 
            $[fileType~"xz";0N!"xz -d ",p;];                              // unzip if xz filepath. 
        };
    inflt[;dir] each fileSet;                                                  // Unzip and apply function to each file.
    } 

// @kind function 
// @fileoverview redditFileInfo returns information about a file path given a 
// @param x {string} A valid file path.
// @returns {dict(dir:string[]); file:string; year:string; month:string} A dictionary of features derived from a file
// name.
// @desc dict.dir a list corresponding to each level of the nested file path of the file.
// @desc dict.file the name of the file
// @desc dict.year the year that the information relates to given the file name
// @desc dict.month the month that the information relates to given the file name
// @example file data.
// // Return the data for a file given a file handler. 
// fHandle: hsym `$"/import/RS_2014-11";
// .hBr.redditFileInfo fHandle
// 
// /=> `dir`file`year`month!((enlist "import");"RS_2014-11";"2014";"11")
redditFileInfo:{[source]
    comp:("/" vs string source);
    comp: 1 _ comp;
    file: last comp;
    dir: ((count comp)-1) # comp;
    year: ("_" vs file)[1][til 4];
    month: ("_" vs file)[1][5 + (til 2)];
    :(`dir`file`year`month)!(dir;file;year;month)
    };

\d .