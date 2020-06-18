package kappa.math;

import kha.math.FastVector3;
import kha.FastFloat;

#if !macro
@:build(kappa.macro.VectorSwizzle.build(3))
#end
@:forward(x, y, z, dot, cross, setFrom)
abstract Vec3(FastVector3) from FastVector3 to FastVector3
{
    inline public function new(x:FastFloat = 0, y:FastFloat = 0, z:FastFloat = 0)
    {
        this = new FastVector3(x, y, z);
    }

    @:to
    inline public function toVec2():Vec2
    {
        return new Vec2(this.x, this.y);
    }

    inline public function toVec4(w:FastFloat):Vec4
    {
        return new Vec4(this.x, this.y, this.z, w);
    }

    @:op(A * B)
    inline public function mulvec(rhs:Vec3):Vec3
    {
        return new Vec3(this.x * rhs.x, this.y * rhs.y, this.z * rhs.z);
    }

    @:op(A * B) @:commutative
    inline public static function mul(lhs:Vec3, rhs:FastFloat):Vec3
    {
        return (lhs : FastVector3).mult(rhs);
    }
    
    @:op(A / B)
    inline public function divvec(rhs:Vec3):Vec3
    {
        return new Vec3(this.x / rhs.x, this.y / rhs.y, this.z / rhs.z);
    }

    @:op(A / B)
    inline public function div(rhs:FastFloat):Vec3
    {
        return this.mult(1 / rhs);
    }

    @:op(A + B)
    inline public function add(rhs:Vec3):Vec3
    {
        return this.add(rhs);
    }

    @:op(A - B)
    inline public function sub(rhs:Vec3):Vec3
    {
        return this.sub(rhs);
    }

    @:op(-A)
    inline public function neg():Vec3
    {
        return this.mult(-1);
    }

    inline public function dist(rhs:Vec3):FastFloat
    {
        return this.sub(rhs).length;
    }

    inline public function distSqr(rhs:Vec3):FastFloat
    {
        return sub(rhs).lengthSqr;
    }

    public var length(get, never):FastFloat;
    inline function get_length():FastFloat { return this.length; }

    public var lengthSqr(get, never):FastFloat;
    inline function get_lengthSqr():FastFloat { return this.x * this.x + this.y * this.y + this.z * this.z; }

    public var normalized(get, never):Vec3;
    inline function get_normalized():Vec3 { return this.normalized(); }

    @:op(A == B)
    inline public function equals(rhs:Vec3):Bool
    {
        return this.x == rhs.x && this.y == rhs.y && this.z == rhs.z;
    }

    inline public function copy():Vec3
    {
        return new Vec3(this.x, this.y, this.z);
    }

    public function toString():String
    {
        return '(${this.x}, ${this.y}, ${this.z})';
    }
}