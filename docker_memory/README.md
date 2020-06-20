
# Dockerファイルがビルドできなかったのでコンパイラをいじめる

# TL;DR

* ある環境でビルドできたDockerfileが別の環境でビルドできなかったのは、メモリ制限のせいだった

# はじめに

理研シミュレータというシミュレータがあります。

[RIKEN-RCCS/riken_simulator](https://github.com/RIKEN-RCCS/riken_simulator)

これは、「京」の次のスーパーコンピュータ「富岳」が採用しているアーキテクチャ「Fujitsu A64FX」のシミュレータです。Gem5というアーキテクチャシミュレータがあり、それにARM AArch64を実装したものです。

これを使うと、AArch64のプロセッサレベルでのシミュレートができるのですが、ビルドに結構手間がかかります。なので、その「手間」をまとめたDockerファイルを作りました。

[kaityo256/aarch64env](https://github.com/kaityo256/aarch64env)

Dockerファイルはこんな感じです。

```Dockerfile
FROM ubuntu:18.04
MAINTAINER kaityo256

ENV USER user
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN useradd -m ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo 'user:userpass' | chpasswd

RUN apt-get update && apt-get install -y \
    g++ \
    g++-8-aarch64-linux-gnu \
    git \
    m4 \
    python-dev \
    scons \
    sudo \
    vim \
    qemu-user-binfmt \
    zlib1g-dev

USER ${USER}

RUN cd ${HOME} \
 && mkdir build \
 && cd build \
 && git clone --depth 1 https://github.com/RIKEN-RCCS/riken_simulator.git

RUN cd ${HOME} \
 && cd build/riken_simulator \
 && sed -i "369,372s:^:#:" SConstruct \
 && scons build/ARM/gem5.opt -j 20

RUN cd ${HOME} \
 && git clone https://github.com/kaityo256/aarch64env.git

RUN cd ${HOME} \
 && echo alias gem5=\'~/build/riken_simulator/build/ARM/gem5.opt ~/build/riken_simulator/configs/example/se.py -c\' >> .bashrc \
 && echo alias ag++=\'aarch64-linux-gnu-g++-8 -static -march=armv8-a+sve\' >> .bashrc
```

たいしたことはしていません。ビルドで僕が詰まったところをちょこちょこ修正してからビルドしているだけです。Riken Simulatorはビルドにえらい時間がかかるのですが、手元に20コアのLinuxマシンがあったので、sconsに`-j 20`を指定して20並列でビルドしています。

さて、このDockerファイルがビルドできない、という連絡が来ました。Dockerって後ろがMacだろうがWindowsだろうかLinuxだろうが同じ環境を作ってくれるものなのに、環境依存性があるとは何事ぞ？と思って調査を始めました。こういう調査ログは、たまに誰かの役に立つこともあるので残しておきます。

## 並列ビルドとキャッシュ

まず疑うのはキャッシュです。Dockerはビルドする時にキャッシュするため、作業の手順によってはおかしなことがおきることがあります。まずは、ローカルで作業した人に`--no-cache`の指定をお願いしましたが、やはりこけたという連絡が来ます。

次に疑ったのは自分のビルドです。キャッシュのせいでビルドできたけれど、実はクリーンビルドしたらこけるのではないかと思い、Linuxマシンで`--no-cache`を指定してビルドしなおします。普通にビルドできます。

`-j 20`を`-j 4`に減らしてもらってもこける、という報告がきます。また、並列ビルドをやめたら、こけなくはなったがビルドが途中で止まる、という連絡が来ました。

## ローカルでのチェック

とりあえず、自分でもローカルマシンで試すことにしました。まずは`-j 20`のままビルドします。こけます。

![j20.png](j20.png)

internal compiler errorさんお久しぶりです。[整数を419378回インクリメント](https://qiita.com/kaityo256/items/6b5715b213e955d44f55)した時以来ですね。internal compiler error、略してICEですが、普通に生きていればあまり見かけないと思います。・・・というようなことをあるところで口走ったら、「え？ICEなんて日常的に見ますよね？」みたいな反応があったのでC++ガチ勢は怖いなと思いました。閑話休題。

とりあえず4コアしかないマシンで20並列するのもアレなんで、`-j 4`でやり直してみます。

![j4.png](j4.png)

やっぱりこけますね。

さて、ビルドに失敗する理由がICEである、ということから、メモリ不足を疑います。

まず、LinuxサーバでDockerfileをビルド中に`docker stats`で利用メモリを確認します。

![memory.png](memory.png)

おおぅ、2.9GB使ってますね。

次に、ローカルのDockerのメモリ制限を見てみましょう。

![docker-memory](docker_memory.png)

Memoryが2.00GB。これですね。

メモリが潤沢にあるLinuxマシンで、2GBのメモリ制限をかけてビルドしなおしてみましょう。

```sh
docker build -t kaityo256/aarch64env:memtest -m 2gb . --no-cache 
```

![linux failed](linux_failed.png)

はい、こけましたね。メモリ不足が原因と確定です。ローカルマシンでビルドに失敗した人には、DockerのSettingsのResourcesでメモリ上限を増やして再度試すようお願いし、ちゃんとビルドできることが確認できてめでたしでした。

## どこでこけたか？

さて、Dockerファイルがビルドできない問題はこれで解決としても、「なんでこんなにメモリを消費したのか」は気になります。20並列はともかく、4並列でもこけて、シリアルビルドだとこけないけどビルドが止まってしまう、ということは、一つのファイルをコンパイルするのに2GB以上を使うファイルがあるはずです。それを調べてみましょう。

まずは、ビルド直前のイメージを作ります。

```Dockerfile
FROM ubuntu:18.04
MAINTAINER kaityo256

ENV USER user
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN useradd -m ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo 'user:userpass' | chpasswd

RUN apt-get update && apt-get install -y \
    g++ \
    g++-8-aarch64-linux-gnu \
    git \
    m4 \
    python-dev \
    scons \
    sudo \
    vim \
    qemu-user-binfmt \
    zlib1g-dev

USER ${USER}

RUN cd ${HOME} \
 && mkdir build \
 && cd build \
 && git clone --depth 1 https://github.com/RIKEN-RCCS/riken_simulator.git

RUN cd ${HOME} \
 && cd build/riken_simulator \
 && sed -i "369,372s:^:#:" SConstruct
```

このイメージをビルドします。

```sh
docker build -t kaityo256/aarch64before .
```

そして、2GBの制限をかけた上でコンテナを起動し、アタッチします。

```sh
docker run -it -u user -m 2gb kaityo256/aarch64before
```

`user`は、作業用に作ったユーザアカウントです。さて、とりあえず並列ビルドしてこけることを確認します。

```sh
cd
cd build
cd riken_simulator
scons build/ARM/gem5.opt -j 20
```

もう一枚ターミナルを開いて、`docker stats`でリソースを監視します。メモリのリミットが2GiBになっています。

で、こけたところで、続けて2並列でビルドしましょう。

```sh
scons build/ARM/gem5.opt -j 2
```

あるところでメモリを使い切り、ビルドが進まなくなります。

![Memory full](memory_full.png)

ここでビルドを止めます。どこで止まったか調べるため、`scons --dry-run`しましょう。

```sh
$ scons build/ARM/gem5.opt --dry-run
(snip)
 [     CXX] ARM/arch/arm/generated/inst-constrs-3.cc -> .o
 [     CXX] ARM/arch/arm/generated/generic_cpu_exec_1.cc -> .o
 [     CXX] ARM/arch/arm/generated/generic_cpu_exec_2.cc -> .o
 [     CXX] ARM/arch/arm/generated/generic_cpu_exec_3.cc -> .o
 [     CXX] ARM/arch/arm/generated/generic_cpu_exec_4.cc -> .o
 [     CXX] ARM/arch/arm/generated/generic_cpu_exec_5.cc -> .o
 [     CXX] ARM/arch/arm/generated/generic_cpu_exec_6.cc -> .o
(snip)
```

ビルドできていないターゲットの先頭は`ARM/arch/arm/generated/inst-constrs-3.o`です。

こいつを単独でビルドしてみましょう。

```sh
scons build/ARM/arch/arm/generated/inst-constrs-3.o
```

もう一枚のターミナルで`docker stats`で監視すると、メモリを使い切っていることがわかります。

![memory full](memory_full_single.png)

メモリが十分にあればビルドできるはずなので、このファイルをビルドするのにどれくらいのメモリが必要なのか調べてみましょう。

一度Dockerコンテナから出ます。そして、ビルド直前のイメージからやりなおします。こういうことができるのがDockerの便利なところですね。今度はメモリ制限をかけません。

```sh
docker run -it -u user kaityo256/aarch64before
```

利用メモリを調べるために`time`をインストールします。

```sh
sudo apt install -y time
```

`time -v`をかませて、問題のファイルをビルドしてみましょう。普通に`time`とするとシェルのtimeが使われてしまうため、フルパスで指定します。

```sh
$ cd
$ cd build/riken_simulator/
$ /usr/bin/time -v scons build/ARM/arch/arm/generated/inst-constrs-3.o
(snip)
scons: done building targets.
        Command being timed: "scons build/ARM/arch/arm/generated/inst-constrs-3.o"
        User time (seconds): 117.09
        System time (seconds): 10.16
        Percent of CPU this job got: 101%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 2:05.54
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 2686200
        Average resident set size (kbytes): 0
        Major (requiring I/O) page faults: 0
        Minor (reclaiming a frame) page faults: 2598152
        Voluntary context switches: 10887
        Involuntary context switches: 963
        Swaps: 0
        File system inputs: 0
        File system outputs: 177568
        Socket messages sent: 0
        Socket messages received: 0
        Signals delivered: 0
        Page size (bytes): 4096
        Exit status: 0
```

注目すべきは「Maximum resident set size」です。2686200 (kbytes)、つまりたった一つのファイルのコンパイルに2.56GB使ってますね。このファイルが原因と判明しました。

## なぜそんなにメモリを食うのか

さて、問題のファイルが`build/ARM/arch/arm/generated/inst-constrs-3.cc`であると判明しました。`inst-constrs-1.cc`や`inst-constrs-2.cc`という似たファイルもありますが、同様に`time -v`で調べても(まぁまぁ使いますが)死ぬほどメモリを使っている、という感じはしません。

では、このファイルをどうやってビルドしているのか確認しましょう。まず、このファイル関連をクリーンします。SConsは-cをつけると関連ファイルを消してくれます。

```sh
scons -c build/ARM/arch/arm/generated/inst-constrs-3.o
```

次に、dry runでビルドコマンドを確認しましょう。

```sh
$ scons --dry-run build/ARM/arch/arm/generated/inst-constrs-3.o
(snip)
scons: Building targets ...
 [ISA DESC] ARM/arch/arm/isa/main.isa -> generated/decoder-g.cc.inc, generated/decoder-ns.cc.inc, generated/decode-method.cc.inc, generated/decoder.hh, generated/decoder-g.hh.inc, generated/decoder-ns.hh.inc, generated/exec-g.cc.inc, generated/exec-ns.cc.inc, generated/max_inst_regs.hh, generated/decoder.cc, generated/inst-constrs-1.cc, generated/inst-constrs-2.cc, generated/inst-constrs-3.cc, generated/generic_cpu_exec_1.cc, generated/generic_cpu_exec_2.cc, generated/generic_cpu_exec_3.cc, generated/generic_cpu_exec_4.cc, generated/generic_cpu_exec_5.cc, generated/generic_cpu_exec_6.cc
 [     CXX] ARM/arch/arm/generated/inst-constrs-3.cc -> .o
scons: done building targets.
```

情報ゼロです。SConsは通常、ビルドコマンドを表示してくれますが、SConstructの設定で消されているようです。見てみましょう。

```py
if GetOption('verbose'):
    def MakeAction(action, string, *args, **kwargs):
        return Action(action, *args, **kwargs)
else:
    MakeAction = Action
    main['CCCOMSTR']        = Transform("CC")
    main['CXXCOMSTR']       = Transform("CXX")
    main['ASCOMSTR']        = Transform("AS")
    main['ARCOMSTR']        = Transform("AR", 0)
    main['LINKCOMSTR']      = Transform("LINK", 0)
    main['SHLINKCOMSTR']    = Transform("SHLINK", 0)
    main['RANLIBCOMSTR']    = Transform("RANLIB", 0)
    main['M4COMSTR']        = Transform("M4")
    main['SHCCCOMSTR']      = Transform("SHCC")
    main['SHCXXCOMSTR']     = Transform("SHCXX")
```

ここですね。オプションに`--verbose`がついていない場合、g++によるビルドが` [     CXX]`とだけ表示されるようになっているようです。

というわけで`--verbose`をつけてみましょう。

```sh
$ scons --verbose build/ARM/arch/arm/generated/inst-constrs-3.o
(snip)
g++ -o build/ARM/arch/arm/generated/inst-constrs-3.o -c -std=c++11 -pipe -fno-strict-aliasing -Wall -Wundef -Wextra -Wno-sign-compare -Wno-unused-parameter -Wno-error=suggest-override -g -O3 -DTRACING_ON=1 -Iext/pybind11/include -Ibuild/nomali/include -Ibuild/libfdt -Ibuild/libelf -Ibuild/iostream3 -Ibuild/fputils/include -Ibuild/drampower/src -Iinclude -Iext -I/usr/include/python2.7 -I/usr/include/x86_64-linux-gnu/python2.7 -Iext/googletest/include -Ibuild/ARM build/ARM/arch/arm/generated/inst-constrs-3.cc
```

コンパイルコマンドがわかりました。多数のインクルードファイルに依存しているようなので、それらを全部インクルードしたファイルを作りましょう。`g++ -E`を使います。

```sh
g++ -E -std=c++11 -pipe -fno-strict-aliasing -Wall -Wundef -Wextra -Wno-sign-compare -Wno-unused-parameter -Wno-error=suggest-override -g -O3 -DTRACING_ON=1 -Iext/pybind11/include -Ibuild/nomali/include -Ibuild/libfdt -Ibuild/libelf -Ibuild/iostream3 -Ibuild/fputils/include -Ibuild/drampower/src -Iinclude -Iext -I/usr/include/python2.7 -I/usr/include/x86_64-linux-gnu/python2.7 -Iext/googletest/include -Ibuild/ARM build/ARM/arch/arm/generated/inst-constrs-3.cc > expanded.cc
```

これで`expanded.cc`という、単独でコンパイルできるファイルができました。コンパイルして利用メモリを確認してみましょう。

```sh
/usr/bin/time -v g++ -O3 -S expanded.cc
```


