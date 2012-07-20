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

feature "GeneralLedger", %q{
  As an user
  I want to view general ledger
} do

  before :each do
    create(:chart)
  end

  scenario 'visit general ledger page', js: true do
    per_page = Settings.root.per_page
    wb = build(:waybill)
    per_page.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    gl = GeneralLedger.paginate(page: 1).all
    gl_count = GeneralLedger.count

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.general_ledger')
    current_hash.should eq('general_ledger')

    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    titles = [
        I18n.t('views.general_ledger.date'),
        I18n.t('views.general_ledger.resource'),
        I18n.t('views.general_ledger.amount'),
        I18n.t('views.general_ledger.type'),
        I18n.t('views.general_ledger.account'),
        I18n.t('views.general_ledger.price'),
        I18n.t('views.general_ledger.debit'),
        I18n.t('views.general_ledger.credit')
    ]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", gl, 2) do |txn, i|
      if i % 2 == 0
        [txn.fact.day.strftime('%Y-%m-%d'),
         txn.fact.amount.to_s,
         txn.fact.resource.tag,
         txn.fact.to.tag,
         txn.value,
         txn.earnings]
      elsif txn.fact.from
        [txn.fact.from.tag,
         txn.value,
         txn.earnings]
      else
        []
      end
    end
    check_paginate("div[@class='paginate']", gl_count, per_page)
    #next_page("div[@class='paginate']")
    #
    #gl = GeneralLedger.paginate(page: 2).all
    #check_content("#container_documents table", gl, 2) do |txn, i|
    #  if i % 2 == 0
    #    [txn.fact.day.strftime('%Y-%m-%d'),
    #     txn.fact.amount.to_s,
    #     txn.fact.resource.tag,
    #     txn.fact.to.tag,
    #     txn.value,
    #     txn.earnings]
    #  elsif txn.fact.from
    #    [txn.fact.from.tag,
    #     txn.value,
    #     txn.earnings]
    #  else
    #    []
    #  end
    #end

    GeneralLedger.paginate(page: 1).all.each do |txn|
      txn.fact.update_attributes(day: 1.months.since.change(day: 13))
    end

    page.should have_datepicker("general_ledger_date")
    page.datepicker("general_ledger_date").next_month.day(11)

    gl = GeneralLedger.on_date(1.months.since.change(day: 11).to_s).all
    check_content("#container_documents table", gl, 2) do |txn, i|
      if i % 2 == 0
        [txn.fact.day.strftime('%Y-%m-%d'),
         txn.fact.amount.to_s,
         txn.fact.resource.tag,
         txn.fact.to.tag,
         txn.value,
         txn.earnings]
      elsif txn.fact.from
        [txn.fact.from.tag,
         txn.value,
         txn.earnings]
      else
        []
      end
    end
  end

  scenario "go to general ledger page from deals", js: true do
    create(:chart)
    wb = build(:waybill)
    3.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    wb2 = build(:waybill)
    3.times do |i|
      wb2.add_item(tag: "resource2##{i}", mu: "mu2#{i}", amount: 200+i, price: 20+i)
    end
    wb2.save!
    wb2.apply

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.deals')
    current_hash.should eq('deals')

    within('#container_documents') do
      page.find(:xpath, ".//table/tbody/tr/td[contains(./text(), '#{wb.deal.tag}')]").click
    end

    date = DateTime.now.strftime('%Y-%m-%d')
    current_hash.should eq("general_ledger?deal_id=#{wb.deal_id}&date=#{date}")

    page.find('#general_ledger_date')[:value].
        should eq(DateTime.now.strftime('%d.%m.%Y'))

    scope = GeneralLedger.on_date(date).paginate(page: 1)
    items = scope.by_deal(wb.deal_id).all
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: items.count * 2)

      items.each do |item|
        page.should have_content(item.fact.day.strftime('%Y-%m-%d'))
        page.should have_content(item.fact.amount.to_s)
        page.should have_content(item.fact.resource.tag)
        page.should have_content(item.fact.from.tag) unless item.fact.from.nil?
        page.should have_content(item.fact.to.tag)
        page.should have_content(item.value)
        page.should have_content(item.earnings)
      end

      scope.by_deal(wb2.deal_id).all.each do |item|
        page.should_not have_content(item.fact.amount.to_s) unless item.fact.from.nil?
        page.should_not have_content(item.fact.from.tag) unless item.fact.from.nil?
        page.should_not have_content(item.fact.to.tag)
        page.should_not have_content(item.value) unless item.fact.from.nil?
      end
    end
  end
end
