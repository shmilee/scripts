#!/usr/bin/perl

##当且仅当第一个参数为正数，脚本成功，默认为0

$picpath='/usr/share/random-desktop/png/';     #图片目录
$bgpath='/usr/share/random-desktop/';     #壁纸目录

chdir $bgpath;
my @bgs = glob "bg*";
$background=$bgpath.$bgs[int rand(@bgs)];     # 随机壁纸
print "$background\n";

chdir $picpath;
$num=int $ARGV[0]+rand(3);     ##随机取得 $ARGV[0] +2张 png格式，第一个参数，设定最少几张图片
print "$num\n";
my @files = glob "*.png";
unlink glob "/tmp/d-*.png";

for(1..$num){
$in=$files[int rand(@files)];
$out="/tmp/d-$in.png";
if(grep /$in/,@do){redo;}       # 确保不重复使用文件
push @do,$in;

my $size=int 120+rand(80);      # 缩放120-200之间
`convert \"$in\" -scale \"$size>\" \"$out\"`;

my $mess=int rand(3);           # 不同效果处理 ,效果4右侧偶尔有阴影，不采用,效果3,灰色，与人物肖像不搭
if($mess == 0){
print "mess\t-> $in\n";
`convert \"$out\" \\( +clone -threshold -1 -virtual-pixel black -spread 30 -blur 0x3 -threshold 40% -spread 2 -blur 10x.7 \\) -compose Copy_Opacity -composite \"$out\"`;
}
if($mess == 1) {
print "frame\t-> $in\n";
`convert \"$out\" -bordercolor "#C2C2C2" -border 5 -bordercolor "#323232" -border 1 \"$out\"`;
}
if($mass == 2) {
print "raise\t-> $in\n";
`convert  \"$out\" +raise 5x5 -swirl 60 \"$out\"`;
}
if($mess == 3) {
print "edge\t-> $in\n";
`convert \"$out\" -colorspace Gray  -edge 1 -negate -scale 120 \"$out\"`;
}
if($mess == 4) {
print "distort\t-> $in\n";
`convert \"$out\" -matte -virtual-pixel transparent -distort Perspective '0,0,0,0  0,90,0,90  90,0,90,25  90,90,90,65' \"$out\"`;
}
#更多效果请登录http://www.imagemagick.org/Usage/mapping/

`convert \"$out\" -background  black \\( +clone -shadow 60x4+4+4 \\) +swap -background none -flatten \"$out\"`;      # 阴影

my $rot=int rand(90)-45;     # 旋转选择正负45度
`convert \"$out\" -background none -rotate $rot \"$out\"`;
}

chdir '/tmp/';
my @files = glob "d-*.png";
my $cmd="habak -ms $background";
#my $cmd="habak -ms $background -mp 550,800 weather.png";
foreach(@files){
my $x=int rand(1000);
my $y=int rand(720);
$cmd=$cmd." -mp $x,$y $_";
}
print "$cmd\n";
`$cmd`;
