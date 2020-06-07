package kappa.core;

typedef EntityIndex = UInt;

/**
 * An Entity is a 32-bit identifier formed with 2 parts: index & version
 * version is highest 12 bits, index is lowest 20 bits.
 * ie. 0xFFF FFFFF
 *   version index
 */
abstract Entity(UInt) from UInt to UInt
{
    /**
     * invalid entity which is index 0xFFFFF.
     * Note that invalid != null
     */
    public static inline final INVALID:Entity = INDEX_MASK;

    public static inline final INDEX_MASK:UInt = 0xFFFFF;
    public static inline final VERSION_MASK:UInt = 0xFFF;
    public static inline final INDEX_BITS:Int = 20;

    public var index(get, set):EntityIndex;
    inline function get_index():EntityIndex 
    {
        return this & INDEX_MASK;
    }
    inline function set_index(value:UInt):EntityIndex 
    {
        return this = (this & ~INDEX_MASK) | value;
    }

    public var version(get, set):UInt;
    inline function get_version():UInt 
    {
        return this >> INDEX_BITS;
    }
    inline function set_version(value:UInt):UInt 
    {
        return this = (this & INDEX_MASK) | (value << INDEX_BITS);
    }

    public var valid(get, never):Bool;
    inline function get_valid():Bool
    {
        return (this & INDEX_MASK) != INVALID;
    }

    public inline function new(id:UInt = INVALID)
    {
        this = id;
    }

    public static inline function make(index:EntityIndex, version:UInt):Entity
    {
        return new Entity(index | (version << INDEX_BITS));
    }
    
    public function toString():String
    {
        return 'e$index.$version';
    }
}