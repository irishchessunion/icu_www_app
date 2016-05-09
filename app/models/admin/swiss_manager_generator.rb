module Admin
  # This class is here to generate the content of a SwissManager compatible file from a list of players
  # First 10 chars for ID, left padded with zeros if < 1000
  # Next 34 chars for last name, first name
  # Next 4 chars for playing title
  # Next 5 chars for federation
  # Next
  # 00000000011111111112222222222333333333344444444445555555555666666666677777
  # 12345678901234567890123456789012345678901234567890123456789012345678901234
  # ID number Name                              TitlFed  Mar16 GamesBorn  Flag
  # 10586     Abberton, Eamonn                      IRL  1467    0  1957  U Castlebar
  # 6150      Abberton, Gerard                           1320    0        U Galuay

  class SwissManagerGenerator
    def initialize
      #           00000000011111111112222222222333333333344444444445555555555666666666677777
      #           12345678901234567890123456789012345678901234567890123456789012345678901234
      #           ID number Name                              TitlFed  Sep11 GamesBorn  Flag
      #           12508608  Abbaszadeh, Esmaeil                   IRI  1925    0
      @content = "ID number Name                              TitlFed  Mar16 GamesBorn  Flag\r\n"
    end

    # @param player [Player]
    def add_player(player)
      id = player.id
      # Swiss manager doesn't like IDs of less than 4 digits, so pad them.
      id = '%04d' % id if id < 1000
      title = Player::TITLES_TO_SWISSMANAGER_FMT.fetch(player.player_title, '')
      yob = player.dob.year.to_s
      # Add gender (if female) and club (if there is one) but replace any occurrences of "w" in club.
      # Also add a something to indicate subscription (lifetime, this season or last season).
      flag = player.gender == 'F' ? 'wU' : 'U'
      # my $sub = $subscriptions->{$id} || 'U';
      club = player.club_name
      if club
        club = club.gsub('W', 'U')
        club = club.gsub('w', 'u')
        flag += " #{club}"
      end
      # 00000000011111111112222222222333333333344444444445555555555666666666677777
      # 12345678901234567890123456789012345678901234567890123456789012345678901234
      # ID number Name                              TitlFed  Sep11 GamesBorn  Flag
      # 12508608  Abbaszadeh, Esmaeil                   IRI  1925    0
      # 7900139   Abbou, Meriem                     wf  ALG  2005    0        wi
      # 2500388   Connolly, Suzanne                     IRL  2012    0  1963  wi
      # 2500035   Orr, Mark J L                     m   IRL  2260    0  1955
      fmt = "%-8s  %-32s  %-2s  %3s  %-4s  %3d  %-4s  %s\r\n"
      @content << fmt % [id, player.name(reversed: true), title, player.fed, player.latest_rating, 0, yob, flag]
    end

    # @param items [Array<Item>]
    # @return [String] The content of the generated file.
    def generate_from_items(items)
      items.each do |item|
        add_player(item.player) if item.player.present?
      end
      @content
    end
  end
end