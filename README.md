# Pushpad - Web Push Notifications Service
 
[Pushpad](https://pushpad.xyz) is a service for sending push notifications from your web app. It supports the **Push API** (Chrome and Firefox) and **APNs** (Safari).

Features:

- notifications are delivered even when the user is not on your website
- users don't need to install any app or plugin
- you can target specific users or send bulk notifications

Currently push notifications work on the following browsers:

- Chrome (Desktop and Android)
- Firefox (44+)
- Safari

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pushpad'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pushpad

## Getting started

First you need to sign up to Pushpad and create a project there.

Then set your authentication credentials:

```ruby
Pushpad.auth_token = '5374d7dfeffa2eb49965624ba7596a09'
Pushpad.project_id = 123 # set it here or pass it as a param to methods later
```

- `auth_token` can be found in the user account settings. 
- `project_id` can be found in the project settings. If your application uses multiple projects, you can pass the `project_id` as a param to methods (e.g. `notification.deliver_to user, project_id: 123`).

## Collecting user subscriptions to push notifications

Pushpad offers two different products. [Learn more](https://pushpad.xyz/docs)

### Pushpad Pro

Choose Pushpad Pro if you want to use Javascript for a seamless integration. [Read the docs](https://pushpad.xyz/docs/pushpad_pro_getting_started)

If you need to generate the HMAC signature for the `uid` you can use this helper:

```ruby
Pushpad.signature_for current_user.id
```

### Pushpad Express

If you want to use Pushpad Express, add a link to your website to let users subscribe to push notifications: 

```erb
<a href="<%= Pushpad.path %>">Push notifications</a>

<!-- If the user is logged in on your website you should track its user id to target him in the future  -->
<a href="<%= Pushpad.path_for current_user # or current_user_id %>">Push notifications</a>
```

When a user clicks the link is sent to Pushpad, asked to receive push notifications and redirected back to your website.

## Sending push notifications

```ruby
notification = Pushpad::Notification.new({
  body: "Hello world!", # max 120 characters
  title: "Website Name", # optional, defaults to your project name, max 30 characters
  target_url: "http://example.com", # optional, defaults to your project website
  icon_url: "http://example.com/assets/icon.png", # optional, defaults to the project icon
  ttl: 604800 # optional, drop the notification after this number of seconds if a device is offline
})

# deliver to a user
notification.deliver_to user # or user_id

# deliver to a group of users
notification.deliver_to users # or user_ids

# deliver to some users only if they have a given preference
# e.g. only "users" who have a interested in "events" will be reached
notification.deliver_to users, tags: ['events']

# deliver to segments
# e.g. any subscriber that has the tag "segment1" OR "segment2"
notification.broadcast tags: ['segment1', 'segment2']

# you can use boolean expressions 
# they must be in the disjunctive normal form (without parenthesis)
notification.broadcast tags: ['zip_code:28865 && !optout:local_events || friend_of:Organizer123']
notification.deliver_to users, tags: ['tag1 && tag2', 'tag3'] # equal to 'tag1 && tag2 || tag3'

# deliver to everyone
notification.broadcast
```

If no user with that id has subscribed to push notifications, that id is simply ignored.

The methods above return an hash: 

- `"id"` is the id of the notification on Pushpad
- `"scheduled"` is the estimated reach of the notification (i.e. the number of devices to which the notification will be sent, which can be different from the number of users, since a user may receive notifications on multiple devices)
- `"uids"` (`deliver_to` only) are the user IDs that will be actually reached by the notification because they are subscribed to your notifications. For example if you send a notification to `['uid1', 'uid2', 'uid3']`, but only `'uid1'` is subscribed, you will get `['uid1']` in response. Note that if a user has unsubscribed after the last notification sent to him, he may still be reported for one time as subscribed (this is due to [the way](http://blog.pushpad.xyz/2016/05/the-push-api-and-its-wild-unsubscription-mechanism/) the W3C Push API works).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

