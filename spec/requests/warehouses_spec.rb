# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'warehouses', %q{
  As an user
  I want to view warehouses
} do

  before :each do
    create(:chart)
  end

  scenario 'view warehouses', js: true do
    per_page = Settings.root.per_page

    wb = build(:waybill)
    (0..per_page).each do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    page_login
    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.warehouses.place'))
        page.should have_content(I18n.t('views.warehouses.tag'))
        page.should have_content(I18n.t('views.warehouses.real_amount'))
        page.should have_content(I18n.t('views.warehouses.expectation_amount'))
        page.should have_content(I18n.t('views.warehouses.mu'))
      end
      page.should have_selector("tbody[@data-bind='foreach: documents']")
      page.all('tbody tr').count.should eq(per_page)
    end

    page.find("#show-filter").click

    within('#filter-area') do
      page.should have_content(I18n.t('views.warehouses.place'))
      page.should have_content(I18n.t('views.warehouses.tag'))
      page.should have_content(I18n.t('views.warehouses.real_amount'))
      page.should have_content(I18n.t('views.warehouses.expectation_amount'))
      page.should have_content(I18n.t('views.warehouses.mu'))

      fill_in('filter-place', with: wb.storekeeper_place.tag)
      fill_in('filter-tag', with: 'resource#0')
      fill_in('filter-real-amount', with: 100)
      fill_in('filter-exp-amount', with: 100)
      fill_in('filter-mu', with: 'mu0')

      click_button(I18n.t('views.home.search'))
    end

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      page.should have_content(wb.storekeeper_place.tag)
      page.should have_content("resource#0")
      page.should have_content("mu0")
      page.should have_content(100)
    end

    page.all("div[@class='paginate']").each { |control|
      within("span[@data-bind='text: range']") do
        control.should have_content("1-1")
      end

      within("span[@data-bind='text: count']") do
        control.should have_content("1")
      end

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('true')
    }

    page.find("#show-filter").click

    within('#filter-area') do
      fill_in('filter-place', with: '')
      fill_in('filter-tag', with: '')
      fill_in('filter-real-amount', with: '')
      fill_in('filter-exp-amount', with: '')
      fill_in('filter-mu', with: '')

      click_button(I18n.t('views.home.search'))
    end

    page.all("div[@class='paginate']").each { |control|
      within("span[@data-bind='text: range']") do
        control.should have_content("1-#{per_page}")
      end

      within("span[@data-bind='text: count']") do
        control.should have_content(Warehouse.count.to_s)
      end

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    }

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page)
    end

    wh = Warehouse.all
    count = Warehouse.count
    (0..(count/per_page).ceil).each { |p|
      wh[p*per_page...p*per_page+per_page].each_with_index { |w, i|
        tr = page.all('#container_documents table tbody tr')[i]
        tr.should have_content(w.tag)
        tr.should have_content(w.place)
        tr.should have_content(w.real_amount.to_i)
        tr.should have_content(w.exp_amount.to_i)
        tr.should have_content(w.mu)
      }

      click_button('>')
    }

    within("div[@class='paginate']") do
      find_button('>')[:disabled].should eq('true')
    end

    (count/per_page).ceil.downto(0).each { |p|
      wh[p*per_page...p*per_page+per_page].each_with_index { |w, i|
        tr = page.all('#container_documents table tbody tr')[i]
        tr.should have_content(w.tag)
        tr.should have_content(w.place)
        tr.should have_content(w.real_amount.to_i)
        tr.should have_content(w.exp_amount.to_i)
        tr.should have_content(w.mu)
      }

      click_button('<')
    }

    within("div[@class='paginate']") do
      find_button('<')[:disabled].should eq('true')
    end
  end

  scenario "user without root credentials should see only his data", js: true do
    password = "password"
    user = create(:user, password: password)
    credential = create(:credential, user: user, document_type: Warehouse.name)

    wb = build(:waybill)
    5.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    page_login(user.email, password)

    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.warehouses.place'))
        page.should have_content(I18n.t('views.warehouses.tag'))
        page.should have_content(I18n.t('views.warehouses.real_amount'))
        page.should have_content(I18n.t('views.warehouses.expectation_amount'))
        page.should have_content(I18n.t('views.warehouses.mu'))
      end
      page.should have_selector("tbody[@data-bind='foreach: documents']")
      within('tbody') do
        page.should_not have_selector("tr")
      end
    end
    click_link I18n.t('views.home.logout')

    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
    5.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    page_login(user.email, password)

    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    resources = Warehouse.all(where: { storekeeper_id: { equal: user.entity_id },
                                       storekeeper_place_id: { equal: credential.place_id } })
    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.warehouses.place'))
        page.should have_content(I18n.t('views.warehouses.tag'))
        page.should have_content(I18n.t('views.warehouses.real_amount'))
        page.should have_content(I18n.t('views.warehouses.expectation_amount'))
        page.should have_content(I18n.t('views.warehouses.mu'))
      end
      page.should have_selector("tbody[@data-bind='foreach: documents']")
      within('tbody') do
        resources.each do |r|
          page.should have_content(r.place)
          page.should have_content(r.tag)
          page.should have_content(r.real_amount.to_i)
          page.should have_content(r.exp_amount.to_i)
          page.should have_content(r.mu)
        end
      end
    end
    click_link I18n.t('views.home.logout')
  end

  scenario 'grouping warehouses', js: true do
    per_page = Settings.root.per_page

    wb = build(:waybill)
    wb2 = build(:waybill)

    3.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu##{i}", price: 100+i, amount: 10+i)
    end

    wb.save!
    wb.apply

    (0..per_page).each { |i|
      wb2.add_item(tag: "resource##{i}", mu: "mu##{i}", price: 500+i, amount: 50+i)
    }
    wb2.save!
    wb2.apply

    page_login
    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    within('#container_documents table tbody') do
      page.all('tr').count.should eq(per_page)
    end

    select(I18n.t('views.warehouses.group_place'), from: 'warehouse_group')

    resources = Warehouse.
        all(where: { place_id: { equal_attr: wb.storekeeper_place.id } })
    resources.length.should eq(3)

    within('#container_documents table tbody') do
      all("tr", visible: true)
      page.should have_selector('tr', count: 2, visible: true)
      page.should have_content(wb.storekeeper_place.tag)
      page.should have_content(wb2.storekeeper_place.tag)
      page.should have_selector(:xpath,
                      ".//tr//td[@class='distribution-tree-actions-by-wb']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']", count: 2)
      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click
      within("#group_#{wb.storekeeper_place.id}") do
        page.should have_selector("td[@class='td-inner-table']")

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{resources.length}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{resources.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('true')
        end

        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: resources.length)
          resources.each do |r|
            page.should have_content(wb.storekeeper_place.tag)
            page.should have_content(r.tag)
            page.should have_content(r.real_amount.to_i)
            page.should have_content(r.exp_amount.to_i)
            page.should have_content(r.mu)
          end
        end
      end
      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click
      page.find("#group_#{wb2.storekeeper_place.id}").visible?.should_not be_true

      resources = Warehouse.
          all(where: { place_id: { equal_attr: wb2.storekeeper_place.id } })
      resources.length.should eq(per_page + 1)

      find(:xpath,
           ".//tr[3]//td[@class='distribution-tree-actions-by-wb']").click
      within("#group_#{wb2.storekeeper_place.id}") do
        page.should have_selector("td[@class='td-inner-table']")
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: per_page)
          per_page.times do |i|
            page.should have_content(wb2.storekeeper_place.tag)
            page.should have_content(resources[i].tag)
            page.should have_content(resources[i].real_amount.to_i)
            page.should have_content(resources[i].exp_amount.to_i)
            page.should have_content(resources[i].mu)
          end
        end

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{per_page}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{resources.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('false')
          click_button('>')
          find_button('<')[:disabled].should eq('false')
          find_button('>')[:disabled].should eq('true')
          within("span[@data-bind='text: range']") do
            page.should have_content("#{per_page + 1}-#{per_page + 1}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{resources.length}")
          end
        end

        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: 1)
          page.should have_content(wb2.storekeeper_place.tag)
          page.should have_content(resources.last.tag)
          page.should have_content(resources.last.real_amount.to_i)
          page.should have_content(resources.last.exp_amount.to_i)
          page.should have_content(resources.last.mu)
        end

        within("div[@class='paginate']") do
          click_button('<')
        end
      end
      find(:xpath,
           ".//tr[3]//td[@class='distribution-tree-actions-by-wb']").click
      page.find("#group_#{wb2.storekeeper_place.id}").visible?.should_not be_true
    end

    select(I18n.t('views.warehouses.group_tag'), from: 'warehouse_group')

    within("div[@class='paginate']") do
      within("span[@data-bind='text: range']") do
        page.should have_content("1-#{per_page}")
      end
      within("span[@data-bind='text: count']") do
        page.should have_content("#{per_page + 1}")
      end
      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
      click_button('>')
      find_button('<')[:disabled].should eq('false')
      find_button('>')[:disabled].should eq('true')
      within("span[@data-bind='text: range']") do
        page.should have_content("#{per_page + 1}-#{per_page + 1}")
      end
      within("span[@data-bind='text: count']") do
        page.should have_content("#{per_page + 1}")
      end
    end

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1, visible: true)
      page.should have_content(Asset.last.tag)
    end

    within("div[@class='paginate']") do
      click_button('<')
    end

    items = wb2.items
    within('#container_documents table tbody') do
      per_page.times do |i|
        page.should have_content(items[i].resource.tag)
      end
    end

    resource = Asset.find_by_tag_and_mu('resource#0', 'mu#0')
    resources = Warehouse.
        all(where: { asset_id: { equal_attr: resource.id } })
    resources.length.should eq(2)

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: per_page, visible: true)
      page.should have_selector(:xpath,
                      ".//tr//td[@class='distribution-tree-actions-by-wb']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']",
                      count: per_page)

      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click
      within("#group_#{resource.id}") do
        page.should have_selector("td[@class='td-inner-table']")

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{resources.length}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{resources.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('true')
        end

        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: resources.length)
          page.should have_content(wb.storekeeper_place.tag)
          page.should have_content(wb2.storekeeper_place.tag)
          page.should have_content(resource.tag)
          resources.each do |r|
            page.should have_content(r.real_amount.to_i)
            page.should have_content(r.exp_amount.to_i)
            page.should have_content(r.mu)
          end
        end
      end
      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click
      page.find("#group_#{resource.id}").visible?.should_not be_true
    end
  end
end
