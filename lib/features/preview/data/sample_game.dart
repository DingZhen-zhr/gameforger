const String sampleGameHtml = r'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0A0E17;display:flex;justify-content:center;align-items:center;height:100dvh;overflow:hidden;touch-action:none;-webkit-user-select:none;user-select:none}
canvas{display:block;border-radius:12px}
</style>
</head>
<body>
<canvas id="g"></canvas>
<script>
const c=document.getElementById('g'),ctx=c.getContext('2d');
function r(){c.width=Math.min(innerWidth,420);c.height=Math.min(innerHeight,640)}
r();onresize=r;
let S=0,go=0,f=0;
const p={x:50,y:0,w:28,h:28,vy:0,vx:0,g:0};
const pl=[],it=[];
function init(){
  p.y=c.height-100;p.vy=0;p.vx=0;p.g=0;
  pl.length=0;it.length=0;S=0;go=0;
  pl.push({x:0,y:c.height-28,w:c.width,h:28});
  for(let i=0;i<6;i++)pl.push({x:40+Math.random()*(c.width-100),y:80+Math.random()*(c.height-160),w:55+Math.random()*35,h:10,mt:Math.random()*50});
  for(let i=0;i<4;i++)it.push({x:60+Math.random()*(c.width-120),y:100+Math.random()*(c.height-200),r:7,g:0});
}
init();
let L=0,R=0;
onkeydown=e=>{if(e.key=='ArrowLeft')L=1;if(e.key=='ArrowRight')R=1;if((e.key==' '||e.key=='ArrowUp')&&p.g){p.vy=-11;p.g=0}if(go)init()};
onkeyup=e=>{if(e.key=='ArrowLeft')L=0;if(e.key=='ArrowRight')R=0};
c.ontouchstart=e=>{e.preventDefault();let t=e.touches[0],r=c.getBoundingClientRect(),x=t.clientX-r.left;if(x<c.width/2)L=1;else R=1;if(p.g){p.vy=-11;p.g=0}if(go)init()};
c.ontouchend=e=>{e.preventDefault();L=0;R=0};
c.onclick=()=>{if(p.g){p.vy=-11;p.g=0}if(go)init()};
function upd(){
  if(go)return;
  p.vx=0;if(L)p.vx=-4.5;if(R)p.vx=4.5;
  p.vy+=0.48;p.x+=p.vx;p.y+=p.vy;p.g=0;
  for(let i of pl){
    if(p.vy>0&&p.x+p.w>i.x&&p.x<i.x+i.w&&p.y+p.h>i.y&&p.y+p.h<i.y+i.h+8){
      p.y=i.y-p.h;p.vy=0;p.g=1;
    }
  }
  for(let i of it){
    if(!i.g&&Math.abs(p.x+p.w/2-i.x)<i.r+p.w/2&&Math.abs(p.y+p.h/2-i.y)<i.r+p.h/2){i.g=1;S++}
  }
  if(p.x<0)p.x=0;if(p.x+p.w>c.width)p.x=c.width-p.w;
  if(p.y>c.height+50)go=1;
  if(S>=it.length)go=2;
}
function draw(){
  ctx.clearRect(0,0,c.width,c.height);
  ctx.fillStyle='#0A0E17';ctx.fillRect(0,0,c.width,c.height);
  ctx.fillStyle='#fff';
  for(let i=0;i<40;i++){
    let sx=(i*137+i*i*13)%c.width,sy=(i*89+i*i*7)%c.height,br=0.25+((i*73)%7)/10;
    ctx.globalAlpha=br;ctx.fillRect(sx,sy,1.5,1.5);
  }
  ctx.globalAlpha=1;
  for(let i of pl){
    let gr=ctx.createLinearGradient(i.x,i.y,i.x,i.y+i.h);
    gr.addColorStop(0,'#7C5CFC');gr.addColorStop(1,'#4A2FB5');
    ctx.fillStyle=gr;ctx.shadowBlur=10;ctx.shadowColor='#7C5CFC44';
    let by=i.y+(i.mt||0)&&Math.sin(f*0.02+(i.mt||0))*2;
    ctx.beginPath();ctx.roundRect(i.x,by||i.y,i.w,i.h,4);ctx.fill();
    ctx.shadowBlur=0;
  }
  for(let i of it){
    if(i.g)continue;
    ctx.beginPath();ctx.arc(i.x,i.y+Math.sin(f*0.05)*4,i.r,0,Math.PI*2);
    ctx.fillStyle='#FFD700';ctx.shadowBlur=15;ctx.shadowColor='#FFD70066';ctx.fill();
    ctx.shadowBlur=0;
    ctx.fillStyle='#FFD70044';
    ctx.beginPath();ctx.arc(i.x,i.y+Math.sin(f*0.05)*4,i.r+5,0,Math.PI*2);ctx.fill();
  }
  ctx.shadowBlur=18;ctx.shadowColor='#00E5FF44';
  ctx.fillStyle='#00E5FF';ctx.beginPath();ctx.roundRect(p.x,p.y,p.w,p.h,6);ctx.fill();
  ctx.shadowBlur=0;
  ctx.fillStyle='#0A0E17';ctx.fillRect(p.x+7,p.y+7,4,4);ctx.fillRect(p.x+17,p.y+7,4,4);
  ctx.fillStyle='#E8EAED';
  ctx.font='bold 16px -apple-system,sans-serif';ctx.textAlign='left';
  ctx.fillText('⭐ '+S+'/'+it.length,12,30);
  if(go){
    ctx.fillStyle='rgba(0,0,0,0.6)';ctx.fillRect(0,0,c.width,c.height);
    ctx.fillStyle='#E8EAED';ctx.textAlign='center';
    ctx.font='bold 26px -apple-system,sans-serif';
    if(go==2)ctx.fillText('🎉 你赢了!',c.width/2,c.height/2-12);
    else ctx.fillText('💀 游戏结束',c.width/2,c.height/2-12);
    ctx.font='15px -apple-system,sans-serif';
    ctx.fillText('点击重新开始',c.width/2,c.height/2+22);
    ctx.textAlign='left';
  }
  f++;
}
setInterval(()=>{upd();draw()},1000/60);
</script>
</body>
</html>''';
