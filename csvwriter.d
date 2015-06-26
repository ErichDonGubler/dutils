import std.conv : to;
import std.stdio : File;
import std.range.primitives : ElementType, isOutputRange;
import std.traits : isSomeChar, isSomeString;

class SequentialCSVWriter(Range, Separator = char)
{
private:	
	auto wroteFirst = false;
	Separator columnSeparator;
	Separator rowSeparator;
	Separator escape;
	static if(is(Range : File))
	{
		import std.file;
		File outputFile;	
	}
	else static if(isSomeString!Range || isOutputRange!(Range, dchar))
	{
		import std.array : appender;
		auto app = appender!Range();	
	}
	else static assert(0, typeof(this).stringof ~ " must be a file or character output range!");

	auto writeRaw(T)(T t)
	{
		static assert(isSomeString!T || isSomeChar!T, "write(...) requires a string or char!");
		static if(is(Range : File))
			outputFile.write(t);
		else
			app ~= t;
	}

public:
	enum DEFAULT_ROW_SEPARATOR = '\n';
	enum DEFAULT_COL_SEPARATOR = ',';
	enum DEFAULT_ESCAPE = '\"';

	static if(is(Range : File))
	{
		this(string path, bool overwrite = true, Separator columnSeparator = DEFAULT_COL_SEPARATOR, Separator rowSeparator = DEFAULT_ROW_SEPARATOR, Separator escape = DEFAULT_ESCAPE)
		{
			outputFile.open(path, (overwrite ? "w+" : "w"));
			this(columnSeparator, rowSeparator, escape);
		}

		this(File file, bool overwrite = true, Separator columnSeparator = DEFAULT_COL_SEPARATOR, Separator rowSeparator = DEFAULT_ROW_SEPARATOR, Separator escape = DEFAULT_ESCAPE)
		{
			outputFile = file;
			this(columnSeparator, rowSeparator, escape);
		}

		private this(Separator columnSeparator, Separator rowSeparator, Separator escape)
		{
			this.columnSeparator = columnSeparator;
			this.rowSeparator = rowSeparator;
			this.escape = escape;
		}
	}
	else
	{
		this(Separator columnSeparator = DEFAULT_COL_SEPARATOR, Separator rowSeparator = DEFAULT_ROW_SEPARATOR, Separator escape = DEFAULT_ESCAPE)
		{
			this.columnSeparator = columnSeparator;
			this.rowSeparator = rowSeparator;
			this.escape = escape;
		}

		auto data()
		{
			return app.data();
		}
	}

	void write(T...)(T t)
	{
		if(wroteFirst)
			writeRaw(columnSeparator);
		wroteFirst = true;
		auto s = t.to!string;
		auto needsEscape = false;
		foreach(c; s)
			if(c == columnSeparator || c == rowSeparator || c == escape)
			{
				needsEscape = true;
				break;
			}

		if(needsEscape)
		{
			writeRaw(escape);
			writeRaw(s);
			writeRaw(escape);
		}
		else
			writeRaw(s);
	}

	void endRow()
	{
		writeRaw(rowSeparator);
		wroteFirst = false;
	}

	auto writeRow(T...)(T ts)
	{
		foreach(t; ts)
			write(t);
		endRow();
	}

	auto writeRow(T)(T[] ts)
	{
		foreach(t; ts)
			write(t);
		endRow();
	}
}

auto csvWriter(Range, Separator = char, T...)(T t)
{
	return new SequentialCSVWriter!(Range, Separator)(t);
}

unittest
{
	//TODO: Write a test case against std.csv.csvReader
	auto test(T)(T writer)
	{
		writer.write("2");
		writer.write("3");
		writer.write("4");
		writer.endRow();
		writer.writeRow("5", "6", "7", ",", "\"", "\n", "2", "3", "4");
		writer.write("5");
		writer.write("6");
		writer.write("7");
	}
	auto writer = new SequentialCSVWriter!(char[])();
	test(writer);
	import std.stdio : writeln;
	writeln(writer.data);

	import std.stdio : tmpfile;
	File f = File.tmpfile();
	test(new SequentialCSVWriter!File(f));
}

auto writeCSVfromMap(T)(T[string] records, bool writeHeaders = true)
{
	auto writer = new csvWriter!File();
	auto wroteHeader = !writeHeaders;
	foreach(r; records)
	{
		if(!wroteHeader)
		{
			foreach(k; r.keys)
				writer.write(k);
			wroteHeader = true;
			writer.endRow();
		}
		foreach(v; r.values)
			writer.write(v);
		writer.endRow();
	}

}