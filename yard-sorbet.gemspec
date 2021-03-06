# typed: strong
# frozen_string_literal: true

require_relative 'lib/yard-sorbet/version'

Gem::Specification.new do |spec|
  spec.name = 'yard-sorbet'
  spec.version = YARDSorbet::VERSION
  spec.author = 'Douglas Eichelberger'
  spec.email = 'dduugg@gmail.com'
  spec.license = 'Apache-2.0'

  spec.summary = 'Create YARD docs from Sorbet type signatures'
  spec.description = <<~DESC
    A YARD plugin that incorporates Sorbet type information
  DESC
  spec.homepage = 'https://github.com/dduugg/yard-sorbet'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/dduugg/yard-sorbet/blob/master/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(sorbet|spec)/}) }
  end

  spec.add_development_dependency 'codecov', '~> 0.2.12'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.4.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.0.0'
  spec.add_development_dependency 'rubocop-sorbet', '~> 0.5.1'
  spec.add_development_dependency 'simplecov', '~> 0.19.1'
  spec.add_development_dependency 'sorbet', '~> 0.5.6083'
  spec.add_runtime_dependency 'sorbet-runtime', '>= 0.5'
  spec.add_runtime_dependency 'yard', '>= 0.9'
end
