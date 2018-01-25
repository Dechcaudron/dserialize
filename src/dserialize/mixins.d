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

    // There are CT limitations that prevent this method from being const
    public dserialize.serialization_bundle.SerializationBundle serialize()
    {
        import dserialize.attributes : Serialize, JustSerialize;
        import dserialize.serialization_bundle : SerializationBundle;
        import std.format : format;
        import std.meta : Alias;
        import std.traits: isBasicType, hasUDA;

        auto bundle = new SerializationBundle(ownTypeSerializationID);

        static if (is(typeof(this) == struct))
        {
            static foreach (string memberName; __traits(allMembers, typeof(this)))//getSymbolsByUDA!(Serialize, JustSerialize))
            {
                {
                    alias member = Alias!(mixin(memberName));
                    static if (hasUDA!(member, Serialize) ||
                            hasUDA!(member, JustSerialize))
                    {
                        dserialize.ct_info.enforceMemberIsReadable!memberName;
                        bundle.put(dserialize.ct_info.getSerializationID!member, member);
                    }
                }
            }
        }
        else
            static assert (false, "Type not supported by dserialize");

        return bundle;
    }

    private template WritableMemberValueT(alias member)
    {
        import std.traits : isCallable, Parameters;

        static if (is(typeof(member)))
            alias WritableMemberValueT = typeof(member);
        else static if (isCallable!member && 
                        Parameters!(member).length == 1)
            alias WritableMemberValueT = Parameters!member[0];
        else
            static assert(false);
    }

    public this(dserialize.serialization_bundle.SerializationBundle bundle)
    {
        import dserialize.attributes : Serialize, JustDeserialize;
        import std.format : format;
        import std.traits : getSymbolsByUDA;

        void enforceMemberIsWritable(alias member)()
        {
            static assert(
                is(typeof(
                    {
                        member = WritableMemberValueT!(member).init;
                    }()
                )),
                format!("Member %s marked to be deserialized, but it cannot be written to.",
                        member.stringof)
            );
        }

        static if (is(typeof(this) == struct))
            static foreach (alias member; getSymbolsByUDA!(Serialize, JustDeserialize))
            {
                enforceMemberIsWritable!member;
                member = bundle.get!WritableMemberValueT(dserialize.ct_info.getSerializationID!member);
                assert(false);
            }
        else
            static assert(false);
        
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
        char charProperty()
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