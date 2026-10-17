/* MIT. Diagnóstico propio, sin libc. NO es Android ni ejecuta APK. */
typedef unsigned long usize;
void* memset(void*d,int c,usize n){volatile unsigned char*p=d;for(usize i=0;i<n;i++)p[i]=(unsigned char)c;return d;}
void* memcpy(void*d,const void*s,usize n){volatile unsigned char*p=d;const volatile unsigned char*q=s;for(usize i=0;i<n;i++)p[i]=q[i];return d;}
static long call(long n,long a,long b,long c,long d,long e,long f) {
 register long x0 __asm__("x0")=a,x1 __asm__("x1")=b,x2 __asm__("x2")=c;
 register long x3 __asm__("x3")=d,x4 __asm__("x4")=e,x5 __asm__("x5")=f;
 register long x8 __asm__("x8")=n;
 __asm__ volatile("svc 0":"+r"(x0):"r"(x1),"r"(x2),"r"(x3),"r"(x4),"r"(x5),"r"(x8):"memory","cc");
 return x0;
}
static usize length(const char*s){usize n=0;while(s[n])n++;return n;}
static void out(const char*s){call(64,1,(long)s,length(s),0,0,0);}
static void number(long n){char s[32];int i=31;s[i]=0;unsigned long u=n<0?-n:n;do{s[--i]='0'+u%10;u/=10;}while(u);if(n<0)s[--i]='-';out(s+i);}
static void line(const char*k,long v){out(k);number(v);out("\n");}
static long openfile(const char*p,long flags){return call(56,-100,(long)p,flags,0,0,0);}
static void show(const char*p){char b[1024];long fd=openfile(p,0);if(fd<0){line("MIAO_ARM|OPEN_ERROR|",fd);return;}long n=call(63,fd,(long)b,sizeof(b)-1,0,0,0);if(n>0){b[n]=0;out(b);}call(57,fd,0,0,0,0,0);}
static void directory(const char*p){call(34,-100,(long)p,0755,0,0,0);}
static long mountfs(const char*type,const char*dst){return call(40,(long)type,(long)dst,(long)type,0,0,0);}
static int contains(const char*s,const char*q){for(;*s;s++){usize i=0;while(q[i]&&q[i]==s[i])i++;if(!q[i])return 1;}return 0;}
static void poweroff(void){call(142,0xfee1dead,672274793,0x4321fedc,0,0,0);}
static void binder(void){
 directory("/dev/binderfs");line("MIAO_ARM|BINDERFS_MOUNT|",mountfs("binder","/dev/binderfs"));
 long ctl=openfile("/dev/binderfs/binder-control",2);
 const char* names[]={"binder","hwbinder","vndbinder"};
 const char* paths[]={"/dev/binder","/dev/hwbinder","/dev/vndbinder"};
 const char* targets[]={"/dev/binderfs/binder","/dev/binderfs/hwbinder","/dev/binderfs/vndbinder"};
 for(int i=0;i<3;i++){
  if(ctl>=0){struct {char name[256];unsigned int major,minor;}dev={0};for(int j=0;names[i][j];j++)dev.name[j]=names[i][j];line("MIAO_ARM|BINDER_CREATE|",call(29,ctl,0xc1086201,(long)&dev,0,0,0));call(36,(long)targets[i],-100,(long)paths[i],0,0,0);}
  long fd=openfile(paths[i],2);
  out("MIAO_ARM|BINDER_OPEN|");out(paths[i]);out("|");number(fd);out("\n");
  if(fd>=0){int version=0;long r=call(29,fd,0xc0046209,(long)&version,0,0,0);line("MIAO_ARM|BINDER_VERSION_RESULT|",r);line("MIAO_ARM|BINDER_PROTOCOL|",version);call(57,fd,0,0,0,0,0);}
 }
 if(ctl>=0)call(57,ctl,0,0,0,0,0);
}
static void compat(void){
 long pid=call(220,17,0,0,0,0,0);
 if(pid==0){const char *args[]={"/bin/arm32-probe",0};const char*env[]={0};long r=call(221,(long)args[0],(long)args,(long)env,0,0,0);line("MIAO_ARM|ARM32_EXEC_ERROR|",r);call(93,127,0,0,0,0,0);}
 if(pid>0){int status=0;long r=call(260,pid,(long)&status,0,0,0,0);line("MIAO_ARM|ARM32_WAIT|",r);line("MIAO_ARM|ARM32_STATUS|",status);}
 else line("MIAO_ARM|CLONE_ERROR|",pid);
}
static void netaddr(long fd,long request,unsigned char a,unsigned char b,unsigned char c,unsigned char d){unsigned char req[40]={0};const char*n="eth0";for(int i=0;n[i];i++)req[i]=n[i];req[16]=2;req[20]=a;req[21]=b;req[22]=c;req[23]=d;line("MIAO_ANDROID|NET_IOCTL|",call(29,fd,request,(long)req,0,0,0));}
static void bootAndroid(void){
 directory("/android-root");
 long rc=call(40,(long)"/dev/vda",(long)"/android-root",(long)"ext4",0,0,0);line("MIAO_ANDROID|ROOT_MOUNT|",rc);if(rc<0)return;
 // Android necesita el nombre de dispositivo usado por APEX, además del nombre de devtmpfs.
 line("MIAO_ANDROID|DEVICE_MAPPER_ALIAS|",call(36,(long)"/dev/mapper/control",-100,(long)"/dev/device-mapper",0,0,0));
 line("MIAO_ANDROID|HW_RANDOM_ALIAS|",call(36,(long)"/dev/hwrng",-100,(long)"/dev/hw_random",0,0,0));
 const char* binder_paths[]={"/dev/binder","/dev/hwbinder","/dev/vndbinder"};
 for(int i=0;i<3;i++)line("MIAO_ANDROID|BINDER_PERMISSIONS|",call(53,-100,(long)binder_paths[i],0666,0,0,0));
 line("MIAO_ANDROID|DMA_HEAP_OWNER|",call(54,-100,(long)"/dev/dma_heap/system",1000,1003,0,0));
 line("MIAO_ANDROID|DMA_HEAP_MODE|",call(53,-100,(long)"/dev/dma_heap/system",0660,0,0,0));

 directory("/android-root/proc");directory("/android-root/sys");directory("/android-root/dev");directory("/android-root/data");directory("/android-root/cache");
 line("MIAO_ANDROID|BOOTSTRAP_APEX_DIRECTORY|",call(34,-100,(long)"/android-root/bootstrap-apex",0755,0,0,0));
 long fd=call(198,2,2,0,0,0,0);if(fd>=0){netaddr(fd,0x8916,10,0,2,15);netaddr(fd,0x891c,255,255,255,0);unsigned char req[40]={0};const char*n="eth0";for(int i=0;n[i];i++)req[i]=n[i];req[16]=0x43;line("MIAO_ANDROID|NET_UP|",call(29,fd,0x8914,(long)req,0,0,0));call(57,fd,0,0,0,0,0);}
 line("MIAO_ANDROID|MOVE_PROC|",call(40,(long)"/proc",(long)"/android-root/proc",0,8192,0,0));
 line("MIAO_ANDROID|MOVE_SYS|",call(40,(long)"/sys",(long)"/android-root/sys",0,8192,0,0));
 line("MIAO_ANDROID|MOVE_DEV|",call(40,(long)"/dev",(long)"/android-root/dev",0,8192,0,0));
 // switch_root real: el nuevo sistema debe ser la raíz del namespace, no sólo un chroot bajo el initramfs.
 line("MIAO_ANDROID|CHDIR_NEW_ROOT|",call(49,(long)"/android-root",0,0,0,0,0));
 long moved=call(40,(long)".",(long)"/",0,8192,0,0);line("MIAO_ANDROID|SWITCH_ROOT_MOVE|",moved);if(moved<0)return;
 line("MIAO_ANDROID|CHROOT|",call(51,(long)".",0,0,0,0,0));call(49,(long)"/",0,0,0,0,0);
 const char *args[]={"/init","qemu=1","androidboot.hardware=redroid","androidboot.use_memfd=true","androidboot.redroid_gpu_mode=guest","androidboot.redroid_width=800","androidboot.redroid_height=600","androidboot.redroid_dpi=160","androidboot.redroid_fps=10","ro.setupwizard.mode=DISABLED",0};
 const char *env[]={"PATH=/system/bin:/vendor/bin","ANDROID_ROOT=/system","ANDROID_DATA=/data",0};
 out("MIAO_ANDROID|EXEC_INIT_ATTEMPT\n");line("MIAO_ANDROID|EXEC_INIT_ERROR|",call(221,(long)"/init",(long)args,(long)env,0,0,0));
}
__attribute__((noreturn)) void _start(void){
 directory("/proc");directory("/sys");directory("/dev");
 mountfs("proc","/proc");mountfs("sysfs","/sys");mountfs("devtmpfs","/dev");
 long fd=openfile("/dev/console",2);if(fd>=0)for(int i=0;i<3;i++)call(24,fd,i,0,0,0,0);
 out("MIAO_ARM|INIT64_STARTED\n");char uts[390];if(call(160,(long)uts,0,0,0,0,0)==0){out("MIAO_ARM|KERNEL|");out(uts+130);out("\nMIAO_ARM|MACHINE|");out(uts+260);out("\n");}
 show("/proc/meminfo");binder();compat();
 out("MIAO_ARM|CONTROL_COMPLETE|ANDROID_NOT_BOOTED\n");
 char cmd[1024];long cfd=openfile("/proc/cmdline",0);if(cfd>=0){long n=call(63,cfd,(long)cmd,sizeof(cmd)-1,0,0,0);if(n>0){cmd[n]=0;if(contains(cmd,"miao.android=1"))bootAndroid();if(contains(cmd,"miao.autopoweroff=1"))poweroff();}call(57,cfd,0,0,0,0,0);}
 const long delay[2]={60,0};for(;;)call(101,(long)delay,0,0,0,0,0);
}
