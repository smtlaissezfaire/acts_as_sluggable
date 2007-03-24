class Page < ActiveRecord::Base
  validates_length_of :title, :minimum => 2
  validates_presence_of :title
  acts_as_slugable :source_column => :title, :target_column => :url_slug, :scope => :parent
end