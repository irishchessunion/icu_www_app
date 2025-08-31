# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

seed_sample_data = true

if seed_sample_data
  # The following 3 lines allow for "type" to be a column that's set.
  # Otherwise an ActiveRecord::SubclassNotFound error will be thrown.
  Fee.inheritance_column = :_type_disabled
  Item.inheritance_column = :_type_disabled
  UserInput.inheritance_column = :_type_disabled

  ActiveRecord::Base.transaction do
    # Sample Admin Account
    admin_player = Player.create!(
      first_name: "Admin",
      last_name: "Admin",
      status: "active",
      email: "admin@icu.ie",
      gender: Player::GENDERS.sample,
      dob: "2000-01-01",
      joined: "2020-01-01",
      source: Player::SOURCES.sample
    )
    
    admin_user = User.create!(
      email: "admin@icu.ie",
      roles: "admin",
      password: "password0",
      salt: "a"*32,
      status: "OK",
      expires_on: "2035-01-01",
      player_id: admin_player.id,
      verified_at: Time.now
    )

    # Sample data for carts
    5.times do |i|
      Cart.create!(
        status: "unpaid",
        total: rand(10..500),
        original_total: rand(10..500),
        payment_method: Cart::PAYMENT_METHODS.sample,
        payment_ref: "pi_#{rand(10000..99999)}",
        confirmation_email: "user#{i}@example.com",
        payment_name: "Test User #{i}",
        user_id: User.first&.id || 1,
        payment_account: "acct_#{rand(10000..99999)}"
      )
    end

    # Sample data for fees
    5.times do |i|
      Fee.create!(
        type: Fee::TYPES.sample,
        name: "Fee #{i}",
        amount: rand(50..100),
        discounted_amount: rand(5..50),
        years: "2025",
        active: true,
        start_date: Date.today - 1.days,
        end_date: Date.today + 1.days
      )
    end

    # Sample data for items
    5.times do |i|
      Item.create!(
        type: "FeeItem",
        player_id: Player.first&.id || 1,
        fee_id: Fee.first&.id || 1,
        cart_id: Cart.all.sample.id,
        description: "Item #{i} description",
        cost: rand(5..100),
        status: Payable::STATUSES[..-2].sample
      )
    end

    # Sample data for players
    5.times do |i|
      Player.create!(
        first_name: "First#{i}",
        last_name: "Last#{i}",
        status: "active",
        email: "player#{i}@example.com",
        gender: Player::GENDERS.sample,
        dob: "2000-01-01",
        joined: "2020-01-01",
        source: Player::SOURCES.sample
      )
    end
    
    # Sample data for users
    Player.all.each do |player|
      User.create!(
        email: "user#{player.id}@example.com",
        roles: "member",
        password: "password#{player.id}",
        salt: "#{player.id}"*32,
        status: "OK",
        expires_on: "2035-01-01",
        player_id: player.id,
        verified_at: Time.now
      )
    end

    # Sample data for refunds
    5.times do |i|
      Refund.create!(
        cart_id: Cart.all.sample.id,
        user_id: User.all.sample.id,
        amount: rand(5..50),
        automatic: [true, false].sample
      )
    end

    # Sample data for payment_errors
    5.times do |i|
      PaymentError.create!(
        cart_id: Cart.all.sample.id,
        message: "Error #{i}",
        details: "Details for error #{i}",
        payment_name: "User #{i}",
        confirmation_email: "user#{i}@example.com"
      )
    end

    # Sample data for articles
    5.times do |i|
      Article.create!(
        access: Article::ACCESSIBILITIES.sample,
        active: true,
        author: "Author #{i}",
        category: Article::CATEGORIES.sample,
        text: "Sample article text #{i}",
        title: "Article #{i}",
        user_id: User.all.sample.id,
        year: 2025
      )
    end

    # Sample data for clubs
    5.times do |i|
      Club.create!(
        name: "Club #{i}",
        city: "City #{i}",
        contact: "Contact #{i}",
        email: "club#{i}@example.com",
        active: true,
        county: Ireland.counties.sample
      )
    end

    # Sample data for events
    5.times do |i|
      Event.create!(
        active: true,
        category: Event::CATEGORIES.sample,
        name: "Event #{i}",
        start_date: Date.today,
        end_date: Date.today + rand(1..30),
        user_id: User.all.sample.id,
        location: "Location #{i}"
      )
    end

    # Sample data for champions
    5.times do |i|
      Champion.create!(
        category:  Champion::CATEGORIES[i],
        notes: "Champion notes #{i}",
        winners: "Winner #{i}",
        year: 2025 - i
      )
    end

    # Sample data for news
    5.times do |i|
      News.create!(
        active: true,
        date: Date.today - i,
        headline: "Headline #{i}",
        summary: "Summary #{i}",
        user_id: User.all.sample.id,
        category: "general"
      )
    end

    # # Sample data for fees (for user_inputs)
    # Fee.all.each do |fee|
    #   UserInput.create!(
    #     fee_id: fee.id,
    #     type: "Userinput::Text",
    #     label: "Input for fee #{fee.id}",
    #     required: true,
    #     max_length: 50
    #   )
    # end

    # Sample data for tournaments
    5.times do |i|
      Tournament.create!(
        active: true,
        category: Tournament::CATEGORIES.sample,
        city: "City #{i}",
        name: "Tournament #{i}",
        year: 2025,
        details: "Details for Tournament #{i}",
        format: Tournament::FORMATS.sample
      )
    end

    # Sample data for relays
    5.times do |i|
      Relay.create!(
        from: "email#{i}@icu.ie",
        to: "email#{i}@gmail.com",
        provider_id: "provider_#{i}",
        enabled: true
      )
    end

    # Sample data for results
    5.times do |i|
      Result.create!(
        competition: "Competition #{i}",
        player1: "Player1 #{i}",
        player2: "Player2 #{i}",
        score: "#{rand(0..1)}-#{rand(0..1)}",
        active: false,
        reporter_id: User.all.sample.id
      )
    end

    # Sample data for sponsors
    5.times do |i|
      Sponsor.create!(
        name: "Sponsor #{i}",
        weight: rand(1..10),
        contact_email: "sponsor#{i}@example.com",
        contact_name: "Contact #{i}",
        weblink: "https://sponsor#{i}.ie"
      )
    end

    # Sample data for images
    5.times do |i|
      Image.create!(
        data_file_name: "image#{i}.jpg",
        caption: "Image #{i} caption",
        credit: "Photographer #{i}",
        year: 2025,
        user_id: User.all.sample.id
      )
    end

    # Sample data for translations
    5.times do |i|
      Translation.create!(
        locale: Translation::LOCALES.sample,
        key: "key_#{i}",
        value: "Value #{i}",
        english: "English #{i}",
        old_english: "Old English #{i}",
        user: "User #{i}",
        active: true
      )
    end

    # Sample data for journal_entries
    5.times do |i|
      JournalEntry.create!(
        journalable_id: Cart.all.sample.id,
        journalable_type: "Cart",
        action: "update",
        column: "total",
        by: "User #{i}",
        ip: "127.0.0.#{i}",
        from: "100",
        to: "90"
      )
    end

    # Sample data for article_likes
    Article.all.each do |article|
      ArticleLike.create!(
        article_id: article.id,
        user_id: User.all.sample.id
      )
    end
    
    # Sample data for series
    5.times do |i|
      Series.create!(
        title: "Series #{i}"
      )
    end
    
    # Sample data for episodes
    5.times do |i|
      Episode.create!(
        article_id: Article.all[i].id,
        series_id: Series.first&.id || 1,
        number: i + 1
      )
    end

    # Sample data for logins
    5.times do |i|
      Login.create!(
        user_id: User.all.sample.id,
        error: nil,
        roles: "member",
        ip: "127.0.0.#{i}"
      )
    end

    # Sample data for mail_events
    5.times do |i|
      MailEvent.create!(
        accepted: rand(0..10),
        rejected: rand(0..5),
        delivered: rand(0..10),
        failed: rand(0..2),
        opened: rand(0..10),
        clicked: rand(0..5),
        unsubscribed: rand(0..2),
        complained: rand(0..1),
        stored: rand(0..10),
        total: rand(10..100),
        other: rand(0..5),
        date: Date.today - i,
        pages: rand(1..5)
      )
    end

    # Sample data for failures
    5.times do |i|
      Failure.create!(
        name: "Failure #{i}",
        details: "Details for failure #{i}",
        active: [true, false].sample
      )
    end

    # Sample data for downloads
    5.times do |i|
      Download.create!(
        access: Download::ACCESSIBILITIES.sample,
        data_file_name: "file#{i}.pdf",
        data_content_type: "application/pdf",
        data_file_size: rand(1000..10000),
        description: "Download #{i}",
        user_id: User.all.sample.id,
        year: 2025
      )
    end

    # Sample data for documents
    5.times do |i|
      Document.create!(
        title: "Document #{i}",
        subtitle: "Subtitle #{i}",
        content: "Content for document #{i}",
        content_type: Document::FORMATS.sample,
        changed_by_id: User.all.sample.id,
        authorized_by: "Authorizer #{i}",
        reason_changed: "Reason #{i}",
        is_current: true,
        url: "https://www.icu.ie/documents/#{i}.md"  # There isn't anything here I just have no clue what to put as a placeholder
      )
    end

    # Sample data for officers
    5.times do |i|
      Officer.create!(
        role: Officer::ROLES[i],
        player_id: Player.all.sample.id,
        rank: i + 1,
        executive: [true, false].sample,
        active: [true, false].sample
      )
    end

    # Sample data for pgns
    5.times do |i|
      Pgn.create!(
        comment: "Comment #{i}",
        content_type: "application/x-chess-pgn",
        file_name: "game#{i}.pgn",
        file_size: rand(1000..10000),
        game_count: rand(1..10),
        user_id: User.all.sample.id
      )
    end

    # Sample data for news_likes
    5.times do |i|
      NewsLike.create!(
        news_id: News.all[i].id,
        user_id: User.all.sample.id
      )
    end


    # # Test partial refund with free items in cart
    # test_cart = Cart.create!()

    # Fee.all.each do |fee|
    #   Item.create!(                                                                                   
    #     player_id: admin_player.id,                                                                                        
    #     fee_id: fee.id,
    #     cart_id: test_cart.id,
    #     description: "Item description",
    #     cost: fee.amount,
    #     status: "paid"
    #     )
    # end
        
    # free_fee = Fee.create!(
    #   type: Fee::TYPES.sample,
    #   name: "Free Fee",
    #   amount: 0,
    #   discounted_amount: 0,
    #   years: "2025",
    #   active: true,
    #   start_date: Date.today - 1.days,
    #   end_date: Date.today + 1.days
    # )

    # Item.create!(                                                                                   
    #   player_id: admin_player.id,                                                                                        
    #   fee_id: free_fee.id,
    #   cart_id: test_cart.id,
    #   description: "Free item",
    #   cost: 0,
    #   status: "paid"
    # )

    # intent = Stripe::PaymentIntent.create(
    #   amount: Fee.all.map{ |fee| fee.amount*100 }.sum.round,
    #   currency: "eur",
    #   payment_method: "pm_card_visa",
    #   confirm: true,
    #   return_url: "https://www.icu.ie"
    # )
    # test_cart.purchase({:payment_intent_id => intent.id, :confirmation_email => "a@a.com", :payment_name => "Name"}, admin_user)
  end
end