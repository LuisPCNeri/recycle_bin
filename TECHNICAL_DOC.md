# TECHNICAL DOC

## System architecture Diagram

## Data flow diagrams

## Metadata schema explanation

## Function descriptions

### initialyze_recyclebin function:
> Creates the .recycle_bin structure in the user's home directory. If the function is called when the .recycle_bin structure already exists inside the user's computer then the metadata.db file and the recyclebin.log file will be reset to their original state and all files will be removed from the recycle bin.

### generate_unique_id function:
> When a file is deleted this function is called and it generates a unique id for the file being deleted. Id takes the format of the time it was generated (timestamp) plus a random assortment of 6 numbers or letters.

### get_file_metadata function:
> Takes in a file as argument and creates it's metadata. The metadata follows the structure ID,FILENAME,ORIGINALPATH,TIMESTAMP,SIZE,TYPE,PERMISSIONS,USER<br>
> This is a function created to be called recursively when deleting files or nested directories.<br>
> Also logs the operations executed by the funtion in the recyclebin.log file

### collect_metadata_recursively function:
> Takes in a file or directory to delete. Checks if the argument given is not valid since only files and directories can be deleted. Also checks if the file the user is trying to delete is the .recycle_bin structure and if so stops the user.<br>

### delete_file function:
> Main function to delete files. Calls the collect_metadata_recursively function and in the end moves the file or directory passed as an argument (and all of it's contents) to the recycle bin.
> Logs it's operations on log file
> Returns 0 on success

### restore_file_data function:
> Takes in the file's metadata and the complete path to the file in the recycle bin as arguments. Restores the file to it's original state and deletes it's metadata entry. Logs operations made to the log file. Returns 0 on success.

### restore_file_recursive function:
> Takes in the original name of a deleted file or directory or it's id in the recycle bin as argument and calls the restore_file_data function. Before calling restore_file_data checks for path conflicts with other files at destination and gives the user options on how to proceed. If the given argument is a directory iterates through all it's contents and then moves the original directory along with everything else to their original path. Returns 0 on success 1 on failure and 2 on operation cancellation.

### restore_file function:
> Main funtion to restore files. Takes in one or multiple arguments with them being the original name of a deleted file or it's id in the recycle bin and calls the restore_file_recursive function. Moves the file or directory (along with all it's contents) to their original path. Checks if any file matching the argument the user gave was found and if not informs the user and stops running. Logs it's operations in the log file.

### del_metadata function:
> Takes in the absolute path of a file in the recycle bin and it's file in the recycle bin as arguments. Finds the corresponding entry int the METADATA_FILE and uses rm -rf on it deleting it permanently. Logs it's operations in the log file and retuns 0 on success. Logs ALL emptying operations in the log file.

### perm_delete function:
> Takes as arguments an option "--force" or "-f" to not ask for permission when deleting files and the original name of a file in the recycle bin or it's id. Then recursively (for directories) runs del_metadata for the corresponding file. Returns 0 on success and 1 on failure.

### empty_recyclebin function:
> Main function to permanently delete files. Takes as arguments the original name or id of one or multiple deleted files or directories. If no arguments are given simply empites all of the recycle bin contents. Checks if no match was found and if so informs the user. returns 0 on success.

### display_help function:
> Takes in no arguments. Displays information on all options for the recycle_bin.sh script and a simple explanation on how to use them.

## Design decisions and rationale

## Algorithm explanations

## Flowcharts for complex operations