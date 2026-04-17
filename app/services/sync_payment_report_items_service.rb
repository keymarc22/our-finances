# Service responsible for synchronising the items of a PaymentReport.
#
# Incoming items are upserted (created or updated) and any persisted item
# whose ID is not present in the incoming list is destroyed.
#
# When an item is marked with +save_as_monthly_bill: true+ and has not yet
# been linked to a MonthlyBill, the service also creates the corresponding
# MonthlyBill and stores the association.
#
# @example
#   SyncPaymentReportItemsService.new(
#     account: current_account,
#     report: @report,
#     items_params: params[:items]
#   ).call
class SyncPaymentReportItemsService
  # @param account [Account] the authenticated user's account
  # @param report  [PaymentReport] the report whose items will be synced
  # @param items_params [Array<Hash>] raw item parameters from the request
  def initialize(account:, report:, items_params:)
    @account       = account
    @report        = report
    @items_params  = Array(items_params)
  end

  # Syncs the report items according to +items_params+.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] if any record fails validation
  def call
    destroy_removed_items
    @items_params.each { |item_params| upsert_item(item_params) }
  end

  private

  # Destroys items that are no longer present in the incoming params.
  def destroy_removed_items
    incoming_ids = @items_params.filter_map { |i| i[:id].presence&.to_i }
    @report.payment_report_items.where.not(id: incoming_ids).destroy_all
  end

  # Creates or updates a single report item and, when requested, links it to a
  # newly created MonthlyBill.
  #
  # @param item_params [Hash] parameters for one item
  # @return [PaymentReportItem]
  def upsert_item(item_params)
    attrs = build_attrs(item_params)

    item = if item_params[:id].present?
      @report.payment_report_items.find(item_params[:id]).tap { |i| i.update!(attrs) }
    else
      @report.payment_report_items.create!(attrs)
    end

    create_monthly_bill_if_needed(item)
    item
  end

  # Builds the attribute hash from raw item params.
  #
  # @param item_params [Hash]
  # @return [Hash]
  def build_attrs(item_params)
    {
      name:                item_params[:name].to_s.strip,
      amount_cents:        (item_params[:amount].to_f * 100).round,
      amount_currency:     item_params[:currency].presence || "USD",
      save_as_monthly_bill: item_params[:save_as_monthly_bill].in?([true, "true", "1"])
    }
  end

  # Creates a MonthlyBill for the item when +save_as_monthly_bill+ is true and
  # the item is not yet linked to one.
  #
  # @param item [PaymentReportItem]
  # @return [void]
  def create_monthly_bill_if_needed(item)
    return unless item.save_as_monthly_bill && item.monthly_bill_id.nil?

    bill = @account.monthly_bills.create!(
      name:             item.name,
      amount_cents:     item.amount_cents,
      amount_currency:  item.amount_currency
    )
    item.update_column(:monthly_bill_id, bill.id)
  end
end

