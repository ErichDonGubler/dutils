module dutils.stack;

import std.exception : enforce;

public struct Stack(T)// Unfortunately, D can't return tuples yet...
{
private:
	T[] ts;

public:
	void push(T t)
	{
		ts ~= t;
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

	string toString(string delegate(T) f)
	{
		string s = "[";
		s ~= f(pop);
		while(!empty)
			s ~= ", " ~ f(pop);
		return s ~ "]";
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