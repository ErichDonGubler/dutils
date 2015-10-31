module dutils.stack;

import std.exception : enforce;

public struct Stack(T)// Unfortunately, D can't return tuples yet...
{
private:
	T[] ts;

public:
	this(T[] ts)
	{
		import std.range : retro, array;
		this.ts = ts.retro.array;
	}

	void push(T t)
	{
		ts ~= t;
	}

	import std.range.primitives : isInputRange;
	import std.traits : Unqual;
	void pushAll(R)(R range)
		if(isInputRange!(Unqual!R))
	{
		ts ~= range;
	}

	ref T peek(size_t depth = 0)
	{
		auto index = ts.length - depth;
		enforce(index > 0, "Attempted to peek beyond stack range");
		return ts[index - 1];
	}

	ref const(T) readOnlyPeek(size_t depth = 0) const
	{
		auto index = ts.length - depth;
		enforce(index > 0, "Attempted to peek beyond stack range");
		return ts[index - 1];
	}

	T pop()//XXX: Unsafe if something throws an exception while getting popped, but acceptable for now
	{
		enforce(ts.length > 0, "Attempted to pop empty stack");
		auto temp = peek;
		ts.length--;
		return temp;
	}

	size_t size() @property const { return ts.length; }

	bool empty() @property const { return ts.length == 0; }

	string toString(string delegate(T) f)// REMOVE?
	{
		string s = "[";
		s ~= f(pop);
		while(!empty)
			s ~= ", " ~ f(pop);
		return s ~ "]";
	}

	string toString()
	{
		import std.conv : to;
		return "s" ~ ts.to!string;
	}
}

unittest
{
	Stack!string yum;
	yum.push("world!");
	yum.push("Hello, ");
	while(!yum.empty)
		write(yum.pop);
	writeln;
}