require 'rails_helper'

describe User do
  describe "validation" do
    it "should be inavlid if password length is less than 6 characters" do
      user = build(:user, password: "Pa1!")
      expect(user).not_to be_valid
      expect(user.errors.full_messages).to eq(["Password is too short (minimum is 6 characters)"])
    end

    it "should be inavlid if password length is more than 10 characters" do
      expect(build(:user, password: "Pa1!213456675856432456463452")).not_to be_valid
    end

    it "should validate presence" do
      expect(build(:user, password: nil)).not_to be_valid
    end

    it "should validate password and password_confirmation to be equal" do
      expect(build(:user, password: "Password1!", password_confirmation: "Password2!")).not_to be_valid
    end

    it "should validate to include at-least one uppercase letter, lowercase letter, numeral and special character" do
      expect(build(:user, password: "Password1")).not_to be_valid
      expect(build(:user, password: "PASSWORD1!")).not_to be_valid
      expect(build(:user, password: "Password!")).not_to be_valid
      expect(build(:user, password: "Password1")).not_to be_valid

      expect(build(:user, password: "Password1!")).to be_valid
    end
  end

  describe "skip validation" do
    it "should skip email validation for users associated to providers" do
      expect {
        create(:user, uid: "uid001", provider: "facebook", email: nil)
      }.to change{User.count}.by(1)
    end

    it "should skip password validation for users associated to providers" do
      expect {
        create(:user, uid: "uid001", provider: "facebook", password: nil, password_confirmation: nil)
      }.to change{User.count}.by(1)
    end

    it "should not skip for regular users" do
      expect(build(:user, email: nil)).not_to be_valid
    end
  end

  describe "send_editor_intro_mail" do
    it "should send mail to the user on assignment of editorial role" do
      user = create(:user)
      mailer = double("mailer")
      expect(EditorWelcomeNotifier).to receive(:welcome).with(user).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      user.update_attributes(type: Editor.name)
    end

    it "should not send mail to the user if other attributes are changed" do
      user = create(:user)
      expect(EditorWelcomeNotifier).not_to receive(:welcome)
      user.update_attributes(first_name: "hi")
    end

    it "should not send mail to the user if type is changed to value other than editor" do
      user = create(:user, type: Editor.name)
      expect(EditorWelcomeNotifier).not_to receive(:welcome)
      user.update_attributes(type: Editor.name)
    end
  end
end