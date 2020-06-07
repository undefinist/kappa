package kappa.math;

import kha.FastFloat;

@:structInit
class Rect
{
    public var x0:FastFloat;
    public var y0:FastFloat;
    public var x1:FastFloat;
    public var y1:FastFloat;

    public function new(x0:FastFloat = 0, y0:FastFloat = 0, x1:FastFloat = 1, y1:FastFloat = 1)
    {
        this.x0 = x0;
        this.y0 = y0;
        this.x1 = x1;
        this.y1 = y1;
    }
    
    public var width(get, never):FastFloat;
    function get_width():FastFloat
    {
        return x1 - x0;
    }
    
    public var height(get, never):FastFloat;
    function get_height():FastFloat
    {
        return y1 - y0;
    }
}