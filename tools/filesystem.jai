copy_file_if_newer :: (source_path: string, destination_path: string) -> (copied: bool)
{
    source_modtime, source_size, source_exists: = file_modtime_and_size(source_path);
    destination_modtime, destination_size, destination_exists: = file_modtime_and_size(destination_path);
    if !source_exists
        return false;

    if destination_exists && destination_modtime >= source_modtime
        return false;

    copy_file(source_path, destination_path);
    return true;
}

/*
example:
copy_file_set_if_newer("source/path", "target", "lib" .["dll, pdb"]);
will copy 
    source/path/lib.dll
    source/path/lib.pdb
to
    target/lib.dll
    target/lib.pdb
*/
copy_file_set_if_newer :: (source_directory: string, destination_directory: string, file_basename: string, extensions: []string) -> bool
{
    result: bool;
    for extension: extensions
    {
        filename: = ifx extension.count != 0 then tprint("%.%", file_basename, extension) else file_basename;
        source_path: = tprint("%/%", source_directory, filename);
        if !file_exists(source_path) { return false; }

        target_path: = tprint("%/%", destination_directory, filename);
        result |= copy_file_if_newer(source_path, target_path);
    }
    return result;
}

#scope_file

#import "File_Utilities";
