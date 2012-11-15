# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

ActiveSupport::Notifications.subscribe "warning.notification" do |name, start, finish, id, payload|
  user = User.find(payload[:object].versions.where{event == "create"}.first.whodunnit)
  return true if user.root?
  managers = user.managers
  NotificationMailer.user_notification_email(user, user_message).deliver
  NotificationMailer.manager_notification_email(managers, manager_message).deliver unless managers.empty?
end
