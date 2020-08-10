# Extend the time class to get round up and floor
class Time
  # Time#round already exists with different meaning in Ruby 1.9
  def round_off(seconds = 60)
    Time.at((self.to_f / seconds).round * seconds)
  end

  def ceil(seconds = 60)
    Time.at((self.to_f / seconds).ceil * seconds)
  end

  def floor(seconds = 60)
    Time.at((self.to_f / seconds).floor * seconds)
  end
end
