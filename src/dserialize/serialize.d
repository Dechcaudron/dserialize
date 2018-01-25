///
module dserialize.serialize;

import dserialize.serialization_format;
import dserialize.serialization_bundle;

public auto serialize(SerializationFmtT, T)(T instance)
if (isSerializationFormat!SerializationFmtT &&
    isSerializable!(T, SerializationFmtT))
{
    return new SerializationFmtT(instance.serialize!SerializationFmtT());
}

public bool isSerializable(T, SerializationFmtT)()
if (isSerializationFormat!SerializationFmtT)
{
    return is(
        typeof(
            {
                const T instance;
                string data = instance.serialize!SerializationFmtT();
            }
        )
    );
}