/// This module contains mixins to make user types serializable
module dserialize.mixins;

import unit_threaded;

mixin template serializationCode()
{
    static import dserialize.ct_info;
    static import std.traits;
    static import dserialize.serialization_bundle;

    private string ownTypeSerializationID() const
    {
        import dserialize.attributes : Serializable;
        import std.traits : getUDAs;

        alias serializableUDAs = getUDAs!(typeof(this), Serializable);
        static if (serializableUDAs.length == 1)
            return serializableUDAs[0].serializationID.isEmpty ?
                   typeof(this).stringof :
                   serializableUDAs[0].serializationID;
        else
            return typeof(this).stringof;
    }

    public dserialize.serialization_bundle.SerializationBundle serialize() const
    {
        import dserialize.attributes : Serialize, JustSerialize;
        import dserialize.serialization_bundle : SerializationBundle;
        import std.traits: getSymbolsByUDA;

        auto bundle = new SerializationBundle(ownTypeSerializationID);

        static if (is(typeof(this) == struct))
        {
            static foreach (alias member; getSymbolsByUDA!(typeof(this), Serialize))
                serializeMember!member(bundle);
            static foreach (alias member; getSymbolsByUDA!(typeof(this), JustSerialize))
                serializeMember!member(bundle);
        }
        else
            static assert (false, "Type not supported by dserialize");

        return bundle;
    }

    public this(dserialize.serialization_bundle.SerializationBundle bundle)
    {
        import dserialize.attributes : Serialize, JustDeserialize;
        import std.format : format;
        import std.meta : Alias;
        import std.traits : hasUDA;

        pragma(msg, typeof(__traits(allMembers, typeof(this))));

        static if (is(typeof(this) == struct))
            static foreach (string memberName; __traits(allMembers, typeof(this)))
            {
                {
                    pragma(msg, memberName);
                    alias member = Alias!(mixin(memberName));
                    pragma(msg, __traits(getAttributes, member));
                    static if (hasUDA!(member, Serialize) ||
                               hasUDA!(member, JustDeserialize))
                    {
                      //  pragma(msg, memberName);
                        static assert(
                            dserialize.ct_info.memberIsWritable!member,
                            format("Member `%s` marked to be serialized, but it cannot be written to", memberName)
                        );
                        member = bundle.get!(dserialize.ct_info.memberWriteType!member)
                            (dserialize.ct_info.serializationID!member);
                    }
                }
            }
        else
            static assert(false);
    }

    private void serializeMember(alias member)
        (dserialize.serialization_bundle.SerializationBundle bundle) const
    {
        import std.format : format;

        enum memberName = __traits(identifier, member);

        static assert(
            dserialize.ct_info.memberIsReadable!member,
            format("Member `%s` marked to be serialized, but it is not readable", memberName)
        );

        bundle.put(dserialize.ct_info.serializationID!member, member);
    }
}

// MODULE TESTS
@Name("`serializationCode` can be used inside structs")
unittest
{
    import dserialize.attributes : Serialize, JustSerialize, JustDeserialize;

    struct MyStruct
    {
        @Serialize
        bool bool_;

        @Serialize("number")
        int int_;

        char char_;

        @property @JustSerialize
        char charProperty() const
        {
            return char_;
        }

        @property @JustDeserialize
        void charProperty(char value)
        {
            char_ = value;
        }

        this(bool bool_, int int_, char char_)
        {
            this.bool_ = bool_;
            this.int_ = int_;
            this.char_ = char_;
        }

        mixin serializationCode sCode;
        alias __ctor = sCode.__ctor;
    }

    MyStruct original = MyStruct(true, 5, 'c');
    auto bundle = original.serialize();

    MyStruct deserialized = MyStruct(bundle);
    deserialized.shouldEqual(original);
}