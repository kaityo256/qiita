# MPIでシェルコマンドを並列実行する

## はじめに

大量のシェルコマンドを実行したいとします。こんな感じ。

```sh
./a.out < input1.txt > output1.txt
./a.out < input2.txt > output2.txt
./a.out < input3.txt > output3.txt
./a.out < input4.txt > output4.txt
...
```

ただし、それぞれのコマンドの実行時間にはかなりゆらぎがあり、その時間は事前に予想できないとします。この時、MPIで多数のプロセスを立ち上げて、片っ端から`std::system`で実行していき、終わりしだいタスクリストの終わってない奴を実行していくようなプログラムを作りました。コードは以下においておきます。

[https://github.com/kaityo256/cps](https://github.com/kaityo256/cps)

## どう使うか

予めやりたい処理をシェルスクリプトっぽくリストにしておきます。

```sh
## tasks
sleep 1.1
sleep 1.4
sleep 0.9
sleep 1.1
sleep 1.3
sleep 1.2
```

これをMPIで実行します。

```sh
mpirun -np 4 ./cps task.sh
```

実行終了後、同じディレクトリに`cps.log`というログを吐きます。

```txt
Number of tasks : 6
Number of processes : 4
Total execution time: 7.043 [s]
Elapsed time: 2.616 [s]
Parallel Efficiency : 0.897426

Task list:
Command : Elapsed time
sleep 1.1 : 1.107 [s]
sleep 1.4 : 1.406 [s]
sleep 0.9 : 0.907 [s]
sleep 1.1 : 1.106 [s]
sleep 1.3 : 1.308 [s]
sleep 1.2 : 1.209 [s]
```

タスクが全部で6つ、プロセス数は4だがスケジューラを除いて3プロセス、全部シリアルに実行したら7.043秒かかるところ、全体で2.616秒かかったので、並列化効率は89.7%、みたいなことがわかります。ちなみに並列化効率はスケジューラを除いたプロセス数で計算しています。

## なぜ作ったのか

多数のCPUコアがあるマシン(例えばRyzen)で、一度に大量の処理をしたいことがあります。この時、`make -j`を使ったり、もう少しちゃんとしたスケジューリングがしたければOpenMPを使うという手もあります。しかし、これらの方法ではノードをまたぐことができません。MPIを使えばノードを何枚でもまたいで実行することができます。また、PCクラスタではMPIを使うことが前提となっていることが多いので、MPIの皮をかぶせておくといろいろ使いやすい、ということもあります。

あと、こういうプログラムは、MPIの非自明な使い方のかんたんなサンプルになっている、という意味もあります。数値計算でMPIを使って、サンプル平均、パラメタ平均、領域分割なんかをやってると、ほとんど場合`MPI_Sendrecv`と`MPI_Allreduce`、`MPI_Allgather`くらいで事足りてしまいます。

しかし、MPIでちょっと複雑なことをしようとすると、とたんにいろいろ面倒になります。ここで紹介する非同期なスケジューラなんかは、やりたいことのわりには複雑だけれど、まぁ、死ぬほど面倒でもない、という、MPIを馬鹿パラ、領域分割以外で使うのにちょうどよい題材だったりします。

そんなわけで、複数のプロセスを立ち上げ、1つをスケジューラ、残りをワーカに振り分け、スケジューラがワーカの状態を監視しながらタスクを割り当てるようなプログラムを組んでみましょう。

ちなみにほとんど[過去の記事](https://qiita.com/kaityo256/items/fafae987032f8b0fa778)に書いた内容とアルゴリズムは同じです。

## 動作原理

## タスクの割当

ランク0番をスケジューラ、それ以外をワーカとします。スケジューラ、ワーカそれぞれで無限ループを回し、ワーカはジョブが来るのを待ちます。

この時、ワーカが現在暇かどうかをスケジューラに知らせるため、ワーカからスケジューラにダミーのデータを送信します。

```cpp
// Sends dummy data to notify that communication is ready.
MPI_Send(&send, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
```

スケジューラ側は、ワーカが暇かどうかを調べるために、このダミーデータを受信しますが、もし`MPI_Recv`で受信してしまうと、暇じゃないワーカに問い合わせた時、そのワーカの仕事が終わるまで処理が返ってきません。そこで、`MPI_Iprobe`でデータが届いてないか覗きます。

```cpp
int isReady = 0;
MPI_Iprobe(i, 0, MPI_COMM_WORLD, &isReady, &st);
```

もしデータが来てなければ次のワーカに`MPI_Iprobe`します。

```cpp
if (!isReady) continue;
```

もしデータが来ていればそのワーカは暇なので仕事を与えます。まずはProbeで覗いてたデータをちゃんと受信します。その後、コマンドリストの文字列を送信します。文字列の送信は、「文字列の長さ」「文字列本体」の二回の通信が必要です。

```cpp
MPI_Recv(&dummy, 1, MPI_INT, i, 0, MPI_COMM_WORLD, &st);
int len = command_list[task_index].length() + 1;
MPI_Send(&len, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
MPI_Send(command_list[task_index].data(), len, MPI_CHAR, i, 0, MPI_COMM_WORLD);
```

## タスクの受け取り

ワーカは、ダミーデータを送信後、コマンド文字列の長さの受信待ち状態に入ります。

```cpp
    int send = 10;
    int len = 0;
    MPI_Status st;
    // Sends dummy data to notify that communication is ready.
    MPI_Send(&send, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
    // Recieve the length of a command
    MPI_Recv(&len, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &st);
```

`MPI_Send`は、受信側が受け取り処理をする前に、送信側で処理が進む可能性がありますが、`MPI_Recv`は、受信が終わるまで次に処理が進みません。なので、暇なワーカはここで待つことになります。

コマンド文字列を受信したら、その文字列を受け取れるだけのバッファを用意して、そこに受信します。

```cpp
    std::unique_ptr<char[]> buf(new char[len]);
    MPI_Recv(buf.get(), len, MPI_CHAR, 0, 0, MPI_COMM_WORLD, &st);
    std::string recv_string = buf.get();
```

これで`recv_string`にコマンド文字列が入るので、後は`std::system`に突っ込むだけです。

```cpp
std::system(recv_string.c_str());
```

楽ちんですね。

## 終了処理

さて、タスクが全て完了したら、ワーカに「終わったよ」と伝えてあげなければいけません。いろいろやり方はあると思いますが、ここでは「コマンド文字列の長さとして0を受信したら終了」とします。

```cpp
    if (len == 0) {
      debug_printf("Finish OK: %d\n", rank);
      break;
    }
```

この`break`で`while`を抜けます。`debug_printf`はデバッグ用なので気にしないでください。

スケジューラ側は、タスクの受け渡しと同様に、終了処理でも`MPI_Iprobe`を使ってワーカが受信可能であるかどうか調べます。受信可能であればコマンド文字列の長さとして0を送信し、終了を伝えます。一つでも仕事が終わっていないワーカがいれば、無限ループでずっと待ちます。全て終わったら無限ループを抜けておしまいです。

## その他雑多なこと

## 文字列送信

上でも触れましたが、文字列の送信では、まず長さを送信してから本体を送る必要があります。送る側はただ二つ送ればよいだけですが、受信側はまず長さを受け取ったら、バッファを用意する必要があります。

```cpp
int len = 0;
MPI_Recv(&len, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &st);
std::unique_ptr<char[]> buf(new char[len]);
MPI_Recv(buf.get(), len, MPI_CHAR, 0, 0, MPI_COMM_WORLD, &st);
std::string recv_string = buf.get();
```

ここではいちいち`char`の配列を`new`して受け取っていますが、事前に十分な長さのバッファを用意しておいてもかまいません。

```cpp
char buf[MAX_COMMAND_LENGTH]];
```

ただし、`std::system`が受け付ける文字列は意外に長いです。`xargs --show-limits`で見てみましょう。

```sh
$ xargs --show-limits
環境変数が 5057 バイトを占めます
POSIX の引数の長さ上限 (このシステム): 2090047
POSIX の最小の引数の長さの上限 (すべてのシステム): 4096
実際に使用できるコマンド長の最大値: 2084990
実際に使用しているコマンドバッファの大きさ: 131072
```

このシステムではコマンド長の最大値は2084990バイトでした。この大きさを事前に用意しておくのはちょっと気が引けますね。

また、今回はランク0番がファイルを読み込み、コマンドをワーカに送信していますが、全てのプロセスがファイルを読み込んでしまえば文字列の送信は必要ありません。スケジューラは「何番目のタスクを実行すればよいか」だけを伝えれば良いことになります。しかし、下手すると1000プロセスとかがせーので同じファイルにアクセスするのはなんかイヤだったので、今回は真面目にランク0番が読み込み、他のプロセスにコマンド文字列送信、という形にしました。

## エラー処理

MPIを使っていると、ちょいちょい面倒なことがありますが、そのうちの一つがエラー処理です。例えば今回のようにランク0番がファイルを読み込んで、残りはファイルを開かない、といった場合に、ファイルの読み込みエラーなどがあった場合にどうするか、等です。

面倒なら、なにかエラーが起きたら`MPI_Abort`してしまえばよいのですが、いちいち大量のエラーが出るのがイヤです。なので、僕は状態フラグを用意して、`MPI_Allreduce`でその論理積を取り、一つでも0がいたらエラー、みたいなことをします。

```cpp
  int is_ready = loadfile(argc, argv);
  int all_ready = 0;
  MPI_Allreduce(&is_ready, &all_ready, 1, MPI_INT, MPI_LAND, MPI_COMM_WORLD);
  if (all_ready) {
    if (rank == 0) {
      manager(procs);
    } else {
      worker(rank);
    }
  }
```

この`loadfile`関数は、ランク0は真面目にファイルを読み込みますが、それ以外はただ1を返す関数です。もしエラーが起きたらランク0が0を返すので、その論理積を取ると、エラーがあったかどうかをプロセス全体で共有できます。

## まとめ

やってることは自明並列なんだけど実装は非自明なMPIプログラムを組んでみました。例えば今回のやり方ではプロセスが一つ無駄になってしまってますが、スレッドを作ってそいつに監視をさせればランク0番もワーカとして使えるようになると思います。他にもいろいろ書き方はあると思いますので、興味のある人は試してみると良いのではないでしょうか？

この記事を見て、MPIで遊んでくれる人が増えるといいな、と思います。

## MPI_ANY_SOURCEの利用(2020年2月21日追記)

`MPI_Iprobe`の代わりに`MPI_ANY_SOURCE`を使ってはどうか、というコメントを頂きました。`MPI_ANY_SOURCE`は、「どこからでも通信を受け付ける」というもので、実際どこから受け付けたかは`MPI_Status`構造体の`MPI_SOURCE`を参照するとわかります。これまでは、`while`文の中に、ランク番号に関する`for`文を回してポーリングしていましたが、これを使うと、例えばタスクの割り振りルーチンは

```cpp
  // Distribute Tasks
  while (task_index < num_tasks) {
    MPI_Status st;
    int isReady = 0;
    MPI_Recv(&isReady, 1, MPI_INT, MPI_ANY_SOURCE, 0, MPI_COMM_WORLD, &st);
    int i = st.MPI_SOURCE;
    if (assign_list[i] != -1) {
      auto start = start_time[i];
      double elapsed = get_time(start);
      ellapsed_time[assign_list[i]] = elapsed;
      debug_printf("task %d assigned to %d is finished at %f\n", task_index, i, get_time(timer_start));
      assign_list[i] = -1;
    }
    // Assign task_index-th task to the i-th process
    assign_list[i] = task_index;
    start_time[i] = std::chrono::system_clock::now();
    debug_printf("task %d is assignd to %d at %f\n", task_index, i, get_time(timer_start));
    int len = command_list[task_index].length() + 1;
    MPI_Send(&len, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
    MPI_Send(command_list[task_index].data(), len, MPI_CHAR, i, 0, MPI_COMM_WORLD);
    task_index++;
  }
```

タスクの終了確認は、

```cpp
  // Complete Notification
  int finish_check = procs - 1;

  while (finish_check > 0) {
    MPI_Status st;
    int dummy = 0;
    int recv = 0;
    MPI_Recv(&recv, 1, MPI_INT, MPI_ANY_SOURCE, 0, MPI_COMM_WORLD, &st);
    int i = st.MPI_SOURCE;
    MPI_Send(&dummy, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
    finish_check--;
    if (assign_list[i] != -1) {
      auto start = start_time[i];
      double elapsed = get_time(start);
      ellapsed_time[assign_list[i]] = elapsed;
      debug_printf("task %d assigned to %d is finished at %f\n", task_index, i, get_time(timer_start));
      assign_list[i] = -1;
    }
  }
```

と、`while`文だけになるので、こっちの方がシンプルですね。
