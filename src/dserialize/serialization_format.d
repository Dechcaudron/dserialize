///
module dserialize.serialization_format;

public bool isSerializationFormat(T)() pure
{
    return is(
        typeof(
            {

            }()
        )
    );
}