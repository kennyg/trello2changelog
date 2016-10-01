require "maruku"

class Meta
  attr_reader :cards
  def initialize list
    @cards = list.cards
  end

  def editors_note
    if card = find_card("editors_note")
      # must not contain p tags
      md_to_html(card.desc).gsub("<p>", "").gsub("</p>", "")
    end
  end

  def preview_text
    if card = find_card("preview_text")
      card.desc
    end
  end

  def published_at
    cards.first.name
  end

  private

  def find_card name
    cards.find { |card| card.name == name }
  end

  def md_to_html text
    Maruku.new(text).to_html
  end
end
