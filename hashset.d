module dutils.hashset;

struct HashSet(T)
{
private:
	bool[T] setData;

public:
	bool has(const ref T t) const
	{
		return (t in setData) !is null;//XXX: Huh?
	}

	void add(const ref T t)
	{
		setData[t] = true;
	}

	bool remove(const ref T t)
	{
		auto thisHas = this.has(t);
		if(thisHas)
			setData.remove(t);
		return thisHas;
	}

	void removeAll()
	{
		foreach(k; setData.byKey)
			setData.remove(k);
	}
}