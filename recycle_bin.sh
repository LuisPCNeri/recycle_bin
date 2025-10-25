#!/bin/bash

# HOURS SPENT: 22
# Please do update the counter :)
# TS WILL ACTUALLY MAKE ME KMS HOLYYY

# LOAD CONFIG
# this lets us use $MAX_SIZE_MB and $RETENTION_DAYS
source "$RECYCLE_BIN_DIR/config"

# GLOBAL VARIABLES
RECYCLE_BIN_DIR="$HOME/.recycle_bin"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"
RECYCLEBIN_LOG_FILE="$RECYCLE_BIN_DIR/recyclebin.log"

# Variables to help with file restoration
RB_LOCATION=""
OG_LOCATION=""

FILE_ID=""

# Color Codes (optional but recommended)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

initialyze_recyclebin(){
	#To create the recycle bin directories
	mkdir -p "$RECYCLE_BIN_DIR"
	echo "Created $RECYCLE_BIN_DIR"
	mkdir "$RECYCLE_BIN_DIR/files"
	echo "Created $RECYCLE_BIN_DIR/files"
	touch "$METADATA_FILE"
	echo "Created $METADATA_FILE"
	cat > "$RECYCLE_BIN_DIR/config" <<EOL
MAX_SIZE_MB=1024
RETENTION_DAYS=30
EOL
	echo "Created $RECYCLE_BIN_DIR/config"
	echo "MAX_SIZE_MB=1024 ; RETENTION_DAYS=30"
	touch "$RECYCLE_BIN_DIR/recyclebin.log"	
	echo "Created $RECYCLE_BIN_DIR/recyclebin.log"

	echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
	echo -e "${GREEN}Finished creating Recycle Bin.${NC}"
}

generate_unique_id() {
	local timestamp=$(date +%s%N)
	local random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
	echo "${timestamp}_${random}"
}

####################
# FUNCTION: get_file_metadata
# DESCRIPTION: Gets the metadata from the given file and writes it to the metadata.db file in the recycle bin
# PARAMETERS: $1 should be a file or directory, only takes one argument
# RETURNS: 0 on success
###################
get_file_metadata(){
	file="$1"
	# Get all metadata from each file
        permissions=$(stat -c %a $file)
        file_creator=$(stat -c %U:%G $file)
        deletion_time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        original_path=$(realpath $file)
        file_name="${file##*/}"
        file_size=$(stat -c %s $file)
		
		# To decide if file is a directory or file
		file_type=''
		if [ -d $file ]; then
			file_type='Directory'
		else
			file_type='File'
		fi

		file_id=$(generate_unique_id)
        echo "$file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> "$METADATA_FILE"
		# Log operation in recyclebin.log
		echo "FILE: $file. Generated METADATA: $file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> "$RECYCLEBIN_LOG_FILE"
		
        echo -e "${GREEN}Created data: $file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator ${NC}"
		OG_LOCATION="${original_path%/*}"
		mv "$file" "${original_path%/*}/$file_id"
		FILE_ID="$file_id"
}

