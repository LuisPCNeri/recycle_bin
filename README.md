# Linux Recycle Bin System

## Author
Luís Correia NMEC 125264<br>
Guilherme Martins NMEC 125260

## Description
This Project consists of a Recycle Bin system for the linux operating system. It should be able to delete, restore, empty, list and search for any files inside it.

## Instalation
To install the Recycle Bin structure run the following command:
```./recycle_bin.sh -i```
It should be now installed in your user directory under the name ".recycle_bin" with all it's subdirectories.

## Usage
When using the ```./recycle_bin.sh``` script the default option will be list, in such case all contents of the recycle bin will be listed. The default structure for the usage of the recycle_bin.sh script is:<br>

```./recycle_bin.sh [OPTION] [FILES]..```<br>

In a lot of the usage options one of the available arguments is the FILE_ID corresponding to the file in the recycle bin. To find it either check the metadata.db file or look into the recycle bin as the name of the files inside it are their corresponding ids.


So to use the delete function:

    Usage:

    ./recycle_bin.sh -d [FILES]..
    ./recycle_bin.sh delete [FILES]..

    Examples:

    ./recycle_bin.sh -d FileToDelete.txt
    ./recycle_bin.sh -d FileToDelete1.txt FileToDelete2.txt
    ./recycle_bin.sh -d DirectoryToDelete

<br>
<b>IMPORTANT TO NOTE</b> when restoring a file the argument passed should be the file's original name or it's id in the recycle_bin
<br>

To restores a file to it's original location:

    ./recycle_bin.sh -r [FILES]..
    ./recycle_bin.sh restore [FILES]..

To empty the recycle bin or permanently delete one of it's files. Permanently deleting a file or directory will almost always ask the user for confirmation, unless of course they use the --force or -f options as well. <b>To delete a certain file or directory from the recycle bin the arguments passed must be either the file name or the id corresponding to the file in the recycle bin</b>.

    ./recycle_bin.sh -e
    ./recycle_bin.sh -e [OPTION]
    ./recycle_bin.sh -e [FILES]..
    ./recycle_bin.sh -e [OPTION] [FILES]..

    Examples:

    ./recycle_bin.sh -e FileNameToDel.txt
    ./recycle_bin.sh -e --force FileIdToDel
    ./recycle_bin.sh -e -f


## Features
Implemented Features:

    - File removal or moving to recycle bin
    - File restoral
    - Empty recycle bin or permanently remove one or multiple files or directories
    - List recycle bin contents and its detailed version
    - Statistics display
    - Search for specific files or extensions in the recycle bin
