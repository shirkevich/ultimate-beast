require File.dirname(__FILE__) + '/../spec_helper'

describe User, 'creation from openid_url' do
  before(:each) do
    @user = User.new
    @user.openid_url = 'http://example-openid.com/'
  end

  it "should be valid" do
    @user.should be_valid
  end

  it "should be activated on create" do
    @user.save.should be_true
    @user.activated.should be_true
  end

  it "should have not empty openid_url" do
    @user.openid_url = nil
    @user.should_not be_valid
    @user.errors.on(:openid_url).should =~ /is too short/
    @user.openid_url = ''
    @user.should_not be_valid
    @user.errors.on(:openid_url).should =~ /is too short/
  end

  it "should validate openid_url format on creation" do
    @user = User.create(:openid_url => 'HTTP://another-openid.com/')
    @user.should be_an_instance_of(User)
    @user.should_not be_new_record
    @user.openid_url.should match(/^http/)
  end

  it "should have openid_url at 255 maximum length" do
    @user.openid_url = 'http://as/' + Array.new(245, '0').join
    @user.should be_valid
    @user.openid_url = 'http://as/' + Array.new(246, '0').join
    @user.should_not be_valid
    @user.errors.on(:openid_url).should =~ /too long/
  end

  it "should not have openid_url that have some other user (with case sensitivity in mind (http://insens.com/SenS is valid))" do
    openid_url_lowercase              = 'http://example-openid.com/user'
    openid_url_with_upcase_domain     = 'httP://examplE-openid.com/user'
    openid_url_with_upcase_path       = 'httP://examplE-openid.com/uSer'
    openid_url_with_upcase_path_saved = 'http://example-openid.com/uSer'

    @user.openid_url = openid_url_lowercase
    @user.save.should be_true

    @user = User.new
    @user.openid_url = openid_url_with_upcase_domain
    @user.save.should_not be_true
    @user.errors.on(:openid_url).should =~ /taken/
    @user.openid_url.should == openid_url_with_upcase_domain.downcase

    @user = User.new
    @user.openid_url = openid_url_with_upcase_path
    @user.save.should be_true
    @user.openid_url.should == openid_url_with_upcase_path_saved
  end
end

describe User, 'creation from email' do
  before(:each) do
    @user = User.new
    @user.email = 'name@organization.org'
    @user.password = '12345'
  end

  it "should be valid" do
    @user.should be_valid
  end

  it "should have valid email address" do
    ['sam', 'sam@@colgate.com', ''].each do |email|
      @user.email = email
      @user.should_not be_valid
    end

    ['johh.doe@google.com', 'johh_doe@mail.mx.1.google.com', 'johh_doe+crazy-iness@mail.mx.1.google.com'].each do |email|
      @user.email = email
      @user.should be_valid
    end
  end

  it "should not create user with same email" do
    @user.save.should be_true
    @another_user = User.new(:email => @user.email, :password => '123123')
    @another_user.should_not be_valid
  end

  it "should have password.length >= 5" do
    ['1', '1234'].each do |password|
      @user.password = password
      @user.should_not be_valid
    end
    ['123456', '12345', 'dfsdfs'].each do |password|
      @user.password = password
      @user.should be_valid
    end
  end

  it "should set login_key" do
    @user.save.should be_true
    @user.login_key.should be_nil
    @user.login_key_expires_at.should be_nil
    @user.reset_login_key!
    @user.login_key_expires_at.should < Time.now.utc+1.year+1.minute
    @user.login_key_expires_at.should > Time.now.utc+1.year-1.minute
  end
end

describe User, 'display name' do
  before(:each) do
    @user = User.new(:openid_url => 'http://valid.url')
    @user.save.should be_true
  end
 
  it "should be possible to set any display name" do
    ['vasya', 'вася пупкин', '23rkoo3'].each do |name|
      @user.display_name = name
      @user.should be_valid
    end
  end 

  it "should be uniq" do
    name = 'вася'
    @user.display_name = name
    @user.save
    @another_user = User.create(:openid_url => 'http://another.ulr')
    @another_user.display_name = 'Вася'
    @another_user.should_not be_valid
  end 
end

describe User, 'admin creation' do
 it "first user should be admin" do
   @user = User.create(:openid_url => 'http://valid.url')
   @user.admin?.should be_true
   @another_user = User.create(:openid_url => 'http://another.valid.url')
   @another_user.admin?.should be_false
 end
end
