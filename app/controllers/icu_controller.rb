class IcuController < ApplicationController
  def officers
    @officers = Officer.active.ordered.include_players
  end

  def subscribers
    params[:season].present? or params[:season] = Season.new.to_s
    @subscribers = Player.search_subscribers(params, icu_subscribers_path)
    flash.now[:warning] = t("no_matches") if @subscribers.count == 0
  end

  def life_members
    @members = Player.life_members
  end

  Global::ICU_DOCS.each_key do |page|
    define_method(page) do
      redirect_to_document(page)
    end
  end

  private

  def redirect_to_document(page)
    if Document.respond_to?(page)
      doc = Document.send(page).current.first
      if doc
        redirect_to doc
      end
    end
  end
end
