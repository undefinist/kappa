package kappa.math;

import kha.math.FastVector4;
import kha.FastFloat;

#if !macro
@:build(kappa.macro.VectorSwizzle.build(4))
#end
@:forward(x, y, z, w, dot, setFrom)
abstract Vec4(FastVector4) from FastVector4 to FastVector4
{
    inline public function new(x:FastFloat = 0, y:FastFloat = 0, z:FastFloat = 0, w:FastFloat = 0)
    {
        this = new FastVector4(x, y, z, w);
    }

    @:to
    inline public function toVec2():kappa.math.Vec2
    {
        return new kappa.math.Vec2(this.x, this.y);
    }

    @:to
    inline public function toVec3():kappa.math.Vec3
    {
        return new kappa.math.Vec3(this.x, this.y, this.z);
    }

    @:op(A * B)
    inline public function mulvec(rhs:Vec4):Vec4
    {
        return new Vec4(this.x * rhs.x, this.y * rhs.y, this.z * rhs.z, this.w * rhs.w);
    }

    @:op(A * B) @:commutative
    inline public static function mul(lhs:Vec4, rhs:FastFloat):Vec4
    {
        return (lhs : FastVector4).mult(rhs);
    }
    
    @:op(A / B)
    inline public function divvec(rhs:Vec4):Vec4
    {
        return new Vec4(this.x / rhs.x, this.y / rhs.y, this.z / rhs.z);
    }

    @:op(A / B)
    inline public function div(rhs:FastFloat):Vec4
    {
        return this.mult(1 / rhs);
    }

    @:op(A + B)
    inline public function add(rhs:Vec4):Vec4
    {
        return this.add(rhs);
    }

    @:op(A - B)
    inline public function sub(rhs:Vec4):Vec4
    {
        return this.sub(rhs);
    }

    @:op(-A)
    inline public function neg():Vec4
    {
        return this.mult(-1);
    }

    inline public function dist(rhs:Vec4):FastFloat
    {
        return this.sub(rhs).length;
    }

    inline public function distSqr(rhs:Vec4):FastFloat
    {
        return sub(rhs).lengthSqr;
    }

    public var length(get, never):FastFloat;
    inline function get_length():FastFloat { return this.length; }

    public var lengthSqr(get, never):FastFloat;
    inline function get_lengthSqr():FastFloat { return this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w; }

    public var normalized(get, never):Vec4;
    inline function get_normalized():Vec4 { return this.normalized(); }

    @:op(A == B)
    inline public function equals(rhs:Vec4):Bool
    {
        return this.x == rhs.x && this.y == rhs.y && this.z == rhs.z && this.w == rhs.w;
    }

    inline public function copy():Vec4
    {
        return new Vec4(this.x, this.y, this.z, this.w);
    }

    public function toString():String
    {
        return '(${this.x}, ${this.y}, ${this.z}, ${this.w})';
    }
}