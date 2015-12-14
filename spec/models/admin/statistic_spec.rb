require 'rails_helper'

describe Admin::Statistic do
  let(:users) { Admin::Statistic.users }
  let(:logins) { Admin::Statistic.logins }
  let(:unique_logins) { Admin::Statistic.unique_logins }

  it 'users' do
    expect(users.name).to eq 'Viewers'
    expect(users.hour).to eq 0
  end

  it 'logins' do
    expect(logins.name).to eq 'Logins'
    expect(logins.hour).to eq 0
  end

  it 'unique_logins' do
    expect(unique_logins.name).to eq 'Unique Logins'
    expect(unique_logins.hour).to eq 0
  end
end
