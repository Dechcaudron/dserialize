///
module dserialize.exceptions;

import std.exception;

public class SerializationException : Exception
{
    mixin basicExceptionCtors;
}

public class DeserializationException : Exception
{
    mixin basicExceptionCtors;
}