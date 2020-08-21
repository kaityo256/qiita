# Rubocopに怒られないように0埋めした桁揃え文字列を作る

## TL;DR

1〜3桁の整数`size`があり、そこから例えば`L064.dat`みたいなファイル名を作りたい時、Rubocopに怒られないようにするには

```rb
filename = format("L%<size>03d.dat", size: size)
```

とすれば良い。これだけなんだけど、ここまで来るのに妙に苦労したのでRubocopの文句からこの記事にたどり着けるように詳細を書いておきます。

## Rubocopに怒られる

## C言語っぽく

1〜3桁の整数`size`があり、そこから例えば`L064.dat`みたいなファイル名を作りたい。C言語から入った人なら`sprintf`使ってこんな感じに書くと思う。

```rb
size = 10
puts sprintf("L%03d.dat", size)
```

これはRubocopに以下のように怒られる。

```sh
$ rubocop format1.rb
Inspecting 1 file
C

Offenses:

format1.rb:2:6: C: Style/FormatString: Favor format over sprintf.
puts sprintf("L%03d.dat", size)
     ^^^^^^^
format1.rb:2:16: C: Style/FormatStringToken: Prefer annotated tokens (like %<foo>s) over unannotated tokens (like %s).
puts sprintf("L%03d.dat", size)
               ^^^^

1 file inspected, 2 offenses detected
```

とりあえず`sprintf`を使うな、`format`を使え、と言ってるようですね。Rubyには書式付き文字列の作成方法が複数あるため、フォーマットを統一するため、Rubocopの`Style/FormatString`でどれを使うか指定できますが、デフォルトでは`EnforcedStyle`が`format`となっています。

## formatを使う

というわけで`format`を使いましょう。`sprintf`の代わりに`format`って書いただけ。

```rb
size = 10
puts format("L%03d.dat", size)
```

これはまたRubocopに怒られる。

```sh
$ rubocop format2.rb
Inspecting 1 file
C

Offenses:

format2.rb:2:15: C: Style/FormatStringToken: Prefer annotated tokens (like %<foo>s) over unannotated tokens (like %s).
puts format("L%03d.dat", size)
              ^^^^

1 file inspected, 1 offense detected
```

Unannotated tokensを使うなと言ってるようですね。

## Template tokensを使う

さて、ここで渡しは先の文句ではannotated tokensを使え、と書いてありますが、それに気づかずに(annotated tokenとtemplate tokenの違いを理解せずに)template tokenを使いました。

Template tokensというのは、`format`の文字列に引数としてハッシュを渡すと、`%{name}`などで、キーを参照してそのまま代入してくれる機能です。ただし、`%{name}`を使うとフォーマットできないので、フォーマットしたい場合はフォーマット済み文字列を渡す必要があります。こんな感じでしょうか。

```rb
size = 10
puts format("L%{size}.dat", size: size.to_s.rjust(3, "0"))
```

なんか不必要に複雑になった上に、まだRubocopに怒られますね。

```sh
$ rubocop format3.rb
Inspecting 1 file
C

Offenses:

format3.rb:2:15: C: Style/FormatStringToken: Prefer annotated tokens (like %<foo>s) over template tokens (like %{foo}).
puts format("L%{size}.dat", size: size.to_s.rjust(3, "0"))
              ^^^^^^^

1 file inspected, 1 offense detected
```

Template tokens `%{foo}`ではなく、annotated tokens`%<foo>s`を使え、と言ってますね。ここで初めてannotated tokenというものがあることを知りました。

## Annotated tokensを使う

Annotated tokensは、templated tokensと同様に引数にハッシュを与えますが、`%<name>d`のようにフォーマット指定できます。これを使うとこうなりますかね。

```rb
size = 10
puts format("L%<size>d.dat", size: size)
```

上記はRubocopは文句を言いませんが、出力結果が0埋めされません。

## Annotated tokensを使って、かつ桁指定して0埋めする

Annotated tokensでは、`printf`と同様にフォーマット指定子が使えます。例えば、3桁の整数で左を0埋めしたければ、`%<name>03d`と書けます。

```rb
size = 10
puts format("L%<size>03d.dat", size: size)
```

ようやくRubocopに文句を言われずに、0埋めした桁揃え文字列を作ることができました。

## まとめというか・・・

普段VSCodeを使ってますが、ちょっとしたスクリプトはVimで書いてます。で、VimでRubocopで確認するようにしてみたらRubocopのうるさいことうるさいこと。自動的に直せるところは直すauto-correctもあるのですが、保存時にこれが走るようにしたらかえって鬱陶しかったので、今のところ手でなおしています。

「自由に、好きなように書ける」のがRubyの良いところだと思っているのですが、その思想とLinterはどうも相性が悪いような気がしますね・・・

## 参考

* [RuboCop | Style/FormatString](https://qiita.com/tbpgr/items/d11b28753dc893920db6)
