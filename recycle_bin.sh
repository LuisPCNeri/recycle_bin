#!/bin/bash

# HOURS SPENT: 12
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
# FUNCTION: list_recycled
# DESCRIPTION: lists the recycled files, either in a compact table, or in a more detailed way (by calling list_recycled_detailed)
# PARAMETERS: $1: if $1="--detailed", calls list_recycled_detailed, else, shows a compact table of recycled files
# RETURNS: 0 on success
#############################
list_recycled() {
	# calls the detailed version of the function if the arg is "--detailed"
	echo "dollar1 is: $1"
	if [[ "$1" == "--detailed" ]]; then
		list_recycled_detailed
		return 0
	fi

	# handles the case where the metadata_file is empty
	if [[ ! -s "$METADATA_FILE" ]]; then
    	echo "Recycle bin is empty."
    	return 0
	fi

	# compact listing
	# table header
	printf "%-5s %-25s %-20s %-10s\n" "ID" "Name" "Date" "Size"
	printf "%-5s %-25s %-20s %-10s\n" "-----" "-------------------------" "--------------------" "----------"
	# printing the actual data
	while IFS=, read -r id name path date size type perm creator; do
    	readable_size=$(numfmt --to=iec $size) # makes size more readable
    	printf "%-5s %-25s %-20s %-10s\n" "$id" "$name" "$date" "$readable_size""B"
	done < "$METADATA_FILE"

	return 0
}

#############################
# FUNCTION: list_recycled_detailed
# DESCRIPTION: called by list_recycled() when "--detailed" is passed as an argument, shows a detailed view of recycled files
# PARAMETERS: none.
# RETURNS: 0 on success
#############################
list_recycled_detailed() {
	if [[ ! -s "$METADATA_FILE" ]]; then
    	echo "Recycle bin is empty."
    	return 0
	fi

	item_num=0
	total_size=0
	while IFS=, read -r id name path date size type perm creator; do
    	readable_size=$(numfmt --to=iec $size) # makes size more readable
    	echo "FILE NAME: $name"
		echo "ID: $id"
		echo "PATH: $path"
		echo "DATE: $date"
		echo "SIZE: ${size}B"
		echo "TYPE: $type"
		echo "PERMISSIONS: $perm"
		echo "CREATOR: $creator"
		item_num=$((item_num + 1))
		total_size=$((total_size + size))

		echo "-----------------------------------------"
	done < "$METADATA_FILE"

	readable_total_size=$(numfmt --to=iec $total_size)
	echo "-----------------------------------------"
	echo "Items in the recycle bin: $item_num"
	echo "Total size: ${total_size}B"

	return 0file or directory, only takes one argument
}

####################
# FUNCTION: search_recycled
# DESCRIPTION: Searches for files in the recycle bin
# PARAMETERS: $1 should be a file name or in the format "*.[FILE_EXTENSION]", $2, if equal to "-i", will make search case insensitive
# RETURNS: 0 on success
###################
search_recycled(){
	if [[ ! -s "$METADATA_FILE" ]]; then
    	echo "Recycle bin is empty."
    	return 0
	fi

	if [[ "$2" == "-i" ]]; then # turns case-insensitive matching on if the argument is present
		shopt -s nocasematch
	fi

	passed_arg="$1"
	files_found=0
	# compact listing
	# table header
	printf "%-5s %-25s %-20s %-10s\n" "ID" "Name" "Date" "Size"
	printf "%-5s %-25s %-20s %-10s\n" "-----" "-------------------------" "--------------------" "----------"
	# printing the actual data

	# detect if argument is a file extension search
	if [[ "$passed_arg" == *.* ]]; then # matches any string containing a dot
		# extract extension: get everything after last dot
		file_extension="${passed_arg##*.}"
		while IFS=, read -r id name path date size type perm creator; do
			if [[ "$name" == *.$file_extension ]]; then
				readable_size=$(numfmt --to=iec "$size") # makes size more readable
				printf "%-5s %-25s %-20s %-10s\n" "$id" "$name" "$date" "$readable_size""B"
				files_found=$((files_found + 1))
			fi
		done < "$METADATA_FILE"
	else 
		search_parameter="$passed_arg"
		while IFS=, read -r id name path date size type perm creator; do
			if [[ "$name" == *"$search_parameter"* ]]; then
				readable_size=$(numfmt --to=iec "$size") # makes size more readable
				printf "%-5s %-25s %-20s %-10s\n" "$id" "$name" "$date" "$readable_size""B"
				files_found=$((files_found + 1))
			fi
		done < "$METADATA_FILE"
	fi

	if [[ $files_found -eq 0 ]]; then
		echo "No files matching the search criteria were found."
	elif [[ $files_found -eq 1 ]]; then
		echo "Found $files_found file."
	else 
		echo "Found $files_found files."
	fi

	# turns case-insensitive matching off 
	shopt -u nocasematch

	return 0
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
		"list"|"-l")
			# list option
			# takes one argument, to choose between detailed and not detailed view
			list_recycled "${@:2}"
			;;
		"search"|"-s")
			# list option
			# takes one argument, a file name or a file extension
			search_recycled "${@:2}"
			;;
		*)
			# As no options are give it will be assumed that the option IS the delete option
			# Passes ALL arguments given to the script to the delete_file func
			delete_file "$@"
			;;
	esac
}
main $@
