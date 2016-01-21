class CreateDownloadVdos < ActiveRecord::Migration
  def change
    create_table :download_vdos do |t|
      t.string :video_name
      t.string :url
      t.string :uid


      t.timestamps
    end
  end
end
