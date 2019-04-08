unit File3dsLoader2;

interface
uses
Direct3d,dxtypes,windows,D3Dunit,Mtools;
const
MM_BACKFACE=1;


procedure Load3dsFile(Filename:string;var ModelMesh:TMesh;M_Flag:cardinal);



///////////////////////////////////////////////////////////////////////////////
implementation

type
Nindex=array[0..9] of char;

var
vertexcounter:integer;
group:array[0..MAX_GROUPS] of cardinal;
ngroup:cardinal;
counter:integer;
NameIndex:array[0..MAX_MATERIALS] of NIndex;

////////////////////////////////////////////////////////////////////////////////
function SearchForMaterial(P,P2:Pointer;FileSize,StartofBlock:integer):integer;
begin
asm
push ebx
push esi
push edi
mov esi,p
mov edi,p2               //search for Material0,1,2,3,.....
add esi,StartofBlock


mov ebx,filesize
sub ebx,startofBlock
sub ebx,4

@loop:
mov ecx,0
@TextSearch:

mov dx,[esi+ecx+10]               //End search with next 4100,4110 block.
cmp dx,$4100                   //new  search in own group only.
jne @noteog
mov dx,[esi+ecx+16]
cmp dx,$4110
jne @notEog
jmp @NoOverallMatch
@notEog:                      //

mov al,[esi+ecx]
mov ah,[edi+ecx]
cmp al,ah
jne @noMatch
cmp ah,0
je @Match
inc ecx
cmp ecx,10
jl @TextSearch
//Match  Must search for null
@Match:
@Findnull:
mov al,[esi]
inc esi
cmp al,0
je @null
jmp @Findnull

@null:
sub esi,p
mov @result,esi
jmp @End

@noMatch:
inc esi
dec ebx
jnz @loop
@NoOverallMatch:
mov eax,0
mov @result,eax


@end:
pop edi
pop esi
pop ebx
end;

end;
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
procedure Load3dsData(OpenFile:Pointer;Filesize,pGroup:Cardinal;var ModelMesh:Tmesh;M_Flag:cardinal);
type
TVector=record
x:single;
y:single;
z:single;
end;
type
TFace=Record
vector:Tvector;
tu:single;
tv:single;
end;

var
pface,pMatBlock,pTex:cardinal;
Mcount,c,x,z:integer;
pMat:integer;
vABC:array [0..2] of word;
FaceCoord:array[0..2] of TFace;
nF:word;
pos:array[0..2] of cardinal;
p,p2:pointer;
FaceVectors:array[0..2] of TD3Dvector;
FaceNormal:Td3dvector;

begin
zeromemory(@pos[0],12);
nF:=0;
p:=@pos[0];
asm                            //search for offset in data to 4120-4140 chunks
push ebx
push esi
push edi
mov dx,$4120
mov esi,openfile
mov edi,p

mov ebx,3
mov ecx,pGroup
@loop:
mov ax,[esi+ecx]
cmp ax,$4100                   //End search with next 4100,4110 block.
jne @noteog                   //Search in own group only.
mov ax,[esi+ecx+6]
cmp ax,$4110
jne @noteog
jmp @notfound
@noteog:                      //

cmp ax,dx
jne @NoMatch
mov al,[esi+ecx+5]
cmp al,0
je @Position

@NoMatch:
inc ecx
cmp ecx,filesize
jl @loop
jmp @notfound

@Position:
mov [edi],ecx

@notfound:
add edi,4
add dx,$10
mov ecx,pGroup
dec ebx
jnz @loop

mov edi,p
mov ecx,[edi]
mov ax,[esi+ecx+6]
mov nF,ax
pop edi
pop esi
pop ebx
end;
pFace:=pos[0]+8;    //4120 offset  Must add 8 to get to actual offset start //
pMatBlock:=pos[1];  //4130 offset
pTex:=pos[2]+8;     //4140 offset
modelmesh.nFaces:=modelmesh.nFaces+Nf;
modelmesh.nVertices:=modelmesh.nVertices+Nf*3;
if counter=0 then getmem(modelmesh.pVertexArray,modelmesh.nVertices*sizeof(TD3DVERTEX))
else reallocmem(modelmesh.pVertexArray,modelmesh.nVertices*sizeof(TD3DVERTEX));


