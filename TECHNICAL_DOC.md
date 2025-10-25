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

### list_recycled function:
> Takes in an optional argument, "--detailed or "--d". If the argument is present, the function calls the function list_recycled_detailed. If not, the function loops over the lines of the metadata file (ignoring the header) and prints a table containing the IDs, names, dates and sizes of the files in the recycle bin. If the recycle bin is empty, a message is printed to notify the user.

### list_recycled_detailed function:
> Function is called when the optional argument "--detailed or "--d" is passed to the function list_recycled. The function loops over the lines of the metadata file (ignoring the header) and prints the names, IDs, paths, dates, sizes, types, permissions and creators of the files, separating the information of diferent files with a line of dashes. At the end, the total number of items in the recycle bin and their total size is printed. However, if the recycle bin is empty, a message is printed to notify the user.

### show_statistics function:
> Takes in no arguments. Loops over the lines of the metadata file (ignoring the header) to collect statistics to print to the terminal: the total number of items in the recycle bin (also displaying how many are directories and how many are files, and their percentages), the total size occupied by items in the recycle bin (also displaying how much size is occupied by directories and files separately, and their percentages), the average file size, and the names of the oldest deleted item and the newest deleted item.

## Design decisions and rationale

## Algorithm explanations

### initialyze recycle bin:

### File deleting algorithm:
> So the user runs the file deleting command with one or multiple arguments. First the delete_file function gets called with all the arguments the user gave but the first one that should be the -d option. Then it will loop through all the arguments given calling the collect_metadata_recursively function passing the file or directory as the argument. Inside the collect_metadata_recursively function the file_id local variable is initialyzed and the argument is saved both to $file and $dir this is because $file is subject to change during execution and $dir is not. First the function checks if the given argument is not a file and if it is the .recycle_bin structure, if so returns 1 and stops. After that it checks if the argument is a directory, if that is true it will iterate through all files or eventual directories inside it (where it would repeat this process) and calls itself to run the function for that specific file or directory. Then for each file it will call the get_file_metadata function passing the file as an argument and writing all of it's metadata to the metadata.db file and logging it to the recyclebin.log file. When it ends the recursion it immediately calls the get_file_metadata again but this time for the directory it just looped through. In the end we return to the delete_file function and with the use of the $OG_LOCATION and $FILE_ID global variables whose value was attributed to them in the get_file_metadata function we move the file or specified directory to the recycle bin.  

### File restoral algorithm:
> When the user runs the restore command all of it's arguments except the option are given to the restore_file function and it is called. First the restore_file function will loop through all of the arguments it was given and for each of them will call the restore_file_recursive function passing the current argument we have in the loop. Inside the restore_file_recursive function we save the function arg to $func_arg and then open the metadata.db with a while loop to read it line by line. For each line the read command is used separating the line by the commas and saving all of the information in an array $file_info. If the line is for some reason empty it will be skipped. Then a check to see if the file already exists at destination is made. If it is true and the file already exists the user is given three options that can be selected via the current terminal, first is to overwrite the file this option changes nothing and simply runs the rest of the function as is, second the user can choose to change the name of the file being restored and in this case a time stamp will be appended to the end of the filename, third the user can choose to cancel, this option will return 2 and stop executing going through the rest of the arguments if any were given. After this check if a match for the file id or file name was found we use the find command to get the absolute path of the file being restored using the file id to match it, then if the file is a directory the function iterates through all the files inside the directory and calls itself for each of them. If the file is not a directory it calls the restore_file_data giving the $file_info array as an argument. This function saves all imporatant file metadata to variables and then changes the file's name to it's original state, changes it's permissions back to their original state, saves it's current location in a global variable $RB_LOCATION and it's original location to $OG_LOCATION. Then it logs the operations made and finally it uses the sed command with the -i option to edit inline and looks for a line in the metadata-db file that matches the \${id} pattern, this is the line starts with the file's id and then deletes it. In the end if the recursion has ended we return to the restore_file_recursive function and find the current argument (directory we just iterated through) location in the recycle bin and use the same sed command as earlier but with the -n option and the p in the end to print the value it finds to save the file id to a variable and then call the restore_file_data function with these new variables. When restore_file_recursive is done running it returns $any_file_found that should be 1 if no file was found and 0 if one was found. We are now back to the restore_file function were a check will be made to see if any file was found and if not skip to the next argument or end. If a file was found we use the $RB_LOCATION and $OG_LOCATION variables to move the file or directory back to it's original location and log it.

### Empty recycle bin algorithm:
> empty_recyclebin is called, first it checks for the presence of the --force flag and if it is there changes the value of the force_flag variable to 1. Then if the user did not specify any files to be permanently deleted the function will simply empty everything in the recycle bin.<br>
> For that the perm_delete function will be called with the force_flag variable and the name or id of the file. In the perm_delete func a check is made to know if the --force flag was used and if it was not it asks the user for confirmation by inputing and entering a y or a n to the current terminal and stores that value in a variable. If the value is n the func stops running and returns 2.
> After the check the function starts to iterate through all lines of metadata.db and saves that line (separated by the commas) in an array. If that line has a match for the given file name or id it will save the file's absolute path in the recycle bin using the find funcion with the -name option. Then the func checks if the file is a directory or not, if it isn't it runs the del_metadata function that using the same sed -i command as last time deletes that entry from the metadata.db file and using rm -rf deletes the file permanently. If the file is a directory it iterates through all of it's contents running del_metadata for them and in the end gets it's path and runs del_metadata for the directories path and it's id and returns any_file_found.
> After all this if no file was found and perm_delete returned 1 the function informs the user and moves on to the next argument if there is one. If not empty_recyclebin retuns 0 and the program exits.

## Flowcharts for complex operations