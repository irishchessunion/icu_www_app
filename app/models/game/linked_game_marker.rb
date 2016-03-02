# This class has a run method that searches through all the articles and news items for any links to games, and
# then sets the in_link field to true for those games.
class Game::LinkedGameMarker
  def run
    unmark_all_games
    articles_with_links.find_each do |article|
      mark_games_in_object(article)
    end

    news_with_links.find_each do |news|
      mark_games_in_object(news)
    end
  end

  def unmark_all_games
    Game.update_all(in_link: false)
  end

  def articles_with_links
    Article.linked_to_game
  end

  def news_with_links
    News.linked_to_game
  end

  # @param object [Article, News]
  def mark_games_in_object(object)
    game_ids = object.game_ids
    updated_record_count = Game.where(id: game_ids).update_all(in_link: true)
    if updated_record_count < game_ids.size
      Rails.logger.info "Article #{object.id} has #{game_ids.size - updated_record_count} bad game links"
    end
  end
end
