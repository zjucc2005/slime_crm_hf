class CreateIndustries < ActiveRecord::Migration[6.0]
  def change
    create_table :industries do |t|
      t.string :name

      t.timestamps :null => false
    end
  end
end
