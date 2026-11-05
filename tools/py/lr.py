"""Minimal headless libretro frontend (ctypes) for bsnes-mercury. Screenshots, memory, savestates, scripted input."""
import ctypes as C, os
from PIL import Image
_HERE=os.path.dirname(os.path.abspath(__file__))
_LOCAL=os.path.normpath(os.path.join(_HERE,'..','libretro','bsnes_mercury_accuracy_libretro.so'))
_SYS='/usr/lib/x86_64-linux-gnu/libretro/bsnes_mercury_accuracy_libretro.so'
CORE=_LOCAL if os.path.isfile(_LOCAL) else _SYS
class GameInfo(C.Structure): _fields_=[('path',C.c_char_p),('data',C.c_void_p),('size',C.c_size_t),('meta',C.c_char_p)]
ENV=C.CFUNCTYPE(C.c_bool,C.c_uint,C.c_void_p)
VID=C.CFUNCTYPE(None,C.c_void_p,C.c_uint,C.c_uint,C.c_size_t)
AUD=C.CFUNCTYPE(None,C.c_int16,C.c_int16)
AUDB=C.CFUNCTYPE(C.c_size_t,C.c_void_p,C.c_size_t)
POLL=C.CFUNCTYPE(None)
STATE=C.CFUNCTYPE(C.c_int16,C.c_uint,C.c_uint,C.c_uint,C.c_uint)
BTN={'B':0,'Y':1,'SELECT':2,'START':3,'UP':4,'DOWN':5,'LEFT':6,'RIGHT':7,'A':8,'X':9,'L':10,'R':11}
class Emu:
    def __init__(self,rom,core=CORE):
        self.L=C.CDLL(core); self.fmt=0; self.frame=None; self.pad=[set(),set()]
        self.sysdir=C.c_char_p(os.path.join(_HERE,'..','..','work','sys').encode()); os.makedirs(self.sysdir.value,exist_ok=True)
        def env(cmd,data):
            cmd&=0xFFFF
            if cmd==10: self.fmt=C.cast(data,C.POINTER(C.c_int))[0]; return True
            if cmd in(9,31): C.cast(data,C.POINTER(C.c_char_p))[0]=self.sysdir.value; return True
            if cmd==3: C.cast(data,C.POINTER(C.c_bool))[0]=True; return True
            return False
        def vid(d,w,h,p):
            if d: self.frame=(C.string_at(d,p*h),w,h,p)
        self._cb=[ENV(env),VID(vid),AUD(lambda l,r:None),AUDB(lambda d,n:n),POLL(lambda:None),
                  STATE(lambda port,dev,idx,id_: 1 if port<2 and dev==1 and id_ in self.pad[port] else 0)]
        L=self.L
        L.retro_set_environment(self._cb[0]); L.retro_init()
        L.retro_set_video_refresh(self._cb[1]); L.retro_set_audio_sample(self._cb[2]); L.retro_set_audio_sample_batch(self._cb[3])
        L.retro_set_input_poll(self._cb[4]); L.retro_set_input_state(self._cb[5])
        self.data=open(rom,'rb').read(); self.buf=C.create_string_buffer(self.data,len(self.data))
        gi=GameInfo(rom.encode(),C.cast(self.buf,C.c_void_p),len(self.data),None)
        assert L.retro_load_game(C.byref(gi)),'load failed'
        L.retro_get_memory_data.restype=C.c_void_p; L.retro_get_memory_size.restype=C.c_size_t
        L.retro_serialize_size.restype=C.c_size_t
    def run(self,n=1,hold=(),port=0):
        self.pad[port]=set(BTN[b] for b in hold)
        for _ in range(n): self.L.retro_run()
        self.pad[port]=set()
    def press(self,b,frames=4,after=20):
        self.run(frames,[b] if isinstance(b,str) else b); self.run(after)
    def mem(self,id_=2):  # 0 SRAM,2 WRAM,3 VRAM
        p=self.L.retro_get_memory_data(id_); n=self.L.retro_get_memory_size(id_)
        return C.string_at(p,n) if p else b''
    def shot(self,path):
        d,w,h,p=self.frame
        bpp=4 if p>=w*4 else 2
        if bpp==4: im=Image.frombuffer('RGBX',(w,h),d,'raw','BGRX',p,1)
        elif self.fmt==2: im=Image.frombuffer('RGB',(w,h),d,'raw','BGR;16',p,1)
        else: im=Image.frombuffer('RGB',(w,h),d,'raw','BGR;15',p,1)
        im.convert('RGB').save(path); return path
    def save(self):
        n=self.L.retro_serialize_size(); b=C.create_string_buffer(n); assert self.L.retro_serialize(b,n); return b.raw
    def load(self,s):
        b=C.create_string_buffer(s,len(s)); assert self.L.retro_unserialize(b,len(s))

def _poke(self,addr,data,id_=2):
    p=self.L.retro_get_memory_data(id_); C.memmove(p+addr,bytes(data),len(data))
Emu.poke=_poke

def _shot2(self,path):
    """interlace-aware screenshot: weave two consecutive fields into 512x448 (game text uses interlace mode).
    Field order picked by vertical smoothness. Falls back to line-doubling if both fields are identical."""
    import numpy as np
    self.shot('/tmp/_f0.png'); a=np.array(Image.open('/tmp/_f0.png')).astype(int)
    self.run(1); self.shot('/tmp/_f1.png'); b=np.array(Image.open('/tmp/_f1.png')).astype(int)
    def weave(x,y):
        o=np.zeros((x.shape[0]*2,)+x.shape[1:],int); o[0::2]=x; o[1::2]=y; return o
    c1=weave(a,b); c2=weave(b,a)
    s1=np.abs(np.diff(c1,axis=0)).sum(); s2=np.abs(np.diff(c2,axis=0)).sum()
    Image.fromarray((c1 if s1<=s2 else c2).astype(np.uint8)).save(path); return path
Emu.shot2=_shot2
