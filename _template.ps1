# _______________________________________________________
# A. Constructor
# _______________________________________________________
param ( # (own code here)
    [string]$targetFolder = $PSScriptRoot,
    [string]$projectName = ""
)

# _______________________________________________________
# B. Static (version controlled)
# _______________________________________________________
#   A. Vars
    Write-Host "..."
    $__workingFolder = $PSScriptRoot #TODO: user may set a path to the script root
    $__missingInputCount = 0

#   A. Validation functions
    function InformInvalidInput($message) {
        Write-Host "> $message" -foregroundcolor "red"
    }
    function HandleMissingInput() {
        if ($__missingInputCount -eq 0) {
            Write-Host "> $message" -foregroundcolor "red"
        }
        $__missingInputCount = $__missingInputCount + 1
    }
    function QueryInput($varName, $varAlias, $value) {
        return $( Read-Host "Q$__missingInputCount. Please enter $varAlias (or press Ctrl+C to cancel)" )
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

# _______________________________________________________
# C. Validations & Confirmation (own code here)
# _______________________________________________________
#   A. Validations
    $projectName = QueryInputString_ForNewSubFolder `
        -toFolderPath "$targetFolder" `
        -value $projectName `
        -varName "projectName" `
        -varAlias "name of your new project"

#   B. Confirmation
    ConfirmOrExit -message "
    Adding a node.js project to:
        Project name: $projectName
        Project folder: $_projectFolder
    "

# _______________________________________________________
# D. Process (own code here)
# _______________________________________________________
$_projectFolder = $targetFolder + '\' + $projectName

CreateFolderIfNotExist -dirName _shared
CreateFolderIfNotExist -dirName KA6.Modules
CreateFolderIfNotExist -dirName KA6.Modules.Electron

WriteFileIfNotExist -fileName sample.txt -content 'This is line 1
This is line 2'

cd _shared
CreateFolderIfNotExist -dirName pub

# _______________________________________________________
# E. Finalization (return to the working folder)
# _______________________________________________________
cd $__workingFolder