For x:=0 to (ModelMesh.nMaterials-1) do begin
pMat:=SearchforMaterial(OpenFile,@NameIndex[x],Filesize,pMatBlock);

asm
mov ecx,openfile
mov eax,0
mov edx,pMat
mov ax,[ecx+edx] //Num Faces in this Material
mov MCount,eax
end;
if pMat=0 then Mcount:=0;
if MCount>0 then begin
ModelMesh.nMaterialChanges:=ModelMesh.nMaterialChanges+1;   //new
Modelmesh.Mvertexpos[counter].Vcount:=MCount*3;             //new
Modelmesh.Mvertexpos[counter].VIndex:=x;                    //new
inc(counter);                                               //new
end;
//writeln('nvertices   ',modelmesh.nvertices);
//writeln(mcount);

p:=@FaceCoord[0];
p2:=@vABC[0];
c:=0;
While c<Mcount do
begin
asm
push ebx
push esi
push edi
mov eax,c
add eax,1
imul eax,2
add eax,pMat
//Get faces number
mov esi,openfile
add esi,eax
mov eax,0
mov ax,[esi]
//Loop for Faces
imul eax,8
mov esi,openfile
add esi,pFace
add esi,eax
mov edi,p2
//Face loop
mov ax,[esi]
mov [edi],ax
mov ax,[esi+2]
mov [edi+2],ax
mov ax,[esi+4]
mov [edi+4],ax

mov ebx,p2
mov edi,p
//loop for Vertices1,2,3
mov ecx,3
@LoopForVertices:
mov eax,0
mov ax,[ebx]
imul eax,12
mov esi,openfile
add esi,pGroup
add esi,eax

mov eax,[esi]
mov [edi],eax
mov eax,[esi+4]
mov [edi+4],eax
mov eax,[esi+8]
mov [edi+8],eax


mov eax,pTex
cmp eax,pGroup
jl @notexture
mov eax,0           //Texture Coords
mov ax,[ebx]
imul eax,8
mov esi,openfile
add esi,pTex
add esi,eax
mov eax,[esi]
mov [edi+12],eax
mov eax,[esi+4]
mov [edi+16],eax


@NoTexture:
add edi,20 //Jump the texture bit
add ebx,2
dec ecx
jnz @LoopForVertices

pop edi
pop esi
pop ebx
end;
//

for z:=0 to 2 do begin
FaceVectors[z].x:=FaceCoord[z].vector.x;
FaceVectors[z].y:=FaceCoord[z].vector.y;
FaceVectors[z].z:=FaceCoord[z].vector.z;

FaceVectors[z]:=VectorMatrixMultiply(FaceVectors[z],rotatexmatrix(1.5707963));
FaceVectors[z]:=VectorMatrixMultiply(FaceVectors[z],rotateymatrix(3.141592654));
end;

//FaceNormal:=vectorcrossproduct(VectorSub(FaceVectors[1],Facevectors[2])
//,VectorSub(FaceVectors[1],Facevectors[0]));
//FaceNormal:=vectornormalize(FaceNormal);

if (M_Flag and MM_BACKFACE)<>MM_BACKFACE then begin
For z:=0 to 2 do
ModelMesh.pVertexArray[vertexcounter+z]:=
setvertex(FaceVectors[z],FaceNormal,FaceCoord[z].tu,-FaceCoord[z].Tv);
end;

if (M_Flag and MM_BACKFACE)=MM_BACKFACE then begin
//Backside-reverse order//
ModelMesh.pVertexArray[vertexcounter+2]:=
setvertex(FaceVectors[0],FaceNormal,FaceCoord[0].tu,-FaceCoord[0].Tv);
ModelMesh.pVertexArray[vertexcounter+1]:=
setvertex(FaceVectors[1],FaceNormal,FaceCoord[1].tu,-FaceCoord[1].Tv);
ModelMesh.pVertexArray[vertexcounter+0]:=
setvertex(FaceVectors[2],FaceNormal,FaceCoord[2].tu,-FaceCoord[2].Tv);
end;

