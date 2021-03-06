class Audience < ActiveRecord::Base
  belongs_to :resource

  def self.get_values
    ['Undergraduate Student', 'Graduate Student',
     'Faculty', 'Staff', 'Alumni',
     'Recent Alumni', 'Everyone', 'Women',
     'Investors', 'Non-profit', 'For-profit'
    ]
  end

  def self.count(label)
    return Audience.where(:val => label).length;
  end

end
