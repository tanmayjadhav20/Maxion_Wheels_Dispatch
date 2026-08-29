const fs=require('fs'),zlib=require('zlib');

function decode(file){
  const b=fs.readFileSync(file);
  let p=8, w,h,bd,ct, idat=[];
  while(p<b.length){
    const len=b.readUInt32BE(p); const type=b.toString('ascii',p+4,p+8);
    const data=b.slice(p+8,p+8+len);
    if(type==='IHDR'){w=data.readUInt32BE(0);h=data.readUInt32BE(4);bd=data[8];ct=data[9];}
    else if(type==='IDAT') idat.push(data);
    else if(type==='IEND') break;
    p+=12+len;
  }
  if(bd!==8||ct!==6) throw new Error('only 8-bit RGBA supported, got bd='+bd+' ct='+ct);
  const raw=zlib.inflateSync(Buffer.concat(idat));
  const bpp=4, stride=w*bpp;
  const out=Buffer.alloc(h*stride);
  let rp=0;
  for(let y=0;y<h;y++){
    const ft=raw[rp++];
    const line=raw.slice(rp,rp+stride); rp+=stride;
    const cur=out.slice(y*stride,(y+1)*stride);
    const prev=y>0?out.slice((y-1)*stride,y*stride):null;
    for(let x=0;x<stride;x++){
      const a=x>=bpp?cur[x-bpp]:0, bb=prev?prev[x]:0, c=(prev&&x>=bpp)?prev[x-bpp]:0;
      let v=line[x];
      switch(ft){
        case 0: break;
        case 1: v=(v+a)&255; break;
        case 2: v=(v+bb)&255; break;
        case 3: v=(v+((a+bb)>>1))&255; break;
        case 4: {const pp=a+bb-c,pa=Math.abs(pp-a),pb=Math.abs(pp-bb),pc=Math.abs(pp-c);
                 v=(v+((pa<=pb&&pa<=pc)?a:(pb<=pc?bb:c)))&255; break;}
        default: throw new Error('filter '+ft);
      }
      cur[x]=v;
    }
  }
  return {w,h,px:out};
}

function encode(w,h,px){
  const stride=w*4;
  const raw=Buffer.alloc(h*(stride+1));
  for(let y=0;y<h;y++){ raw[y*(stride+1)]=0; px.copy(raw,y*(stride+1)+1,y*stride,(y+1)*stride); }
  const idat=zlib.deflateSync(raw,{level:9});
  const chunks=[];
  const chunk=(type,data)=>{
    const c=Buffer.alloc(8+data.length+4);
    c.writeUInt32BE(data.length,0); c.write(type,4,'ascii'); data.copy(c,8);
    c.writeUInt32BE(crc(Buffer.concat([Buffer.from(type,'ascii'),data]))>>>0,8+data.length);
    chunks.push(c);
  };
  const ihdr=Buffer.alloc(13);
  ihdr.writeUInt32BE(w,0); ihdr.writeUInt32BE(h,4); ihdr[8]=8; ihdr[9]=6;
  chunks.push(Buffer.from([0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]));
  chunk('IHDR',ihdr); chunk('IDAT',idat); chunk('IEND',Buffer.alloc(0));
  return Buffer.concat(chunks);
}
let T=null;
function crc(buf){
  if(!T){T=[];for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xedb88320^(c>>>1):c>>>1;T[n]=c>>>0;}}
  let c=0xffffffff;
  for(let i=0;i<buf.length;i++) c=T[(c^buf[i])&255]^(c>>>8);
  return (c^0xffffffff)>>>0;
}
module.exports={decode,encode};