inc(c);
vertexcounter:=vertexcounter+3;
end;
end;

//taken out vertex calculator//
end;

//Material Loading Section/////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
procedure Load3dsFile(Filename:string;var ModelMesh:TMesh;M_Flag:cardinal);
Type
TRGB24=record
r:byte;
g:byte;
b:byte;
end;

Type
RGB3ds=record
NameIndex:array[0..9] of char;
Ambient:TRGB24;
Diffuse:TRGB24;
Specular:TRGB24;
Power:byte;
APower:byte;
Trans:byte;
Emissive:byte;
TextureName:array[0..9] of char;
end;

var
TF:File;
s,nM,x,z:longint;
buf:pointer;
TempRGB:array[0..MAX_MATERIALS] of RGB3ds;
p2:pointer;
Data:array[0..MAX_MATERIALS] of byte;
begin
counter:=0;
vertexcounter:=0;
ngroup:=0;

ModelMesh.Filename:=Filename;
memset(@TempRGB[0],sizeof(TempRGB),0);
nM:=0;

assignfile(TF,ModelMesh.Filename);
reset(TF,1);
s:=filesize(TF);
getmem(buf,filesize(TF));
blockread(TF,Buf^,filesize(TF));
closefile(TF);
p2:=@TempRGB[0];
asm
push ebx
push esi
push edi
mov esi,buf
mov edx,0
mov ecx,s

@loop:
mov ax,[esi]
cmp ax,$AFFF
je @match
inc esi
dec ecx
jnz @loop
jmp @Finish

@Match:
mov ax,[esi+6]
cmp ax,$A000
jne @finish
sub ecx,256
push ecx
mov edi,p2
mov eax,1
add nM,eax
add esi,12

mov ecx,10
@loadName:
mov al,[esi]
mov [edi],al
inc esi
inc edi
cmp al,0
je @eofname
dec ecx
jnz @loadname
jmp @LoadRGB

@eofname:
add edi,ecx
dec edi

@LoadRGB:
mov ecx,15
mov dx,$A010
mov ebx,3
@loop1:
mov ax,[esi]
cmp ax,dx
je @RGBdata
inc esi
dec ecx
jnz @Loop1
sub esi,14
add edi,3
add dx,$10
mov ecx,15
inc esi
dec ebx
jnz @loop1
jmp @LoadPower

@RGBData:
add esi,12
mov al,[esi]
mov [edi],al
mov al,[esi+1]
mov [edi+1],al
mov al,[esi+2]
mov [edi+2],al
add edi,3
add dx,$10
mov ecx,15
inc esi
dec ebx
jnz @loop1

@Loadpower:
mov ecx,15
mov dx,$A040
mov ebx,2
@loop2:
mov ax,[esi]
cmp ax,dx
je @Powerdata
inc esi
dec ecx
jnz @Loop2
inc edi
sub esi,14
jmp @LoadTrans

@powerdata:
add esi,12
mov al,[esi]
mov [edi],al
add dx,$1
inc edi
inc esi
dec ebx
jnz @loop2

//Transparency
@LoadTrans:
mov ecx,15
mov dx,$A050
@loop3:
mov ax,[esi]
cmp ax,dx
je @Transdata
inc esi
dec ecx
jnz @Loop3
inc edi
sub esi,14
jmp @EmissivePower

@Transdata:
add esi,12
mov al,[esi]
mov [edi],al
add edi,1


@EmissivePower:
mov ecx,32
mov dx,$A084
@loop4:
mov ax,[esi]
cmp ax,dx
je @Emissivedata
inc esi
dec ecx
jnz @Loop4
inc edi
sub esi,31
jmp @LoadTexture

@Emissivedata:
add esi,12
mov al,[esi]
mov [edi],al
add edi,1


@LoadTexture:
mov ecx,128
@loop5:
mov ax,[esi]
cmp ax,$A300
je @LoadTName
cmp ax,$AFFF
jne @Texture
mov edx,128
sub edx,ecx
sub esi,edx
jmp @enddata
@Texture:
inc esi
dec ecx
jnz @Loop5
jmp @enddata

