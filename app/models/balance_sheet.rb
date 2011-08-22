
class BalanceSheet < Array
  attr_reader :day, :assets, :liabilities

  def initialize(day = DateTime.now)
    @day = day
    @assets = 0.0
    @liabilities = 0.0

    sql = "
    SELECT states.id AS id, link.id AS deal_id, states.side AS side,
           states.amount AS amount, IFNULL(balances.value, 0.0) AS value,
           states.start AS start
    FROM
      (SELECT deals.id AS id, deals.tag AS tag, deals.rate AS rate,
              deals.entity_id AS entity_id, deals.give_type AS give_type,
              deals.give_id AS give_id, deals.take_type AS take_type,
              deals.take_id AS take_id, states.start AS start
       FROM deals
       LEFT JOIN states ON states.deal_id==deals.id AND
         states.start <= '" + day.to_s + "' AND (states.paid > '" + day.to_s + "'
         OR states.paid IS NULL) WHERE states.start IS NOT NULL)
    AS link
    LEFT JOIN states ON link.id=states.deal_id AND states.start=link.start
    LEFT JOIN balances ON link.id=balances.deal_id AND balances.start=link.start
    UNION
    SELECT id, NULL, incomes.side AS side, NULL, incomes.value AS value,
           incomes.start AS start
    FROM incomes
    WHERE start<='" + day.to_s + "' AND (paid>'" + day.to_s + "' OR paid IS NULL)"

    ActiveRecord::Base.connection.execute(sql).each do |result|
      attrs = Hash.new
      result.each { |key, value| attrs[key.to_sym] = value if key.kind_of?(String) }
      if attrs[:side] == "passive"
        @assets += attrs[:value]
      else
        @liabilities += attrs[:value]
      end
      if attrs[:deal_id].nil? and attrs[:amount].nil?
        self << Income.new(:side => attrs[:side],
                           :value => attrs[:value],
                           :start => attrs[:start])
      else
        self << Balance.new(attrs)
      end
    end
  end
end
