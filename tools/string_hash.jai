StringHash :: struct
{
    value: u32;
    str: string;
}


hash :: (str: string) -> StringHash
{
    return .{ value = get_hash(str), str }
}