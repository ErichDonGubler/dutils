module dutils.hashset;

struct HashSet(T, alias evalFun = null)
{
private:
	debug pragma(msg, typeof(evalFun));
	static if(is(typeof(evalFun) == typeof(null)))
	{
		import std.traits : isAggregateType;
		static if(isAggregateType!T && __traits(hasMember, T, "hashCode"))
		{
			debug pragma(msg, "Found hashCode");
			auto getHashCode(T t) const { return t.hashCode; }
			alias ourEvalFun = getHashCode;
		}
		else
		{
			debug pragma(msg, "Using identity");
			auto identity(const T t) const { return t; }
			alias ourEvalFun = identity;
		}
	}
	else
	{
		debug pragma(msg, "Using user-defined hashEval");
		alias ourEvalFun = evalFun;
	}
	debug pragma(msg, typeof(ourEvalFun));
	import std.traits : ReturnType;
	alias E = ReturnType!ourEvalFun;
	bool[E] setData;

	bool hasEvaluated(const E e) const
	{
		return (cast(T)e in setData) !is null;//XXX: Huh?
	}

public:

	bool has(const T t) const
	{
		return hasEvaluated(ourEvalFun(t));
	}

	void add(T t)
	{
		setData[ourEvalFun(t)] = true;
	}

	bool remove(T t)
	{
		auto e = ourEvalFun(t);
		auto thisHas = this.hasEvaluated(e);
		if(thisHas)
			setData.remove(e);
		return thisHas;
	}

	void removeAll()
	{
		foreach(k; setData.byKey)
			setData.remove(k);
	}

	string toString()
	{
		import std.conv : to;
		return setData.to!string;
	}

	auto values() const
	{
		return setData.keys;
	}
}