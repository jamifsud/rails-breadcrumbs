module Rails
  module Breadcrumbs

    class ActionController::Base

      protected

      @add_resource_breadcrumb = false

      def add_breadcrumb(name, url = '')
        @breadcrumbs ||= []
        url = send(url) if url.is_a?(Symbol)
        @breadcrumbs << [name, url]
      end

      def self.add_breadcrumb(name, url, options = {})
        before_filter options do |controller|
          controller.send(:add_breadcrumb, name, url)
        end
      end

      def self.add_resource_breadcrumb!
        before_filter do
          @add_resource_breadcrumb = true
        end
      end

      # Automatically add the resource crumb
      def render(*args)
        # Automatically add the resource breadcrumb
        if @add_resource_breadcrumb
          resource = self.controller_name.singularize
          if self.instance_variables.include? "@#{resource}".to_sym
            resource_instance = self.instance_variable_get("@#{resource}")

            if resource_instance.new_record?
              add_breadcrumb "New #{resource.titleize}", ''
            else
              add_breadcrumb resource_instance, ''
            end
          end
        end

        super(*args)
      end

    end

    module Helper

      # Options hash accepts the following:
      # :type      => :bootstrap  (Twitter Bootstrap compatible version)
      #
      #               :list       (Basic <ul><li></li></ul>)
      #               :links      (Links separated with separator)
      # :class     => Class to assign to the ul for :type = :list
      # :separator => String representing the separator (ignored if :type => :bootstrap)
      # :li_class  => Class to add to li
      #
      # For backwards compatibility options can be a string specifying the separator to use only
      def breadcrumbs(options = {})
        if options.class == String
          separator = options

          options = Hash.new
          options[:separator] = separator
        end

        options[:separator] = "&rsaquo;" unless options[:separator]
        options[:type] = :links unless options[:type]
        options[:class] = '' unless options[:class]
        options[:li_class] = '' unless options[:li_class]

        # Assemble the array of breadcrumbs
        breadcrumb_array = @breadcrumbs.map do |txt, path|
          front_wrap = (options[:type] == :links) ? '' : '<li>';
          end_wrap = (options[:type] == :links) ? '' : '</li>';

          if options[:type] == :bootstrap
            li_class = (path.blank? || current_page?(path)) ? 'active' : ''
            end_wrap = (path.blank? || current_page?(path)) ? end_wrap : "<span class='divider'>/</span></li>"
          else
            li_class = options[:li_class]
          end

          "#{front_wrap}#{link_to_unless (path.blank? || current_page?(path)), h(txt), path}#{end_wrap}"
        end

        # Apply the active class if we're bootstrap
        if options[:type] == :bootstrap
          current = breadcrumb_array[breadcrumb_array.length - 1]
          breadcrumb_array[breadcrumb_array.length - 1] = current.sub("<span class='divider'>/</span>", "").sub("<li>", "<li class='active'>")
        end

        # Wrap the output if necessary and return it
        if options[:type] == :links
          return breadcrumb_array.join(" #{options[:separator]} ").html_safe
        else
          front_wrap = (options[:type] == :bootstrap) ? "<ul class='breadcrumb'>" : "<ul class='#{options[:class]}'>"
          end_wrap = "</ul>"

          return "#{front_wrap}#{breadcrumb_array.join('')}#{end_wrap}".html_safe
        end
      end
    end
  end
end

ActionController::Base.send(:include, Rails::Breadcrumbs)
ActionView::Base.send(:include, Rails::Breadcrumbs::Helper)
