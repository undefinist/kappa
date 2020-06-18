package kappa.gfx;

import kha.Image;
import haxe.Int32;
import kha.FastFloat;

enum UniformValue
{
    UniFloat(f:FastFloat);
    UniInt(i:Int32);
    UniVec2(x:FastFloat, y:FastFloat);
    UniVec3(x:FastFloat, y:FastFloat, z:FastFloat);
    UniVec4(x:FastFloat, y:FastFloat, z:FastFloat, w:FastFloat);
    UniTexture(img:String);
}