# Purpose: To create a new git project

# _______________________________________________________
# A. Constructor
# _______________________________________________________
param ( # (own code here)
    [string]$targetFolder = $PSScriptRoot,
    [string]$projectName = "",
    [string]$userName = ""
)

# _______________________________________________________
# B. Static (version controlled)
# _______________________________________________________
#   A. Vars
    Write-Host "..." -foregroundcolor "green"
    $global:__workingFolder = $PSScriptRoot #TODO: user may set a path to the script root
    $global:__missingInputCount = 0

#   A. Validation functions
    function InformInvalidInput($message) {
        Write-Host "> $message" -foregroundcolor "red"
    }
    function HandleMissingInput() {
        ++$global:__missingInputCount
        if ($global:__missingInputCount -eq 1) {
            Write-Host "Detected missing input value/s. (Hint: You can set them by adding -[varName] value)" -foregroundcolor "green"
        }
    }
    function QueryInput($varName, $varAlias, $value) {
        return $( Read-Host "Q$global:__missingInputCount. Missing input parameter [$varName]. Please enter $varAlias (or press Ctrl+C to cancel)" )
    }
    function QueryInputString ($varName, $varAlias, $value) {
        $input = $value
        while ($input -eq "") {
            HandleMissingInput
            $input = QueryInput -varName $varName -varAlias $varAlias - value $value
        }
        return $input
    }
    function QueryInputString_ForNewSubFolder ($toFolderPath, $varName, $varAlias, $value) {
        # First to make sure the input has a value
        $folderName = QueryInputString -varName $varName -varAlias $varAlias -value $value
        # Make sure the folder does not exi
        $subFolderPath = "$toFolderPath\$folderName"
        while (Test-Path -path $subFolderPath) {
            InformInvalidInput "Target folder already exists in $toFolderPath"
            $folderName = QueryInput -varName $varName -varAlias $varAlias -value $value
            $subFolderPath = "$toFolderPath\$folderName"
        }
        return $folderName
    }

#   B. Confirmation
    function ConfirmOrExit($message) {
        Write-Host "$message"
        $ret = Read-Host "Enter Y to proceed, N to cancel"
        if ($ret -ne "y"){
            Write-Host "Operation canceled"
            return
        }
    }

#   C1. IO
    function CreateFolderIfNotExist ($dirName) {
        if (!(Test-Path -path $dirName)) {
            New-Item $dirName -type directory
        }
    }
    function WriteFileIfNotExist ($fileName, $content) {
        if (!(Test-Path -path $fileName)) {
            Add-Content $fileName $content
        }
    }

    function CreateSymLinkIfNotExist ($dirName, $linkToDirName) {
        if (!(Test-Path -path $dirName)) {
            cmd /c mklink /d $dirName $linkToDirName
        }
    }

# _______________________________________________________
# C. Validations & Confirmation (own code here)
# _______________________________________________________
#   A. Validations
    $projectName = QueryInputString_ForNewSubFolder `
        -toFolderPath "$targetFolder" `
        -value $projectName `
        -varName "projectName" `
        -varAlias "name of your new project"
    #$userName = QueryInputString `
     #   -value $userName `
      #  -varName "userName" `
       # -varAlias "user name"

#   B. Confirmation
    ConfirmOrExit -message "
    Adding a node.js project to:
        Project name: $projectName
    "

# _______________________________________________________
# D. Process (own code here)
# _______________________________________________________

#   1. Secure shared folders
    cd $targetFolder
    CreateFolderIfNotExist -dirName _shared
    cd _shared
    CreateFolderIfNotExist -dirName release
    CreateFolderIfNotExist -dirName release\css
    CreateFolderIfNotExist -dirName release\js
    CreateFolderIfNotExist -dirName modules
    CreateFolderIfNotExist -dirName typings
    cd ..

