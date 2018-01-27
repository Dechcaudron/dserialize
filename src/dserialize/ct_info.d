///
module dserialize.ct_info;

import dserialize.attributes;
import std.format;
import std.meta;
import std.traits;

public bool isSerializable(T)() pure
{
    return is(
        typeof(
            {
                const T data;
                SerializationBundle bundle;
                bundle.put(string.init, data);
            }()
        )
    ) ||
    is(
        typeof(
            {
                const T data;
                SerializationBundle bundle;
                bundle.put(string.init, data.serialize());
            }()
        )
    );
}

template serializationID(alias member)
if (hasUDA!(member, Serialize) ||
    hasUDA!(member, JustSerialize) ||
    hasUDA!(member, JustDeserialize))
{
    static if (hasUDA!(member, Serialize))
        alias UDAs = getUDAs!(member, Serialize);
    else static if (hasUDA!(member, JustSerialize))
        alias UDAs = getUDAs!(member, JustSerialize);
    else static if (hasUDA!(member, JustDeserialize))
        alias UDAs = getUDAs!(member, JustDeserialize);
    else
        static assert (false);

    enum usesAutomaticID = is(UDAs[0]); // UDA defined without arguments, used as type rather than a struct value
    static if (usesAutomaticID)
        enum string serializationID = __traits(identifier, member);
    else
        enum string serializationID = UDAs[0].serializationID;
}

template memberIsReadable(alias member)
{
    enum memberIsReadable = is(
        typeof(
            {
                auto data = member;
            }()
        )
    );
}

template memberIsWritable(alias member)
{
    enum memberIsWritable = is(
        typeof(
            {
                member = memberWriteType!(member).init;
            }()
        )
    );
}

template memberWriteType(alias member)
{
    static if (is(typeof(member)))
            alias memberWriteType = typeof(member);
        else static if (isCallable!member && 
                        Parameters!(member).length == 1)
            alias memberWriteType = Parameters!member[0];
        else
            static assert(false);
}