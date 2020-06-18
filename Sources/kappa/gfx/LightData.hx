package kappa.gfx;

import kappa.math.Color;
import kappa.math.Vec3;
import kha.FastFloat;

@:structInit
class LightData
{
    public var type:Int = 0;
    public var position:Vec3 = {};
    public var direction:Vec3 = {};
    public var cosInner:FastFloat = 0;
    public var cosOuter:FastFloat = 1;
    public var falloff:FastFloat = 0;
    public var intensity:FastFloat = 1;
    public var color:Color = 0xffffffff;

    public static function create(light:Light, transform:Transform):LightData
    {
        return switch(light.type)
        {
            case PointLight(range):
            {
                type: 0,
                position: transform.position,
                direction: {},
                cosInner: 1,
                cosOuter: 1,
                falloff: range * range,
                intensity: light.intensity,
                color: light.color * light.intensity
            }
            case DirectionalLight:
            {
                type: 1,
                position: transform.position,
                direction: transform.forward,
                cosInner: 1,
                cosOuter: 0,
                falloff: 1,
                intensity: light.intensity,
                color: light.color * light.intensity
            }
            case SpotLight(range, innerAngle, outerAngle):
            {
                type: 2,
                position: transform.position,
                direction: transform.forward,
                cosInner: Math.cos(innerAngle),
                cosOuter: Math.cos(outerAngle),
                falloff: range * range,
                intensity: light.intensity,
                color: light.color * light.intensity
            }
        }
    }
}