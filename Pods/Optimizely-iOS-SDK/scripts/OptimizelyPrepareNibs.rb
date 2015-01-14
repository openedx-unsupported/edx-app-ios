"""
This installation script adds a unique OptimizelyID as a UserDefinedRuntimeAttribute to all standard UIView subclasses within
.storyboard and .xib files contained in an XCode project. Optimizely uses these OptimizelyIDs to identify views
in the web editor.

This script is run as a custom script during a project build phase. More information can be found at:
http://developers.optimizely.com/ios/

To remove the OptimizelyID tags added by this script, email support@optimizely.com.

"""

script_name = File.basename(__FILE__)
# Add local Ruby folder to load path
$LOAD_PATH.unshift("#{ENV['HOME']}/.gem/ruby/#{RUBY_VERSION}") unless $LOAD_PATH.include?("#{ENV['HOME']}/.gem/ruby/#{RUBY_VERSION}")

begin
  require 'rubygems'
rescue LoadError => e
  abort "error: Please install the RubyGems package manager: https://rubygems.org/pages/download"
end

begin
    gem 'nokogiri', '~>1.5.2'
    require 'nokogiri'
rescue LoadError => e
    puts "Dependency 'nokogiri' not satisfied; installing..."
    begin
      success = system('gem install --user-install nokogiri --version "~>1.5.2"')
      if not success # Propogate system call exceptions back to program
        raise $?
      end
    rescue Exception => e
      abort "error: Encountered exception #{e} while installing dependency 'nokogiri'.\n
            run 'gem install --user-install nokogiri --version \"~>1.5.2\""
            # Nokogiri 1.6.1 won't work for Xcode 5.1 command line tools. Will need to
            # ignore unused command line arguments.
            # http://stackoverflow.com/a/22703901/2014694
    end
end

begin
    require 'pathname'
rescue LoadError
    puts "Dependency 'pathname' not satisfied; installing..."
    begin
      # Propogate system call exceptions back to program
      success = system('gem install --user-install pathname')
      if not success
        raise $?
      end
    rescue Exception => e
      abort "error: Encountered exception #{e} while installing dependency 'pathname'.\n
            run 'gem install --user-install pathname' to install pathname."
    end
end

