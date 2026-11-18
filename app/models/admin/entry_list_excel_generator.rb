module Admin
  class EntryListExcelGenerator
    # Generates an excel file of the entrants to a tournament
    # in a format acceptable to Swiss Manager
    # @param items Array containing all of the items to be exported
    # @return A string of bytes containing the excel file data
    def generate_from_items(items)
      # The columns required for Swiss Manager are:
      # ID_no Fide_no Name Title Fed Rtg_Nat Rtg_Int Games Birthday Sub Sex ClubName
      # The information for FIDE ID and FIDE rating are currently missing from the main database

      rows = []
      for item in items
        title = ''
        title = Player::TITLES_TO_SWISSMANAGER_FMT[item.player.player_title] if item.player.player_title

        rating = item.player.latest_rating || item.player.legacy_rating

        # Outputs YOB/01/01 to hide DOB
        dob = item.player.dob ? Date.new(item.player.dob.year, 1, 1).strftime("%Y/%m/%d") : '1900/01/01'

        sub = item.player.subscription_code

        sex = item.player.gender == "F" ? "F": ""

        rows << [item.player_id, '', item.player.name(reversed: true), title, item.player.fed, rating, '', 0, dob, sub, sex, item.player.club&.name]
      end

      # Sort by name ascending
      rows.sort_by! {|e| e[2]}

      axlsx_package = Axlsx::Package.new
      axlsx_package.workbook.add_worksheet(:name => "Entrants") do |sheet|
        sheet.add_row %w(ID_no Fide_no Name Title Fed Rtg_Nat Rtg_Int Games Birthday Sub Sex ClubName)
        for row in rows
          sheet.add_row row
        end
      end

      axlsx_package.to_stream.read
    end
  end
end