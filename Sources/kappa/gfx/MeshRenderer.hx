package kappa.gfx;

import kappa.core.IComponent;
import kappa.gfx.Mesh;
import kappa.gfx.Material;

@:require(kappa.Transform)
class MeshRenderer implements IComponent
{
    @:initArg public var mesh:Mesh = null;
    @:initArg public var material:Material = null;
}