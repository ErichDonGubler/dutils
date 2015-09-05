module dutils.deque;

import std.conv : to;

struct Deque(T)
{
	// FIXME: Make pops throw when deque is totally empty!

	this(T[] ts)
	{
		this[] = ts;
	}

	T[] frontArray, backArray;
	size_t frontLength, backLength;

	void reshuffle()
	{
		import std.math : abs;
		//TODO: Re-center deque
		long diff = frontLength - backLength;
		if(abs(diff) > 1)
		{
			// The imbalanced arrays can be called the "big" array
			// and the "small" array.
			auto totalSize = frontArray.length + backArray.length
				, totalLength = frontLength + backLength
				, bigArraySize = totalSize/2 + totalSize%2
				, smallArraySize = totalSize/2
				, bigArrayLength = totalLength/2 + totalLength%2
				, smallArrayLength = totalLength/2
				, moveSize = abs(diff/2)
				;

			//import std.stdio;
			//writeln("diff: ", diff);
			//writeln("totalSize: ", totalSize);
			//writeln("totalLength: ", totalLength);
			//writeln("bigArraySize: ", bigArraySize);
			//writeln("smallArraySize: ", smallArraySize);
			//writeln("bigArrayLength: ", bigArrayLength);
			//writeln("smallArrayLength: ", smallArrayLength);
			//writeln("moveSize: ", moveSize);

			void moveStuff(ref T[] bigArray, ref T[] smallArray, ref size_t oldBigArrayLength, ref size_t oldSmallArrayLength)
			{
				auto slice = bigArray[0..moveSize]; 
				smallArray.length = smallArraySize;
				// Shuffle small array elements out
				if(smallArraySize < moveSize)
					for(size_t i = 0; i < moveSize; ++i)
						smallArray[$ - 1 - i] = smallArray[$ - 1 - i - moveSize];
				// Move to the small array
				// Remember that slice is already reversed relative to the other array
				foreach(i, t; slice)
					smallArray[moveSize - 1 - i] = t;
				// Remove from the big array
				for(size_t i = 0; i < (oldBigArrayLength - moveSize); ++i)
					bigArray[i] = bigArray[moveSize + i];
				bigArray.length = bigArraySize;
				oldBigArrayLength = bigArrayLength;
				oldSmallArrayLength = smallArrayLength;
			}

			if(diff > 0) // Imbalanced to front
				moveStuff(frontArray, backArray, frontLength, backLength);
			else // Imbalanced to back
			{
				diff *= -1; // Make this positive
				moveStuff(backArray, frontArray, backLength, frontLength);
			}
		}
	}

	void pushFront(T t)
	{
		abstractPush(t, frontArray, frontLength);
	}

	void pushBack(T t)
	{
		abstractPush(t, backArray, backLength);
	}

	void popFront()
	{
		if(frontLength == 0)
			reshuffle;
		if(length == 0)
			throwEmptyException;
		--frontLength;
	}

	void popBack()
	{
		if(backLength == 0)
			reshuffle;
		if(length == 0)
			throwEmptyException;
		--backLength;
	}

	T front()
	{
		if(length == 0)
			throwEmptyException;
		return (frontLength > 0) ? frontArray[$ - 1] : backArray[0];
	}

	T back()
	{
		if(length == 0)
			throwEmptyException;
		return (backLength > 0) ? backArray[$ - 1] : frontArray[0];
	}

	size_t length() const @property { return frontLength + backLength; }

	// int opIndexAssign(int v);  // overloads a[] = v
	// int opIndexAssign(int v, size_t[2] x);  // overloads a[i .. j] = v


	/// Index operator for total reassignment (a[] = [20, 30])
	void opIndexAssign(T[] t)
	{
		frontArray.length = 0;
		frontLength = 0;
		backLength = t.length;
		backArray.length = t.length;
		backArray[] = t.dup;
		reshuffle;
	}

