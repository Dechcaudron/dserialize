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

public string getSerializationID(alias member)() pure
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

    pragma(msg, UDAs);

    enum usesAutomaticID = is(UDAs[0]); // UDA defined without arguments, used as type rather than a struct value
    static if (usesAutomaticID)
        return __traits(identifier, member);
    else
        return UDAs[0].serializationID;
}


/** 
    Enforces at CT the given symbol is readable, so as to ensure it
    can be serialized if marked as to be so 
**/
public void enforceMemberIsReadable(alias member)() pure
{
    static assert(is(typeof(
        {
            auto data = member;     
        }()
    )), 
        "Member %s marked to be serialized, but it is not readable.".format(member.stringof));
}