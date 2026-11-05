require 'rails_helper'

describe Util::PrevNext do
  let(:news)    { create_list(:news, 3) }
  let(:session) { { last_search_list_news: "_#{news.map(&:id).join('_')}_" } }

  it "finds the neighbours of the current item" do
    prev_next = Util::PrevNext.new(session, News, news[1].id.to_s)
    expect(prev_next.prev_id).to eq news[0].id
    expect(prev_next.next_id).to eq news[2].id
  end

  it "treats an id with junk after it as the plain id" do
    prev_next = Util::PrevNext.new(session, News, "#{news[1].id}-1)) OR 977=(SELECT 977 FROM PG_SLEEP(15))--")
    expect(prev_next.curr_id).to eq news[1].id
    expect(prev_next.prev_id).to eq news[0].id
  end
end
