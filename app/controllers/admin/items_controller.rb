require 'csv'

class Admin::ItemsController < ApplicationController
  def index
    authorize! :index, Item
    @items = Item.search(params, admin_items_path)
    flash.now[:warning] = t("no_matches") if @items.count == 0

    respond_to do |format|
      format.html
      format.csv do
        send_data csv_data, filename: "#{params[:description]}.csv", type: 'text/csv'
      end
      format.txt do
        send_data txt_data, filename: "#{params[:description]}.txt", type: 'text/txt'
      end
    end
  end
  
  def sales_ledger
    authorize! :sales_ledger, Item
    @ledger = SalesLedger.new
  end

  private

  def csv_data
    CSV.generate do |csv|
      csv << ["Items for #{params[:description]} generated on #{Time.now}", '', '', '', '']
      csv << %w(Description Player ICU# Rating Fee Status Notes)
      @items.each do |item|
        if item.player.present?
          name, id, rating = item.player.name, item.player.id, item.player.latest_rating
        elsif new_player = item.new_player
          name, id, rating = new_player.name, 'new', 'unknown'
        else
          name, id, rating = nil, nil, nil
        end
        csv << [item.description, name, id, rating, item.cost, item.status, *item.notes]
      end
    end
  end

  def txt_data
    s = ""
    # Write the header.
    s << "ID number Name                              TitlFed  mmyy GamesBorn  Flag\n"
    # Prepare the format.
    # 00000000011111111112222222222333333333344444444445555555555666666666677777
    # 12345678901234567890123456789012345678901234567890123456789012345678901234
    # ID number Name                              TitlFed  Sep11 GamesBorn  Flag
    # 12508608  Abbaszadeh, Esmaeil                   IRI  1925    0
    #  7900139  Abbou, Meriem                     wf  ALG  2005    0        wi
    #  2500388  Connolly, Suzanne                     IRL  2012    0  1963  wi
    #  2500035  Orr, Mark J L                     m   IRL  2260    0  1955
    fmt = "%-8s  %-32s  %-2s  %3s  %-4s  %3d  %-4s  %s\n"

    @items.each do |item|
      if item.player.present?
        id = item.player.id
        # Swiss manager doesn't like IDs of less than 4 digits, so pad them.
        id = '%04d' % id if id < 1000
        title = Player::TITLES_TO_SWISSMANAGER_FMT.fetch(item.player.player_title, '')
        yob = item.player.dob.year.to_s
        # Add gender (if female) and club (if there is one) but replace any occurrences of "w" in club.
        # Also add a something to indicate subscription (lifetime, this season or last season).
        flag = item.player.gender == 'F' ? 'w' : ''
        # my $sub = $subscriptions->{$id} || 'U';
        club = item.player.club_name
        if club
          club = club.gsub('W', 'U')
          club = club.gsub('w', 'u')
          flag += club
        end
        s << fmt % [id, item.player.name(reversed: true), title, item.player.fed, item.player.latest_rating, 0, yob, flag]
      end
    end
    s
  end
end
