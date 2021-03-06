require 'minitest/autorun'
require 'exponent-server-sdk'

class ExponentServerSdkTest < Minitest::Test
  def setup
    @mock = MiniTest::Mock.new
    @response_mock = MiniTest::Mock.new
    @exponent = Exponent::Push::Client.new(@mock)
  end

  def test_publish_with_success
    @response_mock.expect(:code, 200)
    @response_mock.expect(:body, success_body.to_json)

    @mock.expect(:post, @response_mock, client_args)

    @exponent.publish(messages)

    @mock.verify
  end

  def test_publish_with_unknown_error
    @response_mock.expect(:code, 400)
    @response_mock.expect(:body, error_body.to_json)
    message = 'An unknown error occurred.'

    @mock.expect(:post, @response_mock, client_args)

    exception = assert_raises Exponent::Push::UnknownError do
      @exponent.publish(messages)
    end

    assert_equal(message, exception.message)

    @mock.verify
  end

  def test_publish_with_device_not_registered_error
    @response_mock.expect(:code, 200)
    @response_mock.expect(:body, not_registered_device_error_body.to_json)
    message = '"ExponentPushToken[42]" is not a registered push notification recipient'

    @mock.expect(:post, @response_mock, client_args)

    exception = assert_raises Exponent::Push::DeviceNotRegisteredError do
      @exponent.publish(messages)
    end

    assert_equal(message, exception.message)

    @mock.verify
  end

  def test_publish_with_message_too_big_error
    @response_mock.expect(:code, 200)
    @response_mock.expect(:body, message_too_big_error_body.to_json)
    message = 'Message too big'

    @mock.expect(:post, @response_mock, client_args)

    exception = assert_raises Exponent::Push::MessageTooBigError do
      @exponent.publish(messages)
    end

    assert_equal(message, exception.message)

    @mock.verify
  end

  def test_publish_with_message_rate_exceeded_error
    @response_mock.expect(:code, 200)
    @response_mock.expect(:body, message_rate_exceeded_error_body.to_json)
    message = 'Message rate exceeded'

    @mock.expect(:post, @response_mock, client_args)

    exception = assert_raises Exponent::Push::MessageRateExceededError do
      @exponent.publish(messages)
    end

    assert_equal(message, exception.message)

    @mock.verify
  end

  def test_publish_with_invalid_credentials_error
    @response_mock.expect(:code, 200)
    @response_mock.expect(:body, invalid_credentials_error_body.to_json)
    message = 'Invalid credentials'

    @mock.expect(:post, @response_mock, client_args)

    exception = assert_raises Exponent::Push::InvalidCredentialsError do
      @exponent.publish(messages)
    end

    assert_equal(message, exception.message)

    @mock.verify
  end

  def test_publish_with_apn_error
    @response_mock.expect(:code, 200)
    @response_mock.expect(:body, apn_error_body.to_json)

    @mock.expect(:post, @response_mock, client_args)

    exception = assert_raises Exponent::Push::UnknownError do
      @exponent.publish(messages)
    end

    assert_match(/Unknown error format/, exception.message)

    @mock.verify
  end

  private

  def success_body
    { 'data' => [{ 'status' => 'ok' }] }
  end

  def error_body
    {
      'errors' => [{
        'code' => 'INTERNAL_SERVER_ERROR',
        'message' => 'An unknown error occurred.'
      }]
    }
  end

  def message_too_big_error_body
    build_error_body('MessageTooBig', 'Message too big')
  end

  def not_registered_device_error_body
    build_error_body(
      'DeviceNotRegistered',
      '"ExponentPushToken[42]" is not a registered push notification recipient'
    )
  end

  def message_rate_exceeded_error_body
    build_error_body('MessageRateExceeded', 'Message rate exceeded')
  end

  def invalid_credentials_error_body
    build_error_body('InvalidCredentials', 'Invalid credentials')
  end

  def apn_error_body
    {
      'data' => [{
        'status' => 'error',
        'message' =>
          'Could not find APNs credentials for you (your_app). Check whether you are trying to send a notification to a detached app.'
      }]
    }
  end

  def client_args
    [
      'https://exp.host/--/api/v2/push/send',
      {
        body: messages.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      }
    ]
  end

  def messages
    [{
      to: 'ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]',
      sound: 'default',
      body: 'Hello world!'
    }, {
      to: 'ExponentPushToken[yyyyyyyyyyyyyyyyyyyyyy]',
      badge: 1,
      body: "You've got mail"
    }]
  end

  def build_error_body(error_code, message)
    {
      'data' => [{
        'status' => 'error',
        'message' => message,
        'details' => { 'error' => error_code }
      }]
    }
  end
end
