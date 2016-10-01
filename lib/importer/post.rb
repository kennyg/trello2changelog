require "maruku"

class Post
  attr_reader :card
  def initialize card
    @card = card
  end

  def body
    @body ||= begin
      if attached_link
        description = card.desc || ""
      else
        description = (card.desc.lines[2..-1] || []).join
      end

      md_to_html description
    end
  end

  def draft?
    card.desc.empty? || card.labels.any? { |label| label.name == "Draft" }
  end

  def link
    @link ||= if attached_link
      attached_link.url
    else
      card.desc.lines.first.chomp
    end
  end

  def sponsored?
    card.labels.any? { |label| label.name == "Sponsored" }
  end

  def title
    card.name
  end

  private

  def attached_link
    @attached_link ||= card.attachments.first
  end

  def md_to_html text
    Maruku.new(text).to_html
  end
end
