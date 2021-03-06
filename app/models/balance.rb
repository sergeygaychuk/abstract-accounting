# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "state_action"

class Balance < ActiveRecord::Base
  has_paper_trail
  include StateAction

  validates :amount, :value, :start, :side, :deal_id, :presence => true
  validates_inclusion_of :side, :in => [PASSIVE, ACTIVE]
  validates_uniqueness_of :start, :scope => :deal_id
  belongs_to :deal
  has_one :give, :through => :deal
  has_one :take, :through => :deal

  after_initialize :do_init
  scope :not_paid, where("balances.paid IS NULL")
  scope :passive, where(:side => Balance::PASSIVE)
  scope :active, where(:side => Balance::ACTIVE)

  class << self
    def with_resources(resources)
      scope_with(resources) do |key, value|
        ((give.resource_id.in(value)) & (give.resource_type == key) &
            (side == Balance::PASSIVE)) |
            ((take.resource_id.in(value)) & (take.resource_type == key) &
            (side == Balance::ACTIVE))
      end
    end

    def with_entities(entities)
      scope_with(entities) do |key, value|
        (deal.entity_type == key) & (deal.entity_id.in(value))
      end
    end

    def with_places(ids)
      where{((give.place_id.in(ids)) & (side == Balance::PASSIVE)) |
            ((take.place_id.in(ids)) & (side == Balance::ACTIVE))}
    end

    def in_time_frame(start, stop)
      where("balances.start < :stop AND (balances.paid > :start OR balances.paid IS NULL)",
            :start => DateTime.civil(start.year, start.month, start.day, 0, 0, 0),
            :stop => DateTime.civil(stop.year, stop.month, stop.day, 13, 0, 0))
    end

    def paginate(params = {})
      page = params[:page].nil? ? 1 : params[:page].to_i
      per_page = params[:per_page].nil? ?
          Settings.root.per_page.to_i : params[:per_page].to_i
      limit(per_page).offset((page - 1) * per_page)
    end

    def scope_with(items, &block)
      scoped.where do
        scope = nil
        items.inject({}) do |mem, item|
          (mem[item['type']] ||= []).push(item['id'])
          mem
        end.each do |key, value|
          tmp_scope = instance_exec(key, value, &block) if block_given?
          scope = scope ? scope | tmp_scope : tmp_scope
        end
        scope
      end
    end
  end

  def update_value(side, amount, value)
    old_value = self.accounting_value
    old_amount = self.amount
    old_side = self.side
    if update_amount(side, amount)
      old_value *= -1 if old_side != self.side
      if side == PASSIVE && self.side == PASSIVE
        if has_credit?
          self.value = (self.amount * self.credit).accounting_norm
        elsif has_debit?
          self.value = (self.amount * self.deal.rate * self.debit).accounting_norm
        else
          raise "Unexpected behaviour"
        end
      elsif side == ACTIVE && self.side == ACTIVE
        if has_debit?
          self.value = (self.amount * self.debit).accounting_norm
        elsif !value.accounting_zero?
          self.value = old_value + value
        else
          raise "Unexpected behaviour"
        end
      elsif side == PASSIVE && self.side == ACTIVE
        if has_debit?
          self.value = (self.amount * self.debit).accounting_norm
        else
          raise "Unexpected behaviour" \
            if old_value.accounting_negative? || old_amount.accounting_zero?
          self.value = (old_value * self.amount/old_amount).accounting_norm
        end
      elsif side == ACTIVE && self.side == ACTIVE
        if has_credit?
          self.value = self.amount
        elsif !old_value.accounting_negative? && !old_amount.accounting_zero?
          self.value = (old_value - self.amount/old_amount).accounting_norm
        else
          raise "Unexpected behaviour"
        end
      end
    end
    true
  end

  def accounting_value
    if Balance::ACTIVE == self.side && self.has_debit?
      return (self.amount * self.debit).accounting_norm
    end
    self.value
  end

  def debit_diff
    if Balance::ACTIVE == self.side && self.has_debit?
      return (self.amount * self.debit - self.value).accounting_norm
    end
    0.0
  end

  def credit_diff
    if Balance::PASSIVE == self.side && self.has_credit?
      return (self.amount * self.credit - self.value).accounting_norm
    end
    0.0
  end

  protected
  def do_init
    self.side ||= ACTIVE if self.attributes.has_key?('side')
    self.amount ||= 0.0 if self.attributes.has_key?('amount')
    self.value ||= 0.0 if self.attributes.has_key?('value')
  end

  def has_debit?
    return true if !Chart.first.nil? and self.deal.take.resource == Chart.first.currency
    self.deal.take.resource.is_a? Money and !self.deal.take.resource.quotes.first.nil?
  end

  def has_credit?
    return true if !Chart.first.nil? and self.deal.give.resource == Chart.first.currency
    self.deal.give.resource.is_a? Money and !self.deal.give.resource.quotes.first.nil?
  end

  def credit
    if self.deal.give.resource.is_a? Money and !self.deal.give.resource.quote.nil?
      return self.deal.give.resource.quote.rate
    elsif !Chart.first.nil? and self.deal.give.resource == Chart.first.currency
      return 1.0
    end
    0.0
  end

  def debit
    if self.deal.take.resource.is_a? Money and !self.deal.take.resource.quote.nil?
      return self.deal.take.resource.quote.rate
    elsif !Chart.first.nil? and self.deal.take.resource == Chart.first.currency
      return 1.0
    end
    0.0
  end
end
