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

  def constitution
    redirect_to_document("constitution")
  end

  def code_of_conduct
    redirect_to_document("code_of_conduct")
  end

  def membership_byelaws
    redirect_to_document("membership_byelaws")
  end

  def eligibility_criteria
    redirect_to_document("eligibility_criteria")
  end

  def junior_eligibility_criteria
    redirect_to_document("junior_eligibility_criteria")
  end

  def selection_committee
    redirect_to_document("selection_committee")
  end

  def ncc_rules
    redirect_to_document("ncc_rules")
  end

  def affiliation_byelaws
    redirect_to_document("affiliation_byelaws")
  end

  def officer_roles
    redirect_to_document("officer_roles")
  end

  def allegro_rules
    redirect_to_document("allegro_rules")
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
