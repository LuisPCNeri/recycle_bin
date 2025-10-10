#!/bin/bash

#i HOURS SPENT: 4
# Please do update the counter :)
#TS WILL ACTUALLY MAKE ME KMS HOLYYY

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

################################
#FUNCTION: delete_file
#Description: Moves all files or directories given as an argument to .recycle_bin/files/ and writes important file data to the metadata.db file whilst logging it in the metadata.log
#PARAMETERS: $@ Should be any number of arguments but they MUST be a file or directory (Empty or non empty both work)
#RETURNS: 0 on success and -1 on failure
################################

delete_file(){
	#Func to move file from source to recycle bin writing its information to the metadata.db file

	for file in $@; do
		if ! [[ -f $file || -d $file ]]; then
			echo "All arguments given MUST be files or directories"
	 		echo "$file is NOT a file or directory"		
			exit -1
		fi

		#Checks if arguments is a directory and if it is NOT empty then removes adds to recycle bin
		if [[ -d $file ]];then
			#If it is a directory most create METADATA for all files inside
			for recursive_file in $file/*; do
				echo $recursive_file
				#Get all metadata from each file
				permissions=$(stat -c %a $recursive_file)
				file_creator=$(stat -c %U:%G $recursive_file)
				deletion_time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
				original_path=$(realpath $recursive_file)
				file_name="${recursive_file##*/}"
				file_size=$(stat -c %s $recursive_file)
				file_type=$(file $recursive_file)

				#Write to metadata.db file
				#Checks if METADATA_FILE is empty and if so gives the first file an ID of 1
				if [ -s $METADATA_FILE ]; then
					file_id=$(tail -1 $METADATA_FILE | cut -d "," -f1)
                                        echo "$((file_id+1)),$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> $METADATA_FILE
					echo "Created data: $((file_id+1)),$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator"
				else
					file_id="1"
                                        echo "$file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> $METADATA_FILE
                                        echo "Created data: $file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator"

				fi
			done
			
			#Moves the WHOLE dir to the trash
			#mv $file "$RECYCLE_BIN_DIR/files/"
		fi

		#Gets ALL file metadata
		permissions=$(stat -c %a $recursive_file)
                file_creator=$(stat -c %U:%G $file)
                deletion_time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                original_path=$(realpath $file)
                file_name="${file##*/}"
                file_size=$(stat -c %s $file)
                file_type=$(file $file)

		#Checks if METADATA_FILE is empty and if so gives the first file an ID of 1
                if [ -s $METADATA_FILE ]; then
               		 file_id=$(tail -1 $METADATA_FILE | cut -d "," -f1)
                         echo "$(($file_id+1)),$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> $METADATA_FILE
                         echo "Created data: $(($file_id+1)),$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator"
                else
                         file_id="1"
                         echo "$file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator" >> $METADATA_FILE
                         echo "Created data: $file_id,$file_name,$original_path,$deletion_time_stamp,$file_size,$file_type,$permissions,$file_creator"

                fi

		#Moves file to recycle bin
		mv $file "$RECYCLE_BIN_DIR/files/"
		echo "Moved $file from $ORIGINAL_PATH to $RECYCLE_BIN_DIR/files"
	done

	return 0
}
