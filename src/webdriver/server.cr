require "http/client"
require "log"
require "json"
require "./command"
require "./windows"
require "./wait"
require "./element"
require "./document"
require "./cookies"
require "./alerts"

# mixin for browser navigation
module Webdriver
  module BrowserNavigation

    # visits the *url*
    # `browser.goto "https://www.google.com"`
    def goto(url : String)
      server.command.visit_url(url)
    end

    # get the current url
    def url
      server.command.get_url
    end

    # navigates back
    def back
      server.command.go_back
    end

    # gets the title
    def title
      server.command.get_title
    end

    # navigates forward
    def forward
      server.command.go_forward
    end

    # refreshes the browser page
    def refresh
      server.command.refresh
    end
  end

  module BrowserWindow
    # maximizes the browser window
    def maximize
      server.command.maximize_window
    end

    # minimizes the browser window
    def minimize
      server.command.minimize_window
    end

    # makes the browser window fullscreen
    def fullscreen
      server.command.fullscreen_window
    end
  end

  class Browser
    include BrowserNavigation
    include BrowserWindow
    include Document
    include Cookies
    include Alerts
    include Dom::Container

    getter :server, :windows

    # starts the *browser* browser with options
    def self.start(browser = :chrome, **opts)
      Server.new(browser, **opts).run!
    end

    def initialize(@server : Server)
      window_handle = current_window_handle
      @windows = Windows.new([Window.new(window_handle)], command: server.command)
    end

    # switches context to the *window*
    def use(window : Window)
      server.command.use_window(window.handle)
    end

    # closes *window*:
    #
    # will try to switch the previous window/tab:
    #
    # if there is only one window, closing it will quit the browser
    def close(window : Window)
      use(window)
      server.command.delete_window
      window_index = windows.index(window)
      windows.remove(window)
      if window_index
        switch_to = windows.find_closest_index(window_index)
        switch_to.nil? ? quit : use(windows[switch_to])
      end
    end

    # takes a screenshot
    def screenshot
      server.command.capture_screenshot.as_s
    end

    # stops the browser session
    def quit
      server.command.delete_session
    end

    private def current_window_handle
      server.command.get_window_handle.as_s
    end
  end

  class Server
    @@process : Process?
    @remote : String?

    getter :command

    def initialize(browser : Symbol, *,
      @host = "127.0.0.1",
      @role = "standalone",
      @port = "4444",
      @timeout = "30",
      @remote = nil,
      @background = true,
      @args : Array(String)? = nil,
      @capabilities : Capabilities::Base = Capabilities::Base.default(browser, args: args)
    )
      @browser = browser
      @command = Command.new(service_url)
    end

    def driver_mapping
      {
        chrome: "chromedriver",
        firefox: "geckodriver"
      }
    end
    
    def driver_command
      command = driver_mapping[@browser]
      raise "#{@browser} not supported" unless command
      command
    end

    def service_url
      @remote || "http://#{@host}:#{@port}"
    end

    def args 
      ["--host=#{@host}", "--port=#{@port}"]
    end

    def ready?
      command.session_status["ready"]
    end

    def wait_until_ready
      Webdriver::Wait.wait_until(interval: 0.5, timeout: 30, object: self, &.ready?) 
    end
    
    def run!
      Log.info { "Starting #{driver_command} with #{args}" }
      unless @remote
        @@process ||= Process.new(driver_command, args, output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
      end
      wait_until_ready
      start_session!
    end

    def start_session!
      @command.start_session(@capabilities)
      Browser.new(self)
    end
  end
end