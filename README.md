# BatchMover
Command line tool to move big EM data sets from A to B with creation of data subsets in B.

## Installation
1. BatchMover requires PowerShell 4.0+.
2. Just place the ''robo_batch_mover.ps1'' in your location of choice.
3. Create a shortcut to the following command: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noexit -executionpolicy bypass -File path\to\robo_batch_mover.ps1`


## Usage
1. Start BatchMover via shortcut
2. Provide source and destination paths
3. Define the base name of destination data batch subfolders (running numbers will be added)
4. Define the maximum number of files per batch
5. If data batch subfolders with the same basename are already present in the destination, you get an option to continue filling into the last batch subfolder