	/// Index mutator for elements
	void opIndexAssign(T t, size_t i)
	{
		import std.stdio;
		bool touchingFront = i < frontLength;
		if(touchingFront)
			frontArray[(frontLength - 1) - i] = t;
		else
			backArray[i - frontLength] = t;
	}

	/// Index accessor for elements
	T opIndex(size_t i)
	{
		bool touchingFront = i < frontLength;
		if(touchingFront)
			return frontArray[(frontLength - 1) - i];
		else
			return backArray[i - frontLength];
	}

	/// Entire managed array
	T[] opIndex()
	{
		import std.range : retro;
		import std.array : array;
		return frontArray.retro.array ~ backArray.dup;
	}

	size_t opDollar(size_t pos)() { return length; }

	string toString()
	{
		import std.range : appender;
		auto app = appender!string();
		app.put("[");
		bool did_one = false;
		foreach(t; this)
		{
			if(did_one)
				app.put(", ");
			app.put(t.to!string);
			did_one = true;
		}
		app.put("]");
		return app.data;
	}

	void printDebugString()
	{
		import std.stdio;
		write("[");
		bool did_one = false;
		foreach_reverse(t; frontArray[0..frontLength])
		{
			if(did_one)
				write(", ");
			write(t);
			did_one = true;
        }
        write(" | ");
        did_one = false;
		foreach(t; backArray[0..backLength])
		{
			if(did_one)
				write(", ");
			write(t);
			did_one = true;
        }
        writeln("]");
	}


	// Variants with index
	int opApply(int delegate(ref T t) dg)
	{
		int result;
		foreach_reverse(t; frontArray[0..frontLength])
		{
			result = dg(t);
            if(result)
                goto ERROR;
        }
		foreach(t; backArray[0..backLength])
		{
			result = dg(t);
            if(result)
                goto ERROR;
        }
		ERROR: return result;
	}

	int opApplyReverse(int delegate(ref T t) dg)
	{
		int result;
		foreach_reverse(t; backArray[0..backLength])
		{
			result = dg(t);
            if(result)
                goto ERROR;
        }
		foreach(t; frontArray[0..frontLength])
		{
			result = dg(t);
            if(result)
                goto ERROR;
        }
		ERROR: return result;
	}

	auto iterator() @property
	{
		static struct DequeIterator
		{
			bool empty()
			{
				return index == target.length;
			}

			void popFront()
			{
				if(index < target.length)
					++index;
				else
					throw new Exception("out of bounds"); // FIXME: Make this a nice exception!
			}

			T front()
			{
				return target[index];
			}

			this(Deque target)
			{
				this.target = target;
			}

		private:
			size_t index = 0;
			Deque target;
		}	

		return DequeIterator(this);
	}

private:
	void throwEmptyException(string name = __FUNCTION__, int line = __LINE__)
	{
		import std.exception : Exception;
		throw new Exception("unable to perform operation " ~ name ~ " at line " ~ line.to!string ~ " because deque is empty"); // XXX: Need specific exception type
	}

	void abstractPush(ref T t, ref T[] ts, ref size_t numTs)
	{
		if(numTs == ts.length)
		{
			if(ts.length > 0)
				ts.length *= 2;
			else
				ts.length = 1;
		}
		ts[numTs++] = t;
	}

}

unittest
{
	import std.stdio;
	Deque!int stuff;
	foreach(t; [1, 3125, 355, 6278, 89])
		stuff.pushBack(t);
	stuff.printDebugString;
	stuff.reshuffle;
	stuff.printDebugString;
	foreach(t; [1,2,3,4,5])
		stuff.pushBack(t);

	// TODO: Fix reshuffle cases
	
	stuff.printDebugString;

	// Bracket mutators
	stuff[0] = 2;
	stuff[4] = 5;
	stuff[5] = 5;
	stuff[$ - 1] = 9001;

	stuff.printDebugString;

	// Bracket accessors

	foreach(s; stuff)
		write(s, ", ");
	writeln;
}