class Old_format
    @@view_classes = [
                  'IBUIActivityIndicatorView',
                  'IBUIButton',
                  'IBUICollectionView',
                  'IBUICollectionViewCell',
                  'IBUIDatePicker',
                  'IBUIImageView',
                  'IBUILabel',
                  'IBUINavigationBar',
                  'IBUIPageControl',
                  'IBUIPickerView',
                  'IBUIProgressView',
                  'IBUIScrollView',
                  'IBUISearchBar',
                  'IBUISegmentedControl',
                  'IBUISlider',
                  'IBUIStepper',
                  'IBUISwitch',
                  'IBUITabBar',
                  'IBUITableView',
                  'IBUITableViewCell',
                  'IBUITableViewCellContentView',
                  'IBUITextField',
                  'IBUITextView',
                  'IBUIToolbar',
                  'IBUIView',
                  'IBUIWebView'
              ]

    def initialize(file_path)
        """
        The following steps are taken to generate an OptimizelyID userDefinedAttribute:
          1. Search for all Optimizely-supported views.
          2. Obtain the ID associated with each view object.
          3. Search for the corresponding 'objectID' of IBObjectRecord objects, as referenced
             by the ID obtained from step 2.

        Add this userDefinedAttribute tag after all of the information above are obtained.
        """
        @views = []
        file = File.new(file_path, "r")
        dom = Nokogiri.XML(file)

        file_name = Pathname.new(file_path).basename.sub_ext('')

        # Get all view nodes in this file that Optimizely supports
        @@view_classes.each { |tag| @views << dom.xpath("//object[@class=\"#{tag}\"]") }

        file_change_made = false
        @views.each do |view_class|
            if view_class.empty? # File doesn't contain a particular Optimizely view. Skip
                next
            end
            file_change_made = true

            view_node_tag = view_class.first()

            object_records_array = dom.xpath("//object[@key=\"objectRecords\"]")

            # used as DOM root from which userDefinedRuntimeAttributes will be added
            flattened_properties_array = dom.xpath("//*[@key=\"flattenedProperties\" and @class=\"NSMutableDictionary\"]")

            view_class.each do |view_node| # Iterate through each of the views of particular class type
                view_node_class = view_node.attribute('class')
                view_node_ref_num = view_node.attribute('id')

                optimizely_id = "_#{file_name}-#{view_node_class}-#{view_node_ref_num}"

                # Get objectID with corresponding reference number
                reference_node_of_IBObjectRecord = object_records_array.xpath("//object[@class=\"IBObjectRecord\"]//reference[@key=\"object\" and @ref=\"#{view_node_ref_num}\"]").first()
                begin
                  ib_object_record = reference_node_of_IBObjectRecord.parent()
                  object_id_node = ib_object_record.xpath("int[@key=\"objectID\"]").first()
                  object_id = object_id_node.content()
                rescue Exception => e
                  # Cannot add OptimizelyID if object_id unobtainable
                  $stderr.puts "Encountered exception with view node class: #{view_node_class}; view node reference number: #{view_node_ref_num}. \
                  \nSkipping tag for this view..."
                  next
                end

                # Create <object class="NSMutableDictionary"> as outermost container
                placeholder_key = "#{object_id}.IBAttributePlaceholdersKey"
                object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey = flattened_properties_array.xpath("object[@class=\"NSMutableDictionary\" and @key=\"#{placeholder_key}\"]").first()
                if object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.nil?
                    object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey = Nokogiri::XML::Node.new("object", dom)
                    object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.set_attribute("class", "NSMutableDictionary")
                    object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.set_attribute("key", "#{placeholder_key}")
                    flattened_properties_array.after(object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey)
                end

                # Create <string key="NS.key.0"> as second layer
                string_with_key_NSkey0 = object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.xpath("string[@key=\"NS.key.0\"]").first()
                string_with_key_NSkey0 = object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.xpath("string[@key=\"NS.key.0\"]").first()
                if string_with_key_NSkey0.nil?
                    string_with_key_NSkey0 = Nokogiri::XML::Node.new("string", dom)
                    string_with_key_NSkey0.set_attribute("key", "NS.key.0")
                    string_with_key_NSkey0.content = "IBUserDefinedRuntimeAttributesPlaceholderName"
                    object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.add_child(string_with_key_NSkey0)
                end

                # Create <object class="IBUIUserDefinedRuntimeAttributesPlacholder" key="NS.object.0">
                object_with_class_IBUIUserDefRuntimeAttribPlaceholder = object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.xpath("object[@class=\"IBUIUserDefinedRuntimeAttributesPlaceholder\" and \
                                                                                                           @key=\"NS.object.0\"]").first()
                if object_with_class_IBUIUserDefRuntimeAttribPlaceholder.nil?
                    object_node = Nokogiri::XML::Node.new("object", dom)
                    object_node.set_attribute("class", "IBUIUserDefinedRuntimeAttributesPlaceholder")
                    object_node.set_attribute("key", "NS.object.0")
                    object_with_class_NSMutableDictionary_key_IBAttributePlaceholdersKey.add_child(object_node)
                    object_with_class_IBUIUserDefRuntimeAttribPlaceholder = object_node
                end

                # Contents of <object class="IBUIUserDefinedRuntimeAttributesPlaceholder key="NS.object.0">
                string_with_key_name = object_with_class_IBUIUserDefRuntimeAttribPlaceholder.xpath("string[@key=\"name\"]").first()
                if string_with_key_name.nil?
                    string_with_key_name = Nokogiri::XML::Node.new("string", dom)
                    string_with_key_name.set_attribute("key", "name")
                    string_with_key_name.content = "IBUserDefinedRuntimeAttributesPlaceholderName"
                    object_with_class_IBUIUserDefRuntimeAttribPlaceholder.add_child(string_with_key_name)
                end
                reference_with_key_object = object_with_class_IBUIUserDefRuntimeAttribPlaceholder.xpath("reference[@key=\"object\" and @ref=\"#{view_node_ref_num}\"]").first()
                if reference_with_key_object.nil?
                    reference_with_key_object = Nokogiri::XML::Node.new("reference", dom)
                    reference_with_key_object.set_attribute("key", "object")
                    reference_with_key_object.set_attribute("ref", "#{view_node_ref_num}")
                    object_with_class_IBUIUserDefRuntimeAttribPlaceholder.add_child(reference_with_key_object)
                end
                array_with_key_userDefinedRuntimeAttributes = object_with_class_IBUIUserDefRuntimeAttribPlaceholder.xpath("array[@key=\"userDefinedRuntimeAttributes\"]").first()
                if array_with_key_userDefinedRuntimeAttributes.nil?
                    array_with_key_userDefinedRuntimeAttributes = Nokogiri::XML::Node.new("array", dom)
                    array_with_key_userDefinedRuntimeAttributes.set_attribute("key", "userDefinedRuntimeAttributes")
                    object_with_class_IBUIUserDefRuntimeAttribPlaceholder.add_child(array_with_key_userDefinedRuntimeAttributes)
                end

                # Add OptimizelyID node
                object_containing_optimizelyID = array_with_key_userDefinedRuntimeAttributes.xpath("object[@class=\"IBUserDefinedRuntimeAttribute\"]").first()
                if object_containing_optimizelyID.nil?
                    object_containing_optimizelyID = Nokogiri::XML::Node.new("object", dom)
                    object_containing_optimizelyID.set_attribute("class", "IBUserDefinedRuntimeAttribute")

                    # add object's contents
                    string_node_typeID = Nokogiri::XML::Node.new("string", dom)
                    string_node_typeID.set_attribute("key", "typeIdentifier")
                    string_node_typeID.content = "com.apple.InterfaceBuilder.userDefinedRuntimeAttributeType.string"

                    string_node_key_path = Nokogiri::XML::Node.new("string", dom)
                    string_node_key_path.set_attribute("key", "keyPath")
                    string_node_key_path.content = "optimizelyId"

                    string_node_key_value = Nokogiri::XML::Node.new("string", dom)
                    string_node_key_value.set_attribute("key", "value")
                    string_node_key_value.content = optimizely_id

                    [string_node_typeID, string_node_key_path, string_node_key_value].each do |child|
                        object_containing_optimizelyID.add_child(child)
                    end
                    array_with_key_userDefinedRuntimeAttributes.add_child(object_containing_optimizelyID)
                end

            end
        end

      # Write new modified contents out to original file
      if file_change_made
        begin
          File.open("#{file_path}", 'w') { |f| f.write(dom.to_xml(:indent => 1)) }
        rescue Exception => e
          puts "Failed to save changes to #{file_path}"
          puts "Check write permission on file."
        end
      end
    end