###############################
# FUNCTION: collect_metadata_recursively
# DESCRIPTION: Loops through all the files given in the delete_file function recursively, including directories
# PARAMETERS: $1 should be a file or directory
# RETURNS: 0 on success, 1 on failure
##############################
collect_metadata_recursively(){
	local file_id="0"
	local file="$1"
	local dir="$1"
    if ! [[ -f "$file" || -d "$file" ]]; then
        echo "All arguments given MUST be files or directories"
            echo -e "${RED}$file is NOT a file or directory${NC}"         
            return 1
    elif [[ "${file##*/}" == ".recycle_bin" ]]; then
            echo -e "${RED}Must not delete the recycle bin structure.${NC}"
            return 1
    fi
    # Checks if arguments is a directory and if it is NOT empty then removes adds to recycle bin
    if [[ -d $file ]]; then
	# Goes through each file in the directory and gets it's metadata
            for recursive_file in "$file"/*; do
					# If for some ungodly reason nothing exists in "$file"/* just skip over it
                    [[ ! -e "$recursive_file" ]] && continue
                    collect_metadata_recursively "$recursive_file"
            done
		# Gets the directory's metadata
		get_file_metadata "$dir"
	else
		# Gets the metadata from files in the directory
		get_file_metadata "$file"
    fi
}

################################
# FUNCTION: delete_file
# DESCRIPTION: Moves all files or directories given as an argument to .recycle_bin/files/ and writes important file data to the metadata.db file whilst logging it in the metadata.log
# PARAMETERS: $@ Should be any number of arguments but they MUST be a file or directory (Empty or non empty both work)
# RETURNS: 0 on success and 1 on failure
################################
delete_file(){
	# Func to move file from source to recycle bin writing its information to the metadata.db file
	for file in "$@"; do
		# Just moves the files from their original location to the recycle bin
		local dir="$file"
		collect_metadata_recursively "$file"

		mv "$OG_LOCATION/$FILE_ID" "$RECYCLE_BIN_DIR/files/"
		echo -e "${GREEN}Moved $file from $(realpath $dir) to $RECYCLE_BIN_DIR/files ${NC}" 
		
		# Log Operation
		echo "FILE: $file. Moved from $(realpath $dir) to $RECYCLE_BIN_DIR/files" >> "$RECYCLEBIN_LOG_FILE"
	done
	return 0
}
################################
# FUNCTION: restore_file_data
# DESCRIPTION: restores file's data without moving it back accordingly to it's metadata
# PARAMETERS: $1 -> Absolute path to the file in recycle bin, ${@:2} -> file's metadata array
# RETURNS: 0 on success
################################
restore_file_data(){
	file="$1"
	id="$2"
	name="$3"
	og_location="$4"
	perms="$8"
			
	# Change file's name back
	echo "Changed name from $file to ${file%/*}/$name"
	mv "$file" "${file%/*}/$name"
	file="${file%/*}/$name"
	# Restore perms
	echo "Changed perms to $perms"
	chmod "$perms" "$file"
				
	RB_LOCATION="$file"
	OG_LOCATION="${og_location%/*}/"

	echo -e "${GREEN}Restored $file info.${NC}"

	# Log operations
	echo "FILE: $file. Restored file name to $name. Restored perms to $perms" >> "$RECYCLEBIN_LOG_FILE"

	# Erase corresponding line from file
	# -i edits file in place ^ to match it to the start of the file so in this case ^{$file_id} anything that starts with that file id
	# So to explain better What is between / and / is the expression so starts with $file_id and ends is a comma should be deleted
	# That is what the d in the end does
	# Links used:
	# https://www.geeksforgeeks.org/linux-unix/sed-command-in-linux-unix-with-examples/
	# https://www.geeksforgeeks.org/linux-unix/sed-command-linux-set-2/
	sed -i "/^${id},/d" "$METADATA_FILE"

	# Log
	echo "FILE: $file. Removed file metadata entry (WITH RESTORE)" >> "$RECYCLEBIN_LOG_FILE"

	return 0
}
###########################
# FUNCTION: restore_file_recursive
# DESCRIPTION: Restores the file to it's original state giving it's permissions and name back
# PARAMETERS: The name or Id of a file in the recycle bin
# RETURNS: 0 on success, 1 on failure
###########################
restore_file_recursive(){
	local func_arg="$1"
	# Flag to determine if any match was found in the metadata file assumed false
	local any_file_found="1"

	while read line;do
		# Variable names are self explanatory if this calls for a comment i WILL kms
		# Gets all file metadata for each file but it is whatever
		# Should make $line into an array with the info https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash 18/10/25 15:40
		IFS=',' read -r -a file_info <<< "$line"
		local file_id="${file_info[0]}"
		local filename="${file_info[1]}"

		# Checks if it is an empty line if so skips over it
		[[ "$line" == "" ]] && continue

		# TODO Check for errors and solve them

		# Check if file already exists at destination
		if [[ -e "${file_info[2]}" ]]; then
			echo -e "${RED}File already exists at destination.${NC}"

			# Options for user
			r_options=("Overwrite", "Restore with modified name", "Cancel")
			PS3="Choose how you want to proceed:"

			# Let user choose what to do in case of the file already existing
			select option in "${r_options[@]}"; do
				case $REPLY in
					1)	echo -e "${YELLOW}${file_info[2]} will be replaced with the restored file.${NC}"; break ;;
					2)
						filename+=$(date "+%Y-%m-%d_%H:%M:%S")
						echo -e "${GREEN}Filename will now be $filename.${NC}"
						break
						;;
					3) 
						echo -e "${RED}Operation will canceled. All existing changes will NOT be reverted.${NC}"
						exit 2
						;;
					*) echo -e "${RED}Invalid option, please try again.${NC}" ;;
				esac
			done < /dev/tty
		fi

		#TODO Check for existance of parent directories if not well 1 kys 2 create them or whatever not feelig like dooing this one today

		if [[ "$file_id" == "$(basename $func_arg)" ]] || [[ "$filename" == "$(basename $func_arg)" ]]; then
			# A file was found so $any_file_found should now be true
			any_file_found="0"

			file2="$(find "$RECYCLE_BIN_DIR/files/" -name "$file_id")"

			if [[ "${file_info[5]}" == 'Directory' ]]; then
				for r_file in "$file2"/*; do
					[[ ! -e "$r_file" ]] && continue
					restore_file_recursive "$r_file"
				done

				# So to have it get the correct info when it exits the recursion loop
				# $file_id contains the correct id for the directory we just iterated through
				# Get the absolute path for the supposed dir
				local dir="$(find "$RECYCLE_BIN_DIR/files/" -name "$file_id")"
				# Get the dir's info from the metadata file
				local info=$(sed -n "/^${file_id},/p" "$METADATA_FILE")

				# Break it into an array to conform with the restorer func
				IFS=',' read -r -a info_arr <<< "$info"

				# Restore it's data
				restore_file_data "$dir" "${info_arr[@]}"
			else
				restore_file_data "$file2" "${file_info[@]}"
			fi
		fi
	done < "$METADATA_FILE"

	return "$any_file_found"
}
#############################
# FUNCTION: restore_file
# DESCRIPTION: Restores given file to it's original location
# PARAMETERS: $1 MUST be filename or file's id in the recycle bin
# RETURNS: 0 on success, 1 on failure
#############################
restore_file(){
	for arg in $@; do
		restore_file_recursive "$arg"
		
		# Checks restore_file_recursive return value to see if any file matching the name or id was found
		if [[ "$?" == "1" ]]; then
			echo -e "${RED}No file matching \"$arg\" was found. ${NC}"
			continue
		fi

		echo -e "${GREEN}Restored $RB_LOCATION to $OG_LOCATION ${NC}"
		mv "$RB_LOCATION" "$OG_LOCATION"

		# Log
		echo "FILE: $arg. Restored file to it's original location." >> "$RECYCLEBIN_LOG_FILE"
	done

	return 0
}
##############################
# FUNCTION: del_metadata
# DESCRIPTION: Deletes a the metadata from a file and perm removes it
# PARAMETERS: $1 Absolute file path $2 file id in rb
# RETURNS: 0 on success
##############################
del_metadata(){
	local file="$1"
	local file_id="$2"
	# Remove metadata entry from file
	sed -i "/^${file_id},/d" "$METADATA_FILE"
	echo -e "${GREEN}Update the metadata.db file.${NC}"

	# Log
	echo "FILE: $file. Removed file metadata entry (WITH EMPTY)." >> "$RECYCLEBIN_LOG_FILE"

	# Perm delete the file
	# Find the file in the recycle bin first
	del_file=$(find "$HOME/.recycle_bin/files/" -name "${file_id}")

	# REMOVE
	rm -rf "$del_file"
	echo -e "${GREEN}Deleted file $del_file ${NC}"

	# Log
	echo "FILE: $file. Permanently deleted file." >> "$RECYCLEBIN_LOG_FILE"

	return 0
}
#############################
# FUNCION: perm_delete
# DESCRIPTION: Deletes permanently all files given as arguments and any files that may be contained within them (if file is a directory of course)
# PARAMETERS: $1 is the --forced option flag {$@:2} are the files or directories to perm delete
# RETURNS: 0 on success, 1 on failure, 2 on operation canceled
#############################
perm_delete(){
	local file="$2"
	local isForce="$1"
	local any_file_found="1"
	local f_line=$(tail -1 "$METADATA_FILE")

	local fn=$(basename "$file")

	# If the --force option was used then it will NOT ask for confirmation
	if [[ "$isForce" == 0 ]]; then
		echo -e "${YELLOW}Are you sure you want to delete this file ($file)? (y/n) ${NC}"
		read response < /dev/tty

		if [[ "${response,,}" == "n" ]]; then 
			echo -e "${GREEN}Operation was successfully cancelled."
			return 2
		fi
	fi

	while read line; do
		# Checks if the last line of file is the one with the header and if so breaks
		[[ "$f_line" == "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" ]] && return 0

		IFS=',' read -r -a metadata <<< "$line"
		local file_id="${metadata[0]}"
		local filename="${metadata[1]}"

		if [[ "$fn" == "$file_id" || "$fn" == "$filename" ]]; then
			file2="$(find "$RECYCLE_BIN_DIR/files/" -name "$file_id")"

			if [[ "${metadata[5]}" == "Directory" ]]; then
				for rec_file in "$file2"/*; do
					[[ ! -e "$rec_file" ]] && continue
					# you have already confirmed you want THE DIRECTORY deleted why confirm the rest?
					perm_delete "1" "$rec_file"
					# perm_delete "0" "$(basename $rec_file)"
				done
				
				local dir="$(find "$RECYCLE_BIN_DIR/files/" -name "$file_id")"

				del_metadata "$dir" "$file_id"
			else
				del_metadata "$file" "$file_id"
			fi

			any_file_found="0"
		fi
	done < "$METADATA_FILE"

	return "$any_file_found"
}

#############################
# FUNCTION: empty_recyclebin
# DESCRIPTION: Either empties the whole recycle bin removing all present deleted files or permanently deletes just one file
# PARAMETERS: Either name or ID of file/files to permanently delete or nothing (to delete everything)
# RETURNS: 0 on success (find it hard to believe it will somehow fail but) 1 on failure
#############################
empty_recyclebin(){
	local args="$@"
	local force_flag="0"

	# Checks if --force option was used and saves it in a flag
	[[ "${args[0]}" == "--force" || "${args[0]}" == "-f" ]] && force_flag=1 

	# Delete everything in the recycle bin
	if [[ "$#" == "0" || "$#" == "1" && "$force_flag" == 1 ]]; then
		for file in "$RECYCLE_BIN_DIR/files"/*; do
			perm_delete "$force_flag" "$(basename $file)"

			if [[ "$?" == "1" ]]; then
				echo -e "${RED}No file matching \"$file\" was found. ${NC}"
				continue
			fi
		done

		return 0
	fi

	for file in "$args"; do
		perm_delete "$force_flag" "$file"

		if [[ "$?" == "1" ]]; then
			echo -e "${RED}No file matching \"$file\" was found. ${NC}"
			continue
		fi
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
	# TODO Make better lol
	# Main script explanation HERE
	echo -e "Usage: ./recycle_bin.sh [OPTION] [FILE]..\nDoes everything a recycle bin should do I hope THIS MUST BE MADE BETTER\n"

	echo "If no options are used by default recycle bin will list its contents."

	# initialyze_recyclebin help
	echo -e "-i, init		./recycle_bin.sh -i 					Creates the recycle bin directory in your working directory\n"
	# delete func help
	echo -e "-d, delete		./recycle_bin.sh -d [FILES]..			Move all files or directories to the recycle bin\n"
	# restore func help
	echo -e "-r, restore	./recycle_bin.sh -r [FILES]..			Restore files from recycle bin to their original locations.\n"
	# empty func help
	echo -e "-e, empty		./recycle_bin.sh -e [FILES]..			Permanently deletes specified files OR everything in recycle bin if no files were specified.\n"

	echo -e "--force, -f	./recycle_bin.sh -e --force [FILES]..	Permanently delestes specified files OR everything in recycle bin if no files were specified but does not ask for confirmation.\n"
}
#############################
# FUNCTION: list_recycled
# DESCRIPTION: lists the recycled files, either in a compact table, or in a more detailed way (by calling list_recycled_detailed)
# PARAMETERS: $1: if $1="--detailed", calls list_recycled_detailed, else, shows a compact table of recycled files
# RETURNS: 0 on success
#############################
list_recycled() {
	# calls the detailed version of the function if the arg is "--detailed"
	if [[ "$1" == "--detailed" || "$1" == "--d" ]]; then
		list_recycled_detailed
		return 0
	fi

	# handles the case where the metadata_file is empty
	if [[ ! -s "$METADATA_FILE" ]]; then
    	echo "Recycle bin is empty."
		echo "No header was found in the metadata file!"
    	return 0
	fi

	item_num=0
	# compact listing
	# table header
	printf "%-5s %-25s %-20s %-10s\n" "ID" "Name" "Date" "Size"
	printf "%-5s %-25s %-20s %-10s\n" "-----" "-------------------------" "--------------------" "----------"
	# printing the actual data
	while IFS=, read -r id name path date size type perm creator; do
		if [[ $item_num -gt 0 ]]; then
			readable_size=$(numfmt --to=iec $size) # makes size more readable
			printf "%-5s %-25s %-20s %-10s\n" "$id" "$name" "$date" "$readable_size""B"
		fi
		item_num=$((item_num + 1))
	
	if [[ $item_num -eq 0 ]]; then
    	echo "Recycle bin is empty."
    	return 0
	fi
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
	# TODO Still not working twin
	if [[ ! -s "$METADATA_FILE" ]]; then
    	echo "Recycle bin is empty."
		echo "No header was found in the metadata file!"
    	return 0
	fi

	item_num=0
	total_size=0
	while IFS=, read -r id name path date size type perm creator; do
		if [[ $item_num -gt 0 ]]; then
			readable_size=$(numfmt --to=iec $size) # makes size more readable
			echo "FILE NAME: $name"
			echo "ID: $id"
			echo "PATH: $path"
			echo "DATE: $date"
			echo "SIZE: ${size}B"
			echo "TYPE: $type"
			echo "PERMISSIONS: $perm"
			echo "CREATOR: $creator"
			total_size=$((total_size + size))
		fi
		item_num=$((item_num + 1))

		echo "-----------------------------------------"
	done < "$METADATA_FILE"

	item_num=$((item_num - 1))
	if [[ $item_num -eq 0 ]]; then
    	echo "Recycle bin is empty."
    	return 0
	fi
	
	readable_total_size=$(numfmt --to=iec $total_size)
	echo "-----------------------------------------"
	echo "Items in the recycle bin: $item_num"
	echo "Total size: ${total_size}B"

	return 0
}

####################
# FUNCTION: show_statistics
# DESCRIPTION: Displays statistics regarding the recycle bin, such as total number of items (also broke down by file type), average file size, and oldest and newest items, as well as total storage used 
# PARAMETERS: none
# RETURNS: 0 on success
###################

show_statistics() {
	total_item_num=0
	file_item_num=0
	dir_item_num=0

	file_item_size=0
	dir_item_size=0 
	total_size=0

	# for date comparisons
	oldest_ts=9999999999
	newest_ts=0
	oldest_name=""
	newest_name=""
	oldest_date=""
	newest_date=""

	while IFS=, read -r id name path date size type perm creator; do
		if [[ $total_item_num -gt 0 ]]; then
			if [[ $type == "Directory" ]]; then # distinction between normal files and directories
				dir_item_num=$((dir_item_num + 1))
				dir_item_size=$((dir_item_size + size)) 
			else
				file_item_num=$((file_item_num + 1)) 
				file_item_size=$((file_item_size + size)) 
			fi

			# convert date to timestamp for comparison
			ts=$(date -d "$date" +%s 2>/dev/null)
			if [[ -n "$ts" ]]; then
				if (( ts < oldest_ts )); then
					oldest_ts=$ts
					oldest_name="$name"
					oldest_date="$date"
				fi
				if (( ts > newest_ts )); then
					newest_ts=$ts
					newest_name="$name"
					newest_date="$date"
				fi
			fi

		fi
		total_item_num=$((total_item_num + 1)) 

	done < "$METADATA_FILE"

	total_item_num=$((total_item_num - 1))

	total_size=$((file_item_size + dir_item_size))

	# calculating percentages of the dir and file sizes relative to the total size
	dir_size_percent=0 # default zero
	file_size_percent=0 
	if [[ $total_size -ne 0 ]]; then # prevent division by zero
		dir_size_percent=$((dir_item_size * 100 / total_size))
		file_size_percent=$((100 - dir_size_percent))
	fi

	average_file_size=0 # default zero, again
	if [[ $total_item_num -ne 0 ]]; then # prevent division by zero
		average_file_size=$((total_size / total_item_num))
	fi

	# making sizes more readable
	readable_average_file_size=$(numfmt --to=iec $average_file_size)
	readable_total_size=$(numfmt --to=iec $total_size)
	readable_dir_size=$(numfmt --to=iec $dir_item_size)
	readable_file_size=$(numfmt --to=iec $file_item_size)

	echo "-------------------------------------------------------------------"
	echo "RECYCLE BIN STATISTICS"
	echo "-------------------------------------------------------------------"
	# information display
	# number of items
	echo "Number of items in the recycle bin: ${total_item_num}"
	echo "By type: directories - ${dir_item_num} ; files - ${file_item_num}"
	echo "-------------------------------------------------------------------"
	# size
	echo "Total storage usage: ${readable_total_size}B"
	echo "By type: directories - ${readable_dir_size}B (${dir_size_percent}%) ; files - ${readable_file_size}B (${file_size_percent}%)"
	echo "Average file size: - ${readable_average_file_size}B"
	echo "-------------------------------------------------------------------"
	echo "Oldest deleted item: ${oldest_name} (${oldest_date})"
	echo "Newest deleted item: ${newest_name} (${newest_date})"
	echo "-------------------------------------------------------------------"

	return 0
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
		echo "No header was found in the metadata file!"
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

	return 0"${@:2}"
}

####################
# FUNCTION: auto_cleanup
# DESCRIPTION: Automatically deletes files older than RETENTION_DAYS
# PARAMETERS: none
# RETURNS: 0 on success
###################

auto_cleanup() {
	timestamp_now=$(date +%s) # fetches current time
	time_threshold=$((RETENTION_DAYS * 24 * 60 * 60)) # converts $RETENTION_DAYS to seconds

	 if [[ ! -s "$METADATA_FILE" ]]; then
        echo "Recycle bin is empty."
		echo "No header was found in the metadata file!"
        return 0
    fi

	item_num=0
	deleted_items_num=0
	total_deleted_size=0
	while IFS=, read -r id name path date size type perm creator; do
		if [[ $item_num -gt 0 ]]; then
			file_date_timestamp=$(date -d "$date" +%s 2>/dev/null) # converts file date to a timestamp
			if (( timestamp_now - file_date_timestamp > time_threshold )); then # if the file date is older than $RETENTION_DAYS
				total_deleted_size=$((total_deleted_size + size))
				deleted_items_num=$((deleted_items_num + 1))
            	perm_delete "$force_flag" "$name" # force perma-deletes the file
        	fi
		fi
		item_num=$((item_num + 1))

	done < "$METADATA_FILE"

	item_num=$((item_num - 1))
	if [[ $item_num -eq 0 ]]; then
		echo "Recycle bin is empty."
		return 0
	fi

	readable_deleted_size=$(numfmt --to=iec "$total_deleted_size")
	# displaying the auto-cleanup's info summary
	echo "-------------------------------------------------------------------"
	echo "Auto-cleanup completed."
	echo "${deleted_items_num} files have been deleted."
	echo "${readable_deleted_size}B of size has been freed up."
	echo "-------------------------------------------------------------------"

	return 0;
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
		"empty"|"-e")
			empty_recyclebin "${@:2}"
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
		"showstats"|"-S")
			# show statistics option
			show_statistics
			;;
		*)
			# As no options are give it will be assumed that the option IS the list option
			# Passes ALL arguments given to the script to the list
			list_recycled "$@"
			;;
	esac
}
main "$@"