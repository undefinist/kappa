package kappa.res;

class Resource
{
    static var idCounter:kappa.res.ResourceId = 1;
    public var id(default, null):kappa.res.ResourceId;

    public function new()
    {
        id = idCounter++;
    }
}