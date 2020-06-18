package kappa.gfx;

import kha.FastFloat;

enum LightType
{
    DirectionalLight;
    PointLight(range:FastFloat);
    SpotLight(range:FastFloat, innerAngle:FastFloat, outerAngle:FastFloat);
}