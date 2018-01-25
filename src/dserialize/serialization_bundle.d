///
module dserialize.serialization_bundle;

import dserialize.exceptions;
import std.exception;
import std.format;
import std.meta;
import std.variant;

///
public class SerializationBundle
{
    public alias SupportedDataTypes = AliasSeq!(
        byte,
        ubyte,
        short,
        ushort,
        int,
        uint,
        long,
        ulong,
        float,
        double,
        char,
        wchar,
        dchar,
        bool,
        SerializationBundle
    );

    public immutable string typeSerializationID;

    private alias VariantT = Algebraic!SupportedDataTypes;

    private VariantT[string] bundleData;

    public this(string typeSerializationID)
    {
        this.typeSerializationID = typeSerializationID;
    }

    public void put(T)(string key, const T data)
    if (staticIndexOf!(T, SupportedDataTypes) != -1)
    in
    {
        assert(key !is null);
    }
    do
    {
        bundleData[key] = cast()data;
    }

    public T get(T)(string key) const
    in
    {
        assert(key !is null);
    }
    do
    {
        return bundleData[key].get!T;
    }
}