package kappa.math;

import kha.FastFloat;

// @:forwardStatics disabled until completion is fixed
abstract Color(kha.Color) from kha.Color to kha.Color
{
    inline private function new(c:kha.Color)
    {
        this = c;
    }

    @:to
    public function toVec4():kappa.math.Vec4
    {
        return new kappa.math.Vec4(r, g, b, a);
    }

    @:to
    public function toVec3():kappa.math.Vec3
    {
        return new kappa.math.Vec3(r, g, b);
    }

    @:from
    public static function fromVec4(vec:kappa.math.Vec4):Color
    {
        return kha.Color.fromFloats(vec.x, vec.y, vec.z, vec.w);
    }

    @:from
    public static function fromVec3(vec:kappa.math.Vec3):Color
    {
        return kha.Color.fromFloats(vec.x, vec.y, vec.z);
    }

    /**
	 * Creates a new Color object from a packed 32 bit ARGB value.
	 */
	public static inline function fromValue(value:Int):Color
    {
        return kha.Color.fromValue(value);
    }

	/**
	 * Creates a new Color object from components in the range 0 - 255.
	 */
	public static function fromBytes(r:Int, g:Int, b:Int, a:Int = 255):Color
    {
        return kha.Color.fromBytes(r, g, b, a);
    }

	/**
	 * Creates a new Color object from components in the range 0 - 1.
	 */
	public static function fromFloats(r:FastFloat, g:FastFloat, b:FastFloat, a:FastFloat = 1):Color
    {
        return kha.Color.fromFloats(r, g, b, a);
    }

	/**
	 * Creates a new Color object from an HTML style #AARRGGBB string.
	 */
    public static function fromString(value:String):Color
    {
        return kha.Color.fromString(value);
    }
    
    @:op(A * B) @:commutative
    inline public static function mul(lhs:Color, rhs:FastFloat):Color
    {
        return Color.fromBytes(
            Std.int(kappa.math.MathUtil.clamp(lhs.rb * rhs, 0, 255)),
            Std.int(kappa.math.MathUtil.clamp(lhs.gb * rhs, 0, 255)),
            Std.int(kappa.math.MathUtil.clamp(lhs.bb * rhs, 0, 255)),
            Std.int(kappa.math.MathUtil.clamp(lhs.ab * rhs, 0, 255)));
    }

	/**
	 * Float representing the green color component.
	 */
    public var r(get, set):FastFloat;
	/**
	 * Float representing the green color component.
	 */
	public var g(get, set):FastFloat;
	/**
	 * Float representing the blue color component.
	 */
	public var b(get, set):FastFloat;
	/**
	 * Float representing the alpha color component.
	 */
    public var a(get, set):FastFloat;
	/**
	 * Float representing the green color component.
	 */
    public var rb(get, set):Int;
	/**
	 * Float representing the green color component.
	 */
	public var gb(get, set):Int;
	/**
	 * Float representing the blue color component.
	 */
	public var bb(get, set):Int;
	/**
	 * Float representing the alpha color component.
	 */
    public var ab(get, set):Int;
    


    private inline function get_r():FastFloat { return this.R; }
    private inline function get_g():FastFloat { return this.G; }
    private inline function get_b():FastFloat { return this.B; }
    private inline function get_a():FastFloat { return this.A; }
    private inline function set_r(value:FastFloat):FastFloat { return this.R = value; }
    private inline function set_g(value:FastFloat):FastFloat { return this.G = value; }
    private inline function set_b(value:FastFloat):FastFloat { return this.B = value; }
    private inline function set_a(value:FastFloat):FastFloat { return this.A = value; }

    private inline function get_rb():Int { return this.Rb; }
    private inline function get_gb():Int { return this.Gb; }
    private inline function get_bb():Int { return this.Bb; }
    private inline function get_ab():Int { return this.Ab; }
    private inline function set_rb(value:Int):Int { return this.Rb = value; }
    private inline function set_gb(value:Int):Int { return this.Gb = value; }
    private inline function set_bb(value:Int):Int { return this.Bb = value; }
    private inline function set_ab(value:Int):Int { return this.Ab = value; }

}