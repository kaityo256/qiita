require "yaml"
require "open-uri"

data = YAML.load(File.open("qiita.yaml"))
dirlist = YAML.load(File.open("dirlist.yaml"))

puts <<EOS
# Qiitaに書いた記事アーカイブ

## 概要

Qiitaに投稿した記事のアーカイブ

## 記事一覧

EOS

data.each do |article|
  title = article["title"]
  next unless dirlist[title]

  dir = dirlist[title]
  created = Time.iso8601(article["created_at"])
  updated = Time.iso8601(article["updated_at"])
  url = article["url"]
  puts "* [#{title}](#{dir}/README.md)"
  puts "  * [Qiita](#{url})"
  puts "  * 作成：#{created}"
  puts "  * 更新：#{updated}"
end

puts <<EOS

## ライセンス

Copyright (C) 2018-2019 Hiroshi Watanabe

この文章と絵(pptxファイルを含む)はクリエイティブ・コモンズ 4.0 表示 (CC-BY 4.0)
で提供する。

This article and pictures are licensed under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

本リポジトリに含まれるプログラムは、[MITライセンス](https://opensource.org/licenses/MIT)で提供する。

The source codes in this repository are licensed under [the MIT License](https://opensource.org/licenses/MIT).
EOS
