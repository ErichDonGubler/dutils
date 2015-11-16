module dutils.logging;

import std.stdio;

class IndentedLogger(string indentString)
{ //TODO: Use @aliasThis template to make this a debug-only class. :)
private:
	bool enabled;
	bool wroteIndentation = false;
	int _indentation = 0;
	File file;

protected:

	void checkIndentation()
	{
		if(!wroteIndentation)
			for(auto i = 0; i < _indentation; i++)
				file.write(indentString);
		wroteIndentation = true;
	}

public:
	this(File file = stdout, bool enabled = true)
	{
		this.file = file;
		this.enabled = enabled;
	}
	auto ref indentation() @property { return _indentation; }
	const auto ref logging() @property { return enabled; }

	void logln(T...)(T t)
	{
		if(enabled)
		{
			checkIndentation;
			file.writeln(t);
			wroteIndentation = false;
		}
	}

	void log(T...)(T t)
	{
		if(enabled)
		{
			checkIndentation;
			file.write(t);
		}
	}

	mixin template LoggerMember()
	{
		SimpleLogger logger;
		alias logger this;
	}
}

auto indentedLogger(string indentString = "  ")(bool enabled = true)
{
	return new IndentedLogger!indentString(enabled);
}

alias SimpleLogger = IndentedLogger!"  ";