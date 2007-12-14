require 'active_record'

module Multiup
  module Acts #:nodoc:
    module Slugable #:nodoc:

      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Generates a URL slug based on provided fields and adds <tt>after_validation</tt> callbacks.
        #
        #   class Page < ActiveRecord::Base
        #     acts_as_slugable :source_column => :title, :target_column => :url_slug, :scope => :parent
        #   end
        #
        # Configuration options:
        # * <tt>source_column</tt> - specifies the column name used to generate the URL slug
        # * <tt>slug_column</tt> - specifies the column name used to store the URL slug
        # * <tt>scope</tt> - Given a symbol, it'll attach "_id" and use that as the foreign key 
        #   restriction. It's also possible to give it an entire string that is interpolated if 
        #   you need a tighter scope than just a foreign key.
        def acts_as_slugable(options = {})
          configuration = { :source_column => 'name', :slug_column => 'url_slug', :scope => nil}
          configuration.update(options) if options.is_a?(Hash)
          
          configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/

          if configuration[:scope].is_a?(Symbol)
            scope_condition_method = %(
              def slug_scope_condition
                if #{configuration[:scope].to_s}.nil?
                  "#{configuration[:scope].to_s} IS NULL"
                else
                  "#{configuration[:scope].to_s} = \#{#{configuration[:scope].to_s}}"
                end
              end
            )
          elsif configuration[:scope].nil?
            scope_condition_method = "def slug_scope_condition() \"1 = 1\" end"
          else
            scope_condition_method = "def slug_scope_condition() \"#{configuration[:scope]}\" end"
          end
          
          class_eval <<-EOV
            include Multiup::Acts::Slugable::InstanceMethods
          
            def acts_as_slugable_class
              ::#{self.name}
            end

            def source_column
              "#{configuration[:source_column]}"
            end

            def slug_column
              "#{configuration[:slug_column]}"
            end
            
            #{scope_condition_method}
          
            after_validation :create_slug
          EOV
        end
      end

      # Adds instance methods.
      module InstanceMethods
        private
          # URL slug creation logic
          #
          # The steps are roughly as follows
          # 1. If the record hasn't passed its validations, exit immediately
          # 2. If the <tt>source_column</tt> is empty, exit immediately (no error is thrown - this should be checked with your own validation)
          # 3. If the <tt>url_slug</tt> is already set we have nothing to do, otherwise
          #    a. Strip out punctuation
          #    b. Replace unusable characters with dashes
          #    c. Clean up any doubled up dashes
          #    d. Check if the slug is unique and, if not, append a number until it is
          #    e. Save the URL slug      
          def create_slug
            return if self.errors.length > 0
            
            if self[source_column].nil? or self[source_column].empty?
              return
            end

            if self[slug_column].to_s.empty?
              test_string = self[source_column]

              #strip out common punctuation
              proposed_slug = test_string.strip.downcase.gsub(/[\'\"\#\$\,\.\!\?\%\@\(\)]+/, '')

              #replace ampersand chars with 'and'
              proposed_slug = proposed_slug.gsub(/&/, 'and')

              #replace non-word chars with dashes
              proposed_slug = proposed_slug.gsub(/[\W^-_]+/, '-')

              #remove double dashes
              proposed_slug = proposed_slug.gsub(/\-{2}/, '-')

              suffix = ""
              existing = true
              acts_as_slugable_class.transaction do
                while existing != nil
                  # look for records with the same url slug and increment a counter until we find a unique slug
                  existing = acts_as_slugable_class.find(:first, :conditions => ["#{slug_column} = ? and #{slug_scope_condition}",  proposed_slug + suffix])
                  if existing
                    if suffix.empty?
                      suffix = "-0"
                    else
                      suffix.succ!
                    end
                  end
                end
              end # end of transaction         
              self[slug_column] = proposed_slug + suffix
            end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Multiup::Acts::Slugable
end
