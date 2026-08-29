// Regenerates the bundled Vistar brand marks from the source art.
//
//   node tool/build_brand_assets.js
//
// Reads assets/logo.png (S swoosh) and assets/logo_name.png (wordmark),
// autocrops each to its visible pixels, resizes in premultiplied-alpha space,
// and writes the three files under assets/brand/ that the app actually ships.
// Run this after replacing either source image.

const fs=require('fs'),path=require('path');
const {decode,encode}=require('./png.js');

const SRC=path.resolve(__dirname,'..','assets');
const OUT=path.join(SRC,'brand');
fs.mkdirSync(OUT,{recursive:true});

// tight autocrop on alpha, with a small transparent margin so glows aren't clipped
function autocrop(img,threshold,marginPct){
  const {w,h,px}=img;
  let x0=w,y0=h,x1=-1,y1=-1;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    if(px[(y*w+x)*4+3]>threshold){
      if(x<x0)x0=x; if(x>x1)x1=x; if(y<y0)y0=y; if(y>y1)y1=y;
    }
  }
  const mx=Math.round((x1-x0+1)*marginPct), my=Math.round((y1-y0+1)*marginPct);
  x0=Math.max(0,x0-mx); y0=Math.max(0,y0-my);
  x1=Math.min(w-1,x1+mx); y1=Math.min(h-1,y1+my);
  const cw=x1-x0+1, ch=y1-y0+1;
  const out=Buffer.alloc(cw*ch*4);
  for(let y=0;y<ch;y++) px.copy(out,y*cw*4,((y+y0)*w+x0)*4,((y+y0)*w+x0+cw)*4);
  return {w:cw,h:ch,px:out};
}

// area-average downscale in PREMULTIPLIED alpha space.
// The source has opaque-grey RGB under alpha=0 pixels; premultiplying keeps that
// grey from bleeding into the edges of the mark.
function resize(img,tw,th){
  const {w,h,px}=img;
  const out=Buffer.alloc(tw*th*4);
  const sx=w/tw, sy=h/th;
  for(let y=0;y<th;y++){
    const yA=Math.floor(y*sy), yB=Math.max(yA+1,Math.ceil((y+1)*sy));
    for(let x=0;x<tw;x++){
      const xA=Math.floor(x*sx), xB=Math.max(xA+1,Math.ceil((x+1)*sx));
      let r=0,g=0,b=0,a=0,n=0;
      for(let j=yA;j<yB&&j<h;j++)for(let i=xA;i<xB&&i<w;i++){
        const o=(j*w+i)*4, al=px[o+3]/255;
        r+=px[o]*al; g+=px[o+1]*al; b+=px[o+2]*al; a+=px[o+3]; n++;
      }
      const o=(y*tw+x)*4;
      const av=a/n;
      if(av<0.5){ out[o]=out[o+1]=out[o+2]=out[o+3]=0; continue; }
      const un=255/av; // un-premultiply
      out[o]=Math.min(255,Math.round(r/n*un));
      out[o+1]=Math.min(255,Math.round(g/n*un));
      out[o+2]=Math.min(255,Math.round(b/n*un));
      out[o+3]=Math.round(av);
    }
  }
  return {w:tw,h:th,px:out};
}

// force RGB of fully-transparent pixels to match their nearest visible colour's hue-free
// neutral so no grey halo can ever appear if a renderer ignores premultiplication
function cleanTransparent(img){
  const {w,h,px}=img;
  for(let i=0;i<w*h;i++){ if(px[i*4+3]===0){ px[i*4]=px[i*4+1]=px[i*4+2]=0; } }
  return img;
}

const jobs=[
  {src:'logo.png',      out:'s_mark.png',    fit:'h', size:720, note:'S mark - loaders, watermark, sidebar glyph'},
  {src:'logo.png',      out:'s_mark_sm.png', fit:'h', size:280, note:'S mark small - inline UI spots'},
  {src:'logo_name.png', out:'wordmark.png',  fit:'w', size:972, note:'Wordmark - splash + login'},
];

for(const j of jobs){
  const img=decode(path.join(SRC,j.src));
  const cropped=autocrop(img,6,0.02);
  let tw,th;
  if(j.fit==='h'){ th=j.size; tw=Math.round(cropped.w*(j.size/cropped.h)); }
  else { tw=j.size; th=Math.round(cropped.h*(j.size/cropped.w)); }
  const small=cleanTransparent(resize(cropped,tw,th));
  const buf=encode(small.w,small.h,small.px);
  fs.writeFileSync(path.join(OUT,j.out),buf);
  const srcKb=(fs.statSync(path.join(SRC,j.src)).size/1024).toFixed(0);
  console.log(`${j.out.padEnd(14)} ${String(img.w+'x'+img.h).padEnd(10)} -> crop ${String(cropped.w+'x'+cropped.h).padEnd(10)} -> ${String(tw+'x'+th).padEnd(10)} ${srcKb}KB -> ${(buf.length/1024).toFixed(0)}KB   (${j.note})`);
}
