import lua.Table;

class TableTools {
	public static inline function get<K,V>(table:Table<K,V>, k:K):Null<V> {
		return table[cast k];
	}

	public static inline function set<K,V>(table:Table<K,V>, k:K, v:V) {
		table[cast k] = v;
	}
}

