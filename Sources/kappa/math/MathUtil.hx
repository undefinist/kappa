package kappa.math;

class MathUtil
{
    @:generic
    inline public static function max<T:Float>(a:T, b:T):T
    {
        return (a > b) ? a : b;
    }

    @:generic
    inline public static function min<T:Float>(a:T, b:T):T
    {
        return (a < b) ? a : b;
    }

    @:generic
    inline public static function clamp<T:Float>(value:T, min:T, max:T):T
    {
        return MathUtil.max(MathUtil.min(value, max), min);
    }
}