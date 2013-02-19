# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'bo_m', %q{
  As an user
  I want to view bo_m
} do

  before :each do
    create :chart
  end

  scenario 'bom - bom', js: true do
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.bom')
    current_hash.should eq('estimate/bo_ms/new')
    page.should have_content(I18n.t('views.estimates.uid'))
    page.should have_content(I18n.t('views.resources.tag'))
    page.should have_content(I18n.t('views.resources.mu'))
    titles = [I18n.t('views.estimates.code'), I18n.t('views.resources.tag'),
              I18n.t('views.resources.mu'), I18n.t('views.estimates.rate')]
    check_header("#container_documents table", titles)

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should have_content('2')
    page.should have_content(I18n.t('views.estimates.elements.machinist'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.bo_m.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")
    find_field('uid')[:disabled].should eq(nil)
    find_field('asset_tag')[:disabled].should eq(nil)
    find_field('asset_mu')[:disabled].should eq(nil)
    find_field('builders')[:disabled].should eq(nil)
    find_field('rank')[:disabled].should eq(nil)
    find_field('machinist')[:disabled].should eq(nil)

    click_button(I18n.t('views.users.save'))

    resources = nil

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.uid')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.resources.tag')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.resources.mu')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.catalog')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('uid', :with => '123456')
      6.times { create(:asset) }
      resources = Asset.order(:tag).limit(6)
      fill_in('asset_tag', :with => resources[0].tag[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[3].click
      end
      find_field('asset_mu')[:value].should eq(resources[3].mu)
    end

    2.times{ create(:catalog) }
    catalogs = Estimate::Catalog.order("id ASC").all
    catalog = catalogs[0]
    find('#bom_catalog').click
    page.should have_selector('#catalogs_selector')
    within('#catalogs_selector') do
      within('table tbody') do
        within(:xpath, './/tr[1]//td[2]') do
          find("span[@class='cell-link']").click
        end
      end
    end
    page.should have_no_selector('#catalogs_selector')

    within("#container_documents form") do
      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.boms')} : #{I18n.t('errors.messages.blanks')}")
      end

      fill_in('builders', :with => '150')

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.rank')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('builders', :with => '')
      fill_in('rank', :with => '160')

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.builders')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('builders', :with => '150')

      page.should have_content('3')
      page.should have_content(I18n.t('views.estimates.elements.machinery'))
      page.should have_xpath(".//td/span[@id='add-mach']")
      page.find(:xpath, ".//td/span[@id='add-mach']").click
      page.should have_content(I18n.t('views.estimates.elements.mu.machine'))
      page.should have_xpath(".//td/span[@id='remove-mach']")

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.code')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.rate')} : #{I18n.t('errors.messages.blank')}")
      end

      page.find(:xpath, ".//td/span[@id='remove-mach']").click

      page.should have_content('4')
      page.should have_content(I18n.t('views.estimates.elements.resources'))
      page.should have_xpath(".//td/span[@id='add-res']")
      page.find(:xpath, ".//td/span[@id='add-res']").click
      page.should have_xpath(".//td/span[@id='remove-res']")

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.code')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.resources.mu')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.rate')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('resources_code_0', :with => '456')
      check_autocomplete('resources_tag_0', resources, :tag, :should_clear)
      fill_in('resources_rate_0', :with => '185')

      fill_in('builders', :with => 'a')
      fill_in('rank', :with => 'b')
      fill_in('machinist', :with => 'c')
      fill_in('resources_rate_0', :with => 'f')

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.builders')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.rank')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinist')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.rate')} : #{I18n.t('errors.messages.number')}")
      end

      fill_in('builders', :with => '150')
      fill_in('rank', :with => '160')
      fill_in('machinist', :with => '')
      fill_in('resources_rate_0', :with => '190')

      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "estimate/bo_ms/#{Estimate::BoM.last.id}"
      Estimate::BoM.last.items.count.should eq(3)
      visit '#inbox'
      visit "#estimate/bo_ms/#{Estimate::BoM.last.id}"
    end

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.bo_m.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq('true')
    find_button(I18n.t('views.users.edit'))[:disabled].should eq(nil)
    find_field('uid')[:disabled].should eq('true')
    find_field('asset_tag')[:disabled].should eq('true')
    find_field('asset_mu')[:disabled].should eq('true')
    find_field('bom_catalog')[:disabled].should eq('true')
    find_field('builders')[:disabled].should eq('true')
    find_field('rank')[:disabled].should eq('true')
    find_field('resources_code_0')[:disabled].should eq('true')
    find_field('resources_tag_0')[:disabled].should eq('true')
    find_field('resources_mu_0')[:disabled].should eq('true')
    find_field('resources_rate_0')[:disabled].should eq('true')

    within("#container_documents table tbody") do
      page.should_not have_no_content('2')
      page.should_not have_no_content(I18n.t('views.estimates.elements.machinist'))
      page.should_not have_no_content(I18n.t('views.estimates.elements.mu.people'))

      page.should have_no_content('4')
      page.should have_no_content(I18n.t('views.estimates.elements.resources'))
      page.should have_no_xpath(".//td/span[@id='add-res']")
      page.should have_no_xpath(".//td/span[@id='add-mach']")
      page.should have_no_xpath(".//td/span[@id='remove-res']")
      page.should have_no_xpath(".//td/span[@id='remove-mach']")

    end

    bom = Estimate::BoM.last

    find_field('uid')[:value].should eq(bom.uid)
    find_field('asset_tag')[:value].should eq(bom.resource.tag)
    find_field('asset_mu')[:value].should eq(bom.resource.mu)
    find_field('bom_catalog')[:value].should eq(catalog.tag)
    find_field('builders')[:value].should eq(bom.builders[0].rate.to_i.to_s)
    find_field('rank')[:value].should eq(bom.rank[0].rate.to_i.to_s)
    find_field('resources_code_0')[:value].should eq(bom.resources[0].uid)
    find_field('resources_tag_0')[:value].should eq(bom.resources[0].resource.tag)
    find_field('resources_mu_0')[:value].should eq(bom.resources[0].resource.mu)
    find_field('resources_rate_0')[:value].should eq(bom.resources[0].rate.to_i.to_s)

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.bo_m.page.title.edit'))
    end

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should have_content('2')
    page.should have_content(I18n.t('views.estimates.elements.machinist'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('3')
    page.should have_content(I18n.t('views.estimates.elements.machinery'))
    page.should have_xpath(".//td/span[@id='add-mach']")

    page.should have_content('4')
    page.should have_content(I18n.t('views.estimates.elements.resources'))
    page.should have_xpath(".//td/span[@id='add-res']")

    find_field('uid')[:disabled].should eq(nil)
    find_field('asset_tag')[:disabled].should eq(nil)
    find_field('asset_mu')[:disabled].should eq(nil)
    find_field('bom_catalog')[:disabled].should eq(nil)
    find_field('builders')[:disabled].should eq(nil)
    find_field('rank')[:disabled].should eq(nil)
    find_field('resources_code_0')[:disabled].should eq(nil)
    find_field('resources_tag_0')[:disabled].should eq(nil)
    find_field('resources_mu_0')[:disabled].should eq(nil)
    find_field('resources_rate_0')[:disabled].should eq(nil)

    fill_in('asset_mu', :with => 'asdfg')
    find('#bom_catalog').click
    page.should have_selector('#catalogs_selector')
    within('#catalogs_selector') do
      within('table tbody') do
        within(:xpath, './/tr[2]//td[2]') do
          find("span[@class='cell-link']").click
        end
      end
    end
    page.should have_no_selector('#catalogs_selector')
    fill_in('builders', :with => '')
    fill_in('rank', :with => '')
    fill_in('machinist', :with => '')
    page.find(:xpath, ".//td/span[@id='remove-res']").click

    click_button(I18n.t('views.users.save'))
    find("#container_notification").visible?.should be_true
    within("#container_notification") do
      page.should have_content("#{I18n.t(
          'views.estimates.boms')} : #{I18n.t('errors.messages.blanks')}")
    end

    fill_in('machinist', :with => '160')
    page.find(:xpath, ".//td/span[@id='add-mach']").click
    fill_in('machinery_code_0', :with => '123')
    6.times { create(:asset, mu: I18n.t('views.estimates.elements.mu.machine')) }
    resources = Asset.order(:tag).where('mu' => I18n.t('views.estimates.elements.mu.machine')).limit(6)
    check_autocomplete('machinery_tag_0', resources, :tag, :should_clear)
    fill_in('machinery_rate_0', :with => '180')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "estimate/bo_ms/#{bom.id}"
    Estimate::BoM.last.items.count.should eq(2)
    visit '#inbox'
    visit "#estimate/bo_ms/#{Estimate::BoM.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.bo_m.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq('true')
    find_button(I18n.t('views.users.edit'))[:disabled].should eq(nil)
    find_field('uid')[:disabled].should eq('true')
    find_field('asset_tag')[:disabled].should eq('true')
    find_field('asset_mu')[:disabled].should eq('true')
    find_field('bom_catalog')[:disabled].should eq('true')
    find_field('machinist')[:disabled].should eq('true')
    find_field('machinery_code_0')[:disabled].should eq('true')
    find_field('machinery_tag_0')[:disabled].should eq('true')
    find_field('machinery_rate_0')[:disabled].should eq('true')

    within("#container_documents table tbody") do
      page.should_not have_no_content('1')
      page.should_not have_no_content(I18n.t('views.estimates.elements.builders'))
      page.should_not have_no_content(I18n.t('views.estimates.elements.mu.people'))
      page.should_not have_no_content('1.1')
      page.should_not have_no_content(I18n.t('views.estimates.elements.rank'))

      page.should have_no_content('4')
      page.should have_no_content(I18n.t('views.estimates.elements.resources'))
      page.should have_no_xpath(".//td/span[@id='add-res']")
      page.should have_no_xpath(".//td/span[@id='add-mach']")
      page.should have_no_xpath(".//td/span[@id='remove-res']")
      page.should have_no_xpath(".//td/span[@id='remove-mach']")
    end

    bom = Estimate::BoM.last
    catalog = catalogs[1]

    find_field('uid')[:value].should eq(bom.uid)
    find_field('asset_tag')[:value].should eq(bom.resource.tag)
    find_field('asset_mu')[:value].should eq(bom.resource.mu)
    find_field('bom_catalog')[:value].should eq(catalog.tag)
    find_field('machinist')[:value].should eq(bom.machinist[0].rate.to_i.to_s)
    find_field('machinery_code_0')[:value].should eq(bom.machinery[0].uid)
    find_field('machinery_tag_0')[:value].should eq(bom.machinery[0].resource.tag)
    find_field('machinery_rate_0')[:value].should eq(bom.machinery[0].rate.to_i.to_s)
  end

  scenario 'catalogs dialog selector', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:catalog) }
    catalogs = Estimate::Catalog.limit(per_page).order("id ASC")
    first_catalog = catalogs[0]
    parent_catalog = catalogs[1]
    catalog_named = catalogs[3]
    catalog_named.tag = "aaaaa"
    catalog_named.save!
    count = per_page + 1
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.bom')

    find('#bom_catalog').click
    within('#catalogs_selector') do
      titles = [I18n.t('views.estimates.catalogs.tag'), I18n.t('views.estimates.catalogs.select')]
      check_header("table", titles)
      check_content("table", catalogs) do |catalog|
        [catalog.tag]
      end

      check_paginate("div[@class='paginate']", count, per_page)
      next_page("div[@class='paginate']")
      catalogs = Estimate::Catalog.limit(per_page).offset(per_page).order("id ASC")
      check_content("table", catalogs) do |catalog|
        [catalog.tag]
      end

      first_catalog.parent = parent_catalog
      first_catalog.save!

      prev_page("div[@class='paginate']")

      page.should have_selector("div[@class='breadcrumbs'] ul li", count: 1)
      page.find(:xpath, "table//tbody//tr[1]//td[1]").text.should eq(parent_catalog.tag)
      find("span[@data-bind='text: count']").should have_content((count-1).to_s)

      page.find(:xpath, "table//tbody//tr[1]//td[1]").click
      page.should have_selector('table tbody tr', count: 1)
      page.should have_selector("div[@class='breadcrumbs'] ul li", count: 2)
      page.find(:xpath, "//div[@class='breadcrumbs']//ul//li[2]").text.should eq(parent_catalog.tag)
      find("span[@data-bind='text: count']").should have_content('1')
      find("span[@data-bind='text: range']").should have_content("1-1")

      within(:xpath, "table//tbody//tr[1]//td[2]") do
        page.find("span[@class='cell-link']").text.
            should eq(I18n.t('views.estimates.catalogs.select_catalog'))
      end

      page.find(:xpath, "//div[@class='breadcrumbs']//ul//li[1]").click
      page.should have_selector('table tbody tr', count: per_page)
      page.should have_selector("div[@class='breadcrumbs'] ul li", count: 1)
      find("span[@data-bind='text: count']").should have_content(count-1)
      find("span[@data-bind='text: range']").should have_content("1-#{per_page}")

      fill_in('dialog_search', :with => 'aaaa')
      click_button(I18n.t('views.home.search'))
      page.should have_selector('table tbody tr', count: 1)
      find("span[@data-bind='text: count']").should have_content('1')
      find("span[@data-bind='text: range']").should have_content("1-1")
      page.find(:xpath, "table//tbody//tr[1]//td[1]").text.should eq(catalog_named.tag)
    end
  end

  scenario 'view and sort boms', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:bo_m)}
    count = Estimate::BoM.all.count
    boms = Estimate::BoM.limit(per_page)

    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.boms')
    current_hash.should eq('estimate/bo_ms')
    wait_for_ajax
    titles = [I18n.t('views.estimates.uid'),
              I18n.t('views.resources.tag'), I18n.t('views.resources.mu'),
              I18n.t('views.estimates.catalogs.tag')]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", boms) do |bom|
      [bom.uid, bom.resource.tag, bom.resource.mu, bom.catalog.tag]
    end
    wait_for_ajax
    check_paginate("div[@class='paginate']", count, per_page)

    test_order = lambda do |field, type|
      boms = Estimate::BoM.limit(per_page).send("sort_by_#{field}","#{type}")
      within('#container_documents table') do
        within('thead tr') do
          page.find("##{field}").click
          if type == 'asc'
            page.should have_xpath("//th[@id='#{field}']" +
                                       "/span[@class='ui-icon ui-icon-triangle-1-s']")
          elsif type == 'desc'
            page.should have_xpath("//th[@id='#{field}']" +
                                       "/span[@class='ui-icon ui-icon-triangle-1-n']")
          end
        end
      end
      check_content("#container_documents table", boms) do |bom|
        [bom.uid, bom.resource.tag, bom.resource.mu, bom.catalog.tag]
      end
    end

    test_order.call('uid','asc')
    test_order.call('uid','desc')
    test_order.call('tag','asc')
    test_order.call('tag','desc')
    test_order.call('mu','asc')
    test_order.call('mu','desc')
    test_order.call('catalog_tag','asc')
    test_order.call('catalog_tag','desc')
  end

  scenario 'check filtrate', js: true do
    20.times do |i|
      ass = create(:asset, tag: "tag#{i}", mu: "mu#{i}")
      create(:bo_m, uid: "uid#{i}", resource_id: ass.id)
    end
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.boms')
    wait_for_ajax
    page.find("#show-filter").click
    within('#filter-area') do
      fill_in('filter_uid', with: '1')
      fill_in('filter_mu', with: '1')
      page.find("#addtag")[:disabled].should eq("true")
      fill_in('filter_tag', with: '1')
      page.find("#addtag")[:disabled].should eq(nil)
      click_button(I18n.t('views.estimates.inclusion'))
      fill_in('tag0', with: '2')
      click_button_and_wait(I18n.t('views.home.search'))
    end
    boms = Estimate::BoM.search_by({ like: { uid: '1', mu: '1', tag: '1',
                                              tags: { 0 => {tag:'2',
                                                            type: "#{I18n.t('views.estimates.or')}"}}}})
    check_content("#container_documents table", boms) do |bom|
      [bom.uid, bom.resource.tag, bom.resource.mu, bom.catalog.tag]
    end
    page.find("#show-filter").click
    within('#filter-area') do
      find('#type')['value'].should eq(I18n.t('views.estimates.or'))
      select("#{I18n.t('views.estimates.and')}", from: "type")
      find('#type')['value'].should eq(I18n.t('views.estimates.and'))
      click_button_and_wait(I18n.t('views.home.search'))
    end
    boms = Estimate::BoM.search_by({ like: { uid: '1', mu: '1', tag: '1',
                                             tags: { 0 => { tag:'2',
                                                           type: "#{I18n.t('views.estimates.and')}"}}}})
    check_content("#container_documents table", boms) do |bom|
      [bom.uid, bom.resource.tag, bom.resource.mu, bom.catalog.tag]
    end
    page.find("#show-filter").click
    within('#filter-area') do
      find('#filter_uid')['value'].should eq('1')
      find('#filter_mu')['value'].should eq('1')
      find('#filter_tag')['value'].should eq('1')
      find('#tag0')['value'].should eq('2')

      page.find("#clear_filter").click

      find('#filter_uid')['value'].should eq('')
      find('#filter_mu')['value'].should eq('')
      find('#filter_tag')['value'].should eq('')
      page.should_not have_selector('tag0')
      click_button_and_wait(I18n.t('views.home.search'))
    end
    boms = Estimate::BoM.all
    check_content("#container_documents table", boms) do |bom|
      [bom.uid, bom.resource.tag, bom.resource.mu, bom.catalog.tag]
    end
    page.find("#show-filter").click

    within('#filter-area') do
      fill_in('filter_tag', with: '1')
      click_button(I18n.t('views.estimates.inclusion'))
      fill_in('tag0', with: '2')
      click_button(I18n.t('views.estimates.inclusion'))
      fill_in('tag1', with: '3')
      page.find("#delete1").click
      click_button_and_wait(I18n.t('views.home.search'))
    end
    boms = Estimate::BoM.search_by({ like: { tag: '1',
                                             tags: { 0 => {tag:'2',
                                                           type: "#{I18n.t('views.estimates.or')}"}}}})
    check_content("#container_documents table", boms) do |bom|
      [bom.uid, bom.resource.tag, bom.resource.mu, bom.catalog.tag]
    end
  end

  scenario 'show bom', js: true do
    10.times { create(:bo_m) }
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate.bo_ms.data')
    wait_for_ajax
    find(:xpath, "//tr[1]/td[1]").click
    wait_for_ajax
    bom = Estimate::BoM.first
    current_hash.should eq("estimate/bo_ms/#{bom.id}")
  end
end