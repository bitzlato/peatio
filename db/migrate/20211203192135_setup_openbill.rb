class SetupOpenbill < ActiveRecord::Migration[5.2]
  DIR = './vendor/openbill/migrations'
  def up
    Dir.entries(DIR).select{|f| File.file? DIR+ f }.sort.each do |file|
      say_with_time "Migrate with #{file}" do
        execute File.read DIR + file
      end
    end
  end
end
