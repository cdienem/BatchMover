# https://stackoverflow.com/a/65527560
Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public static class NaturalSort
{
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    private static extern int StrCmpLogicalW(string psz1, string psz2);
    public static string[] Sort(string[] array)
    {
        System.Array.Sort(array, (psz1, psz2) => StrCmpLogicalW(psz1, psz2));
        return array;
    }
}
"@


function Get-Max-Batch-Number($location, $pre){
# Checks folders in current location and their ending numbers
# Returns the next number

    $batch_nums = New-Object Collections.Generic.List[Int]

    foreach ($d in Get-ChildItem -Path $location -Directory -Filter "$pre*"){
        $batch_nums.Add($d.Name.Replace($pre, ""))
    }

    $max = ($batch_nums | Measure-Object -Maximum).Maximum
    if($max -ne $null){
        return $max
    } 
}


function Next-Batch($dest, $batch, $pre){
    Write-Host "Switching batch $batch"
    $current = [int]($batch.Replace($pre,""))
    $new = $current+1
    Write-Host "Trying to twitch from $batch to $pre$new"
    While($true){
        # Create if not exist, otherwise count further up
        if(!(Test-Path -Path $dest\$pre$new)){
            Write-Host "Creating batch folder:"
            Write-Host "     "$dest\$pre$new
            New-Item -Path $dest\$pre$new -ItemType "directory" | Out-Null
            break
        } else {
            $new = $new+1
        }
    }
    return $pre+$new
}


function Get-File-Count($location, $ext){
    return ( Get-ChildItem $location -Filter *$ext | Measure-Object ).Count
}




Write-Host "#####################################"
Write-Host "      Batch Mover v2024-01-29"
Write-Host "#####################################"


# File extension
$ext = Read-Host -Prompt 'File extension'
if (($ext.StartsWith(".")) -eq $FALSE){
	$ext = ".$ext"
}

# Source location
$src = Read-Host -Prompt 'Path to image stacks'
if(!(Test-Path -Path $src )){
	Write-Host "$src does not exist."
    Read-Host -Prompt "Press Enter to exit."
	exit
}


# Destination location
$dest = Read-Host -Prompt 'Destination for image stacks'
if(!(Test-Path -Path $dest )){
	Write-Host "$dest does not exist."
    Read-Host -Prompt "Press Enter to exit."
	exit
}


$pre = Read-Host -Prompt 'Data batch folder prefix (e.g. "data"; a running number will be added)'
$batch_size = Read-Host -Prompt 'Maximum number of images per data batch'


$max_batch = $(Get-Max-Batch-Number $dest $pre)
if ($max_batch -eq $null){
    Write-Host "No batch subfolders found"
    Write-Host "Starting with"
    Write-Host "     "$dest\$pre"1"
    $batch = $pre+"1"
} else {
    Write-Host "Existing batch subfolders found"
    
    # Sort the file list in a natural way
    $batchfolders = $(Get-ChildItem -Path $dest -Directory -Filter "$pre*").Name
    $batchfolders = [NaturalSort]::Sort($batchfolders)
    
    foreach ($d in $batchfolders){
        $fnum = $(Get-File-Count $dest\$d $ext)
        Write-Host "     $d : ($fnum / $batch_size files)"
    }
    if($fnum -lt $batch_size){
        # Offer resume
        $resume_last = Read-Host -Prompt "Continue moving files to last batch ($d)? [y/n]"
        if("$resume_last" -in "y","Y"){
            $batch = $d
        } else {
            $batch = $pre+$($max_batch+1)
        }
    } else {
        $batch = $pre+$($max_batch+1)
    }
     
}

#Write-Host $batch
# Set up starting batch folder if it does not exist
if(!(Test-Path -Path $dest\$batch )){
    Write-Host "Creating batch folder:"
    Write-Host "     "$dest\$batch
    New-Item -Path "$dest\$batch" -ItemType "directory" | Out-Null
}


While($true){
    # Check how many files are in dest
    $dest_file_num = $(Get-File-Count $dest\$batch $ext)
    if($dest_file_num -ge $batch_size){
        # Needs to switch batch!
        $batch = $(Next-Batch $dest $batch $pre)
        $safe_todo = $batch_size
    } else{
        $safe_todo = $($batch_size - $dest_file_num)
    }
           
    
    foreach($image in $(Get-ChildItem -Path $src -File -Filter "*$ext")){
        $last_write = (Get-Item $src\$image).LastWriteTime
        $min_age = New-TimeSpan -minutes 1
        if(((get-Date) - $last_write) -gt $min_age){
            Write-Host "$image -> $batch" 
            robocopy $src $dest\$batch $image.Name /mov /ndl /njh /njs /ns /nc
        }    
        $safe_todo = $($safe_todo-1)
        if($safe_todo -eq 0){
            break
        }
    }

}




