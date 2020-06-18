/**
 * Haxe port of mikktspace originally written by Morten S. Mikkelsen.
 * Haxe port by Malody Hoe / undefinist. https://github.com/undefinist/mikktspacehx
 * 
 * MIT License
 * 
 * Copyright (c) 2020 Malody Hoe
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package kappa.format;

// #if cpp
// typedef FastFloat = cpp.Float32;
// #elseif hl
// typedef FastFloat = hl.F32;
// #elseif java
// typedef FastFloat = Single;
// #else
// typedef FastFloat = Float;
// #end
import kha.FastFloat;

@:structInit
class SMikkTSpaceInterface
{
    /**
     * Returns the number of faces (triangles/quads) on the mesh to be processed.
     */
    public var m_getNumFaces:(pContext:SMikkTSpaceContext)->Int;

    /**
     * Returns the number of vertices on face number iFace
     * iFace is a number in the range {0, 1, ..., getNumFaces()-1}
     */
    public var m_getNumVerticesOfFace:(pContext:SMikkTSpaceContext, iFace:Int)->Int;

    /**
     * returns the position of the referenced face of vertex number iVert.
     * iVert is in the range {0,1,2} for triangles and {0,1,2,3} for quads.
     */
    public var m_getPosition:(pContext:SMikkTSpaceContext, fvPosOut:SVec3, iFace:Int, iVert:Int)->Void;
    
    /**
     * returns the normal of the referenced face of vertex number iVert.
     * iVert is in the range {0,1,2} for triangles and {0,1,2,3} for quads.
     */
    public var m_getNormal:(pContext:SMikkTSpaceContext, fvNormOut:SVec3, iFace:Int, iVert:Int)->Void;
    
	/**
	 * returns the texcoord of the referenced face of vertex number iVert. (just fill x and y)
     * iVert is in the range {0,1,2} for triangles and {0,1,2,3} for quads.
	 */
    public var m_getTexCoord:(pContext:SMikkTSpaceContext, fvTexcOut:SVec3, iFace:Int, iVert:Int)->Void;

    /**
     * either (or both) of the two setTSpace callbacks can be set.
     * The callback `m_setTSpaceBasic()` is sufficient for basic normal mapping.
     * 
     * This function is used to return the tangent and fSign to the application.
     * `fvTangent` is a unit length vector.
     * For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
     * ```
     * bitangent = fSign * cross(vN, tangent);
     * ```
     * Note that the results are returned unindexed. It is possible to generate a new index list
     * But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
     * DO NOT! use an already existing index list.
     */
    public var m_setTSpaceBasic:(pContext:SMikkTSpaceContext, fvTangent:SVec3, fSign:FastFloat, iFace:Int, iVert:Int)->Void;

    /**
     * either (or both) of the two setTSpace callbacks can be set.
     * The callback `m_setTSpaceBasic()` is sufficient for basic normal mapping.
     * 
     * This function is used to return tangent space results to the application.
     * `fvTangent` and `fvBiTangent` are unit length vectors and `fMagS` and `fMagT` are their
     * true magnitudes which can be used for relief mapping effects.
     * `fvBiTangent` is the "real" bitangent and thus may not be perpendicular to `fvTangent`.
     * However, both are perpendicular to the vertex normal.
     * For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
     * ```
     * fSign = bIsOrientationPreserving ? 1.0 : -1.0;
     * bitangent = fSign * cross(vN, tangent);
     * ```
     * Note that the results are returned unindexed. It is possible to generate a new index list
     * But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
     * DO NOT! use an already existing index list.
     */
    public var m_setTSpace:(pContext:SMikkTSpaceContext, fvTangent:SVec3, fvBiTangent:SVec3, fMagS:FastFloat, fMagT:FastFloat,
                            bIsOrientationPreserving:Bool, iFace:Int, iVert:Int)->Void;
}

@:structInit
class SMikkTSpaceContext
{
    /**
     * initialized with callback functions
     */
    public var m_pInterface:SMikkTSpaceInterface;

    /**
     * pointer to client side mesh data etc. (passed as the first parameter with every interface call)
     */
    public var m_pUserData:Dynamic;
}

typedef SVec3 = kappa.math.Vec3;
// @:structInit
// class SVec3
// {
//     public var x:FastFloat = 0;
//     public var y:FastFloat = 0;
//     public var z:FastFloat = 0;
//     public function new(x:FastFloat = 0, y:FastFloat = 0, z:FastFloat = 0)
//     {
//         this.x = x;
//         this.y = y;
//         this.z = z;
//     }
//     public function copy() { return new SVec3(x, y, z); }
// }

private class SSubGroup
{
    public var iNrFaces:Int = 0;
    public var pTriMembers:Array<Int> = [];
    public function new() {}
}

private class SGroup
{
    public var iNrFaces:Int = 0;
    public var pFaceIndicesRaw:Array<Int> = null;
    public var pFaceIndicesOffset:Int = 0;
    public var iVertexRepresentitive:Int = 0;
    public var bOrientPreservering:Bool = false;
    public function new() {}
}

private class STriInfo
{
    public var FaceNeighbors:Array<Int> = [0,0,0];
    public var AssignedGroup:Array<SGroup> = [null,null,null];
    
    // normalized first order face derivatives
    public var vOs:SVec3 = new SVec3(); public var vOt:SVec3 = new SVec3();
    public var fMagS:FastFloat = 0; public var fMagT:FastFloat = 0; // original magnitudes

    // determines if the current and the next triangle are a quad.
    public var iOrgFaceNumber:Int = 0;
    public var iFlag:Int = 0; public var iTSpacesOffs:Int = 0;
    public var vert_num:Array<UInt> = [0,0,0,0];
    
    public function new() {}
}

private class STSpace
{
    public var vOs:SVec3 = new SVec3();
    public var fMagS:FastFloat = 0;
    public var vOt:SVec3 = new SVec3();
    public var fMagT:FastFloat = 0;
    public var iCounter:Int = 0;	// this is to average back into quads.
    public var bOrient:Bool = false;
    
    public function copyFrom(rhs:STSpace)
    {
        vOs = rhs.vOs.copy();
        fMagS = rhs.fMagS;
        vOt = rhs.vOt.copy();
        fMagT = rhs.fMagT;
        iCounter = rhs.iCounter;
        bOrient = rhs.bOrient;
    }
    
    public function new() {}
}

private class STmpVert
{
    public var vert:Array<FastFloat> = [0,0,0];
    public var index:Int = 0;
    
    public function new() {}
}

private abstract SEdge(Array<Int>) to Array<Int> from Array<Int>
{
    public var i0(get,set):Int;
    inline function get_i0():Int { return this[0]; }
    inline function set_i0(value:Int):Int { return this[0] = value; }

    public var i1(get,set):Int;
    inline function get_i1():Int { return this[1]; }
    inline function set_i1(value:Int):Int { return this[1] = value; }

    public var f(get,set):Int;
    inline function get_f():Int { return this[2]; }
    inline function set_f(value:Int):Int { return this[2] = value; }

    inline public function new()
    {
        this = [0, 0, 0];
    }
}

/**
 * Haxe port of mikktspace originally written by Morten S. Mikkelsen.
 * Haxe port by Malody Hoe / undefinist.
 */
class Mikktspace
{
    static inline var INTERNAL_RND_SORT_SEED = 39871946;

