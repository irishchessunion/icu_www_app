FactoryBot.define do
  factory :news do
    active   { true }
    summary  { Faker::Lorem.sentence(word_count: 2) }
    headline { Faker::Lorem.sentence(word_count: 4) }
    user
    date     { Date.today }

    factory :news_extra do
      summary do 
        "Womens Officer Gearóidín Uí Laighléis has news of upcoming events both at
home and abroad.

#### Galway Blitz

There will be a Ladies Tournament (Blitz) in Galway on Sunday 20th January
in The Bridge Club. This will take place at the same time as John Alfred's
[EVT:98:monthly rapidplay]. Entries to me via [EMA:women@icu.ie].

#### Swedish Open

Also, there will be a [Ladies Open](http://www.scandinavian-chess.se/index.asp)
in Täby, Sweden from 20-25 March. Some Irish ladies have already expressed an interest.
I'm working on it &#9786;. It would be lovely if a crowd of us could go over."
      end
    end
  end
end
