module dutils.logging;

class SimpleLogger
{ //TODO: Use @aliasThis template to make this a debug-only class. :)
private:
	import std.stdio;
	bool enabled;
	bool wroteIndentation = false;
	int _indentation = 0;

protected:

	void checkIndentation()
	{
		if(!wroteIndentation)
			for(auto i = 0; i < _indentation; i++)
				write("  ");
		wroteIndentation = true;
	}

public:
	this(bool enabled = true) { this.enabled = enabled; }
	auto ref indentation() @property { return _indentation; }
	const auto ref logging() @property { return enabled; }

	void logln(T...)(T t)
	{
		if(enabled)
		{
			checkIndentation;
			writeln(t);
			wroteIndentation = false;
		}
	}

	void log(T...)(T t)
	{
		if(enabled)
		{
			checkIndentation;
			write(t);
		}
	}

	mixin template LoggerMember()
	{
		SimpleLogger logger;
		alias logger this;
	}
}