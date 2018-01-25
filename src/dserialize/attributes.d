module dserialize.attributes;

public struct Serializable
{
    immutable string serializationID;
}

public struct Serialize
{
    immutable string serializationID;
}

public struct JustSerialize
{
    immutable string serializationID;
}

public struct JustDeserialize
{
    immutable string serializationID;
}