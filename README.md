![](https://img.shields.io/gem/v/shoot.svg)
![](https://img.shields.io/codeclimate/github/joaomilho/shoot.svg)

# Shoot

Shoot is a helper library to take screenshots using [BrowserStack](https://www.browserstack.com/). If you don't need a full integration test coupled with screenshots, it's a simpler choice.

## Installation

Add this line to your application's Gemfile:

```ruby
group :test do
  gem 'shoot'
end
```

And then execute:

    $ bundle

Also add the following environment variables: `BROWSERSTACK_USER` and `BROWSERSTACK_KEY`. The way you do it is up to you (we recommend either dotenv or an export in your personal files).

## Usage

Shoot installs a binary. To inspect it, just run:

    $ shoot
    
The first thing you should do is:
 
    $ shoot list
	ID   OS #                Browser #     Device
	0    OS X Snow Leopard   safari 5.1
	1    OS X Snow Leopard   chrome 14.0
	2    OS X Snow Leopard   chrome 16.0
	...
	537  ios 7.0             ipad          iPad mini Retina
	538  ios 7.0             iphone        iPhone 5S
	539  ios 7.0             iphone        iPhone 5C
	
The `list` command basically fetches all browsers available on [BrowserStack](https://www.browserstack.com/) and caches them locally on `.screenshots/.browsers.json`. You can choose to add this folder on your `.gitignore`, since shoot will save all images there as well.

Then, you can choose to activate the browsers you wanna use, based on id. Example:

	$ shoot activate 2

Now, create a scenario. Here's an example:

```ruby
class MyScenario < Shoot::Scenario
	def login
		visit "http://url.to.login"
	end
end
```

As you can see, it follows [capybara's](https://github.com/jnicklas/capybara) syntax, so you can visit pages, fill forms, click links and so on...

Now run:

	$ shoot scenario my_scenario.rb
	
This will run all the methods of MyScenario and generate screenshots for all active browsers, at the end of each method.

The resulting images will be saved on <font size="7">	`.screenshots`</font> folder.

If you wanna have multiple shots on each method, use the `shoot` method:

```ruby
class MyScenario < Shoot::Scenario
	def login
		visit "http://url.to.login"
		shoot(:blank_form)
		
		fill_in('user', with: 'john')
		fill_in('password', with: '1234')
		shoot(:filled_form)
		
		click_button('Login')
		find('#welcome') # This makes sure it waits before you take another shot
		shoot(:welcome_page)
	end
end
```


If you wanna just test your scenarios, without paying [BrowserStack](https://www.browserstack.com/) and wasting time with remote connections:

	$ shoot test my_scenario.rb
	
Or you can run a whole folder, like:

	$ shoot test my_scenarios/

The `test` command will run locally using [phantomjs](http://phantomjs.org/) ([poltergeist](https://github.com/teampoltergeist/poltergeist)).

You can choose to deactivate the browsers you don't wanna use, based on id as well. Example:

	$ shoot deactivate 2

If you want to deactivate all the active browsers at once you can run:

	$ shoot deactivate_all

To open all screenshots (on a Mac), run:

	$ shoot open

### Interactive mode

Sometimes running all the commands above becomes annoying. Here's where the interactive mode comes to the rescue. Just run any of the commands below: 

    # shoot -i
    # shoot --interactive
    # shoot interactive    
    
And you'll be prompted for actions. You can run things like:

	(interactive mode) # list ie
	(interactive mode) # activate 12 34 56
	(interactive mode) # test /my_test_folder
	(interactive mode) # open
	(interactive mode) # deactivate 12
	(interactive mode) # update	
	
You got the idea.				

### List of commands

	shoot activate IDs                    # Activate platforms, based on IDs
	shoot active                          # List active platforms.
	shoot deactivate IDs                  # Deactivate platforms, based on IDs
	shoot deactivate_all                  # Deactivate all the platforms
	shoot help [COMMAND]                  # Describe available commands or one specific 
	shoot interactive, --interactive, -i  # Interactive mode
	shoot list [FILTER]                   # List all platforms. Optionally passing a filter
	shoot open                            # Opens all screenshots taken
	shoot scenario PATH                   # Runs the given scenario or all files in a directory on all active platforms
	shoot test PATH                       # Runs the given scenario or all files in a directory on a local phantomjs
	shoot update                          # Update browser list (WARNING: will override active browsers)
	shoot version, --version, -v          # Shoot version

### Using [ngrok](https://ngrok.com/)

In order to access your local development environment on [BrowserStack](https://www.browserstack.com/) you need to forward it somehow to the external world (a.k.a. the internet). [BrowserStack](https://www.browserstack.com/) has it's own forwarder, but [ngrok](https://ngrok.com/) is better. If you wanna use it:

1. Install it from [https://ngrok.com/download](https://ngrok.com/download)

2. Enable subdomains by registering.

3. Use the `Shoot::Ngrok` class in your test, like this:

``` ruby
  def my_test
    my_server = Shoot::Ngrok.new(12345)
    visit my_server.url
  end
```

Where `12345` is the port of your local server. The default is `3000`, since I believe you're probably using [Rails](http://rubyonrails.org/).

#### What if I'm using [pow](http://pow.cx)?

If you're using [pow](http://pow.cx), skip step 3 above and do it like this instead:

``` ruby
  def my_test
    my_server = Shoot::NgrokPow.new(:my_server_folder)
    visit my_server.url
  end
```

NgrokPow will create another symlink of your server folder with a unique name and forward it correctly to [ngrok](https://ngrok.com/). This symlink will be properly removed at the end of the execution of shoot.

## Contributing

1. Fork it ( https://github.com/joaomilho/shoot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
