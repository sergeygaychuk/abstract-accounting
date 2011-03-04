
module FloatAccounting
  def accounting_zero?; self < 0.00009 and self > -0.00009; end
  def accounting_round64
    if self < 0.0
     (self - 0.5).ceil
    else
     (self + 0.5).floor
    end
  end
  def accounting_norm
    (self * 100.0).accounting_round64 / 100.0
  end
  def accounting_negative?
    !self.accounting_zero? and self < 0.0
  end
end

class Float; include FloatAccounting; end