    static inline function veq(v1:SVec3, v2:SVec3):Bool { return v1.x == v2.x && v1.y == v2.y && v1.z == v2.z; }
    static inline function vadd(v1:SVec3, v2:SVec3):SVec3 { return new SVec3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z); }
    static inline function vsub(v1:SVec3, v2:SVec3):SVec3 { return new SVec3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z); }
    static inline function vscale(fS:FastFloat, v:SVec3):SVec3 { return new SVec3(v.x * fS, v.y * fS, v.z * fS); }
    static inline function vdot(v1:SVec3, v2:SVec3):FastFloat { return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z; }
    static inline function LengthSquared(v:SVec3):FastFloat { return vdot(v, v); }
    static inline function Length(v:SVec3):FastFloat { return Math.sqrt(LengthSquared(v)); }
    static inline function Normalize(v:SVec3):SVec3 { return vscale(1 / Length(v), v); }
    static inline function NotZero(fX:FastFloat):Bool
    {
        // could possibly use FLT_EPSILON instead
        return Math.abs(fX) > 0;
    }
    static function VNotZero(v:SVec3):Bool
    {
        // might change this to an epsilon based test
        return NotZero(v.x) || NotZero(v.y) || NotZero(v.z);
    }

    static inline var MARK_DEGENERATE    = 1;
    static inline var QUAD_ONE_DEGEN_TRI = 2;
    static inline var GROUP_WITH_ANY     = 4;
    static inline var ORIENT_PRESERVING  = 8;

    static macro function assert(b:haxe.macro.Expr.ExprOf<Bool>)
    {
        return macro if(!($b)) throw "Assert failure: " + $v{haxe.macro.ExprTools.toString(b)};
    }

    static function MakeIndex(iFace:Int, iVert:Int):Int
    {
        assert(iVert>=0 && iVert<4 && iFace>=0);
        return (iFace<<2) | (iVert&0x3);
    }
    
    static function IndexToData(iIndexIn:Int):{iFace:Int, iVert:Int}
    {
        return { iVert: iIndexIn&0x3, iFace: iIndexIn>>2 };
    }

    static function AvgTSpace(pTS0:STSpace, pTS1:STSpace):STSpace
    {
        var ts_res:STSpace = new STSpace();

        // this if is important. Due to floating point precision
        // averaging when ts0==ts1 will cause a slight difference
        // which results in tangent space splits later on
        if (pTS0.fMagS==pTS1.fMagS && pTS0.fMagT==pTS1.fMagT &&
            veq(pTS0.vOs,pTS1.vOs) && veq(pTS0.vOt, pTS1.vOt))
        {
            ts_res.fMagS = pTS0.fMagS;
            ts_res.fMagT = pTS0.fMagT;
            ts_res.vOs = pTS0.vOs;
            ts_res.vOt = pTS0.vOt;
        }
        else
        {
            ts_res.fMagS = 0.5*(pTS0.fMagS+pTS1.fMagS);
            ts_res.fMagT = 0.5*(pTS0.fMagT+pTS1.fMagT);
            ts_res.vOs = vadd(pTS0.vOs,pTS1.vOs);
            ts_res.vOt = vadd(pTS0.vOt,pTS1.vOt);
            if ( VNotZero(ts_res.vOs) ) ts_res.vOs = Normalize(ts_res.vOs);
            if ( VNotZero(ts_res.vOt) ) ts_res.vOt = Normalize(ts_res.vOt);
        }

        return ts_res;
    }

    public static function genTangSpaceDefault(pContext:SMikkTSpaceContext):Bool
    {
        return genTangSpace(pContext, 180.0);
    }

    public static function genTangSpace(pContext:SMikkTSpaceContext, fAngularThreshold:FastFloat):Bool
    {
        // count nr_triangles
        var piTriListIn:Array<Int> = null, piGroupTrianglesBuffer:Array<Int> = null;
        var pTriInfos:Array<STriInfo> = null;
        var pGroups:Array<SGroup> = null;
        var psTspace:Array<STSpace> = null;
        var iNrTrianglesIn = 0, f=0, t=0, i=0;
        var iNrTSPaces = 0, iTotTris = 0, iDegenTriangles = 0, iNrMaxGroups = 0;
        var iNrActiveGroups = 0, index = 0;
        var iNrFaces = pContext.m_pInterface.m_getNumFaces(pContext);
        var bRes = false;
        var fThresCos:FastFloat = Math.cos((fAngularThreshold*Math.PI)/180.0);

        // verify all call-backs have been set
        if (pContext.m_pInterface.m_getNumFaces==null ||
            pContext.m_pInterface.m_getNumVerticesOfFace==null ||
            pContext.m_pInterface.m_getPosition==null ||
            pContext.m_pInterface.m_getNormal==null ||
            pContext.m_pInterface.m_getTexCoord==null )
            return false;

        // count triangles on supported faces
        for (f in 0...iNrFaces)
        {
            var verts = pContext.m_pInterface.m_getNumVerticesOfFace(pContext, f);
            if (verts==3) ++iNrTrianglesIn;
            else if (verts==4) iNrTrianglesIn += 2;
        }
        if (iNrTrianglesIn<=0) return false;

        // allocate memory for an index list
        piTriListIn = [ for(i in 0...iNrTrianglesIn*3) 0 ];
        pTriInfos = [ for(i in 0...iNrTrianglesIn) new STriInfo() ];

        // make an initial triangle -. face index list
        iNrTSPaces = GenerateInitialVerticesIndexList(pTriInfos, piTriListIn, pContext, iNrTrianglesIn);

        // make a welded index list of identical positions and attributes (pos, norm, texc)
        //printf("gen welded index list begin\n");
        GenerateSharedVerticesIndexList(piTriListIn, pContext, iNrTrianglesIn);
        //printf("gen welded index list end\n");

        // Mark all degenerate triangles
        iTotTris = iNrTrianglesIn;
        iDegenTriangles = 0;
        for (t in 0...iTotTris)
        {
            final i0 = piTriListIn[t*3+0];
            final i1 = piTriListIn[t*3+1];
            final i2 = piTriListIn[t*3+2];
            final p0 = GetPosition(pContext, i0);
            final p1 = GetPosition(pContext, i1);
            final p2 = GetPosition(pContext, i2);
            if (veq(p0,p1) || veq(p0,p2) || veq(p1,p2))	// degenerate
            {
                pTriInfos[t].iFlag |= MARK_DEGENERATE;
                ++iDegenTriangles;
            }
        }
        iNrTrianglesIn = iTotTris - iDegenTriangles;

        // mark all triangle pairs that belong to a quad with only one
        // good triangle. These need special treatment in DegenEpilogue().
        // Additionally, move all good triangles to the start of
        // pTriInfos[] and piTriListIn[] without changing order and
        // put the degenerate triangles last.
        DegenPrologue(pTriInfos, piTriListIn, iNrTrianglesIn, iTotTris);

        
        // evaluate triangle level attributes and neighbor list
        //printf("gen neighbors list begin\n");
        InitTriInfo(pTriInfos, piTriListIn, pContext, iNrTrianglesIn);
        //printf("gen neighbors list end\n");

        
        // based on the 4 rules, identify groups based on connectivity
        iNrMaxGroups = iNrTrianglesIn*3;
        pGroups = [ for(i in 0...iNrMaxGroups) new SGroup() ];
        piGroupTrianglesBuffer = [ for(i in 0...iNrTrianglesIn*3) 0 ];
        
        //printf("gen 4rule groups begin\n");
        iNrActiveGroups =
            Build4RuleGroups(pTriInfos, pGroups, piGroupTrianglesBuffer, piTriListIn, iNrTrianglesIn);
        //printf("gen 4rule groups end\n");

        //

        psTspace = [ for(i in 0...iNrTSPaces) new STSpace() ];
        
        for (t in 0...iNrTSPaces)
        {
            psTspace[t].vOs.x=1.0; psTspace[t].vOs.y=0.0; psTspace[t].vOs.z=0.0; psTspace[t].fMagS=1.0;
            psTspace[t].vOt.x=0.0; psTspace[t].vOt.y=1.0; psTspace[t].vOt.z=0.0; psTspace[t].fMagT=1.0;
        }

        // make tspaces, each group is split up into subgroups if necessary
        // based on fAngularThreshold. Finally a tangent space is made for
        // every resulting subgroup
        //printf("gen tspaces begin\n");
        bRes = GenerateTSpaces(psTspace, pTriInfos, pGroups, iNrActiveGroups, piTriListIn, fThresCos, pContext);
        //printf("gen tspaces end\n");

        // degenerate quads with one good triangle will be fixed by copying a space from
        // the good triangle to the coinciding vertex.
        // all other degenerate triangles will just copy a space from any good triangle
        // with the same welded index in piTriListIn[].
        DegenEpilogue(psTspace, pTriInfos, piTriListIn, pContext, iNrTrianglesIn, iTotTris);

        var index:Int = 0;
        for (f in 0...iNrFaces)
        {
            var verts = pContext.m_pInterface.m_getNumVerticesOfFace(pContext, f);
            if (verts!=3 && verts!=4) continue;
            

            // I've decided to let degenerate triangles and group-with-anythings
            // vary between left/right hand coordinate systems at the vertices.
            // All healthy triangles on the other hand are built to always be either or.

            /*// force the coordinate system orientation to be uniform for every face.
            // (this is already the case for good triangles but not for
            // degenerate ones and those with bGroupWithAnything==true)
            bool bOrient = psTspace[index].bOrient;
            if (psTspace[index].iCounter == 0)	// tspace was not derived from a group
            {
                // look for a space created in GenerateTSpaces() by iCounter>0
                bool bNotFound = true;
                int i=1;
                while (i<verts && bNotFound)
                {
                    if (psTspace[index+i].iCounter > 0) bNotFound=false;
                    else ++i;
                }
                if (!bNotFound) bOrient = psTspace[index+i].bOrient;
            }*/

            // set data
            for (i in 0...verts)
            {
                var pTSpace = psTspace[index];
                if (pContext.m_pInterface.m_setTSpace!=null)
                    pContext.m_pInterface.m_setTSpace(pContext, pTSpace.vOs, pTSpace.vOt, pTSpace.fMagS, pTSpace.fMagT, pTSpace.bOrient, f, i);
                if (pContext.m_pInterface.m_setTSpaceBasic!=null)
                    pContext.m_pInterface.m_setTSpaceBasic(pContext, pTSpace.vOs, pTSpace.bOrient ? 1.0 : -1.0, f, i);

                ++index;
            }
        }

        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    static inline final g_iCells:Int = 2048;

    // it is IMPORTANT that this function is called to evaluate the hash since
    // inlining could potentially reorder instructions and generate different
    // results for the same effective input value fVal.
    static function FindGridCell(fMin:FastFloat, fMax:FastFloat, fVal:FastFloat):Int
    {
        final fIndex:FastFloat = g_iCells * ((fVal-fMin)/(fMax-fMin));
        final iIndex:Int = Std.int(fIndex);
        return iIndex < g_iCells ? (iIndex >= 0 ? iIndex : 0) : (g_iCells - 1);
    }

    static function GenerateSharedVerticesIndexList(piTriList_in_and_out:Array<Int>, pContext:SMikkTSpaceContext, iNrTrianglesIn:Int)
    {
        // Generate bounding box
        var piHashTable:Array<Int>=null, piHashCount:Array<Int>=null, piHashOffsets:Array<Int>=null, piHashCount2:Array<Int>=null;
        var pTmpVert:Array<STmpVert> = null;
        var i=0, iChannel=0, k=0, e=0;
        var iMaxCount=0;
        var vMin:SVec3 = GetPosition(pContext, 0), vMax = vMin.copy(), vDim:SVec3 = new SVec3();
        var fMin:FastFloat = 0, fMax:FastFloat = 0;
        for (i in 1...iNrTrianglesIn*3)
        {
            final index = piTriList_in_and_out[i];

            var vP = GetPosition(pContext, index);
            if (vMin.x > vP.x) vMin.x = vP.x;
            else if (vMax.x < vP.x) vMax.x = vP.x;
            if (vMin.y > vP.y) vMin.y = vP.y;
            else if (vMax.y < vP.y) vMax.y = vP.y;
            if (vMin.z > vP.z) vMin.z = vP.z;
            else if (vMax.z < vP.z) vMax.z = vP.z;
        }

        vDim = vsub(vMax,vMin);
        iChannel = 0;
        fMin = vMin.x; fMax=vMax.x;
        if (vDim.y>vDim.x && vDim.y>vDim.z)
        {
            iChannel=1;
            fMin = vMin.y; fMax=vMax.y;
        }
        else if (vDim.z>vDim.x)
        {
            iChannel=2;
            fMin = vMin.z; fMax=vMax.z;
        }

        // make allocations
        piHashTable = [ for(i in 0...iNrTrianglesIn*3) 0 ];
        piHashCount = [ for(i in 0...g_iCells) 0 ];
        piHashOffsets = [ for(i in 0...g_iCells) 0 ];
        piHashCount2 = [ for(i in 0...g_iCells) 0 ];

        // count amount of elements in each cell unit
        for (i in 0...iNrTrianglesIn*3)
        {
            final index = piTriList_in_and_out[i];
            final vP = GetPosition(pContext, index);
            final fVal = iChannel==0 ? vP.x : (iChannel==1 ? vP.y : vP.z);
            final iCell = FindGridCell(fMin, fMax, fVal);
            ++piHashCount[iCell];
        }

        // evaluate start index of each cell.
        piHashOffsets[0]=0;
        for (k in 1...g_iCells)
            piHashOffsets[k]=piHashOffsets[k-1]+piHashCount[k-1];

        // insert vertices
        for (i in 0...iNrTrianglesIn*3)
        {
            final index = piTriList_in_and_out[i];
            final vP = GetPosition(pContext, index);
            final fVal = iChannel==0 ? vP.x : (iChannel==1 ? vP.y : vP.z);
            final iCell = FindGridCell(fMin, fMax, fVal);

            assert(piHashCount2[iCell]<piHashCount[iCell]);
            piHashTable[piHashOffsets[iCell] + piHashCount2[iCell]] = i; // vertex i has been inserted.
            ++piHashCount2[iCell];
        }
        for (k in 0...g_iCells)
            assert(piHashCount2[k] == piHashCount[k]);	// verify the count

        // find maximum amount of entries in any hash entry
        iMaxCount = piHashCount[0];
        for (k in 1...g_iCells)
            if (iMaxCount<piHashCount[k])
                iMaxCount=piHashCount[k];
        pTmpVert = [ for(i in 0...iMaxCount) new STmpVert() ];

        // complete the merge
        for (k in 0...g_iCells)
        {
            // extract table of cell k and amount of entries in it
            var offset = piHashOffsets[k];
            final iEntries = piHashCount[k];
            if (iEntries < 2) continue;

            for (e in 0...iEntries)
            {
                var i = piHashTable[offset + e];
                var vP = GetPosition(pContext, piTriList_in_and_out[i]);
                pTmpVert[e].vert[0] = vP.x; pTmpVert[e].vert[1] = vP.y;
                pTmpVert[e].vert[2] = vP.z; pTmpVert[e].index = i;
            }
            MergeVertsFast(piTriList_in_and_out, pTmpVert, pContext, 0, iEntries-1);
        }
    }

    static function MergeVertsFast(piTriList_in_and_out:Array<Int>, pTmpVert:Array<STmpVert>, pContext:SMikkTSpaceContext, iL_in:Int, iR_in:Int)
    {
        // make bbox
        var c=0, l=0, channel=0;
        var fvMin:Array<FastFloat> = [0,0,0], fvMax:Array<FastFloat> = [0,0,0];
        var dx:FastFloat=0, dy:FastFloat=0, dz:FastFloat=0, fSep:FastFloat=0;
        for (c in 0...3)
        {	fvMin[c]=pTmpVert[iL_in].vert[c]; fvMax[c]=fvMin[c];	}
        for (l in iL_in+1...iR_in+1)
            for (c in 0...3)
                if (fvMin[c]>pTmpVert[l].vert[c]) fvMin[c]=pTmpVert[l].vert[c];
                else if (fvMax[c]<pTmpVert[l].vert[c]) fvMax[c]=pTmpVert[l].vert[c];
    
        dx = fvMax[0]-fvMin[0];
        dy = fvMax[1]-fvMin[1];
        dz = fvMax[2]-fvMin[2];
    
        channel = 0;
        if (dy>dx && dy>dz) channel=1;
        else if (dz>dx) channel=2;
    
        fSep = 0.5*(fvMax[channel]+fvMin[channel]);
    
        // terminate recursion when the separation/average value
        // is no longer strictly between fMin and fMax values.
        if (fSep>=fvMax[channel] || fSep<=fvMin[channel])
        {
            // complete the weld
            for (l in iL_in+1...iR_in + 1)
            {
                var i = pTmpVert[l].index;
                final index = piTriList_in_and_out[i];
                final vP = GetPosition(pContext, index);
                final vN = GetNormal(pContext, index);
                final vT = GetTexCoord(pContext, index);
    
                var bNotFound = true;
                var l2=iL_in, i2rec=-1;
                while (l2<l && bNotFound)
                {
                    final i2 = pTmpVert[l2].index;
                    final index2 = piTriList_in_and_out[i2];
                    final vP2 = GetPosition(pContext, index2);
                    final vN2 = GetNormal(pContext, index2);
                    final vT2 = GetTexCoord(pContext, index2);
                    i2rec=i2;
    
                    //if (vP==vP2 && vN==vN2 && vT==vT2)
                    if (vP.x==vP2.x && vP.y==vP2.y && vP.z==vP2.z &&
                        vN.x==vN2.x && vN.y==vN2.y && vN.z==vN2.z &&
                        vT.x==vT2.x && vT.y==vT2.y && vT.z==vT2.z)
                        bNotFound = false;
                    else
                        ++l2;
                }
                
                // merge if previously found
                if (!bNotFound)
                    piTriList_in_and_out[i] = piTriList_in_and_out[i2rec];
            }
        }
        else
        {
            var iL=iL_in, iR=iR_in;
            assert((iR_in-iL_in)>0);	// at least 2 entries
    
            // separate (by fSep) all points between iL_in and iR_in in pTmpVert[]
            while (iL < iR)
            {
                var bReadyLeftSwap = false, bReadyRightSwap = false;
                while ((!bReadyLeftSwap) && iL<iR)
                {
                    assert(iL>=iL_in && iL<=iR_in);
                    bReadyLeftSwap = !(pTmpVert[iL].vert[channel]<fSep);
                    if (!bReadyLeftSwap) ++iL;
                }
                while ((!bReadyRightSwap) && iL<iR)
                {
                    assert(iR>=iL_in && iR<=iR_in);
                    bReadyRightSwap = pTmpVert[iR].vert[channel]<fSep;
                    if (!bReadyRightSwap) --iR;
                }
                assert( (iL<iR) || !(bReadyLeftSwap && bReadyRightSwap) );
    
                if (bReadyLeftSwap && bReadyRightSwap)
                {
                    final sTmp = pTmpVert[iL];
                    assert(iL<iR);
                    pTmpVert[iL] = pTmpVert[iR];
                    pTmpVert[iR] = sTmp;
                    ++iL; --iR;
                }
            }
    
            assert(iL==(iR+1) || (iL==iR));
            if (iL==iR)
            {
                final bReadyRightSwap = pTmpVert[iR].vert[channel]<fSep;
                if (bReadyRightSwap) ++iL;
                else --iR;
            }
    
            // only need to weld when there is more than 1 instance of the (x,y,z)
            if (iL_in < iR)
                MergeVertsFast(piTriList_in_and_out, pTmpVert, pContext, iL_in, iR);	// weld all left of fSep
            if (iL < iR_in)
                MergeVertsFast(piTriList_in_and_out, pTmpVert, pContext, iL, iR_in);	// weld all right of (or equal to) fSep
        }
    }

    static function GenerateInitialVerticesIndexList(pTriInfos:Array<STriInfo>, piTriList_out:Array<Int>, pContext:SMikkTSpaceContext, iNrTrianglesIn:Int):Int
    {
        var iTSpacesOffs = 0, f=0, t=0;
        var iDstTriIndex = 0;
        for (f in 0...pContext.m_pInterface.m_getNumFaces(pContext))
        {
            final verts = pContext.m_pInterface.m_getNumVerticesOfFace(pContext, f);
            if (verts!=3 && verts!=4) continue;

            pTriInfos[iDstTriIndex].iOrgFaceNumber = f;
            pTriInfos[iDstTriIndex].iTSpacesOffs = iTSpacesOffs;

            if (verts==3)
            {
                var pVerts = pTriInfos[iDstTriIndex].vert_num;
                pVerts[0]=0; pVerts[1]=1; pVerts[2]=2;
                piTriList_out[iDstTriIndex*3+0] = MakeIndex(f, 0);
                piTriList_out[iDstTriIndex*3+1] = MakeIndex(f, 1);
                piTriList_out[iDstTriIndex*3+2] = MakeIndex(f, 2);
                ++iDstTriIndex;	// next
            }
            else
            {
                {
                    pTriInfos[iDstTriIndex+1].iOrgFaceNumber = f;
                    pTriInfos[iDstTriIndex+1].iTSpacesOffs = iTSpacesOffs;
                }

                {
                    // need an order independent way to evaluate
                    // tspace on quads. This is done by splitting
                    // along the shortest diagonal.
                    final i0 = MakeIndex(f, 0);
                    final i1 = MakeIndex(f, 1);
                    final i2 = MakeIndex(f, 2);
                    final i3 = MakeIndex(f, 3);
                    final T0 = GetTexCoord(pContext, i0);
                    final T1 = GetTexCoord(pContext, i1);
                    final T2 = GetTexCoord(pContext, i2);
                    final T3 = GetTexCoord(pContext, i3);
                    final distSQ_02 = LengthSquared(vsub(T2,T0));
                    final distSQ_13 = LengthSquared(vsub(T3,T1));
                    var bQuadDiagIs_02:Bool;
                    if (distSQ_02<distSQ_13)
                        bQuadDiagIs_02 = true;
                    else if (distSQ_13<distSQ_02)
                        bQuadDiagIs_02 = false;
                    else
                    {
                        final P0 = GetPosition(pContext, i0);
                        final P1 = GetPosition(pContext, i1);
                        final P2 = GetPosition(pContext, i2);
                        final P3 = GetPosition(pContext, i3);
                        final distSQ_02 = LengthSquared(vsub(P2,P0));
                        final distSQ_13 = LengthSquared(vsub(P3,P1));

                        bQuadDiagIs_02 = distSQ_13>=distSQ_02;
                    }

                    if (bQuadDiagIs_02)
                    {
                        {
                            var pVerts_A = pTriInfos[iDstTriIndex].vert_num;
                            pVerts_A[0]=0; pVerts_A[1]=1; pVerts_A[2]=2;
                        }
                        piTriList_out[iDstTriIndex*3+0] = i0;
                        piTriList_out[iDstTriIndex*3+1] = i1;
                        piTriList_out[iDstTriIndex*3+2] = i2;
                        ++iDstTriIndex;	// next
                        {
                            var pVerts_B = pTriInfos[iDstTriIndex].vert_num;
                            pVerts_B[0]=0; pVerts_B[1]=2; pVerts_B[2]=3;
                        }
                        piTriList_out[iDstTriIndex*3+0] = i0;
                        piTriList_out[iDstTriIndex*3+1] = i2;
                        piTriList_out[iDstTriIndex*3+2] = i3;
                        ++iDstTriIndex;	// next
                    }
                    else
                    {
                        {
                            var pVerts_A = pTriInfos[iDstTriIndex].vert_num;
                            pVerts_A[0]=0; pVerts_A[1]=1; pVerts_A[2]=3;
                        }
                        piTriList_out[iDstTriIndex*3+0] = i0;
                        piTriList_out[iDstTriIndex*3+1] = i1;
                        piTriList_out[iDstTriIndex*3+2] = i3;
                        ++iDstTriIndex;	// next
                        {
                            var pVerts_B = pTriInfos[iDstTriIndex].vert_num;
                            pVerts_B[0]=1; pVerts_B[1]=2; pVerts_B[2]=3;
                        }
                        piTriList_out[iDstTriIndex*3+0] = i1;
                        piTriList_out[iDstTriIndex*3+1] = i2;
                        piTriList_out[iDstTriIndex*3+2] = i3;
                        ++iDstTriIndex;	// next
                    }
                }
            }

            iTSpacesOffs += verts;
            assert(iDstTriIndex<=iNrTrianglesIn);
        }

        for (t in 0...iNrTrianglesIn)
            pTriInfos[t].iFlag = 0;

        // return total amount of tspaces
        return iTSpacesOffs;
    }

    static function GetPosition(pContext:SMikkTSpaceContext, index:Int):SVec3
    {
        var res:SVec3 = {};
        var data = IndexToData(index);
        var iF = data.iFace, iI = data.iVert;
        pContext.m_pInterface.m_getPosition(pContext, res, iF, iI);
        return res;
    }
    
    static function GetNormal(pContext:SMikkTSpaceContext, index:Int):SVec3
    {
        var res:SVec3 = {};
        var data = IndexToData(index);
        var iF = data.iFace, iI = data.iVert;
        pContext.m_pInterface.m_getNormal(pContext, res, iF, iI);
        return res;
    }
    
    static function GetTexCoord(pContext:SMikkTSpaceContext, index:Int):SVec3
    {
        var res:SVec3 = {};
        var data = IndexToData(index);
        var iF = data.iFace, iI = data.iVert;
        pContext.m_pInterface.m_getTexCoord(pContext, res, iF, iI);
        res.z = 1.0;
        return res;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // returns the texture area times 2
    static function CalcTexArea(pContext:SMikkTSpaceContext, indices:Array<Int>, offset:Int):FastFloat
    {
        final t1 = GetTexCoord(pContext, indices[offset + 0]);
        final t2 = GetTexCoord(pContext, indices[offset + 1]);
        final t3 = GetTexCoord(pContext, indices[offset + 2]);

        final t21x = t2.x-t1.x;
        final t21y = t2.y-t1.y;
        final t31x = t3.x-t1.x;
        final t31y = t3.y-t1.y;

        final fSignedAreaSTx2 = t21x*t31y - t21y*t31x;

        return fSignedAreaSTx2<0 ? (-fSignedAreaSTx2) : fSignedAreaSTx2;
    }

    static function InitTriInfo(pTriInfos:Array<STriInfo>, piTriListIn:Array<Int>, pContext:SMikkTSpaceContext, iNrTrianglesIn:Int)
    {
        var t = 0;
        // pTriInfos[f].iFlag is cleared in GenerateInitialVerticesIndexList() which is called before this function.

        // generate neighbor info list
        for (f in 0...iNrTrianglesIn)
        {
            for (i in 0...3)
            {
                pTriInfos[f].FaceNeighbors[i] = -1;
                pTriInfos[f].AssignedGroup[i] = null;

                pTriInfos[f].vOs.x=0.0; pTriInfos[f].vOs.y=0.0; pTriInfos[f].vOs.z=0.0;
                pTriInfos[f].vOt.x=0.0; pTriInfos[f].vOt.y=0.0; pTriInfos[f].vOt.z=0.0;
                pTriInfos[f].fMagS = 0;
                pTriInfos[f].fMagT = 0;

                // assumed bad
                pTriInfos[f].iFlag |= GROUP_WITH_ANY;
            }
        }

        // evaluate first order derivatives
        for (f in 0...iNrTrianglesIn)
        {
            // initial values
            final v1 = GetPosition(pContext, piTriListIn[f*3+0]);
            final v2 = GetPosition(pContext, piTriListIn[f*3+1]);
            final v3 = GetPosition(pContext, piTriListIn[f*3+2]);
            final t1 = GetTexCoord(pContext, piTriListIn[f*3+0]);
            final t2 = GetTexCoord(pContext, piTriListIn[f*3+1]);
            final t3 = GetTexCoord(pContext, piTriListIn[f*3+2]);

            final t21x = t2.x-t1.x;
            final t21y = t2.y-t1.y;
            final t31x = t3.x-t1.x;
            final t31y = t3.y-t1.y;
            final d1 = vsub(v2,v1);
            final d2 = vsub(v3,v1);

            final fSignedAreaSTx2 = t21x*t31y - t21y*t31x;
            //assert(fSignedAreaSTx2!=0);
            var vOs = vsub(vscale(t31y,d1), vscale(t21y,d2));	// eq 18
            var vOt = vadd(vscale(-t31x,d1), vscale(t21x,d2)); // eq 19

            pTriInfos[f].iFlag |= (fSignedAreaSTx2>0 ? ORIENT_PRESERVING : 0);

            if ( NotZero(fSignedAreaSTx2) )
            {
                final fAbsArea = Math.abs(fSignedAreaSTx2);
                final fLenOs = Length(vOs);
                final fLenOt = Length(vOt);
                final fS = (pTriInfos[f].iFlag&ORIENT_PRESERVING)==0 ? -1.0 : 1.0;
                if ( NotZero(fLenOs) ) pTriInfos[f].vOs = vscale(fS/fLenOs, vOs);
                if ( NotZero(fLenOt) ) pTriInfos[f].vOt = vscale(fS/fLenOt, vOt);

                // evaluate magnitudes prior to normalization of vOs and vOt
                pTriInfos[f].fMagS = fLenOs / fAbsArea;
                pTriInfos[f].fMagT = fLenOt / fAbsArea;

                // if this is a good triangle
                if ( NotZero(pTriInfos[f].fMagS) && NotZero(pTriInfos[f].fMagT))
                    pTriInfos[f].iFlag &= (~GROUP_WITH_ANY);
            }
        }

        // force otherwise healthy quads to a fixed orientation
        while (t<(iNrTrianglesIn-1))
        {
            final iFO_a = pTriInfos[t].iOrgFaceNumber;
            final iFO_b = pTriInfos[t+1].iOrgFaceNumber;
            if (iFO_a==iFO_b)	// this is a quad
            {
                final bIsDeg_a = (pTriInfos[t].iFlag&MARK_DEGENERATE)!=0;
                final bIsDeg_b = (pTriInfos[t+1].iFlag&MARK_DEGENERATE)!=0;
                
                // bad triangles should already have been removed by
                // DegenPrologue(), but just in case check bIsDeg_a and bIsDeg_a are false
                if ((bIsDeg_a||bIsDeg_b)==false)
                {
                    final bOrientA = (pTriInfos[t].iFlag&ORIENT_PRESERVING)!=0;
                    final bOrientB = (pTriInfos[t+1].iFlag&ORIENT_PRESERVING)!=0;
                    // if this happens the quad has extremely bad mapping!!
                    if (bOrientA!=bOrientB)
                    {
                        //printf("found quad with bad mapping\n");
                        var bChooseOrientFirstTri = false;
                        if ((pTriInfos[t+1].iFlag&GROUP_WITH_ANY)!=0) bChooseOrientFirstTri = true;
                        else if ( CalcTexArea(pContext, piTriListIn, t*3+0) >= CalcTexArea(pContext, piTriListIn, (t+1)*3+0) )
                            bChooseOrientFirstTri = true;

                        // force match
                        {
                            final t0 = bChooseOrientFirstTri ? t : (t+1);
                            final t1 = bChooseOrientFirstTri ? (t+1) : t;
                            pTriInfos[t1].iFlag &= (~ORIENT_PRESERVING);	// clear first
                            pTriInfos[t1].iFlag |= (pTriInfos[t0].iFlag&ORIENT_PRESERVING);	// copy bit
                        }
                    }
                }
                t += 2;
            }
            else
                ++t;
        }
        
        // match up edge pairs
        {
            var pEdges:Array<SEdge> = [ for(i in 0...iNrTrianglesIn*3) new SEdge() ];
            BuildNeighborsFast(pTriInfos, pEdges, piTriListIn, iNrTrianglesIn);
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static function Build4RuleGroups(pTriInfos:Array<STriInfo>, pGroups:Array<SGroup>, piGroupTrianglesBuffer:Array<Int>, piTriListIn:Array<Int>, iNrTrianglesIn:Int):Int
    {
        final iNrMaxGroups = iNrTrianglesIn*3;
        var iNrActiveGroups = 0;
        var iOffset = 0;
        for (f in 0...iNrTrianglesIn)
        {
            for (i in 0...3)
            {
                // if not assigned to a group
                if ((pTriInfos[f].iFlag&GROUP_WITH_ANY)==0 && pTriInfos[f].AssignedGroup[i]==null)
                {
                    var bOrPre:Bool;
                    var neigh_indexL:Int, neigh_indexR:Int;
                    final vert_index = piTriListIn[f*3+i];
                    assert(iNrActiveGroups<iNrMaxGroups);
                    pTriInfos[f].AssignedGroup[i] = pGroups[iNrActiveGroups];
                    pTriInfos[f].AssignedGroup[i].iVertexRepresentitive = vert_index;
                    pTriInfos[f].AssignedGroup[i].bOrientPreservering = (pTriInfos[f].iFlag&ORIENT_PRESERVING)!=0;
                    pTriInfos[f].AssignedGroup[i].iNrFaces = 0;
                    pTriInfos[f].AssignedGroup[i].pFaceIndicesRaw = piGroupTrianglesBuffer;
                    pTriInfos[f].AssignedGroup[i].pFaceIndicesOffset = iOffset;
                    ++iNrActiveGroups;

                    AddTriToGroup(pTriInfos[f].AssignedGroup[i], f);
                    bOrPre = (pTriInfos[f].iFlag&ORIENT_PRESERVING)!=0;
                    neigh_indexL = pTriInfos[f].FaceNeighbors[i];
                    neigh_indexR = pTriInfos[f].FaceNeighbors[i>0?(i-1):2];
                    if (neigh_indexL>=0) // neighbor
                    {
                        final bAnswer =
                            AssignRecur(piTriListIn, pTriInfos, neigh_indexL,
                                        pTriInfos[f].AssignedGroup[i] );
                        
                        final bOrPre2 = (pTriInfos[neigh_indexL].iFlag&ORIENT_PRESERVING)!=0;
                        final bDiff = bOrPre!=bOrPre2;
                        assert(bAnswer || bDiff);
                    }
                    if (neigh_indexR>=0) // neighbor
                    {
                        final bAnswer =
                            AssignRecur(piTriListIn, pTriInfos, neigh_indexR,
                                        pTriInfos[f].AssignedGroup[i] );

                        final bOrPre2 = (pTriInfos[neigh_indexR].iFlag&ORIENT_PRESERVING)!=0;
                        final bDiff = bOrPre!=bOrPre2;
                        assert(bAnswer || bDiff);
                    }

                    // update offset
                    iOffset += pTriInfos[f].AssignedGroup[i].iNrFaces;
                    // since the groups are disjoint a triangle can never
                    // belong to more than 3 groups. Subsequently something
                    // is completely screwed if this assertion ever hits.
                    assert(iOffset <= iNrMaxGroups);
                }
            }
        }

        return iNrActiveGroups;
    }

    static function AddTriToGroup(pGroup:SGroup, iTriIndex:Int)
    {
        pGroup.pFaceIndicesRaw[pGroup.pFaceIndicesOffset + pGroup.iNrFaces] = iTriIndex;
        ++pGroup.iNrFaces;
    }
    
    static function AssignRecur(piTriListIn:Array<Int>, psTriInfos:Array<STriInfo>, iMyTriIndex:Int, pGroup:SGroup):Bool
    {
        var pMyTriInfo = psTriInfos[iMyTriIndex];
    
        // track down vertex
        final iVertRep = pGroup.iVertexRepresentitive;
        var offsetVerts = 3*iMyTriIndex+0;
        var i=-1;
        if (piTriListIn[offsetVerts+0]==iVertRep) i=0;
        else if (piTriListIn[offsetVerts+1]==iVertRep) i=1;
        else if (piTriListIn[offsetVerts+2]==iVertRep) i=2;
        assert(i>=0 && i<3);
    
        // early out
        if (pMyTriInfo.AssignedGroup[i] == pGroup) return true;
        else if (pMyTriInfo.AssignedGroup[i]!=null) return false;
        if ((pMyTriInfo.iFlag&GROUP_WITH_ANY)!=0)
        {
            // first to group with a group-with-anything triangle
            // determines it's orientation.
            // This is the only existing order dependency in the code!!
            if ( pMyTriInfo.AssignedGroup[0] == null &&
                pMyTriInfo.AssignedGroup[1] == null &&
                pMyTriInfo.AssignedGroup[2] == null )
            {
                pMyTriInfo.iFlag &= (~ORIENT_PRESERVING);
                pMyTriInfo.iFlag |= (pGroup.bOrientPreservering ? ORIENT_PRESERVING : 0);
            }
        }
        {
            final bOrient = (pMyTriInfo.iFlag&ORIENT_PRESERVING)!=0;
            if (bOrient != pGroup.bOrientPreservering) return false;
        }
    
        AddTriToGroup(pGroup, iMyTriIndex);
        pMyTriInfo.AssignedGroup[i] = pGroup;
    
        {
            final neigh_indexL = pMyTriInfo.FaceNeighbors[i];
            final neigh_indexR = pMyTriInfo.FaceNeighbors[i>0?(i-1):2];
            if (neigh_indexL>=0)
                AssignRecur(piTriListIn, psTriInfos, neigh_indexL, pGroup);
            if (neigh_indexR>=0)
                AssignRecur(piTriListIn, psTriInfos, neigh_indexR, pGroup);
        }
    
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static function GenerateTSpaces(psTspace:Array<STSpace>, pTriInfos:Array<STriInfo>, pGroups:Array<SGroup>,
                                 iNrActiveGroups:Int, piTriListIn:Array<Int>, fThresCos:Float,
                                 pContext:SMikkTSpaceContext):Bool
    {
        var pSubGroupTspace:Array<STSpace> = null;
        var pUniSubGroups:Array<SSubGroup> = null;
        var pTmpMembers:Array<Int> = null;
        var iMaxNrFaces=0, iUniqueTspaces=0;
        for (g in 0...iNrActiveGroups)
            if (iMaxNrFaces < pGroups[g].iNrFaces)
                iMaxNrFaces = pGroups[g].iNrFaces;

        if (iMaxNrFaces == 0) return true;

        // make initial allocations
        pSubGroupTspace = [ for(i in 0...iMaxNrFaces) new STSpace() ];
        pUniSubGroups = [ for(i in 0...iMaxNrFaces) new SSubGroup() ];
        pTmpMembers = [ for(i in 0...iMaxNrFaces) 0 ];


        iUniqueTspaces = 0;
        for (g in 0...iNrActiveGroups)
        {
            var pGroup = pGroups[g];
            var iUniqueSubGroups = 0;

            for (i in 0...pGroup.iNrFaces)	// triangles
            {
                final f = pGroup.pFaceIndicesRaw[pGroup.pFaceIndicesOffset + i];	// triangle number
                var index=-1, iVertIndex=-1, iOF_1=-1, iMembers=0;
                var tmp_group:SSubGroup = new SSubGroup();
                var bFound:Bool;
                var n:SVec3, vOs:SVec3, vOt:SVec3;
                if (pTriInfos[f].AssignedGroup[0]==pGroup) index=0;
                else if (pTriInfos[f].AssignedGroup[1]==pGroup) index=1;
                else if (pTriInfos[f].AssignedGroup[2]==pGroup) index=2;
                assert(index>=0 && index<3);

                iVertIndex = piTriListIn[f*3+index];
                assert(iVertIndex==pGroup.iVertexRepresentitive);

                // is normalized already
                n = GetNormal(pContext, iVertIndex);
                
                // project
                vOs = vsub(pTriInfos[f].vOs, vscale(vdot(n,pTriInfos[f].vOs), n));
                vOt = vsub(pTriInfos[f].vOt, vscale(vdot(n,pTriInfos[f].vOt), n));
                if ( VNotZero(vOs) ) vOs = Normalize(vOs);
                if ( VNotZero(vOt) ) vOt = Normalize(vOt);

                // original face number
                iOF_1 = pTriInfos[f].iOrgFaceNumber;
                
                iMembers = 0;
                for (j in 0...pGroup.iNrFaces)
                {
                    final t = pGroup.pFaceIndicesRaw[pGroup.pFaceIndicesOffset + j];	// triangle number
                    final iOF_2 = pTriInfos[t].iOrgFaceNumber;

                    // project
                    var vOs2 = vsub(pTriInfos[t].vOs, vscale(vdot(n,pTriInfos[t].vOs), n));
                    var vOt2 = vsub(pTriInfos[t].vOt, vscale(vdot(n,pTriInfos[t].vOt), n));
                    if ( VNotZero(vOs2) ) vOs2 = Normalize(vOs2);
                    if ( VNotZero(vOt2) ) vOt2 = Normalize(vOt2);

                    {
                        final bAny = ( (pTriInfos[f].iFlag | pTriInfos[t].iFlag) & GROUP_WITH_ANY )!=0;
                        // make sure triangles which belong to the same quad are joined.
                        final bSameOrgFace = iOF_1==iOF_2;

                        final fCosS = vdot(vOs,vOs2);
                        final fCosT = vdot(vOt,vOt2);

                        assert(f!=t || bSameOrgFace);	// sanity check
                        if (bAny || bSameOrgFace || (fCosS>fThresCos && fCosT>fThresCos))
                            pTmpMembers[iMembers++] = t;
                    }
                }

                // sort pTmpMembers
                tmp_group.iNrFaces = iMembers;
                tmp_group.pTriMembers = pTmpMembers;
                if (iMembers>1)
                {
                    QuickSort(pTmpMembers, 0, iMembers - 1, INTERNAL_RND_SORT_SEED);
                }

                // look for an existing match
                bFound = false;
                var l=0;
                while (l<iUniqueSubGroups && !bFound)
                {
                    bFound = CompareSubGroups(tmp_group, pUniSubGroups[l]);
                    if (!bFound) ++l;
                }
                
                // assign tangent space index
                assert(bFound || l==iUniqueSubGroups);
                //piTempTangIndices[f*3+index] = iUniqueTspaces+l;

                // if no match was found we allocate a new subgroup
                if (!bFound)
                {
                    // insert new subgroup
                    var pIndices = [ for(i in 0...iMembers) 0 ];
                    pUniSubGroups[iUniqueSubGroups].iNrFaces = iMembers;
                    pUniSubGroups[iUniqueSubGroups].pTriMembers = pIndices;
                    for(i in 0...iMembers)
                        pIndices[i] = tmp_group.pTriMembers[i];
                    pSubGroupTspace[iUniqueSubGroups].copyFrom(
                        EvalTspace(tmp_group.pTriMembers, iMembers, piTriListIn, pTriInfos, pContext, pGroup.iVertexRepresentitive));
                    ++iUniqueSubGroups;
                }

                // output tspace
                {
                    final iOffs = pTriInfos[f].iTSpacesOffs;
                    final iVert = pTriInfos[f].vert_num[index];
                    var pTS_out = psTspace[iOffs+iVert];
                    assert(pTS_out.iCounter<2);
                    assert(((pTriInfos[f].iFlag&ORIENT_PRESERVING)!=0) == pGroup.bOrientPreservering);
                    if (pTS_out.iCounter==1)
                    {
                        pTS_out.copyFrom(AvgTSpace(pTS_out, pSubGroupTspace[l]));
                        pTS_out.iCounter = 2;	// update counter
                        pTS_out.bOrient = pGroup.bOrientPreservering;
                    }
                    else
                    {
                        assert(pTS_out.iCounter==0);
                        pTS_out.copyFrom(pSubGroupTspace[l]);
                        pTS_out.iCounter = 1;	// update counter
                        pTS_out.bOrient = pGroup.bOrientPreservering;
                    }
                }
            }

            // clean up and offset iUniqueTspaces
            iUniqueTspaces += iUniqueSubGroups;
        }

        return true;
    }

    static function EvalTspace(face_indices:Array<Int>, iFaces:Int, piTriListIn:Array<Int>, pTriInfos:Array<STriInfo>,
                               pContext:SMikkTSpaceContext, iVertexRepresentitive:Int):STSpace
    {
        var res:STSpace = new STSpace();
        var fAngleSum:FastFloat = 0;
        res.vOs.x=0.0; res.vOs.y=0.0; res.vOs.z=0.0;
        res.vOt.x=0.0; res.vOt.y=0.0; res.vOt.z=0.0;
        res.fMagS = 0; res.fMagT = 0;

        for (face in 0...iFaces)
        {
            final f = face_indices[face];

            // only valid triangles get to add their contribution
            if ( (pTriInfos[f].iFlag&GROUP_WITH_ANY)==0 )
            {
                var n, vOs, vOt, p0, p1, p2, v1, v2 = new SVec3();
                var fCos:FastFloat, fAngle:FastFloat, fMagS:FastFloat, fMagT:FastFloat;
                var i=-1, index=-1, i0=-1, i1=-1, i2=-1;
                if (piTriListIn[3*f+0]==iVertexRepresentitive) i=0;
                else if (piTriListIn[3*f+1]==iVertexRepresentitive) i=1;
                else if (piTriListIn[3*f+2]==iVertexRepresentitive) i=2;
                assert(i>=0 && i<3);

                // project
                index = piTriListIn[3*f+i];
                n = GetNormal(pContext, index);
                vOs = vsub(pTriInfos[f].vOs, vscale(vdot(n,pTriInfos[f].vOs), n));
                vOt = vsub(pTriInfos[f].vOt, vscale(vdot(n,pTriInfos[f].vOt), n));
                if ( VNotZero(vOs) ) vOs = Normalize(vOs);
                if ( VNotZero(vOt) ) vOt = Normalize(vOt);

                i2 = piTriListIn[3*f + (i<2?(i+1):0)];
                i1 = piTriListIn[3*f + i];
                i0 = piTriListIn[3*f + (i>0?(i-1):2)];

                p0 = GetPosition(pContext, i0);
                p1 = GetPosition(pContext, i1);
                p2 = GetPosition(pContext, i2);
                v1 = vsub(p0,p1);
                v2 = vsub(p2,p1);

                // project
                v1 = vsub(v1, vscale(vdot(n,v1),n)); if ( VNotZero(v1) ) v1 = Normalize(v1);
                v2 = vsub(v2, vscale(vdot(n,v2),n)); if ( VNotZero(v2) ) v2 = Normalize(v2);

                // weight contribution by the angle
                // between the two edge vectors
                fCos = vdot(v1,v2); fCos=fCos>1?1:(fCos<(-1) ? (-1) : fCos);
                fAngle = Math.acos(fCos);
                fMagS = pTriInfos[f].fMagS;
                fMagT = pTriInfos[f].fMagT;

                res.vOs=vadd(res.vOs, vscale(fAngle,vOs));
                res.vOt=vadd(res.vOt,vscale(fAngle,vOt));
                res.fMagS+=(fAngle*fMagS);
                res.fMagT+=(fAngle*fMagT);
                fAngleSum += fAngle;
            }
        }

        // normalize
        if ( VNotZero(res.vOs) ) res.vOs = Normalize(res.vOs);
        if ( VNotZero(res.vOt) ) res.vOt = Normalize(res.vOt);
        if (fAngleSum>0)
        {
            res.fMagS /= fAngleSum;
            res.fMagT /= fAngleSum;
        }

        return res;
    }

    static function CompareSubGroups(pg1:SSubGroup, pg2:SSubGroup):Bool
    {
        var bStillSame=true;
        var i=0;
        if (pg1.iNrFaces!=pg2.iNrFaces) return false;
        while (i<pg1.iNrFaces && bStillSame)
        {
            bStillSame = pg1.pTriMembers[i]==pg2.pTriMembers[i];
            if (bStillSame) ++i;
        }
        return bStillSame;
    }

    static function QuickSort(pSortBuffer:Array<Int>, iLeft:Int, iRight:Int, uSeed:UInt):Void
    {
        var iL, iR, n, index, iMid, iTmp = 0;

        // Random
        var t=uSeed&31;
        t=(uSeed<<t)|(uSeed>>(32-t));
        uSeed=uSeed+t+3;
        // Random end

        iL=iLeft; iR=iRight;
        n = (iR-iL)+1;
        assert(n>=0);
        index = cast(uSeed%n, Int);

        iMid=pSortBuffer[index + iL];


        do
        {
            while (pSortBuffer[iL] < iMid)
                ++iL;
            while (pSortBuffer[iR] > iMid)
                --iR;

            if (iL <= iR)
            {
                iTmp = pSortBuffer[iL];
                pSortBuffer[iL] = pSortBuffer[iR];
                pSortBuffer[iR] = iTmp;
                ++iL; --iR;
            }
        }
        while (iL <= iR);

        if (iLeft < iR)
            QuickSort(pSortBuffer, iLeft, iR, uSeed);
        if (iL < iRight)
            QuickSort(pSortBuffer, iL, iRight, uSeed);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////

    static function BuildNeighborsFast(pTriInfos:Array<STriInfo>, pEdges:Array<SEdge>, piTriListIn:Array<Int>, iNrTrianglesIn:Int)
    {
        var uSeed = INTERNAL_RND_SORT_SEED;				// could replace with a random seed?

        // build array of edges
        var iEntries=0, iCurStartIndex=-1;
        for (f in 0...iNrTrianglesIn)
            for (i in 0...3)
            {
                final i0 = piTriListIn[f*3+i];
                final i1 = piTriListIn[f*3+(i<2?(i+1):0)];
                pEdges[f*3+i].i0 = i0 < i1 ? i0 : i1;			// put minimum index in i0
                pEdges[f*3+i].i1 = !(i0 < i1) ? i0 : i1;		// put maximum index in i1
                pEdges[f*3+i].f = f;							// record face number
            }

        // sort over all edges by i0, this is the pricy one.
        QuickSortEdges(pEdges, 0, iNrTrianglesIn*3-1, 0, uSeed);	// sort channel 0 which is i0

        // sub sort over i1, should be fast.
        // could replace this with a 64 bit int sort over (i0,i1)
        // with i0 as msb in the quicksort call above.
        iEntries = iNrTrianglesIn*3;
        iCurStartIndex = 0;
        for (i in 1...iEntries)
        {
            if (pEdges[iCurStartIndex].i0 != pEdges[i].i0)
            {
                final iL = iCurStartIndex;
                final iR = i-1;
                //const int iElems = i-iL;
                iCurStartIndex = i;
                QuickSortEdges(pEdges, iL, iR, 1, uSeed);	// sort channel 1 which is i1
            }
        }

        // sub sort over f, which should be fast.
        // this step is to remain compliant with BuildNeighborsSlow() when
        // more than 2 triangles use the same edge (such as a butterfly topology).
        iCurStartIndex = 0;
        for (i in 1...iEntries)
        {
            if (pEdges[iCurStartIndex].i0 != pEdges[i].i0 || pEdges[iCurStartIndex].i1 != pEdges[i].i1)
            {
                final iL = iCurStartIndex;
                final iR = i-1;
                //const int iElems = i-iL;
                iCurStartIndex = i;
                QuickSortEdges(pEdges, iL, iR, 2, uSeed);	// sort channel 2 which is f
            }
        }

        // pair up, adjacent triangles
        for (i in 0...iEntries)
        {
            final i0=pEdges[i].i0;
            final i1=pEdges[i].i1;
            final f = pEdges[i].f;
            var bUnassigned_A:Bool;

            var i0_A, i1_A = 0;
            var edgenum_A, edgenum_B=0;	// 0,1 or 2
            var res = GetEdge(piTriListIn, f*3, i0, i1);	// resolve index ordering and edge_num
            var i0_A = res.i0, i1_A = res.i1;
            var edgenum_A = res.edgenum;
            var edgenum_B = 0;
            bUnassigned_A = pTriInfos[f].FaceNeighbors[edgenum_A] == -1;

            if (bUnassigned_A)
            {
                // get true index ordering
                var j=i+1, t=0;
                var bNotFound = true;
                while (j<iEntries && i0==pEdges[j].i0 && i1==pEdges[j].i1 && bNotFound)
                {
                    var bUnassigned_B:Bool;
                    t = pEdges[j].f;
                    // flip i0_B and i1_B
                    var res2 = GetEdge(piTriListIn, t*3, pEdges[j].i0, pEdges[j].i1);	// resolve index ordering and edge_num
                    var i1_B = res2.i0, i0_B = res2.i1;
                    edgenum_B = res2.edgenum;

                    //assert(!(i0_A==i1_B && i1_A==i0_B));
                    bUnassigned_B =  pTriInfos[t].FaceNeighbors[edgenum_B]==-1;
                    if (i0_A==i0_B && i1_A==i1_B && bUnassigned_B)
                        bNotFound = false;
                    else
                        ++j;
                }

                if (!bNotFound)
                {
                    var t = pEdges[j].f;
                    pTriInfos[f].FaceNeighbors[edgenum_A] = t;
                    //assert(pTriInfos[t].FaceNeighbors[edgenum_B]==-1);
                    pTriInfos[t].FaceNeighbors[edgenum_B] = f;
                }
            }
        }
    }
    
    static function QuickSortEdges(pSortBuffer:Array<SEdge>, iLeft:Int, iRight:Int, channel:Int, uSeed:UInt):Void
    {
        var t:UInt;
        var iL, iR, n, index, iMid = 0;
    
        // early out
        var sTmp:SEdge;
        final iElems = iRight-iLeft+1;
        if (iElems<2) return;
        else if (iElems==2)
        {
            if (pSortBuffer[iLeft][channel] > pSortBuffer[iRight][channel])
            {
                sTmp = pSortBuffer[iLeft];
                pSortBuffer[iLeft] = pSortBuffer[iRight];
                pSortBuffer[iRight] = sTmp;
            }
            return;
        }
    
        // Random
        t=uSeed&31;
        t=(uSeed<<t)|(uSeed>>(32-t));
        uSeed=uSeed+t+3;
        // Random end
    
        iL=iLeft; iR=iRight;
        n = (iR-iL)+1;
        assert(n>=0);
        index = cast((uSeed%n), Int);
    
        iMid=pSortBuffer[index + iL][channel];
    
        do
        {
            while (pSortBuffer[iL][channel] < iMid)
                ++iL;
            while (pSortBuffer[iR][channel] > iMid)
                --iR;
    
            if (iL <= iR)
            {
                sTmp = pSortBuffer[iL];
                pSortBuffer[iL] = pSortBuffer[iR];
                pSortBuffer[iR] = sTmp;
                ++iL; --iR;
            }
        }
        while (iL <= iR);
    
        if (iLeft < iR)
            QuickSortEdges(pSortBuffer, iLeft, iR, channel, uSeed);
        if (iL < iRight)
            QuickSortEdges(pSortBuffer, iL, iRight, channel, uSeed);
    }

    // resolve ordering and edge number
    static function GetEdge(indices:Array<Int>, indices_offset:Int, i0_in:Int, i1_in:Int):{i0:Int, i1:Int, edgenum:Int}
    {
        var res = { i0:0, i1:0, edgenum: -1 };
        
        // test if first index is on the edge
        if (indices[indices_offset+0]==i0_in || indices[indices_offset+0]==i1_in)
        {
            // test if second index is on the edge
            if (indices[indices_offset+1]==i0_in || indices[indices_offset+1]==i1_in)
            {
                res.edgenum=0;	// first edge
                res.i0=indices[indices_offset+0];
                res.i1=indices[indices_offset+1];
            }
            else
            {
                res.edgenum=2;	// third edge
                res.i0=indices[indices_offset+2];
                res.i1=indices[indices_offset+0];
            }
        }
        else
        {
            // only second and third index is on the edge
            res.edgenum=1;	// second edge
            res.i0=indices[indices_offset+1];
            res.i1=indices[indices_offset+2];
        }

        return res;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// Degenerate triangles ////////////////////////////////////

    static function DegenPrologue(pTriInfos:Array<STriInfo>, piTriList_out:Array<Int>, iNrTrianglesIn:Int, iTotTris:Int)
    {
        var iNextGoodTriangleSearchIndex=-1;
        var bStillFindingGoodOnes:Bool;

        // locate quads with only one good triangle
        var t=0;
        while (t<(iTotTris-1))
        {
            final iFO_a = pTriInfos[t].iOrgFaceNumber;
            final iFO_b = pTriInfos[t+1].iOrgFaceNumber;
            if (iFO_a==iFO_b)	// this is a quad
            {
                final bIsDeg_a = (pTriInfos[t].iFlag&MARK_DEGENERATE)!=0;
                final bIsDeg_b = (pTriInfos[t+1].iFlag&MARK_DEGENERATE)!=0;
                if (bIsDeg_a != bIsDeg_b)
                {
                    pTriInfos[t].iFlag |= QUAD_ONE_DEGEN_TRI;
                    pTriInfos[t+1].iFlag |= QUAD_ONE_DEGEN_TRI;
                }
                t += 2;
            }
            else
                ++t;
        }

        // reorder list so all degen triangles are moved to the back
        // without reordering the good triangles
        iNextGoodTriangleSearchIndex = 1;
        t=0;
        bStillFindingGoodOnes = true;
        while (t<iNrTrianglesIn && bStillFindingGoodOnes)
        {
            final bIsGood = (pTriInfos[t].iFlag&MARK_DEGENERATE)==0;
            if (bIsGood)
            {
                if (iNextGoodTriangleSearchIndex < (t+2))
                    iNextGoodTriangleSearchIndex = t+2;
            }
            else
            {
                var t0 = 0, t1 = 0;
                // search for the first good triangle.
                var bJustADegenerate = true;
                while (bJustADegenerate && iNextGoodTriangleSearchIndex<iTotTris)
                {
                    var bIsGood = (pTriInfos[iNextGoodTriangleSearchIndex].iFlag&MARK_DEGENERATE)==0;
                    if (bIsGood) bJustADegenerate=false;
                    else ++iNextGoodTriangleSearchIndex;
                }

                t0 = t;
                t1 = iNextGoodTriangleSearchIndex;
                ++iNextGoodTriangleSearchIndex;
                assert(iNextGoodTriangleSearchIndex > (t+1));

                // swap triangle t0 and t1
                if (!bJustADegenerate)
                {
                    for (i in 0...3)
                    {
                        var index = piTriList_out[t0*3+i];
                        piTriList_out[t0*3+i] = piTriList_out[t1*3+i];
                        piTriList_out[t1*3+i] = index;
                    }
                    {
                        var tri_info = pTriInfos[t0];
                        pTriInfos[t0] = pTriInfos[t1];
                        pTriInfos[t1] = tri_info;
                    }
                }
                else
                    bStillFindingGoodOnes = false;	// this is not supposed to happen
            }

            if (bStillFindingGoodOnes) ++t;
        }

        assert(bStillFindingGoodOnes);	// code will still work.
        assert(iNrTrianglesIn == t);
    }

    static function DegenEpilogue(psTspace:Array<STSpace>, pTriInfos:Array<STriInfo>, piTriListIn:Array<Int>, pContext:SMikkTSpaceContext, iNrTrianglesIn:Int, iTotTris:Int)
    {
        // deal with degenerate triangles
        // punishment for degenerate triangles is O(N^2)
        for (t in iNrTrianglesIn...iTotTris)
        {
            // degenerate triangles on a quad with one good triangle are skipped
            // here but processed in the next loop
            var bSkip = (pTriInfos[t].iFlag&QUAD_ONE_DEGEN_TRI)!=0;

            if (!bSkip)
            {
                for (i in 0...3)
                {
                    final index1 = piTriListIn[t*3+i];
                    // search through the good triangles
                    var bNotFound = true;
                    var j=0;
                    while (bNotFound && j<(3*iNrTrianglesIn))
                    {
                        final index2 = piTriListIn[j];
                        if (index1==index2) bNotFound=false;
                        else ++j;
                    }

                    if (!bNotFound)
                    {
                        final iTri:Int = cast j/3;
                        final iVert:Int = j%3;
                        final iSrcVert=pTriInfos[iTri].vert_num[iVert];
                        final iSrcOffs=pTriInfos[iTri].iTSpacesOffs;
                        final iDstVert=pTriInfos[t].vert_num[i];
                        final iDstOffs=pTriInfos[t].iTSpacesOffs;
                        
                        // copy tspace
                        psTspace[iDstOffs+iDstVert] = psTspace[iSrcOffs+iSrcVert];
                    }
                }
            }
        }

        // deal with degenerate quads with one good triangle
        for (t in 0...iNrTrianglesIn)
        {
            // this triangle belongs to a quad where the
            // other triangle is degenerate
            if ( (pTriInfos[t].iFlag&QUAD_ONE_DEGEN_TRI)!=0 )
            {
                var vDstP:SVec3;
                var iOrgF=-1, i=0;
                var bNotFound:Bool;
                var pV = pTriInfos[t].vert_num;
                var iFlag = (1<<pV[0]) | (1<<pV[1]) | (1<<pV[2]);
                var iMissingIndex = 0;
                if ((iFlag&2)==0) iMissingIndex=1;
                else if ((iFlag&4)==0) iMissingIndex=2;
                else if ((iFlag&8)==0) iMissingIndex=3;

                iOrgF = pTriInfos[t].iOrgFaceNumber;
                vDstP = GetPosition(pContext, MakeIndex(iOrgF, iMissingIndex));
                bNotFound = true;
                i=0;
                while (bNotFound && i<3)
                {
                    final iVert = pV[i];
                    final vSrcP = GetPosition(pContext, MakeIndex(iOrgF, iVert));
                    if (veq(vSrcP, vDstP))
                    {
                        final iOffs = pTriInfos[t].iTSpacesOffs;
                        psTspace[iOffs+iMissingIndex] = psTspace[iOffs+iVert];
                        bNotFound=false;
                    }
                    else
                        ++i;
                }
                assert(!bNotFound);
            }
        }
    }

}