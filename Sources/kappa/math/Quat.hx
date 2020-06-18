package kappa.math;

import kha.math.FastMatrix4;
import kha.FastFloat;
import kappa.math.Vec3;
import kappa.math.Mat4;

@:using(kappa.math.Quat)
@:structInit
class Quat
{
    public var x:FastFloat = 0;
    public var y:FastFloat = 0;
    public var z:FastFloat = 0;
    public var w:FastFloat = 1;

    inline public function new(x:FastFloat = 0, y:FastFloat = 0, z:FastFloat = 0, w:FastFloat = 1)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }
    
    inline public function copy():Quat
    {
        return new Quat(x, y, z, w);
    }
	
	// Axis has to be normalized
    inline public static function fromAxisAngle(axis:Vec3, radians:FastFloat):Quat
    {
		var q = new Quat();
		q.w = Math.cos(radians / 2.0);
		q.x = q.y = q.z = Math.sin(radians / 2.0);
		q.x *= axis.x;
		q.y *= axis.y;
		q.z *= axis.z;
		return q;
    }
    
    inline public static function lerp(q0:Quat, q1:Quat, t:FastFloat):Quat
    {
        return new Quat(
            q0.x * (1 - t) + q1.x * t,
            q0.y * (1 - t) + q1.y * t,
            q0.z * (1 - t) + q1.z * t,
            q0.w * (1 - t) + q1.w * t);
    }
	
    public static function slerp(q0:Quat, q1:Quat, t:FastFloat):Quat
    {
        final epsilon:FastFloat = 0.0005;

        var q1_ = q0.copy();
        var cosTheta = q0.dot(q1_);

		// Shortest path
		if (cosTheta < 0)
		{
			cosTheta  = -cosTheta;
			q1_.scale(-1);
		}

		// Divide by 0
		if (cosTheta > 1 - epsilon)
		{
			return q0.lerp(q1, t);
		}
		else
		{
			var ohm = Math.acos(cosTheta);
            var sOhm = Math.sin(ohm);
            
            var scl0 = Math.sin((1 - t) * ohm) / sOhm;
            var scl1 = Math.sin(t * ohm) / sOhm;

            return q0.scale(scl0).add(q1_.scale(scl1));
		}
	}
	
	// TODO: This should be multiplication
    public inline function rotated(b:Quat):Quat
    {
        return mul(b).normalize();
	}
	
    inline public function scaled(scale:FastFloat):Quat
    {
		return new Quat(x * scale, y * scale, z * scale, w * scale);
	}
	
    inline public function scale(scale:FastFloat):Quat
    {
		x = x * scale;
		y = y * scale;
		z = z * scale;
        w = w * scale;
        return this;
	}
	
    public inline function matrix():Mat4
    {
		final s:FastFloat = 2.0;
		
		var xs:FastFloat = x * s;
		var ys:FastFloat = y * s;
		var zs:FastFloat = z * s;
		var wx:FastFloat = w * xs;
		var wy:FastFloat = w * ys;
		var wz:FastFloat = w * zs;
		var xx:FastFloat = x * xs; 
		var xy:FastFloat = x * ys;
		var xz:FastFloat = x * zs;
		var yy:FastFloat = y * ys;
		var yz:FastFloat = y * zs;
		var zz:FastFloat = z * zs;

		return new Mat4(
			1 - (yy + zz), xy - wz, xz + wy, 0,
			xy + wz, 1 - (xx + zz), yz - wx, 0,
			xz - wy, yz + wx, 1 - (xx + yy), 0,
			0, 0, 0, 1
		);
	}
	
	// // For adding a (scaled) axis-angle representation of a quaternion
	// public inline function addVector(vec: Vector3): Quaternion {
	// 	var result: Quaternion = new Quaternion(x, y, z, w);
	// 	var q1: Quaternion = new Quaternion(0, vec.x, vec.y, vec.z);
	
	// 	q1 = q1.mult(result);

	// 	result.x += q1.x * 0.5;
	// 	result.y += q1.y * 0.5;
	// 	result.z += q1.z * 0.5;
	// 	result.w += q1.w * 0.5;
	// 	return result;
	// }
	
    public inline function add(q:Quat):Quat
    {
		return new Quat(x + q.x, y + q.y, z + q.z, w + q.w);
	}
	
    public inline function sub(q:Quat):Quat
    {
		return new Quat(x - q.x, y - q.y, z - q.z, w - q.w);
	}

    public inline function mul(r:Quat):Quat
    {
        return new Quat(
			w * r.x + x * r.w + y * r.z - z * r.y,
			w * r.y - x * r.z + y * r.w + z * r.x,
			w * r.z + x * r.y - y * r.x + z * r.w,
			w * r.w - x * r.x - y * r.y - z * r.z);
	}
	
    public inline function normalize():Quat
    {
		return scale(1.0 / Math.sqrt(x * x + y * y + z * z + w * w));
	}
	
    public inline function dot(q:Quat):FastFloat
    {
		return x * q.x + y * q.y + z * q.z + w * q.w;
	}

	// GetEulerAngles extracts Euler angles from the quaternion, in the specified order of
	// axis rotations and the specified coordinate system. Right-handed coordinate system
	// is the default, with CCW rotations while looking in the negative axis direction.
	// Here a,b,c, are the Yaw/Pitch/Roll angles to be returned.
	// rotation a around axis A1
	// is followed by rotation b around axis A2
	// is followed by rotation c around axis A3
	// rotations are CCW or CW (D) in LH or RH coordinate system (S)
	
	public static inline var AXIS_X: Int = 0;
	public static inline var AXIS_Y: Int = 1;
	public static inline var AXIS_Z: Int = 2;
	
    public function getEulerAngles(A1:Int, A2:Int, A3:Int, S:Int = 1, D:Int = 1):Vec3
    {
		var result:Vec3 = new Vec3();

		var Q:Array<FastFloat> = [x, y, z];

		var ww:FastFloat = w * w;

		var Q11:FastFloat = Q[A1]*Q[A1];
		var Q22:FastFloat = Q[A2]*Q[A2];
		var Q33:FastFloat = Q[A3]*Q[A3];

		var psign:FastFloat = -1;
		
		var SingularityRadius:FastFloat = 0.0000001;
		var PiOver2:FastFloat = Math.PI / 2.0;
		
		// Determine whether even permutation
		if (((A1 + 1) % 3 == A2) && ((A2 + 1) % 3 == A3)) {
			psign = 1;
		}

		var s2:FastFloat = psign * 2.0 * (psign*w*Q[A2] + Q[A1]*Q[A3]);

		if (s2 < -1 + SingularityRadius) { // South pole singularity
			result.x = 0;
			result.y = -S*D*PiOver2;
			result.z = S*D*Math.atan2(2*(psign*Q[A1]*Q[A2] + w*Q[A3]), ww + Q22 - Q11 - Q33 );
		}
		else if (s2 > 1 - SingularityRadius) { // North pole singularity
			result.x = 0;
			result.y = S*D*PiOver2;
			result.z = S*D*Math.atan2(2*(psign*Q[A1]*Q[A2] + w*Q[A3]), ww + Q22 - Q11 - Q33);
		}
		else {
			result.x = -S*D*Math.atan2(-2*(w*Q[A1] - psign*Q[A2]*Q[A3]), ww + Q33 - Q11 - Q22);
			result.y = S*D*Math.asin(s2);
			result.z = S*D*Math.atan2(2*(w*Q[A3] - psign*Q[A1]*Q[A2]), ww + Q11 - Q22 - Q33);
		}      
		
		return result;
	}
}
