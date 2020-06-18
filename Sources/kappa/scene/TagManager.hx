package kappa.scene;

import kappa.core.Entity;
import kappa.core.System;
import kappa.scene.Tag;

class TagManager extends System
{
    public function new()
    {
    }

    public function findWithTag(_tag:String):Entity
    {
        return _world.view(Tag).find((entity, tag) -> return tag.tag == _tag);
    }
}