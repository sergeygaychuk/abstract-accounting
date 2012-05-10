# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "rspec"
require 'spec_helper'

feature "Transcripts", %q{
  As an user
  I want to view transcripts
} do

  scenario 'visit transcripts page', js: true do
    rub = Factory(:chart).currency
    aasii = Factory(:asset)
    share = Factory(:deal,
                     give: Factory.build(:deal_give, resource: aasii),
                     take: Factory.build(:deal_take, resource: rub),
                     rate: 10000)
    bank = Factory(:deal,
                   give: Factory.build(:deal_give, resource: rub),
                   take: Factory.build(:deal_take, resource: rub),
                   rate: 1)
    fact = Factory(:fact, day: DateTime.now.change(day: 1),
                          from: share, to: bank, resource: rub, amount: 100000)
    Factory(:txn, fact: fact)

    page_login
    click_link I18n.t('views.home.transcripts')
    current_hash.should eq('transcripts')
    page.should have_xpath("//li[@id='transcripts' and @class='sidebar-selected']")

    page.should have_datepicker("transcript_date_from")
    page.should have_datepicker("transcript_date_to")

    page.datepicker("transcript_date_from").prev_month.day(1)

    txns = Transcript.new(share, DateTime.now.change(day: 1, month: DateTime.now.month),
                          DateTime.now + 1).all

    5.times { Factory(:deal) }
    items = Deal.limit(6).all.sort
    check_autocomplete("deal_tag", items, :tag)
    fill_in('deal_tag', with: share.tag)
    page.should have_xpath("//ul[contains(@class, 'ui-autocomplete')"+
                               " and contains(@style, 'display: block')]")
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete')"+
        " and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.transcripts.date'))
        page.should have_content(I18n.t('views.transcripts.account'))
        page.should have_content(I18n.t('views.transcripts.debit'))
        page.should have_content(I18n.t('views.transcripts.credit'))
      end

      within('tbody') do
        txns.each do |txn|
          page.should have_content(txn.fact.day.strftime('%Y-%m-%d'))
          if share.id == txn.fact.to.id
            page.should have_content(txn.fact.from.tag)
          else
            page.should have_content(txn.fact.to.tag)
          end
          page.should have_content(txn.fact.amount)
        end
      end
    end
  end
end