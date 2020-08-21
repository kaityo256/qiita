# 数式を含むMarkdownファイルをRe:VIEWにする

## はじめに

数式を含む文書を書くことが多いのですが、いつもMarkdownで書いています。Markdownはいろいろなことができませんが、逆に「いろいろなこと」をしないように書くようになるので、慣れるとLaTeXより楽だったりします。とりあえず私は

* 大きなブロック(章等)が表現できる
* 箇条書きなどがある
* リンクを張れる
* 数式を入れられる
* 画像を入れられる

だけができれば良く、それ以上のことは要求しません。

VSCodeで書くと、数式も含めてプレビューできるので便利です。そのままGitHubに上げても数式は見えませんが、適当なテンプレートを使ってPandocで変換してやればGitHub Pagesで数式が見えるようになり、ついでにレスポンシブ対応にもできて便利です。例えば[一週間でなれる！スパコンプログラマ](https://kaityo256.github.io/sevendayshpc/)はそうやって作っています。

このようにMarkdownは気軽に書けていいのですが、方言が極めて多く、特に数式の扱いが統一されていないのが困りもので、変換時に様々なトラブルを引き起こします。

というわけで今回、こうやって書いた「数式を含むMarkdown」をRe:VIEW StarterでPDF化する際に困ったことをまとめておきます。以下、Re:VIEW Starterを使う関係で、Re:VIEWのバージョンは2.5を想定します。

## 方針

マークダウンファイル`*.md`を[md2review](https://github.com/takahashim/md2review)で`*.re`に変換します。ただし、数式が変換できないので、事前に変換スクリプトをかませておきます。また、数式中にアンダースコアがあると変換がおかしくなるので、それもエスケープしておき、後で元に戻す必要があります。

## 数式

Markdownに数式を入れる方法はいくつか流儀がありますが、ここではインライン数式は`$`、ブロック数式は`$$`で囲むことにします。VSCodeではプレビューにKaTeXを使う関係で、`aligned`まわりとか、微妙にQiitaと違ったりします。

## アンダースコアのエスケープ

まず困るのが、アンダースコアが文中に二回出現すると、強調構文と解釈されてしまうことです。md2reviewは変換にRedcarpetを使っていますが、Redcarpetは数式に対応しておらず、数式中に出現するアンダースコアをMarkdownの強調と解釈してしまいます。こんなコードを書いてみましょう。

```rb
require 'redcarpet'
require 'redcarpet/render/review'
render = Redcarpet::Render::ReVIEW.new()
mk = Redcarpet::Markdown.new(render)
puts mk.render(ARGV[0])
```

これに`$t_1$`を食わせてもそのままスルーされます。

```txt
$ ruby test.rb '$t_1$'

$t_1$
```

しかし、`From $t_1$ to $t_2$`みたいなのを食わせるとこうなります。

```txt
$ ruby test.rb 'From $t_1$ to $t_2$'

From $t@<b>{1$ to $t}2$
```

途中にある二つのアンダースコアに挟まれた部分を強調だと認識されてしまったのです。これは、ブロック内でも同じで、インライン、ブロックともに数式中のアンダースコアをエスケープしてやる必要があります。なんでも良いですが、なんかRe:VIEWっぽく`@<underscore>`にしておいて、後で戻すことにしましょう。

## インライン数式中の中カッコ

Re:VIEWでは、インライン数式は`@\<m\>{}'で表現できます。しかし、この中で、そのままでは中カッコが使えません。なので、

```txt
$T_i^n$
```

みたいなのは

```txt
@<m>{T_i^n}
```

にすればよいのですが、

```txt
$T_i^{n+1}$
```

をそのまま

```txt
@<m>{T_i^{n+1}}
```

にするとエラーとなります。`}`を`\{`とエスケープしてやるなど、解決策はいくつかあると思いますが、一番簡単なのは[フェンス記法](https://github.com/kmuto/review/blob/master/doc/format.ja.md#%E3%82%A4%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%B3%E5%91%BD%E4%BB%A4%E3%81%AE%E3%83%95%E3%82%A7%E3%83%B3%E3%82%B9%E8%A8%98%E6%B3%95)を使うことです。

フェンスには`$`か`|`が使えますが、`$`だと変換が面倒になるので$|$を使うことにします。これを使うと、

```txt
$T_i^{n+1}$
```

は

```txt
@<m>|T_i^{n+1}|
```

と書けます。もちろん、数式中に`|`を使っている場合は真面目にエスケープする必要があります。

## スクリプト

というわけで、`*.md`を`md2review`に食わせる前と後に手抜き変換スクリプトをかませることにします。

前処理はこんな感じでしょうか。

```rb

def escape_underscore(str)
  str.gsub('_','@<underscore>') 
end

def escape_inline_math(str)
  while str =~ /\$(.*?)\$/
    math = escape_underscore($1)
    str = $` + "@<m>|" + math + "|" + $'
  end
  str
end

def in_math
  while line=gets
    if line=~/\$\$/
      puts "//}"
      return
    else
      puts escape_underscore(line)
    end
  end
end

while line=gets
  if line=~/\$\$/
    puts "//texequation{"
    in_math
  else
    puts escape_inline_math(line)
  end
end
```

インライン、ブロック中の数式のアンダースコアをエスケープするのと、それぞれRe:VIEW形式に変換しています

ポスト処理は、エスケープしていたアンダースコアを戻すだけです。

```rb
while line=gets
  puts line.gsub('@<underscore>','_')
end
```

これだけならsedでもいい感じがしますが、将来なんか面倒な処理が増えた時のためにRubyで書いておきます。

後は、Markdownから参照する画像をRe:VIEWから参照できるディレクトリ(`images`以下)に適当にコピーすれば、変換が可能です。

## まとめ

数式を含むMarkdownファイルを、`md2reviwe`を使ってRe:VIEWファイルに変換してみました。上記の方法で変換して作ったPDFを[ここ](https://github.com/kaityo256/sevendayshpc/releases)に置いておきます。まだ変換ミスなどで「??」になってたり、そこかしこに変なところはありますが、パッと見にはそれっぽくなってることがわかるかと思います。もっと苦労するかと思いましたが、もともと自分の書いてたMarkdownであまり凝ったことをしていなかったせいか、上記の修正だけでそれなりの変換ができました。ただし、印刷用にちゃんとしたものにするためには、変換後にそれなりに手で修正をいれる必要はありそうです。

今回、[Re:VIEW Starter](https://kauplan.org/reviewstarter/)を使いましたが、簡単なステップできれいなPDFができて便利でした。また、変換トラブルでエラーが起きた時、Re:VIEW Starter拡張の範囲コメント(`#@+++`と`#@---`)で二分探索ができたのがデバッグに役に立ちました。

「手軽に書けて、ウェブで簡単に見られるようにして、かつきれいなPDFを生成したい」、文書書きさんならいつも思うことだと思います。「これが最善」という方法はありませんが、とりあえずMarkdown+数式で書いて、PandocでHTMLにして、md2reviewでRe:VIEW経由でPDFにする、という方法を紹介してみました。他にもいろんな方法はあると思いますが、本稿が誰かの参考になれば幸いです。

## 参考

* [技術系同人誌を書く人の味方「Re:VIEW Starter」の紹介](https://qiita.com/kauplan/items/d01e6e39a05be0b908a1)、[2019年夏の新機能](https://qiita.com/kauplan/items/dd8dd0f4a6e0eb539a98)、[2019年冬の新機能](https://qiita.com/kauplan/items/e36edd7900498e231aaf)
