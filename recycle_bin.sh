#!/bin/bash

# HOURS SPENT: 3
# Please do update the counter :)

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
}

delete_file(){
	#Func to move file from source to recycle bin writing its information to the metadata.db file

	for file in $@; do
		if ! [[ -f $file || -d $file ]]; then
			echo "Argument must be a file or directory"	       
			exit -1
		fi

		#Checks if arguments is a directory and if it is NOT empty then removes adds to recycle bin
		if [[ -d $file ]];then
			#If it is a directory most create METADATA for all files inside
			for recursive_file in $file/*; do
				echo $recursive_file
				#Get all metadata from each file
				PERMISSIONS=$(stat -c %A $recursive_file)
				FILE_CREATOR=$(stat -c %U $recursive_file)
				CREATION_TIME_STAMP=$(stat -c %w $recursive_file)
				ORIGINAL_PATH=$(realpath $recursive_file)
				FILE_NAME="${recursive_file##*/}"

				#Write to metadata.db file
				#Checks if METADATA_FILE is empty and if so gives the first file an ID of 1
				if [ -s $METADATA_FILE ]; then
					FILE_ID=$(tail -1 $METADATA_FILE | cut -d ";" -f1)
                                        echo "$(($FILE_ID+1));$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS" >> $METADATA_FILE
					echo "Created data: $(($FILE_ID+1));$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS"
				else
					FILE_ID="1"
                                        echo "$FILE_ID;$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS" >> $METADATA_FILE
					echo "Created data: $(($FILE_ID+1));$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS"
				fi
			done
			
			#Moves the WHOLE dir to the trash
			#mv $file "$RECYCLE_BIN_DIR/files/"
		fi

		#Gets ALL file metadata
		PERMISSIONS=$(stat -c %A $file)
                FILE_CREATOR=$(stat -c %U $file)
                CREATION_TIME_STAMP=$(stat -c %w $file)

		#Has to get the actual real path from https://stackoverflow.com/questions/5265702/how-to-get-full-path-of-a-file @ 9/10/25 18h
		ORIGINAL_PATH=$(realpath $file)
                FILE_NAME="${file##*/}"

		#Checks if METADATA_FILE is empty and if so gives the first file an ID of 1
                if [ -s $METADATA_FILE ]; then
			FILE_ID=$(tail -1 $METADATA_FILE | cut -d ";" -f1)
                        echo "$(($FILE_ID+1));$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS" >> $METADATA_FILE
			echo "Created data: $(($FILE_ID+1));$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS"
                else
			FILE_ID="1"
                        echo "$FILE_ID;$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS" >> $METADATA_FILEecho $FILE_ID
			echo "Created data: $(($FILE_ID+1));$FILE_NAME;$ORIGINAL_PATH;$FILE_CREATOR;$CREATION_TIME_STAMP;$PERMISSIONS"
                fi

		#Moves file to recycle bin
		mv $file "$RECYCLE_BIN_DIR/files/"
		echo "Moved $file from $ORIGINAL_PATH to $RECYCLE_BIN_DIR/files"
	done

	return 0
}
