Range :: struct($T: Type)
{
    min: T; @serialize
    max: T; @serialize
}

RangeFloat :: Range(float32);
RangeInt :: Range(s32);

