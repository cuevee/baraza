class NewsletterMailer < ApplicationMailer
  helper ApplicationHelper
  def send_mail(newsletter)
    @newsletter = newsletter
    mail(to: Subscriber.all.collect(&:email), subject: "Baraza newsletter")
  end
end