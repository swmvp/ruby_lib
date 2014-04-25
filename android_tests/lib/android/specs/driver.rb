# rake android[driver]
describe 'driver' do
  def is_sauce
    ENV['UPLOAD_FILE'] && ENV['SAUCE_USERNAME']
  end

  t 'load_appium_txt' do
    # __FILE__ is '(eval)' so use env var set by the Rakefile
    parsed   = Appium.load_appium_txt file: ENV['APPIUM_TXT'], verbose: true
    apk_name = File.basename parsed[:caps][:app]
    assert_equal apk_name, 'api.apk'
  end

  describe 'Appium::Driver attributes' do
    # attr_reader :default_wait, :app_path, :app_name, :selendroid,
    #            :app_package, :app_activity, :app_wait_activity,
    #            :sauce_username, :sauce_access_key, :port, :os, :debug
    t 'default_wait attr' do
      set_wait 1
      default_wait.must_equal 1
      set_wait # restore default
    end

    t 'app_path attr' do
      apk_name = File.basename driver_attributes[:caps][:app]
      apk_name.must_equal 'api.apk'
    end

    # Only used for Sauce Labs
    t 'verify all attributes' do
      2.times { set_wait 1 } # must set twice to validate last_waits
      actual              = driver_attributes
      actual[:caps][:app] = File.basename actual[:caps][:app]
      expected            = { caps:             { platformName: 'android',
                                                  app:          'api.apk' },
                              custom_url:       false,
                              export_session:   false,
                              default_wait:     1,
                              last_waits:       [1, 1],
                              sauce_username:   nil,
                              sauce_access_key: nil,
                              port:             4723,
                              device:           'android',
                              debug:            true }

      actual.must_equal expected
    end
  end

  describe 'Appium::Driver' do
    t '@@loaded' do
      loaded = $driver.class.class_variable_get :@@loaded
      loaded.must_equal true
    end

    t '$driver.class' do
      $driver.class.must_equal Appium::Driver
    end

    t 'absolute_app_path' do
      def absolute_app_path path;
        $driver.class.absolute_app_path path;
      end

      def validate_path path;
        absolute_app_path(path).must_equal path;
      end

      validate_path 'sauce-storage:some_storage_suffix'
      validate_path 'http://www.saucelabs.com'

      # fake real paths for osx/windows.
      FakeFS.activate!

      osx_existing_path = '/Users/user/myapp.app'
      FileUtils.mkdir_p osx_existing_path
      validate_path osx_existing_path

      # TODO: FakeFS fails on Windows paths due to the drive letters.
      # Look into how opscode/chef tests this.
      # windows_existing_path = "C:\\Program Files\\myapp.apk"
      # FileUtils.mkdir_p windows_existing_path
      # validate_path windows_existing_path

      FakeFS.deactivate!

      # bundle id test
      validate_path 'my.bundle.id'

      # relative path test
      relative_path = File.join __FILE__, ('..' + File::SEPARATOR) * 4, 'api.apk'
      expected_path = File.expand_path relative_path

      absolute_app_path(relative_path).must_equal expected_path

      # invalid path test
      invalid_path_errors = false
      begin
        absolute_app_path('../../does_not_exist.apk')
      rescue Exception
        invalid_path_errors = true
      ensure
        invalid_path_errors.must_equal true
      end
    end
  end

  describe 'methods' do
    t 'status' do
      appium_server_version['build'].keys.sort.must_equal %w(revision version)
    end

    t 'server_version' do
      server_version = appium_server_version['build']['version']
      if is_sauce
        server_version.must_match 'Sauce OnDemand'
      else
        server_version.must_match /(\d+)\.(\d+).(\d+)/
      end
    end

=begin
  Skip:
    ios_capabilities # save for iOS tests
    absolute_app_path # tested already by starting the driver for this test
    server_url # sauce labs only
=end
    t 'restart' do
      set_wait 1 # ensure wait is 1 before we restart.
      restart
      mobile(:currentActivity).must_equal '.ApiDemos'
    end

    t 'driver' do
      driver.browser.must_equal :Android
    end

=begin
  Skip:
    screenshot   # this is slow and already tested by Appium
    driver_quit  # tested by restart
    start_driver # tested by restart
    no_wait  # posts value to server, it's not stored locally
    set_wait # posts value to server, it's not stored locally
=end
    t 'default_wait' do
      set_wait 1
      default_wait.must_equal 1
    end

    # returns true unless an error is raised
    t 'exists' do
      exists(0, 0) { true }.must_equal true
      exists(0, 0) { raise 'error' }.must_equal false
    end

    # any script
    t 'execute_script' do
      execute_script('mobile: currentActivity').must_equal '.ApiDemos'
    end

    # any mobile method
    t 'mobile' do
      mobile(:currentActivity).must_equal '.ApiDemos'
    end

    # any elements
    t 'find_elements' do
      find_elements(:tag_name, :text).length.must_equal 12
    end

    # any element
    t 'find_element' do
      find_element(:tag_name, :text).class.must_equal Selenium::WebDriver::Element
    end

    # Skip: x # x is only used in Pry
  end
end
