import std.typecons : Flag;
alias PK = Flag!"isPrimaryKey";
alias PrimaryKey = PK.yes;

struct Table(T)
{
	static assert(is(T == struct), "Use a struct as your record type!");

private:
	size_t _length;

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
				foreach(a; __traits(getAttributes, __traits(getMember, T, m)))
				{
					if(a == PrimaryKey)
					{
						mapMembers ~= "\nT[typeof(T." ~ m ~ ")] map_" ~ m ~ ";";
						setterCheckCode ~= "if(t." ~ m ~ " in " ~ mapOf!m ~ ") uniqueKeyFail(\"" ~ m ~ "\", t); ";
						setterCommitCode ~= mapOf!m ~ "[t." ~ m ~ "] = t; ";
						hasCode    ~= "static if(key == \"" ~ m ~ "\") return cast(bool)(t in " ~ mapOf!m ~ "); ";
					}
				}
			}
			code ~= "private:\n" ~ mapMembers;
			code ~= "public: ";
			code ~= "\nvoid set(T t) { import std.conv : to; "
					~ "auto uniqueKeyFail(string field, T t) { throw new Exception(\"Unique key constraint for field \\\"\" ~ field ~ \"\\\" failed: \" ~ t.to!string); } "
					~ setterCheckCode ~ setterCommitCode ~ "_length += 1; }";
			code ~= "\nbool has(string key, T)(T t) { " ~ indexAssert ~ " " ~ hasCode ~ "}";
		}
		return code;
	}

public:
	size_t length() @property { return _length; }
	size_t empty() @property { return _length == 0; }

	T get(string key, U)(U u)
	{
		mixin(indexAssert);
		import std.conv : to;
		mixin("if(u !in " ~ mapOf!key ~ ") throw new Exception(\"Key \\\"\" ~ u.to!string ~ \"\\\" not found!\"); "
				~ "return " ~ mapOf!key ~ "[u];");
	}

	T get(string key, U)(U u, T defaultValue)
	{
		mixin(indexAssert);
		import core.exception : RangeError;
		import std.exception : ifThrown;
		mixin("return (" ~ mapOf!key ~ "[u]).ifThrown!RangeError(defaultValue);");
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