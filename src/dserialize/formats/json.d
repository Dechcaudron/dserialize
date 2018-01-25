module dserialize.formats.json;

import dserialize.ct_info;
import dserialize.serialization_bundle;
import std.conv;
import std.traits;
import std.string;
import unit_threaded;

public class JsonSerializationBundle
{
    public static string serialize(T)(T data, string dataID) pure
    if (isIntegral!T)
    {
        return format("\"%s\":%s", dataID, to!string(data));
    }
    unittest
    {
        serialize(84, "data").shouldEqual("\"data\":84");
    }

    public static string serialize(T)(T data, string dataID) pure
    if (isFloatingPoint!T)
    {
        // TODO: implement
    }

    public static string serialize(T)(T data, string dataID) pure
    if (isSomeString!T)
    {
        return format("\"%s\":\"%s\"", dataID, to!string(data));
    }
    unittest
    {
        serialize("value", "key").shouldEqual("\"key\":\"value\"");
    }

    public static string serialize(T)(T data, string dataID) pure
    if (isSerializable!(T))
    {
        return format("\"%s\":%s", dataID, data.serialize!(typeof(this)).rawData);
    }
}