package kappa.math;

import kha.FastFloat;
import kha.math.FastMatrix4;

@:forwardStatics
@:forward(inverse, transpose, cofactor, determinant, trace, _00, _10, _20, _30, _01, _11, _21, _31, _02, _12, _22, _32, _03, _13, _23, _33)
abstract Mat4(FastMatrix4) from FastMatrix4 to FastMatrix4
{
    public inline function new(
        _00:FastFloat, _10:FastFloat, _20:FastFloat, _30:FastFloat,
        _01:FastFloat, _11:FastFloat, _21:FastFloat, _31:FastFloat,
        _02:FastFloat, _12:FastFloat, _22:FastFloat, _32:FastFloat,
        _03:FastFloat, _13:FastFloat, _23:FastFloat, _33:FastFloat) 
    {
        this = new FastMatrix4(
            _00, _10, _20, _30,
            _01, _11, _21, _31,
            _02, _12, _22, _32,
            _03, _13, _23, _33);
    }
    
    @:op(A * B)
    extern inline public function mulmat(rhs:Mat4):Mat4
    {
        return this.multmat(rhs);
    }

    @:op(A * B)
    extern inline public function mulvec(rhs:Vec4):Vec4
    {
        return this.multvec(rhs);
    }

    @:op(A * B) @:commutative
    extern inline public static function mul(lhs:Mat4, rhs:FastFloat):Mat4
    {
        return (lhs : FastMatrix4).mult(rhs);
    }

    @:op(A / B)
    extern inline public function div(rhs:FastFloat):Mat4
    {
        return this.mult(1 / rhs);
    }

    @:op(A + B)
    extern inline public function add(rhs:Mat4):Mat4
    {
        return this.add(rhs);
    }

    @:op(A - B)
    extern inline public function sub(rhs:Mat4):Mat4
    {
        return this.sub(rhs);
    }
}