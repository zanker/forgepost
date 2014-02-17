guard("rspec", :all_after_pass => false, :cli => "--color --fail-fast") do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) {|match| "spec/lib/#{match[1]}_spec.rb"}
end