package kappa.gfx;

import haxe.io.UInt32Array;
import haxe.io.Float32Array;

@:structInit
class MeshData
{
	public var positions:Float32Array;
	public var normals:Float32Array = null;
	public var texCoords:Float32Array = null;
	public var tangents:Float32Array = null;
    public var indices:UInt32Array;
}