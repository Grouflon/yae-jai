StringHash :: struct
{
    hash: u32;
    str: string;
}

string_hash :: (str: string) -> StringHash
{
    hash: u32 = Hash.get_hash(str);

    str_ptr, added: = find_or_add(*string_hash_repository, hash);
    if added
    {
        <<str_ptr = copy_string(str);
    }
    else
    {
        assert(<<str_ptr == str, "Hash Collision: %(%) vs %(%)", str, hash, <<str_ptr, hash);
    }
    return .{hash, <<str_ptr};
}

free_string_hash_repository :: ()
{
    for str: string_hash_repository
    {
        free(str);
    }
    table_free(*string_hash_repository);
}

operator == :: (a: StringHash, b: StringHash) -> bool
{
    return a.hash == b.hash;
}

#scope_file

string_hash_repository : Table(u32, string);

get_hash :: (string_hash: StringHash) -> u32
{
    return string_hash.hash;
}

Hash :: #import "Hash";

#poke_name (#import "Hash_Table") operator ==;
#poke_name Hash get_hash;