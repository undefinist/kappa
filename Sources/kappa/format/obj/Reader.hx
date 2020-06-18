package kappa.format.obj;

import kappa.gfx.MeshData;
import haxe.io.UInt32Array;
import haxe.io.Float32Array;
import kappa.math.Vec2;
import kappa.math.Vec3;
import kappa.format.Mikktspace;

@:structInit
class Vertex
{
    public var position:Vec3;
    public var normal:Vec3;
    public var texCoord:Vec2;
    public var tangent:Vec3;
    public function equals(rhs:Vertex):Bool
    {
        return
            position == rhs.position &&
            normal == rhs.normal &&
            texCoord == rhs.texCoord &&
            tangent == rhs.tangent;
    }
}

class Reader
{
    public static function read(blob:kha.Blob):MeshData
    {
        var positions:Array<Vec3> = [];
        var normals:Array<Vec3> = [];
        var texCoords:Array<Vec2> = [];
        var faceVerts:Array<Vertex> = [];

        var skipLine = false;
        var tokens = new Array<String>();
        var token = "";

        function parseFace(token:String):Vertex
        {
            var tokens = token.split("/");
            return { 
                position: positions[Std.parseInt(tokens[0]) - 1],
                texCoord: tokens[1].length == 0 ? new Vec2() : texCoords[Std.parseInt(tokens[1]) - 1],
                normal: normals[Std.parseInt(tokens[2]) - 1],
                tangent: {}
            };
        }

        for(i in 0...blob.length)
        {
            var c = blob.readU8(i);
            switch(c)
            {
                case "#".code: skipLine = true;
                case "\n".code:
                    if(!skipLine && token.length > 0) { tokens.push(token); token = ""; }
                    switch(tokens[0])
                    {
                        case "v": positions.push(new Vec3(Std.parseFloat(tokens[1]), Std.parseFloat(tokens[2]), Std.parseFloat(tokens[3])));
                        case "vn": normals.push(new Vec3(Std.parseFloat(tokens[1]), Std.parseFloat(tokens[2]), Std.parseFloat(tokens[3])));
                        case "vt": texCoords.push(new Vec2(Std.parseFloat(tokens[1]), Std.parseFloat(tokens[2])));
                        case "f": faceVerts.push(parseFace(tokens[1])); faceVerts.push(parseFace(tokens[2])); faceVerts.push(parseFace(tokens[3]));
                    }
                    tokens.resize(0);
                    skipLine = false;
                case " ".code: if(!skipLine && token.length > 0) { tokens.push(token); token = ""; }
                default: if(!skipLine) token += String.fromCharCode(c);
            }
        }

        Mikktspace.genTangSpaceDefault({
            m_pInterface: {
                m_getNumFaces: pContext -> {
                    var arr:Array<Vertex> = pContext.m_pUserData;
                    return cast arr.length / 3;
                },
                m_getNumVerticesOfFace: (pContext, iFace) -> return 3,
                m_getPosition: (pContext, fvPosOut, iFace, iVert) -> {
                    var arr:Array<Vertex> = pContext.m_pUserData;
                    var pos = arr[iFace * 3 + iVert].position;
                    fvPosOut.x = pos.x; fvPosOut.y = pos.y; fvPosOut.z = pos.z;
                },
                m_getNormal: (pContext, fvNormOut, iFace, iVert) -> {
                    var arr:Array<Vertex> = pContext.m_pUserData;
                    var norm = arr[iFace * 3 + iVert].normal;
                    fvNormOut.x = norm.x; fvNormOut.y = norm.y; fvNormOut.z = norm.z;
                },
                m_getTexCoord: (pContext, fvTexcOut, iFace, iVert) -> {
                    var arr:Array<Vertex> = pContext.m_pUserData;
                    var texc = arr[iFace * 3 + iVert].texCoord;
                    fvTexcOut.x = texc.x; fvTexcOut.y = texc.y;
                },
                m_setTSpaceBasic: (pContext, fvTangent, fSign, iFace, iVert) -> {
                    var arr:Array<Vertex> = pContext.m_pUserData;
                    var vert = arr[iFace * 3 + iVert];
                    vert.tangent.setFrom(fvTangent);
                },
                m_setTSpace: null
            },
            m_pUserData: faceVerts
        });

        return fold(faceVerts);
    }

    static function fold(faceVerts:Array<Vertex>):MeshData
    {
        var compressedVerts:Array<Vertex> = [];
        var indices:Array<UInt> = [];
        var index = 0;
        for(i in 0...faceVerts.length)
        {
            var v = faceVerts[i];
            var identical = -1; // index of identical vertex
            for(j in 0...compressedVerts.length) // find identical vertex
            {
                var v1 = compressedVerts[j];
                if(v.equals(v1))
                {
                    identical = j;
                    break;
                }
            }
            if(identical == -1)
            {
                compressedVerts.push(v);
                indices.push(index);
                ++index;
            }
            else 
                indices.push(identical);
        }

        var positions = new Float32Array(compressedVerts.length * 3);
        var normals = new Float32Array(compressedVerts.length * 3);
        var texCoords = new Float32Array(compressedVerts.length * 2);
        var tangents = new Float32Array(compressedVerts.length * 3);

        for(i in 0...compressedVerts.length)
        {
            var v = compressedVerts[i];
            positions[i * 3] = v.position.x; positions[i * 3 + 1] = v.position.y; positions[i * 3 + 2] = v.position.z;
            normals  [i * 3] = v.normal.x;   normals  [i * 3 + 1] = v.normal.y;   normals  [i * 3 + 2] = v.normal.z;
            tangents [i * 3] = v.tangent.x;  tangents [i * 3 + 1] = v.tangent.y;  tangents [i * 3 + 2] = v.tangent.z;
            texCoords[i * 2] = v.texCoord.x; texCoords[i * 2 + 1] = v.texCoord.y;
        }

        return { 
            positions: positions, 
            normals: normals, 
            texCoords: texCoords, 
            tangents: tangents,
            indices: UInt32Array.fromArray(indices) 
        };
    }
}