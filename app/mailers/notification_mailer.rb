# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class NotificationMailer < ActionMailer::Base
  default_url_options[:host] = "localhost:3000"
  default from: "admin@aasii.org"

  def user_notification_email(user, warning_object)
    @user = user
    @warning_object = warning_object
    mail(:to => user.email,
         :subject => I18n.t("warnings.warning") + '!',
         :template_path => 'notification_mailer',
         :template_name => warning_object.class.name.demodulize.underscore,
         :content_type => "text/html")
  end

  def manager_notification_email(user, warning_object)
    @user = user
    managers = user.managers.map { |m| m.email }
    @warning_object = warning_object
    mail(:to => managers,
         :subject => I18n.t("warnings.warning") + '!',
         :template_path => 'notification_mailer',
         :template_name => warning_object.class.name.demodulize.underscore,
         :content_type => "text/html")
  end
end
