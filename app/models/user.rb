require 'digest/sha1'

class User < ActiveRecord::Base
  def self.per_page
    50
  end
  has_many :moderatorships, :dependent => :destroy
  has_many :forums, :through => :moderatorships, :order => "#{Forum.table_name}.name"

  has_many :posts
  has_many :topics
  has_many :monitorships
  has_many :monitored_topics, :through => :monitorships, :conditions => ["#{Monitorship.table_name}.active = ?", true], :order => "#{Topic.table_name}.replied_at desc", :source => :topic

  with_options :if => :not_openid? do |u|
    u.validates_presence_of	:email
    u.validates_presence_of     :password_hash
    u.validates_length_of       :password, :minimum => 5, :allow_nil => true
    u.validates_confirmation_of :password, :on => :create
    u.validates_confirmation_of :password, :on => :update, :allow_nil => true
  end

  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Please check the e-mail address"[:check_email_message], :allow_nil => true

  def before_validation
    write_attribute(:display_name, display_name.split.join(' ')) if attribute_present?(:display_name)
  end
  validates_uniqueness_of :email, :allow_nil => true
  validates_uniqueness_of :display_name, :case_sensitive => false, :allow_nil => true
  validates_uniqueness_of :openid_url, :case_sensitive => true, :allow_nil => true
  validates_length_of     :openid_url, :within => 8..255, :allow_nil => true

  # first user becomes admin automatically
  before_create { |u| u.admin = u.activated = true if User.count == 0 }
  # users coming from openid becomes activated
  before_create { |u| u.activated = true if u.openid_url }
  before_save   { |u| u.email.downcase! if u.email }

  attr_reader :password
  attr_protected :admin, :posts_count, :login, :created_at, :updated_at, :last_login_at, :topics_count, :activated

  def self.currently_online
    User.find(:all, :conditions => ["last_seen_at > ?", Time.now.utc-5.minutes])
  end

  # we allow false to be passed in so a failed login can check
  # for an inactive account to show a different error
  def self.authenticate(email, password, activated=true)
    find_by_email_and_password_hash_and_activated(email, Digest::SHA1.hexdigest(password + PASSWORD_SALT), activated)
  end

  def self.search(query, options = {})
    with_scope :find => { :conditions => build_search_conditions(query) } do
      options[:page] ||= nil
      paginate options
    end
  end

  def self.build_search_conditions(query)
    query && ['LOWER(display_name) LIKE :q OR LOWER(login) LIKE :q', {:q => "%#{query}%"}]
  end

  def password=(value)
    return if value.blank?
    write_attribute :password_hash, Digest::SHA1.hexdigest(value + PASSWORD_SALT)
    @password = value
  end
  
  def openid_url=(value)
    write_attribute :openid_url, value.blank? ? nil : OpenIdAuthentication.normalize_url(value)
  end
  
  def reset_login_key(rehash = true)
    # this is not currently honored
    self.login_key_expires_at = Time.now.utc+1.year
    self.login_key = Digest::SHA1.hexdigest(Time.now.to_s + password_hash.to_s + rand(123456789).to_s).to_s if rehash
  end
  
  def reset_login_key!(rehash = true)
    reset_login_key(rehash)
    save!
    login_key
  end
  
  def active_login_key
    reset_login_key!(login_key.blank?)
  end

  def moderator_of?(forum)
    moderatorships.count("#{Moderatorship.table_name}.id", :conditions => ['forum_id = ?', (forum.is_a?(Forum) ? forum.id : forum)]) == 1
  end

  def beauty_name(length = 100) 
    return display_name[0..length] unless display_name.blank?
    return openid_url.sub(/^https?:\/\//, '')[0..length] unless openid_url.blank?
    return "/users/#{id}"
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :email << :login_key << :login_key_expires_at << :password_hash << :openid_url << :activated << :admin
    super
  end
  
  def not_openid?
    openid_url.nil?
  end
  
  def update_posts_count
    self.class.update_posts_count id
  end
  
  def self.update_posts_count(id)
    User.update_all ['posts_count = ?', Post.count(:id, :conditions => {:user_id => id})],   ['id = ?', id]
  end

end
