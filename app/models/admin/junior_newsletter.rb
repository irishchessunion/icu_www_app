require 'csv'

module Admin
  class JuniorNewsletter
    def generate(users)
      CSV.generate do |csv|
        csv << ["Users who requested a junior report generated on #{Time.now}", '', '', '']
        csv << %w(ICU# Rating Name Email)
        users.each do |user|
          if user.player.present?
            id, rating, name, email = user.player.id, user.player.latest_rating, user.player.name, user.email
          else
            id, rating, name, email = user.id, "", "", user.email
          end
          csv << [id, rating, name, email]
        end
      end
    end
  end
end