#   2. Create project folders
    CreateFolderIfNotExist -dirName $projectName
    cd $projectName

    # Local folders
    CreateFolderIfNotExist -dirName _app
    CreateFolderIfNotExist -dirName _app\less
    CreateFolderIfNotExist -dirName _app\sass
    CreateFolderIfNotExist -dirName _app\ts
    CreateFolderIfNotExist -dirName _release
    CreateFolderIfNotExist -dirName _release\css
    CreateFolderIfNotExist -dirName _release\js
    CreateFolderIfNotExist -dirName .vscode
    CreateFolderIfNotExist -dirName node_modules
    CreateFolderIfNotExist -dirName typings

    # Link to shared folders
    cd _app
    CreateSymLinkIfNotExist -dirName _shared -linkToDirName ..\..\_shared\modules
    cd ..\_release
    CreateSymLinkIfNotExist -dirName _shared -linkToDirName ..\..\_shared\release
    cd ..\typings
    CreateSymLinkIfNotExist -dirName _shared -linkToDirName ..\..\_shared\typings
    cd ..


#   3.1 Write app files
    cd _app
    WriteFileIfNotExist -fileName index.html -content @"
<html>
	<head>
		<title>Hello world</title>
		<meta charset="utf-8">
	</head>
	<body>
		Hello world!
	</body>
</html>
"@
    WriteFileIfNotExist -fileName main.js -content @"
/// <reference path="../typings/node/node.d.ts"/>
var app = require('app');
var BrowserWindow = require('browser-window');
var mainWindow = null;

app.on('window-all-closed', function() {
 if (process.platform != 'darwin')
 app.quit();
});

app.on('ready', function() { 
    mainWindow = new BrowserWindow({width: 800, height: 600}); 
    mainWindow.loadUrl('file://' + __dirname + '/index.html'); 
    mainWindow.on('closed', function() {
        mainWindow = null;
    }); 
});
"@
    WriteFileIfNotExist -fileName tsconfig.json -content @"
{
    "compilerOptions": {
        "target": "es6",
        "noImplicitAny": true,
        "removeComments": true,
        "preserveConstEnums": true,
        "declaration": true,
        "noLibCheck": true,
        "sourceMap": true
    }
}
"@
    cd ..

#   3.2 Write project definition
    WriteFileIfNotExist -fileName .gitignore -content @"
# Folders to ignore
node_modules/
typings/
_app/_shared
_release/_shared
"@
    WriteFileIfNotExist -fileName package.json -content @"
{
    "name": "$projectName",
    "version": "0.1.0",
    "license": "UNLICENSED",
    "description": "My node application",
    "main": "main.js",
    "engine": "node => 4.2.3",
    "devDependencies": {
        "gulp": "^3.9.0",
        "gulp-less": "^3.0.5",
        "gulp-sass": "^2.1.1",
        "gulp-typescript": "^2.10.0",
        "merge2": "^0.3.6",
        "tsd": "^0.6.0-beta.5"
    },
    "dependencies": {
        "electron-prebuilt": "^0.36.2"
    }
}
"@
    WriteFileIfNotExist -fileName gulpfile.js -content @"
"use strict"

/*____________________________________________________________________________________________ */
// Required components
var _libraries = [];


/*____________________________________________________________________________________________ */
// Folder structure
var _localAppDir = "./_app"; // this is where the client application for elentron is written
var _sharedSrcDir = "./_app/_shared"; // symbolic link to the reusable stuff
var _sharedTsdDir = "./typings/_shared"; // this is where d.ts files are saved
var _localDistDir = "./_release"; 
var _sharedDistDir = "./_release/_shared";

/*____________________________________________________________________________________________ */
// Required components
var _build = require("gulp");
var _lessCompiler = require("gulp-less");
var _sassCompiler = require("gulp-sass");
var _typescriptCompiler = require("gulp-typescript");
var _mergeTask = require("merge2");
//var _project = require("./package.json");


/*____________________________________________________________________________________________ */
// Less compile task
_build.task("lessCompilerTaskForApp", function () {
  return _build.src(_localAppDir + "/less/**/*.less")
    .pipe(_lessCompiler())
    .pipe(_build.dest(_localDistDir + "/css"));
});

