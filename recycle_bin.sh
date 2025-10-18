#!/bin/bash

# HOURS SPENT: 9
# HOURS SPENT2: ~~ Poe as tuas aqui gui
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
						# If for some ungodly reason nothing exists in "$file"/* just skip over it
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
# FUNCTION: restore_file
# DESCRIPTION: Restores given file to it's original location
# PARAMETERS: $1 MUST be filename or file's id in the recycle bin
# RETURNS: 0 on success, -1 on failure
#############################
restore_file(){
	# First argument is the filename or id guess i'll have to do like a slave and check for both
	if ! [ $1 ]; then
		echo "Argument MUST be the name of a file or it's id in the recycle bin"
		exit -1
	fi

	for i in $@; do

		func_arg="$i"
		# Will loop thru the metadata.db file and if it finds something that computes recover it. If not fuck you.
		while read line;do
			# Variable names are self explanatory if this calls for a comment i WILL kms
			# Gets all file metadata for each file but it is whatever
			# Should make $line into an array with the info https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash 18/10/25 15:40
			IFS=',' read -r -a file_info <<< "$line"
			file_id="${file_info[0]}"
			filename="${file_info[1]}"

			# Checks if it is an empty line if so skips over it
			if [[ "$line" == "" ]]; then
				continue
			fi

			if [[ "$file_id" == "$func_arg" ]] || [[ "$filename" == "$file_arg" ]]; then
				# Found ze file i am zerman now
				file=$(find "$HOME/.recycle_bin/files/" -name "${file_info[0]}")
				# File is found now to actually restore it
				og_file_location="${file_info[2]}"
				og_file_perms="${file_info[6]}"
				echo "${file_info[@]}"

				# Change file's name back
				echo "Changed name from $file to ${file_info[2]%/*}/$filename"
				mv "$file" "${file%/*}/$filename"
				file="${file%/*}/$filename"
				# Restore perms
				echo "Changed perms to $og_file_perms"
				chmod "$og_file_perms" "$file"
				
				# Move it back
				echo "Restored file to ${file_info[2]%/*}/"
				mv "$file" "${file_info[2]%/*}/"

				# Erase corresponding line from file
				# -i edits file in place ^ to match it to the start of the file so in this case ^{$file_id} anything that starts with that file id
				# So to explain better What is between / and / is the expression so starts with $file_id and ends is a comma should be deleted
				# That is what the d in the end does
				# Links used:
				# https://www.geeksforgeeks.org/linux-unix/sed-command-in-linux-unix-with-examples/
				# https://www.geeksforgeeks.org/linux-unix/sed-command-linux-set-2/
				sed -i "/^${file_id},/d" "$METADATA_FILE"
			fi
		done < "$METADATA_FILE"
	done
	
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
	# restore_file func help
	echo "-r, restore		Restore a file or directory"
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
		"restore"|"-r")
			# restore option
			restore_file "${@:2}"
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
