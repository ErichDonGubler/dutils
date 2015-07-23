enum
{
	PrimaryKey,
	IndexedForeignKey,
}

struct Table(T)
{
	static assert(is(T == struct), "Use a struct as your record type!");

private:
	size_t _length;
	T[] records;

	// The compile-time part of this struct
	enum tableCode = generateTable();
	//pragma(msg, "tableCode: ", tableCode);
	mixin(tableCode);
	static string mapOf(string s)() pure { return "map_" ~ s; }
	enum indexAssert = "static assert(__traits(hasMember, typeof(this), mapOf!key()), \"\\\'\" ~ key ~ \"\\\' is not an indexed field\");";
	static string generateTable()
	{
		string code;
		{
			import std.typetuple;
			import std.traits;
			string mapMembers, setterCheckCode, setterCommitCode, hasCode;
			foreach(m; __traits(allMembers, T))
			{
				auto traits = __traits(getAttributes, __traits(getMember, T, m));
				//template validateTraits(PK isPrimary, IFK isForeign, Traits...)
				//{
				//	static if(Traits.length)
				//	{
				//		static if(is(typeof(Traits[0] == PK)) && Traits[0] == PK.yes)
				//			enum newIsPrimary = PK.yes;
				//		else
				//			enum newIsPrimary = isPrimary;
				//		static if(is(typeof(Traits[0] == IFK)) && Traits[0] == IFK.yes)
				//			enum newIsForeign = IFK.yes;
				//		else
				//			enum newIsForeign = isForeign;
				//		static assert((newIsPrimary ^ newIsForeign) || (!newIsPrimary && !newIsForeign), "key \"" ~ m ~ "\" cannot be primary and secondary");
				//		enum validateTraits = validateTraits!(newIsPrimary, newIsForeign, Traits[1..$]);
				//	}
				//	else
				//		enum validateTraits = true;
				//}
				//static assert(validateTraits!(PK.no, IFK.no, traits));
				foreach(a; traits)
				{
					if(a == PrimaryKey)
					{
						mapMembers ~= "\nT[typeof(T." ~ m ~ ")] map_" ~ m ~ ";";
						setterCheckCode ~= "\nif(t." ~ m ~ " in " ~ mapOf!m ~ ") uniqueKeyFail(\"" ~ m ~ "\", t); ";
						setterCommitCode ~= '\n' ~ mapOf!m ~ "[t." ~ m ~ "] = t; ";
						hasCode ~= "\nstatic if(key == \"" ~ m ~ "\") return cast(bool)(t in " ~ mapOf!m ~ "); ";
					}
					if(a == IndexedForeignKey)
					{
						mapMembers ~= "\nT[][typeof(T." ~ m ~ ")] map_" ~ m ~ ";";
						setterCommitCode ~= '\n' ~ mapOf!m ~ "[t." ~ m ~ "] ~= t; ";
					}
				}

				
			}
			code ~= "private:\n" ~ mapMembers;
			code ~= "\npublic: ";
			code ~= "\nvoid set(T t) { import std.conv : to; "
					~ "auto uniqueKeyFail(string field, T t) { throw new Exception(\"Unique key constraint for field \\\"\" ~ field ~ \"\\\" failed: \" ~ t.to!string); } "
					~ setterCheckCode ~ setterCommitCode ~ "\nrecords ~= t;\n_length += 1; }";
			code ~= "\nbool has(string key, T)(T t) { " ~ indexAssert ~ " " ~ hasCode ~ "}";
		}
		return code;
	}

public:
	size_t length() @property { return _length; }
	size_t empty() @property { return _length == 0; }

	auto get(string key, U)(U u)
	{
		mixin(indexAssert);
		import std.conv : to;
		mixin("if(u !in " ~ mapOf!key ~ ") throw new Exception(\"Key \\\"\" ~ u.to!string ~ \"\\\" not found!\"); "
				~ "return " ~ mapOf!key ~ "[u];");
	}

	auto get(string key, U)(U u, lazy T defaultValue)
	{
		mixin(indexAssert);
		mixin("return (" ~ mapOf!key ~ ".get(u, defaultValue);");
	}

	auto by(string field)()
	{
		mixin("return " ~ mapOf!field ~ ".byKey();");
	}

	int opApply(int delegate(ref T) dg)
    {
        int result = 0;
        foreach(r; records)
        {
            result = dg(r);
            if (result)
                break;
        }
        return result;
    }
}

unittest
{
	import std.typecons : Nullable;
	struct Test
	{
		@PrimaryKey string name;
		size_t number;
		Nullable!size_t alternate_number;
	}
	alias TestTable = Table!Test;

	auto t = TestTable();
	auto d = Test("INVALID", 42, typeof(Test.alternate_number).init);
	t.set(Test("Blarg", 1231));

	try
	{
		t.set(Test("Blarg", 123133));
		assert(0, "No duplicate names allowed!");
	}
	catch{}

	// t.has!"MEH"(1231); // Should fail, because no member named "MEH"

	import std.stdio;
	writeln(t.has!"name"("blarg"));
	writeln(t.get!"name"("blarg", d));
	writeln(t.has!"name"("Blarg"));
	writeln(t.get!"name"("Blarg"));
}