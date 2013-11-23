class String
    def to_range
        case self.count('.')
            when 2
                elements = self.split('..')
                return Range.new(elements[0].to_i, elements[1].to_i)
            when 3
                elements = self.split('...')
                return Range.new(elements[0].to_i, elements[1].to_i-1)
            else
                raise ArgumentError.new("Couldn't convert to Range:
#{str}")
        end
    end
end


Address = Struct.new(:number, :street, :town, :state, :lat, :lng) do
  def to_loc
    {lat: self.lat, lng: self.lng}
  end

  def town_state_s
    "#{self.town}, #{self.state}"
  end

  def to_s
    "%i %s, %s {%f, %f}" % [self.number, self.street, self.town_state_s(), self.lat, self.lng]
  end
end

Bar = Struct.new(:id, :name, :address, :sells) do
  def to_s
    "#{self.id}: #{self.name} (#{self.address.to_s})"
  end
end

Person = Struct.new(:id, :name, :address, :company_id, :age)
Company = Struct.new(:id, :name, :address, :employees)
Beer = Struct.new(:name, :manf, :recyclable, :price_range)
Buys = Struct.new(:bar_id, :person_id, :beer_name, :quantity, :date)
# Frequents = Struct.new(:person_id, :bar_id, :weeklyCount)

class Hash
  def keys_to_sym(*keys)
    self.keys.each do |key|
      self[key.to_sym] = self[key]
      self.delete key
    end
    return self
  end
end
