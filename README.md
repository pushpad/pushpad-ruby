# Pushpad - Web Push Notifications

[![Gem Version](https://badge.fury.io/rb/pushpad.svg)](https://badge.fury.io/rb/pushpad)
![Build Status](https://github.com/pushpad/pushpad-ruby/workflows/CI/badge.svg)

[Pushpad](https://pushpad.xyz) is a service for sending push notifications from websites and web apps. It uses the **Push API**, which is a standard supported by all major browsers (Chrome, Firefox, Opera, Edge, Safari).

The notifications are delivered in real time even when the users are not on your website and you can target specific users or send bulk notifications.

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

You can subscribe the users to your notifications using the Javascript SDK, as described in the [getting started guide](https://pushpad.xyz/docs/pushpad_pro_getting_started).

If you need to generate the HMAC signature for the `uid` you can use this helper:

```ruby
Pushpad.signature_for current_user.id
```

## Sending push notifications

```ruby
notification = Pushpad::Notification.new({
  # required, the main content of the notification
  body: "Hello world!",

  # optional, the title of the notification (defaults to your project name)
  title: "Website Name",

  # optional, open this link on notification click (defaults to your project website)
  target_url: "https://example.com",

  # optional, the icon of the notification (defaults to the project icon)
  icon_url: "https://example.com/assets/icon.png",

  # optional, the small icon displayed in the status bar (defaults to the project badge)
  badge_url: "https://example.com/assets/badge.png",

  # optional, an image to display in the notification content
  # see https://pushpad.xyz/docs/sending_images
  image_url: "https://example.com/assets/image.png",

  # optional, drop the notification after this number of seconds if a device is offline
  ttl: 604800,

  # optional, prevent Chrome on desktop from automatically closing the notification after a few seconds
  require_interaction: true,

  # optional, enable this option if you want a mute notification without any sound
  silent: false,

  # optional, enable this option only for time-sensitive alerts (e.g. incoming phone call)
  urgent: false,

  # optional, a string that is passed as an argument to action button callbacks
  custom_data: "123",

  # optional, add some action buttons to the notification
  # see https://pushpad.xyz/docs/action_buttons
  actions: [
    {
      title: "My Button 1",
      target_url: "https://example.com/button-link", # optional
      icon: "https://example.com/assets/button-icon.png", # optional
      action: "myActionName" # optional
    }
  ],

  # optional, bookmark the notification in the Pushpad dashboard (e.g. to highlight manual notifications)
  starred: true,

  # optional, use this option only if you need to create scheduled notifications (max 5 days)
  # see https://pushpad.xyz/docs/schedule_notifications
  send_at: Time.utc(2016, 7, 25, 10, 9),

  # optional, add the notification to custom categories for stats aggregation
  # see https://pushpad.xyz/docs/monitoring
  custom_metrics: ['examples', 'another_metric'] # up to 3 metrics per notification
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
# they can include parentheses and the operators !, &&, || (from highest to lowest precedence)
# https://pushpad.xyz/docs/tags
notification.broadcast tags: ['zip_code:28865 && !optout:local_events || friend_of:Organizer123']
notification.deliver_to users, tags: ['tag1 && tag2', 'tag3'] # equal to 'tag1 && tag2 || tag3'

# deliver to everyone
notification.broadcast
```

You can set the default values for most fields in the project settings. See also [the docs](https://pushpad.xyz/docs/rest_api#notifications_api_docs) for more information about notification fields.

If you try to send a notification to a user ID, but that user is not subscribed, that ID is simply ignored.

The methods above return an hash:

- `"id"` is the id of the notification on Pushpad
- `"scheduled"` is the estimated reach of the notification (i.e. the number of devices to which the notification will be sent, which can be different from the number of users, since a user may receive notifications on multiple devices)
- `"uids"` (`deliver_to` only) are the user IDs that will be actually reached by the notification because they are subscribed to your notifications. For example if you send a notification to `['uid1', 'uid2', 'uid3']`, but only `'uid1'` is subscribed, you will get `['uid1']` in response. Note that if a user has unsubscribed after the last notification sent to him, he may still be reported for one time as subscribed (this is due to [the way](https://blog.pushpad.xyz/2016/05/the-push-api-and-its-wild-unsubscription-mechanism/) the W3C Push API works).
- `"send_at"` is present only for scheduled notifications. The fields `"scheduled"` and `"uids"` are not available in this case.

The `id` and `scheduled_count` attribute are also stored on the notification object:

```ruby

notification.deliver_to user

notification.id # => 1000
notification.scheduled_count # => 5
```

## Getting push notification data

You can retrieve data for past notifications:

```ruby
notification = Pushpad::Notification.find(42)

# get basic attributes
notification.id # => 42
notification.title # => "Foo Bar"
notification.body # => "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
notification.target_url # => "https://example.com"
notification.ttl # => 604800
notification.require_interaction # => false
notification.silent # => false
notification.urgent # => false
notification.icon_url # => "https://example.com/assets/icon.png"
notification.badge_url # => "https://example.com/assets/badge.png"

# `created_at` is a `Time` instance
notification.created_at.utc.to_s # => "2016-07-06 10:09:14 UTC"

# get statistics
notification.scheduled_count # => 1
notification.successfully_sent_count # => 4
notification.opened_count # => 2
```

Or for mutliple notifications of a project at once:

```ruby
notifications = Pushpad::Notification.find_all(project_id: 5)

# same attributes as for single notification in example above
notifications[0].id # => 42
notifications[0].title # => "Foo Bar"
```

If `Pushpad.project_id` is defined, the `project_id` option can be
omitted.

The REST API paginates the result set. You can pass a `page` parameter
to get the full list in multiple requests.

```ruby
notifications = Pushpad::Notification.find_all(project_id: 5, page: 2)
```

## Scheduled notifications

You can create scheduled notifications that will be sent in the future:

```ruby
notification = Pushpad::Notification.new({
  body: "This notification will be sent after 60 seconds",
  send_at: Time.now.utc + 60
})

notification.broadcast
```

You can also cancel a scheduled notification:

```ruby
notification = Pushpad::Notification.find(5)
notification.cancel
```

## Getting subscription count

You can retrieve the number of subscriptions for a given project,
optionally filtered by `tags` or `uids`:

```ruby
Pushpad::Subscription.count(project_id: 5) # => 100
Pushpad::Subscription.count(project_id: 5, uids: ['user1']) # => 2
Pushpad::Subscription.count(project_id: 5, tags: ['sports']) # => 10
Pushpad::Subscription.count(project_id: 5, tags: 'sports && travel') # => 5
Pushpad::Subscription.count(project_id: 5, uids: ['user1'], tags: 'sports && travel') # => 1
```

If `Pushpad.project_id` is defined, the `project_id` option can be
omitted.

## Getting push subscription data

You can retrieve the subscriptions for a given project,
optionally filtered by `tags` or `uids`:

```ruby
Pushpad::Subscription.find_all(project_id: 5)
Pushpad::Subscription.find_all(project_id: 5, uids: ['user1'])
Pushpad::Subscription.find_all(project_id: 5, tags: ['sports'])
Pushpad::Subscription.find_all(project_id: 5, tags: 'sports && travel')
Pushpad::Subscription.find_all(project_id: 5, uids: ['user1'], tags: 'sports && travel')
```

If `Pushpad.project_id` is defined, the `project_id` option can be
omitted.

The REST API paginates the result set. You can pass a `page` parameter
to get the full list in multiple requests.

```ruby
subscriptions = Pushpad::Subscription.find_all(project_id: 5, page: 2)
```

You can also retrieve the data of a specific subscription if you already know its id:

```ruby
Pushpad::Subscription.find 123
Pushpad::Subscription.find 123, project_id: 456
```

## Updating push subscription data

Usually you add data, like user IDs and tags, to the push subscriptions using the [JavaScript SDK](https://pushpad.xyz/docs/javascript_sdk_reference) in the frontend.

However you can also update the subscription data from your server:

```ruby
Pushpad::Subscription.find_all(uids: ['user1']).each do |subscription|
  # update the user ID associated to the push subscription
  subscription.update uid: 'myuser1'
  
  # update the tags associated to the push subscription
  tags = subscription.tags
  tags << 'another_tag'
  subscription.update tags: tags
end
```

## Importing push subscriptions

If you need to [import](https://pushpad.xyz/docs/import) some existing push subscriptions (from another service to Pushpad, or from your backups) or if you simply need to create some test data, you can use this method:

```ruby
attributes = {
  endpoint: "https://example.com/push/f7Q1Eyf7EyfAb1", 
  p256dh: "BCQVDTlYWdl05lal3lG5SKr3VxTrEWpZErbkxWrzknHrIKFwihDoZpc_2sH6Sh08h-CacUYI-H8gW4jH-uMYZQ4=",
  auth: "cdKMlhgVeSPzCXZ3V7FtgQ==",
  uid: "exampleUid", 
  tags: ["exampleTag1", "exampleTag2"]
}

subscription = Pushpad::Subscription.create(attributes, project_id: 5)
```

Please note that this is not the standard way to collect subscriptions on Pushpad: usually you subscribe the users to the notifications using the [JavaScript SDK](https://pushpad.xyz/docs/javascript_sdk_reference) in the frontend.

## Deleting push subscriptions

Usually you unsubscribe a user from push notifications using the [JavaScript SDK](https://pushpad.xyz/docs/javascript_sdk_reference) in the frontend (recommended).

However you can also delete the subscriptions using this library. Be careful, the subscriptions are permanently deleted!

```ruby
subscription = Pushpad::Subscription.find 123
subscription.delete
```

## Managing projects

Projects are usually created manually from the Pushpad dashboard. However you can also create projects from code if you need advanced automation or if you manage [many different domains](https://pushpad.xyz/docs/multiple_domains).

```ruby
attributes = {
  # required attributes
  sender_id: 123,
  name: "My project",
  website: "https://example.com",
  
  # optional configurations
  icon_url: "https://example.com/icon.png",
  badge_url: "https://example.com/badge.png",
  notifications_ttl: 604800,
  notifications_require_interaction: false,
  notifications_silent: false
}

project = Pushpad::Project.create(attributes)
```

You can also find, update and delete projects:

```ruby
Pushpad::Project.find_all.each do |p|
  puts "Project #{p.id}: #{p.name}"
end

project = Pushpad::Project.find 123

project.update(name: 'The New Project Name')

project.delete
```

## Managing senders

Senders are usually created manually from the Pushpad dashboard. However you can also create senders from code.

```ruby
attributes = {
  # required attributes
  name: "My sender",
  
  # optional configurations
  # do not include these fields if you want to generate them automatically
  vapid_private_key: "-----BEGIN EC PRIVATE KEY----- ...",
  vapid_public_key: "-----BEGIN PUBLIC KEY----- ..."
}

sender = Pushpad::Sender.create(attributes)
```

You can also find, update and delete senders:

```ruby
Pushpad::Sender.find_all.each do |s|
  puts "Sender #{s.id}: #{s.name}"
end

sender = Pushpad::Sender.find 987

sender.update(name: 'The New Sender Name')

sender.delete
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
