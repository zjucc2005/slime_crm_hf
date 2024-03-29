class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  require 'carrierwave/orm/activerecord'

  CURRENCY = {
      :RMB => 'RMB',
      :USD => 'USD'
  }.stringify_keys

  FUXING = %w[公皙 南荣 东里 东宫 仲长 万俟 闻人 夏侯 子书 子桑 即墨 达奚 褚师 吴铭 欧阳 太史 端木 上官 司马 东方 子车 亓官 司寇
              巫马 东郭 南门 羊舌 微生 公西 颛孙 壤驷 公良 漆雕 乐正 宰父 独孤 南宫 诸葛 尉迟 公羊 赫连 澹台 皇甫 宗政 濮阳 公冶
              太叔 申屠 公孙 段干 百里 呼延 轩辕 令狐 公仪 梁丘 公户 公玉 慕容 仲孙 钟离 长孙 宇文 司徒 鲜于 司空 闾丘 谷梁 拓跋
              夹谷 公仲 公上 公门 公山 公坚 左丘 公伯 西门 公祖 第五 公乘 贯丘]

  def uid(len=6)
    sprintf("%0#{len}d", id)
  end

  def expose_fields(*args)
    res = {}
    args.each do |arg|
      arg.is_a?(Hash) ? res.merge!(arg) : res[arg] = self.send(arg)
    end
    res
  end
end
