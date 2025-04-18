class CreateProjectInvoices < ActiveRecord::Migration[6.0]
  def change
    create_table :project_invoices do |t|
      t.references :project
      t.string :invoice_no
      t.datetime :payment_date
      t.decimal :amount, precision: 10, scale: 2
      t.string :file
      t.timestamps null: false
    end
  end
end
