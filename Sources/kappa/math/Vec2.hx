package kappa.math;

import kha.math.FastVector2;
import kha.FastFloat;

#if !macro
@:build(kappa.macro.VectorSwizzle.build(2))
#end
@:forward(x, y, normalized, dot, setFrom)
abstract Vec2(FastVector2) from FastVector2 to FastVector2
{
    inline public function new(x:FastFloat = 0, y:FastFloat = 0)
    {
        this = new FastVector2(x, y);
    }

    @:op(A * B)
    inline public function mulvec(rhs:Vec2):Vec2
    {
        return new Vec2(this.x * rhs.x, this.y * rhs.y);
    }

    @:op(A * B) @:commutative
    inline public static function mul(lhs:Vec2, rhs:FastFloat):Vec2
    {
        return (lhs : FastVector2).mult(rhs);
    }
    
    @:op(A / B)
    inline public function divvec(rhs:Vec2):Vec2
    {
        return new Vec2(this.x / rhs.x, this.y / rhs.y);
    }

    @:op(A / B)
    inline public function div(rhs:FastFloat):Vec2
    {
        return this.mult(1 / rhs);
    }

    @:op(A + B)
    inline public function add(rhs:Vec2):Vec2
    {
        return this.add(rhs);
    }

    @:op(A - B)
    inline public function sub(rhs:Vec2):Vec2
    {
        return this.sub(rhs);
    }

    @:op(-A)
    inline public function neg():Vec2
    {
        return this.mult(-1);
    }

    inline public function dist(rhs:Vec2):FastFloat
    {
        return this.sub(rhs).length;
    }

    inline public function distSqr(rhs:Vec2):FastFloat
    {
        return sub(rhs).lengthSqr;
    }

    public var length(get, never):FastFloat;
    inline function get_length():FastFloat { return this.length; }

    public var lengthSqr(get, never):FastFloat;
    inline function get_lengthSqr():FastFloat { return this.x * this.x + this.y * this.y; }

    @:op(A == B)
    inline public function equals(rhs:Vec2):Bool
    {
        return this.x == rhs.x && this.y == rhs.y;
    }

    public function toString():String
    {
        return '(${this.x}, ${this.y})';
    }

}