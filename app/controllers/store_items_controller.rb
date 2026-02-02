class StoreItemsController < ApplicationController
  before_action :find_store_item, only: %i[edit update]

  def new
    new_store
  end

  def create
    if params[:barcode].present?
      params[:store_item] ||= {}
      params[:store_item][:barcode] = params[:barcode]
      new_store

      render :new
    else
      @store_item = StoreItemCreator.build(current_account, store_item_params)
      if @store_item.save
        @item_price = @store_item.item_prices.last # map element in list
        flash.now[:notice] = "Store item was successfully created."
      else
        flash.now[:alert] = "Failed to create store item."
      end
    end
  end

  def edit
    @item_price = @store_item.item_prices.find(params[:item_price_id])
    load_form_data
  end

  def update
    @store_item = current_account.store_items.find(params[:id])
    byebug
    if @store_item.update(store_item_params)
      @item_price = @store_item.item_prices.find(params[:item_price_id])
      flash.now[:notice] = "Store item was successfully updated."
    else
      flash.now[:alert] = "Failed to update store item."
    end
  end

  def store_fields
    new_store
  end

  private

  def store_item_params
    params.fetch(:store_item, {}).permit(
      :name,
      :package,
      :barcode,
      item_prices_attributes: [
        :id,
        :amount,
        :store_id,
        store_attributes: %i[id name account_id]
      ],
    )
  end

  def find_store_item
    @store_item = current_account.store_items.find(params[:id])
  end

  def load_form_data
    @stores = current_account.stores.order(:name)
    @store = @item_price.build_store if params[:add_store].present? || @stores.empty?
  end

  def new_store
    @store_item = StoreItem.new(store_item_params)
    @item_price = @store_item.item_prices.build
    load_form_data
  end
end