@loadTname:
mov ecx,10
add esi,6
@loop6:
mov al,[esi]
cmp al,46
je @enddata
mov [edi],al
cmp al,0
je @enddata
inc esi
inc edi
dec ecx
jnz @loop6


@endData:
mov eax,33
add p2,eax
pop ecx
jmp @loop


@finish:
pop edi
pop esi
pop ebx
end;
z:=0;
//Rearrange So Transparent meshes are first//
ModelMesh.nMaterials:=nM;
Modelmesh.nMaterialchanges:=0;
for x:=0 to (nM-1) do begin
if temprgb[x].Trans>0 then begin
Data[z]:=x;
inc(z);end;
end;
for x:=0 to (nM-1) do begin
if temprgb[x].Trans=0 then begin
Data[z]:=x;
inc(z);end;
end;

for x:=0 to (nM-1) do begin
modelmesh.Material[x].ambient.r:=temprgb[Data[x]].ambient.r/255;
modelmesh.Material[x].ambient.g:=temprgb[Data[x]].ambient.g/255;
modelmesh.Material[x].ambient.b:=temprgb[Data[x]].ambient.b/255;
modelmesh.Material[x].ambient.a:=(100-temprgb[Data[x]].Trans)/100;
modelmesh.Material[x].diffuse.r:=temprgb[Data[x]].diffuse.r/255;
modelmesh.Material[x].diffuse.g:=temprgb[Data[x]].diffuse.g/255;
modelmesh.Material[x].diffuse.b:=temprgb[Data[x]].diffuse.b/255;
modelmesh.Material[x].diffuse.a:=(100-temprgb[Data[x]].Trans)/100;
modelmesh.Material[x].specular.r:=(temprgb[Data[x]].specular.r/255)*(temprgb[Data[x]].APower/100);
modelmesh.Material[x].specular.g:=(temprgb[Data[x]].specular.g/255)*(temprgb[Data[x]].APower/100);
modelmesh.Material[x].specular.b:=(temprgb[Data[x]].specular.b/255)*(temprgb[Data[x]].APower/100);
modelmesh.Material[x].emissive.r:=modelmesh.Material[x].diffuse.r*temprgb[Data[x]].Emissive/100;
modelmesh.Material[x].emissive.g:=modelmesh.Material[x].diffuse.g*temprgb[Data[x]].Emissive/100;
modelmesh.Material[x].emissive.b:=modelmesh.Material[x].diffuse.b*temprgb[Data[x]].Emissive/100;
modelmesh.Material[x].Power:=temprgb[Data[x]].Power;
modelmesh.Material[x].smooth_angle:=DEFAULT_SMOOTH_ANGLE;

if temprgb[Data[x]].textureName[0]<>'' then
begin
modelmesh.material[x].TextureFlag:=1;
memcpy(@modelmesh.Material[x].TextureName,@temprgb[Data[x]].textureName,10);
end;
end;
for x:=0 to (nM-1) do memcpy(@NameIndex[x],@temprgb[Data[x]].nameindex,10);
//
p2:=@group[0];
asm
push esi
push edi
mov edi,p2
mov esi,buf
mov ecx,s
sub ecx,10
@loop1:
mov ax,[esi]
cmp ax,$4100
jne @nomatch
mov ax,[esi+6]
cmp ax,$4110
jne @nomatch
mov eax,esi
sub eax,buf
add eax,14
mov [edi],eax
add edi,4
mov eax,ngroup
add eax,1
mov ngroup,eax
@nomatch:
inc esi
dec ecx
jnz @loop1

pop edi
pop esi
end;

for x:=0 to ngroup-1 do  begin
Load3dsdata(buf,s,group[x],modelmesh,M_Flag);            //must send procedure ngroup.
end;

Modelmesh.Mvertexpos[0].Vstart:=0;
for x:=1 to (modelMesh.nMaterialchanges-1) do begin
Modelmesh.Mvertexpos[x].Vstart:=
Modelmesh.Mvertexpos[x-1].Vstart+Modelmesh.Mvertexpos[x-1].Vcount;
end;

//Smoothing Normals//
smooth_normals(modelmesh);
freemem(buf);
end;


end.
