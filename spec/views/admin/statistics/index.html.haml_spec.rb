require 'rails_helper'

RSpec.describe "admin/statistics/index", type: :view do
  before(:each) do
    assign(:statistics, [
      Admin::Statistic.new(name: 'Logins', hour: 2, day: 4, week: 10, month: 23, year: 50, forever: 51),
      Admin::Statistic.new(name: 'Users', hour: 2, day: 4, week: 10, month: 23, year: 50, forever: 51),
    ])
  end

  it "renders a list of admin/statistics" do
    render
    assert_select "tr>td", :text => "10", :count => 2
  end
end
