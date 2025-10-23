# Linux Recycle Bin System

## Author
Luís Correia NMEC 125264<br>
Guilherme Martins NMEC ???

## Description
This Project consists of a Recycle Bin system for the linux operating system. It should be able to delete, restore, empty, list and search for any files inside it.

## Instalation
To install the Recycle Bin structure run the following command:
```./recycle_bin.sh -i```
It should be now installed in your user directory under the name ".recycle_bin" with all it's subdirectories.

## Usage
When using the ```./recycle_bin.sh``` script the default option will be list, in such case all contents of the recycle bin will be listed. The default structure for the usage of the recycle_bin.sh script is:<br>

```./recycle_bin.sh [OPTION] [FILES]..```

So to use the delete function:

    Usage:

    ./recycle_bin.sh [FILES]..
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


## Features
Implemented Features:

    - File removal or moving to recycle bin
    - File restoral
    - Empty recycle bin or permanently remove one or multiple files or directories
    - List recycle bin contents and its detailed version
    - Search for specific files or extensions in the recycle bin