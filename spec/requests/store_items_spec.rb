require 'rails_helper'

RSpec.describe "StoreItems", type: :request, sign_in: true do
  let(:user)        { @user }
  let(:account)     { user.account }
  let(:store_item)  { create(:store_item, account: account) }

  it "POST /store_items creates a store item" do
    expect {
      post store_items_path, params: { store_item: {
        name: "Nuevo",
        package: "unit",
        barcode: "654321",
        item_prices_attributes: { "0" => { amount: "15.5", store_attributes: { name: 'Nueva', account_id: account.id } } }
      } }
    }.to change(StoreItem, :count).by(1)
  end

  it "PATCH /store_items/:id updates a store item" do
    patch store_item_path(store_item), params: { store_item: { name: "Modificado" } }
    expect(store_item.reload.name).to eq("Modificado")
  end
end
