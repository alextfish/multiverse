# == Schema Information
# Schema version: 20100930004247
#
# Table name: users
#
#  id                 :integer         not null, primary key
#  name               :string(255)
#  email              :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  encrypted_password :string(255)
#  salt               :string(255)
#  admin              :boolean
#

require 'digest'
class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :name, :email, :password, :password_confirmation
  has_many :logs

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name,  :presence => true,
                    :length   => { :maximum => 50 },
                    :uniqueness => { :case_sensitive => false }
  validates :email, :presence => true,
                    :format   => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }
  # Automatically create the virtual attribute 'password_confirmation'.
  validates :password, :presence     => true,
                       :confirmation => true,
                       :length       => { :within => 4..140 }

  has_many :cardsets
  has_many :comments

  before_save :encrypt_password

  def to_s
    name
  end

  # Return true if the user's password matches the submitted password.
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end

  def User.NON_SIGNED_IN_USER
    -1
  end
  def User.user_and_name_for(id)
    case
      when id == User.NON_SIGNED_IN_USER
        [nil, "a non-signed-in user"]
      when id && !(user = User.find(id)).nil?     # define user if we can
        [user, user.name]
      else # an edit from before edits were logged (uid==nil) or a user that no longer exists
        [nil, "someone"]
    end
  end
  def User.name_for(id)
    user, name = User.user_and_name_for(id)
    name
  end


  def User.authenticate(email, submitted_password)
    user = find_by_email(email)
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def self.authenticate_with_salt(id, incoming_salt)
    user = find_by_id(id)
    return nil  if user.nil?
    return user if user.salt == incoming_salt
  end

  private

    def encrypt_password
      self.salt = make_salt if new_record?
      self.encrypted_password = encrypt(password)
    end

    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end

    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end
end
