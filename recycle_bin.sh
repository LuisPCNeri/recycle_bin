#!/bin/bash

# HOURS SPENT: 8
# Please do update the counter :)
# TS WILL ACTUALLY MAKE ME KMS HOLYYY

# GLOBAL VARIABLES
RECYCLE_BIN_DIR="$HOME/.recycle_bin"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"

initialyze_recyclebin(){
	#SHOULD PROBABLY CHECK IF EXISTS PATH WITH THAT NAME
	#To create the recycle bin directories
	mkdir "$RECYCLE_BIN_DIR"
	mkdir "$RECYCLE_BIN_DIR/files"
	touch "$METADATA_FILE"
	touch "$RECYCLE_BIN_DIR/config"
	touch "$RECYCLE_BIN_DIR/recyclebin.log"	
}

####################
# FUNCTION: get_file_metadata
# DESCRIPTION: Gets the metadata from the given file and writes it to the metadata.db file in the recycle bin
# PARAMETERS: $1 should be a file or directory, only takes one argument
# RETURNS: 0 on success
###################
get_file_metadata(){
	file="$1"
	file_id="0"
	# Get all metadata from each file
        permissions=$(stat -c %a $file)
        file_creator=$(stat -c %U:%G $file)
        deletion_time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        original_path=$(realpath $file)
        file_name="${file##*/}"
        file_size=$(stat -c %s $file)
        file_type=$(file $file)

        # Write to metadata.db file
        # Checks if METADATA_FILE is empty and if so gives the first file an ID of 1
        if [ -s $METADATA_FILE ]; then
        	file_id=$(tail -1 $METADATA_FILE | cut -d "," -f1)
                echo "$((file_id+1)),$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> $METADATA_FILE
                echo "Created data: $((file_id+1)),$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator"
		mv "$file" "${file%/*}/$((file_id+1))"
        else
                file_id="1"
                echo "$file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> $METADATA_FILE
                echo "Created data: $file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator"
		mv "$file" "${file%/*}/$file_id"
        fi
	return "$((file_id + 1))"
}

###############################
# FUNCTION: collect_metadata_recursively
# DESCRIPTION: Loops through all the files given in the delete_file function recursively, including directories
# PARAMETERS: $1 should be a file or directory
# RETURNS: 0 on success, -1 on failure
##############################
collect_metadata_recursively(){
	local file_id="0"
	local file="$1"
	local dir="$1"
        if ! [[ -f $file || -d $file ]]; then
        	echo "All arguments given MUST be files or directories"
                echo "$file is NOT a file or directory"         
                exit -1
        elif [[ "${file##*/}" == ".recycle_bin" ]]; then
                echo "Must not delete the recycle bin structure."
                exit -1
        fi
        # Checks if arguments is a directory and if it is NOT empty then removes adds to recycle bin
        if [[ -d $file ]]; then
		# Goes through each file in the directory and gets it's metadata
                for recursive_file in "$file"/*; do
                        [[ ! -e "$recursive_file" ]] && continue
                        collect_metadata_recursively $recursive_file
            	done
		# Gets the directory's metadata
		get_file_metadata "$dir"
		file_id="$?"
		return "$file_id"
	else
		# Gets the metadata from files in the directory
		get_file_metadata "$file"
		file_id="$?"
        fi
	return "$file_id"
}

################################
# FUNCTION: delete_file
# Description: Moves all files or directories given as an argument to .recycle_bin/files/ and writes important file data to the metadata.db file whilst logging it in the metadata.log
# PARAMETERS: $@ Should be any number of arguments but they MUST be a file or directory (Empty or non empty both work)
# RETURNS: 0 on success and -1 on failure
################################
delete_file(){
	# Func to move file from source to recycle bin writing its information to the metadata.db file
	for file in $@; do
		# Just moves the files from their original location to the recycle bin
		local dir="$file"
		collect_metadata_recursively "$file"
		mv "${file%%/*}/$?" "$RECYCLE_BIN_DIR/files/"
		echo "Moved $dir from $(realpath $dir) to $RECYCLE_BIN_DIR/files"
	done
	return 0
}

#############################
# FUNCTION: display_help
# DESCRIPTION: Shows information on how the script is used with examples and all options available
# PARAMETERS: None, again it is just an help function to show the script should be used and well... help
# RETURNS: 0 ig doubt the HELP func fails
############################
display_help(){
	# Main script explanation HERE
	echo -e "Usage: ./recycle_bin.sh [OPTION] [FILE]..\nDoes everything a recycle bin should do I hope THIS MUST BE MADE BETTER\n"
	# initialyze_recyclebin help
	echo "-i, init			Creates the recycle bin directory in your working directory"
	# delete func help
	echo "-d, delete		Move all files or directories to the recycle bin"
}

#############################
# FUNCTION: main
# DESCRIPTION: Handles all script options
# PARAMETERS: $1 is the script option (by default option will be delete) "${$@:2}" will be the function params
# RETURNS: 0 on success, -1 on failure
#############################
main(){

	# Will be a MASSIVE case statement as for I know not of a better way to check for ALL options
	# DEFAULT OPTION will be the delete option to remove the specified files
	
	case "$1" in
		"init"|"-i")
			# initialyze_recyclebin option
			# Creates the .recycle_bin structure in the user's pc more specifically the working directory
			initialyze_recyclebin
			;;
		"delete"|"-d")
			# delete option
			# Passes all args BUT THE FIRST (as the first IS the option used)  to the delete_file func
			delete_file "${@:2}"
			;;
		"--help")
			# help Option
			# Takes no args because well it is just an help option
			display_help
			;;
		*)
			# As no options are give it will be assumed that the option IS the delete option
			# Passes ALL arguments given to the script to the delete_file func
			delete_file "$@"
			;;
	esac
}
main $@
