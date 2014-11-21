require 'spec_helper'

describe "Users" do
  before(:all) do
      let(:user) { FactoryGirl.build(:user) }
  end

  describe "when not signed in" do
    it "should allow sign in" do
      visit '/'
      expect(page).to have_content(/Sign in/)
      
      visit cardsets_index
      expect(page).to have_content(/Sign in/)
      
      click_link "Sign in"
      expect(page).to have_field 
    end
    
    it "should allow new user registration" do
      visit signup_path
      expect(page).to have_field('user[name]')
      expect(page).to have_field('user[email]')
      expect(page).to have_field('user[password]')
      expect(page).to have_field('user[password_confirmation]')
      
      fill_in 'Username', with: user.name
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign up'
      
      saved_user = User.where(:name => user.name).includes(:authentications).last
      expect(saved_user).to_not be_nil
      expect(saved_user.email).to eql user.email
    end
  end
  
end