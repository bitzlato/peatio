class AddRidvanMigrations < ActiveRecord::Migration[5.2]
  def change
    create_table :nodes do |t|
      t.string :description, null: false
      t.string :network_key, null: false, length: 12
      t.string :url, null: false
      t.timestamps
    end
    add_index :nodes, :url, unique: true

    create_table :addresses do |t|
      t.timestamp :created_at, null: false
      t.string :network_key, length: 12, null: false
      t.citext :address, null: false
      t.string :key_encrypted, null: false
      t.string :owner_kind, length: 12, null: false, default: 'user'
    end

    add_index :addresses, [:address, :network_key], unique: true

    # TODO Проверять что адрес создается c существующим network_key
  end
end
