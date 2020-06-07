package kappa.macro;

class MacroTools
{
    public static function getClassName(ctype:haxe.macro.Type.ClassType):String
    {
        var packageModule = ctype.module;
        var lastDelim = packageModule.lastIndexOf(".");
        var module = lastDelim >= 0 ? packageModule.substr(lastDelim + 1) : packageModule;
        return module == ctype.name ? packageModule : packageModule + "." + ctype.name;
    }
}