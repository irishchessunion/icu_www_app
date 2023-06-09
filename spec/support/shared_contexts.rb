shared_context "features" do
  let(:active)       { I18n.t("active") }
  let(:address)      { I18n.t("address") }
  let(:any)          { I18n.t("any") }
  let(:cancel)       { I18n.t("cancel") }
  let(:category)     { I18n.t("category") }
  let(:city)         { I18n.t("city") }
  let(:comment)      { I18n.t("comment") }
  let(:confirm)      { I18n.t("confirm") }
  let(:contact)      { I18n.t("contact") }
  let(:date)         { I18n.t("date") }
  let(:delete)       { I18n.t("delete") }
  let(:description)  { I18n.t("description") }
  let(:details)      { I18n.t("details") }
  let(:edit)         { I18n.t("edit") }
  let(:either)       { I18n.t("either") }
  let(:email)        { I18n.t("email") }
  let(:file)         { I18n.t("file") }
  let(:inactive)     { I18n.t("inactive") }
  let(:last_search)  { I18n.t("last_search") }
  let(:latitude)     { I18n.t("latitude") }
  let(:longitude)    { I18n.t("longitude") }
  let(:member)       { I18n.t("member") }
  let(:name)         { I18n.t("name") }
  let(:new_one)      { I18n.t("new") }
  let(:none)         { I18n.t("none") }
  let(:notes)        { I18n.t("notes") }
  let(:please)       { I18n.t("please_select") }
  let(:save)         { I18n.t("save") }
  let(:search)       { I18n.t("search") }
  let(:season)       { I18n.t("season") }
  let(:signed_in_as) { I18n.t("session.signed_in_as") }
  let(:type)         { I18n.t("type") }
  let(:unauthorized) { I18n.t("unauthorized.default") }
  let(:year)         { I18n.t("year") }

  let(:failure)     { "div.alert-danger" }
  let(:field_error) { "div.help-block" }
  let(:success)     { "div.alert-success" }
  let(:warning)     { "div.alert-warning" }

  let(:created) { "successfully created" }
  let(:deleted) { "successfully deleted" }
  let(:updated) { "successfully updated" }

  let(:force_submit) { "\n" }
end