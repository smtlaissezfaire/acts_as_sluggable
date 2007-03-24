require File.dirname(__FILE__) + '/test_helper'

#require File.join(File.dirname(__FILE__), 'abstract_unit')
require File.join(File.dirname(__FILE__), 'fixtures/page')

#require 'breakpoint'

class ActsAsSlugableTest < Test::Unit::TestCase
  fixtures :pages

  def setup
    @allowable_characters = Regexp.new("^[A-Za-z0-9_-]+$")
  end

  def test_hooks_presence
    assert Page.after_validation.include?(:create_slug)
    assert Page.after_validation.include?(:create_slug)
  end

  def test_create
    # create, with title
    pg = Page.create(:title => "Creation")
    assert pg.valid?
    assert_equal "creation", pg.url_slug

    # create, with title and url_slug
    pg = Page.create(:title => "Test overrride", :parent_id => nil, :url_slug => "something-different")
    assert pg.valid?
    assert_equal "something-different", pg.url_slug
  end
  
  def test_validations_still_working
    # create, with nil title
    pg = Page.create(:title => nil)
    assert !pg.valid?
    assert pg.errors.on(:title)


    # create, with blank title
    pg = Page.create(:title => '')
    assert !pg.valid?
    assert pg.errors.on(:title)
  end

  def test_update
  return
    pg = Page.create(:title => "Slug update")
    pg.save
    assert_equal "slug-update", pg.url_slug

    # update, with title
    pg.update_attribute(:title, "Updated title only")
    assert_equal "slug-update", pg.url_slug

    # update, with title and nil slug
    pg.update_attributes(:title => "Updated title and slug to nil", :url_slug => nil)
    assert_equal "updated-title-and-slug-to-nil", pg.url_slug
    
    # update, with empty slug
    pg.update_attributes(:title => "Updated title and slug to empty", :url_slug => '')
    assert_equal "updated-title-and-slug-to-empty", pg.url_slug
  end

  def test_uniqueness
    # create two pages with the same title and 
    # within the same scope - slugs should be unique
    t = "Unique title"

    pg1 = Page.create(:title => t, :parent_id => 1)
    assert pg1.valid?
    
    pg2 = Page.create(:title => t, :parent_id => 1)
    assert pg2.valid?
    
    assert_not_equal pg1.url_slug, pg2.url_slug
  end

  def test_scope
    # create two pages with the same title
    # but not in the same scope - slugs should be the same
    title = "Unique scoped title"

    pg1 = Page.new(:title => title, :parent_id => 1)
    pg1.save
    
    pg2 = Page.new(:title => title, :parent_id => 2)
    pg2.save

    assert_equal pg1.url_slug, pg2.url_slug
  end

  def test_characters
    return
    check_for_allowable_characters "Title"
    check_for_allowable_characters "Title and some spaces"
    check_for_allowable_characters "Title-with-dashes"
    check_for_allowable_characters "Title-with'-$#)(*%symbols"
    check_for_allowable_characters "/urltitle/"
    check_for_allowable_characters "calculé en française"
  end

  private
    def check_for_allowable_characters(title)
      pg = Page.new(:title => title)
      pg.save
      assert_match @allowable_characters, pg.url_slug  
    end
end
