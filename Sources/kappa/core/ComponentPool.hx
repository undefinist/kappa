package kappa.core;

import kappa.core.Entity;

@:allow(kappa.core.PoolIterator)
class ComponentPool
{
    private static inline final _INVALID_INDEX = Entity.INVALID;

    /**
     * holds indices to `_packed` and `_data`.
     */
    private var _sparse:Array<EntityIndex>;

    /**
     * holds indices to `_sparse`.
     */
    private var _packed:Array<EntityIndex>;

    /**
     * holds the actual components. data is recycled.
     */
    private var _data:Array<IComponent>;

    public var size(get, never):UInt;
    function get_size():UInt
    {
        return _packed.length;
    }

    public function new() 
    {
        _sparse = [];
        _packed = [];
        _data = [];
    }

    public function add<T:IComponent>(index:EntityIndex, component:T):T
    {
        var len = _packed.push(index);
        while(index >= _sparse.length)
            _sparse.push(_INVALID_INDEX);
        _sparse[index] = len - 1;
        if(_data.length == len) // `_data` cannot be shorter than `_packed`, as it is never trimmed.
            _data.push(null);
        return cast _data[len - 1] = component;
    }

    public function recycle(index:EntityIndex):IComponent
    {
        if(_data.length == _packed.length)
            return null;
        var len = _packed.push(index);
        while(index >= _sparse.length)
            _sparse.push(_INVALID_INDEX);
        _sparse[index] = len - 1;
        return cast _data[len - 1];
    }

    public function remove(index:EntityIndex):IComponent
    {
        var _packedindex = _sparse[index];
        _sparse[index] = _INVALID_INDEX;

        // fill gap using last elem
        var c = _data[_packedindex];
        _data[_packedindex] = _data[_data.length - 1];
        _data[_data.length - 1] = c;
        _packed[_packedindex] = _packed[_packed.length - 1];
        _packed.pop();

        // repoint elem that was shifted
        _sparse[_packed[_packedindex]] = _packedindex;

        return c;
    }

    public function has(index:EntityIndex):Bool
    {
        return index < _sparse.length && _sparse[index] != _INVALID_INDEX;
    }

    public function get(index:EntityIndex):IComponent
    {
        return _data[_sparse[index]];
    }

    public function iterator():PoolIterator
    {
        return new PoolIterator(this);
    }

    public function entities():Iterator<EntityIndex>
    {
        return _packed.iterator();
    }
}

typedef PoolElement = { 
    index:EntityIndex,
    component:IComponent 
};

class PoolIterator
{
    var _pool:ComponentPool;
    var _packedIndex:EntityIndex;

    public function new(pool:ComponentPool)
    {
        _pool = pool;
        _packedIndex = 0;
    }

    public function hasNext():Bool
    {
        return _packedIndex < _pool._packed.length;
    }

    public function next():PoolElement
    {
        var ret = { index: _pool._packed[_packedIndex], component: _pool._data[_packedIndex] };
        ++_packedIndex;
        return ret;
    }
}