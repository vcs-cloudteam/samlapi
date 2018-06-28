#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'aws-sdk'
require 'parseconfig'
require 'onelogin/ruby-saml'
require 'base64'
require 'highline'
require 'json'

BASE_URL = 'https://as1.fim.psu.edu/idp/profile/SAML2/Unsolicited/SSO?providerId=urn:amazon:webservices'.freeze
AWS_ROLE = 'https://aws.amazon.com/SAML/Attributes/Role'.freeze
AWS_CONFIG_FILE = '/.aws/credentials'.freeze
REGION = 'us-east-1'.freeze
OUTPUT_FORMAT = 'json'.freeze

cli = HighLine.new

# Get the federated credentials from the user
print 'login: '
login = STDIN.gets.chomp
password = cli.ask('Enter your password:  ') { |q| q.echo = '*' }
print ''

puts 'Launching WebAccess page...'
driver = Selenium::WebDriver.for :firefox
driver.navigate.to BASE_URL

# print 'zero'
wait = Selenium::WebDriver::Wait.new(timeout: 30) # seconds
wait.until { driver.find_element(id: 'login') }
# print 'one'

element = driver.find_element(:id, 'login')
element.send_keys login
element = driver.find_element(:id, 'password')
element.send_keys password

puts 'Posting WebAccess Credentials...'
element.submit

puts 'Sleeping 5 seconds...'
sleep 5

# print 'two'
wait.until { driver.find_element(id: 'duo_device') }
# print 'three'
element = driver.find_element(:name, 'service')

puts 'Sending a DUO Push...'
element.submit
#driver.switch_to.default_content

wait.until { driver.find_element(name: 'SAMLResponse') }
assertion = driver.find_element(:name, 'SAMLResponse').attribute('value')

driver.quit

saml = OneLogin::RubySaml::Response.new(Base64.decode64(assertion))

aws_roles = []
saml.attributes.multi(AWS_ROLE).each do |role|
  (principal_arn, role_arn) = role.split(',')
  aws_roles.push(principal_arn: principal_arn,
                 role_arn: role_arn)
end

if aws_roles.length > 1
  i = 0
  puts 'Please choose the role you would like to assume:'
  aws_roles.each do |aws_role|
    print '[', i, ']: ', aws_role[:role_arn]
    puts
    i += 1
  end

  print 'Selection: '
  selection = STDIN.gets.chomp.to_i

  puts "you selected #{selection}, #{aws_roles[selection][:role_arn]}"

  if selection > aws_roles.length - 1
    puts 'You selected an invalid role index, please try again'
    exit(0)
  end

  principal_arn = aws_roles[selection][:principal_arn]
  role_arn = aws_roles[selection][:role_arn]
else
  principal_arn = aws_roles[0][:principal_arn]
  role_arn = aws_roles[0][:role_arn]
end


sts = Aws::STS::Client.new(region: 'us-east-1')
token = sts.assume_role_with_saml(role_arn: role_arn,
                                  principal_arn: principal_arn,
                                  saml_assertion: assertion)

# Write the AWS STS token into the AWS credential file
filename = Dir.home + AWS_CONFIG_FILE

if not File.file?(filename)
  puts "Creating #{filename}"
  File.open(filename, "w") {}
else
  puts "Reading #{filename}"
end

# Read in the existing config file
config = ParseConfig.new(filename)

# Put the credentials into a specific profile instead of clobbering
# the default credentials
config.add_to_group('saml', 'output', OUTPUT_FORMAT)
config.add_to_group('saml', 'region', REGION)
config.add_to_group('saml', 'aws_access_key_id', token.credentials.access_key_id)
config.add_to_group('saml', 'aws_secret_access_key', token.credentials.secret_access_key)
config.add_to_group('saml', 'aws_session_token', token.credentials.session_token)

puts "Writing #{filename}"

# Write the updated config file
file = File.open(filename, 'w')
config.write(file, false)
file.close

# Give the user some basic info as to what has just happened
puts "\n\n----------------------------------------------------------------"
puts 'Your new access key pair has been stored in the AWS configuration file under the saml profile.'
puts "Note that it will expire at #{token.credentials.expiration}."
puts 'After this time you may safely rerun this script to refresh your access key pair.'
puts 'To use this credential call the AWS CLI with the --profile option (e.g. aws --profile saml ec2 describe-instances).'
puts 
puts 'Optionall, simply copy/paste the following into the shell in which you wish to access AWS via the chosen role:'
puts "export AWS_ACCESS_KEY_ID=\"#{token.credentials.access_key_id}\""
puts "export AWS_SECRET_ACCESS_KEY=\"#{token.credentials.secret_access_key}\""
puts "export AWS_SESSION_TOKEN=\"#{token.credentials.session_token}\""
puts "----------------------------------------------------------------\n\n"
