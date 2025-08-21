class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  validates :contact_number, presence: true, format: { with: /\A\+[1-9]\d{9,14}\z/, message: "must be in E.164 format (e.g. +639123456789)" }
  validates :current_address, :email, :first_name, :last_name, presence: true
  validates :time_zone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "%{value} is not a valid time zone" }

  # dependencies
  has_many :packages
  has_many :remittances
end
