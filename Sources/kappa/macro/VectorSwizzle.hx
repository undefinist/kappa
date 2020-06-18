package kappa.macro;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr;

class VectorSwizzle
{
    public static macro function build(dims:Int):Array<Field>
    {
        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        for(i in 0...dims)
        {
            for(j in 0...dims)
            {
                for(k in 0...dims)
                {
                    for(l in 0...dims)
                    {
                        addSwizzle4(fields, pos, i, j, k, l);
                    }
                    addSwizzle3(fields, pos, i, j, k);
                }
                addSwizzle2(fields, pos, i, j);
            }
        }

        return fields;
    }
    
    private static function addSwizzle2(fields:Array<Field>, pos:Position, i:Int, j:Int)
    {
        var x = i == 3 ? "w" : String.fromCharCode("x".code + i);
        var y = j == 3 ? "w" : String.fromCharCode("x".code + j);
        fields.push({
            name: x + y,
            kind: FProp("get", "never", macro:Vec2),
            pos: pos,
            access: [APublic]
        });
        var getter:Function = { 
            expr: macro return new Vec2($p{["this", x]}, $p{["this", y]}), 
            ret: macro:Vec2, 
            args: [] 
        };
        fields.push({ 
            name: "get_" + x + y, 
            access: [Access.APrivate, Access.AInline],
            kind: FieldType.FFun(getter),
            pos: Context.currentPos()
        });
    }
    
    private static function addSwizzle3(fields:Array<Field>, pos:Position, i:Int, j:Int, k:Int)
    {
        var x = i == 3 ? "w" : String.fromCharCode("x".code + i);
        var y = j == 3 ? "w" : String.fromCharCode("x".code + j);
        var z = k == 3 ? "w" : String.fromCharCode("x".code + k);
        fields.push({
            name: x + y + z,
            kind: FProp("get", "never", macro:Vec3),
            pos: pos,
            access: [APublic]
        });
        var getter:Function = { 
            expr: macro return new Vec3($p{["this", x]}, $p{["this", y]}, $p{["this", z]}), 
            ret: macro:Vec3, 
            args: [] 
        };
        fields.push({ 
            name: "get_" + x + y + z, 
            access: [Access.APrivate, Access.AInline],
            kind: FieldType.FFun(getter),
            pos: Context.currentPos()
        });
    }
    
    private static function addSwizzle4(fields:Array<Field>, pos:Position, i:Int, j:Int, k:Int, l:Int)
    {
        var x = i == 3 ? "w" : String.fromCharCode("x".code + i);
        var y = j == 3 ? "w" : String.fromCharCode("x".code + j);
        var z = k == 3 ? "w" : String.fromCharCode("x".code + k);
        var w = l == 3 ? "w" : String.fromCharCode("x".code + l);
        fields.push({
            name: x + y + z + w,
            kind: FProp("get", "never", macro:Vec4),
            pos: pos,
            access: [APublic]
        });
        var getter:Function = { 
            expr: macro return new Vec4($p{["this", x]}, $p{["this", y]}, $p{["this", z]}, $p{["this", w]}), 
            ret: macro:Vec4, 
            args: [] 
        };
        fields.push({ 
            name: "get_" + x + y + z + w,
            access: [Access.APrivate, Access.AInline],
            kind: FieldType.FFun(getter),
            pos: Context.currentPos()
        });
    }
}

#end