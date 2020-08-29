# JITアセンブラXbyakを使ってみる（その３）



Docker でarchlinuxのインストール

とりあえずarchlinuxのlatestをpullしておく。

```sh
docker pull archlinux
```

pacman -S --noconfirm aarch64-linux-gnu-gcc 
pacman -S git --noconfirm
pacman -S vim --noconfirm
pacman -S qemu --noconfirm
pacman -S qemu-arch-extra --noconfirm

[root@9d84625bc733 ~]# aarch64-linux-gnu-g++ --version
aarch64-linux-gnu-g++ (GCC) 10.2.0
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

GCCは10.2からよりAArch64 intrinsicsにフル対応しているようなのだが、Arch Linuxにはaarch64-linux-gnu-gcc 10.1.0-1のパッケージがあり、使いたい組み込み関数が問題なく使えた。

alias ag++="aarch64-linux-gnu-g++ -march=armv8-a+sve -static -O3"

# 確認

AArch64でSVEが使えるか確認してみよう。まずはSVEの組み込み関数を使ってみる。

```cpp
#include <cstdio>
#include <arm_sve.h>

int main(){
  printf("%d\n",svcntd());
}
```

`svcntd`命令は、実行中の石でのSIMD長を教えてくれるものだ。SVE命令は頭に`sv`が付く。`cnt`はおそらくcountで、最後の`d`は`double`だと思う。要するにレジスタに入る`double`の数を教えてくれる。

