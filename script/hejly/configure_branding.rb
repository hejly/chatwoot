# Run explicitly with: bundle exec rails runner script/hejly/configure_branding.rb
abort 'Hejly branding requires a pure CE image without enterprise/.' if Rails.root.join('enterprise').exist? || ChatwootApp.enterprise?

branding = {
  'INSTALLATION_NAME' => 'Hejly',
  'BRAND_NAME' => 'Hejly',
  'BRAND_URL' => 'https://gethejly.com',
  'WIDGET_BRAND_URL' => 'https://gethejly.com'
}.freeze

InstallationConfig.transaction do
  # Require existing records from normal database preparation; preserve their locks.
  configs = branding.keys.to_h { |name| [name, InstallationConfig.find_by!(name: name)] }
  configs.each do |name, config|
    next if config.value == branding.fetch(name)

    config.value = branding.fetch(name)
    config.save!
  end
end

branding.each_key do |name|
  puts "#{name}=#{InstallationConfig.find_by!(name: name).value}"
end
