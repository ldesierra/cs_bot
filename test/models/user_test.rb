require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate admin password correctly" do
    # Set up environment variable for testing
    ENV["ADMIN_PASSWORD"] = "test_admin_password"

    user = User.new(
      email: "test1@example.com",
      password: "password123",
      password_confirmation: "password123",
      user_number: "12345",
      admin_password: "wrong_password"
    )

    assert_not user.valid?
    assert_includes user.errors[:admin_password], "is incorrect"
  end

  test "should allow registration with correct admin password" do
    # Set up environment variable for testing
    ENV["ADMIN_PASSWORD"] = "test_admin_password"

    user = User.new(
      email: "test2@example.com",
      password: "password123",
      password_confirmation: "password123",
      user_number: "67890",
      admin_password: "test_admin_password"
    )

    # Should be valid (admin password validation passes)
    assert user.valid?
  end
end