/*____________________________________________________________________________________________ */
// Sass compile task
_build.task("sassCompilerTaskForApp", function () {
  return _build.src(_localAppDir + "/sass/**/*.sass")
    .pipe(_sassCompiler())
    .pipe(_build.dest(_localDistDir + "/css"));
});

/*____________________________________________________________________________________________ */
// TypeScript compile and merge tasks (all into a single file)
var _typescriptProject = _typescriptCompiler.createProject(_localAppDir + "/tsconfig.json");
_build.task("typescriptCompilerTaskForApp", function() {
  var tsResult = _typescriptProject.src(_localAppDir + "/ts/**/*.ts")
    .pipe(_typescriptCompiler({
        outFile: "main.js"
      }));
       
  return _mergeTask([
    tsResult.js.pipe(_build.dest(_localDistDir + "/js"))
    ]);
});

/*____________________________________________________________________________________________ */
// TypeScript compile and merge tasks for libraries (all into a single file per library)
var _library = null;
var _libraryTitle = null;
var _libraryTypescriptProject = null;
var _tsResult = null;
if (_libraries.length > 0) {
    for(var i = 0; i < _libraries.length; ++i) {
        let _library = _libraries[i];
        let _libraryTitle = _library.name.charAt(0).toUpperCase() + _library.name.substr(1);
        _build.task("typescriptCompilerTaskFor" + _libraryTitle, function() {

            let _libraryTypescriptProject = _typescriptCompiler.createProject(_sharedSrcDir + "/" + _library.name + "/tsconfig.json");
            let _tsResult = _libraryTypescriptProject.src()
                .pipe(_typescriptCompiler({
                    outFile: _library.name + ".js", 
                    declaration: true 
                }));

            return _mergeTask([
                _tsResult.dts.pipe(_build.dest(_sharedTsdDir)),
                _tsResult.js.pipe(_build.dest(_sharedDistDir + "/js"))
                ]);
            });
    }
}

/*____________________________________________________________________________________________ */
// Watch
_build.task("fileWatch", function() {
    _build.watch(_localAppDir + "/less/**/*.less", ["lessCompilerTaskForApp"]);
    _build.watch(_localAppDir + "/sass/**/*.sass", ["sassCompilerTaskForApp"]);
    _build.watch(_localAppDir + "/ts/**/*.ts", ["typescriptCompilerTaskForApp"]);
    if (_libraries.length > 0) {
        for(var i = 0; i < _libraries.length; i++) {
            let _library = _libraries[i];
            let _libraryTitle = _library.name.charAt(0).toUpperCase() + _library.name.substr(1);
            _build.watch(_sharedSrcDir + "/" + _library.name + "/**/*.ts", ["typescriptCompilerTaskFor" + _libraryTitle]);
        }
    }
})
"@

#   3.3 VS Code files
    cd .vscode
    WriteFileIfNotExist -fileName launch.json -content @"
 {
	"version": "0.2.0",
	"configurations": [
		{
	            "name": "$projectName",
	            "type": "node",
	            "program": "_app/main.js", // important
	            "stopOnEntry": false,
	            "args": [],
	            "cwd": ".",
	            // next line is very important
	            "runtimeExecutable": "node_modules/electron-prebuilt/dist/electron.exe",
	            "runtimeArguments": [],
	            "env": { }, 
	            "sourceMaps": false
		}
	]
}
"@
    WriteFileIfNotExist -fileName tasks.json -content @"
{
    "version": "0.1.0",
    "command": "gulp",
    "isShellCommand": true,
    "args": [
        "--no-color"
    ],
    "tasks": [
        {
            "taskName": "fileWatch",
            "isBuildCommand": true,
            "showOutput": "always",
            "isWatching": true
        }
    ]
}
"@
    cd ..


#TODO
#npm install -g gulp
#npm install

#tsd install node
#tsd install gulp
#tsd install gulp-less
#tsd install gulp-sass
#tsd install gulp-typescript 
#tsd install merge2 




# _______________________________________________________
# E. Finalization (return to the working folder)
# _______________________________________________________
cd $global:__workingFolder
