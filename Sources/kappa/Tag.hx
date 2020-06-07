package kappa;

import kappa.core.IComponent;

class Tag implements IComponent
{
    public var index:UInt = 0;

    public function init(?tag = "Default") {}
}