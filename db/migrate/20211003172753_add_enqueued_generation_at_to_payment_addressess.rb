class AddEnqueuedGenerationAtToPaymentAddressess < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_addresses, :enqueued_generation_at, :timestamp
  end
end