end

class New_format
  @@view_classes = ["activityIndicatorView",
                 "button",
                 "collectionView",
                 "collectionViewCell",
                 "datePicker",
                 "imageView",
                 "label",
                 "navigationBar",
                 "pageControl",
                 "pickerView",
                 "progressView",
                 "scrollView",
                 "searchBar",
                 "segmentedControl",
                 "slider",
                 "stepper",
                 "switch",
                 "tabBar",
                 "tableView",
                 "tableViewCell",
                 "tableViewCellContentView",
                 "textField",
                 "textView",
                 "toolbar",
                 "view",
                 "webView"]

  def initialize(file_path)
      """
      Search file for each of the different views specified in @@view_classes. Under each view object,
      add a userDefinedRuntimeAttribute containing an OptimizelyID.

      OptimizelyID tags are structured as _[file name]-[view object]-[view tag ID]
      """
      @views_classes_in_file = []
      file = File.new(file_path, "r")
      dom = Nokogiri.XML(file) do |config|
        config.default_xml.noblanks
      end

      file_name = Pathname.new(file_path).basename.sub_ext('')

      # Get all view nodes in this file that Optimizely supports
      @@view_classes.each { |tag| @views_classes_in_file << dom.xpath("//#{tag}") }

      file_change_made = false
      @views_classes_in_file.each do |view_class|
          if view_class.empty? # File doesn't contain a particular Optimizely view class. Skip
              next
          end

          file_change_made = true
          view_node_tag = view_class.first().name() # Used for OptimizelyID tag

          # A file may contain multiple view objects of the same class. Need to tag each separately.
          # For example, a file may contain multiple button objects. Thus, iterate through and process each button object.
          view_class.each do |view_node|
              view_node_id = view_node.attribute('id')
              value = "_#{file_name}-#{view_node_tag}-#{view_node_id}"

              userDefinedRuntimeAttributes_node = view_node.xpath('userDefinedRuntimeAttributes').first()

              if userDefinedRuntimeAttributes_node.nil? # Search for the <userDefinedRuntimeAttrs> tag, which encloses <userDefinedRuntimeAttribute>
                  userDefinedRuntimeAttributes_node = Nokogiri::XML::Node.new("userDefinedRuntimeAttributes", dom)
                  view_node.add_child(userDefinedRuntimeAttributes_node)
              end

              optimizely_id_node = userDefinedRuntimeAttributes_node.xpath('userDefinedRuntimeAttribute[@keyPath="optimizelyId"]').first()
              if optimizely_id_node.nil?
                  optimizely_id_node = Nokogiri::XML::Node.new("userDefinedRuntimeAttribute" , dom)
                  optimizely_id_node.set_attribute("type", "string")
                  optimizely_id_node.set_attribute("keyPath", "optimizelyId")
                  optimizely_id_node.set_attribute("value", value)

                  userDefinedRuntimeAttributes_node.add_child(optimizely_id_node)
              end
          end
      end

      # Write new modified contents out to original file
      if file_change_made
        begin
          File.open("#{file_path}", 'w') { |f| f.write(dom.to_xml(:indent => 4)) }

        rescue Exception => e
          puts "Failed to save changes to #{file_path}"
          puts "Check write permission on file."
        end
      end
  end

end

def process_view_file(file_path)
    """
    There are two different sets of view objects. Each set is structured differently,
    and thus must be handled separately.
    """
    New_format.new(file_path)
    Old_format.new(file_path)
end

def install_optimizely(file_path)
    puts "Installing Optimizely in #{file_path}"
    process_view_file(file_path)
end

def get_view_files(project_dir)
    Dir.chdir(project_dir)
    view_files = Dir.glob('**/*.{storyboard,xib}')
    return view_files
end

def get_full_path(project_dir, matches)
    return matches.map { |match| File.join(project_dir, match) }
end

def main()
    """
    Searches for all *.{xib, storyboard} files in project directory and adds OptimizelyIDs to all UIView objects
    in the files.
    """

    project_dir = ENV["SRCROOT"]
    if project_dir.nil?
      project_dir = File.dirname(__FILE__)
    end

    view_files = get_full_path(project_dir, get_view_files(project_dir))
    puts "Configuring OptimizelyIDs for the following files:"
    view_files.each { |path| puts(path) }
    view_files.each { |path| install_optimizely(path) }

end

main()
