#!/bin/bash

# HOURS SPENT: 1
# Please do update the counter :)

# GLOBAL VARIABLES
RECYCLE_BIN_DIR="$HOME/.recycle_bin"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"

initialize_recyclebin(){
	#SHOULD PROBABLY CHECK IF EXISTS PATH WITH THAT NAME
	#To create the recycle bin directories
	mkdir "$RECYCLE_BIN_DIR"
	mkdir "$RECYCLE_BIN_DIR/files"
	touch "$METADATA_FILE"
	touch "$RECYCLE_BIN_DIR/config"	
}

initialize_recyclebin
