![](https://img.shields.io/gem/v/shoot.svg)
![](https://img.shields.io/codeclimate/github/joaomilho/shoot.svg)

# Shoot

Shoot is a helper library to take screenshots using BrowserStack. If you don't need a full integration test coupled with screenshots, it's a simpler choice.

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
	
The `list` command basically fetches all browsers available on BrowserStack and caches them locally on `.screenshots/.browsers.json`. You can choose to add this folder on your `.gitignore`, since shoot will save all images there as well.

Then, you can choose to activate the browsers you wanna use, based on id. Example:

	$ shoot activate 2

This will activate (given your output is the same as above) chrome 16 on OS X Snow Leopard.

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
	
This will run all the methods of MyScenario and generate screenshots for all active browsers.

The resulting images will be saved on <font size="7">	`.screenshots`</font> folder.


## Contributing

1. Fork it ( https://github.com/joaomilho/shoot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
