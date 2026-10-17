/* MIT. Puente propio dentro del invitado. No crea un entorno Android. */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#ifndef MIAO_UPLOAD_DIR
#define MIAO_UPLOAD_DIR "/data/local/tmp"
#endif
static const char alphabet[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static uint32_t checksum(uint32_t c,const unsigned char*p,size_t n){while(n--){c^=*p++;for(int i=0;i<8;i++)c=(c>>1)^(0xedb88320u&-(c&1));}return c;}
static size_t encode(const unsigned char*p,size_t n,char*out){size_t j=0;for(size_t i=0;i<n;i+=3){uint32_t v=(uint32_t)p[i]<<16;if(i+1<n)v|=(uint32_t)p[i+1]<<8;if(i+2<n)v|=p[i+2];out[j++]=alphabet[v>>18];out[j++]=alphabet[(v>>12)&63];out[j++]=i+1<n?alphabet[(v>>6)&63]:'=';out[j++]=i+2<n?alphabet[v&63]:'=';}out[j]=0;return j;}
static int digit(char c){const char*p=c?strchr(alphabet,c):NULL;return p?(int)(p-alphabet):-1;}
static int decode(const char*s,unsigned char*out,size_t cap){size_t n=strlen(s),j=0;if(n%4)return-1;for(size_t i=0;i<n;i+=4){int a=digit(s[i]),b=digit(s[i+1]),c=s[i+2]=='='?0:digit(s[i+2]),d=s[i+3]=='='?0:digit(s[i+3]);if(a<0||b<0||c<0||d<0)return-1;int tail=(s[i+3]=='=')+(s[i+2]=='=');if((tail&&i+4!=n)||(s[i+2]=='='&&s[i+3]!='='))return-1;if((tail==2&&(b&15))||(tail==1&&(c&3)))return-1;if(j+3-tail>cap)return-1;uint32_t v=(a<<18)|(b<<12)|(c<<6)|d;out[j++]=v>>16;if(tail<2)out[j++]=v>>8;if(!tail)out[j++]=v;}return(int)j;}
static int serial=1,upload=-1;
static uint64_t expected=0,written=0;
static uint32_t upload_crc=0xffffffffu;
static int install_ready=0;
static void send_all(const char*p,size_t n){while(n){ssize_t r=write(serial,p,n);if(r<0&&errno==EINTR)continue;if(r<=0)return;p+=r;n-=r;}}
static void emit(unsigned id,const char*kind,int code,const unsigned char*data,size_t size){
 uint32_t crc=checksum(0xffffffffu,data,size)^0xffffffffu;char line[4400],base64[4097];
 int n=snprintf(line,sizeof(line),"MIAO1 %u begin %s %d %zu %08x\n",id,kind,code,size,crc);send_all(line,n);
 for(size_t i=0;i<size;i+=3072){size_t take=size-i<3072?size-i:3072;encode(data+i,take,base64);n=snprintf(line,sizeof(line),"MIAO1 %u chunk %zu %s\n",id,i,base64);send_all(line,n);}
 n=snprintf(line,sizeof(line),"MIAO1 %u end\n",id);send_all(line,n);
}
static void text(unsigned id,const char*kind,int code,const char*msg){emit(id,kind,code,(const unsigned char*)msg,strlen(msg));}
static long milliseconds(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec*1000+t.tv_nsec/1000000;}
static void run(unsigned id,char*const argv[]){
 int fds[2];if(pipe(fds)){text(id,"exec",errno,"pipe");return;}pid_t pid=fork();
 if(!pid){setpgid(0,0);close(fds[0]);dup2(fds[1],1);dup2(fds[1],2);close(fds[1]);int fd=open("/dev/null",O_RDONLY);if(fd>=0){dup2(fd,0);close(fd);}execv(argv[0],argv);_exit(127);}
 if(pid>0)setpgid(pid,pid);close(fds[1]);if(pid<0){close(fds[0]);text(id,"exec",errno,"fork");return;}
 unsigned char*output=malloc(2*1024*1024);if(!output){kill(pid,SIGKILL);close(fds[0]);waitpid(pid,NULL,0);text(id,"exec",ENOMEM,"memoria");return;}
 size_t count=0;int failure=0,status=0;long deadline=milliseconds()+180000;
 for(;;){struct pollfd fd={fds[0],POLLIN,0};int r=poll(&fd,1,500);if(r<0&&errno==EINTR)continue;if(milliseconds()>deadline){failure=ETIMEDOUT;break;}if(r<0){failure=errno;break;}if(!r)continue;ssize_t got=read(fds[0],output+count,2*1024*1024-count);if(got<=0)break;count+=got;if(count==2*1024*1024){failure=EFBIG;break;}}
 if(failure){kill(-pid,SIGKILL);kill(pid,SIGKILL);}close(fds[0]);for(;;){pid_t done=waitpid(pid,&status,WNOHANG);if(done==pid)break;if(done<0&&errno!=EINTR){failure=errno;break;}if(milliseconds()>deadline){failure=ETIMEDOUT;kill(-pid,SIGKILL);kill(pid,SIGKILL);waitpid(pid,&status,0);break;}poll(NULL,0,20);}
 int code=failure?failure:(WIFEXITED(status)?WEXITSTATUS(status):128+WTERMSIG(status));emit(id,"exec",code,output,count);free(output);
}
static int package_name(const char*s){size_t n=strlen(s);if(!n||n>200)return 0;for(size_t i=0;i<n;i++)if(!((s[i]>='a'&&s[i]<='z')||(s[i]>='A'&&s[i]<='Z')||(s[i]>='0'&&s[i]<='9')||s[i]=='_'||s[i]=='.'))return 0;return strchr(s,'.')!=NULL;}
static void command(char*line){
 unsigned id;char verb[32];int used=0;if(sscanf(line,"MIAO1 %u %31s %n",&id,verb,&used)!=2||!used)return;char*arg=line+used;arg[strcspn(arg,"\r\n")]=0;
 if(!strcmp(verb,"ping")){text(id,"ping",0,"puente invitado; Android debe verificarse por getprop");return;}
 if(!strcmp(verb,"info")){char*a[]={"/system/bin/getprop",NULL};run(id,a);return;}
 if(!strcmp(verb,"screen")){char*a[]={"/system/bin/screencap","-p",NULL};run(id,a);return;}
 if(!strcmp(verb,"key")){unsigned key;char extra;if(sscanf(arg,"%u%c",&key,&extra)!=1||key>288){text(id,"error",EINVAL,"tecla");return;}char k[16];snprintf(k,sizeof(k),"%u",key);char*a[]={"/system/bin/input","keyevent",k,NULL};run(id,a);return;}
 if(!strcmp(verb,"tap")){unsigned x,y;char extra;if(sscanf(arg,"%u %u%c",&x,&y,&extra)!=2||x>8192||y>8192){text(id,"error",EINVAL,"coordenadas");return;}char xs[16],ys[16];snprintf(xs,sizeof(xs),"%u",x);snprintf(ys,sizeof(ys),"%u",y);char*a[]={"/system/bin/input","tap",xs,ys,NULL};run(id,a);return;}
 if(!strcmp(verb,"launch")||!strcmp(verb,"path")){if(!package_name(arg)){text(id,"error",EINVAL,"paquete");return;}char*launch[]={"/system/bin/monkey","-p",arg,"-c","android.intent.category.LAUNCHER","1",NULL};char*path[]={"/system/bin/pm","path",arg,NULL};run(id,!strcmp(verb,"launch")?launch:path);return;}
 if(!strcmp(verb,"apk-begin")){install_ready=0;char*end;errno=0;unsigned long long size=strtoull(arg,&end,10);struct statvfs fs;if(errno||*end||!size||size>1073741824ULL||statvfs(MIAO_UPLOAD_DIR,&fs)||(uint64_t)fs.f_bavail*fs.f_frsize<size+67108864ULL){text(id,"error",ENOSPC,"tamaño o espacio insuficiente");return;}if(upload>=0)close(upload);upload=open(MIAO_UPLOAD_DIR "/miao-upload.apk",O_CREAT|O_TRUNC|O_WRONLY|O_NOFOLLOW|O_CLOEXEC,0600);if(upload<0){text(id,"error",errno,"archivo APK");return;}expected=size;written=0;upload_crc=0xffffffffu;text(id,"upload",0,"0");return;}
 if(!strcmp(verb,"apk-chunk")){unsigned long long offset;int skip=0;unsigned char bytes[6144];if(upload<0||sscanf(arg,"%llu %n",&offset,&skip)!=1||!skip||offset!=written){text(id,"error",EINVAL,"orden de fragmentos");return;}int n=decode(arg+skip,bytes,sizeof(bytes));if(n<1||written+(uint64_t)n>expected){text(id,"error",EINVAL,"fragmento");return;}size_t done=0;while(done<(size_t)n){ssize_t r=write(upload,bytes+done,n-done);if(r<0&&errno==EINTR)continue;if(r<=0){close(upload);upload=-1;expected=0;written=0;install_ready=0;text(id,"error",EIO,"escritura");return;}done+=r;}upload_crc=checksum(upload_crc,bytes,n);written+=n;char ack[32];snprintf(ack,sizeof(ack),"%llu",(unsigned long long)written);text(id,"upload",0,ack);return;}
 if(!strcmp(verb,"apk-finish")){char*end;errno=0;unsigned long crc=strtoul(arg,&end,16);if(upload<0||errno||end==arg||*end||crc>0xffffffffUL||written!=expected||crc!=(upload_crc^0xffffffffu)){text(id,"error",EINVAL,"APK incompleto o suma distinta");return;}if(fsync(upload)){text(id,"error",errno,"sincronización");return;}close(upload);upload=-1;install_ready=1;text(id,"upload",0,"APK recibido; todavía no instalado");return;}
 if(!strcmp(verb,"install")){if(!install_ready||upload>=0||!expected||written!=expected){text(id,"error",EINVAL,"transferencia sin confirmar");return;}char*a[]={"/system/bin/pm","install","-r",MIAO_UPLOAD_DIR "/miao-upload.apk",NULL};run(id,a);return;}
 text(id,"error",EINVAL,"comando desconocido");
}
static int selftest(void){unsigned char b[8];char s[16];if((checksum(0xffffffffu,(const unsigned char*)"123456789",9)^0xffffffffu)!=0xcbf43926u)return 1;if(decode("AAEC/w==",b,sizeof(b))!=4||b[0]!=0||b[1]!=1||b[2]!=2||b[3]!=255)return 2;if(encode(b,4,s)!=8||strcmp(s,"AAEC/w=="))return 3;if(decode("AB==",b,sizeof(b))>=0||decode("AA=A",b,sizeof(b))>=0||decode("!!!!",b,sizeof(b))>=0)return 4;if(!package_name("cl.miao.probe")||package_name("x;id")||package_name("no_dot"))return 5;puts("MIAO_BRIDGE_SELF_TEST_OK");return 0;}
int main(int argc,char**argv){if(argc==2&&!strcmp(argv[1],"--self-test"))return selftest();if(argc!=2)return 2;int inputfd;if(!strcmp(argv[1],"--stdio")){serial=STDOUT_FILENO;inputfd=STDIN_FILENO;}else{serial=open(argv[1],O_RDWR|O_NOCTTY|O_CLOEXEC);if(serial<0)return 3;inputfd=serial;}struct termios t;if(tcgetattr(serial,&t)==0){cfmakeraw(&t);tcsetattr(serial,TCSANOW,&t);}char line[8500];size_t n=0;int dropping=0;for(;;){char c;ssize_t r=read(inputfd,&c,1);if(r<0&&errno==EINTR)continue;if(r<=0)break;if(c=='\n'){if(!dropping){line[n]=0;command(line);}n=0;dropping=0;}else if(!dropping){if(n+1<sizeof(line))line[n++]=c;else{n=0;dropping=1;}}}if(upload>=0)close(upload);close(serial);return 0;}

